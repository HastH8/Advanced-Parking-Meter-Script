local QBCore = exports['qb-core']:GetCoreObject()

local models = Config.TargetPropModels

local bones = Config.BonesForTarget

local Jobs = Config.JobCanCheckParkingTime

function debug(message)
    if Config.debug then
        print("^1[DEBUG] ^7" .. message)
    end
end

function Notify(title, message, type, length)
    exports['kedi_ui']:ShowNotification({
        type = type or 'info', -- 'success', 'error', 'warning', 'info'
        title = title,
        message = message,
        duration = length or 5000, -- milliseconds
        icon = icon or 'fa-solid fa-square-parking' -- optional
    })
end

if Config.TargetSystem == "qb-target" then
    exports["qb-target"]:AddTargetModel(models, {
        options = {{
            type = "client",
            event = "meter:OpenMenu",
            icon = 'fa-solid fa-square-parking',
            label = translations.GetParkingTicket

        }},
        distance = 2.5
    })
    if Config.UseRobbery then
        exports["qb-target"]:AddTargetModel(models, {
            options = {{
                type = "client",
                event = "meter:PoliceCheckResult",
                icon = 'fa-solid fa-sack-dollar',
                label = translations.RobParkingMeter

            }},
            distance = 2.5
        })

    end
    if Config.AllCanCheckVehicle then
        exports['qb-target']:AddTargetBone(bones, {
            options = {{
                type = "client",
                event = "meter:CheckParkingTime",
                icon = 'fa-solid fa-square-parking',
                label = translations.TargetLabelCheckParkingTime

            }},
            distance = Config.TargetDistance
        })
    elseif not Config.AllCanCheckVehicle then
        exports['qb-target']:AddTargetBone(bones, {
            options = {{
                type = "client",
                event = "meter:CheckParkingTime",
                icon = 'fa-solid fa-square-parking',
                label = translations.TargetLabelCheckParkingTime,
                job = Jobs

            }},
            distance = Config.TargetDistance
        })
    end

elseif Config.TargetSystem == "ox-target" then
    -- Fix the export name
    exports.ox_target:addModel(models, {
        {
            name = 'parking_meter_ticket',
            icon = 'fa-solid fa-square-parking',
            label = translations.GetParkingTicket,
            onSelect = function()
                TriggerEvent('meter:OpenMenu')
            end,
            distance = 2.5
        }
    })
    
    if Config.UseRobbery then
        exports.ox_target:addModel(models, {
            {
                name = 'parking_meter_rob',
                icon = 'fa-solid fa-sack-dollar',
                label = translations.RobParkingMeter,
                onSelect = function()
                    TriggerEvent('meter:PoliceCheckResult')
                end,
                distance = 2.5
            }
        })
    end
    
    if Config.AllCanCheckVehicle then
        exports.ox_target:addGlobalVehicle({
            {
                name = 'check_parking_ticket',
                icon = "fa-solid fa-square-parking",
                label = translations.TargetLabelCheckParkingTime,
                onSelect = function()
                    TriggerEvent('meter:CheckParkingTime')
                end,
                distance = 2.5
            }
        })
    elseif not Config.AllCanCheckVehicle then
        exports.ox_target:addGlobalVehicle({
            {
                name = 'check_parking_ticket_job',
                icon = "fa-solid fa-square-parking",
                label = translations.TargetLabelCheckParkingTime,
                groups = Jobs,
                onSelect = function()
                    TriggerEvent('meter:CheckParkingTime')
                end,
                distance = 2.5
            }
        })
    end
end

if Config.UseRobbery then
    RegisterNetEvent('meter:AlertPolice', function(coords)

        if Config.Dispatch == "codem-dispatch" then
            local Text = 'A Parking Meter is being robbed'
            local Type = 'Robbery'

            local Data = {
                type = Type,
                header = 'Robbery in progress',
                text = Text,
                code = '10-51'
            }
        end

        local clientId = GetPlayerServerId(PlayerId())
        if Config.UseDispatch then
            if math.random(1, 100) <= Config.ChanceToAlertPolice then
                if Config.Dispatch == "emergencydispatch" then
                    TriggerServerEvent('meter:AlertPoliceServer', coords)
                elseif Config.Dispatch == "ps-dispatch" then
                    exports["ps-dispatch"]:ParkingmeterRobbery()
                elseif Config.Dispatch == "codem-dispatch" then
                    exports['codem-dispatch']:CustomDispatch(Data)
                elseif Config.Dispatch == "qs-dispatch" then
                    exports['qs-dispatch']:ToggleDuty(true)
                    local playerInfo = exports['qs-dispatch']:GetPlayerInfo()
                    local title = "10-60 - Parking Meter Robbery"
                    local message = "A Parking Meter is being robbed"

                    TriggerServerEvent('qs-dispatch:server:CreateDispatchCall', {
                        job = {'police'},
                        callLocation = playerInfo.coords,
                        callCode = {
                            code = 'Parking Meter Robbery',
                            snippet = '10-60'
                        },
                        message = message,
                        flashes = false,
                        image = nil,
                        blip = {
                            sprite = 488,
                            scale = 0.8,
                            colour = 1,
                            flashes = true,
                            text = 'Parking Meter Robbery',
                            time = (10 * 60 * 1000)
                        }
                    })
                end
            end
        end
    end)
end


function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        if not handle or handle == -1 then return end

        local success = true
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success

        EndFindVehicle(handle)
    end)
end


RegisterNetEvent('kedi_ui:client:Notify')
AddEventHandler('kedi_ui:client:Notify', function(data)
    Notify(data.title, data.message, data.type, data.length, data.icon)
end)
