-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local kong = kong
local producers = require "kong.enterprise_edition.kafka.plugins.producers"
local cert_utils = require "kong.enterprise_edition.kafka.plugins.cert_utils"
local cjson_encode = require("cjson").encode

local ngx_encode_base64 = ngx.encode_base64


local KafkaUpstreamHandler = {}

KafkaUpstreamHandler.PRIORITY = 751
KafkaUpstreamHandler.VERSION = "0.3.1"


local raw_content_types = {
  ["text/plain"] = true,
  ["text/html"] = true,
  ["application/xml"] = true,
  ["text/xml"] = true,
  ["application/soap+xml"] = true,
}


local function build_kafka_message_from_request(conf)
  local method
  if conf.forward_method then
    method = kong.request.get_method()
  end

  local headers
  if conf.forward_headers then
    headers = kong.request.get_headers()
  end

  local uri, uri_args
  if conf.forward_uri then
    uri      = kong.request.get_path_with_query()
    uri_args = kong.request.get_query()
  end

  local body, body_args, body_base64
  if conf.forward_body then
    body = kong.request.get_raw_body()
    local err
    body_args, err = kong.request.get_body()
    if err and err:match("content type") then
      body_args = {}
      local content_type = kong.request.get_header("content-type")
      if not raw_content_types[content_type] then
        -- don't know what this body MIME type is, base64 it just in case
        body = ngx_encode_base64(body)
        body_base64 = true
      end
    end
  end

  return cjson_encode({
    method      = method,
    headers     = headers,
    uri         = uri,
    uri_args    = uri_args,
    body        = body,
    body_args   = body_args,
    body_base64 = body_base64,
  })
end


local function handle_error(err)
  kong.log.err(err)
  return kong.response.exit(502, { message = "Bad Gateway", error = err })
end


function KafkaUpstreamHandler:access(conf)
  local message, err = build_kafka_message_from_request(conf)
  if not message then
    return handle_error("could not build a Kafka message from request: " .. tostring(err))
  end

  -- fetch certificate from the store
  if conf.security.certificate_id then
    local client_cert, client_priv_key, err = cert_utils.load_certificate(conf.security.certificate_id)
    if not client_cert or not client_priv_key or err ~= nil then
      kong.log.err("failed to find or load certificate: ", err)
      return kong.response.exit(500, { message = "Could not load certificate" })
    end
    conf.security.client_cert = client_cert
    conf.security.client_priv_key = client_priv_key
  end

  local producer, err = producers.get_or_create(conf)
  if not producer then
    return handle_error("could not create a Kafka Producer from given configuration: " .. tostring(err))
  end

  local ok, err = producer:send(conf.topic, nil, message)
  if not ok then
    return handle_error("could not send a message on topic " .. conf.topic .. ": " .. tostring(err))
  end

  return kong.response.exit(200, { message = "message sent" })
end


return KafkaUpstreamHandler
