local config = require 'config'

camera.init()

wifi.start()
wifi.mode(wifi.STATION)
wifi.sta.config({ ssid = config.wifi.ssid, pwd = config.wifi.pwd })

wifi.sta.on('got_ip', function(ev, info)
  print('Server running on http://' .. info.ip .. ':' .. config.port)
end)

local server = require 'lib/Server'(config.port)

server.get('/', function(request, response)
  camera.capture()
  local image_size = camera.image_size()
  for i = 0, image_size - 1, 1000 do
    response.write(camera.image_chunk(i, math.min(1000, image_size - i)))
  end
end, { 'Content-Type: image/jpeg', 'Content-disposition: inline; filename=image.jpg' })
