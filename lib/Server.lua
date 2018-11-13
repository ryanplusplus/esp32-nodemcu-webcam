local function write_header(attributes, response, callback)
  attributes = attributes or {
    'Content-Type: text/html'
  }

  local header =
    'HTTP/1.0 200 OK\r\n' ..
    'Server: NodeMCU on ESP32\r\n' ..
    table.concat(attributes, '\r\n') ..
    '\r\n\r\n'

  response:send(header, callback)
end

local function write_file(filename, response, co)
  local f = file.open(filename, 'r')

  while true do
    local chunk = f:read(1000)
    if chunk then
      response:send(chunk, function() assert(coroutine.resume(co)) end)
      coroutine.yield()
    else
      break
    end
  end

  f:close()
end

local function parse_request(request)
  local params = {}
  local method, url = request:match('(%w*) ([^%?%s]*)%??')
  local param_string = request:match('?([^%s]*)') or ''

  for name, value in param_string:gmatch('(%w*)=(%w*)') do
    params[name] = value
  end

  return {
    method = method,
    url = url,
    params = params
  }
end

return function(port)
  local routes = {
    GET = {},
    PUT = {},
    POST = {},
    DELETE = {}
  }

  net.createServer(net.TCP):listen(port, function(connection)
    connection:on('receive', function(response, request)
      request = parse_request(request)

      if routes[request.method][request.url] then
        local callback, attributes = unpack(routes[request.method][request.url])

        local co
        co = coroutine.create(function()
          write_header(attributes, response, function() assert(coroutine.resume(co)) end)
          coroutine.yield()

          callback(request, {
            write = function(value)
              response:send(value, function() assert(coroutine.resume(co)) end)
              coroutine.yield()
            end,
            write_file = function(filename)
              write_file(filename, response, co)
            end
          })

          response:close()
        end)

        assert(coroutine.resume(co))
      end
    end)
  end)

  return {
    get = function(url, callback, header_attributes) routes.GET[url] = { callback, header_attributes } end,
    put = function(url, callback, header_attributes) routes.PUT[url] = { callback, header_attributes } end,
    post = function(url, callback, header_attributes) routes.POST[url] = { callback, header_attributes } end,
    delete = function(url, callback, header_attributes) routes.DELETE[url] = { callback, header_attributes } end
  }
end
