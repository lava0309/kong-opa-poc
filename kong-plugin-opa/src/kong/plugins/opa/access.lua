local cjson_safe = require "cjson.safe"
local http = require "resty.http"
local jwt_decoder = require "kong.plugins.jwt.jwt_parser"

local webdis_host = os.getenv("WEB_DIS_HOST") or "webdis"
local webdis_port = os.getenv("WEB_DIS_PORT") or "7379"

-- string interpolation with named parameters in table
local function interp(s, tab)
    return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

-- query "Get a Document (with Input)" endpoint from the OPA Data API
local function getDocument(path, conf)
    -- serialize the path into a string containing the JSON representation
    local json_body = assert(cjson_safe.encode({ input = { path = path } }))

    local opa_uri = interp("${protocol}://${host}:${port}/${base_path}/${decision}", {
        protocol = conf.server.protocol,
        host = conf.server.host,
        port = conf.server.port,
        base_path = conf.policy.base_path,
        decision = conf.policy.decision
    })

    local res, err = http.new():request_uri(opa_uri, {
        method = "POST",
        body = json_body,
        headers = {
            ["Content-Type"] = "application/json",
        },
        keepalive_timeout = conf.server.connection.timeout,
        keepalive_pool = conf.server.connection.pool
    })

    if err then
        error(err) -- failed to request the endpoint
    end

    kong.log.debug("opa response: ", res)

    -- deserialize the response into a Lua table
    return assert(cjson_safe.decode(res.body))
end

-- module
local _M = {}

function _M.execute(conf)
    -- get the path from the request
    local path = ngx.var.upstream_uri
    kong.log.debug("request path: ", path)

    -- Decode JWT token
    local token = kong.request.get_header("Authorization")
    if not token then
        kong.log.err("Missing JWT token")
        return kong.response.exit(401, { message = "Missing JWT token" })
    end

    local _, _, jwt = string.find(token, "Bearer%s+(.+)")
    if not jwt then
        kong.log.err("Bad token format")
        return kong.response.exit(401, { message = "Bad token format" })
    end

    local decoded_jwt, err = jwt_decoder:new(jwt)
    if err then
        kong.log.err("Invalid JWT token: ", err)
        return kong.response.exit(401, { message = "Invalid JWT token" })
    end

    local claims = decoded_jwt.claims
    local user_id = claims.sub
    if not user_id then
        kong.log.err("User ID not found in JWT token")
        return kong.response.exit(401, { message = "User ID not found in JWT token" })
    end

    -- Prepare data for Webdis
    local httpc = http.new()
    local response, error = httpc:request_uri("https://dog.ceo/api/breeds/list/all", {
        method = "GET",
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if not response then
        kong.log.err("Failed to communicate with Webdis: ", error)
        return kong.response.exit(500, { message = response.body})
    end

    -- POST data to Webdis
    local httpc = http.new()
    local res, err = httpc:request_uri("http://" .. webdis_host .. ":" .. webdis_port .. "/SET/" .. user_id, {
        method = "POST",
        body = cjson_safe.encode(response),
        headers = {
            ["Content-Type"] = "application/json",
        },
    })

    if res then
        kong.log.err("Failed to communicate with Webdis: ", err)
        return kong.response.exit(500, { message = res.status})
    end

    -- get the decision from OPA
    local status, opa_res = pcall(getDocument, path, conf)

    if not status then
        kong.log.err("Failed to get document: ", opa_res)
        return kong.response.exit(500, { message = "Oops, something went wrong" })
    end

    -- when the policy fails, 'result' is omitted
    if not opa_res.result then
        kong.log.info("Access forbidden by OPA")
        return kong.response.exit(403, { message = "Access Forbidden" })
    end

    -- access allowed
    kong.log.debug("Access allowed to path: ", path)
end

return _M