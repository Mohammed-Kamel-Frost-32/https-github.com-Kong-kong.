local enums       = require "kong.enterprise_edition.dao.enums"
local helpers     = require "spec.helpers"
local conf_loader = require "kong.conf_loader"


local _M = {}


function _M.register_rbac_resources(dao)
  local utils = require "kong.tools.utils"
  local bit   = require "bit"
  local rbac  = require "kong.rbac"
  local bxor  = bit.bxor

  -- action int for all
  local action_bits_all = 0x0
  for k, v in pairs(rbac.actions_bitfields) do
    action_bits_all = bxor(action_bits_all, rbac.actions_bitfields[k])
  end

  local roles = {}

  -- now, create the roles and assign endpoint permissions to them

  -- first, a read-only role across everything
  roles.read_only = dao.rbac_roles:insert({
    id = utils.uuid(),
    name = "read-only",
    comment = "Read-only access across all initial RBAC resources",
  })
  -- this role only has the 'read-only' permissions
  dao.rbac_role_endpoints:insert({
    role_id = roles.read_only.id,
    workspace = "*",
    endpoint = "*",
    actions = rbac.actions_bitfields.read,
  })

  -- admin role with CRUD access to all resources except RBAC resource
  roles.admin = dao.rbac_roles:insert({
    id = utils.uuid(),
    name = "admin",
    comment = "CRUD access to most initial resources (no RBAC)",
  })

  -- the 'admin' role has 'full-access' + 'no-rbac' permissions
  dao.rbac_role_endpoints:insert({
    role_id = roles.admin.id,
    workspace = "*",
    endpoint = "*",
    actions = action_bits_all, -- all actions
  })

  dao.rbac_role_endpoints:insert({
    role_id = roles.admin.id,
    workspace = "*",
    endpoint = "/rbac",
    negative = true,
    actions = action_bits_all, -- all actions
  })

  -- finally, a super user role who has access to all initial resources
  roles.super_admin = dao.rbac_roles:insert({
    id = utils.uuid(),
    name = "super-admin",
    comment = "Full CRUD access to all initial resources, including RBAC entities",
  })

  dao.rbac_role_entities:insert({
    role_id = roles.super_admin.id,
    entity_id = "*",
    entity_type = "wildcard",
    actions = action_bits_all, -- all actions
  })

  dao.rbac_role_endpoints:insert({
    role_id = roles.super_admin.id,
    workspace = "*",
    endpoint = "*",
    actions = action_bits_all, -- all actions
  })

  local super_admin, err = dao.rbac_users:insert({
    id = utils.uuid(),
    name = "super_gruce",
    user_token = "letmein",
    enabled = true,
    comment = "Test - Initial RBAC Super Admin User"
  })

  if err then
    return err
  end

  local super_user_role, err = dao.rbac_user_roles:insert({
    user_id = super_admin.id,
    role_id = roles.super_admin.id
  })

  if err then
    return err
  end

  return super_admin, super_user_role
end


--- Returns the Dev Portal port.
-- @param ssl (boolean) if `true` returns the ssl port
local function get_portal_port(ssl)
  if ssl == nil then ssl = false end
  for _, entry in ipairs(_M.portal_api_listeners) do
    if entry.ssl == ssl then
      return entry.port
    end
  end
  error("No portal port found for ssl=" .. tostring(ssl), 2)
end


--- Returns the Dev Portal ip.
-- @param ssl (boolean) if `true` returns the ssl ip address
local function get_portal_ip(ssl)
  if ssl == nil then ssl = false end
  for _, entry in ipairs(_M.portal_api_listeners) do
    if entry.ssl == ssl then
      return entry.ip
    end
  end
  error("No portal ip found for ssl=" .. tostring(ssl), 2)
end


--- returns a pre-configured `http_client` for the Dev Portal.
-- @name portal_client
function _M.portal_client(timeout)
  local portal_ip = get_portal_ip()
  local portal_port = get_portal_port()
  assert(portal_ip, "No portal_ip found in the configuration")
  return helpers.http_client(portal_ip, portal_port, timeout)
end


-- helper for reset token tests
function _M.register_token_statuses(dao)
  for status, id in pairs(enums.TOKENS.STATUS) do
    local _, err = dao.token_statuses:insert({
      id = id,
      name = status,
    })

    if err then
      return err
    end
  end
end


_M.portal_api_listeners = conf_loader.parse_listeners(helpers.test_conf.portal_api_listen)

return _M
