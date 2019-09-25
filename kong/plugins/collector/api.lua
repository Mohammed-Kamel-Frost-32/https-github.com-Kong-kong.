local backend = require "kong.plugins.collector.backend"
local utils = require "kong.tools.utils"

local function backend_data()
    local rows = kong.db.plugins:select_all({ name = "collector" })
    return rows[1]
end

return {
  ["/collector/status"] = {
    GET = function(self, db)
      local backend_data = backend_data()

      if not backend_data then
        return kong.response.exit(404, { message = "No configuration found." })
      end

      local query = kong.request.get_raw_query()
      local res, err = backend.http_get(
        backend_data.config.host,
        backend_data.config.port,
        backend_data.config.connection_timeout,
        "/status",
        query
      )
      if err then
        error("communication with brain/immunity failed: " .. tostring(err))
      else
        return kong.response.exit(res.status, res:read_body())
      end
    end
  },
  ["/collector/alerts"] = {
    GET = function(self, db)
      local row =  backend_data()

      if not row then
        return kong.response.exit(404, { message = "No configuration found." })
      end

      local query = kong.request.get_query()
      local workspace_name = self.url_params.workspace_name
      local args = kong.table.merge(query, { workspace_name = workspace_name })
      local params = utils.encode_args(args)

      local res, err = backend.http_get(
        row.config.host,
        row.config.port,
        row.config.connection_timeout,
        "/alerts",
        params
      )

      if err then
        error("communication with brain/immunity failed: " .. tostring(err))
      else
        return kong.response.exit(res.status, res:read_body())
      end
    end
  },
  ["/service_maps"] = {
    GET = function(self, db)
      local row =  backend_data()

      if not row then
        return kong.response.exit(404, { message = "No configuration found." })
      end


      local query = kong.request.get_query()
      local workspace_name = self.url_params.workspace_name
      local args = kong.table.merge(query, { workspace_name = workspace_name })
      local params = utils.encode_args(args)

      local res, err = backend.http_get(
        row.config.host,
        row.config.port,
        row.config.connection_timeout,
        "/service-map",
        params
      )

      if err then
        error("communication with brain/immunity failed: " .. tostring(err))
      else
        return kong.response.exit(res.status, res:read_body())
      end
    end
  }
}
