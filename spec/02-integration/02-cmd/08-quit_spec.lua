local helpers = require "spec.helpers"

describe("kong quit", function()
  setup(function()
    helpers.get_db_utils() -- runs migrations
    helpers.prepare_prefix()
  end)
  after_each(function()
    helpers.kill_all()
  end)
  teardown(function()
    helpers.clean_prefix()
  end)

  it("quit help", function()
    local _, stderr = helpers.kong_exec "quit --help"
    assert.not_equal("", stderr)
  end)
  it("quits gracefully", function()
    assert(helpers.kong_exec("start --conf " .. helpers.test_conf_path))
    assert(helpers.kong_exec("quit --prefix " .. helpers.test_conf.prefix))
  end)
  it("quit gracefully with --timeout option", function()
    assert(helpers.kong_exec("start --conf " .. helpers.test_conf_path))
    assert(helpers.kong_exec("quit --timeout 2 --prefix " .. helpers.test_conf.prefix))
  end)
end)
