Config.Coin = {
    namaTabel = 'gatrons_coin',
    maksimalTransaksi = 100000000,
    maksimalSaldo = 2000000000,
}

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
            coords = vec4(-1046.27, -2680.68, 12.97, 316.16),
            zOffset = 1.0,
            spawnDistance = 80.0,
            despawnDistance = 120.0,
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            label = 'Buka Gatrons Case Shop',
            icon = 'fa-solid fa-box-open',
            distance = 2.0,
        },
    },

    produk = {
        { box = 'classic_box', harga = 250 },
        { box = 'premium_box', harga = 750 },
    },
}
