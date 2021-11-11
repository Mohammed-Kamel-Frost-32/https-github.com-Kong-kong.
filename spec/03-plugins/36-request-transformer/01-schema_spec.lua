-- This software is copyright Kong Inc. and its licensors.
-- Use of the software is subject to the agreement between your organization
-- and Kong Inc. If there is no such agreement, use is governed by and
-- subject to the terms of the Kong Master Software License Agreement found
-- at https://konghq.com/enterprisesoftwarelicense/.
-- [ END OF LICENSE 0867164ffc95e54f04670b5169c09574bdbd9bba ]

local request_transformer_schema = require "kong.plugins.request-transformer.schema"
local v = require("spec.helpers").validate_plugin_config_schema

describe("Plugin: request-transformer(schema)", function()
  it("validates http_method", function()
    local ok, err = v({ http_method = "GET" }, request_transformer_schema)
    assert.truthy(ok)
    assert.falsy(err)
  end)
  it("errors invalid http_method", function()
    local ok, err = v({ http_method = "HELLO!" }, request_transformer_schema)
    assert.falsy(ok)
    assert.equal("invalid value: HELLO!", err.config.http_method)
  end)
  it("validate regex pattern as value", function()
    local config = {
      add = {
        querystring = {"uri_param1:$(uri_captures.user1)", "uri_param2:$(uri_captures.user2)"},
      }
    }
    local ok, err = v(config, request_transformer_schema)
    assert.truthy(ok)
    assert.is_nil(err)
  end)
  it("validate string as value", function()
    local config = {
      add = {
        querystring = {"uri_param1:$(uri_captures.user1)", "uri_param2:value"},
      }
    }
    local ok, err = v(config, request_transformer_schema)
    assert.truthy(ok)
    assert.is_nil(err)
  end)
  it("error for missing value", function()
    local config = {
      add = {
        querystring = {"uri_param2:"},
      }
    }
    local ok, err = v(config, request_transformer_schema)
    assert.falsy(ok)
    assert.not_nil(err)
  end)
  it("error for malformed regex pattern in value", function()
    local config = {
      add = {
        querystring = {"uri_param2:$(uri_captures user2)"},
      }
    }
    local ok, err = v(config, request_transformer_schema)
    assert.falsy(ok)
    assert.not_nil(err)
  end)
end)

