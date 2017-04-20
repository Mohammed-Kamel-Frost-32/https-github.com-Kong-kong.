local schemas_validation = require "kong.dao.schemas_validation"
local schema = require "kong.plugins.request-termination.schema"

local v = schemas_validation.validate_entity

describe("Plugin: request-termination (schema)", function()
  it("should accept a valid status_code", function()
    assert(v({status_code = 404}, schema))
  end)
  it("should accept a valid message", function()
    assert(v({message = "Not found"}, schema))
  end)
  it("should accept a valid content_type", function()
    assert(v({content_type = "text/html",body = "<body><h1>Not found</h1>"}, schema))
  end)
  it("should accept a valid body", function()
    assert(v({body = "<body><h1>Not found</h1>"}, schema))
  end)

  describe("errors", function()
    it("status_code should only accept numbers", function()
      local ok, err = v({status_code = "abcd"}, schema)
      assert.same({status_code = "status_code is not a number"}, err)
      assert.False(ok)
    end)
    it("status_code < 100", function()
      local ok, _, err = v({status_code = "99"}, schema)
      assert.False(ok)
      assert.same("status_code must be between 100..599", err.message)
    end)
    it("status_code > 599", function()
      local ok, _, err = v({status_code = "600"}, schema)
      assert.False(ok)
      assert.same("status_code must be between 100..599", err.message)
    end)
    it("message with body", function()
      local ok, _, err = v({message = "error", body = "test"}, schema)
      assert.False(ok)
      assert.same("message cannot be used with content_type or body", err.message)
    end)
    it("message with body and content_type", function()
      local ok, _, err = v({message = "error", content_type="text/html", body = "test"}, schema)
      assert.False(ok)
      assert.same("message cannot be used with content_type or body", err.message)
    end)
    it("message with content_type", function()
      local ok, _, err = v({message = "error", content_type="text/html"}, schema)
      assert.False(ok)
      assert.same("message cannot be used with content_type or body", err.message)
    end)
    it("content_type without body", function()
      local ok, _, err = v({content_type="text/html"}, schema)
      assert.False(ok)
      assert.same("content_type requires a body", err.message)
    end)
  end)
end)
