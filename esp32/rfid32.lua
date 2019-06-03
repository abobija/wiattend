-- Title        : RFID32
-- Author       : Alija Bobija (https://abobija.com)
-- Description  : Library for interfacing ESP32 with MFRC522
-- Dependencies : > spi
--                > bit
--                > tmr

local M = {}

local function hex(arg)
  return string.format("0x%02X", arg)
end

local function extend(tbl, with)
    if with ~= nil then
        for k, v in pairs(with) do
            if tbl[k] == nil then
                tbl[k] = with[k]
            end
        end
    end

    return tbl
end

M.write = function(addr, val)
    M._device:transfer(string.char(
        bit.band(bit.lshift(addr, 1), 0x7E),
        val
    ))
end

M.read = function(addr)
    M._device:transfer(string.char(
        bit.bor(bit.band(bit.lshift(addr, 1), 0x7E), 0x80)
    ))
    
    return M._device:transfer(string.char(0xFF)):byte(1)
end

local function rc522_set_bitmask(address, mask)
    M.write(address, bit.bor(M.read(address), mask))
end


local function rc522_clear_bitmask(address, mask)
    M.write(address, bit.band(M.read(address), bit.bnot(mask)))
end

local function rc522_antenna_on()
    if bit.bnot(bit.band(M.read(0x14), 0x03)) then
        rc522_set_bitmask(0x14, 0x03)
    end
end

function rc522_firmware()
  return M.read(0x37)
end

M.card_write = function(command, data)
    local back_data = {}
    local back_length = 0
    local err = false
    local irq = 0x00
    local irq_wait = 0x00
    local last_bits = 0
    local n = 0

    if command == 0x0E then
        irq = 0x12
        irq_wait = 0x10
    end
    
    if command == 0x0C then
        irq = 0x77
        irq_wait = 0x30
    end

    M.write(0x02, bit.bor(irq, 0x80))
    rc522_clear_bitmask(0x04, 0x80)
    rc522_set_bitmask(0x0A, 0x80)
    M.write(0x01, 0x00)

    for i,v in ipairs(data) do
        M.write(0x09, data[i])
    end

    M.write(0x01, command)
    
    if command == 0x0C then
        rc522_set_bitmask(0x0D, 0x80)
    end
    
    local i = 1000
    
    while true do
        n = M.read(0x04)
        i = i - 1
        if  not ((i ~= 0) and (bit.band(n, 0x01) == 0) and (bit.band(n, irq_wait) == 0)) then
            break
        end
    end
    
    rc522_clear_bitmask(0x0D, 0x80)

    if (i ~= 0) then
        if bit.band(M.read(0x06), 0x1B) == 0x00 then
            err = false
            
            if (command == 0x0C) then
                n = M.read(0x0A)
                last_bits = bit.band(M.read(0x0C),0x07)
                if last_bits ~= 0 then
                    back_length = (n - 1) * 8 + last_bits
                else
                    back_length = n * 8
                end

                if (n == 0) then
                    n = 1
                end 

                if (n > 16) then
                    n = 16
                end
                
                for i=1, n do
                    back_data[i] = M.read(0x09)
                end
              end
        else
            err = true
        end
    end

    return  err, back_data, back_length 
end

M.request = function()
    local req_mode = { 0x26 }
    local err = true
    local back_bits = 0
    local back_data = nil

    M.write(0x0D, 0x07)
    err, back_data, back_bits = M.card_write(0x0C, req_mode)

    if err or (back_bits ~= 0x10) then
        return false, nil
     end

    return true, back_data
end

M.anticoll = function()
    local back_data = {}
    local serial_number = {  0x93, 0x20 }
    local err = nil
    local back_bits = nil

    local serial_number_check = 0
    
    M.write(0x0D, 0x00)
    
    err, back_data, back_bits = M.card_write(0x0C, serial_number)
    
    if not err then
        if table.maxn(back_data) == 5 then
            for i, v in ipairs(back_data) do
                serial_number_check = bit.bxor(serial_number_check, back_data[i])
            end 
            
            if serial_number_check ~= back_data[4] then
                err = true
            end
        else
            err = true
        end
    end
    
    return error, back_data
end

M.calculate_crc = function(data)
    rc522_clear_bitmask(0x05, 0x04)
    rc522_set_bitmask(0x0A, 0x80)

    for i,v in ipairs(data) do
        M.write(0x09, data[i])
    end
    
    M.write(0x01, 0x03)

    local i = 255
    local n = 0
    
    while true do
        n = M.read(0x05)
        i = i - 1
        if not ((i ~= 0) and not bit.band(n, 0x04)) then
            break
        end
    end

    return { M.read(0x22), M.read(0x21) }
end

M.serial_no_hex = function(sn)
    local _hex = ''

    for _, b in pairs(sn) do
        _hex = _hex .. hex(b) .. ' '
    end

    return _hex
end

M.tag = function(serial_no)
    local self = {
        sn = serial_no
    }

    self.hex = function()
        return M.serial_no_hex(self.sn)
    end

    return self
end

M.get_tag = function()
    if M.request() == true then
        local err = nil
        local serial_no = nil
        
        err, serial_no = M.anticoll()
        
        local buf = {}
        
        buf[1] = 0x50
        buf[2] = 0
        
        crc = M.calculate_crc(buf)
        
        table.insert(buf, crc[1])
        table.insert(buf, crc[2])
        
        M.card_write(0x0C, buf)
        rc522_clear_bitmask(0x08, 0x08)

        if #serial_no == 5 then
            return M.tag(serial_no)
        end
    end

    return nil
end

M.scan = function(opts)
    local options = extend({
        interval       = 125,
        pause_interval = 1000,
        got_tag        = nil
    }, opts)

    local _timer = tmr.create()

    _timer:register(options.interval, tmr.ALARM_SEMI, function()
        local _tag = M.get_tag()

        
        if _tag == nil then
            _timer:interval(options.interval)
        else
            _timer:interval(options.pause_interval)
            
            options.got_tag(_tag)
        end
        
        _timer:start()
    end)
    
    _timer:start()

    return M
end

local function rc522_spi_init() 
    M._master = spi.master(spi.VSPI, {
        sclk = M.config.pin_clk,
        mosi = M.config.pin_mosi,
        miso = M.config.pin_miso
    }, 0)

    M._device = M._master:device({
        cs         = M.config.pin_sda,
        mode       = 0,
        freq       = 5000000,
        halfduplex = false
    })
end

M.init = function() 
    rc522_spi_init()

    M.write(0x01, 0x0F)
    M.write(0x2A, 0x8D)
    M.write(0x2B, 0x3E)
    M.write(0x2D, 0x1E)
    M.write(0x2C, 0x00)
    M.write(0x15, 0x40)
    M.write(0x11, 0x3D)

    rc522_antenna_on()

    print('RC522 Firmware:', hex(rc522_firmware()))

    return M
end

return function(config)
    M.config = extend({
        pin_sda  = nil,
        pin_clk  = nil,
        pin_miso = nil,
        pin_mosi = nil
    }, config)
    
    return M
end