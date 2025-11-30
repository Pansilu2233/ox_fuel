if not lib.checkDependency('ox_lib', '3.22.0', true) then return end
if not lib.checkDependency('ox_inventory', '2.30.0', true) then return end

return {
	-- Get notified when a new version releases
	versionCheck = true,

	-- Enable support for ox_target
	ox_target = false,

	/*
	* Show or hide gas stations blips
	* 0 - Hide all
	* 1 - Show nearest (5000ms interval check)
	* 2 - Show all
	*/
	showBlips = 2,

	-- Total duration (ex. 10% missing fuel): 10 / 0.25 * 250 = 10 seconds

	-- Fuel refill value (every 250msec add 0.25%)
	refillValue = 0.50,

	-- Fuel tick time (every 250 msec)
	refillTick = 250,

	-- Fuel cost (Added once every tick)
	priceTick = 5,

	-- Can durability loss per refillTick
	durabilityTick = 1.3,

	-- Enables fuel can
	petrolCan = {
		enabled = true,
		duration = 5000,
		price = 1000,
		refillPrice = 800,
	},

	---Modifies the fuel consumption rate of all vehicles - see [`SET_FUEL_CONSUMPTION_RATE_MULTIPLIER`](https://docs.fivem.net/natives/?_0x845F3E5C).
	globalFuelConsumptionRate = 10.0,

	-- Gas pump models
	pumpModels = {
		`prop_gas_pump_old2`,
		`prop_gas_pump_1a`,
		`prop_vintage_pump`,
		`prop_gas_pump_old3`,
		`prop_gas_pump_1c`,
		`prop_gas_pump_1b`,
		`prop_gas_pump_1d`,
	},

	-- UI Settings
	-- Enable/disable new NUI (fallback to ox_lib progress when false)
	UseNUI = true,

	-- Show fuel gauge HUD while driving
	ShowFuelHUD = true,

	-- UI position options: 'bottom-right', 'bottom-left', 'top-right', 'top-left'
	HUDPosition = 'bottom-right',

	-- Framework Settings
	-- 'auto' - Auto-detect framework
	-- 'qbox' - Force QBOX framework
	-- 'qb-core' - Force QB-Core framework
	-- 'esx' - Force ESX framework
	-- 'ox_core' - Force ox_core framework
	-- 'standalone' - Force standalone mode (ox_inventory only)
	Framework = 'auto',

	-- NUI Theme Settings
	UITheme = {
		primaryColor = '#00ff00',
		secondaryColor = '#ffffff',
		dangerColor = '#ff0000',
		warningColor = '#ffaa00',
	},

	-- Debug mode (prints framework detection info)
	Debug = false,
}
