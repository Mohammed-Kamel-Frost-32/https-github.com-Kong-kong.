local Errors = require "kong.dao.errors"
local utils = require "kong.tools.utils"

return {
  no_consumer = true,
  fields = {
    status_code = { type = "number" },
    message = { type = "string" },
    content_type = { type = "string" },
    body = { type = "string" },
  },
  self_check = function(schema, plugin_t, dao, is_updating)
    local errors
  
    if plugin_t.status_code then
      if plugin_t.status_code < 100 or plugin_t.status_code > 599 then
        return false, "status_code must be between 100..599"
      end
    end
    
    if plugin_t.message then
      if plugin_t.content_type or plugin_t.body then
        return false, "message cannot be used with content_type or body"
      end
    else
      if plugin_t.content_type and not plugin_t.body then
        return false, "content_type requires a body"
      end
    end
    
    return true
  end
}
