local M = {}

M.load = function()
    if file.open("config.json") then
        local decoder = sjson:decoder()
        
        decoder:write(file.read())
        file.close()
        
        return decoder:result()
    end
    
    return nil
end

return M
