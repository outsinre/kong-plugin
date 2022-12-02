local helpers = require "spec.helpers"


local PLUGIN_NAME = "zacharyhu"


for _, strategy in helpers.all_strategies() do if strategy ~= "cassandra" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local proxy_client
    local kong_yml

    lazy_setup(function()

      -- still write test setup to db even if strategy is 'off'
      local bp, _ = assert(helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME }))

      -- Inject a test route. No need to create a service, there is a default
      -- service which will echo the request.
      local route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      -- add the plugin to test to the route we created
      bp.plugins:insert {
        name = PLUGIN_NAME,
        route = { id = route1.id },
        config = {},
      }

      -- can provide custom runtime data
      kong_yml = helpers.make_yaml_file()

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- minimal seconds to propagate db CRUD to db replicas
        db_update_propagation = strategy == "cassandra" and 1 or 0,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded; may remove "bundled"
        plugins = "bundled," .. PLUGIN_NAME,
        -- write & load declarative config, only if 'strategy=off'
        declarative_config = strategy == "off" and kong_yml or nil,
        -- just prove tests run when postgres used as intermediate store for strategy 'off'
        -- can be omitted
        pg_host = strategy == "off" and "unknownhost.konghq.com" or nil,
        cassandra_contact_points = strategy == "off" and "unknownhost.konghq.com" or nil,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      proxy_client = helpers.proxy_client()
    end)

    after_each(function()
      if proxy_client then proxy_client:close() end
    end)



    describe("request", function()
      it("gets a 'hello-world' header", function()
        local r = proxy_client:get("/request", {
          headers = {
            host = "test1.com"
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- now check the request (as echoed by the mock backend) to have the header
        local header_value = assert.request(r).has.header("hello-world")
        -- validate the value of that header
        assert.equal("this is on a request", header_value)
      end)
    end)



    describe("response", function()
      it("gets a 'bye-world' header", function()
        local r = proxy_client:get("/request", {
          headers = {
            host = "test1.com"
          }
        })
        -- validate that the request succeeded, response status 200
        assert.response(r).has.status(200)
        -- now check the response to have the header
        local header_value = assert.response(r).has.header("bye-world")
        -- validate the value of that header
        assert.equal("this is on the response", header_value)
      end)
    end)

  end)

end end
