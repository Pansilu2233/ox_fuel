-- QBOX Server Bridge
-- Provides QBOX-specific server functions for ox_fuel

local QBCore = exports['qbx_core']:GetCoreObject()

local QBoxBridge = {}

---Get QBOX player object
---@param source number Player server ID
---@return table|nil
function QBoxBridge.getPlayer(source)
    return QBCore.Functions.GetPlayer(source)
end

---Get player money
---@param source number Player server ID
---@param account? string Account type (cash, bank)
---@return number
function QBoxBridge.getMoney(source, account)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return 0 end
    
    account = account or 'cash'
    return player.PlayerData.money[account] or 0
end

---Remove money from player
---@param source number Player server ID
---@param amount number Amount to remove
---@param account? string Account type (cash, bank)
---@param reason? string Reason for removal
---@return boolean success
function QBoxBridge.removeMoney(source, amount, account, reason)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    account = account or 'cash'
    reason = reason or 'fuel-purchase'
    
    return player.Functions.RemoveMoney(account, amount, reason)
end

---Add money to player
---@param source number Player server ID
---@param amount number Amount to add
---@param account? string Account type (cash, bank)
---@param reason? string Reason for addition
---@return boolean success
function QBoxBridge.addMoney(source, amount, account, reason)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    account = account or 'cash'
    reason = reason or 'fuel-refund'
    
    return player.Functions.AddMoney(account, amount, reason)
end

---Get player citizen ID
---@param source number Player server ID
---@return string|nil
function QBoxBridge.getCitizenId(source)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        return player.PlayerData.citizenid
    end
    return nil
end

---Send notification to player
---@param source number Player server ID
---@param message string Notification message
---@param type? string Notification type
---@param duration? number Duration in ms
function QBoxBridge.notify(source, message, type, duration)
    type = type or 'primary'
    duration = duration or 5000
    
    TriggerClientEvent('QBCore:Notify', source, message, type, duration)
end

---Get player job
---@param source number Player server ID
---@return table|nil
function QBoxBridge.getJob(source)
    local player = QBCore.Functions.GetPlayer(source)
    if player then
        return player.PlayerData.job
    end
    return nil
end

---Check if player has permission/job
---@param source number Player server ID
---@param permission string Permission or job name to check
---@return boolean
function QBoxBridge.hasPermission(source, permission)
    local player = QBCore.Functions.GetPlayer(source)
    if not player then return false end
    
    -- Check if permission matches job name
    if player.PlayerData.job and player.PlayerData.job.name == permission then
        return true
    end
    
    -- Check QBX permissions if available
    if QBCore.Functions.HasPermission then
        return QBCore.Functions.HasPermission(source, permission)
    end
    
    return false
end

return QBoxBridge
