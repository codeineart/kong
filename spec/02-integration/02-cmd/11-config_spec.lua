local helpers = require "spec.helpers"
local cjson = require "cjson"

describe("kong config", function()
  local yaml_path = "spec/fixtures/declarative_config.yaml"

  local db

  lazy_setup(function()
    local _
    _, db = helpers.get_db_utils(nil, {
      "plugins", "routes", "services"
    }) -- runs migrations
    helpers.prepare_prefix()
  end)
  after_each(function()
    helpers.kill_all()
  end)
  before_each(function()
    db.plugins:truncate()
    db.routes:truncate()
    db.services:truncate()
  end)
  lazy_teardown(function()
    helpers.clean_prefix()
  end)

  it("config help", function()
    local _, stderr = helpers.kong_exec "config --help"
    assert.not_equal("", stderr)
  end)

  it("config imports a yaml file", function()
    helpers.start_kong({
      nginx_conf = "spec/fixtures/custom_nginx.template",
    })

    assert(helpers.kong_exec("config -vv import " .. yaml_path, {
      prefix = helpers.test_conf.prefix,
    }))

    local client = helpers.admin_client()

    local res = client:get("/services/foo")
    assert.res_status(200, res)

    local res = client:get("/services/bar")
    assert.res_status(200, res)

    local res = client:get("/services/foo/plugins")
    local body = assert.res_status(200, res)
    local json = cjson.decode(body)
    assert.equals(2, #json.data)

    local res = client:get("/services/bar/plugins")
    local body = assert.res_status(200, res)
    local json = cjson.decode(body)
    assert.equals(2, #json.data)
  end)
end)
