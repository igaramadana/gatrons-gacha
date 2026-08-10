GachaShop = {}

local terakhirBeli = {}

local function ambilConfig()
    return Config.Shop or {}
end

local function bolehBelanja(source)
    local cfg = ambilConfig()
    local security = cfg.keamanan or {}
    local jeda = tonumber(security.jedaBeliMs) or 650
    local sekarang = GetGameTimer()
    local terakhir = terakhirBeli[source] or 0

    if sekarang - terakhir < jeda then
        return false
    end

    terakhirBeli[source] = sekarang
    return true
end

local function cariProduk(namaBox)
    local cfg = ambilConfig()

    for index, produk in ipairs(cfg.produk or {}) do
        if produk.box == namaBox then
            return produk, index
        end
    end

    return nil
end

local function bikinProdukUi(source, produk)
    local box = Config.Box[produk.box]
    if not box then return nil end

    return {
        nama = produk.box,
        label = produk.label or box.label or produk.box,
        deskripsi = produk.deskripsi or box.deskripsi or '',
        harga = math.max(0, math.floor(tonumber(produk.harga) or 0)),
        gambar = produk.gambar or box.gambarTutup,
        aksen = produk.aksen or box.aksen or '#58D878',
        dimiliki = GachaInventory.hitungItem(source, produk.box),
    }
end

function GachaShop.ambilData(source)
    local cfg = ambilConfig()
    if cfg.aktif == false then
        return nil, 'shop_mati'
    end

    if not GachaCoin.udahSiap() then
        return nil, 'coin_belum_siap'
    end

    local citizenid, errCitizen = GachaFramework.ambilCitizenId(source)
    if not citizenid then
        return nil, errCitizen or 'citizenid_ga_ketemu'
    end

    local saldo, errSaldo = GachaCoin.ambil(source)
    if saldo == nil then
        return nil, errSaldo or 'saldo_gagal'
    end

    local produkUi = {}
    for _, produk in ipairs(cfg.produk or {}) do
        local data = bikinProdukUi(source, produk)
        if data then produkUi[#produkUi + 1] = data end
    end

    return {
        namaPlayer = GetPlayerName(source) or 'Citizen',
        citizenid = citizenid,
        saldo = saldo,
        labelCoin = 'GATRONS COIN',
        maksimalJumlah = math.max(1, math.floor(tonumber((cfg.keamanan or {}).maksimalJumlah) or 10)),
        produk = produkUi,
    }
end

function GachaShop.beli(source, namaBox, jumlah)
    local cfg = ambilConfig()
    if cfg.aktif == false then
        return { oke = false, kode = 'shop_mati', pesan = 'Case shop sedang tidak aktif.' }
    end

    if not bolehBelanja(source) then
        return { oke = false, kode = 'terlalu_cepat', pesan = 'Tunggu sebentar sebelum membeli lagi.' }
    end

    namaBox = GachaUtils.bersihinTeks(namaBox, 64)
    jumlah = tonumber(jumlah)

    if not namaBox or not jumlah then
        return { oke = false, kode = 'payload_ngaco', pesan = 'Data pembelian tidak valid.' }
    end

    jumlah = math.floor(jumlah)
    local maksimal = math.max(1, math.floor(tonumber((cfg.keamanan or {}).maksimalJumlah) or 10))
    if jumlah < 1 or jumlah > maksimal then
        return { oke = false, kode = 'jumlah_ngaco', pesan = ('Maksimal pembelian %s box sekali transaksi.'):format(maksimal) }
    end

    local produk = cariProduk(namaBox)
    local box = Config.Box[namaBox]

    if not produk or not box then
        return { oke = false, kode = 'produk_ga_ada', pesan = 'Box tersebut tidak dijual di shop.' }
    end

    local hargaSatuan = math.floor(tonumber(produk.harga) or 0)
    if hargaSatuan <= 0 then
        return { oke = false, kode = 'harga_ngaco', pesan = 'Harga box belum dikonfigurasi dengan benar.' }
    end

    if not GachaInventory.itemAda(namaBox) then
        return { oke = false, kode = 'item_ga_ada', pesan = 'Item box belum terdaftar di ox_inventory.' }
    end

    if not GachaInventory.bisaNampung(source, namaBox, jumlah) then
        return { oke = false, kode = 'inventory_penuh', pesan = 'Inventory kamu tidak cukup untuk menampung box.' }
    end

    local total = hargaSatuan * jumlah
    local bayarOke, saldoAtauErr, saldoKalauGagal = GachaCoin.kurangin(source, total, ('beli_%s_x%s'):format(namaBox, jumlah))

    if not bayarOke then
        local saldo = tonumber(saldoKalauGagal) or 0
        return {
            oke = false,
            kode = saldoAtauErr or 'bayar_gagal',
            pesan = saldoAtauErr == 'coin_kurang' and 'Gatrons Coin kamu tidak cukup.' or 'Pembayaran gagal diproses.',
            saldo = saldo,
        }
    end

    local kasihOke, infoItem = GachaInventory.kasihItem(source, namaBox, jumlah)
    if not kasihOke then
        local rollbackOke, rollbackSaldo = GachaCoin.tambah(source, total, ('rollback_%s_x%s'):format(namaBox, jumlah))

        if not rollbackOke then
            print(('^1[gatrons-gacha] CRITICAL: gagal refund %s coin ke source %s setelah AddItem gagal (%s).^7'):format(
                total,
                source,
                tostring(infoItem)
            ))
        end

        return {
            oke = false,
            kode = infoItem or 'gagal_kasih_box',
            pesan = rollbackOke and 'Box gagal dimasukkan. Gatrons Coin sudah dikembalikan.' or 'Box gagal dimasukkan dan refund perlu dicek staff.',
            saldo = rollbackOke and rollbackSaldo or saldoAtauErr,
        }
    end

    local saldoBaru = tonumber(saldoAtauErr) or 0
    local dimiliki = GachaInventory.hitungItem(source, namaBox)

    return {
        oke = true,
        pesan = ('Berhasil membeli %sx %s.'):format(jumlah, box.label or namaBox),
        saldo = saldoBaru,
        namaBox = namaBox,
        jumlah = jumlah,
        dimiliki = dimiliki,
    }
end

lib.callback.register('gatrons-gacha:server:ambilShop', function(source)
    local data, err = GachaShop.ambilData(source)
    if data then return { oke = true, data = data } end

    return {
        oke = false,
        kode = err or 'shop_gagal',
        pesan = 'Case shop belum siap. Coba lagi sebentar.',
    }
end)

lib.callback.register('gatrons-gacha:server:beliBox', function(source, namaBox, jumlah)
    return GachaShop.beli(source, namaBox, jumlah)
end)

AddEventHandler('playerDropped', function()
    terakhirBeli[source] = nil
end)
