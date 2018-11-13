# esp32-webcam
Simple webcam using an [M5Stack ESP32 camera module](https://www.banggood.com/M5Stack-Official-ESP32-Camera-Module-Development-Board-OV2640-Camera-Type-C-Grove-Port-p-1333598.html?cur_warehouse=CN#jsReviewsWrap).

The firmware is based on NodeMCU with Lua bindings for a camera library found [here](https://github.com/igrr/esp32-cam-demo).

## Installation
Install `espeon` with

```shell
luarocks install espeon
```

1. Flash the firmware with

```shell
espeon flash
```

Upload the application with

```shell
espeon upload
```

## Configuration
The application can be configured by modifying `config.lua`.

## Usage
The application connects to WiFi and hosts an HTTP server. The IP address of the server is printed to the console when the ESP32 connects to the WiFi base station.

An image is captured and served to clients when an HTTP GET is issued to `/`.
