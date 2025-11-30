-- NUI Module for ox_fuel
-- Handles NUI callbacks and UI state management

local config = require 'config'
local state = require 'client.state'

local NUI = {}

-- NUI state
NUI.isHudVisible = false
NUI.isPumpOpen = false
NUI.isRefueling = false
NUI.currentVehicle = nil
NUI.startFuel = 0

-- Check if NUI is enabled
function NUI.isEnabled()
    return config.UseNUI == true
end

-- Update theme from config
function NUI.updateTheme()
    if not NUI.isEnabled() then return end
    
    SendNUIMessage({
        action = 'updateTheme',
        theme = config.UITheme
    })
end

-- Show fuel HUD while driving
function NUI.showHUD(fuelLevel)
    if not NUI.isEnabled() or not config.ShowFuelHUD then return end
    
    NUI.isHudVisible = true
    SendNUIMessage({
        action = 'showHUD',
        fuel = fuelLevel,
        position = config.HUDPosition or 'bottom-right'
    })
end

-- Hide fuel HUD
function NUI.hideHUD()
    if not NUI.isEnabled() then return end
    
    NUI.isHudVisible = false
    SendNUIMessage({
        action = 'hideHUD'
    })
end

-- Update fuel HUD value
function NUI.updateHUD(fuelLevel)
    if not NUI.isEnabled() or not NUI.isHudVisible then return end
    
    SendNUIMessage({
        action = 'updateHUD',
        fuel = fuelLevel
    })
end

-- Show pump interface
function NUI.showPumpInterface(vehicle)
    if not NUI.isEnabled() then return false end
    
    local vehState = Entity(vehicle).state
    local currentFuel = vehState.fuel or GetVehicleFuelLevel(vehicle)
    
    NUI.isPumpOpen = true
    NUI.currentVehicle = vehicle
    NUI.startFuel = currentFuel
    
    -- Hide HUD when pump interface is open
    NUI.hideHUD()
    
    SendNUIMessage({
        action = 'showPumpInterface',
        currentFuel = currentFuel,
        targetFuel = 100,
        priceTick = config.priceTick,
        refillValue = config.refillValue,
        theme = config.UITheme
    })
    
    SetNuiFocus(true, true)
    return true
end

-- Hide pump interface
function NUI.hidePumpInterface()
    if not NUI.isEnabled() then return end
    
    NUI.isPumpOpen = false
    NUI.currentVehicle = nil
    
    SendNUIMessage({
        action = 'hidePumpInterface'
    })
    
    SetNuiFocus(false, false)
end

-- Show refueling progress
function NUI.showRefuelProgress(currentFuel, targetFuel)
    if not NUI.isEnabled() then return false end
    
    NUI.isRefueling = true
    
    SendNUIMessage({
        action = 'showRefuelProgress',
        currentFuel = currentFuel,
        targetFuel = targetFuel,
        startFuel = NUI.startFuel
    })
    
    SetNuiFocus(false, false)
    return true
end

-- Update refueling progress
function NUI.updateRefuelProgress(currentFuel, targetFuel, price)
    if not NUI.isEnabled() or not NUI.isRefueling then return end
    
    SendNUIMessage({
        action = 'updateRefuelProgress',
        currentFuel = currentFuel,
        targetFuel = targetFuel,
        price = price,
        startFuel = NUI.startFuel
    })
end

-- Hide refueling progress
function NUI.hideRefuelProgress()
    if not NUI.isEnabled() then return end
    
    NUI.isRefueling = false
    
    SendNUIMessage({
        action = 'hideRefuelProgress'
    })
end

-- Hide all NUI elements
function NUI.hideAll()
    if not NUI.isEnabled() then return end
    
    NUI.isHudVisible = false
    NUI.isPumpOpen = false
    NUI.isRefueling = false
    NUI.currentVehicle = nil
    
    SendNUIMessage({
        action = 'hideAll'
    })
    
    SetNuiFocus(false, false)
end

-- NUI Callbacks
RegisterNUICallback('closePump', function(data, cb)
    NUI.hidePumpInterface()
    cb('ok')
end)

RegisterNUICallback('confirmRefuel', function(data, cb)
    if NUI.isPumpOpen and NUI.currentVehicle then
        local vehicle = NUI.currentVehicle
        local targetFuel = data.targetFuel or 100
        
        NUI.hidePumpInterface()
        
        -- Trigger refueling with NUI
        TriggerEvent('ox_fuel:startNUIRefuel', vehicle, targetFuel)
    end
    cb('ok')
end)

RegisterNUICallback('cancelRefuel', function(data, cb)
    if NUI.isRefueling then
        state.isFueling = false
        NUI.hideRefuelProgress()
        
        -- Show HUD again if in vehicle
        if cache.seat == -1 and cache.vehicle then
            local vehState = Entity(cache.vehicle).state
            NUI.showHUD(vehState.fuel or GetVehicleFuelLevel(cache.vehicle))
        end
    end
    cb('ok')
end)

-- Initialize theme on resource start
CreateThread(function()
    Wait(500)
    NUI.updateTheme()
end)

return NUI
