local typedefs = require "kong.db.schema.typedefs"

return {
  name = "aws-sns",
  fields = {
    { protocols = typedefs.protocols_http },
    { config = {
      type = "record",
      fields = {
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
  }
}
