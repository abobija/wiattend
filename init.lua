local config_io = require('config_io')
local config = config_io.load()
local rc522 = nil

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
                    if code < 0 then
                        print('HTTP error')
                    else
                        print(code, data)
                    end

                    rfid.scan_resume()
                end
            )
        end
    })
end

wifi.mode(wifi.STATION)

wifi.sta.config({
    ssid  = config.wifi_ssid,
    pwd   = config.wifi_pwd,
    auto  = false
})

wifi.sta.on('got_ip', init_wiattend)

wifi.start()
wifi.sta.connect()