local Workspaces = {}


local constants = require("kong.constants")
local lmdb = require("resty.lmdb")


local DECLARATIVE_DEFAULT_WORKSPACE_KEY = constants.DECLARATIVE_DEFAULT_WORKSPACE_KEY


function Workspaces:truncate()
  self.super.truncate(self)
  if kong.configuration.database == "off" then
    return true
  end

  local default_ws, err = self:insert({ name = "default" })
  if err then
    kong.log.err(err)
    return
  end

  ngx.ctx.workspace = default_ws.id
  kong.default_workspace = default_ws.id
end


function Workspaces:select_by_name(key, options)
  if kong.configuration.database == "off" then
    return lmdb.get(DECLARATIVE_DEFAULT_WORKSPACE_KEY)
  end

  return self.super.select_by_name(key, options)
end


return Workspaces
