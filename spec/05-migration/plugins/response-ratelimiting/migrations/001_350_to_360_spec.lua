
local cjson = require "cjson"
local uh = require "spec.upgrade_helpers"


local function deep_matches(t1, t2, parent_keys)
    for key, v in pairs(t1) do
        local composed_key = (parent_keys and parent_keys .. "." .. key) or key
        if type(v) == "table" then
            deep_matches(t1[key], t2[key], composed_key)
        else
            assert.message("expected values at key " .. composed_key .. " to be the same").equal(t1[key], t2[key])
        end
    end
end

if uh.database_type() == 'postgres' then
    describe("rate-limiting plugin migration", function()
        lazy_setup(function()
            assert(uh.start_kong())
        end)

        lazy_teardown(function ()
            assert(uh.stop_kong(nil, true))
        end)

        uh.setup(function ()
            local admin_client = assert(uh.admin_client())

            local res = assert(admin_client:send {
                method = "POST",
                path = "/plugins/",
                body = {
                    name = "response-ratelimiting",
                    config = {
                        minute = 200,
                        redis_host = "localhost",
                        redis_port = 57198,
                        redis_username = "test",
                        redis_password = "secret",
                        redis_ssl = true,
                        redis_ssl_verify = true,
                        redis_server_name = "test.example",
                        redis_timeout = 1100,
                        redis_database = 2,
                    }
                },
                headers = {
                ["Content-Type"] = "application/json"
                }
            })
            assert.res_status(201, res)
            admin_client:close()
        end)

        uh.new_after_up("has updated rate-limiting redis configuration", function ()
            local admin_client = assert(uh.admin_client())
            local res = assert(admin_client:send {
                method = "GET",
                path = "/plugins/"
            })
            local body = cjson.decode(assert.res_status(200, res))
            assert.equal(1, #body.data)
            assert.equal("response-ratelimiting", body.data[1].name)
            local expected_config = {
                minute = 200,
                redis = {
                    base = {
                        host = "localhost",
                        port = 57198,
                        username = "test",
                        password = "secret",
                        ssl = true,
                        ssl_verify = true,
                        server_name = "test.example",
                        timeout = 1100,
                        database = 2,
                    }
                }
            }
            deep_matches(expected_config, body.data[1].config)
            admin_client:close()
        end)
    end)
end
