local M = {}

local channel = nil
local timer = nil 

local success_freq = 1300
local success_duty = 400

local error_freq = 300
local error_duty = 400

M.success = function()
    channel:setfreq(success_freq)
    channel:setduty(success_duty)
    channel:resume()
    
    timer:start()
end

M.error = function()
    channel:setfreq(error_freq)
    channel:setduty(error_duty)
    channel:resume()

    timer:start()
end

--[[
    @config - {
        gpio
    }
]]
return function(config)
    channel = ledc.newChannel({
        gpio      = config.gpio,
        bits      = ledc.TIMER_13_BIT,
        mode      = ledc.HIGH_SPEED,
        timer     = ledc.TIMER_0,
        channel   = ledc.CHANNEL_0,
        frequency = success_freq,
        duty      = success_duty
    })

    channel:stop(ledc.IDLE_LOW)
    
    timer = tmr:create()
    
    timer:register(250, tmr.ALARM_SEMI, function (t)
        channel:stop(ledc.IDLE_LOW)
    end)

    return M
end