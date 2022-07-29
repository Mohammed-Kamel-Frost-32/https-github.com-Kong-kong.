package = "kong-plugin-mocking"
version = "3.0.0-0"

local pluginName = package:match("^kong%-plugin%-(.+)$")  -- "mocking"

supported_platforms = {"linux", "macosx"}
source = {
  url = "http://github.com/Kong/kong-plugin-mocking.git",
  tag = "3.0.0"
}

description = {
  summary = "Kong is a scalable and customizable API Management Layer built on top of Nginx.",
  homepage = "http://getkong.org",
  license = "Apache 2.0"
}

dependencies = {
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins."..pluginName..".handler"] = "kong/plugins/"..pluginName.."/handler.lua",
    ["kong.plugins."..pluginName..".schema"] = "kong/plugins/"..pluginName.."/schema.lua",
    ["kong.plugins."..pluginName..".mime_parse"] = "kong/plugins/"..pluginName.."/mime_parse.lua",
  }
}
