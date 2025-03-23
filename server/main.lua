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

function GetServerTime()
    return os.time()
end

function FormatTimeForDB(timestamp)
    if Config.UseServerTime then
        return os.date("%Y-%m-%d %H:%M:%S", timestamp)
    else
        return os.date("!%Y-%m-%d %H:%M:%S", timestamp + (Config.UTCTime * 3600))
    end
end

function FormatTimeForDisplay(timestamp)
    if Config.UseServerTime then
        return os.date("%Y-%m-%d %H:%M:%S", timestamp)
    else
        local adjustedTime = timestamp + (Config.UTCTime * 3600)
        return os.date("!%Y-%m-%d %H:%M:%S", adjustedTime)
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
    local currentTime = GetServerTime()
    local newExpirationTime = currentTime + (ParkDuration * 60)
    local formattedCurrentTime = FormatTimeForDB(currentTime)
    local formattedExpiration = FormatTimeForDB(newExpirationTime)
    
    MySQL.Async.fetchAll('SELECT *, UNIX_TIMESTAMP(expiration_time) as exp_timestamp FROM meter WHERE licenseplate = ? AND streetname = ?', {LicensePlate, Streetname},
        function(result)
            if #result > 0 then
                local ticket = result[1]
                local currentExpirationTime = tonumber(ticket.exp_timestamp)
                
                if newExpirationTime > currentExpirationTime then
                    MySQL.Async.execute([[
                    UPDATE meter
                    SET parkduration = ?, parkdate = ?,
                    parktime = ?,
                    expiration_time = ?
                    WHERE licenseplate = ? AND streetname = ?
                    ]], {
                        ParkDuration, 
                        formattedCurrentTime:sub(1, 10),
                        formattedCurrentTime:sub(12),
                        formattedExpiration, 
                        LicensePlate, 
                        Streetname
                    },
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
                VALUES (?, ?, ?, ?, ?, ?)
                ]], {
                    LicensePlate, 
                    Streetname, 
                    ParkDuration, 
                    formattedCurrentTime:sub(1, 10),
                    formattedCurrentTime:sub(12),
                    formattedExpiration
                },
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
    MySQL.Async.fetchAll('SELECT *, UNIX_TIMESTAMP(expiration_time) as exp_timestamp FROM meter WHERE licenseplate = ?', {LicensePlate}, function(results)
        if #results > 0 then
            local foundActiveTicket = false
            local currentTime = GetServerTime()

            for _, row in ipairs(results) do
                local expirationTime = tonumber(row.exp_timestamp)
                if expirationTime and currentTime <= expirationTime and streetName == row.streetname then
                    foundActiveTicket = true
                    local formattedExpiration = FormatTimeForDisplay(expirationTime)
                    SerNotify(source, "Parking Meter", string.format(translations.PrkingGood, LicensePlate, formattedExpiration), "success", 5000)
                    break
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
    local price = Duration * Config.PricePerMinutes
    debug("Calculated price: " .. price)
    
    if hasmoney(source, price) then
        debug("Player has enough money")
        removemoney(source, price)
        local currentTime = GetServerTime()
        local expirationTime = currentTime + (Duration * 60)
        local formattedExpiration = FormatTimeForDB(expirationTime)
        local currentDate = FormatTimeForDB(currentTime):sub(1, 10) 
        local currentTimeStr = FormatTimeForDB(currentTime):sub(12) 
        
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
                    local displayExpiration = FormatTimeForDisplay(expirationTime)
                    
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
   local Player = GetPlayer(source)
   local playerJob = ""
   local canFine = false
   
   if Player then
       if Config.Core == "qbcore" then
           playerJob = Player.PlayerData.job.name
           debug("Player job: " .. playerJob)
       elseif Config.Core == "esx" then
           playerJob = Player.job.name
           debug("Player job: " .. playerJob)
       end
       debug("Checking if job is in allowed list: " .. playerJob)
       if type(Config.JobCanCheckParkingTime) == "table" then
           if Config.TargetSystem == "qb-target" then
               for job, _ in pairs(Config.JobCanCheckParkingTime) do
                   if job == playerJob then
                       canFine = true
                       debug("Player can fine: true (job match in qb-target format)")
                       break
                   end
               end
           else
               for _, job in ipairs(Config.JobCanCheckParkingTime) do
                   debug("Checking against job: " .. job)
                   if job == playerJob then
                       canFine = true
                       debug("Player can fine: true (job match in ox-target format)")
                       break
                   end
               end
           end
       end
   end
    MySQL.Async.fetchAll('SELECT *, expiration_time as raw_expiration, UNIX_TIMESTAMP(expiration_time) as exp_timestamp FROM meter WHERE licenseplate = ?', {LicensePlate}, function(results)
        debug("Database query returned " .. #results .. " results for plate: " .. LicensePlate)
       
        local ticketData = {
            hasTicket = false,
            message = translations and string.format(translations.NoParkingTicket or "No parking ticket for %s", LicensePlate) or
                     "No parking ticket found",
            canFine = canFine,
            licensePlate = LicensePlate,
            streetName = streetName
        }
       
        if #results > 0 then
            local foundActiveTicket = false
            local currentTimestamp = os.time()
           
            for i, row in ipairs(results) do
                if streetName == row.streetname then
                    debug("Found ticket for matching street")
                    foundActiveTicket = true
                   
                    local expirationTimestamp = tonumber(row.exp_timestamp)
                    
                    if expirationTimestamp then
                        debug("Using timestamp: " .. expirationTimestamp)
                        
                        local formattedCurrent = os.date("%Y-%m-%d %H:%M:%S", currentTimestamp)
                        local formattedExpiration = os.date("%Y-%m-%d %H:%M:%S", expirationTimestamp)
                        local isExpired = currentTimestamp > expirationTimestamp
                        
                        ticketData = {
                            hasTicket = true,
                            licensePlate = LicensePlate,
                            streetName = streetName,
                            expirationTime = formattedExpiration,
                            currentDate = formattedCurrent,
                            isExpired = isExpired,
                            parkDuration = row.parkduration,
                            showBuyButton = isExpired,
                            canFine = canFine
                        }
                       
                        if not isExpired then
                            SerNotify(source, "Parking Meter",
                                string.format(translations.PrkingGood or "Valid parking ticket for %s until %s",
                                    LicensePlate,
                                    formattedExpiration
                                ),
                                "success",
                                5000
                            )
                        else
                            local timeDiff = os.difftime(currentTimestamp, expirationTimestamp)
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
                        debug("Failed to get valid timestamp")
                        
                        ticketData = {
                            hasTicket = true,
                            licensePlate = LicensePlate,
                            streetName = streetName,
                            expirationTime = "Unknown",
                            currentDate = os.date("%Y-%m-%d %H:%M:%S", currentTimestamp),
                            isExpired = false,
                            parkDuration = row.parkduration,
                            showBuyButton = true,
                            canFine = canFine  
                        }
                       
                        SerNotify(source, "Parking Meter",
                            "Parking ticket information retrieved, but time comparison unavailable",
                            "info",
                            5000
                        )
                    end
                    break
                end
            end

            if not foundActiveTicket then
                ticketData.message = translations and
                    string.format(translations.NoParkingTicketForThisStreet or "No parking ticket for %s at this location", LicensePlate) or
                    "No valid parking ticket found for this location"
                ticketData.showBuyButton = true
                SerNotify(source, "Parking Meter", ticketData.message, "error", 5000)
            end
        else
            SerNotify(source, "Parking Meter", ticketData.message, "error", 5000)
        end
        debug("Sending ticket data to client: " .. json.encode(ticketData))
        TriggerClientEvent('meter:DisplayTicketUI', source, ticketData)
    end)
end)

RegisterNetEvent('meter:IssueFine', function(licensePlate, streetName, fineAmount)
    local source = source
    local Player = GetPlayer(source)
    
    if not Player then 
        debug("Player not found")
        return 
    end

    local hasPermission = false
    local playerJob = ""

    if Config.Core == "qbcore" then
        playerJob = Player.PlayerData.job.name
    elseif Config.Core == "esx" then
        playerJob = Player.job.name
    end
    
    debug("Player job: " .. playerJob)
    
    for _, job in pairs(Config.JobCanCheckParkingTime) do
        if job == playerJob then
            debug("Player has permission to issue fines")
            hasPermission = true
            break
        end
    end
    
    if not hasPermission then
        SerNotify(source, "Parking Meter", "You don't have permission to issue fines", "error", 5000)
        debug("Player does not have permission to issue fines")
        return
    end
    
    -- Clean the license plate to ensure consistent formatting
    if not licensePlate or licensePlate == "" then
        SerNotify(source, "Parking Meter", "Invalid license plate", "error", 5000)
        return
    end
    
    licensePlate = string.gsub(licensePlate, "%s+", "")
    
    GetVehicleOwner(licensePlate, function(ownerIdentifier, found)
        if found and ownerIdentifier then
            local fineLabel = "Parking Fine - " .. streetName
            
            -- Always create a bill, even if player is online
            if IssueBill(source, ownerIdentifier, fineAmount, fineLabel, playerJob) then
                SerNotify(source, "Parking Meter", "Fine of $" .. fineAmount .. " issued to vehicle owner", "success", 5000)
                
                -- Notify the player if they're online
                local targetPlayer = nil
                if Config.Core == "qbcore" then
                    targetPlayer = QBCore.Functions.GetPlayerByCitizenId(ownerIdentifier)
                elseif Config.Core == "esx" then
                    targetPlayer = ESX.GetPlayerFromIdentifier(ownerIdentifier)
                end
                
                if targetPlayer then
                    SerNotify(targetPlayer.source, "Parking Fine", "You have received a fine of $" .. fineAmount .. " for illegal parking at " .. streetName, "error", 5000)
                end
            else
                SerNotify(source, "Parking Meter", "Failed to issue fine", "error", 5000)
            end
        else
            SerNotify(source, "Parking Meter", "This vehicle is not owned by anyone. Cannot send fine.", "error", 5000)
        end
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
