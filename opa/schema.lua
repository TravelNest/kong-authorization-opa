return {
  fields = {
    timeout = {
      type = "number",
      default = 60000,
      required = true,
    },
    keepalive = {
      type = "number",
      default = 60000,
      required = true,
    },
    opa_host = {
      type = "string",
      required = true,
    },
    policy_uri = {
      type= "string",
      required = true,
    },
    port = {
      type = "number",
      default = 80,
    },
    forward_request_method = {
      type = "boolean",
      default = false,
    },
    forward_request_uri = {
      type = "boolean",
      default = false,
    },
    forward_request_headers = {
      type = "boolean",
      default = false,
    },
    forward_request_body = {
      type = "boolean",
      default = false,
    },
    forward_upstream_split_path = {
      type = "boolean",
      default = true,
    },
    debug = {
      type= "boolean",
      default = false,
    },
  },
}
