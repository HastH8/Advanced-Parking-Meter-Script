if Config.Core == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Core == "esx" then
    ESX = exports['es_extended']:getSharedObject()
end
local Webhook = "" -- Discord Webhook
local itemRemoved = false

function debug(message)
    if Config.debug then
        print("^1[DEBUG] ^7" .. message)
    end
end

RegisterNetEvent('meter:AddMoney', function(source, pos, identifier, date, time, expirationTime)
    local identifierlist = ExtractIdentifiers(source)
    local discord = (identifierlist.discord and identifierlist.discord:gsub("old_pattern", "new_pattern")) or ""
    local MoneyAmount = Config.GetRobMoney

    if itemRemoved then
        local Player = GetPlayer(source)
        if Player then
            addmoney(source, MoneyAmount)

            local msg = string.format(translations.RobedParkingMeter, MoneyAmount)
            SerNotify(source, "Robbery", msg, "success", 5000)

            itemRemoved = false

            DiscordWebhook(16753920, Config.Titel, identifier .. "\nRobbed a Parkingmeter at: " .. pos .. "\nHe got " ..
                MoneyAmount .. "€\n" .. discord)
        end
    end
end)

RegisterNetEvent('meter:RemoveItem', function(source, pos, identifier, date, time, expirationTime)
    local itemName = Config.RobItem
    local Player = GetPlayer(source)

    if Player then
        if Config.RemoveItem then
            removeitem(source, itemName, 1)
        end
        itemRemoved = true
        TriggerEvent('meter:AddMoney', source, pos, identifier, date, time, expirationTime)
    end
end)

lib.callback.register('meter:HasItem', function(source, item)
    local item = Config.RobItem
    debug("Checking if player " .. source .. " has item: " .. item)
    local hasItem = hasitem(source, item, 1)
    debug("Item check result: " .. tostring(hasItem))
    return hasItem
end)

RegisterNetEvent('meter:AlertPoliceServer', function(coords)
    TriggerEvent('emergencydispatch:emergencycall:new', "police", "A parking meter was robbed", coords, true)
end)
RegisterNetEvent('meter:InsertInDB', function(source, LicensePlate, ParkDuration, Streetname, Date, Time)
    local seconds = math.floor(Time / 1000)
    local UTCTime = Config.UTCTime
    local currentTime = os.time()
    local newExpirationTime = currentTime + (ParkDuration * 60)

    MySQL.Async.fetchAll('SELECT * FROM meter WHERE licenseplate = ? AND streetname = ?', {LicensePlate, Streetname},
        function(result)
            if #result > 0 then
                local ticket = result[1]
                local currentExpirationTime = tonumber(ticket.expiration_time) / 1000

                if newExpirationTime > currentExpirationTime then
                    MySQL.Async.execute([[
                    UPDATE meter
                    SET parkduration = ?, parkdate = ?, 
                    parktime = DATE_ADD(FROM_UNIXTIME(?), INTERVAL ? HOUR),
                    expiration_time = FROM_UNIXTIME(?)
                    WHERE licenseplate = ? AND streetname = ?
                ]], {ParkDuration, Date, seconds, UTCTime, newExpirationTime, LicensePlate, Streetname},
                        function(rowsChanged)
                            if rowsChanged > 0 then
                                TriggerEvent('meter:pay', source, LicensePlate, ParkDuration, Streetname, Date, Time)
                            else
                                SerNotify(source, "Parking Meter", translations.DataBaseError, "error", 5000)
                            end
                        end)
                else
                    SerNotify(source, "Parking Meter", string.format(translations.HasAllreadTicket, LicensePlate, Streetname), "error", 5000)
                end
            else
                MySQL.Async.execute([[
                INSERT INTO meter 
                (licenseplate, streetname, parkduration, parkdate, parktime, expiration_time)
                VALUES (?, ?, ?, ?, DATE_ADD(FROM_UNIXTIME(?), INTERVAL ? HOUR), FROM_UNIXTIME(?))
            ]], {LicensePlate, Streetname, ParkDuration, Date, seconds, UTCTime, newExpirationTime},
                    function(rowsChanged)
                        if rowsChanged > 0 then
                            TriggerEvent('meter:pay', source, LicensePlate, ParkDuration, Streetname, Date, Time)
                        else
                            SerNotify(source, "Parking Meter", translations.DataBaseError, "error", 5000)
                        end
                    end)
            end
        end)
end)

RegisterNetEvent('meter:GetDataFromDB', function(source, LicensePlate, streetName)
    MySQL.Async.fetchAll('SELECT * FROM meter WHERE licenseplate = ?', {LicensePlate}, function(results)
        if #results > 0 then
            local foundActiveTicket = false
            local currentTime = os.time()

            for _, row in ipairs(results) do
                local expirationTime = tonumber(row.exp_timestamp)      
                if expirationTime then
                    if currentTime <= expirationTime and streetName == row.streetname then
                        foundActiveTicket = true
                        local expirationDateTime = os.date("!%Y-%m-%d %H:%M:%S", expirationTime)
                        SerNotify(source, "Parking Meter", string.format(translations.PrkingGood, LicensePlate, expirationDateTime), "success", 5000)
                        break
                    end
                end
            end
            

            if not foundActiveTicket then
                SerNotify(source, "Parking Meter", string.format(translations.NoParkingTicketForThisStreet, LicensePlate), "error", 5000)
            end
        else
            SerNotify(source, "Parking Meter", string.format(translations.NoParkingTicket, LicensePlate), "error", 5000)
        end
    end)
end)

RegisterNetEvent('meter:DeleteOldContent', function()
    local currentTime = os.time()

    MySQL.Async.execute('DELETE FROM meter WHERE expiration_time < FROM_UNIXTIME(?)', {currentTime})

    if Config.UseRobbery then
        MySQL.Async.execute('DELETE FROM meter_robbery WHERE expiration < FROM_UNIXTIME(?)', {currentTime})
    end
end)


RegisterNetEvent('meter:pay', function(source, LicensePlate, Duration, StreetName)
    debug("Processing payment - Source: " .. source .. ", Plate: " .. LicensePlate .. ", Duration: " .. Duration .. ", Street: " .. StreetName)
    
    -- Calculate price based on duration and price per minute
    local price = Duration * Config.PricePerMinutes
    debug("Calculated price: " .. price)
    
    if hasmoney(source, price) then
        debug("Player has enough money")
        removemoney(source, price)
        
        -- Calculate expiration time
        local currentTime = os.time()
        local expirationTime = currentTime + (Duration * 60)

        -- Format for database - use UTC time with the "!" prefix
        local formattedExpiration = os.date("!%Y-%m-%d %H:%M:%S", expirationTime)
        local currentDate = os.date("!%Y-%m-%d", currentTime)
        local currentTimeStr = os.date("!%H:%M:%S", currentTime)
        
        MySQL.Async.execute('REPLACE INTO meter (licenseplate, streetname, parkduration, parkdate, parktime, expiration_time) VALUES (?, ?, ?, ?, ?, ?)',
            {
                LicensePlate, 
                StreetName, 
                Duration,
                currentDate,
                currentTimeStr,
                formattedExpiration
            },
            function(rowsChanged)
                if rowsChanged > 0 then
                    debug("Successfully inserted ticket into database")
                    SerNotify(source, "Parking Meter", 
                        string.format(translations.ParkTicketBought, Duration, price), 
                        "success", 
                        5000
                    )
                else
                    debug("Failed to insert ticket into database")
                    SerNotify(source, "Parking Meter", 
                        translations.DataBaseError, 
                        "error", 
                        5000
                    )
                end
            end
        )
    else
        debug("Player does not have enough money")
        SerNotify(source, "Parking Meter", 
            translations.NotEnoughMoney, 
            "error", 
            5000
        )
    end
end)

RegisterNetEvent('meter:GetDataFromDBForUI', function(source, LicensePlate, streetName)
    debug("Getting ticket data for UI - Source: " .. source .. ", Plate: " .. LicensePlate .. ", Street: " .. streetName)
    
    MySQL.Async.fetchAll('SELECT *, UNIX_TIMESTAMP(expiration_time) as exp_timestamp FROM meter WHERE licenseplate = ?', {LicensePlate}, function(results)
        debug("Database query returned " .. #results .. " results for plate: " .. LicensePlate)
        
        local ticketData = {
            hasTicket = false,
            message = translations and string.format(translations.NoParkingTicket or "No parking ticket for %s", LicensePlate) or 
                     "No parking ticket found"
        }
        
        if #results > 0 then
            local foundActiveTicket = false
            local currentTime = os.time()
            
            for i, row in ipairs(results) do
                if streetName == row.streetname then
                    debug("Found ticket for matching street")
                    foundActiveTicket = true
                    
                    -- Get expiration timestamp directly from the query result
                    local expirationTime = tonumber(row.exp_timestamp)
                    debug("Raw expiration timestamp: " .. tostring(expirationTime))
                    
                    if expirationTime then
                        local formattedExpiration = os.date("%Y-%m-%d %H:%M:%S", expirationTime)
                        debug("Formatted expiration time: " .. formattedExpiration)
                        
                        ticketData = {
                            hasTicket = true,
                            licensePlate = LicensePlate,
                            streetName = streetName,
                            expirationTime = formattedExpiration,
                            currentDate = os.date("%Y-%m-%d %H:%M:%S", currentTime),
                            isExpired = currentTime > expirationTime,
                            parkDuration = row.parkduration
                        }
                        
                        if currentTime <= expirationTime then
                            SerNotify(source, "Parking Meter", 
                                string.format(translations.PrkingGood or "Valid parking ticket for %s until %s", 
                                    LicensePlate, 
                                    formattedExpiration
                                ), 
                                "success", 
                                5000
                            )
                        else
                            local timeDiff = os.difftime(currentTime, expirationTime)
                            local minutesOvertime = math.floor(timeDiff / 60)
                            SerNotify(source, "Parking Meter", 
                                string.format(translations.PrkingOvertime or "Parking expired by %s", 
                                    minutesOvertime .. " minutes"
                                ), 
                                "error", 
                                5000
                            )
                        end
                    else
                        debug("Failed to get expiration timestamp")
                        ticketData.message = "Error reading ticket expiration time"
                    end
                    break
                end
            end

            if not foundActiveTicket then
                ticketData.message = translations and 
                    string.format(translations.NoParkingTicketForThisStreet or "No parking ticket for %s at this location", LicensePlate) or 
                    "No valid parking ticket found for this location"
                SerNotify(source, "Parking Meter", ticketData.message, "error", 5000)
            end
        else
            SerNotify(source, "Parking Meter", ticketData.message, "error", 5000)
        end
        
        debug("Sending ticket data to client: " .. json.encode(ticketData))
        TriggerClientEvent('meter:DisplayTicketUI', source, ticketData)
    end)
end)

if Config.UseRobbery then
    RegisterNetEvent('meter:Robbery_GetDataFromDB', function(source, pos)
        local identifier = GetPlayerIdentifier(source)

        MySQL.Async.fetchAll('SELECT *, UNIX_TIMESTAMP(expiration_time) as exp_timestamp FROM meter WHERE licenseplate = ?', {LicensePlate}, function(results)
            if #results > 0 then
                local canRob = true
                for _, row in ipairs(results) do
                    local expirationTimeMillis = tonumber(row.expiration)
                    local expirationTimeSeconds = math.floor(expirationTimeMillis / 1000)
                    if os.time() < expirationTimeSeconds then
                        SerNotify(source, "Parking Meter", translations.YouCanNotRobberAgain, "error", 5000)
                        canRob = false
                        break
                    end
                end
                if canRob then
                    TriggerClientEvent('meter:RobParkingMeterProgressbar', source, pos, identifier)
                end
            else
                TriggerClientEvent('meter:RobParkingMeterProgressbar', source, pos, identifier)
            end
        end)
    end)

    RegisterNetEvent('meter:RobberyInsertInDB', function(source, pos, identifier)
        local currentTime = os.time()
        local date = os.date("%Y-%m-%d", currentTime)
        local time = os.date("%H:%M:%S", currentTime)
        local expirationTime = os.date("%Y-%m-%d %H:%M:%S", currentTime + (Config.TimeBeforeCanRobAgain * 60))

        MySQL.Async.execute([[
            INSERT INTO meter_robbery 
            (identifier, robdate, robtime, expiration)
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            robdate = VALUES(robdate),
            robtime = VALUES(robtime),
            expiration = VALUES(expiration)
        ]], {identifier, date, time, expirationTime}, function(rowsChanged)
            if rowsChanged > 0 then
                TriggerEvent('meter:RemoveItem', source, pos, identifier, date, time, expirationTime)
            else
                SerNotify(source, "Parking Meter", translations.DataBaseError, "error", 5000)
            end
        end)
    end)

    RegisterNetEvent('meter:CheckPoliceCount', function(source, minPoliceCount)
        debug("Police Count: " .. minPoliceCount)
        local policeCount = 0
        for _, player in pairs(GetPlayers()) do
            local Player = GetPlayer(player)
            if Player and Player.PlayerData.job.name == "police" and Player.PlayerData.job.onduty then
                policeCount = policeCount + 1
            end
        end
        debug("Police Count: " .. policeCount)
        if policeCount >= minPoliceCount then
            debug(" police online")
            TriggerClientEvent('meter:RobParkingMeter', source)
        else
            debug("no Police online")
            SerNotify(source, "Parking Meter", translations.NotEnoughPolice, "error", 5000)
        end
    end)
end
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    if Config.DeleteOldEntries then
        TriggerEvent('meter:DeleteOldContent')
    end
end)

function ExtractIdentifiers(playerId)
    local identifiers = {}

    for i = 0, GetNumPlayerIdentifiers(playerId) - 1 do
        local id = GetPlayerIdentifier(playerId, i)

        if string.find(id, "steam:") then
            identifiers['steam'] = id
        elseif string.find(id, "discord:") then
            identifiers['discord'] = id
        elseif string.find(id, "license:") then
            identifiers['license'] = id
        elseif string.find(id, "license2:") then
            identifiers['license2'] = id
        end
    end

    return identifiers
end

function DiscordWebhook(color, name, message, footer)
    local embed = {{
        ["color"] = color,
        ["author"] = {
            ["icon_url"] = Config.IconURL,
            ["name"] = Config.ServerName
        },
        ["title"] = "**" .. name .. "**",
        ["description"] = "**" .. message .. "**",
        ["footer"] = {
            ["text"] = os.date('%d/%m/%Y [%X]')
        }
    }}

    PerformHttpRequest(Webhook, function(err, text, headers)
    end, 'POST', json.encode({
        username = Config.BotName,
        embeds = embed
    }), {
        ['Content-Type'] = 'application/json'
    })
end
