if Config.Core == "qbcore" then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Core == "esx" then
    ESX = exports['es_extended']:getSharedObject()
end

local itemRemoved = false

function additem(source, item, count)
    local Player = GetPlayer(source)
    if not Player then
        return debug("Player not found")
    end
    if Config.Inv == "qb-inventory" then
        Player.Functions.AddItem(item, count)
    elseif Config.Inv == "ox_inventory" then
        exports.ox_inventory:AddItem(source, item, count)
    elseif Config.Inv == "codem-inventory" then
        exports['codem-inventory']:AddItem(source, item, count)
    elseif Config.Inv == "qs-inventory" then
        exports['qs-inventory']:AddItem(source, item, count)
    elseif Config.Inv == "tgiann-inventory" then
        exports["tgiann-inventory"]:AddItem(source, item, count, nil, nil, false)
    elseif Config.Inv == "custom" then
        debug("Custom inventory has not been integrated integrate your inv in shared/server.lua")
    else
        debug("Inventory not found")
    end
end

function removeitem(source, item, count)
    local Player = GetPlayer(source)
    if not Player then
        return debug("Player not found")
    end
    if Config.Inv == "qb-inventory" then
        Player.Functions.RemoveItem(item, count)
    elseif Config.Inv == "ox_inventory" then
        exports.ox_inventory:RemoveItem(source, item, count)
    elseif Config.Inv == "codem-inventory" then
        exports['codem-inventory']:RemoveItem(source, item, count)
    elseif Config.Inv == "qs-inventory" then
        exports['qs-inventory']:RemoveItem(source, item, count)
    elseif Config.Inv == "tgiann-inventory" then
        exports["tgiann-inventory"]:RemoveItem(source, item, count, nil, nil)
    elseif Config.Inv == "custom" then
        debug("Custom inventory has not been integrated integrate your inv in shared/server.lua")
    else
        debug("Inventory not found")
    end
end

function hasitem(source, item, count)
    local Player = GetPlayer(source)
    if not Player then
        return debug("Player not found")
    end
    
    if Config.Inv == "qb-inventory" then
        return Player.Functions.GetItemByName(item).amount >= count
    elseif Config.Inv == "ox_inventory" then
        return exports.ox_inventory:GetItemCount(source, item) >= count
    elseif Config.Inv == "codem-inventory" then
        -- Add return statement here
        return exports['codem-inventory']:HasItem(source, item, count)
    elseif Config.Inv == "qs-inventory" then
        return exports['qs-inventory']:GetItemTotalAmount(source, item) >= count
    elseif Config.Inv == "tgiann-inventory" then
        return exports["tgiann-inventory"]:HasItem(source, item, count)
    elseif Config.Inv == "custom" then
        debug("Custom inventory has not been integrated integrate your inv in shared/server.lua")
        return false
    else
        debug("Inventory not found")
        return false
    end
end

function GetPlayer(source)
    if Config.Core == "qbcore" then
        return QBCore.Functions.GetPlayer(source)
    elseif Config.Core == "esx" then
        return ESX.GetPlayerFromId(source)
    else
        debug("Invalid core framework specified in config")
        return nil
    end
end
function GetPlayers()
    if Config.Core == "qbcore" then
        return QBCore.Functions.GetPlayers()
    elseif Config.Core == "esx" then
        return ESX.GetPlayers()
    end
end

function addmoney(source, amount)
    local Player = GetPlayer(source)

    if not Player then
        return debug("Player not found")
    end

    if Config.Moneytype == "cash" then
        if Config.Core == "qbcore" then
            Player.Functions.AddMoney("cash", amount)
        elseif Config.Core == "esx" then
            Player.addMoney(amount)
        end
    elseif Config.Moneytype == "bank" then
        if Config.Core == "qbcore" then
            Player.Functions.AddMoney("bank", amount)
        elseif Config.Core == "esx" then
            Player.addAccountMoney("bank", amount)
        end
    elseif Config.Moneytype == "black_money" then
        if Config.Core == "qbcore" then
            additem(source, "black_money", amount)
        elseif Config.Core == "esx" then
            Player.addAccountMoney("black_money", amount)
        end
    elseif Config.Moneytype == "custom" then
        debug("Custom money has not been integrated integrate your money in shared/server.lua")
    else
        debug("Money not found")
    end
end

function removemoney(source, amount)
    local Player = GetPlayer(source)

    if not Player then
        return debug("Player not found")
    end

    if Config.Moneytype == "cash" then
        if Config.Core == "qbcore" then
            Player.Functions.RemoveMoney("cash", amount)
        elseif Config.Core == "esx" then
            Player.removeMoney(amount)
        end
    elseif Config.Moneytype == "bank" then
        if Config.Core == "qbcore" then
            Player.Functions.RemoveMoney("bank", amount)
        elseif Config.Core == "esx" then
            Player.removeAccountMoney("bank", amount)
        end
    elseif Config.Moneytype == "black_money" then
        if Config.Core == "qbcore" then
            removeitemitem(source, "black_money", amount)
        elseif Config.Core == "esx" then
            Player.removeAccountMoney("black_money", amount)
        end
    elseif Config.Moneytype == "custom" then
        debug("Custom money has not been integrated integrate your money in shared/server.lua")
    else
        debug("Money not found")
    end
end

function hasmoney(source, amount)
    local Player = GetPlayer(source)

    if not Player then
        return debug("Player not found")
    end

    if Config.Moneytype == "cash" then
        if Config.Core == "qbcore" then
            return Player.PlayerData.money.cash >= amount
        elseif Config.Core == "esx" then
            return Player.getMoney() >= amount
        end
    elseif Config.Moneytype == "bank" then
        if Config.Core == "qbcore" then
            return Player.PlayerData.money.bank >= amount
        elseif Config.Core == "esx" then
            return Player.getAccount("bank").money >= amount
        end
    elseif Config.Moneytype == "black_money" then
        if Config.Core == "qbcore" then
            return hasitem(source, "black_money", amount)
        elseif Config.Core == "esx" then
            return Player.getAccount("black_money").money >= amount
        end
    elseif Config.Moneytype == "custom" then
        debug("Custom money has not been integrated integrate your money in shared/server.lua")
        return false
    else
        debug("Money not found")
        return false
    end
end


function SerNotify(source, title, message, type, length, icon)
    TriggerClientEvent('kedi_ui:client:Notify', source, {
        title = title,
        message = message,
        type = type,
        length = length or 5000,
        icon = icon or "fa-solid fa-square-parking"
    })
end

-- Function to get vehicle owner from database
function GetVehicleOwner(licensePlate, callback)
    if not licensePlate or licensePlate == "" then
        callback(nil, false)
        return
    end

    licensePlate = string.gsub(licensePlate, "%s+", "")
    
    if Config.Core == "qbcore" then
        MySQL.Async.fetchAll('SELECT * FROM player_vehicles WHERE plate = @plate', {['@plate'] = licensePlate}, function(results)
            if results and #results > 0 then
                callback(results[1].citizenid, true)
            else
                callback(nil, false)
            end
        end)
    elseif Config.Core == "esx" then
        MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE plate = @plate', {['@plate'] = licensePlate}, function(results)
            if results and #results > 0 then
                callback(results[1].owner, true)
            else
                callback(nil, false)
            end
        end)
    end
end

-- Function to issue a bill to a player
function IssueBill(officerSource, targetIdentifier, amount, label, jobName)
    -- Check if targetIdentifier is valid
    if not targetIdentifier or targetIdentifier == "" then
        return false
    end
    
    local officerPlayer = GetPlayer(officerSource)
    if not officerPlayer then return false end
    
    local officerIdentifier = nil
    
    if Config.Core == "qbcore" then
        officerIdentifier = officerPlayer.PlayerData.citizenid
    elseif Config.Core == "esx" then
        officerIdentifier = officerPlayer.identifier
    end
    
    local societyName = Config.SocietyNames[jobName] or jobName
    
    if Config.BillScript == 'default' then
        if Config.Core == "esx" or Config.Core == "oldesx" then
            MySQL.Async.execute('INSERT INTO billing (identifier, sender, target_type, target, label, amount) VALUES (@identifier, @sender, @target_type, @target, @label, @amount)',
            {
                ['@identifier'] = targetIdentifier,
                ['@sender'] = officerIdentifier,
                ['@target_type'] = 'society',
                ['@target'] = societyName,
                ['@label'] = label,
                ['@amount'] = amount
            })
        else
            -- QBCore uses phone_invoices table
            MySQL.Async.execute('INSERT INTO `phone_invoices` (`citizenid`, `amount`, `society`, `sender`, `sendercitizenid`) VALUES (@citizenid, @amount, @society, @sender, @sendercitizenid)', 
            {
                ['@citizenid'] = targetIdentifier,
                ['@amount'] = amount,
                ['@society'] = societyName,
                ['@sender'] = jobName,
                ['@sendercitizenid'] = officerIdentifier
            })
        end
        return true
    elseif Config.BillScript == 'codem-billing' then
        -- Get target source if online
        local targetSource = nil
        if Config.Core == "qbcore" then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetIdentifier)
            if targetPlayer then targetSource = targetPlayer.PlayerData.source end
        elseif Config.Core == "esx" then
            local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
            if targetPlayer then targetSource = targetPlayer.source end
        end
        
        if targetSource then
            exports['codem-billing']:createBilling(officerSource, targetSource, amount, label, jobName)
            return true
        else
            -- Offline billing fallback
            return IssueBill(officerSource, targetIdentifier, amount, label, jobName)
        end
    elseif Config.BillScript == 'codem-billingv2' then
        local targetSource = nil
        if Config.Core == "qbcore" then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetIdentifier)
            if targetPlayer then targetSource = targetPlayer.PlayerData.source end
        elseif Config.Core == "esx" then
            local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
            if targetPlayer then targetSource = targetPlayer.source end
        end
        
        if targetSource then
            exports["codem-billingv2"]:CreateBillingJob(officerSource, targetSource, amount, label)
            return true
        else
            -- Offline billing fallback
            return IssueBill(officerSource, targetIdentifier, amount, label, jobName)
        end
    elseif Config.BillScript == 'okokBilling' then
        local targetSource = nil
        if Config.Core == "qbcore" then
            local targetPlayer = QBCore.Functions.GetPlayerByCitizenId(targetIdentifier)
            if targetPlayer then targetSource = targetPlayer.PlayerData.source end
        elseif Config.Core == "esx" then
            local targetPlayer = ESX.GetPlayerFromIdentifier(targetIdentifier)
            if targetPlayer then targetSource = targetPlayer.source end
        end
        
        if targetSource then
            TriggerEvent("okokBilling:CreateCustomInvoice", targetSource, amount, label, label, jobName, societyName)
            return true
        else
            -- Offline billing fallback
            return IssueBill(officerSource, targetIdentifier, amount, label, jobName)
        end
    elseif Config.BillScript == 'jaksamBilling' then
        exports["billing_ui"]:createBill(officerIdentifier, targetIdentifier, label, amount, societyName, 'society')
        return true
    elseif Config.BillScript == 'tgg-billing' then
        local invoiceData = {
            items = {
               {
                    key = "parking",
                    label = label,
                    price = amount,
                    quantity = 1,
                    priceChange = false,
                    quantityChange = false
                }
            },
            total = amount,
            notes = nil, -- Optional
            sender = societyName, -- Your society job identifier e.g. 'police' or '__personal'
            senderId = officerIdentifier, -- Usually this is the player's identifier
            senderName = "Your sender name", -- Usually this is the player's name
            recipientId = targetIdentifier, -- The recipient's identifier
            recipientName = "The recipient name", -- The recipient's name
            taxPercentage = 10,
            senderCompanyName = societyName, -- If sender is '__personal' might be nil
        }
        exports["tgg-billing"]:CreateInvoice(invoiceData)
        return true
    elseif Config.BillScript == 'custom' then
        -- Your custom billing script here
        return true
    end
    
    return false
end
