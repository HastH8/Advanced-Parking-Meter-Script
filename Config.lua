Config = {}

Config.debug = false -- Enable / Disable Debug Messages

Config.Inv = 'codem-inventory' -- 'qb-inventory' , 'ox_inventory' , 'codem-inventory' , 'qs-inventory' , 'custom'

Config.Moneytype = 'bank' -- 'cash' , 'bank' , 'black_money'

Config.locales = "en"  -- Language

Config.TargetSystem = "ox-target" --ox-target or qb-target

Config.UTCTime = 0 --Put here you UTC time + you can get it from here for your region https://en.wikipedia.org/wiki/List_of_UTC_offsets

Config.DeleteOldEntries = true -- Delete unused stuff in sql

Config.ServerName = "" -- Bot Name

Config.BotName = "" -- Bot Name

Config.IconURL = "" -- Avatar

Config.Titel = "Parkingmeter system"  -- Titel

Config.MaxDistanceGetVehicles = 15 -- Distance from cars to automaticly get car plates

Config.MinParkingTime = 1 -- Min Time

Config.MaxParkingTime = 30 -- Max Time

Config.PricePerMinutes = 1 -- Price 

Config.AllCanCheckVehicle = true -- Put true if you want everyone to check if there is ticket or false and set jobs below

Config.JobCanCheckParkingTime =  {"ambulance", "mechanic", "police"} -- For OX-Target comment this if you use qb target and uncomment the line below
-- Config.JobCanCheckParkingTime = {["police"] = 0, ["sast"] = 0} -- For QB-Target

Config.BonesForTarget = { -- Bones for the targetsystem; currently on the car
    "seat_dside_f",
    "seat_pside_f",
    "seat_dside_r",
    "seat_pside_r",
    "door_dside_f",
    "door_dside_r",
    "door_pside_f",
    "door_pside_r"
}
	 
Config.TargetPropModels = { -- Props for the parkingmeter
    "prop_parknmeter_01",
    "prop_parknmeter_02",
}

--Rob setting
Config.UseRobbery = true -- True if you want it to be active

Config.MinPoliceCount = 0 -- Min police to start

Config.UseDispatch = true  -- Dispatch Notification? true or false

Config.ChanceToAlertPolice = 100 -- Chance to send a dispatch notification

Config.Dispatch = "emergencydispatch"  -- ps-dispatch, emergencydispatch, codem-dispatch or qs-dispatch add your own in shared/client.lua

Config.GetRobMoney  = math.random(100, 225) -- Money to get from the parkingmeter

Config.RobItem = "lockpick" -- Item required 

Config.RemoveItem = true -- Remove item after using

Config.RobParkingMeterDuration = 5000 -- Milisec to rob the parkingmeter

Config.RobParkingMeterProgressLabel = "Parking meter is being robbed!" -- Text from the progressbar

Config.SkillCheck = false -- if you want a skillCheck for your robbery 

Config.SkillcheckSettings = {'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'easy'} -- edit here the difficulty of the skillcheck

Config.TimeBeforeCanRobAgain = 1 -- Put here the time before the person can make a new robbery 5 = 5 minutes