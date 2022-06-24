local typedefs = require "kong.db.schema.typedefs"

return {
  name = "aws-sns",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
      type = "record",
      fields = {
        { timeout = {
          type = "number",
          required = true,
          default = 60000,
        } },
        { keepalive = {
          type = "number",
          required = true,
          default = 60000,
        } },
        { aws_key = {
          type = "string",
        } },
        { aws_secret = {
          type = "string",
        } },
        { aws_assume_role_arn = {
          type = "string",
        } },
        { aws_role_session_name = {
          type = "string",
          default = "kong",
        } },
        { aws_region = typedefs.host },
        { topic_arn = {
          type = "string",
          required = true,
        } },
        { host = typedefs.host },
        { port = typedefs.port { default = 443 }, },
        { proxy_url = typedefs.url },
        { skip_large_bodies = {
          type = "boolean",
          default = false,
        } },
        { base64_encode_body = {
          type = "boolean",
          default = false,
        } },
      }
    },
  } },
  entity_checks = {
    { mutually_required = { "config.aws_key", "config.aws_secret" } },
    { custom_entity_check = {
        field_sources = { "config.proxy_url" },
        fn = function(entity)
          local proxy_url = entity.config and entity.config.proxy_url

          if type(proxy_url) == "string" then
            local scheme = proxy_url:match("^([^:]+)://")

            if scheme and scheme ~= "http" then
              return nil, "proxy_url scheme must be http"
            end
          end

          return true
        end,
      }
    },
  }
}
