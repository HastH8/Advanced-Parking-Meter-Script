// Global variables for purchase UI
let vehicleData = [];
let pricePerMinute = 1;
let minDuration = 1;
let maxDuration = 15;
let currentStreet = "";

// Debug function to log messages
function debugLog(message) {
    console.log('[DEBUG] ' + message);
}

// Initialize the UI when the DOM is loaded
window.addEventListener('DOMContentLoaded', function() {
    debugLog('Parking system UI loaded');
    
    // Set up event listeners for purchase UI
    document.getElementById('durationSlider').addEventListener('input', updateDuration);
    document.getElementById('licensePlateSelect').addEventListener('change', updatePreview);
    document.getElementById('purchaseButton').addEventListener('click', purchaseTicket);
    document.getElementById('cancelButton').addEventListener('click', closePurchaseUI);
    document.getElementById('closeButton').addEventListener('click', closePurchaseUI);
    
    // Close UI when ESC is pressed
    document.addEventListener('keyup', function(event) {
        if (event.key === 'Escape') {
            debugLog('ESC key pressed');
            if (document.getElementById('purchaseContainer').classList.contains('show')) {
                closePurchaseUI();
            } else if (document.getElementById('ticketContainer').classList.contains('show')) {
                closeTicketUI();
            }
        }
    });
    
    // Update the current date and time
    updateDateTime();
    setInterval(updateDateTime, 1000);
});

// Listen for messages from the game client
window.addEventListener('message', function(event) {
    const data = event.data;
    debugLog('Received message: ' + JSON.stringify(data));
    
    // Handle purchase UI messages
    if (data.action === 'openPurchaseUI') {
        debugLog('Opening purchase UI');
        document.getElementById('purchaseContainer').classList.add('show');
        document.getElementById('ticketContainer').classList.remove('show');
        
        // Update configuration values
        if (data.config) {
            pricePerMinute = data.config.pricePerMinute || 1;
            minDuration = data.config.minDuration || 1;
            maxDuration = data.config.maxDuration || 30;
            
            // Update slider min/max
            const slider = document.getElementById('durationSlider');
            slider.min = minDuration;
            slider.max = maxDuration;
            slider.value = Math.min(Math.max(15, minDuration), maxDuration);
            
            debugLog('Updated config values - Price per minute: ' + pricePerMinute);
        }
        
        // Set street name
        currentStreet = data.streetName || "Unknown Street";
        document.getElementById('streetNameInput').value = currentStreet;
        document.getElementById('previewStreet').textContent = currentStreet;
        debugLog('Set street name: ' + currentStreet);
        
        // Populate vehicle list
        populateVehicleList(data.vehicles || []);
        
        // Update preview and price
        updateDuration();
    } 
    // Handle ticket check UI messages
    else if (data.action === 'showTicket') {
        debugLog('Opening ticket check UI');
        document.getElementById('ticketContainer').classList.add('show');
        document.getElementById('purchaseContainer').classList.remove('show');
        
        if (data.hasTicket) {
            // Show valid ticket
            debugLog('Showing valid ticket UI');
            document.getElementById('ticketUI').classList.add('show');
            document.getElementById('noTicketUI').classList.remove('show');
            
            // Update ticket information
            document.getElementById('licensePlate').textContent = data.licensePlate;
            document.getElementById('streetName').textContent = data.streetName;
            document.getElementById('expirationTime').textContent = data.expirationTime;
            document.getElementById('ticketDate').textContent = data.currentDate;
            document.getElementById('ticketId').textContent = 'TKT-' + Math.floor(Math.random() * 90000) + 10000;
            debugLog('Updated ticket information');
            
            // Set status
            const statusElement = document.getElementById('ticketStatus');
            if (data.isExpired) {
                debugLog('Ticket is expired');
                statusElement.innerHTML = '<span>EXPIRED</span>';
                statusElement.classList.remove('valid');
                statusElement.classList.add('expired');
            } else {
                debugLog('Ticket is valid');
                statusElement.innerHTML = '<span>VALID</span>';
                statusElement.classList.add('valid');
                statusElement.classList.remove('expired');
            }
        } else {
            // Show no ticket message
            debugLog('Showing no ticket UI with message: ' + data.message);
            document.getElementById('ticketUI').classList.remove('show');
            document.getElementById('noTicketUI').classList.add('show');
            document.getElementById('noTicketMessage').textContent = data.message;
        }
    }
    // Handle close UI messages
    else if (data.action === 'hideTicket' || data.action === 'closePurchaseUI') {
        debugLog('Closing all UIs');
        document.getElementById('ticketContainer').classList.remove('show');
        document.getElementById('purchaseContainer').classList.remove('show');
    }
});

// PURCHASE UI FUNCTIONS

// Populate the vehicle dropdown with nearby vehicles
function populateVehicleList(vehicles) {
    vehicleData = vehicles;
    const select = document.getElementById('licensePlateSelect');
    
    // Clear existing options
    while (select.options.length > 1) {
        select.remove(1);
    }
    
    // Add vehicle options
    vehicles.forEach(vehicle => {
        const option = document.createElement('option');
        option.value = vehicle.plate;
        option.textContent = vehicle.plate;
        select.appendChild(option);
    });
    
    debugLog('Populated vehicle list with ' + vehicles.length + ' vehicles');
    
    // Select first vehicle if available
    if (vehicles.length > 0) {
        select.selectedIndex = 1;
        updatePreview();
    }
}

// Update duration and price when slider changes
function updateDuration() {
    const slider = document.getElementById('durationSlider');
    const duration = parseInt(slider.value);
    document.getElementById('durationValue').textContent = duration;
    
    // Update price
    const price = (duration * pricePerMinute).toFixed(2);
    document.getElementById('totalPrice').textContent = '$' + price;
    
    // Update preview
    document.getElementById('previewDuration').textContent = duration + ' minutes';
    
    // Calculate expiration time (client-side approximation)
    const now = new Date();
    const expiration = new Date(now.getTime() + duration * 60000);
    document.getElementById('previewExpires').textContent = formatDateTime(expiration);
    
    updatePreview();
    
    debugLog('Updated duration to ' + duration + ' minutes, price to $' + price);
}

// Update the preview when vehicle selection changes
function updatePreview() {
    const plateSelect = document.getElementById('licensePlateSelect');
    const selectedPlate = plateSelect.value;
    
    if (selectedPlate) {
        document.getElementById('previewPlate').textContent = selectedPlate;
        debugLog('Updated preview plate to ' + selectedPlate);
    } else {
        document.getElementById('previewPlate').textContent = 'No Vehicle Selected';
        debugLog('No vehicle selected for preview');
    }
}

// Purchase the ticket
function purchaseTicket() {
    const plate = document.getElementById('licensePlateSelect').value;
    const duration = parseInt(document.getElementById('durationSlider').value);
    
    if (!plate) {
        debugLog('Error: No vehicle selected');
        return;
    }
    
    debugLog('Purchasing ticket for plate ' + plate + ', duration ' + duration + ' minutes');
    
    // Send purchase request to the game client
    fetch('https://kedi_parkmeter/purchaseTicket', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            plate: plate,
            duration: duration,
            streetName: currentStreet
        })
    }).then(response => {
        debugLog('Sent purchase request');
        closePurchaseUI();
    }).catch(error => {
        debugLog('Error sending purchase request: ' + error);
    });
}

// Close the purchase UI
function closePurchaseUI() {
    debugLog('Closing purchase UI');
    fetch('https://kedi_parkmeter/closePurchaseUI', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).catch(error => {
        debugLog('Error sending close UI request: ' + error);
    });
}

// TICKET CHECK UI FUNCTIONS

// Close the ticket check UI
function closeTicketUI() {
    debugLog('Closing ticket check UI');
    fetch('https://kedi_parkmeter/closeTicket', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    }).catch(error => {
        debugLog('Error sending close ticket request: ' + error);
    });
}

// SHARED FUNCTIONS

// Update the current date and time display
function updateDateTime() {
    const now = new Date();
    document.getElementById('currentDateTime').textContent = formatDateTime(now);
}

// Format date and time for display
function formatDateTime(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');
    
    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
}