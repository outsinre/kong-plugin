local helpers = require "spec.helpers"


local PLUGIN_NAME = "zacharyhu"


for _, strategy in helpers.all_strategies() do if strategy == "postgres" then
  describe(PLUGIN_NAME .. ": (access) [#" .. strategy .. "]", function()
    local client

    lazy_setup(function()
      helpers.clean_logfile()

      local bp = helpers.get_db_utils(strategy == "off" and "postgres" or strategy, nil, { PLUGIN_NAME })

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

      -- start kong
      assert(helpers.start_kong({
        -- set the strategy
        database   = strategy,
        -- use the custom test template to create a local mock server
        nginx_conf = "spec/fixtures/custom_nginx.template",
        -- make sure our plugin gets loaded
        plugins = PLUGIN_NAME,
        -- write & load declarative config, only if 'strategy=off'
        declarative_config = strategy == "off" and helpers.make_yaml_file() or nil,
      }))
    end)

    lazy_teardown(function()
      helpers.stop_kong(nil, true)
    end)

    describe("print log", function()
      it("gets a 'hello-world' header", function()
        for _ = 1, 500 do
          client = helpers.proxy_client()
          local r = client:get("/request", {
            headers = {
              host = "test1.com"
            }
          })
          assert.response(r).has.status(200)
          assert.logfile().has.line([[Hello World: response]], true)
          client:close()
        end
      end)
    end)

  end)

end end
