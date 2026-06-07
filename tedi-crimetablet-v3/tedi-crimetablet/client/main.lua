-- ===== CRIME TABLET - CLIENT =====

local ESX = exports['es_extended']:getSharedObject()
local isTabletOpen = false
local hasTablet = false
local activeBoost = nil
local activeHeist = nil
local boostBlip = nil
local dropOffBlip = nil

-- ===== TABLET OPEN/CLOSE =====
RegisterCommand('crimetablet', function()
    if not isTabletOpen then
        OpenTablet()
    end
end, false)

-- Key mapping
RegisterKeyMapping('crimetablet', 'Open Crime Tablet', 'keyboard', Config.TabletKey)

-- ox_inventory item usage (export for item callback)
exports('useTablet', function(data, slot)
    if not isTabletOpen then
        OpenTablet()
    end
end)

-- Event-based fallback for older ox_inventory versions
RegisterNetEvent('crimetablet:useTablet')
AddEventHandler('crimetablet:useTablet', function()
    if not isTabletOpen then
        OpenTablet()
    end
end)

function OpenTablet()
    if isTabletOpen then return end
    isTabletOpen = true
    
    SetNuiFocus(true, true)
    
    -- Request player data from server
    ESX.TriggerServerCallback('crimetablet:getPlayerData', function(data)
        SendNUIMessage({
            action = 'open',
            playerData = data
        })
    end)
    
    -- Play tablet animation
    local playerPed = PlayerPedId()
    RequestAnimDict('cellphone@in_car@ds')
    while not HasAnimDictLoaded('cellphone@in_car@ds') do
        Wait(10)
    end
    TaskPlayAnim(playerPed, 'cellphone@in_car@ds', 'cellphone_text_read_base', 8.0, -8.0, -1, 49, 0, false, false, false)
end

function CloseTablet()
    if not isTabletOpen then return end
    isTabletOpen = false
    
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    
    -- Stop animation
    local playerPed = PlayerPedId()
    StopAnimTask(playerPed, 'cellphone@in_car@ds', 'cellphone_text_read_base', 1.0)
end

RegisterNUICallback('closeTablet', function(data, cb)
    CloseTablet()
    cb({})
end)

-- ===== BOOSTING SYSTEM =====
RegisterNUICallback('acceptBoostContract', function(data, cb)
    if activeBoost then
        cb({ success = false, message = 'You already have an active contract!' })
        return
    end
    
    -- Check police count
    ESX.TriggerServerCallback('crimetablet:canStartBoost', function(canStart, message)
        if canStart then
            TriggerServerEvent('crimetablet:startBoostContract', data.class, data.vehicle, data.reward)
            cb({ success = true })
        else
            cb({ success = false, message = message })
        end
    end)
end)

RegisterNetEvent('crimetablet:boostContractStarted')
AddEventHandler('crimetablet:boostContractStarted', function(contractData)
    activeBoost = contractData
    CloseTablet()
    
    -- Spawn target vehicle
    local vehicleHash = GetHashKey(contractData.vehicleModel)
    RequestModel(vehicleHash)
    while not HasModelLoaded(vehicleHash) do
        Wait(10)
    end
    
    local spawnCoords = contractData.spawnLocation
    local vehicle = CreateVehicle(vehicleHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, false)
    SetVehicleOnGroundProperly(vehicle)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleDoorLockStatus(vehicle, 2) -- Locked
    
    activeBoost.vehicle = vehicle
    activeBoost.stage = 'steal'
    
    -- Set GPS to vehicle
    boostBlip = AddBlipForCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z)
    SetBlipSprite(boostBlip, 225)
    SetBlipColour(boostBlip, 1) -- Red
    SetBlipRoute(boostBlip, true)
    SetBlipRouteColour(boostBlip, 1)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Target Vehicle')
    EndTextCommandSetBlipName(boostBlip)
    
    ShowNotification('~r~Target vehicle marked on GPS. Go steal it!')
    
    -- Monitor boost progress
    Citizen.CreateThread(function()
        MonitorBoostContract()
    end)
end)

function MonitorBoostContract()
    while activeBoost do
        Wait(500)
        
        if activeBoost.stage == 'steal' then
            -- Check if player is in the target vehicle
            local playerPed = PlayerPedId()
            if IsPedInVehicle(playerPed, activeBoost.vehicle, false) then
                activeBoost.stage = 'hack'
                RemoveBlip(boostBlip)
                
                SendNUIMessage({
                    action = 'contractUpdate',
                    stage = 'hack',
                    progress = 40
                })
                
                ShowNotification('~y~Vehicle acquired! Hack the tracker to continue.')
                
                -- Start hack after short delay
                Wait(2000)
                StartTrackerHack()
            end
            
        elseif activeBoost.stage == 'deliver' then
            -- Check if player reached drop-off
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dropOff = activeBoost.dropOff
            local dist = #(playerCoords - vector3(dropOff.x, dropOff.y, dropOff.z))
            
            if dist < 10.0 then
                -- Draw marker at drop-off
                DrawMarker(1, dropOff.x, dropOff.y, dropOff.z - 1.0, 0, 0, 0, 0, 0, 0, 5.0, 5.0, 1.0, 230, 57, 70, 100, false, true, 2, false, nil, nil, false)
            end
            
            if dist < 3.0 and IsPedInVehicle(PlayerPedId(), activeBoost.vehicle, false) then
                CompleteBoostContract()
            end
        end
    end
end

function StartTrackerHack()
    if not isTabletOpen then
        OpenTablet()
        Wait(500)
    end
    
    -- Trigger hack minigame via NUI
    local difficulty = Config.Boosting.HackDifficulty[activeBoost.class] or { length = 4, timer = 15 }
    
    SendNUIMessage({
        action = 'startHack',
        length = difficulty.length,
        timer = difficulty.timer
    })
end

RegisterNUICallback('hackResult', function(data, cb)
    if data.success then
        activeBoost.stage = 'deliver'
        
        -- Set drop-off location
        local dropOffs = Config.Boosting.DropOffLocations
        local dropOff = dropOffs[math.random(#dropOffs)]
        activeBoost.dropOff = { x = dropOff.x, y = dropOff.y, z = dropOff.z }
        
        -- Remove vehicle lock
        SetVehicleDoorLockStatus(activeBoost.vehicle, 1)
        
        -- Set GPS to drop-off
        dropOffBlip = AddBlipForCoord(dropOff.x, dropOff.y, dropOff.z)
        SetBlipSprite(dropOffBlip, 358)
        SetBlipColour(dropOffBlip, 2) -- Green
        SetBlipRoute(dropOffBlip, true)
        SetBlipRouteColour(dropOffBlip, 2)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentString('Drop-Off Point')
        EndTextCommandSetBlipName(dropOffBlip)
        
        SendNUIMessage({
            action = 'contractUpdate',
            stage = 'deliver',
            progress = 70
        })
        
        ShowNotification('~g~Tracker disabled! Deliver the vehicle to the drop-off.')
        CloseTablet()
    else
        -- Hack failed - alert police
        ShowNotification('~r~Hack failed! Police have been alerted!')
        TriggerServerEvent('crimetablet:hackFailed', activeBoost)
        
        -- Give player another chance after cooldown
        Wait(10000)
        if activeBoost and activeBoost.stage == 'hack' then
            ShowNotification('~y~Try hacking again...')
            StartTrackerHack()
        end
    end
    cb({})
end)

function CompleteBoostContract()
    if not activeBoost then return end
    
    -- Remove blips
    if dropOffBlip then RemoveBlip(dropOffBlip) end
    
    -- Delete vehicle
    local vehicle = activeBoost.vehicle
    TaskLeaveVehicle(PlayerPedId(), vehicle, 0)
    Wait(2000)
    DeleteEntity(vehicle)
    
    -- Notify server
    TriggerServerEvent('crimetablet:completeBoost', activeBoost.class, activeBoost.reward)
    
    ShowNotification('~g~Contract completed! Payment received.')
    
    SendNUIMessage({
        action = 'contractUpdate',
        stage = 'deliver',
        progress = 100
    })
    
    activeBoost = nil
end

-- ===== HEIST SYSTEM =====
RegisterNUICallback('inviteCrew', function(data, cb)
    TriggerServerEvent('crimetablet:inviteCrew', data.heistId)
    cb({ success = true })
end)

RegisterNUICallback('startHeist', function(data, cb)
    ESX.TriggerServerCallback('crimetablet:canStartHeist', function(canStart, message)
        if canStart then
            TriggerServerEvent('crimetablet:startHeist', data.heistId)
            cb({ success = true })
            CloseTablet()
        else
            cb({ success = false, message = message })
        end
    end)
end)

RegisterNetEvent('crimetablet:heistStarted')
AddEventHandler('crimetablet:heistStarted', function(heistData)
    activeHeist = heistData
    ShowNotification('~p~Heist started! Follow the objectives.')
end)

RegisterNetEvent('crimetablet:heistStageUpdate')
AddEventHandler('crimetablet:heistStageUpdate', function(stage, description)
    if activeHeist then
        activeHeist.currentStage = stage
        ShowNotification('~y~' .. description)
    end
end)

RegisterNetEvent('crimetablet:heistComplete')
AddEventHandler('crimetablet:heistComplete', function(payout)
    activeHeist = nil
    ShowNotification('~g~Heist completed! You earned $' .. payout)
end)

-- ===== BLACK MARKET (Player Listings) =====
RegisterNUICallback('getMarketListings', function(data, cb)
    TriggerServerEvent('crimetablet:getMarketListings')
    cb({})
end)

RegisterNUICallback('getMyListings', function(data, cb)
    TriggerServerEvent('crimetablet:getMyListings')
    cb({})
end)

RegisterNUICallback('listItem', function(data, cb)
    TriggerServerEvent('crimetablet:listItem', data.item, data.price, data.qty, data.desc)
    cb({ success = true })
end)

RegisterNUICallback('buyListing', function(data, cb)
    TriggerServerEvent('crimetablet:buyListing', data.listingId)
    cb({ success = true })
end)

RegisterNUICallback('removeListing', function(data, cb)
    TriggerServerEvent('crimetablet:removeListing', data.listingId)
    cb({ success = true })
end)

-- ===== DARK CHAT =====
RegisterNUICallback('sendChatMessage', function(data, cb)
    TriggerServerEvent('crimetablet:sendChatMessage', data.channel, data.message)
    cb({})
end)

RegisterNUICallback('getChatHistory', function(data, cb)
    TriggerServerEvent('crimetablet:getChatHistory', data.channel)
    cb({})
end)

RegisterNetEvent('crimetablet:chatMessage')
AddEventHandler('crimetablet:chatMessage', function(channel, msgData)
    SendNUIMessage({
        action = 'chatMessage',
        channel = channel,
        message = msgData
    })
end)

RegisterNetEvent('crimetablet:receiveChatHistory')
AddEventHandler('crimetablet:receiveChatHistory', function(channel, messages)
    SendNUIMessage({
        action = 'chatHistory',
        channel = channel,
        messages = messages
    })
end)

RegisterNetEvent('crimetablet:receiveMarketListings')
AddEventHandler('crimetablet:receiveMarketListings', function(listings)
    SendNUIMessage({
        action = 'marketListings',
        listings = listings
    })
end)

RegisterNetEvent('crimetablet:notification')
AddEventHandler('crimetablet:notification', function(msg, type)
    SendNUIMessage({
        action = 'notification',
        message = msg,
        type = type
    })
end)

-- ===== UTILITY FUNCTIONS =====
function ShowNotification(msg)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandThefeedPostTicker(false, true)
end

-- ===== CREW INVITE HANDLING =====
RegisterNetEvent('crimetablet:crewInvite')
AddEventHandler('crimetablet:crewInvite', function(fromPlayer, heistName)
    -- Show accept/decline prompt
    local accepted = false
    
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName('~y~' .. fromPlayer .. '~w~ invited you to ~r~' .. heistName .. '~w~\n~g~[E]~w~ Accept  ~r~[X]~w~ Decline')
    EndTextCommandDisplayHelp(0, false, true, 30000)
    
    Citizen.CreateThread(function()
        local timeout = GetGameTimer() + 30000
        while GetGameTimer() < timeout do
            Wait(0)
            if IsControlJustPressed(0, 38) then -- E key
                TriggerServerEvent('crimetablet:acceptCrewInvite', fromPlayer)
                ShowNotification('~g~You joined the heist crew!')
                return
            elseif IsControlJustPressed(0, 73) then -- X key
                TriggerServerEvent('crimetablet:declineCrewInvite', fromPlayer)
                ShowNotification('~r~Invite declined.')
                return
            end
        end
    end)
end)

-- ===== CLEANUP ON RESOURCE STOP =====
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    if isTabletOpen then
        CloseTablet()
    end
    
    if boostBlip then RemoveBlip(boostBlip) end
    if dropOffBlip then RemoveBlip(dropOffBlip) end
    
    if activeBoost and activeBoost.vehicle then
        DeleteEntity(activeBoost.vehicle)
    end
end)
