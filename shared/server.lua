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
    if Config.Core == "esx" then
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
