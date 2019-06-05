local rc522 = nil

local function init_wiattend()
    if rc522 ~= nil then return end

    rc522 = require('rfid32')({
        pin_sda  = 22,
        pin_clk  = 19,
        pin_miso = 25,
        pin_mosi = 23
    })
    .init()
    .scan({
        got_tag = function(tag, rfid)
            rfid.scan_pause()

            local tag_uid = tag.hex()
            print( tag_uid )

            http.post(
                'http://192.168.0.105:8181/log',
                {
                    timeout = 5000,
                    headers = {
                        ['sguid'] = '2ce81521-c42f-4556-8c28-c69d7e3a3a47',
                        ['rfid-tag'] = tag_uid
                    }
                },
                '',
                function(code, data)
                    if (code < 0) then
                        print('HTTP request failed')
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
    ssid  = 'Renault 1.9D',
    pwd   = 'renault19',
    auto  = false
})

wifi.sta.on('got_ip', init_wiattend)

wifi.start()
wifi.sta.connect()