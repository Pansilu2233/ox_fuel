// OX Fuel NUI Script
(function() {
    'use strict';

    // State management
    const state = {
        currentFuel: 0,
        targetFuel: 100,
        maxFuel: 100,
        priceTick: 5,
        refillValue: 0.5,
        isRefueling: false,
        hudPosition: 'bottom-right',
        theme: {
            primaryColor: '#00ff00',
            secondaryColor: '#ffffff',
            dangerColor: '#ff0000',
            warningColor: '#ffaa00'
        }
    };

    // DOM Elements
    const elements = {
        // HUD
        fuelHud: document.getElementById('fuel-hud'),
        hudValue: document.querySelector('.hud-value'),
        hudRingProgress: document.querySelector('.hud-ring-progress'),
        
        // Pump Interface
        pumpInterface: document.getElementById('pump-interface'),
        closeBtn: document.getElementById('close-btn'),
        currentFuelDisplay: document.querySelector('.current-fuel'),
        targetFuelDisplay: document.querySelector('.target-fuel'),
        gaugeProgress: document.querySelector('.gauge-progress'),
        gaugeTarget: document.querySelector('.gauge-target'),
        fuelSlider: document.getElementById('fuel-slider'),
        sliderFill: document.getElementById('slider-fill'),
        fuelMinus: document.getElementById('fuel-minus'),
        fuelPlus: document.getElementById('fuel-plus'),
        fuelToAdd: document.getElementById('fuel-to-add'),
        totalCost: document.getElementById('total-cost'),
        cancelBtn: document.getElementById('cancel-btn'),
        confirmBtn: document.getElementById('confirm-btn'),
        
        // Progress
        refuelProgress: document.getElementById('refuel-progress'),
        progressBar: document.getElementById('progress-bar'),
        progressFuel: document.getElementById('progress-fuel'),
        progressCost: document.getElementById('progress-cost')
    };

    // Utility functions
    function clamp(value, min, max) {
        return Math.min(Math.max(value, min), max);
    }

    function formatMoney(amount) {
        return '$' + amount.toLocaleString();
    }

    function calculateCost(fuelToAdd) {
        // Calculate cost based on ticks needed
        const ticks = Math.ceil(fuelToAdd / state.refillValue);
        return ticks * state.priceTick;
    }

    function getFuelColor(percentage) {
        if (percentage <= 25) return 'danger';
        if (percentage <= 50) return 'warning';
        return '';
    }

    function updateTheme(theme) {
        if (!theme) return;
        
        const root = document.documentElement;
        if (theme.primaryColor) root.style.setProperty('--primary-color', theme.primaryColor);
        if (theme.secondaryColor) root.style.setProperty('--secondary-color', theme.secondaryColor);
        if (theme.dangerColor) root.style.setProperty('--danger-color', theme.dangerColor);
        if (theme.warningColor) root.style.setProperty('--warning-color', theme.warningColor);
        
        state.theme = { ...state.theme, ...theme };
    }

    // HUD Functions
    function updateHUD(fuelLevel) {
        state.currentFuel = fuelLevel;
        
        // Update value text
        elements.hudValue.textContent = Math.round(fuelLevel);
        
        // Update ring progress (283 is circumference of circle with r=45)
        const circumference = 283;
        const offset = circumference - (fuelLevel / 100) * circumference;
        elements.hudRingProgress.style.strokeDashoffset = offset;
        
        // Update color based on fuel level
        const colorClass = getFuelColor(fuelLevel);
        elements.hudRingProgress.classList.remove('warning', 'danger');
        if (colorClass) {
            elements.hudRingProgress.classList.add(colorClass);
        }
    }

    function showHUD(position) {
        if (position) {
            state.hudPosition = position;
            elements.fuelHud.classList.remove('position-bottom-left', 'position-top-right', 'position-top-left');
            if (position !== 'bottom-right') {
                elements.fuelHud.classList.add('position-' + position);
            }
        }
        elements.fuelHud.classList.remove('hidden');
    }

    function hideHUD() {
        elements.fuelHud.classList.add('hidden');
    }

    // Pump Interface Functions
    function updateGauge() {
        const circumference = 534; // 2 * PI * 85
        
        // Current fuel progress
        const currentOffset = circumference - (state.currentFuel / 100) * circumference;
        elements.gaugeProgress.style.strokeDashoffset = currentOffset;
        
        // Target fuel indicator
        const targetOffset = circumference - (state.targetFuel / 100) * circumference;
        elements.gaugeTarget.style.strokeDashoffset = targetOffset;
        
        // Update color based on current fuel
        const colorClass = getFuelColor(state.currentFuel);
        elements.gaugeProgress.classList.remove('warning', 'danger');
        if (colorClass) {
            elements.gaugeProgress.classList.add(colorClass);
        }
        
        // Update displays
        elements.currentFuelDisplay.textContent = Math.round(state.currentFuel);
        elements.targetFuelDisplay.textContent = Math.round(state.targetFuel);
        
        // Update slider
        elements.fuelSlider.value = state.targetFuel;
        elements.fuelSlider.min = Math.ceil(state.currentFuel);
        const sliderPercent = ((state.targetFuel - state.currentFuel) / (100 - state.currentFuel)) * 100;
        elements.sliderFill.style.width = clamp(sliderPercent, 0, 100) + '%';
        
        // Update price display
        const fuelToAdd = state.targetFuel - state.currentFuel;
        elements.fuelToAdd.textContent = Math.round(fuelToAdd) + '%';
        elements.totalCost.textContent = formatMoney(calculateCost(fuelToAdd));
        
        // Disable confirm if no fuel to add
        elements.confirmBtn.disabled = fuelToAdd <= 0;
    }

    function showPumpInterface(data) {
        state.currentFuel = data.currentFuel || 0;
        state.targetFuel = data.targetFuel || 100;
        state.maxFuel = 100;
        state.priceTick = data.priceTick || 5;
        state.refillValue = data.refillValue || 0.5;
        
        if (data.theme) {
            updateTheme(data.theme);
        }
        
        elements.fuelSlider.min = Math.ceil(state.currentFuel);
        elements.fuelSlider.max = state.maxFuel;
        elements.fuelSlider.value = state.targetFuel;
        
        updateGauge();
        elements.pumpInterface.classList.remove('hidden');
        hideHUD();
    }

    function hidePumpInterface() {
        elements.pumpInterface.classList.add('hidden');
    }

    // Refueling Progress Functions
    function showRefuelProgress(data) {
        state.isRefueling = true;
        elements.progressBar.style.width = '0%';
        elements.progressFuel.textContent = Math.round(data.currentFuel || state.currentFuel) + '%';
        elements.progressCost.textContent = formatMoney(0);
        elements.refuelProgress.classList.remove('hidden');
        hidePumpInterface();
    }

    function updateRefuelProgress(data) {
        const currentFuel = data.currentFuel || 0;
        const targetFuel = data.targetFuel || 100;
        const price = data.price || 0;
        
        const startFuel = data.startFuel || state.currentFuel;
        const progress = ((currentFuel - startFuel) / (targetFuel - startFuel)) * 100;
        
        elements.progressBar.style.width = clamp(progress, 0, 100) + '%';
        elements.progressFuel.textContent = Math.round(currentFuel) + '%';
        elements.progressCost.textContent = formatMoney(price);
    }

    function hideRefuelProgress() {
        state.isRefueling = false;
        elements.refuelProgress.classList.add('hidden');
    }

    // NUI Message Handler
    window.addEventListener('message', function(event) {
        const data = event.data;
        
        switch (data.action) {
            // HUD Actions
            case 'showHUD':
                showHUD(data.position);
                if (data.fuel !== undefined) {
                    updateHUD(data.fuel);
                }
                break;
                
            case 'hideHUD':
                hideHUD();
                break;
                
            case 'updateHUD':
                updateHUD(data.fuel);
                break;
                
            // Pump Interface Actions
            case 'showPumpInterface':
                showPumpInterface(data);
                break;
                
            case 'hidePumpInterface':
                hidePumpInterface();
                break;
                
            // Refueling Progress Actions
            case 'showRefuelProgress':
                showRefuelProgress(data);
                break;
                
            case 'updateRefuelProgress':
                updateRefuelProgress(data);
                break;
                
            case 'hideRefuelProgress':
                hideRefuelProgress();
                showHUD();
                break;
                
            // Theme
            case 'updateTheme':
                updateTheme(data.theme);
                break;
                
            // Hide all UI
            case 'hideAll':
                hideHUD();
                hidePumpInterface();
                hideRefuelProgress();
                break;
        }
    });

    // Event Listeners
    elements.fuelSlider.addEventListener('input', function() {
        state.targetFuel = parseInt(this.value);
        updateGauge();
    });

    elements.fuelMinus.addEventListener('click', function() {
        state.targetFuel = clamp(state.targetFuel - 5, Math.ceil(state.currentFuel), 100);
        updateGauge();
    });

    elements.fuelPlus.addEventListener('click', function() {
        state.targetFuel = clamp(state.targetFuel + 5, Math.ceil(state.currentFuel), 100);
        updateGauge();
    });

    elements.closeBtn.addEventListener('click', function() {
        sendCallback('closePump');
    });

    elements.cancelBtn.addEventListener('click', function() {
        sendCallback('closePump');
    });

    elements.confirmBtn.addEventListener('click', function() {
        if (!elements.confirmBtn.disabled) {
            sendCallback('confirmRefuel', {
                targetFuel: state.targetFuel,
                fuelToAdd: state.targetFuel - state.currentFuel,
                cost: calculateCost(state.targetFuel - state.currentFuel)
            });
        }
    });

    // Keyboard Controls
    document.addEventListener('keydown', function(event) {
        // ESC key
        if (event.key === 'Escape') {
            if (!elements.pumpInterface.classList.contains('hidden')) {
                sendCallback('closePump');
            } else if (state.isRefueling) {
                sendCallback('cancelRefuel');
            }
        }
        
        // E key for confirm
        if (event.key === 'e' || event.key === 'E') {
            if (!elements.pumpInterface.classList.contains('hidden') && !elements.confirmBtn.disabled) {
                sendCallback('confirmRefuel', {
                    targetFuel: state.targetFuel,
                    fuelToAdd: state.targetFuel - state.currentFuel,
                    cost: calculateCost(state.targetFuel - state.currentFuel)
                });
            }
        }
    });

    // Send callback to Lua
    function sendCallback(name, data) {
        fetch('https://ox_fuel/' + name, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(data || {})
        }).catch(function() {
            // Ignore fetch errors in browser testing
        });
    }

    // Initialize - hide all on load
    hideHUD();
    hidePumpInterface();
    hideRefuelProgress();
})();
