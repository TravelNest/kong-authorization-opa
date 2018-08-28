local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local utils = require "kong.tools.utils"
local http = require "resty.http"
local cjson = require "cjson.safe"
local public_utils = require "kong.tools.public"

-- functions
local new_tab
do
  local ok
  ok, new_tab = pcall(require, "table.new")
  if not ok then
    new_tab = function(narr, nrec) return {} end
  end
end

function slice(list, from, to)
  sliced_results = {};
  for i=from, to do
    table.insert(sliced_results, list[i]);
  end;
  return sliced_results;
end

function split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result
end

-- defaults
local DEFAULT_PORT = 80

local OPAHandler = BasePlugin:extend()

function OPAHandler:new()
  OPAHandler.super.new(self, "opa")
end

function OPAHandler:access(conf)
  local start_time = ngx.now()
  OPAHandler.super.access(self)

  local opa_input = new_tab(0, 6)

  -- forwarding various additional data based on config
  if conf.forward_request_body or conf.forward_request_headers
    or conf.forward_request_method or conf.forward_request_uri
    or conf.forward_upstream_split_path
  then
    local var = ngx.var

    if conf.forward_request_method then
      opa_input.method = var.request_method
    end

    if conf.forward_request_headers then
      opa_input.headers = ngx.req.get_headers()
    end

    if conf.forward_upstream_split_path then
      raw_split_uri = split(var.upstream_uri, "/")
      opa_input.path = slice(raw_split_uri, 2, #raw_split_uri)
    end

    if conf.forward_request_uri then
      opa_input.uri      = var.request_uri
      opa_input.uri_args = ngx.req.get_uri_args()
    end

    if conf.forward_request_body then
      ngx.req.read_body()

      local body_args, err_code, body_raw = public_utils.get_body_info()
      if err_code == public_utils.req_body_errors.unknown_ct then
        -- don't know what this body MIME type is, base64 it just in case
        body_raw = ngx.encode_base64(body_raw)
        opa_input.body_base64 = true
      end

      opa_input.body      = body_raw
      opa_input.body_args = body_args
    end

  end

  -- package up into correct OPA format
  local opa_body = new_tab(0, 6)
  opa_body.input = opa_input

  -- jsonify
  local opa_body_json, err = cjson.encode(opa_body)
  if not opa_body_json then
    ngx.log(ngx.ERR, "[opa] could not JSON encode upstream body",
                     " to forward request values: ", err)
  end

  -- config'd request variables
  local host = conf.opa_host
  local path = conf.policy_uri
  local port = conf.port or DEFAULT_PORT

  -- Trigger request to OPA
  local client = http.new()
  client:set_timeout(conf.timeout)
  client:connect(host, port)

  local res, err = client:request {
    method = "POST",
    path = path,
    body = opa_body_json,
    headers = {
      ["Content-Type"] = "application/json",
    }
  }
  if not res then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  local body = res:read_body()
  local headers = res.headers

  local ok, err = client:set_keepalive(conf.keepalive)
  if not ok then
    return responses.send_HTTP_INTERNAL_SERVER_ERROR(err)
  end

  -- set latency header
  ngx.header["X-Kong-Authz-Latency"] = (ngx.now() - start_time) * 1000

  if not conf.debug
  then
    if not string.find(body, "true")
    then
      return responses.send_HTTP_UNAUTHORIZED()
    end
    -- else continue the request
  else
    ngx.status = 200
    ngx.say(body)
    return ngx.exit(ngx.status)
  end

end

-- Priority places this after Authentication and just after Rate Limiting plugins, see:
-- https://docs.konghq.com/0.13.x/plugin-development/custom-logic/#plugins-execution-order
OPAHandler.PRIORITY = 899
OPAHandler.VERSION = "0.1.0"

return OPAHandler
