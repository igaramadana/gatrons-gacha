# Gatrons Gacha V2

A free, server-authoritative case-opening / gacha resource for FiveM.

`gatrons-gachav2` provides a CS-style case opening experience using `ox_inventory`, a React NUI, an NPC case shop powered by `ox_target`, a database-backed **Gatrons Coin** currency, and vehicle rewards with QB/Qbox garage integration.

> **Current behavior:** Gatrons Coin and pending gacha rewards are **per character (`citizenid`)**.  
> Using a case from `ox_inventory` only opens the preview UI. The case is removed **only after the player clicks `OPEN CASE`**.

---

## Features

- CS-style case opening UI with smooth continuous deceleration.
- Reel stops on the exact server-selected reward.
- Short stop delay before the result screen.
- Server-authoritative weighted RNG.
- `ox_inventory` usable case items.
- Case is **not consumed when the preview UI opens**.
- Case is consumed server-side only after `OPEN CASE` is clicked.
- Item reward images are fetched automatically from `ox_inventory`.
- Vehicle reward images support:
  - local UI paths;
  - external URLs;
  - `nui://` paths from another FiveM resource;
  - optional automatic image path generation from the vehicle model.
- Item rewards through `ox_inventory`.
- Vehicle rewards for QB-Core and Qbox.
- Qbox garage integration through `qbx_vehicles` / `qbx_garages`.
- QB garage support using the common `player_vehicles` schema.
- NPC case shop using `ox_target`.
- Proximity-based NPC spawning / despawning.
- Database-backed **Gatrons Coin**.
- Gatrons Coin is stored **per character (`citizenid`)**.
- Shop payments are validated server-side.
- Purchase success/error feedback uses `ox_lib` notifications.
- Coin exports:
  - `addCoin`
  - `removeCoin`
  - `getCoin`
  - `setCoin`
- Admin command:
  - `/setcoin [id] [amount]`
- `/setcoin` permission uses `group.admin`.
- Pending reward protection.
- Double-open / double-claim protection.
- React + TypeScript + Vite.
- Tailwind CSS v3.
- Motion animations.
- Quantico font.
- Bun frontend workflow.
- Browser preview for UI development.

---

# Requirements

## Required

- FiveM / FXServer
- `ox_lib`
- `oxmysql`
- `ox_inventory`
- `ox_target`
- MySQL or MariaDB

## Framework

Use one of the following.

### Qbox

Recommended resources:

```text
qbx_core
qbx_vehicles
qbx_garages
```

### QB-Core

Required:

```text
qb-core
```

For vehicle rewards, use a garage resource compatible with the standard QB `player_vehicles` structure, or modify the included garage bridge for your own schema.

---

# Installation

## 1. Install the resource

Place the resource inside your FiveM resources folder:

```text
resources/
└── [gatrons]/
    └── gatrons-gachav2/
```

It is recommended to keep the folder name exactly:

```text
gatrons-gachav2
```

The included `ox_inventory` item definitions reference this resource name in their exports.

If you rename the resource, update those exports too.

---

## 2. Database

For a fresh installation, import:

```text
install/gatrons_gacha.sql
```

The resource also contains runtime table setup/migration logic.

### Current coin ownership model

Gatrons Coin is **per character**, using:

```text
citizenid
```

Example:

```text
Account
├── Character A / citizenid ABC123 → 5,000 coin
└── Character B / citizenid XYZ789 → 250 coin
```

The two characters do not share their balance.

### Main coin table

```text
gatrons_coin
├── citizenid
├── balance
├── created_at
└── updated_at
```

`citizenid` is the primary key.

---

# ox_inventory Case Items

Open:

```text
install/ox_inventory/items.lua
```

Copy the case definitions into:

```text
ox_inventory/data/items.lua
```

Example:

```lua
['classic_box'] = {
    label = 'Classic Box',
    weight = 800,
    stack = true,
    close = true,
    consume = 1,
    description = 'Classic case dari Gatrons Development.',

    client = {
        image = 'classic-box.png',
        export = 'gatrons-gachav2.pakeBox',
    },

    server = {
        export = 'gatrons-gachav2.urusPakeBox',
    },
},
```

And:

```lua
['premium_box'] = {
    label = 'Premium Box',
    weight = 900,
    stack = true,
    close = true,
    consume = 1,
    description = 'Premium case dari Gatrons Development.',

    client = {
        image = 'premium-box.png',
        export = 'gatrons-gachav2.pakeBox',
    },

    server = {
        export = 'gatrons-gachav2.urusPakeBox',
    },
},
```

This is intentional.

The resource cancels the normal `ox_inventory` consumption during the initial **Use Item** phase.

The lifecycle is:

```text
Use case from ox_inventory
        ↓
Server validates the item
        ↓
Preview UI opens
        ↓
CASE IS STILL IN INVENTORY
        ↓
Player clicks OPEN CASE
        ↓
Server validates session + character + slot + item
        ↓
Server removes exactly 1 case
        ↓
Server selects and stores the reward
        ↓
Roulette starts
```

If the player closes the preview UI before clicking `OPEN CASE`, the case remains in their inventory.

---

# Framework Configuration

Configuration:

```text
shared/config.lua
```

Default:

```lua
Config.Framework = {
    mode = 'auto',

    resourceQbox = 'qbx_core',
    resourceQb = 'qb-core',
}
```

Available modes:

```lua
mode = 'auto'
mode = 'qbox'
mode = 'qb'
```

`auto` checks Qbox first and then QB-Core.

---

# Garage Configuration

Vehicle rewards are handled through:

```text
server/integrations/garage.lua
```

## Qbox

Example:

```lua
Config.Garasi = {
    garasiDefault = 'motelgarage',

    qbox = {
        resourceKendaraan = 'qbx_vehicles',
        resourceGarasi = 'qbx_garages',
        garasiDefault = 'motelgarage',
    },
}
```

The built-in Qbox bridge creates player vehicles through `qbx_vehicles` and validates garage names through `qbx_garages`.

## QB-Core

Example:

```lua
Config.Garasi = {
    qb = {
        resourceGarasi = 'qb-garages',
        garasiDefault = 'motelgarage',
        tabelKendaraan = 'player_vehicles',
        prefixPlate = 'GTR',

        wajibGarasiNyala = true,
    },
}
```

The built-in QB bridge expects the common `player_vehicles` fields used by standard QB setups.

If your garage uses a different SQL schema or custom exports, edit:

```text
server/integrations/garage.lua
```

Do not put custom garage SQL inside the gacha engine itself.

---

# Configuring Cases

Cases and reward pools are configured in:

```text
shared/config.lua
```

Example:

```lua
Config.Box = {
    classic_box = {
        label = 'Classic Box',

        deskripsi = 'Standard Gatrons case.',

        gambarTutup = 'gacha/classic-box-closed.png',
        gambarBuka = 'gacha/classic-box-open.png',

        aksen = '#58D878',

        hadiah = {
            -- rewards
        },
    },
}
```

Case UI images are relative to:

```text
ui/dist/
```

For frontend development, place source assets in:

```text
ui/public/
```

and rebuild the UI.

---

# Reward Configuration

## Item reward

```lua
{
    jenis = 'item',
    nama = 'lockpick',
    label = 'Lockpick',
    jumlah = 1,

    rarity = 'uncommon',
    weight = 1700,
}
```

For normal `ox_inventory` items you do **not** need to set `gambar`.

The server reads the item visual from `ox_inventory`.

If the item has a custom:

```lua
client.image
```

that image is used.

Otherwise the resource falls back to:

```text
<item_name>.png
```

from the configured `ox_inventory` image path.

---

## Vehicle reward

```lua
{
    jenis = 'vehicle',
    model = 'sultanrs',
    label = 'Karin Sultan RS',
    jumlah = 1,

    rarity = 'legendary',
    weight = 70,

    gambar = 'vehicles/sultanrs.webp',
}
```

You can optionally override the reward garage:

```lua
garasi = 'motelgarage'
```

Or define a garage for each framework:

```lua
garasi = {
    qbox = 'motelgarage',
    qb = 'pillboxgarage',
}
```

---

# Vehicle Reward Images

Vehicle reward images are configured directly from Lua.

Configuration:

```lua
Config.GambarVehicle = {
    otomatis = false,
    folder = 'vehicles',
    ekstensi = 'webp',
}
```

## Option 1 — Local path

Reward:

```lua
gambar = 'vehicles/sultanrs.webp'
```

For a ready-to-run build, place the image at:

```text
ui/dist/vehicles/sultanrs.webp
```

Recommended structure:

```text
ui/dist/
└── vehicles/
    ├── sultanrs.webp
    ├── comet6.webp
    └── jester4.webp
```

## Option 2 — External URL

```lua
gambar = 'https://your-cdn.com/vehicles/sultanrs.webp'
```

Use a direct image URL.

The remote host must allow the FiveM Chromium/NUI browser to load the image.

## Option 3 — Image from another FiveM resource

```lua
gambar = 'nui://vehicle_images/web/images/sultanrs.webp'
```

The target file must be exposed by the other resource.

## Option 4 — Automatic image path

Enable:

```lua
Config.GambarVehicle = {
    otomatis = true,
    folder = 'vehicles',
    ekstensi = 'webp',
}
```

Then:

```lua
{
    jenis = 'vehicle',
    model = 'sultanrs',
    label = 'Karin Sultan RS',
    rarity = 'legendary',
    weight = 70,
}
```

automatically resolves to:

```text
vehicles/sultanrs.webp
```

If a reward has an explicit `gambar`, that explicit value takes priority.

### Recommended vehicle image format

Recommended:

```text
Format       WebP / PNG
Background   Transparent
Resolution   800x450 or 1024x576
Angle        Front 3/4
Filename     Same as spawn model when auto mode is used
```

---

# Rarity & Weighted RNG

Default rarity structure:

```lua
Config.Rarity = {
    common = {
        label = 'Common',
        warna = '#8B95A7',
    },

    uncommon = {
        label = 'Uncommon',
        warna = '#58D878',
    },

    rare = {
        label = 'Rare',
        warna = '#3E8BFF',
    },

    epic = {
        label = 'Epic',
        warna = '#C54CFF',
    },

    legendary = {
        label = 'Legendary',
        warna = '#FFBE2E',
    },
}
```

Rewards use weights rather than percentages.

Example:

```lua
{ weight = 3000 }
{ weight = 1000 }
{ weight = 100 }
```

Weights do not need to total `100`.

Higher weight means a higher probability of being selected.

The winning reward is always selected on the **server**, never by React/NUI.

---

# NPC Case Shop

Shop configuration:

```text
shared/shop_config.lua
```

Example:

```lua
Config.Shop = {
    aktif = true,
    debugSpawn = true,

    keamanan = {
        jedaBeliMs = 650,
        maksimalJumlah = 10,
    },

    npc = {
        {
            model = 'a_m_m_business_01',

            coords = vector4(
                -56.98,
                -1096.62,
                26.42,
                24.0
            ),

            zOffset = 0.0,

            spawnDistance = 80.0,
            despawnDistance = 120.0,

            scenario = 'WORLD_HUMAN_CLIPBOARD',

            label = 'Buka Gatrons Case Shop',
            icon = 'fa-solid fa-box-open',

            distance = 2.0,
        },
    },

    produk = {
        {
            box = 'classic_box',
            harga = 250,
        },

        {
            box = 'premium_box',
            harga = 750,
        },
    },
}
```

## NPC spawning

NPCs use a proximity spawner.

Default behavior:

```text
Player enters spawnDistance
        ↓
NPC is created
        ↓
ox_target interaction is registered

Player leaves despawnDistance
        ↓
NPC is removed
```

This makes the shop more reliable when the resource is restarted while players are already online.

## NPC debug commands

```text
/gachashopdebug
/gachashoprespawn
```

Check the client F8 console for:

```text
[gatrons-gacha:shop]
```

---

# Gatrons Coin

Gatrons Coin is the shop currency.

It is stored **per character**, using `citizenid`.

Configuration:

```lua
Config.Coin = {
    namaTabel = 'gatrons_coin',

    maksimalTransaksi = 100000000,
    maksimalSaldo = 2000000000,
}
```

Shop prices are never trusted from the NUI.

The client only sends the requested box and quantity.

The server reads the real price from:

```lua
Config.Shop.produk
```

and calculates the final total server-side.

If payment succeeds but `ox_inventory:AddItem` fails, the resource attempts to refund the coin automatically.

---

# Coin Exports

All coin exports are **server exports**.

`target` can be:

```text
number → online player server ID
string → citizenid, useful for an offline character
```

## addCoin

```lua
local oke, saldo = exports['gatrons-gachav2']:addCoin(
    source,
    500,
    'daily_reward'
)
```

Offline character:

```lua
local oke, saldo = exports['gatrons-gachav2']:addCoin(
    'ABC123',
    500,
    'offline_reward'
)
```

## removeCoin

```lua
local oke, hasil, saldo = exports['gatrons-gachav2']:removeCoin(
    source,
    250,
    'payment'
)
```

When the balance is insufficient:

```text
oke = false
hasil = 'coin_kurang'
saldo = current balance
```

## getCoin

```lua
local saldo, err = exports['gatrons-gachav2']:getCoin(source)
```

Or:

```lua
local saldo, err = exports['gatrons-gachav2']:getCoin('ABC123')
```

## setCoin

```lua
local oke, saldo, citizenid = exports['gatrons-gachav2']:setCoin(
    source,
    5000,
    'staff_adjustment'
)
```

---

# Admin Command

```text
/setcoin [id] [amount]
```

Example:

```text
/setcoin 12 5000
```

This sets the **currently active character** of server ID `12` to exactly:

```text
5000 Gatrons Coin
```

Reset:

```text
/setcoin 12 0
```

## Permission

The command uses:

```text
group.admin
```

Server console is also allowed.

If your server already assigns admins to `group.admin`, no additional custom `gatrons.gacha.admin` ACE is required for `/setcoin`.

---

# Open Case Lifecycle

The case lifecycle is intentionally split into two stages.

## Stage 1 — Preview

```text
Player uses case in ox_inventory
        ↓
Server validates item / character / session
        ↓
Normal ox_inventory consume is cancelled
        ↓
Preview UI opens
```

At this point:

```text
the case is still inside ox_inventory
```

Closing the UI does not consume anything.

## Stage 2 — Open Case

After the player clicks:

```text
OPEN CASE
```

the server performs:

```text
Validate preview token
Validate character citizenid
Validate original inventory slot
Validate item still exists
Check pending opening
Lock session against double-click
Select reward server-side
Validate garage bridge if reward is a vehicle
Remove exactly 1 case
Save pending transaction
Send result data to NUI
Start roulette
```

If transaction storage fails after the case was removed, the resource attempts to return the same case and metadata.

---

# Pending Reward Protection

A reward is saved in the database before the roulette finishes.

This protects against:

- disconnects;
- crashes;
- UI interruptions;
- resource/client restarts;
- duplicate claims.

Pending reward ownership is based on:

```text
citizenid
```

so another character cannot claim the reward.

High-level lifecycle:

```text
rolling
   ↓
ready / claiming
   ↓
claimed
```

---

# Security Model

The client and NUI are treated as untrusted.

The NUI does **not** decide:

- reward;
- rarity;
- weight;
- shop price;
- coin balance;
- vehicle ownership;
- inventory delivery.

Important protections include:

- server-authoritative weighted RNG;
- server-side shop prices;
- server-side coin writes;
- case session tokens;
- character validation;
- original slot validation;
- case removal only after `OPEN CASE`;
- double-click / double-opening lock;
- pending transaction storage;
- duplicate claim protection;
- minimum opening duration guard;
- inventory capacity validation;
- garage bridge readiness validation;
- automatic shop refund if box delivery fails.

Do not move reward selection, payment logic, or vehicle ownership to React/client code.

---

# Notifications

Shop purchase feedback does not render an extra feedback panel inside the Shop UI.

Success and error messages use:

```text
ox_lib notify
```

This keeps the NUI clean and lets notification styling follow the server's existing `ox_lib` setup.

---

# Resource Start Order

## Qbox

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure ox_target

ensure qbx_core
ensure qbx_vehicles
ensure qbx_garages

ensure gatrons-gachav2
```

## QB-Core

```cfg
ensure ox_lib
ensure oxmysql
ensure ox_inventory
ensure ox_target

ensure qb-core
ensure qb-garages

ensure gatrons-gachav2
```

If you use a custom garage resource, start it before `gatrons-gachav2`.

---

# UI Development

The release build should already contain:

```text
ui/dist/
```

Normal server owners do **not** need Bun just to run the resource.

Bun is only required if you want to edit/build the frontend.

## Stack

```text
React
TypeScript
Vite
Tailwind CSS v3
Motion
Quantico
Bun
```

## Install dependencies

```bash
cd ui
bun install
```

## Browser preview

```bash
bun run dev
```

The development UI can be previewed in a normal browser without launching FiveM.

Some `cfx-nui-*` item image paths may not be available in a normal browser. This is expected.

## Production build

```bash
bun run build
```

Production output:

```text
ui/dist/
```

After rebuilding:

```cfg
restart gatrons-gachav2
```

---

# Adding Vehicle Images During UI Development

When editing frontend source, place local vehicle images in:

```text
ui/public/vehicles/
```

Example:

```text
ui/public/vehicles/
├── sultanrs.webp
├── comet6.webp
└── jester4.webp
```

Run:

```bash
bun run build
```

Vite copies them to:

```text
ui/dist/vehicles/
```

If you are not rebuilding the frontend, you can place final images directly inside:

```text
ui/dist/vehicles/
```

---

# Important Configuration Files

```text
shared/config.lua
```

Controls:

- framework;
- garage bridge;
- security timing;
- rarity;
- case definitions;
- reward pools;
- vehicle images.

```text
shared/shop_config.lua
```

Controls:

- Gatrons Coin limits;
- NPC locations;
- NPC spawning;
- shop security;
- box prices.

---

# Important Resource Files

```text
gatrons-gachav2/
├── client/
│   ├── main.lua
│   ├── nui.lua
│   └── shop.lua
│
├── server/
│   ├── admin.lua
│   ├── coin.lua
│   ├── gacha.lua
│   ├── main.lua
│   ├── shop.lua
│   ├── storage.lua
│   └── integrations/
│       ├── framework.lua
│       ├── garage.lua
│       └── inventory.lua
│
├── shared/
│   ├── config.lua
│   ├── shop_config.lua
│   └── utils.lua
│
├── install/
│   ├── gatrons_gacha.sql
│   └── ox_inventory/
│       ├── items.lua
│       └── images/
│
├── ui/
│   ├── public/
│   ├── src/
│   ├── dist/
│   ├── bun.lock
│   └── package.json
│
└── fxmanifest.lua
```

---

# Custom Garage Integration

If your garage is not compatible with the built-in QB/Qbox bridge, modify:

```text
server/integrations/garage.lua
```

Keep the rest of the gacha engine framework-agnostic.

The intended integration contract is:

```lua
GachaGarasi.cekSiap(hadiah)
GachaGarasi.kasihMobil(source, hadiah, citizenid)
```

Example success:

```lua
return true, {
    garage = 'motelgarage',
    vehicleId = 123,
}
```

Example failure:

```lua
return false, 'garage_ga_siap'
```

---

# Troubleshooting

## NPC does not appear

Confirm:

```text
ox_target = started
Config.Shop.aktif = true
```

Go within the configured:

```lua
spawnDistance
```

Then run:

```text
/gachashopdebug
```

Check F8 for:

```text
[gatrons-gacha:shop]
```

Force a respawn:

```text
/gachashoprespawn
```

Also check:

```lua
coords
zOffset
spawnDistance
despawnDistance
```

in:

```text
shared/shop_config.lua
```

---

## ox_target interaction does not appear

Make sure:

```cfg
ensure ox_target
ensure gatrons-gachav2
```

is in the correct order.

Check F8 for an `ox_target` registration error.

---

## NUI does not open

Make sure:

```text
ui/dist/index.html
```

exists.

If you edited the UI:

```bash
cd ui
bun run build
```

---

Check:

- the case is still in the original inventory slot;
- the item name matches the configured box name;
- the case item is registered in `ox_inventory`;
- F8/server console for `gagal_hapus_box`.

---

## Item reward image is missing

Check that the item exists in:

```text
ox_inventory
```

and that its image exists inside:

```text
ox_inventory/web/images/
```

If the item uses a custom:

```lua
client.image
```

make sure that filename exists.

---

## Vehicle image is missing

For:

```lua
gambar = 'vehicles/sultanrs.webp'
```

the final build needs:

```text
ui/dist/vehicles/sultanrs.webp
```

For automatic mode, make sure the filename matches the vehicle spawn model.

For an external URL, make sure it is a direct image URL accessible from FiveM NUI.

---

## Vehicle reward is not in the garage

### Qbox

Check:

```text
qbx_core
qbx_vehicles
qbx_garages
```

and verify the configured garage name exists.

### QB-Core

Check:

- `qb-core` is started;
- the garage resource is started;
- `player_vehicles` matches the bridge schema;
- the configured garage exists.

For a custom garage, edit:

```text
server/integrations/garage.lua
```

---

## `/setcoin` says no permission

The current command checks:

```text
group.admin
```

Make sure your admin principal inherits that ACE group.

---

## `/setcoin` changes the wrong balance

`/setcoin` always applies to the **currently active character** of the target server ID.

Example:

```text
/setcoin 12 5000
```

updates the active `citizenid` of player ID `12`.

---

## Character has 0 coin after switching character

This is expected.

Gatrons Coin is per-character.

Each `citizenid` owns an independent balance.

---

## Pending reward cannot be claimed on another character

This is expected and intentional.

Pending openings are also per-character.

Switch back to the character that started the opening.

---

inside this resource.

If you redistribute a modified version:

- clearly document framework/garage changes;
- keep server-side reward/payment validation;
- document any database migration;
- update the resource name inside `ox_inventory` exports if you rename it.

---

# Credits

Created by **Gatrons Development**.

Built for the FiveM ecosystem using:

- Cfx.re / FiveM
- Overextended ecosystem
- Qbox
- QBCore
- React
- TypeScript
- Vite
- Tailwind CSS
- Motion
- Bun

The case-opening concept is inspired by popular game case-opening interfaces, while the implementation and UI are built specifically for this resource.

---
