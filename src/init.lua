local config_io = require('config_io')
local config = config_io.load()
local rc522 = nil
local piezo = require('piezo32')({ gpio = config.piezo_gpio })

gpio.config({ gpio = config.green_led_pin, dir = gpio.IN_OUT })
gpio.config({ gpio = config.red_led_pin, dir = gpio.IN_OUT })
gpio.config({ gpio = config.blue_led_pin, dir = gpio.IN_OUT })

gpio.write(config.green_led_pin, 0)
gpio.write(config.red_led_pin, 0)
gpio.write(config.blue_led_pin, 0)

local blue_led_tmr = tmr.create()

blue_led_tmr:register(100, tmr.ALARM_AUTO, function()
    if gpio.read(config.blue_led_pin) == 1 then
        gpio.write(config.blue_led_pin, 0)
    else
        gpio.write(config.blue_led_pin, 1)
    end
end)

local function disconnected_wifi()
    blue_led_tmr:start()
end

local function connected_wifi()
    blue_led_tmr:stop()
    gpio.write(config.blue_led_pin, 1)
end

local function init_wiattend()
    if rc522 ~= nil then return end

    rc522 = require('rfid32')({
        pin_sda  = config.rc522_sda,
        pin_clk  = config.rc522_clk,
        pin_miso = config.rc522_miso,
        pin_mosi = config.rc522_mosi
    })
    .init()
    .scan({
        got_tag = function(tag, rfid)
            rfid.scan_pause()

            local tag_uid = tag.hex()
            print( tag_uid )

            http.post(
                config.wiattend_srv_url .. '/log',
                {
                    timeout = 5000,
                    headers = {
                        ['sguid'] = '2ce81521-c42f-4556-8c28-c69d7e3a3a47',
                        ['rfid-tag'] = tag_uid
                    }
                },
                '',
                function(code, data)
                    if code ~= 200 then
                        print('HTTP error')
                        piezo.error({
                            on_step = function(step)
                                gpio.write(
                                    config.red_led_pin,
                                    step.playing and 1 or 0
                                )
                            end
                        })
                    else
                        print(code, data)
                        piezo.success({
                            on_step = function(step)
                                gpio.write(
                                    config.green_led_pin,
                                    step.playing and 1 or 0
                                )
                            end
                        })
                    end

                    rfid.scan_resume()
                end
            )
        end
    })
end

disconnected_wifi()

wifi.mode(wifi.STATION)

wifi.sta.config({
    ssid  = config.wifi_ssid,
    pwd   = config.wifi_pwd,
    auto  = false
})

wifi.sta.on('got_ip', function()
    connected_wifi()
    init_wiattend()
end)

wifi.sta.on('disconnected', disconnected_wifi)

wifi.start()
wifi.sta.connect()
