-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local typedefs = require "kong.db.schema.typedefs"

return {
  name = "tcp-log",
  fields = {
    { protocols = typedefs.protocols },
    { consumer_group = typedefs.no_consumer_group },
    { config = {
        type = "record",
        fields = {
          { host = typedefs.host({ required = true, description = "The IP address or host name to send data to." }), },
          { port = typedefs.port({ required = true, description = "The port to send data to on the upstream server." }), },
          { timeout = { description = "An optional timeout in milliseconds when sending data to the upstream server.", type = "number", default = 10000, }, },
          { keepalive = { description = "An optional value in milliseconds that defines how long an idle connection lives before being closed.", type = "number", default = 60000, }, },
          { tls = { description = "Indicates whether to perform a TLS handshake against the remote server.", type = "boolean", required = true, default = false, }, },
          { tls_sni = { description = "An optional string that defines the SNI (Server Name Indication) hostname to send in the TLS handshake.", type = "string", }, },
          { custom_fields_by_lua = typedefs.lua_code({ description = "A list of key-value pairs, where the key is the name of a log field and the value is a chunk of Lua code, whose return value sets or replaces the log field value." }), },
        },
    }, },
  }
}
