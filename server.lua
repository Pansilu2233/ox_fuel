local config = require 'config'

if not config then return end

if config.versionCheck then lib.versionCheck('overextended/ox_fuel') end

local ox_inventory = exports.ox_inventory

-- Load bridge for framework support
local Bridge = require 'bridge.server'
local Framework = require 'bridge.framework'

-- Debug log for framework detection
if config.Debug then
	print(('[ox_fuel] Server initialized with framework: %s'):format(Framework.getName()))
end

local function setFuelState(netId, fuel)
	local vehicle = NetworkGetEntityFromNetworkId(netId)

	if vehicle == 0 or GetEntityType(vehicle) ~= 2 then
		return
	end

	local state = Entity(vehicle)?.state
	fuel = math.clamp(fuel, 0, 100)

	state:set('fuel', fuel, true)
end

---@param playerId number
---@param price number
---@return boolean?
local function defaultPaymentMethod(playerId, price)
	-- First try using the bridge for framework-specific money handling
	local frameworkName = Framework.getName()
	
	if frameworkName ~= 'standalone' then
		local playerMoney = Bridge.getMoney(playerId, 'cash')
		
		if playerMoney >= price then
			local success = Bridge.removeMoney(playerId, price, 'cash')
			if success then return true end
		end
		
		Bridge.notify(playerId, locale('not_enough_money', price - playerMoney), 'error')
		return false
	end
	
	-- Fallback to ox_inventory for standalone
	local success = ox_inventory:RemoveItem(playerId, 'money', price)

	if success then return true end

	local money = ox_inventory:GetItemCount(playerId, 'money')

	TriggerClientEvent('ox_lib:notify', playerId, {
		type = 'error',
		description = locale('not_enough_money', price - money)
	})
end

local payMoney = defaultPaymentMethod

exports('setPaymentMethod', function(fn)
	payMoney = fn or defaultPaymentMethod
end)

-- Export to get current framework name
exports('getFramework', function()
	return Framework.getName()
end)

-- Export bridge functions for external use
exports('getBridgeMoney', function(playerId, account)
	return Bridge.getMoney(playerId, account)
end)

exports('bridgeRemoveMoney', function(playerId, amount, account)
	return Bridge.removeMoney(playerId, amount, account)
end)

exports('bridgeAddMoney', function(playerId, amount, account)
	return Bridge.addMoney(playerId, amount, account)
end)

RegisterNetEvent('ox_fuel:pay', function(price, fuel, netid)
	assert(type(price) == 'number', ('Price expected a number, received %s'):format(type(price)))
	local source = source
	if not payMoney(source, price) then return end

	fuel = math.floor(fuel)
	setFuelState(netid, fuel)

	-- Use bridge notification for framework compatibility
	Bridge.notify(source, locale('fuel_success', fuel, price), 'success')
end)

RegisterNetEvent('ox_fuel:fuelCan', function(hasCan, price)
	local source = source
	if hasCan then
		local item = ox_inventory:GetCurrentWeapon(source)

		if not item or item.name ~= 'WEAPON_PETROLCAN' or not payMoney(source, price) then return end

		item.metadata.durability = 100
		item.metadata.ammo = 100

		ox_inventory:SetMetadata(source, item.slot, item.metadata)

		Bridge.notify(source, locale('petrolcan_refill', price), 'success')
	else
		if not ox_inventory:CanCarryItem(source, 'WEAPON_PETROLCAN', 1) then
			return Bridge.notify(source, locale('petrolcan_cannot_carry'), 'error')
		end

		if not payMoney(source, price) then return end

		ox_inventory:AddItem(source, 'WEAPON_PETROLCAN', 1)

		Bridge.notify(source, locale('petrolcan_buy', price), 'success')
	end
end)

RegisterNetEvent('ox_fuel:updateFuelCan', function(durability, netid, fuel)
	local source = source
	local item = ox_inventory:GetCurrentWeapon(source)

	if item and durability > 0 then
		durability = math.floor(item.metadata.durability - durability)
		item.metadata.durability = durability
		item.metadata.ammo = durability

		ox_inventory:SetMetadata(source, item.slot, item.metadata)
		setFuelState(netid, fuel)
	end

	-- player is sus?
end)
