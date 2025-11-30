-- Bridge Client Module
-- Provides framework-agnostic client functions for ox_fuel

local config = require 'config'
local Framework = require 'bridge.framework'

local Bridge = {}

-- Framework-specific objects
local QBCore, ESX, Ox

-- Initialize framework objects based on detected framework
local function initFramework()
    local frameworkName = Framework.getName()
    
    if frameworkName == 'qbox' then
        QBCore = exports['qbx_core']:GetCoreObject()
    elseif frameworkName == 'qb-core' then
        QBCore = exports['qb-core']:GetCoreObject()
    elseif frameworkName == 'esx' then
        ESX = nil
        -- ESX uses callbacks - with timeout to prevent infinite loop
        local timeout = 50 -- 5 seconds max
        while ESX == nil and timeout > 0 do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            timeout = timeout - 1
            Wait(100)
        end
        if not ESX then
            print('[ox_fuel] Warning: ESX framework detected but could not initialize')
        end
    elseif frameworkName == 'ox_core' then
        Ox = require '@ox_core.lib.init'
    end
end

CreateThread(initFramework)

---Get player data on client
---@return table|nil
function Bridge.getPlayerData()
    local frameworkName = Framework.getName()
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        return QBCore.Functions.GetPlayerData()
    elseif frameworkName == 'esx' then
        return ESX.GetPlayerData()
    elseif frameworkName == 'ox_core' then
        return Ox.GetPlayerData()
    end
    
    return nil
end

---Get player money on client
---@param account? string Account type (cash, bank, etc.)
---@return number
function Bridge.getMoney(account)
    local frameworkName = Framework.getName()
    account = account or 'cash'
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        local playerData = QBCore.Functions.GetPlayerData()
        if playerData and playerData.money then
            if account == 'cash' then
                return playerData.money.cash or 0
            elseif account == 'bank' then
                return playerData.money.bank or 0
            end
        end
        return 0
    elseif frameworkName == 'esx' then
        local playerData = ESX.GetPlayerData()
        if playerData then
            if account == 'cash' then
                return playerData.money or 0
            elseif account == 'bank' then
                for _, acc in pairs(playerData.accounts or {}) do
                    if acc.name == 'bank' then
                        return acc.money or 0
                    end
                end
            end
        end
        return 0
    elseif frameworkName == 'ox_core' then
        local player = Ox.GetPlayer()
        if player then
            return player.get(account) or 0
        end
        return 0
    end
    
    -- Standalone - use ox_inventory
    return exports.ox_inventory:GetItemCount('money') or 0
end

---Show notification on client
---@param message string Notification message
---@param type? string Notification type (success, error, info, warning)
---@param duration? number Duration in milliseconds
function Bridge.notify(message, type, duration)
    local frameworkName = Framework.getName()
    type = type or 'info'
    duration = duration or 5000
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        QBCore.Functions.Notify(message, type, duration)
    elseif frameworkName == 'esx' then
        ESX.ShowNotification(message)
    else
        -- Use ox_lib for ox_core and standalone
        lib.notify({
            type = type,
            description = message,
            duration = duration
        })
    end
end

---Check if player is loaded/ready
---@return boolean
function Bridge.isPlayerLoaded()
    local frameworkName = Framework.getName()
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        local playerData = QBCore.Functions.GetPlayerData()
        return playerData ~= nil and playerData.citizenid ~= nil
    elseif frameworkName == 'esx' then
        local playerData = ESX.GetPlayerData()
        return playerData ~= nil and playerData.identifier ~= nil
    elseif frameworkName == 'ox_core' then
        local player = Ox.GetPlayer()
        return player ~= nil
    end
    
    -- Standalone - always loaded
    return true
end

---Get player job
---@return table|nil
function Bridge.getJob()
    local frameworkName = Framework.getName()
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        local playerData = QBCore.Functions.GetPlayerData()
        return playerData and playerData.job
    elseif frameworkName == 'esx' then
        local playerData = ESX.GetPlayerData()
        return playerData and playerData.job
    elseif frameworkName == 'ox_core' then
        local player = Ox.GetPlayer()
        if player then
            return player.getGroupByType('job')
        end
    end
    
    return nil
end

---Progress bar wrapper (uses ox_lib)
---@param options table Progress options
---@return boolean completed
function Bridge.progressBar(options)
    return lib.progressBar(options)
end

---Progress circle wrapper (uses ox_lib)
---@param options table Progress options
---@return boolean completed
function Bridge.progressCircle(options)
    return lib.progressCircle(options)
end

return Bridge
