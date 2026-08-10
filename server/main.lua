local lagiBuka = {}
local jedaPake = {}
local udahSiap = false

local WAKTU_SIAP_MS = 120000

local function ambilCitizenId(source)
    return GachaFramework.ambilCitizenId(source)
end

local function bikinIdBukaan(source)
    local citizenid = ambilCitizenId(source) or 'unknown'
    local buntut = citizenid:gsub('[^%w]', ''):sub(-8)
    return ('gg_%s_%s_%06d'):format(os.time(), buntut, math.random(0, 999999))
end

local function bikinTokenSiap(source, citizenid, namaBox)
    local buntut = citizenid:gsub('[^%w]', ''):sub(-6)
    return ('ready_%s_%s_%s_%05d'):format(
        source,
        buntut,
        namaBox:gsub('[^%w_]', ''):sub(1, 20),
        math.random(0, 99999)
    )
end

local function bolehPake(source)
    local sekarang = GetGameTimer()
    local terakhir = jedaPake[source] or 0

    if sekarang - terakhir < Config.Keamanan.jedaPakeMs then
        return false
    end

    jedaPake[source] = sekarang
    return true
end

local function kirimNotif(source, pesan, tipe)
    TriggerClientEvent('gatrons-gacha:client:notif', source, pesan, tipe or 'inform')
end

local function kirimPending(source, pending)
    local dataUi = GachaMesin.bikinDataUi(pending.box_name, pending.hadiah)
    if not dataUi then return end

    TriggerClientEvent('gatrons-gacha:client:pending', source, {
        id = pending.id,
        status = pending.status,
        box = dataUi,
    })
end

local function beresinHadiah(source, transaksi)
    local hadiah = transaksi.hadiah

    if hadiah.jenis == 'item' then
        local oke, info = GachaInventory.kasihItem(source, hadiah.nama, hadiah.jumlah or 1, hadiah.metadata)
        return oke, info
    end

    if hadiah.jenis == 'vehicle' then
        return GachaGarasi.kasihMobil(source, hadiah, transaksi.citizenid)
    end

    return false, 'jenis_hadiah_ga_dikenal'
end

local function prosesKlaim(source, id)
    id = GachaUtils.bersihinTeks(id, Config.Keamanan.batasId)
    if not id then return { oke = false, kode = 'id_ngaco', pesan = 'ID opening tidak valid.' } end

    local citizenid = ambilCitizenId(source)
    if not citizenid then return { oke = false, kode = 'citizenid_ga_ada', pesan = 'Character player tidak ditemukan.' } end

    local transaksi = GachaStorage.ambil(id, citizenid)
    if not transaksi then return { oke = false, kode = 'ga_ketemu', pesan = 'Opening tidak ditemukan.' } end

    if transaksi.status == 'claimed' then
        return { oke = false, kode = 'udah_diambil', pesan = 'Hadiah ini sudah pernah diambil.' }
    end

    if transaksi.status == 'claiming' then
        return { oke = false, kode = 'lagi_diproses', pesan = 'Hadiah sedang diproses. Hubungi staff jika status ini menetap.' }
    end

    local sesi = lagiBuka[source]
    if sesi and sesi.id == id then
        local lewat = GetGameTimer() - sesi.mulai
        if lewat < Config.Keamanan.minimalAnimasiMs then
            return { oke = false, kode = 'kepagian', pesan = 'Animasi gacha belum selesai.' }
        end
    end

    if not GachaStorage.kunciKlaim(id, citizenid) then
        return { oke = false, kode = 'dikunci', pesan = 'Reward sedang diproses atau sudah diklaim.' }
    end

    local oke, info = beresinHadiah(source, transaksi)
    if not oke then
        GachaStorage.balikinReady(id, citizenid)
        return {
            oke = false,
            kode = type(info) == 'string' and info or 'gagal_kasih_hadiah',
            pesan = info == 'inventory_penuh' and 'Inventory kamu penuh. Kosongkan slot lalu coba ambil lagi.' or 'Hadiah belum bisa diberikan. Reward tetap tersimpan.',
        }
    end

    if not GachaStorage.tandaiSelesai(id, citizenid) then
        print(('^1[gatrons-gacha] CRITICAL: reward %s berhasil dikirim tapi DB gagal finalisasi. ID %s.^7'):format(transaksi.hadiah.label or '?', id))
        lagiBuka[source] = nil
        return { oke = false, kode = 'db_finalisasi_gagal', pesan = 'Reward terkirim, tapi log finalisasi gagal. Jangan klaim ulang; hubungi staff.' }
    end

    lagiBuka[source] = nil

    return {
        oke = true,
        pesan = transaksi.hadiah.jenis == 'vehicle'
            and ('Kendaraan masuk ke garage %s.'):format(type(info) == 'table' and info.garage or GachaGarasi.ambilGarasiDefault())
            or 'Hadiah sudah masuk ke inventory.',
        hadiah = transaksi.hadiah,
        info = info,
    }
end

-- USE item hanya membuka preview.
-- Return false sengaja dipakai untuk membatalkan consume bawaan ox_inventory.
-- Box baru dihapus manual ketika callback bukaCase berhasil.
exports('urusPakeBox', function(event, item, inventory, slot, data)
    if event ~= 'usingItem' then return end
    if not udahSiap then return false end
    if not inventory or inventory.type ~= 'player' then return false end

    local source = tonumber(inventory.id)
    if not source or source <= 0 then return false end

    local box = Config.Box[item.name]
    if not box then return false end

    if lagiBuka[source] or not bolehPake(source) then
        kirimNotif(source, 'Masih ada gacha yang belum selesai.', 'error')
        return false
    end

    local citizenid, errCitizen = ambilCitizenId(source)
    if not citizenid then
        kirimNotif(source, ('Character belum siap (%s).'):format(errCitizen or 'unknown'), 'error')
        return false
    end

    local pending = GachaStorage.ambilPending(citizenid)
    if pending then
        kirimPending(source, pending)
        return false
    end

    local dataSlot = inventory.items and inventory.items[slot] or nil
    if not dataSlot or dataSlot.name ~= item.name or (tonumber(dataSlot.count) or 0) < 1 then
        kirimNotif(source, 'Box tidak ditemukan di slot inventory.', 'error')
        return false
    end

    local token = bikinTokenSiap(source, citizenid, item.name)

    lagiBuka[source] = {
        token = token,
        namaBox = item.name,
        slot = slot,
        metadata = GachaUtils.copyTabel(dataSlot.metadata or {}),
        citizenid = citizenid,
        dibuat = GetGameTimer(),
        tahap = 'siap',
    }

    local preview = GachaMesin.bikinDataPreview(item.name)
    if not preview then
        lagiBuka[source] = nil
        kirimNotif(source, 'Data box gagal disiapkan.', 'error')
        return false
    end

    TriggerClientEvent('gatrons-gacha:client:siapBuka', source, {
        id = token,
        box = preview,
    })

    SetTimeout(WAKTU_SIAP_MS, function()
        local sesi = lagiBuka[source]
        if sesi and sesi.token == token and sesi.tahap == 'siap' then
            lagiBuka[source] = nil
        end
    end)

    -- WAJIB false: ox_inventory tidak mengurangi item di fase USE.
    return false
end)

lib.callback.register('gatrons-gacha:server:bukaCase', function(source, token)
    if not udahSiap then
        return { oke = false, kode = 'server_belum_siap', pesan = 'Gacha server belum siap.' }
    end

    token = GachaUtils.bersihinTeks(token, 128)
    if not token then
        return { oke = false, kode = 'token_ngaco', pesan = 'Sesi opening tidak valid.' }
    end

    local sesi = lagiBuka[source]
    if not sesi or sesi.token ~= token then
        return { oke = false, kode = 'sesi_ga_ada', pesan = 'Sesi box sudah habis. Use box lagi dari inventory.' }
    end

    if sesi.tahap ~= 'siap' then
        return { oke = false, kode = 'lagi_diproses', pesan = 'Opening sedang diproses.' }
    end

    if GetGameTimer() - sesi.dibuat > WAKTU_SIAP_MS then
        lagiBuka[source] = nil
        return { oke = false, kode = 'sesi_expired', pesan = 'Sesi box expired. Use box lagi dari inventory.' }
    end

    local citizenid, errCitizen = ambilCitizenId(source)
    if not citizenid or citizenid ~= sesi.citizenid then
        lagiBuka[source] = nil
        return { oke = false, kode = 'character_ganti', pesan = ('Character berubah (%s). Use box ulang.'):format(errCitizen or 'unknown') }
    end

    local pending = GachaStorage.ambilPending(citizenid)
    if pending then
        lagiBuka[source] = nil
        kirimPending(source, pending)
        return { oke = false, kode = 'ada_pending', pesan = 'Selesaikan pending reward lebih dulu.' }
    end

    -- Lock sesi SEBELUM RNG / RemoveItem untuk menahan double click.
    sesi.tahap = 'ngunci'

    local dataSlot = GachaInventory.ambilSlot(source, sesi.slot)
    if not dataSlot or dataSlot.name ~= sesi.namaBox or (tonumber(dataSlot.count) or 0) < 1 then
        sesi.tahap = 'siap'
        return { oke = false, kode = 'box_ga_ada', pesan = 'Box sudah tidak ada di slot inventory.' }
    end

    local hadiah, errHadiah = GachaMesin.acakHadiah(sesi.namaBox)
    if not hadiah then
        sesi.tahap = 'siap'
        return { oke = false, kode = 'pool_gagal', pesan = ('Pool box gagal: %s'):format(errHadiah or 'unknown') }
    end

    if hadiah.jenis == 'vehicle' then
        local bridgeOke, errBridge = GachaGarasi.cekSiap(hadiah)
        if not bridgeOke then
            sesi.tahap = 'siap'
            return {
                oke = false,
                kode = 'garage_belum_siap',
                pesan = ('Bridge garage belum siap (%s). Box belum dipakai.'):format(errBridge or 'unknown'),
            }
        end
    end

    -- Ini titik consume yang sebenarnya: hanya terjadi setelah player klik OPEN CASE.
    local boxKehapus, errHapus = GachaInventory.hapusBox(
        source,
        sesi.namaBox,
        sesi.slot,
        sesi.metadata
    )

    if not boxKehapus then
        sesi.tahap = 'siap'
        return {
            oke = false,
            kode = 'gagal_hapus_box',
            pesan = ('Box gagal dipakai (%s).'):format(errHapus or 'unknown'),
        }
    end

    local id = bikinIdBukaan(source)
    sesi.id = id
    sesi.hadiah = hadiah
    sesi.mulai = GetGameTimer()

    local kesimpen = GachaStorage.simpan({
        id = id,
        citizenid = sesi.citizenid,
        namaBox = sesi.namaBox,
        hadiah = hadiah,
    })

    if not kesimpen then
        local balik = GachaInventory.balikinBox(source, sesi.namaBox, sesi.metadata)
        sesi.id = nil
        sesi.hadiah = nil
        sesi.tahap = 'siap'

        return {
            oke = false,
            kode = 'db_gagal',
            pesan = balik and 'Transaksi gagal dibuat. Box sudah dikembalikan.' or 'Transaksi gagal dan refund box gagal. Hubungi staff.',
        }
    end

    sesi.tahap = 'rolling'

    local dataUi = GachaMesin.bikinDataUi(sesi.namaBox, hadiah)
    if not dataUi then
        -- Transaksi sudah aman di DB; reward tetap recoverable sebagai pending.
        return {
            oke = false,
            kode = 'ui_gagal',
            pesan = 'Reward sudah tersimpan, tetapi data UI gagal dibuat. Tutup UI lalu buka pending reward.',
        }
    end

    return {
        oke = true,
        payload = {
            id = id,
            box = dataUi,
        },
    }
end)

lib.callback.register('gatrons-gacha:server:batalSiap', function(source)
    local sesi = lagiBuka[source]

    -- Hanya sesi PREVIEW yang boleh dibatalkan.
    -- Sesi rolling tidak dibuang agar minimal-animation guard tetap aman.
    if sesi and sesi.tahap == 'siap' then
        lagiBuka[source] = nil
        return true
    end

    return false
end)

lib.callback.register('gatrons-gacha:server:klaim', function(source, id)
    return prosesKlaim(source, id)
end)

lib.callback.register('gatrons-gacha:server:cekPending', function(source)
    if not udahSiap then return nil end

    local citizenid = ambilCitizenId(source)
    if not citizenid then return nil end

    local pending = GachaStorage.ambilPending(citizenid)
    if not pending then return nil end

    return {
        id = pending.id,
        status = pending.status,
        box = GachaMesin.bikinDataUi(pending.box_name, pending.hadiah),
    }
end)

RegisterCommand('gacharesetclaim', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'gatrons.gacha.admin') then
        return
    end

    local id = args[1]
    if not id then return end

    local berubah = MySQL.update.await([[
        UPDATE `gatrons_gacha_pending`
        SET `status` = 'ready', `claim_started_at` = NULL
        WHERE `id` = ? AND `status` = 'claiming'
    ]], { id })

    print(('[gatrons-gacha] reset claiming %s -> %s row'):format(id, berubah))
end, false)

AddEventHandler('playerDropped', function()
    lagiBuka[source] = nil
    jedaPake[source] = nil
end)

CreateThread(function()
    math.randomseed(os.time() + GetGameTimer())
    math.random(); math.random(); math.random()

    while not GachaCoin.udahSiap() do
        Wait(100)
    end

    GachaStorage.siapinTabel()
    udahSiap = true
    print('^2[gatrons-gacha] Server siap. Box consume-on-open + pending per-character aktif.^7')
end)
