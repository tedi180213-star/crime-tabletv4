-- ===== CRIME TABLET - SERVER =====

local ESX = exports['es_extended']:getSharedObject()

-- Player cooldowns
local boostCooldowns = {}
local heistCooldowns = {}

-- ===== DATABASE INIT =====
MySQL.ready(function()
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `crime_tablet_players` (
            `identifier` VARCHAR(60) NOT NULL,
            `boost_level` INT DEFAULT 0,
            `boost_xp` INT DEFAULT 0,
            `boosts_completed` INT DEFAULT 0,
            `total_earnings` INT DEFAULT 0,
            `heist_level` INT DEFAULT 0,
            `crypto` INT DEFAULT 0,
            `scratching_points` INT DEFAULT 0,
            PRIMARY KEY (`identifier`)
        )
    ]])
    
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `crime_tablet_transactions` (
            `id` INT AUTO_INCREMENT,
            `identifier` VARCHAR(60) NOT NULL,
            `type` VARCHAR(20) NOT NULL,
            `label` VARCHAR(100) NOT NULL,
            `amount` INT NOT NULL,
            `timestamp` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        )
    ]])
end)

-- ===== GET PLAYER DATA =====
ESX.RegisterServerCallback('crimetablet:getPlayerData', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(nil) return end
    
    local identifier = xPlayer.getIdentifier()
    
    MySQL.query('SELECT * FROM crime_tablet_players WHERE identifier = ?', { identifier }, function(result)
        local data = {
            level = 0,
            xp = 0,
            cash = xPlayer.getMoney(),
            crypto = 0,
            boostLevel = 0,
            boostsCompleted = 0,
            totalEarnings = 0,
            heistLevel = 0,
            scratchingPoints = 0,
            transactions = {}
        }
        
        if result and result[1] then
            data.boostLevel = result[1].boost_level
            data.xp = result[1].boost_xp
            data.boostsCompleted = result[1].boosts_completed
            data.totalEarnings = result[1].total_earnings
            data.heistLevel = result[1].heist_level
            data.crypto = result[1].crypto
            data.scratchingPoints = result[1].scratching_points
            data.level = math.floor((result[1].boost_level + result[1].heist_level) / 2)
        else
            -- Create player record
            MySQL.insert('INSERT INTO crime_tablet_players (identifier) VALUES (?)', { identifier })
        end
        
        -- Get recent transactions
        MySQL.query('SELECT * FROM crime_tablet_transactions WHERE identifier = ? ORDER BY timestamp DESC LIMIT 10', { identifier }, function(transactions)
            if transactions then
                for _, t in ipairs(transactions) do
                    table.insert(data.transactions, {
                        label = t.label,
                        amount = t.amount,
                        time = FormatTime(t.timestamp)
                    })
                end
            end
            cb(data)
        end)
    end)
end)

-- ===== BOOSTING =====
ESX.RegisterServerCallback('crimetablet:canStartBoost', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false, 'Error') return end
    
    -- Check cooldown
    local identifier = xPlayer.getIdentifier()
    if boostCooldowns[identifier] and boostCooldowns[identifier] > os.time() then
        local remaining = boostCooldowns[identifier] - os.time()
        cb(false, 'Cooldown: ' .. math.ceil(remaining / 60) .. ' min remaining')
        return
    end
    
    cb(true, nil)
end)

RegisterNetEvent('crimetablet:startBoostContract')
AddEventHandler('crimetablet:startBoostContract', function(class, vehicle, reward)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    
    -- Set cooldown
    boostCooldowns[identifier] = os.time() + (Config.Boosting.CooldownMinutes * 60)
    
    -- Get vehicle model from config
    local classData = Config.Boosting.Classes[class]
    if not classData then return end
    
    -- Check police requirement for this specific class
    local policeCount = GetPoliceCount()
    if classData.requiredPolice and policeCount < classData.requiredPolice then
        TriggerClientEvent('crimetablet:notification', source, 'Not enough police online (' .. policeCount .. '/' .. classData.requiredPolice .. ')', 'error')
        return
    end
    
    local vehicleModel = classData.vehicles[math.random(#classData.vehicles)]
    
    -- Random spawn location (near player but not too close)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Generate spawn point offset
    local angle = math.random() * 2 * math.pi
    local distance = math.random(200, 500)
    local spawnX = playerCoords.x + (math.cos(angle) * distance)
    local spawnY = playerCoords.y + (math.sin(angle) * distance)
    
    local contractData = {
        class = class,
        vehicleModel = vehicleModel,
        vehicleLabel = vehicle,
        reward = reward,
        cryptoReward = math.random(classData.cryptoPayout.min, classData.cryptoPayout.max),
        spawnLocation = { x = spawnX, y = spawnY, z = 30.0, w = math.random(0, 360) },
        dropOff = nil
    }
    
    TriggerClientEvent('crimetablet:boostContractStarted', source, contractData)
end)

RegisterNetEvent('crimetablet:completeBoost')
AddEventHandler('crimetablet:completeBoost', function(class, reward)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local classData = Config.Boosting.Classes[class]
    if not classData then return end
    
    -- Pay the player
    xPlayer.addMoney(reward)
    
    -- Add crypto
    local cryptoReward = math.random(classData.cryptoPayout.min, classData.cryptoPayout.max)
    
    -- Update database
    MySQL.update([[
        UPDATE crime_tablet_players 
        SET boost_xp = boost_xp + 15,
            boosts_completed = boosts_completed + 1,
            total_earnings = total_earnings + ?,
            crypto = crypto + ?
        WHERE identifier = ?
    ]], { reward, cryptoReward, identifier })
    
    -- Check for level up
    MySQL.query('SELECT boost_xp, boost_level FROM crime_tablet_players WHERE identifier = ?', { identifier }, function(result)
        if result and result[1] then
            local xp = result[1].boost_xp
            local level = result[1].boost_level
            local xpNeeded = 100 + (level * 25)
            
            if xp >= xpNeeded then
                local newLevel = level + 1
                MySQL.update('UPDATE crime_tablet_players SET boost_level = ?, boost_xp = 0 WHERE identifier = ?', { newLevel, identifier })
                TriggerClientEvent('crimetablet:levelUp', source, 'boost', newLevel)
            end
        end
    end)
    
    -- Log transaction
    MySQL.insert('INSERT INTO crime_tablet_transactions (identifier, type, label, amount) VALUES (?, ?, ?, ?)', {
        identifier, 'boost', 'Boost Contract (' .. class .. ' Class)', reward
    })
    
    -- Alert police
    AlertPolice(source, 'Vehicle boosting completed')
end)

RegisterNetEvent('crimetablet:hackFailed')
AddEventHandler('crimetablet:hackFailed', function(boostData)
    local source = source
    AlertPolice(source, 'Failed vehicle hack attempt detected')
end)

RegisterNetEvent('crimetablet:addScratchingPoints')
AddEventHandler('crimetablet:addScratchingPoints', function(points)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    MySQL.update('UPDATE crime_tablet_players SET scratching_points = scratching_points + ? WHERE identifier = ?', { points, identifier })
end)

-- ===== HEIST SYSTEM (Includes House Robbery) =====
ESX.RegisterServerCallback('crimetablet:canStartHeist', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then cb(false, 'Error') return end
    
    local identifier = xPlayer.getIdentifier()
    
    -- Check cooldown
    if heistCooldowns[identifier] and heistCooldowns[identifier] > os.time() then
        local remaining = heistCooldowns[identifier] - os.time()
        cb(false, 'Cooldown: ' .. math.ceil(remaining / 60) .. ' min remaining')
        return
    end
    
    -- Check police
    local policeCount = GetPoliceCount()
    if policeCount < Config.Heist.PoliceRequired then
        cb(false, 'Not enough police online (' .. policeCount .. '/' .. Config.Heist.PoliceRequired .. ')')
        return
    end
    
    cb(true, nil)
end)

RegisterNetEvent('crimetablet:startHeist')
AddEventHandler('crimetablet:startHeist', function(heistId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local identifier = xPlayer.getIdentifier()
    local heistConfig = Config.Heist.Heists[heistId]
    if not heistConfig then return end
    
    -- Check for required items if house robbery
    if heistConfig.requiresItems then
        for _, item in ipairs(heistConfig.requiresItems) do
            local hasItem = exports.ox_inventory:GetItem(source, item, nil, true)
            if not hasItem or hasItem < 1 then
                TriggerClientEvent('crimetablet:notification', source, 'Missing required item: ' .. item, 'error')
                return
            end
        end
    end
    
    -- Set cooldown
    heistCooldowns[identifier] = os.time() + (Config.Heist.CooldownMinutes * 60)
    
    local heistData = {
        id = heistId,
        name = heistConfig.label,
        stages = heistConfig.stages,
        currentStage = 1,
        payout = math.random(heistConfig.payout.min, heistConfig.payout.max)
    }
    
    TriggerClientEvent('crimetablet:heistStarted', source, heistData)
    
    -- Alert police about potential heist
    AlertPolice(source, 'Suspicious activity near ' .. heistConfig.label)
end)

RegisterNetEvent('crimetablet:inviteCrew')
AddEventHandler('crimetablet:inviteCrew', function(heistId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local playerName = xPlayer.getName()
    
    local heistConfig = Config.Heist.Heists[heistId]
    if not heistConfig then return end
    
    -- Find nearby players (up to max crew size)
    local players = ESX.GetPlayers()
    local crewCount = 1
    for _, playerId in ipairs(players) do
        if playerId ~= source and crewCount < Config.Heist.MaxCrewSize then
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local dist = #(playerCoords - targetCoords)
            
            if dist < 10.0 then
                TriggerClientEvent('crimetablet:crewInvite', playerId, playerName, heistConfig.label)
                crewCount = crewCount + 1
            end
        end
    end
end)

RegisterNetEvent('crimetablet:acceptCrewInvite')
AddEventHandler('crimetablet:acceptCrewInvite', function(fromPlayer)
    local source = source
    TriggerClientEvent('crimetablet:crewMemberJoined', fromPlayer, GetPlayerName(source))
end)

-- ===== BLACK MARKET (Player Listings) =====
local marketListings = {}
local nextListingId = 1

RegisterNetEvent('crimetablet:getMarketListings')
AddEventHandler('crimetablet:getMarketListings', function()
    local source = source
    TriggerClientEvent('crimetablet:receiveMarketListings', source, marketListings)
end)

RegisterNetEvent('crimetablet:listItem')
AddEventHandler('crimetablet:listItem', function(itemName, price, qty, desc)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Validate
    if price < Config.BlackMarket.MinPrice or price > Config.BlackMarket.MaxPrice then
        TriggerClientEvent('crimetablet:notification', source, 'Invalid price!', 'error')
        return
    end
    
    -- Check player has the item
    local hasItem = exports.ox_inventory:GetItem(source, itemName, nil, true)
    if not hasItem or hasItem < qty then
        TriggerClientEvent('crimetablet:notification', source, "You don't have enough of this item!", 'error')
        return
    end
    
    -- Remove item from player inventory
    exports.ox_inventory:RemoveItem(source, itemName, qty)
    
    -- Create listing
    local listing = {
        id = nextListingId,
        owner = xPlayer.getIdentifier(),
        seller = 'Anonymous#' .. math.random(1000, 9999),
        item = itemName,
        price = price,
        qty = qty,
        desc = desc or '',
        time = os.time()
    }
    table.insert(marketListings, listing)
    nextListingId = nextListingId + 1
    
    TriggerClientEvent('crimetablet:notification', source, 'Item listed successfully!', 'success')
end)

RegisterNetEvent('crimetablet:buyListing')
AddEventHandler('crimetablet:buyListing', function(listingId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    -- Find listing
    local listingIndex = nil
    local listing = nil
    for i, l in ipairs(marketListings) do
        if l.id == listingId then
            listingIndex = i
            listing = l
            break
        end
    end
    
    if not listing then
        TriggerClientEvent('crimetablet:notification', source, 'Listing no longer available!', 'error')
        return
    end
    
    -- Cant buy your own listing
    if listing.owner == xPlayer.getIdentifier() then
        TriggerClientEvent('crimetablet:notification', source, "You can't buy your own listing!", 'error')
        return
    end
    
    -- Check money
    if xPlayer.getMoney() < listing.price then
        TriggerClientEvent('crimetablet:notification', source, 'Not enough money!', 'error')
        return
    end
    
    -- Process purchase
    xPlayer.removeMoney(listing.price)
    
    -- Give item to buyer
    exports.ox_inventory:AddItem(source, listing.item, listing.qty)
    
    -- Pay seller (minus fee)
    local fee = math.floor(listing.price * Config.BlackMarket.ListingFeePercent / 100)
    local sellerPayout = listing.price - fee
    
    -- Find seller and pay them
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local target = ESX.GetPlayerFromId(playerId)
        if target and target.getIdentifier() == listing.owner then
            target.addMoney(sellerPayout)
            TriggerClientEvent('crimetablet:notification', playerId, 'Your item sold for $' .. sellerPayout .. '!', 'success')
            break
        end
    end
    
    -- Remove listing
    table.remove(marketListings, listingIndex)
    
    -- Log transaction
    MySQL.insert('INSERT INTO crime_tablet_transactions (identifier, type, label, amount) VALUES (?, ?, ?, ?)', {
        xPlayer.getIdentifier(), 'market', 'Bought: ' .. listing.item, -listing.price
    })
    
    TriggerClientEvent('crimetablet:notification', source, 'Purchased ' .. listing.item .. '!', 'success')
end)

RegisterNetEvent('crimetablet:removeListing')
AddEventHandler('crimetablet:removeListing', function(listingId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    if not xPlayer then return end
    
    for i, listing in ipairs(marketListings) do
        if listing.id == listingId and listing.owner == xPlayer.getIdentifier() then
            -- Return item to player
            exports.ox_inventory:AddItem(source, listing.item, listing.qty)
            table.remove(marketListings, i)
            TriggerClientEvent('crimetablet:notification', source, 'Listing removed!', 'info')
            return
        end
    end
end)

-- ===== DARK CHAT =====
local chatHistory = {
    global = {},
    deals = {},
    crew = {},
    intel = {}
}

RegisterNetEvent('crimetablet:sendChatMessage')
AddEventHandler('crimetablet:sendChatMessage', function(channel, message)
    local source = source
    if not message or message == '' then return end
    if #message > Config.DarkChat.MaxMessageLength then
        message = string.sub(message, 1, Config.DarkChat.MaxMessageLength)
    end
    
    -- Validate channel
    local validChannel = false
    for _, ch in ipairs(Config.DarkChat.Channels) do
        if ch == channel then validChannel = true break end
    end
    if not validChannel then return end
    
    -- Create anonymous ID (consistent per player per session)
    local anonId = 'Anon#' .. (source * 7 % 9000 + 1000)
    
    local msgData = {
        sender = anonId,
        msg = message,
        time = os.time(),
        sourceId = source
    }
    
    -- Add to history
    table.insert(chatHistory[channel], msgData)
    if #chatHistory[channel] > Config.DarkChat.MessageHistory then
        table.remove(chatHistory[channel], 1)
    end
    
    -- Broadcast to all tablet users
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        TriggerClientEvent('crimetablet:chatMessage', playerId, channel, {
            sender = anonId,
            msg = message,
            time = 'now',
            self = (playerId == source)
        })
    end
end)

RegisterNetEvent('crimetablet:getChatHistory')
AddEventHandler('crimetablet:getChatHistory', function(channel)
    local source = source
    if chatHistory[channel] then
        local messages = {}
        for _, msg in ipairs(chatHistory[channel]) do
            table.insert(messages, {
                sender = msg.sender,
                msg = msg.msg,
                time = FormatTime(msg.time),
                self = (msg.sourceId == source)
            })
        end
        TriggerClientEvent('crimetablet:receiveChatHistory', source, channel, messages)
    end
end)

-- ===== UTILITY FUNCTIONS =====
function GetPoliceCount()
    local count = 0
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and xPlayer.getJob() and xPlayer.getJob().name == 'police' then
            count = count + 1
        end
    end
    return count
end

function AlertPolice(source, message)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    
    local players = ESX.GetPlayers()
    for _, playerId in ipairs(players) do
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer and xPlayer.getJob() and xPlayer.getJob().name == 'police' then
            TriggerClientEvent('crimetablet:policeAlert', playerId, message, playerCoords)
        end
    end
end

function FormatTime(timestamp)
    if not timestamp then return 'Unknown' end
    local now = os.time()
    local diff = now - timestamp
    
    if diff < 60 then return 'Just now'
    elseif diff < 3600 then return math.floor(diff / 60) .. ' min ago'
    elseif diff < 86400 then return math.floor(diff / 3600) .. 'h ago'
    else return math.floor(diff / 86400) .. 'd ago'
    end
end

-- ===== ITEM USAGE =====
ESX.RegisterUsableItem(Config.TabletItem, function(source)
    TriggerClientEvent('crimetablet:useTablet', source)
end)

print('^2[Crime Tablet]^0 Resource started successfully!')
print('^3[Crime Tablet]^0 D, C, B Classes now do NOT require police!')
print('^3[Crime Tablet]^0 Only A and S Classes require police online!')
print('^3[Crime Tablet]^0 House Robbery added to Heist app!')
