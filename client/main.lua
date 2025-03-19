local displayingTicket = false

-- Function to format date time (client-side safe version)
function FormatDateTime(timestamp)
    debug("Formatting timestamp: " .. tostring(timestamp))
    -- Use a safer approach for client-side
    local year, month, day, hour, min, sec = string.match(timestamp, "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)")
    if year then
        return year.."-"..month.."-"..day.." "..hour..":"..min..":"..sec
    else
        return timestamp
    end
end

-- Function to get current date time formatted (client-side safe version)
function GetCurrentDateTime()
    debug("Getting current date time")
    -- Get current time from the server instead
    return GetGameTimer() -- Just a placeholder, we'll get the actual date from the server
end

function ShowPurchaseUI(vehicles, streetName)
    debug("Showing purchase UI with " .. #vehicles .. " vehicles on street: " .. streetName)
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openPurchaseUI',
        vehicles = vehicles,
        streetName = streetName,
        config = {
            pricePerMinute = Config.PricePerMinutes,
            minDuration = Config.MinParkingTime,
            maxDuration = Config.MaxParkingTime
        }
    })
end

-- Function to hide the purchase UI
function HidePurchaseUI()
    debug("Hiding purchase UI")
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'closePurchaseUI'})
end

-- Function to show the ticket UI
function ShowTicketUI(data)
    debug("Showing ticket UI with data: " .. json.encode(data))
    SetNuiFocus(true, true)
    SendNUIMessage(data)
end

-- Function to hide the ticket UI
function HideTicketUI()
    debug("Hiding ticket UI")
    SetNuiFocus(false, false)
    SendNUIMessage({action = 'hideTicket'})
end

-- Register NUI callback for closing the purchase UI
RegisterNUICallback('closePurchaseUI', function(data, cb)
    debug("NUI callback: closePurchaseUI received")
    HidePurchaseUI()
    cb('ok')
end)

-- Register NUI callback for closing the ticket UI
RegisterNUICallback('closeTicket', function(data, cb)
    debug("NUI callback: closeTicket received")
    HideTicketUI()
    cb('ok')
end)

-- Register NUI callback for purchasing a ticket
RegisterNUICallback('purchaseTicket', function(data, cb)
    debug("NUI callback: purchaseTicket received for plate: " .. data.plate)
    
    local clientId = GetPlayerServerId(PlayerId())
    
    -- Send purchase request to server
    TriggerServerEvent('meter:pay', clientId, data.plate, data.duration, data.streetName)
    
    HidePurchaseUI()
    cb('ok')
end)

RegisterNetEvent('meter:OpenMenu', function()
    debug("Opening purchase menu")
    local ped = PlayerPedId()
    local clientId = GetPlayerServerId(PlayerId())
    local playerCoords = GetEntityCoords(ped)
    local licensePlates = {}

    for vehicle in EnumerateVehicles() do
        local vehicleCoords = GetEntityCoords(vehicle)
        if #(playerCoords - vehicleCoords) < Config.MaxDistanceGetVehicles then
            local plate = GetVehicleNumberPlateText(vehicle)
            if plate then
                debug("Found nearby vehicle with plate: " .. plate)
                table.insert(licensePlates, {
                    plate = plate
                })
            end
        end
    end

    if #licensePlates == 0 then
        debug("No vehicles found nearby")
        Notify("Parking Meter", translations.NoVehicleNearby, "error", 5000)
        return
    end

    local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(playerCoords.x, playerCoords.y, playerCoords.z))
    debug("Opening purchase UI for street: " .. streetName)
    
    ShowPurchaseUI(licensePlates, streetName)
end)

-- Helper function to toggle NUI frame
function ToggleNuiFrame(toggle)
    debug("Toggling NUI frame: " .. tostring(toggle))
    SetNuiFocus(toggle, toggle)
    SendNUIMessage({
        action = toggle and 'openPurchaseUI' or 'closePurchaseUI'
    })
end
RegisterNetEvent('meter:CheckParkingTime', function()
    debug("Checking parking time")
    local ped = PlayerPedId()
    local clientId = GetPlayerServerId(PlayerId())
    local pos = GetEntityCoords(ped)
    local targetVehicle = GetClosestVehicle(pos.x, pos.y, pos.z, 5.0, 0, 70)
    
    if targetVehicle == 0 then
        debug("No vehicle found nearby")
        return
    end
    
    local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(pos.x, pos.y, pos.z))
    local plate = GetVehicleNumberPlateText(targetVehicle)
    
    debug("Vehicle check - Plate: " .. plate .. ", Street: " .. streetName)
    
    -- Request ticket data from server
    TriggerServerEvent('meter:GetDataFromDBForUI', clientId, plate, streetName)
end)

RegisterNetEvent('meter:DisplayTicketUI', function(ticketData)
    debug("Received ticket data from server: " .. json.encode(ticketData))
    
    if ticketData.hasTicket then
        debug("Vehicle has a ticket, showing valid ticket UI")
        ShowTicketUI({
            action = 'showTicket',
            hasTicket = true,
            licensePlate = ticketData.licensePlate,
            streetName = ticketData.streetName,
            expirationTime = ticketData.expirationTime,
            currentDate = ticketData.currentDate,
            isExpired = ticketData.isExpired
        })
    else
        debug("Vehicle has no ticket, showing no ticket UI with message: " .. ticketData.message)
        ShowTicketUI({
            action = 'showTicket',
            hasTicket = false,
            message = ticketData.message
        })
    end
end)

if Config.UseRobbery then
    RegisterNetEvent('meter:PoliceCheckResult', function()
        print("Received police check result")
        local ped = PlayerPedId()
        local clientId = GetPlayerServerId(PlayerId())

        if IsPedInAnyVehicle(ped, false) then
            print("Player is in vehicle")
            Notify("Parking Meter", translations.NotDoInCar, "error", 5000)
        else
            debug("Player is not in vehicle sending server")
            TriggerServerEvent('meter:CheckPoliceCount', clientId, Config.MinPoliceCount)
        end
    end)

    RegisterNetEvent('meter:RobParkingMeter', function()
        local ped = PlayerPedId()
        local clientId = GetPlayerServerId(PlayerId())
        local pos = GetEntityCoords(ped)
        debug("Starting robbery check")

        lib.callback('meter:HasItem', false, function(hasItem)
            debug("Item check completed")
            if hasItem then
                debug("Player has required item")
                TriggerServerEvent('meter:Robbery_GetDataFromDB', clientId, pos)
            else
                Notify("Parking Meter", translations.NoItemToRob, "error", 5000)
            end
        end)
    end)

    RegisterNetEvent('meter:RobParkingMeterProgressbar', function(pos, identifier)
        exports['kedi_ui']:StartProgress({
            label = Config.RobParkingMeterProgressLabel,
            duration = Config.RobParkingMeterDuration, -- milliseconds
            canCancel = true, -- allow cancellation with X key
            animation = {
                dict = "mini@repair",
                name = "fixing_a_ped",
                flags = 49
            },
            onComplete = function()
                RobberySkillcheck(pos, identifier)
            end,
            onCancel = function()
                Notify("Parking Meter", "Robbery Canceled", "error", 5000)
            end
        })
    end)

    function RobberySkillcheck(pos, identifier)
        local clientId = GetPlayerServerId(PlayerId())
        local coords = GetEntityCoords(PlayerPedId())
        local success = Config.SkillCheck and lib.skillCheck(Config.SkillcheckSettings, {'w', 'a', 's', 'd'}) or true

        if success then
            TriggerServerEvent('meter:RobberyInsertInDB', clientId, pos, identifier)
            TriggerEvent('meter:AlertPolice', coords)
        end
    end
end
