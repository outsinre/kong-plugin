local typedefs = require "kong.db.schema.typedefs"


local PLUGIN_NAME = "zacharyhu"


local schema = {
  -- name, fields and entity_checks
  name = PLUGIN_NAME,
  fields = {
    -- the 'fields' array is the top-level entry with fields defined by Kong
    -- default fields ignored here
    { consumer = typedefs.no_consumer },  -- this plugin cannot be configured on a consumer (typical for auth plugins)
    { protocols = typedefs.protocols_http },
    { config = {
        -- The 'config' record is the custom part when enabling this plugin
        type = "record",
        fields = {
          -- a standard defined field (typedef), with some customizations
          { request_header = typedefs.header_name {
              required = true,
              default = "Hello-World" } },
          { response_header = typedefs.header_name {
              required = true,
              default = "Bye-World" } },
          { ttl = { -- self defined field
              type = "integer",
              default = 600,
              required = true,
              -- validator rules (e.g. 'gt') validate a single field
              -- can define 'custom_validator' function equivalent to 'gt'
              custom_validator = function(v)
                if v > 0 then return true end

                return nil, "must greater than 0"
              end }},
        },
        entity_checks = {
          -- 'entity_checks' rules (e.g. 'at_least_one_of') validate multiple fields
          -- the following is silly because it is always true, since they are both required
          { at_least_one_of = { "request_header", "response_header" }, },
          -- We specify that both header-names cannot be the same
          { distinct = { "request_header", "response_header"} },
        },
      },
    },
  },
}

return schema
