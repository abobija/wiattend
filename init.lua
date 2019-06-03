require('rfid32')({
        pin_sda  = 22,
        pin_clk  = 19,
        pin_miso = 25,
        pin_mosi = 23
    })
    .init()
    .scan({
        got_tag = function(tag, rfid)
            print( tag.hex() )
        end
    })
