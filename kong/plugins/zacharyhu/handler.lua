--- If you're not sure your plugin is executing, uncomment the line below and restart Kong
-- then it will throw an error which indicates the plugin is being loaded at least.

--[=[
assert(ngx.get_phase() == "timer", "The world is coming to an end!")
--]=]


local kong = kong
local subsystem = ngx.config.subsystem


local ZacharyHuHandler = {
  PRIORITY = 1000, -- set the plugin priority, which determines plugin execution order
  VERSION = "0.1.0", -- version in X.Y.Z format. Check hybrid-mode compatibility requirements.
}


--- master process initializes any module level code in the 'init_by_lua_block',
-- before worker processes are forked. So anything you add here will run once,
-- and are available to all workers.
kong.log.debug("saying hi from the 'init' handler")


--- worker initialization in the 'init_worker_by_lua_block' handles more initialization,
-- but only AFTER the worker process has been forked/created.
-- this function does not accept argumenbt 'plugin_conf'
function ZacharyHuHandler:init_worker()

  kong.log.debug("saying hi from the 'init_worker' handler")
end


if subsystem == "stream" then
  function ZacharyHuHandler:preread(plugin_conf)  -- 'plugin_conf' retrieved from db and passed to handler

    kong.log.debug("saying hi from the 'preread' handler")
  end
end


--- runs in the 'ssl_certificate_by_lua_block'
-- IMPORTANT: during the `certificate` phase, neither `route`, `service` nor `consumer`
-- will have been identified. Hence, this handler will only be executed if the plugin is
-- configured as a global plugin!
function ZacharyHuHandler:certificate(plugin_conf)

  kong.log.debug("saying hi from the 'certificate' handler")
end


if subsystem ~= "stream" then
  --- runs in the 'rewrite_by_lua_block'
  -- IMPORTANT: during the `rewrite` phase, neither `route`, `service` nor `consumer`
  -- would have been identified. Hence, this handler will only be executed if the plugin is
  -- configured as a global plugin!
  function ZacharyHuHandler:rewrite(plugin_conf)

    kong.log.debug("saying hi from the 'rewrite' handler")
  end
end


if subsystem == "http" then
  --- called whenever there is config update. An array of current plugin configurations
  -- is passed to the function.
  function ZacharyHuHandler:configure(plugin_confs)

    kong.log.inspect(plugin_confs)
    kong.log.debug("saying hi from the 'configure' handler")
  end

  --- runs in the 'access_by_lua_block'
  -- can also customize request headers
  function ZacharyHuHandler:access(plugin_conf)

    kong.log.inspect(plugin_conf)
    kong.service.request.set_header(plugin_conf.request_header, "this is on a request")
  end
end


--[=[ counterpart of 'access' handler
function ZacharyHuHandler:ws_handshake(plugin_conf)

  kong.log.debug("saying hi from the 'ws_handshake' handler")
end --]=]


if subsystem == "http" then
  --[=[
  --- runs in the Kong's "fake response phase"
  -- replaces and conflicts with 'header_filter' and 'body_filter'
  -- implicitly enables "buffering outpout" (only http/1.1 traffic)
  -- can access to response headers and response body simultaneously
  function ZacharyHuHandler:response(plugin_conf)

    kong.log.debug("saying hi from the 'response' handler")
  end --]=]

  --- We do not have a ':content_filter(plugin_conf)' as
  -- content is generated from 'Kong.balancer()'.

  --- runs in the 'header_filter_by_lua_block'
  -- customize response headers from upstream (not from 'content_by_lua_block')
  function ZacharyHuHandler:header_filter(plugin_conf)

    kong.response.set_header(plugin_conf.response_header, "this is on the response")
  end

  --- runs in the 'body_filter_by_lua_block'
  -- customize response body from upstream (not from 'content_by_lua_block')
  function ZacharyHuHandler:body_filter(plugin_conf)

    kong.log.debug("saying hi from the 'body_filter' handler")

  end
end


--[=[ ws traffic
function ZacharyHuHandler:ws_client_frame(plugin_conf)

  kong.log.debug("saying hi from the 'ws_client_frame' handler")
end


function ZacharyHuHandler:ws_upstream_frame(plugin_conf)

  kong.log.debug("saying hi from the 'ws_upstream_frame' handler")
end --]=]


--- runs in the 'log_by_lua_block'
-- mainly for 'access.log'
function ZacharyHuHandler:log(plugin_conf)

  kong.log.debug("saying hi from the 'log' handler")
end


--[=[ counterpart of 'log' handler
function ZacharyHuHandler:ws_close(config)

  kong.log.debug("saying hi from the 'ws_close' handler")
end --]=]


-- return our plugin object
return ZacharyHuHandler
