local config = require 'config'

if not config then return end

SetFuelConsumptionState(true)
SetFuelConsumptionRateMultiplier(config.globalFuelConsumptionRate)

AddTextEntry('fuelHelpText', locale('fuel_help'))
AddTextEntry('petrolcanHelpText', locale('petrolcan_help'))
AddTextEntry('fuelLeaveVehicleText', locale('leave_vehicle'))
AddTextEntry('ox_fuel_station', locale('fuel_station_blip'))

local utils = require 'client.utils'
local state = require 'client.state'
local fuel  = require 'client.fuel'

-- Lazy load NUI module
local NUI
local function getNUI()
	if not NUI then
		NUI = require 'client.nui'
	end
	return NUI
end

require 'client.stations'

local function startDrivingVehicle()
	local vehicle = cache.vehicle

	if not DoesVehicleUseFuel(vehicle) then return end

	local vehState = Entity(vehicle).state

	if not vehState.fuel then
		vehState:set('fuel', GetVehicleFuelLevel(vehicle), true)
		while not vehState.fuel do Wait(0) end
	end

	SetVehicleFuelLevel(vehicle, vehState.fuel)

	-- Show fuel HUD when entering vehicle (if NUI enabled)
	local nui = getNUI()
	if config.UseNUI and config.ShowFuelHUD then
		nui.showHUD(vehState.fuel)
	end

	local fuelTick = 0
	local hudUpdateTick = 0

	while cache.seat == -1 do
		if GetIsVehicleEngineRunning(vehicle) then
			if not DoesEntityExist(vehicle) then
				-- Hide HUD when vehicle no longer exists
				if config.UseNUI and config.ShowFuelHUD then
					nui.hideHUD()
				end
				return
			end
			SetFuelConsumptionRateMultiplier(config.globalFuelConsumptionRate)

			local fuelAmount = tonumber(vehState.fuel)
			local newFuel = GetVehicleFuelLevel(vehicle)
			if fuelAmount > 0 then
				if GetVehiclePetrolTankHealth(vehicle) < 700 then
					newFuel -= math.random(10, 20) * 0.01
				end

				if fuelAmount ~= newFuel then
					if fuelTick == 15 then
						fuelTick = 0
					end

					fuel.setFuel(vehState, vehicle, newFuel, fuelTick == 0)
					fuelTick += 1

					-- Update HUD every 3 seconds to reduce overhead
					hudUpdateTick += 1
					if config.UseNUI and config.ShowFuelHUD and hudUpdateTick >= 3 then
						nui.updateHUD(newFuel)
						hudUpdateTick = 0
					end
				end
			end
		else
			if not DoesEntityExist(vehicle) then
				-- Hide HUD when vehicle no longer exists
				if config.UseNUI and config.ShowFuelHUD then
					nui.hideHUD()
				end
				return
			end
			SetFuelConsumptionRateMultiplier(0.0)
		end
		Wait(1000)
	end

	fuel.setFuel(vehState, vehicle, vehState.fuel, true)

	-- Hide HUD when leaving vehicle
	if config.UseNUI and config.ShowFuelHUD then
		nui.hideHUD()
	end
end

if cache.seat == -1 then CreateThread(startDrivingVehicle) end

lib.onCache('seat', function(seat)
	if cache.vehicle then
		state.lastVehicle = cache.vehicle
	end

	if seat == -1 then
		SetTimeout(0, startDrivingVehicle)
	else
		-- Hide HUD when not in driver seat
		local nui = getNUI()
		if config.UseNUI and config.ShowFuelHUD then
			nui.hideHUD()
		end
	end
end)

if config.ox_target then return require 'client.target' end

RegisterCommand('startfueling', function()
	local nui = getNUI()

	-- Check if NUI pump interface is open - if so, close it
	if config.UseNUI and nui.isPumpOpen then
		nui.hidePumpInterface()
		return
	end

	if state.isFueling or cache.vehicle or lib.progressActive() then return end

	local petrolCan = config.petrolCan.enabled and GetSelectedPedWeapon(cache.ped) == `WEAPON_PETROLCAN`
	local playerCoords = GetEntityCoords(cache.ped)
	local nearestPump = state.nearestPump

	if nearestPump then
		local moneyAmount = utils.getMoney()

		if petrolCan and moneyAmount >= config.petrolCan.refillPrice then
			return fuel.getPetrolCan(nearestPump, true)
		end

		local vehicleInRange = state.lastVehicle and #(GetEntityCoords(state.lastVehicle) - playerCoords) <= 3

		if not vehicleInRange then
			if not config.petrolCan.enabled then return end

			if moneyAmount >= config.petrolCan.price then
				return fuel.getPetrolCan(nearestPump)
			end

			return lib.notify({ type = 'error', description = locale('petrolcan_cannot_afford') })
		elseif moneyAmount >= config.priceTick then
			return fuel.startFueling(state.lastVehicle, true)
		else
			return lib.notify({ type = 'error', description = locale('refuel_cannot_afford') })
		end

		return lib.notify({ type = 'error', description = locale('vehicle_far') })
	elseif petrolCan then
		local vehicle = utils.getVehicleInFront()

		if vehicle and DoesVehicleUseFuel(vehicle) then

			local boneIndex = utils.getVehiclePetrolCapBoneIndex(vehicle)
			local fuelcapPosition = boneIndex and GetWorldPositionOfEntityBone(vehicle, boneIndex)

			if fuelcapPosition and #(playerCoords - fuelcapPosition) < 1.8 then
				return fuel.startFueling(vehicle, false)
			end

			return lib.notify({ type = 'error', description = locale('vehicle_far') })
		end
	end
end)

RegisterKeyMapping('startfueling', 'Fuel vehicle', 'keyboard', 'e')
TriggerEvent('chat:removeSuggestion', '/startfueling')

-- Hide all NUI on resource stop
AddEventHandler('onResourceStop', function(resourceName)
	if GetCurrentResourceName() == resourceName then
		local nui = getNUI()
		if config.UseNUI then
			nui.hideAll()
		end
	end
end)
