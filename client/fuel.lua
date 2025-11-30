local config = require 'config'
local state = require 'client.state'
local utils = require 'client.utils'
local fuel = {}

-- Lazy load NUI module to avoid circular dependency
local NUI
local function getNUI()
	if not NUI then
		NUI = require 'client.nui'
	end
	return NUI
end

---@param vehState StateBag
---@param vehicle integer
---@param amount number
---@param replicate? boolean
function fuel.setFuel(vehState, vehicle, amount, replicate)
	if DoesEntityExist(vehicle) then
		amount = math.clamp(amount, 0, 100)

		SetVehicleFuelLevel(vehicle, amount)
		vehState:set('fuel', amount, replicate)
	end
end

function fuel.getPetrolCan(coords, refuel)
	TaskTurnPedToFaceCoord(cache.ped, coords.x, coords.y, coords.z, config.petrolCan.duration)
	Wait(500)

	if lib.progressCircle({
			duration = config.petrolCan.duration,
			useWhileDead = false,
			canCancel = true,
			disable = {
				move = true,
				car = true,
				combat = true,
			},
			anim = {
				dict = 'timetable@gardener@filling_can',
				clip = 'gar_ig_5_filling_can',
				flags = 49,
			}
		}) then
		if refuel and exports.ox_inventory:GetItemCount('WEAPON_PETROLCAN') then
			return TriggerServerEvent('ox_fuel:fuelCan', true, config.petrolCan.refillPrice)
		end

		TriggerServerEvent('ox_fuel:fuelCan', false, config.petrolCan.price)
	end

	ClearPedTasks(cache.ped)
end

-- Start fueling with classic ox_lib progress (fallback)
function fuel.startFuelingClassic(vehicle, isPump)
	local vehState = Entity(vehicle).state
	local fuelAmount = vehState.fuel or GetVehicleFuelLevel(vehicle)
	local duration = math.ceil((100 - fuelAmount) / config.refillValue) * config.refillTick
	local price, moneyAmount
	local durability = 0

	if 100 - fuelAmount < config.refillValue then
		return lib.notify({ type = 'error', description = locale('tank_full') })
	end

	if isPump then
		price = 0
		moneyAmount = utils.getMoney()

		if config.priceTick > moneyAmount then
			return lib.notify({
				type = 'error',
				description = locale('not_enough_money', config.priceTick)
			})
		end
	elseif not state.petrolCan then
		return lib.notify({ type = 'error', description = locale('petrolcan_not_equipped') })
	elseif state.petrolCan.metadata.ammo <= config.durabilityTick then
		return lib.notify({
			type = 'error',
			description = locale('petrolcan_not_enough_fuel')
		})
	end

	state.isFueling = true

	TaskTurnPedToFaceEntity(cache.ped, vehicle, duration)
	Wait(500)

	CreateThread(function()
		lib.progressCircle({
			duration = duration,
			useWhileDead = false,
			canCancel = true,
			disable = {
				move = true,
				car = true,
				combat = true,
			},
			anim = {
				dict = isPump and 'timetable@gardener@filling_can' or 'weapon@w_sp_jerrycan',
				clip = isPump and 'gar_ig_5_filling_can' or 'fire',
			},
		})

		state.isFueling = false
	end)

	while state.isFueling do
		if isPump then
			price += config.priceTick

			if price + config.priceTick >= moneyAmount and lib.progressActive() then
				lib.cancelProgress()
			end
		elseif state.petrolCan then
			durability += config.durabilityTick

			if durability >= state.petrolCan.metadata.ammo then
				lib.cancelProgress()
				durability = state.petrolCan.metadata.ammo
				break
			end
		else
			break
		end

		fuelAmount += config.refillValue

		if fuelAmount >= 100 then
			state.isFueling = false
			fuelAmount = 100.0
		end

		Wait(config.refillTick)
	end

	ClearPedTasks(cache.ped)

	if isPump then
		TriggerServerEvent('ox_fuel:pay', price, fuelAmount, NetworkGetNetworkIdFromEntity(vehicle))
	else
		TriggerServerEvent('ox_fuel:updateFuelCan', durability, NetworkGetNetworkIdFromEntity(vehicle), fuelAmount)
	end
end

-- Start fueling with NUI
function fuel.startFuelingNUI(vehicle, targetFuel)
	local nui = getNUI()
	local vehState = Entity(vehicle).state
	local startFuel = vehState.fuel or GetVehicleFuelLevel(vehicle)
	local fuelAmount = startFuel
	local price = 0
	local moneyAmount = utils.getMoney()

	if 100 - fuelAmount < config.refillValue then
		return lib.notify({ type = 'error', description = locale('tank_full') })
	end

	if config.priceTick > moneyAmount then
		return lib.notify({
			type = 'error',
			description = locale('not_enough_money', config.priceTick)
		})
	end

	state.isFueling = true

	TaskTurnPedToFaceEntity(cache.ped, vehicle, 1000)
	Wait(500)

	-- Show NUI progress
	nui.showRefuelProgress(fuelAmount, targetFuel)

	-- Play animation
	lib.requestAnimDict('timetable@gardener@filling_can')
	TaskPlayAnim(cache.ped, 'timetable@gardener@filling_can', 'gar_ig_5_filling_can', 8.0, 8.0, -1, 49, 0, false, false, false)

	while state.isFueling do
		price += config.priceTick

		if price + config.priceTick >= moneyAmount then
			state.isFueling = false
			break
		end

		fuelAmount += config.refillValue

		-- Update NUI progress
		nui.updateRefuelProgress(fuelAmount, targetFuel, price)

		if fuelAmount >= targetFuel then
			state.isFueling = false
			fuelAmount = targetFuel
		end

		Wait(config.refillTick)
	end

	ClearPedTasks(cache.ped)
	nui.hideRefuelProgress()

	-- Show HUD again if in vehicle
	if cache.seat == -1 and cache.vehicle then
		nui.showHUD(fuelAmount)
	end

	TriggerServerEvent('ox_fuel:pay', price, fuelAmount, NetworkGetNetworkIdFromEntity(vehicle))
end

-- Main fueling function - routes to NUI or classic based on config
function fuel.startFueling(vehicle, isPump)
	local nui = getNUI()
	
	-- For petrol can, always use classic method
	if not isPump then
		return fuel.startFuelingClassic(vehicle, isPump)
	end
	
	-- For pump, check if NUI is enabled and show interface
	if config.UseNUI and nui.isEnabled() then
		-- Show pump interface
		nui.showPumpInterface(vehicle)
	else
		-- Use classic ox_lib progress
		fuel.startFuelingClassic(vehicle, isPump)
	end
end

-- Event handler for NUI refuel confirmation
AddEventHandler('ox_fuel:startNUIRefuel', function(vehicle, targetFuel)
	if vehicle and DoesEntityExist(vehicle) then
		fuel.startFuelingNUI(vehicle, targetFuel)
	end
end)

return fuel
