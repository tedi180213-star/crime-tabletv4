Config = {}

-- General Settings
Config.TabletItem = 'crime_tablet' -- ox_inventory item name
Config.TabletCommand = 'crimetablet' -- Command to open tablet (backup)
Config.TabletKey = 'F5' -- Key to open tablet (when item is in inventory)

-- Tablet Account Settings
Config.TabletAccounts = {
    Enabled = true,
    DefaultPassword = 'password123', -- Can be changed by user
}

-- Boosting Settings
Config.Boosting = {
    Enabled = true,
    CooldownMinutes = 10, -- Cooldown between contracts
    PoliceRequired = 2, -- Minimum police online to start boost
    GroupSize = 4, -- Max group size for boosting
    CarScratchingPoints = 10, -- Points per successful car scratch
    HackDifficulty = { -- Hack minigame difficulty per class
        ['D'] = { length = 4, timer = 15 },
        ['C'] = { length = 5, timer = 12 },
        ['B'] = { length = 6, timer = 10 },
        ['A'] = { length = 7, timer = 8 },
        ['S'] = { length = 8, timer = 6 },
    },
    Classes = {
        ['D'] = {
            label = 'D Class',
            requiredLevel = 0,
            payout = { min = 2000, max = 5000 },
            cryptoPayout = { min = 1, max = 3 },
            vehicles = { 'asea', 'emperor', 'stanier', 'ingot', 'premier', 'stratum' },
        },
        ['C'] = {
            label = 'C Class',
            requiredLevel = 5,
            payout = { min = 5000, max = 10000 },
            cryptoPayout = { min = 3, max = 6 },
            vehicles = { 'fusilade', 'penumbra', 'prairie', 'blista', 'brioso' },
        },
        ['B'] = {
            label = 'B Class',
            requiredLevel = 15,
            payout = { min = 12000, max = 20000 },
            cryptoPayout = { min = 6, max = 12 },
            vehicles = { 'sultan', 'kuruma', 'schafter2', 'sentinel', 'zion' },
        },
        ['A'] = {
            label = 'A Class',
            requiredLevel = 30,
            payout = { min = 25000, max = 45000 },
            cryptoPayout = { min = 12, max = 25 },
            vehicles = { 'elegy2', 'jester', 'massacro', 'banshee', 'comet2' },
        },
        ['S'] = {
            label = 'S Class',
            requiredLevel = 50,
            payout = { min = 60000, max = 100000 },
            cryptoPayout = { min = 25, max = 50 },
            vehicles = { 'zentorno', 'turismor', 'entityxf', 'nero', 'krieger' },
        },
    },
    DropOffLocations = {
        vector4(1205.67, -3102.34, 5.54, 265.12),
        vector4(489.23, -1314.56, 29.27, 182.45),
        vector4(-583.12, -1634.78, 19.81, 95.67),
        vector4(1533.45, 6332.12, 24.11, 312.89),
    },
}

-- House Robbery Settings
Config.HouseRobbery = {
    Enabled = true,
    CooldownMinutes = 120, -- Cooldown between house robberies
    PoliceRequired = 1, -- Minimum police online
    GroupSize = 4, -- Max group size
    RequiredItems = {
        'lockpick',
        'thermal_device'
    },
    Payouts = {
        cash = { min = 15000, max = 45000 },
        gold = { min = 2, max = 8 },
        diamonds = { min = 1, max = 4 }
    },
    Locations = {
        vector3(265.45, 225.85, 101.68),
        vector3(-450.23, 560.12, 112.45),
        vector3(1150.67, -780.34, 67.89),
        vector3(-320.56, 1020.34, 209.45),
    }
}

-- Lockpicking Settings
Config.Lockpicking = {
    Enabled = true,
    CarLockpickItem = 'lockpick',
    HouseLockpickItem = 'thermal_device',
    UnlockTime = 5, -- seconds
    RequiredSkill = 0,
}

-- Heist Settings
Config.Heist = {
    Enabled = true,
    CooldownMinutes = 60, -- Cooldown between heists
    PoliceRequired = 3, -- Minimum police online
    MaxCrewSize = 4,
    Heists = {
        ['fleeca'] = {
            label = 'Fleeca Bank',
            description = 'Small bank robbery. Quick in and out.',
            difficulty = 'Easy',
            payout = { min = 50000, max = 80000 },
            requiredLevel = 0,
            minCrew = 2,
            maxCrew = 3,
            stages = { 'Setup', 'Hack Vault', 'Grab Cash', 'Escape' },
            image = 'fleeca.png',
        },
        ['paleto'] = {
            label = 'Paleto Bay Bank',
            description = 'Medium difficulty heist in Paleto Bay.',
            difficulty = 'Medium',
            payout = { min = 120000, max = 180000 },
            requiredLevel = 10,
            minCrew = 3,
            maxCrew = 4,
            stages = { 'Setup', 'Breach', 'Thermite Vault', 'Grab Cash', 'Escape' },
            image = 'paleto.png',
        },
        ['pacific'] = {
            label = 'Pacific Standard',
            description = 'High-risk heist. Heavy police response.',
            difficulty = 'Hard',
            payout = { min = 300000, max = 500000 },
            requiredLevel = 25,
            minCrew = 4,
            maxCrew = 4,
            stages = { 'Recon', 'Setup', 'Hack Security', 'Breach Vault', 'Escape' },
            image = 'pacific.png',
        },
        ['union'] = {
            label = 'Union Depository',
            description = 'Legendary heist. Maximum security.',
            difficulty = 'Extreme',
            payout = { min = 750000, max = 1200000 },
            requiredLevel = 50,
            minCrew = 4,
            maxCrew = 4,
            stages = { 'Intel', 'Equipment', 'Infiltrate', 'Crack Vault', 'Extract', 'Escape' },
            image = 'union.png',
        },
    },
}

-- Black Market Settings (Player Listings)
Config.BlackMarket = {
    Enabled = true,
    MaxListingsPerPlayer = 5, -- Max items a player can list at once
    ListingFeePercent = 5, -- 5% fee when listing an item
    MinPrice = 100, -- Minimum listing price
    MaxPrice = 500000, -- Maximum listing price
}

-- Dark Chat Settings
Config.DarkChat = {
    Enabled = true,
    MaxMessageLength = 200, -- Max characters per message
    Channels = { 'global', 'deals', 'crew', 'intel' },
    MessageHistory = 50, -- How many messages to keep per channel
}

-- Notification Settings
Config.Notifications = {
    position = 'top-right', -- top-left, top-right, bottom-left, bottom-right
    duration = 5000, -- ms
}
