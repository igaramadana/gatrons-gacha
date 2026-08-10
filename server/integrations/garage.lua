GachaGarasi = {}

local hurufPlat = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'

local function resourceNyala(nama)
    return type(nama) == 'string' and nama ~= '' and GetResourceState(nama) == 'started'
end

local function copyTable(data)
    if type(data) ~= 'table' then return {} end

    local hasil = {}
    for key, value in pairs(data) do
        if type(value) == 'table' then
            hasil[key] = copyTable(value)
        else
            hasil[key] = value
        end
    end
    return hasil
end

local function ambilCfgFramework(framework)
    local cfg = Config.Garasi or {}
    return cfg[framework] or {}
end

local function ambilGarasiHadiah(hadiah, framework)
    local cfg = ambilCfgFramework(framework)
    local dariHadiah = type(hadiah) == 'table' and hadiah.garasi or nil

    if type(dariHadiah) == 'table' then
        dariHadiah = dariHadiah[framework]
    end

    if type(dariHadiah) == 'string' and dariHadiah ~= '' then
        return dariHadiah
    end

    return cfg.garasiDefault or Config.Garasi.garasiDefault or 'motelgarage'
end

local function bikinPlatSekali(prefix)
    prefix = tostring(prefix or 'GTR'):upper():gsub('[^A-Z0-9]', ''):sub(1, 3)
    if prefix == '' then prefix = 'GTR' end

    local sisa = math.max(1, 8 - #prefix)
    local buntut = {}

    for i = 1, sisa do
        local idx = math.random(1, #hurufPlat)
        buntut[i] = hurufPlat:sub(idx, idx)
    end

    return (prefix .. table.concat(buntut)):sub(1, 8)
end

local function platUdahAdaQb(plate, tabel)
    local query = ('SELECT 1 FROM `%s` WHERE `plate` = ? LIMIT 1'):format(tabel)
    return MySQL.scalar.await(query, { plate }) ~= nil
end

local function bikinPlatQb(cfg)
    local tabel = cfg.tabelKendaraan or 'player_vehicles'

    for _ = 1, 24 do
        local plate = bikinPlatSekali(cfg.prefixPlate)
        if not platUdahAdaQb(plate, tabel) then
            return plate
        end
    end

    return nil
end

local function validasiGarasiQbox(garage, cfg)
    local resourceGarasi = cfg.resourceGarasi or 'qbx_garages'
    if not resourceNyala(resourceGarasi) then
        return false, 'qbx_garages_mati'
    end

    local oke, daftar = pcall(function()
        return exports[resourceGarasi]:GetGarages()
    end)

    if not oke or type(daftar) ~= 'table' then
        return false, 'gagal_baca_garasi_qbox'
    end

    if not daftar[garage] then
        return false, ('garasi_qbox_ga_ada:%s'):format(garage)
    end

    return true
end

local function kasihMobilQbox(source, hadiah, citizenid)
    local cfg = ambilCfgFramework('qbox')
    local resourceMobil = cfg.resourceKendaraan or 'qbx_vehicles'

    if not resourceNyala(resourceMobil) then
        return false, 'qbx_vehicles_mati'
    end

    local garage = ambilGarasiHadiah(hadiah, 'qbox')
    local garasiOke, errGarasi = validasiGarasiQbox(garage, cfg)
    if not garasiOke then return false, errGarasi end

    local request = {
        model = hadiah.model,
        citizenid = citizenid,
        garage = garage,
        props = type(hadiah.props) == 'table' and copyTable(hadiah.props) or nil,
    }

    local aman, vehicleId, err = pcall(function()
        return exports[resourceMobil]:CreatePlayerVehicle(request)
    end)

    if not aman then
        print(('^1[gatrons-gacha] qbx_vehicles CreatePlayerVehicle error: %s^7'):format(vehicleId))
        return false, 'qbx_create_vehicle_error'
    end

    if not vehicleId then
        local kode = type(err) == 'table' and (err.code or err.message) or err
        return false, kode or 'gagal_bikin_kendaraan_qbox'
    end

    return true, {
        framework = 'qbox',
        garage = garage,
        vehicleId = vehicleId,
        model = hadiah.model,
    }
end

local function kasihMobilQb(source, hadiah, citizenid)
    local cfg = ambilCfgFramework('qb')
    local resourceGarasi = cfg.resourceGarasi or 'qb-garages'

    if cfg.wajibGarasiNyala ~= false and not resourceNyala(resourceGarasi) then
        return false, 'qb_garages_mati'
    end

    local player = GachaFramework.ambilPlayer(source)
    if not player or not player.PlayerData then
        return false, 'player_qb_ga_ketemu'
    end

    local license = player.PlayerData.license or select(1, GachaFramework.ambilLicense(source))
    if not license then return false, 'license_qb_ga_ada' end

    local model = type(hadiah.model) == 'string' and hadiah.model:lower() or nil
    if not model or model == '' or #model > 64 then
        return false, 'model_kendaraan_ngaco'
    end

    local garage = ambilGarasiHadiah(hadiah, 'qb')
    if type(garage) ~= 'string' or garage == '' or #garage > 64 then
        return false, 'nama_garasi_ngaco'
    end

    local tabel = cfg.tabelKendaraan or 'player_vehicles'
    if not tostring(tabel):match('^[%w_]+$') then
        return false, 'nama_tabel_ngaco'
    end

    local plate = bikinPlatQb(cfg)
    if not plate then return false, 'gagal_bikin_plate_unik' end

    local props = copyTable(hadiah.props)
    props.plate = plate

    local mods = json.encode(props)
    if not mods then return false, 'gagal_encode_props' end

    local hash = joaat(model)
    local query = ([=[
        INSERT INTO `%s`
            (`license`, `citizenid`, `vehicle`, `hash`, `mods`, `plate`, `garage`, `state`)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ]=]):format(tabel)

    local id = MySQL.insert.await(query, {
        license,
        citizenid,
        model,
        hash,
        mods,
        plate,
        garage,
        1, -- langsung GARAGED supaya muncul di qb-garages
    })

    if not id then
        return false, 'gagal_insert_kendaraan_qb'
    end

    return true, {
        framework = 'qb',
        garage = garage,
        vehicleId = id,
        plate = plate,
        model = model,
    }
end

function GachaGarasi.cekSiap(hadiah)
    local framework = GachaFramework.ambilNama()
    if not framework then return false, 'framework_ga_ketemu' end

    if framework == 'qbox' then
        local cfg = ambilCfgFramework('qbox')
        local resourceMobil = cfg.resourceKendaraan or 'qbx_vehicles'
        if not resourceNyala(resourceMobil) then return false, 'qbx_vehicles_mati' end

        local garage = ambilGarasiHadiah(hadiah, 'qbox')
        return validasiGarasiQbox(garage, cfg)
    end

    if framework == 'qb' then
        local cfg = ambilCfgFramework('qb')
        local resourceGarasi = cfg.resourceGarasi or 'qb-garages'
        if cfg.wajibGarasiNyala ~= false and not resourceNyala(resourceGarasi) then
            return false, 'qb_garages_mati'
        end

        local tabel = cfg.tabelKendaraan or 'player_vehicles'
        if not tostring(tabel):match('^[%w_]+$') then return false, 'nama_tabel_ngaco' end

        local adaTabel = MySQL.scalar.await([[
            SELECT 1
            FROM information_schema.tables
            WHERE table_schema = DATABASE() AND table_name = ?
            LIMIT 1
        ]], { tabel })

        if not adaTabel then return false, 'tabel_player_vehicles_ga_ada' end
        return true
    end

    return false, 'framework_ga_didukung'
end

function GachaGarasi.ambilCitizenId(source)
    return GachaFramework.ambilCitizenId(source)
end

function GachaGarasi.ambilGarasiDefault(framework)
    framework = framework or GachaFramework.ambilNama()
    if not framework then return Config.Garasi.garasiDefault or 'motelgarage' end
    return ambilGarasiHadiah(nil, framework)
end

function GachaGarasi.kasihMobil(source, hadiah, citizenidSimpan)
    if type(hadiah) ~= 'table' or hadiah.jenis ~= 'vehicle' then
        return false, 'hadiah_bukan_vehicle'
    end

    local framework = GachaFramework.ambilNama()
    if not framework then
        return false, 'framework_ga_ketemu'
    end

    local citizenid = citizenidSimpan
    if type(citizenid) ~= 'string' or citizenid == '' then
        citizenid = select(1, GachaFramework.ambilCitizenId(source))
    end

    if not citizenid then
        return false, 'citizenid_ga_ada'
    end

    if framework == 'qbox' then
        return kasihMobilQbox(source, hadiah, citizenid)
    end

    if framework == 'qb' then
        return kasihMobilQb(source, hadiah, citizenid)
    end

    return false, 'framework_ga_didukung'
end
