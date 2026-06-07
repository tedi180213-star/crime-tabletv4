# 🔴 Tedi Crime Tablet

A premium FiveM ESX crime tablet resource featuring Boosting, Heists, and Black Market apps with a modern dark UI.

## Features

### 📱 Crime Tablet
- Modern dark UI with card-based layout
- Real-time stats and notifications
- Crypto wallet system
- Level progression

### 🚗 Boosting App
- Accept vehicle boost contracts (D → S Class)
- Steal, hack tracker, and deliver vehicles
- Hacking minigame to disable GPS tracker
- XP & level system to unlock higher class vehicles
- Crypto + cash rewards
- Police alerts on hack failures

### 🏦 Heist App
- 4 heist locations (Fleeca, Paleto, Pacific Standard, Union Depository)
- Crew system — invite nearby players
- Multi-stage progression
- Difficulty scaling with payouts up to $1.2M
- Police alert system

### 🏪 Black Market
- 5 categories: Weapons, Ammo, Attachments, Substances, Tools
- Stock system with refresh timer
- Direct ox_inventory integration
- Dynamic pricing

## Dependencies

- [es_extended](https://github.com/esx-framework/esx-legacy) (ESX Framework)
- [oxmysql](https://github.com/overextended/oxmysql) (Database)
- [ox_inventory](https://github.com/overextended/ox_inventory) (Inventory)

## Installation

1. **Download** and place `tedi-crimetablet` in your `resources` folder

2. **Run SQL** — Import `sql/install.sql` into your database

3. **Add item to ox_inventory** — Add the contents of `ox_inventory_item.lua` to your `ox_inventory/data/items.lua`

4. **Add tablet image** — Place `crime_tablet.png` in `ox_inventory/web/images/`

5. **Add to server.cfg:**
   ```
   ensure tedi-crimetablet
   ```

6. **Configure** — Edit `config.lua` to adjust:
   - Police requirements
   - Cooldowns
   - Payouts
   - Vehicle lists
   - Item prices
   - Drop-off locations

## Usage

- Give players the `crime_tablet` item via ox_inventory
- Players use the item to open the tablet
- Alternatively, press `F5` (configurable) or use `/crimetablet` command

## Configuration

All settings are in `config.lua`:
- `Config.Boosting` — Vehicle classes, payouts, hack difficulty
- `Config.Heist` — Heist locations, crew size, stages
- `Config.BlackMarket` — Categories, items, prices, stock

## Credits

Made by Tedi
