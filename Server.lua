local function write_header(response, callback)
  local header =
    'HTTP/1.0 200 OK\r\n' ..
    'Server: NodeMCU on ESP8266\r\n' ..
    'Content-Type: image/jpeg\r\n' ..
    'Content-disposition: inline; filename=image.jpg\r\n' ..
    '\r\n'

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
        local co
        co = coroutine.create(function()
          write_header(response, function() assert(coroutine.resume(co)) end)
          coroutine.yield()

          routes[request.method][request.url](request, {
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
    get = function(url, handler) routes.GET[url] = handler end,
    put = function(url, handler) routes.PUT[url] = handler end,
    post = function(url, handler) routes.POST[url] = handler end,
    delete = function(url, handler) routes.DELETE[url] = handler end
  }
end
