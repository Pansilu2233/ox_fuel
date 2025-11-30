-- QBOX Client Bridge
-- Provides QBOX-specific client functions for ox_fuel

local QBCore = exports['qbx_core']:GetCoreObject()

local QBoxBridge = {}

---Get player data
---@return table|nil
function QBoxBridge.getPlayerData()
    return QBCore.Functions.GetPlayerData()
end

---Get player money
---@param account? string Account type (cash, bank)
---@return number
function QBoxBridge.getMoney(account)
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.money then return 0 end
    
    account = account or 'cash'
    return playerData.money[account] or 0
end

---Get player citizen ID
---@return string|nil
function QBoxBridge.getCitizenId()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData then
        return playerData.citizenid
    end
    return nil
end

---Show notification
---@param message string Notification message
---@param type? string Notification type (success, error, primary, etc.)
---@param duration? number Duration in ms
function QBoxBridge.notify(message, type, duration)
    type = type or 'primary'
    duration = duration or 5000
    
    QBCore.Functions.Notify(message, type, duration)
end

---Check if player is logged in/loaded
---@return boolean
function QBoxBridge.isLoggedIn()
    local playerData = QBCore.Functions.GetPlayerData()
    return playerData ~= nil and playerData.citizenid ~= nil
end

---Get player job
---@return table|nil
function QBoxBridge.getJob()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData then
        return playerData.job
    end
    return nil
end

---Get player gang
---@return table|nil
function QBoxBridge.getGang()
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData then
        return playerData.gang
    end
    return nil
end

---Check if player has job
---@param jobName string Job name to check
---@param onDuty? boolean Check if on duty (optional)
---@return boolean
function QBoxBridge.hasJob(jobName, onDuty)
    local playerData = QBCore.Functions.GetPlayerData()
    if not playerData or not playerData.job then return false end
    
    if playerData.job.name ~= jobName then return false end
    
    if onDuty ~= nil then
        return playerData.job.onduty == onDuty
    end
    
    return true
end

---Get player metadata
---@param key string Metadata key
---@return any
function QBoxBridge.getMetadata(key)
    local playerData = QBCore.Functions.GetPlayerData()
    if playerData and playerData.metadata then
        return playerData.metadata[key]
    end
    return nil
end

-- Register QBOX player data update handler
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Player loaded event - can be used for initialization
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    -- Player unloaded event - can be used for cleanup
end)

return QBoxBridge
