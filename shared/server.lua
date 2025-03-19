local QBCore = exports['qb-core']:GetCoreObject()
local itemRemoved = false

function additem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
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
    elseif Config.Inv == "custom" then
        debug("Custom inventory has not been integrated integrate your inv in shared/server.lua")
    else
        debug("Inventory not found")
    end
end

function removeitem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
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
    elseif Config.Inv == "custom" then
        debug("Custom inventory has not been integrated integrate your inv in shared/server.lua")
    else
        debug("Inventory not found")
    end
end

function hasitem(source, item, count)
    local Player = QBCore.Functions.GetPlayer(source)
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
    elseif Config.Inv == "custom" then
        debug("Custom inventory has not been integrated integrate your inv in shared/server.lua")
        return false
    else
        debug("Inventory not found")
        return false
    end
end

function addmoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return debug("Player not found")
    end
    if Config.Moneytype == "cash" then
        Player.Functions.AddMoney("cash", amount)
    elseif Config.Moneytype == "bank" then
        Player.Functions.AddMoney("bank", amount)
    elseif Config.Moneytype == "black_money" then
        additem(source, "black_money", amount)
    elseif Config.Moneytype == "custom" then
        debug("Custom money has not been integrated integrate your money in shared/server.lua")
    else
        debug("Money not found")
    end
end

function removemoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return debug("Player not found")
    end
    if Config.Moneytype == "cash" then
        Player.Functions.RemoveMoney("cash", amount)
    elseif Config.Moneytype == "bank" then
        Player.Functions.RemoveMoney("bank", amount)
    elseif Config.Moneytype == "black_money" then
        removeitemitem(source, "black_money", amount)
    elseif Config.Moneytype == "custom" then
        debug("Custom money has not been integrated integrate your money in shared/server.lua")
    else
        debug("Money not found")
    end
end

function hasmoney(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then
        return debug("Player not found")
    end
    if Config.Moneytype == "cash" then
        return Player.PlayerData.money.cash >= amount
    elseif Config.Moneytype == "bank" then
        return Player.PlayerData.money.bank >= amount
    elseif Config.Moneytype == "black_money" then
        return hasitem(source, "black_money", amount)
    elseif Config.Moneytype == "custom" then
        debug("Custom money has not been integrated integrate your money in shared/server.lua")
    else
        debug("Money not found")
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
