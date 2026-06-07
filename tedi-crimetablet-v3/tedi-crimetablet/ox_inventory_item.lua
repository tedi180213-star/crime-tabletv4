-- ===== ADD THIS TO YOUR ox_inventory/data/items.lua =====
-- Since we use ESX.RegisterUsableItem, you DON'T need the client export field.
-- Just add the basic item definition:

['crime_tablet'] = {
    label = 'Crime Tablet',
    weight = 500,
    stack = false,
    close = true,
    description = 'An encrypted tablet for underground operations',
},
