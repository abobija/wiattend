local rc522 = require('rfid32')().init()

local timer = tmr.create()

timer:register(250, tmr.ALARM_AUTO, function()

    local tag = rc522.tag()

    if tag ~= nil then
        print( rc522.tag_hex(tag) )
    end
end)

timer:start()