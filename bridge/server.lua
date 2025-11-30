-- Bridge Server Module
-- Provides framework-agnostic server functions for ox_fuel

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
        ESX = exports['es_extended']:getSharedObject()
    elseif frameworkName == 'ox_core' then
        Ox = require '@ox_core.lib.init'
    end
end

initFramework()

---Get player data based on framework
---@param source number Player server ID
---@return table|nil
function Bridge.getPlayer(source)
    local frameworkName = Framework.getName()
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        return QBCore.Functions.GetPlayer(source)
    elseif frameworkName == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif frameworkName == 'ox_core' then
        return Ox.GetPlayer(source)
    end
    
    return nil
end

---Get player money
---@param source number Player server ID
---@param account? string Account type (cash, bank, etc.)
---@return number
function Bridge.getMoney(source, account)
    local frameworkName = Framework.getName()
    account = account or 'cash'
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            if account == 'cash' then
                return player.PlayerData.money.cash or 0
            elseif account == 'bank' then
                return player.PlayerData.money.bank or 0
            end
        end
        return 0
    elseif frameworkName == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == 'cash' then
                return xPlayer.getMoney() or 0
            elseif account == 'bank' then
                return xPlayer.getAccount('bank').money or 0
            end
        end
        return 0
    elseif frameworkName == 'ox_core' then
        local player = Ox.GetPlayer(source)
        if player then
            -- ox_core uses accounts differently
            return player.get(account) or 0
        end
        return 0
    end
    
    -- Standalone - use ox_inventory
    return exports.ox_inventory:GetItemCount(source, 'money') or 0
end

---Remove money from player
---@param source number Player server ID
---@param amount number Amount to remove
---@param account? string Account type (cash, bank, etc.)
---@return boolean success
function Bridge.removeMoney(source, amount, account)
    local frameworkName = Framework.getName()
    account = account or 'cash'
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            if account == 'cash' then
                return player.Functions.RemoveMoney('cash', amount, 'fuel-purchase')
            elseif account == 'bank' then
                return player.Functions.RemoveMoney('bank', amount, 'fuel-purchase')
            end
        end
        return false
    elseif frameworkName == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == 'cash' then
                if xPlayer.getMoney() >= amount then
                    xPlayer.removeMoney(amount)
                    return true
                end
            elseif account == 'bank' then
                local bankAccount = xPlayer.getAccount('bank')
                if bankAccount and bankAccount.money >= amount then
                    xPlayer.removeAccountMoney('bank', amount)
                    return true
                end
            end
        end
        return false
    elseif frameworkName == 'ox_core' then
        local player = Ox.GetPlayer(source)
        if player then
            local currentMoney = player.get(account) or 0
            if currentMoney >= amount then
                player.set(account, currentMoney - amount)
                return true
            end
        end
        return false
    end
    
    -- Standalone - use ox_inventory
    local success = exports.ox_inventory:RemoveItem(source, 'money', amount)
    return success and true or false
end

---Add money to player
---@param source number Player server ID
---@param amount number Amount to add
---@param account? string Account type (cash, bank, etc.)
---@return boolean success
function Bridge.addMoney(source, amount, account)
    local frameworkName = Framework.getName()
    account = account or 'cash'
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            if account == 'cash' then
                return player.Functions.AddMoney('cash', amount, 'fuel-refund')
            elseif account == 'bank' then
                return player.Functions.AddMoney('bank', amount, 'fuel-refund')
            end
        end
        return false
    elseif frameworkName == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            if account == 'cash' then
                xPlayer.addMoney(amount)
                return true
            elseif account == 'bank' then
                xPlayer.addAccountMoney('bank', amount)
                return true
            end
        end
        return false
    elseif frameworkName == 'ox_core' then
        local player = Ox.GetPlayer(source)
        if player then
            local currentMoney = player.get(account) or 0
            player.set(account, currentMoney + amount)
            return true
        end
        return false
    end
    
    -- Standalone - use ox_inventory
    return exports.ox_inventory:AddItem(source, 'money', amount) ~= nil
end

---Send notification to player
---@param source number Player server ID
---@param message string Notification message
---@param type? string Notification type (success, error, info)
function Bridge.notify(source, message, type)
    local frameworkName = Framework.getName()
    type = type or 'info'
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        TriggerClientEvent('QBCore:Notify', source, message, type)
    elseif frameworkName == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    else
        -- Use ox_lib for ox_core and standalone
        TriggerClientEvent('ox_lib:notify', source, {
            type = type,
            description = message
        })
    end
end

---Get player identifier
---@param source number Player server ID
---@return string|nil
function Bridge.getIdentifier(source)
    local frameworkName = Framework.getName()
    
    if frameworkName == 'qbox' or frameworkName == 'qb-core' then
        local player = QBCore.Functions.GetPlayer(source)
        if player then
            return player.PlayerData.citizenid
        end
    elseif frameworkName == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.getIdentifier()
        end
    elseif frameworkName == 'ox_core' then
        local player = Ox.GetPlayer(source)
        if player then
            return player.stateId or player.odid
        end
    end
    
    -- Fallback to license
    for _, v in pairs(GetPlayerIdentifiers(source)) do
        if string.sub(v, 1, 8) == 'license:' then
            return v
        end
    end
    
    return nil
end

---Check if player has item
---@param source number Player server ID
---@param item string Item name
---@param count? number Required count (default 1)
---@return boolean
function Bridge.hasItem(source, item, count)
    count = count or 1
    
    -- Always use ox_inventory for items as it's a dependency
    local itemCount = exports.ox_inventory:GetItemCount(source, item)
    return itemCount >= count
end

---Remove item from player
---@param source number Player server ID
---@param item string Item name
---@param count? number Amount to remove (default 1)
---@return boolean
function Bridge.removeItem(source, item, count)
    count = count or 1
    local success = exports.ox_inventory:RemoveItem(source, item, count)
    return success and true or false
end

---Add item to player
---@param source number Player server ID
---@param item string Item name
---@param count? number Amount to add (default 1)
---@param metadata? table Item metadata
---@return boolean
function Bridge.addItem(source, item, count, metadata)
    count = count or 1
    local success = exports.ox_inventory:AddItem(source, item, count, metadata)
    return success and true or false
end

return Bridge
