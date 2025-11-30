-- Bridge Framework Detection and Unified API
-- Detects and provides abstraction for: QBOX, QB-Core, ESX, ox_core, or standalone

local config = require 'config'

---@class Framework
---@field name string
---@field detected boolean
local Framework = {
    name = 'standalone',
    detected = false
}

-- Framework detection
local function detectFramework()
    local configFramework = config.Framework or 'auto'
    
    if configFramework ~= 'auto' then
        Framework.name = configFramework
        Framework.detected = true
        return
    end
    
    -- Auto-detect framework
    if GetResourceState('qbx_core') == 'started' then
        Framework.name = 'qbox'
        Framework.detected = true
    elseif GetResourceState('qb-core') == 'started' then
        Framework.name = 'qb-core'
        Framework.detected = true
    elseif GetResourceState('es_extended') == 'started' then
        Framework.name = 'esx'
        Framework.detected = true
    elseif GetResourceState('ox_core') == 'started' then
        Framework.name = 'ox_core'
        Framework.detected = true
    else
        Framework.name = 'standalone'
        Framework.detected = true
    end
end

detectFramework()

-- Export framework info
function Framework.getName()
    return Framework.name
end

function Framework.isDetected()
    return Framework.detected
end

-- Debug log
if config.Debug then
    print(('[ox_fuel] Framework detected: %s'):format(Framework.name))
end

return Framework
