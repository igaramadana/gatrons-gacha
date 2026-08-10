GachaCoin = {}

local siap = false

local function ambilConfig()
    return Config.Coin or {}
end

local function namaTabel()
    local nama = ambilConfig().namaTabel or 'gatrons_coin'

    if not nama:match('^[%w_]+$') then
        return 'gatrons_coin'
    end

    return nama
end

local function rapihinJumlah(jumlah)
    jumlah = tonumber(jumlah)

    if not jumlah or jumlah ~= jumlah or jumlah == math.huge or jumlah == -math.huge then
        return nil
    end

    jumlah = math.floor(jumlah)

    local batas = tonumber(ambilConfig().maksimalTransaksi) or 100000000

    if jumlah <= 0 or jumlah > batas then
        return nil
    end

    return jumlah
end

local function rapihinSaldo(saldo)
    saldo = tonumber(saldo)

    if not saldo or saldo ~= saldo or saldo == math.huge or saldo == -math.huge then
        return nil
    end

    saldo = math.floor(saldo)

    local batas = tonumber(ambilConfig().maksimalSaldo) or 2000000000

    if saldo < 0 or saldo > batas then
        return nil
    end

    return saldo
end

local function rapihinCitizenId(citizenid)
    if type(citizenid) ~= 'string' then
        return nil
    end

    citizenid = citizenid:gsub('^%s+', ''):gsub('%s+$', '')

    if citizenid == '' or #citizenid > 64 then
        return nil
    end

    -- QBCore/Qbox citizenid biasanya alphanumeric. Tetap izinkan _ dan - untuk custom core.
    if not citizenid:match('^[%w_-]+$') then
        return nil
    end

    return citizenid
end

local function ambilPemilik(target)
    if type(target) == 'number' then
        local source = math.floor(target)

        if source <= 0 then
            return nil, nil, 'source_ngaco'
        end

        local citizenid, errCitizen = GachaFramework.ambilCitizenId(source)
        if not citizenid then
            return nil, nil, errCitizen or 'citizenid_ga_ketemu'
        end

        return citizenid, source
    end

    if type(target) == 'string' then
        local citizenid = rapihinCitizenId(target)

        if not citizenid then
            return nil, nil, 'citizenid_ngaco'
        end

        return citizenid, nil
    end

    return nil, nil, 'target_ngaco'
end

local function tabelAda(tabel)
    local row = MySQL.single.await([[
        SELECT `TABLE_NAME`
        FROM `INFORMATION_SCHEMA`.`TABLES`
        WHERE `TABLE_SCHEMA` = DATABASE()
          AND `TABLE_NAME` = ?
        LIMIT 1
    ]], { tabel })

    return row ~= nil
end

local function kolomAda(tabel, kolom)
    local row = MySQL.single.await([[
        SELECT `COLUMN_NAME`
        FROM `INFORMATION_SCHEMA`.`COLUMNS`
        WHERE `TABLE_SCHEMA` = DATABASE()
          AND `TABLE_NAME` = ?
          AND `COLUMN_NAME` = ?
        LIMIT 1
    ]], { tabel, kolom })

    return row ~= nil
end

local function primaryKey(tabel)
    local row = MySQL.single.await([[
        SELECT `COLUMN_NAME`
        FROM `INFORMATION_SCHEMA`.`KEY_COLUMN_USAGE`
        WHERE `TABLE_SCHEMA` = DATABASE()
          AND `TABLE_NAME` = ?
          AND `CONSTRAINT_NAME` = 'PRIMARY'
        ORDER BY `ORDINAL_POSITION`
        LIMIT 1
    ]], { tabel })

    return row and row.COLUMN_NAME or nil
end

local function bikinTabelKarakter(tabel)
    MySQL.query.await(([=[
        CREATE TABLE IF NOT EXISTS `%s` (
            `citizenid` VARCHAR(64) NOT NULL,
            `balance` BIGINT UNSIGNED NOT NULL DEFAULT 0,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]=]):format(tabel))
end

local function migrasiTabel()
    local tabel = namaTabel()

    if not tabelAda(tabel) then
        bikinTabelKarakter(tabel)
        return
    end

    local sudahKarakter = primaryKey(tabel) == 'citizenid' and not kolomAda(tabel, 'identifier')
    if sudahKarakter then
        return
    end

    local backup = tabel .. '_identifier_backup'
    local temp = tabel .. '_character_tmp'
    local lama = tabel .. '_migrating_old'

    -- Backup dibuat sekali agar saldo schema lama tetap bisa dipulihkan manual.
    if not tabelAda(backup) then
        MySQL.query.await(('CREATE TABLE `%s` LIKE `%s`'):format(backup, tabel))
        MySQL.query.await(('INSERT INTO `%s` SELECT * FROM `%s`'):format(backup, tabel))
    end

    MySQL.query.await(('DROP TABLE IF EXISTS `%s`'):format(temp))
    bikinTabelKarakter(temp)

    if kolomAda(tabel, 'citizenid') then
        -- Balance account-based lama dipindahkan ke citizenid terakhir yang tersimpan di row tersebut.
        -- MAX dipakai agar duplicate legacy row tidak menggandakan saldo.
        MySQL.query.await(([=[
            INSERT INTO `%s` (`citizenid`, `balance`)
            SELECT `citizenid`, MAX(`balance`)
            FROM `%s`
            WHERE `citizenid` IS NOT NULL AND `citizenid` <> ''
            GROUP BY `citizenid`
        ]=]):format(temp, tabel))
    end

    MySQL.query.await(('DROP TABLE IF EXISTS `%s`'):format(lama))
    MySQL.query.await(('RENAME TABLE `%s` TO `%s`, `%s` TO `%s`'):format(tabel, lama, temp, tabel))
    MySQL.query.await(('DROP TABLE `%s`'):format(lama))

    print(('^3[gatrons-gacha] Coin DB dimigrasi ke per-character. Backup schema lama: %s^7'):format(backup))
end

local function pastiinAkun(citizenid)
    local tabel = namaTabel()

    MySQL.query.await(([=[
        INSERT INTO `%s` (`citizenid`, `balance`)
        VALUES (?, 0)
        ON DUPLICATE KEY UPDATE `citizenid` = VALUES(`citizenid`)
    ]=]):format(tabel), { citizenid })
end

local function ambilSaldo(citizenid)
    local tabel = namaTabel()

    local saldo = MySQL.scalar.await(
        ('SELECT `balance` FROM `%s` WHERE `citizenid` = ? LIMIT 1'):format(tabel),
        { citizenid }
    )

    return math.max(0, math.floor(tonumber(saldo) or 0))
end

local function kabarinSaldo(source, saldo)
    if not source or GetPlayerPing(source) <= 0 then
        return
    end

    TriggerClientEvent('gatrons-gacha:client:coinUpdate', source, saldo)
end

function GachaCoin.siapinTabel()
    migrasiTabel()
    siap = true
end

function GachaCoin.udahSiap()
    return siap
end

function GachaCoin.ambil(target)
    if not siap then
        return nil, 'coin_belum_siap'
    end

    local citizenid, source, err = ambilPemilik(target)
    if not citizenid then
        return nil, err
    end

    pastiinAkun(citizenid)

    local saldo = ambilSaldo(citizenid)
    kabarinSaldo(source, saldo)

    return saldo
end

function GachaCoin.tambah(target, jumlah, alasan)
    if not siap then
        return false, 'coin_belum_siap'
    end

    jumlah = rapihinJumlah(jumlah)
    if not jumlah then
        return false, 'jumlah_ngaco'
    end

    local citizenid, source, err = ambilPemilik(target)
    if not citizenid then
        return false, err
    end

    local batasSaldo = tonumber(ambilConfig().maksimalSaldo) or 2000000000
    local tabel = namaTabel()

    pastiinAkun(citizenid)

    MySQL.update.await(([=[
        UPDATE `%s`
        SET `balance` = LEAST(`balance` + ?, ?)
        WHERE `citizenid` = ?
    ]=]):format(tabel), {
        jumlah,
        batasSaldo,
        citizenid,
    })

    local saldo = ambilSaldo(citizenid)
    kabarinSaldo(source, saldo)

    GachaUtils.debugPrint(('addCoin %s +%s (%s) -> %s'):format(
        citizenid,
        jumlah,
        tostring(alasan or 'tanpa_alasan'),
        saldo
    ))

    return true, saldo
end

function GachaCoin.kurangin(target, jumlah, alasan)
    if not siap then
        return false, 'coin_belum_siap'
    end

    jumlah = rapihinJumlah(jumlah)
    if not jumlah then
        return false, 'jumlah_ngaco'
    end

    local citizenid, source, err = ambilPemilik(target)
    if not citizenid then
        return false, err
    end

    local tabel = namaTabel()
    pastiinAkun(citizenid)

    local berubah = MySQL.update.await(([=[
        UPDATE `%s`
        SET `balance` = `balance` - ?
        WHERE `citizenid` = ? AND `balance` >= ?
    ]=]):format(tabel), {
        jumlah,
        citizenid,
        jumlah,
    })

    local saldo = ambilSaldo(citizenid)

    if berubah ~= 1 then
        kabarinSaldo(source, saldo)
        return false, 'coin_kurang', saldo
    end

    kabarinSaldo(source, saldo)

    GachaUtils.debugPrint(('removeCoin %s -%s (%s) -> %s'):format(
        citizenid,
        jumlah,
        tostring(alasan or 'tanpa_alasan'),
        saldo
    ))

    return true, saldo
end

function GachaCoin.set(target, saldoBaru, alasan)
    if not siap then
        return false, 'coin_belum_siap'
    end

    saldoBaru = rapihinSaldo(saldoBaru)
    if saldoBaru == nil then
        return false, 'saldo_ngaco'
    end

    local citizenid, source, err = ambilPemilik(target)
    if not citizenid then
        return false, err
    end

    local tabel = namaTabel()
    pastiinAkun(citizenid)

    local berubah = MySQL.update.await(
        ('UPDATE `%s` SET `balance` = ? WHERE `citizenid` = ?'):format(tabel),
        { saldoBaru, citizenid }
    )

    if berubah == nil then
        return false, 'database_gagal'
    end

    local saldo = ambilSaldo(citizenid)
    kabarinSaldo(source, saldo)

    GachaUtils.debugPrint(('setCoin %s = %s (%s)'):format(
        citizenid,
        saldo,
        tostring(alasan or 'tanpa_alasan')
    ))

    return true, saldo, citizenid
end

-- target:
-- number = player source (otomatis memakai character aktif)
-- string = citizenid (berguna untuk karakter offline)
exports('addCoin', function(target, jumlah, alasan)
    return GachaCoin.tambah(target, jumlah, alasan)
end)

exports('removeCoin', function(target, jumlah, alasan)
    return GachaCoin.kurangin(target, jumlah, alasan)
end)

exports('getCoin', function(target)
    return GachaCoin.ambil(target)
end)

exports('setCoin', function(target, saldo, alasan)
    return GachaCoin.set(target, saldo, alasan)
end)

CreateThread(function()
    GachaCoin.siapinTabel()
    print('^2[gatrons-gacha] Gatrons Coin database siap (per-character / citizenid).^7')
end)
