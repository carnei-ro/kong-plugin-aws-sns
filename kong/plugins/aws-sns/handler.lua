-- Copyright (C) Kong Inc.

local aws_v4 = require "kong.plugins.aws-sns.v4"
local cjson = require "cjson.safe"
cjson.decode_array_with_array_mt(true)
local request_util = require "kong.plugins.aws-sns.request-util"
local kong = kong

local IAM_CREDENTIALS_CACHE_KEY_PATTERN = "plugin.aws-sns.iam_role_temp_creds.%s"
local AWS_PORT = 443
local AWS_REGION do
  AWS_REGION = os.getenv("AWS_REGION") or os.getenv("AWS_DEFAULT_REGION")
end

local function fetch_aws_credentials(aws_conf)
  local fetch_metadata_credentials do
    local metadata_credentials_source = {
      require "kong.plugins.aws-sns.iam-ecs-credentials",
      -- The EC2 one will always return `configured == true`, so must be the last!
      require "kong.plugins.aws-sns.iam-ec2-credentials",
    }

    for _, credential_source in ipairs(metadata_credentials_source) do
      if credential_source.configured then
        fetch_metadata_credentials = credential_source.fetchCredentials
        break
      end
    end
  end

  if aws_conf.aws_assume_role_arn then
    local metadata_credentials, err = fetch_metadata_credentials()

    if err then
      return nil, err
    end

    local aws_sts_cred_source = require "kong.plugins.aws-sns.iam-sts-credentials"
    return aws_sts_cred_source.fetch_assume_role_credentials(aws_conf.aws_region,
                                                             aws_conf.aws_assume_role_arn,
                                                             aws_conf.aws_role_session_name,
                                                             metadata_credentials.access_key,
                                                             metadata_credentials.secret_key,
                                                             metadata_credentials.session_token)

  else
    return fetch_metadata_credentials()
  end
end


local ngx_encode_base64 = ngx.encode_base64
local tostring = tostring
local error = error
local fmt = string.format


local raw_content_types = {
  ["text/plain"] = true,
  ["text/html"] = true,
  ["application/xml"] = true,
  ["text/xml"] = true,
  ["application/soap+xml"] = true,
}


local plugin = {}


function plugin:access(conf)
  local upstream_body = kong.table.new(0, 6)

  local content_type = kong.request.get_header("content-type")
  local body_raw = request_util.read_request_body(conf.skip_large_bodies)
  local body_args, err = kong.request.get_body()
  if err and err:match("content type") then
    body_args = {}
    if not raw_content_types[content_type] and conf.base64_encode_body then
      -- don't know what this body MIME type is, base64 it just in case
      body_raw = ngx_encode_base64(body_raw)
      upstream_body.request_body_base64 = true
    end
  end

  upstream_body.request_body      = body_raw
  upstream_body.request_body_args = body_args

  local sns_body = {
    Action = "Publish",
    Version = "2010-03-31",
    TopicArn = conf.topic_arn,
    Message = upstream_body.request_body,
  }

  local upstream_body_encoded, err = ngx.encode_args(sns_body)

  if not upstream_body_encoded then
    kong.log.err("could not encode upstream body",
                 " to forward request values: ", err)
  end

  local region = conf.aws_region or AWS_REGION
  local host = conf.host

  if not region then
    return error("no region specified")
  end

  if not host then
    host = fmt("sns.%s.amazonaws.com", region)
  end

  local port = conf.port or AWS_PORT

  local opts = {
    region = region,
    service = "sns",
    method = "POST",
    headers = {
      ["Content-Type"] = "application/x-www-form-urlencoded; charset=utf-8",
      ["Accept"] = "application/json",
      ["Content-Length"] = upstream_body_encoded and tostring(#upstream_body_encoded),
    },
    body = upstream_body_encoded,
    path = "/",
    host = host,
    port = port,
  }

  local aws_conf = {
    aws_region = conf.aws_region,
    aws_assume_role_arn = conf.aws_assume_role_arn,
    aws_role_session_name = conf.aws_role_session_name,
  }

  if not conf.aws_key then
    -- no credentials provided, so try the IAM metadata service
    local iam_role_cred_cache_key = fmt(IAM_CREDENTIALS_CACHE_KEY_PATTERN, conf.aws_assume_role_arn or "default")
    local iam_role_credentials = kong.cache:get(
      iam_role_cred_cache_key,
      nil,
      fetch_aws_credentials,
      aws_conf
    )

    if not iam_role_credentials then
      return kong.response.error(500)
    end

    opts.access_key = iam_role_credentials.access_key
    opts.secret_key = iam_role_credentials.secret_key
    opts.headers["X-Amz-Security-Token"] = iam_role_credentials.session_token

  else
    opts.access_key = conf.aws_key
    opts.secret_key = conf.aws_secret
  end

  local request
  request, err = aws_v4(opts)
  if err then
    return error(err)
  end

  -- kong.response.exit(200, request )

  kong.service.request.set_method(request.method)
  kong.service.request.set_scheme("https")
  if request.target == "/?" then
    request.target = "/"
  end
  kong.service.request.set_path(request.target)

  kong.service.set_target(request.host, request.port)

  if request.body then
    kong.service.request.set_raw_body(request.body)
  else
    kong.service.request.set_raw_body('')
  end

  kong.service.request.set_headers(request.headers)
end

plugin.PRIORITY = 750

plugin.VERSION = "0.2.0"

return plugin
