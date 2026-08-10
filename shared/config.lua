Config = {}

Config.Debug = false

Config.Keamanan = {
    jedaPakeMs = 1200,
    minimalAnimasiMs = 5600,
    batasId = 64,
    maksimalPending = 1,
}

Config.Framework = {
    -- auto = deteksi qbx_core dulu, lalu qb-core.
    -- Bisa dipaksa jadi 'qbox' atau 'qb' kalau server kamu cuma mau satu mode.
    mode = 'auto',
    resourceQbox = 'qbx_core',
    resourceQb = 'qb-core',
}

Config.Garasi = {
    -- Fallback kalau config per-framework tidak diisi.
    garasiDefault = 'garasibandara',

    qbox = {
        resourceKendaraan = 'qbx_vehicles',
        resourceGarasi = 'qbx_garages',
        garasiDefault = 'garasibandara', -- sesuai qbx_garages yang kamu upload
    },

    qb = {
        resourceGarasi = 'qb-garages',
        garasiDefault = 'garasibandara', -- ganti kalau nama garage QB kamu beda
        tabelKendaraan = 'player_vehicles',
        prefixPlate = 'GTR',

        -- true = reward vehicle ditahan kalau qb-garages belum started.
        -- false = tetap insert ke player_vehicles walau resource garage sedang mati.
        wajibGarasiNyala = true,
    },
}

Config.Rarity = {
    common = { label = 'Common', warna = '#8B95A7' },
    uncommon = { label = 'Uncommon', warna = '#58D878' },
    rare = { label = 'Rare', warna = '#3E8BFF' },
    epic = { label = 'Epic', warna = '#C54CFF' },
    legendary = { label = 'Legendary', warna = '#FFBE2E' },
}

-- gambar reward item TIDAK perlu ditulis.
-- UI otomatis ambil client.image dari ox_inventory; kalau tidak ada, fallback ke <item_name>.png.
-- gambar manual hanya perlu untuk vehicle/custom reward yang memang tidak berasal dari ox_inventory.
Config.Box = {
    classic_box = {
        label = 'Classic Box',
        deskripsi = 'Standard Gatrons case dengan campuran utility item dan satu hadiah kendaraan langka.',
        gambarTutup = 'gacha/classic-box-closed.png',
        gambarBuka = 'gacha/classic-box-open.png',
        aksen = '#58D878',
        hadiah = {
            { jenis = 'item', nama = 'water', label = 'Water', jumlah = 3, rarity = 'common', weight = 3200 },
            { jenis = 'item', nama = 'bandage', label = 'Bandage', jumlah = 2, rarity = 'common', weight = 2800 },
            { jenis = 'item', nama = 'lockpick', label = 'Lockpick', jumlah = 1, rarity = 'uncommon', weight = 1700 },
            { jenis = 'vehicle', model = 'bf400', label = 'BF400', jumlah = 1, rarity = 'legendary', weight = 70, gambar='https://docs.fivem.net/vehicles/bf400.webp' },
        },
    },
    premium_box = {
        label = 'Premium Box',
        deskripsi = 'Premium Gatrons case dengan peluang rare, epic, dan legendary yang lebih tinggi.',
        gambarTutup = 'gacha/premium-box-closed.png',
        gambarBuka = 'gacha/premium-box-open.png',
        aksen = '#F0BC45',
        hadiah = {
            { jenis = 'item', nama = 'bandage', label = 'Bandage', jumlah = 5, rarity = 'uncommon', weight = 2400 },
            { jenis = 'item', nama = 'lockpick', label = 'Lockpick', jumlah = 3, rarity = 'uncommon', weight = 2200 },
            { jenis = 'vehicle', model = 'comet6', label = 'Pfister Comet S2', jumlah = 1, rarity = 'epic', weight = 5000, gambar='https://docs.fivem.net/vehicles/comet6.webp' },
            { jenis = 'vehicle', model = 'jester4', label = 'Dinka Jester RR', jumlah = 1, rarity = 'legendary', weight = 90, gambar='https://docs.fivem.net/vehicles/jester4.webp' },
        },
    },
}
