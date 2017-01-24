-- v0.3
-- guarantee that trailer and truck is loaded, before spawn

local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

--use this for debugging
function Chat(t)
	TriggerEvent("chatMessage", 'TRUCKER', { 0, 255, 255}, "" .. tostring(t))
end

--locations
--arrays
local TruckingCompany = {}
TruckingCompany[0] = {["x"] = -7.100,["y"] = -0.300, ["z"] = 73.077}
local TruckingTrailer = {}
TruckingTrailer[0] = {["x"] = 39.822, ["y"] = 25.884, ["z"] = 72.00}

local Truck = {"HAULER", "PACKER", "PHANTOM"}
local Trailer = {"TANKER", "TRAILERS", "TRAILERS2", "TRAILERLOGS"}

local MissionData = {
    [0] = {1212.4463, 2667.4351, 38.79, 5000}, --x,y,z,money
    [1] = {2574.5144, 328.5554, 108.45, 10000},
    [2] = {-2565.0894, 2345.8904, 33.06, 15000},
    [3] = {1706.7966, 4943.9897, 42.16, 20000},
    [4] = {196.5617, 6631.0967, 31.53, 30000}
}
local MISSION = {}
MISSION.start = false
MISSION.tailer = false
MISSION.truck = false
MISSION.trailerBlip = false
MISSION.currentDestinationBlip = false

MISSION.hashTruck = 0
MISSION.hashTrailer = 0

local currentMission = -1

local playerCoords
local playerPed

local GUI = {}
GUI.loaded          = false
GUI.showStartText   = false
GUI.showMenu        = false
GUI.selected        = {}
GUI.menu            = -1 --current menu

GUI.title           = {}
GUI.titleCount      = 0

GUI.desc            = {}
GUI.descCount       = 0

GUI.button          = {}
GUI.buttonCount     = 0

GUI.time            = 0

--text for mission
local text1 = false
local text2 = false

--Blips
local Blip = {}

--focus button color
local r = 0
local g= 128
local b = 192
local alpha = 200

function clear()
    MISSION.start = false
    SetBlipAlpha(MISSION.trailerBlip, 0)
    SetBlipAlpha(MISSION.currentDestinationBlip, 0)
    SetBlipRoute(MISSION.currentDestinationBlip, false) 
    
    if ( DoesEntityExist(MISSION.trailer) ) then
         SetEntityAsNoLongerNeeded(MISSION.trailer)
    end
    if ( DoesEntityExist(MISSION.truck) ) then
         SetEntityAsNoLongerNeeded(MISSION.truck)
         SetVehicleDoorsLocked(MISSION.truck, 2)
         SetVehicleUndriveable(MISSION.truck, true)
    end
    
    MISSION.start = false
    MISSION.trailer = false
    MISSION.truck = false
    MISSION.trailerBlip = false
    MISSION.currentDestinationBlip = false
    MISSION.hashTruck = 0
    MISSION.hashTrailer = 0
    currentMission = -1
end


Citizen.CreateThread(function() 
    while true do
        Wait(0)
        playerPed = GetPlayerPed(-1)
        playerCoords = GetEntityCoords(playerPed, 0)
        
        --if(IsControlPressed(1, Keys["N"])) then
        --    Chat(playerCoords)
		--end
        --if(IsControlPressed(1, Keys["M"])) then
			tick()
		--end 
    end
    
end)

function init()
    Citizen.Trace("intialize TruckerJob...")
    Blip["Company"] = AddBlipForCoord(TruckingCompany[0]["x"], TruckingCompany[0]["y"], TruckingCompany[0]["z"])
    SetBlipSprite(Blip["Company"], 318)
    SetBlipScale(Blip["Company"], 0.8)
	SetBlipAsShortRange(Blip["Company"], true)
   -- GUI.loaded = true
end
init()
--Draw Text / Menus
function tick()
    --use: playerCoods
    --
    --
    --Show menu, when player is near
    if( MISSION.start == false) then
        if( GetDistanceBetweenCoords( playerCoords, TruckingCompany[0]["x"], TruckingCompany[0]["y"], TruckingCompany[0]["z"] ) < 10) then
            if(GUI.showStartText == false) then
                GUI.drawStartText()
            end
                --key controlling
                if(IsControlPressed(1, Keys["N+"]) and GUI.showMenu == false) then
                    GUI.showMenu = true
                    GUI.menu = 0
                end
                if(IsControlPressed(1, Keys["N-"]) and GUI.showMenu == true) then
                    GUI.showMenu = false
                end
            else
                GUI.showStartText = false
        end --if GetDistanceBetweenCoords ...

        --menu
        if( GUI.loaded == false) then
            GUI.init() 
        end

        if( GUI.showMenu == true and GUI.menu ~= -1) then
            if( GUI.time == 0) then
                GUI.time = GetGameTimer()
            end
            if( (GetGameTimer() - GUI.time) > 100) then
                GUI.updateSelectionMenu(GUI.menu)
            end
            GUI.renderMenu(GUI.menu)
        end --if GUI.loaded == false
    elseif( MISSION.start == true ) then
        
        MISSION.markerUpdate(IsEntityAttached(MISSION.trailer))
        
        if( IsEntityAttached(MISSION.trailer) and text1 == false) then
            TriggerEvent("mt:missiontext", "Drive to the marked ~g~destination~w~.", 10000)
            text1 = true
        elseif( not IsEntityAttached(MISSION.trailer) and text2 == false ) then
            TriggerEvent("mt:missiontext", "Attach the ~o~trailer~w~.", 15000)
            text2 = true
        end
        
        local trailerCoords = GetEntityCoords(MISSION.trailer, 0)
        
        if ( GetDistanceBetweenCoords(currentMission[1], currentMission[2], currentMission[3], trailerCoords ) < 25 and  not IsEntityAttached(MISSION.trailer)) then
            TriggerEvent("mt:missiontext", "You gained $"..currentMission[4], 5000)
            MISSION.removeMarker()
            MISSION.getMoney()
            clear()
        elseif ( GetDistanceBetweenCoords(currentMission[1], currentMission[2], currentMission[3], trailerCoords ) < 25 and IsEntityAttached(MISSION.trailer) ) then
            TriggerEvent("mt:missiontext", "Arrived. Detach your ~o~trailer~w~ with ~r~H~w~", 15000)
            Wait(3000)
        end
        
        if ( IsEntityDead(MISSION.trailer) or IsEntityDead(MISSION.truck) ) then
            MISSION.removeMarker()
            clear()
        end
        
        Wait(1000)
    end --if MISSION.start == false
end



---------------------------------------
---------------------------------------
---------------------------------------
----------------MISSON-----------------
---------------------------------------   
---------------------------------------  
---------------------------------------
function GUI.optionMisson(trailerN)
    
    --select trailer
    MISSION.hashTrailer = GetHashKey(Trailer[trailerN + 1])
    RequestModel(MISSION.hashTrailer)
    
    while not HasModelLoaded(MISSION.hashTrailer) do
        Wait(1)
    end
    
    --select random truck
    local randomTruck = GetRandomIntInRange(1, #Truck)
    
    MISSION.hashTruck = GetHashKey(Truck[randomTruck])
	RequestModel(MISSION.hashTruck)
    
    while not HasModelLoaded(MISSION.hashTruck) do
        Wait(1)
    end
end

function GUI.Mission(missionN)
    currentMission = MissionData[missionN]
    GUI.showMenu = false
        
    --mission start
    MISSION.start = true
    MISSION.spawnTrailer()
    MISSION.spawnTruck()    
end

function MISSION.spawnTruck()
    
    MISSION.truck = CreateVehicle(MISSION.hashTruck, 12.1995, -1.174761, 73.000, 0.0, true, false)
    SetVehicleOnGroundProperly(MISSION.trailer)
    SetVehicleNumberPlateText(MISSION.truck, "M15510")
    SetVehRadioStation(MISSION.truck, "OFF")
	SetPedIntoVehicle(playerPed, MISSION.truck, -1)
    
    --important
    SetEntityAsMissionEntity(MISSION.truck, true, true);
end

function MISSION.spawnTrailer()
    MISSION.trailer = CreateVehicle(MISSION.hashTrailer, TruckingTrailer[0]["x"], TruckingTrailer[0]["y"], TruckingTrailer[0]["z"], 0.0, true, false)
    SetVehicleOnGroundProperly(MISSION.trailer)
    SetEntityAsMissionEntity(MISSION.trailer, -1)
    
    --setMarker on trailer
    MISSION.trailerMarker()
end

local oneTime = false

function MISSION.trailerMarker()
    MISSION.trailerBlip = AddBlipForEntity(MISSION.trailer)
        SetBlipSprite(MISSION.trailerBlip, 1)
        SetBlipColour(MISSION.trailerBlip, 17)
        SetBlipRoute(MISSION.trailerBlip, false)
end

function MISSION.markerUpdate(trailerAttached)
    if( trailerAttached ) then
        --doesn't work for a reason..
        --RemoveBlip(MISSION.trailerBlip)
        SetBlipAlpha(MISSION.trailerBlip, 0)
        
    elseif ( not trailerAttached and MISSION.trailerBlip) then
        SetBlipAlpha(MISSION.trailerBlip, 1000)
    end
    
    if( MISSION.currentDestinationBlip == false and trailerAttached ) then
        MISSION.currentDestinationBlip = AddBlipForCoord(currentMission[1], currentMission[2], currentMission[3])
        SetBlipSprite(MISSION.currentDestinationBlip, 1)
        SetBlipColour(MISSION.currentDestinationBlip, 2)
        SetBlipRoute(MISSION.currentDestinationBlip, true) 
    end
end

function MISSION.removeMarker()
    SetBlipAlpha(MISSION.currentDestinationBlip, 0) 
    SetBlipAlpha(MISSION.trailerBlip, 0)
end

function MISSION.getMoney()
    --local pedMoney = GetPedMoney(playerPed)
    --local gainedMoney = currentMission[4]
    --SetPedMoney(playerPed, pedMoney + gainedMoney)
    --Citizen.Trace("\n\n\n"..GetPedMoney(playerPed))
    --Citizen.Trace("\n You have $"..GetPedMoney(playerPed))
    --TriggerEvent("es:activateMoney", )
    --TriggerEvent("es:added")
    
end
---------------------------------------
---------------------------------------
---------------------------------------
-----------------MENU------------------
---------------------------------------   
---------------------------------------  
---------------------------------------
function GUI.drawStartText()
    TriggerEvent("mt:missiontext", "You want to be a trucker? Press ~r~N+~w~ to start.", 500)
    --GUI.showStartText = true
end

function GUI.renderMenu(menu)
    GUI.renderTitle()
    GUI.renderDesc()
    GUI.renderButtons(menu)
end

function GUI.init()
    GUI.loaded = true
    GUI.addTitle("You're a trucker now.", 0.425, 0.19, 0.45, 0.07 )
    GUI.addDesc("Choose a trailer.", 0.575, 0.375, 0.15, 0.30 )

    --menu, title, function, position
    GUI.addButton(0, "RON Tanker trailer", GUI.optionMisson, 0.35, 0.25, 0.3, 0.05 )
    GUI.addButton(0, "Container trailer", GUI.optionMisson, 0.35, 0.30, 0.3, 0.05 )
    GUI.addButton(0, "Articulated trailer", GUI.optionMisson, 0.35, 0.35, 0.3, 0.05 )
    GUI.addButton(0, "Log trailer", GUI.optionMisson, 0.35, 0.40, 0.3, 0.05 )
    GUI.addButton(0, " ", GUI.null, 0.35, 0.45, 0.3, 0.05)
    GUI.addButton(0, "Exit Menu", GUI.exit, 0.35, 0.50, 0.3, 0.05 )
    
    GUI.buttonCount = 0
    
    GUI.addButton(1, "Mission 1 [ 5.000$ ]", GUI.Mission, 0.35, 0.25, 0.3, 0.05)
    GUI.addButton(1, "Mission 2 [ 10.000$ ]", GUI.Mission, 0.35, 0.30, 0.3, 0.05)
    GUI.addButton(1, "Mission 3 [ 15.000$ ]", GUI.Mission, 0.35, 0.35, 0.3, 0.05)
    GUI.addButton(1, "Mission 4 [ 20.000$ ]", GUI.Mission, 0.35, 0.40, 0.3, 0.05)
    GUI.addButton(1, "Mission 5 [ 30.000$ ]", GUI.Mission, 0.35, 0.45, 0.3, 0.05)
    GUI.addButton(1, "Exit Menu", GUI.Exit, 0.35, 0.50, 0.3, 0.05)
end

--Render stuff
function GUI.renderTitle()
    for id, settings in pairs(GUI.title) do
        local screen_w = 0
        local screen_h = 0
        screen_w, screen_h = GetScreenResolution(0,0)
        boxColor = {0,0,0,255}
		SetTextFont(0)
		SetTextScale(0.0, 0.40)
		SetTextColour(255, 255, 255, 255)
		SetTextCentre(true)
		SetTextDropshadow(0, 0, 0, 0, 0)
		SetTextEdge(0, 0, 0, 0, 0)
		SetTextEntry("STRING")
        AddTextComponentString(settings["name"])
        DrawText((settings["xpos"] + 0.001), (settings["ypos"] - 0.015))
        --AddTextComponentString(settings["name"])
        GUI.renderBox(
            settings["xpos"], settings["ypos"], settings["xscale"], settings["yscale"],
            boxColor[1], boxColor[2], boxColor[3], boxColor[4]
        )
    end
end

function GUI.renderDesc()
		for id, settings in pairs(GUI.desc) do
		local screen_w = 0
		local screen_h = 0
		screen_w, screen_h =  GetScreenResolution(0, 0)
		boxColor = {0,0,0,240}
		SetTextFont(0)
		SetTextScale(0.0, 0.37)
		SetTextColour(255, 255, 255, 255)
		SetTextDropShadow(0, 0, 0, 0, 0)
		SetTextEdge(0, 0, 0, 0, 0)
		SetTextEntry("STRING")
		AddTextComponentString(settings["name"] .. "\n" .."\n" .."Num8 for UP" .. "\n" .. "Num2 for DOWN" .. "\n" .. "Num5 to Select".. "\n" .."Hold H to Detach" .. "\n" .. "Trainer")
		DrawText((settings["xpos"] - 0.06), (settings["ypos"] - 0.13))
		AddTextComponentString(settings["name"])
		GUI.renderBox(
            settings["xpos"], settings["ypos"], settings["xscale"], settings["yscale"],
            boxColor[1], boxColor[2], boxColor[3], boxColor[4]
        )
		end
end

function GUI.renderButtons(menu)
	for id, settings in pairs(GUI.button[menu]) do
		local screen_w = 0
		local screen_h = 0
		screen_w, screen_h =  GetScreenResolution(0, 0)
		boxColor = {0,0,0,100}
		if(settings["active"]) then
			boxColor = {r,g,b,alpha}
		end
		SetTextFont(0)
		SetTextScale(0.0, 0.35)
		SetTextColour(255, 255, 255, 255)
		SetTextCentre(true)
		SetTextDropShadow(0, 0, 0, 0, 0)
		SetTextEdge(0, 0, 0, 0, 0)
		SetTextEntry("STRING")
		AddTextComponentString(settings["name"])
		DrawText((settings["xpos"] + 0.001), (settings["ypos"] - 0.015))
		--AddTextComponentString(settings["name"])
		GUI.renderBox(
            settings["xpos"], settings["ypos"], settings["xscale"],
            settings["yscale"], boxColor[1], boxColor[2], boxColor[3], boxColor[4]
        )
	 end     
end

function GUI.renderBox(xpos, ypos, xscale, yscale, color1, color2, color3, color4)
	DrawRect(xpos, ypos, xscale, yscale, color1, color2, color3, color4);
end

--adding stuff
function GUI.addTitle(name, xpos, ypos, xscale, yscale)
	GUI.title[GUI.titleCount] = {}
	GUI.title[GUI.titleCount]["name"] = name
	GUI.title[GUI.titleCount]["xpos"] = xpos
	GUI.title[GUI.titleCount]["ypos"] = ypos 	
	GUI.title[GUI.titleCount]["xscale"] = xscale
	GUI.title[GUI.titleCount]["yscale"] = yscale
end

function GUI.addDesc(name, xpos, ypos, xscale, yscale)
	GUI.desc[GUI.descCount] = {}
	GUI.desc[GUI.descCount]["name"] = name
	GUI.desc[GUI.descCount]["xpos"] = xpos
	GUI.desc[GUI.descCount]["ypos"] = ypos 	
	GUI.desc[GUI.descCount]["xscale"] = xscale
	GUI.desc[GUI.descCount]["yscale"] = yscale
end

function GUI.addButton(menu, name, func, xpos, ypos, xscale, yscale)
    if(not GUI.button[menu]) then
        GUI.button[menu] = {}
        GUI.selected[menu] = 0
    end
    GUI.button[menu][GUI.buttonCount] = {}
	GUI.button[menu][GUI.buttonCount]["name"] = name
	GUI.button[menu][GUI.buttonCount]["func"] = func
	GUI.button[menu][GUI.buttonCount]["xpos"] = xpos
	GUI.button[menu][GUI.buttonCount]["ypos"] = ypos 	
	GUI.button[menu][GUI.buttonCount]["xscale"] = xscale
	GUI.button[menu][GUI.buttonCount]["yscale"] = yscale
    GUI.button[menu][GUI.buttonCount]["active"] = 0
    GUI.buttonCount = GUI.buttonCount + 1
end

function GUI.Null()
end

function GUI.Exit()
    GUI.hiddenMenu1 = true
	GUI.hiddenMenu2 = true
	print("Exit menu")
end

--update stuff
function GUI.updateSelectionMenu(menu)
    if( IsControlPressed(0, Keys["DOWN"]) ) then
        if( GUI.selected[menu] < #GUI.button[menu] ) then
            GUI.selected[menu] = GUI.selected[menu] + 1
        end
    elseif( IsControlPressed(0, Keys["TOP"]) ) then
        if( GUI.selected[menu] > 0 ) then
            GUI.selected[menu] = GUI.selected[menu] - 1 
        end
    elseif( IsControlPressed(0, Keys["ENTER"]) ) then
        if( type(GUI.button[menu][GUI.selected[menu]]["func"]) == "function" ) then
            --remember variable GUI.selected[menu]
            
            --call mission functions
            GUI.button[menu][GUI.selected[menu]]["func"](GUI.selected[menu])
            
            
            GUI.menu = 1
            GUI.selected[menu] = 0
            if( not GUI.menu ) then
                GUI.menu = -1
            end
            
            --GUI.button[menu][GUI.selected[menu]]["func"](GUI.selected[menu])
        else
            Citizen.Trace("\n Failes to call function! - Selected Menu: "..GUI.selected[menu].." \n")
        end
        GUI.time = 0
    end
    local i = 0
    for id, settings in ipairs(GUI.button[menu]) do
        GUI.button[menu][i]["active"] = false
        if( i == GUI.selected[menu] ) then
            GUI.button[menu][i]["active"] = true
        end
        i = i + 1
    end
end