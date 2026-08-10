GachaStorage = {}

local namaTabel = 'gatrons_gacha_pending'

local function encodeAman(data)
    local oke, hasil = pcall(json.encode, data)
    return oke and hasil or nil
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

local function kolomNullable(tabel, kolom)
    local row = MySQL.single.await([[
        SELECT `IS_NULLABLE`
        FROM `INFORMATION_SCHEMA`.`COLUMNS`
        WHERE `TABLE_SCHEMA` = DATABASE()
          AND `TABLE_NAME` = ?
          AND `COLUMN_NAME` = ?
        LIMIT 1
    ]], { tabel, kolom })

    return row and row.IS_NULLABLE == 'YES'
end

local function bikinTabelKarakter(tabel)
    MySQL.query.await(([=[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` VARCHAR(64) NOT NULL,
            `citizenid` VARCHAR(64) NOT NULL,
            `box_name` VARCHAR(64) NOT NULL,
            `reward_json` LONGTEXT NOT NULL,
            `status` VARCHAR(16) NOT NULL DEFAULT 'rolling',
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `claim_started_at` TIMESTAMP NULL DEFAULT NULL,
            `claimed_at` TIMESTAMP NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_gatrons_gacha_citizen` (`citizenid`, `status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]=]):format(tabel))
end

local function cobaIsiCitizenIdLegacy()
    if not kolomAda(namaTabel, 'identifier') or not kolomAda(namaTabel, 'citizenid') then
        return
    end

    local sumberCoin = nil

    if tabelAda('gatrons_coin') and kolomAda('gatrons_coin', 'identifier') and kolomAda('gatrons_coin', 'citizenid') then
        sumberCoin = 'gatrons_coin'
    elseif tabelAda('gatrons_coin_identifier_backup')
        and kolomAda('gatrons_coin_identifier_backup', 'identifier')
        and kolomAda('gatrons_coin_identifier_backup', 'citizenid') then
        sumberCoin = 'gatrons_coin_identifier_backup'
    end

    if not sumberCoin then
        return
    end

    MySQL.update.await(([=[
        UPDATE `%s` AS p
        INNER JOIN `%s` AS c ON c.`identifier` = p.`identifier`
        SET p.`citizenid` = c.`citizenid`
        WHERE (p.`citizenid` IS NULL OR p.`citizenid` = '')
          AND c.`citizenid` IS NOT NULL
          AND c.`citizenid` <> ''
    ]=]):format(namaTabel, sumberCoin))
end

function GachaStorage.siapinTabel()
    if not tabelAda(namaTabel) then
        bikinTabelKarakter(namaTabel)
        return
    end

    local perluMigrasi = kolomAda(namaTabel, 'identifier')
        or not kolomAda(namaTabel, 'citizenid')
        or kolomNullable(namaTabel, 'citizenid')

    if not perluMigrasi then
        return
    end

    cobaIsiCitizenIdLegacy()

    local backup = namaTabel .. '_identifier_backup'
    local temp = namaTabel .. '_character_tmp'
    local lama = namaTabel .. '_migrating_old'

    if not tabelAda(backup) then
        MySQL.query.await(('CREATE TABLE `%s` LIKE `%s`'):format(backup, namaTabel))
        MySQL.query.await(('INSERT INTO `%s` SELECT * FROM `%s`'):format(backup, namaTabel))
    end

    MySQL.query.await(('DROP TABLE IF EXISTS `%s`'):format(temp))
    bikinTabelKarakter(temp)

    if kolomAda(namaTabel, 'citizenid') then
        MySQL.query.await(([=[
            INSERT INTO `%s` (`id`, `citizenid`, `box_name`, `reward_json`, `status`, `created_at`, `claim_started_at`, `claimed_at`)
            SELECT `id`, `citizenid`, `box_name`, `reward_json`, `status`, `created_at`, `claim_started_at`, `claimed_at`
            FROM `%s`
            WHERE `citizenid` IS NOT NULL AND `citizenid` <> ''
        ]=]):format(temp, namaTabel))
    end

    MySQL.query.await(('DROP TABLE IF EXISTS `%s`'):format(lama))
    MySQL.query.await(('RENAME TABLE `%s` TO `%s`, `%s` TO `%s`'):format(namaTabel, lama, temp, namaTabel))
    MySQL.query.await(('DROP TABLE `%s`'):format(lama))

    print(('^3[gatrons-gacha] Pending DB dimigrasi ke per-character. Backup schema lama: %s^7'):format(backup))
end

function GachaStorage.simpan(data)
    local rewardJson = encodeAman(data.hadiah)

    if not rewardJson or type(data.citizenid) ~= 'string' or data.citizenid == '' then
        return false
    end

    local berubah = MySQL.insert.await(([=[
        INSERT INTO `%s` (`id`, `citizenid`, `box_name`, `reward_json`, `status`)
        VALUES (?, ?, ?, ?, 'rolling')
    ]=]):format(namaTabel), {
        data.id,
        data.citizenid,
        data.namaBox,
        rewardJson,
    })

    return berubah ~= nil
end

function GachaStorage.ambil(id, citizenid)
    local row = MySQL.single.await(([=[
        SELECT `id`, `citizenid`, `box_name`, `reward_json`, `status`,
               UNIX_TIMESTAMP(`created_at`) AS `created_at_unix`
        FROM `%s`
        WHERE `id` = ? AND `citizenid` = ?
        LIMIT 1
    ]=]):format(namaTabel), {
        id,
        citizenid,
    })

    if not row then
        return nil
    end

    local oke, hadiah = pcall(json.decode, row.reward_json)
    if not oke or type(hadiah) ~= 'table' then
        return nil
    end

    row.hadiah = hadiah
    row.reward_json = nil

    return row
end

function GachaStorage.ambilPending(citizenid)
    local row = MySQL.single.await(([=[
        SELECT `id`, `citizenid`, `box_name`, `reward_json`, `status`,
               UNIX_TIMESTAMP(`created_at`) AS `created_at_unix`
        FROM `%s`
        WHERE `citizenid` = ? AND `status` IN ('rolling', 'ready', 'claiming')
        ORDER BY `created_at` DESC
        LIMIT 1
    ]=]):format(namaTabel), {
        citizenid,
    })

    if not row then
        return nil
    end

    local oke, hadiah = pcall(json.decode, row.reward_json)
    if not oke or type(hadiah) ~= 'table' then
        return nil
    end

    row.hadiah = hadiah
    row.reward_json = nil

    return row
end

function GachaStorage.kunciKlaim(id, citizenid)
    local berubah = MySQL.update.await(([=[
        UPDATE `%s`
        SET `status` = 'claiming', `claim_started_at` = CURRENT_TIMESTAMP
        WHERE `id` = ? AND `citizenid` = ? AND `status` IN ('rolling', 'ready')
    ]=]):format(namaTabel), {
        id,
        citizenid,
    })

    return berubah == 1
end

function GachaStorage.balikinReady(id, citizenid)
    MySQL.update.await(([=[
        UPDATE `%s`
        SET `status` = 'ready', `claim_started_at` = NULL
        WHERE `id` = ? AND `citizenid` = ? AND `status` = 'claiming'
    ]=]):format(namaTabel), {
        id,
        citizenid,
    })
end

function GachaStorage.tandaiSelesai(id, citizenid)
    local berubah = MySQL.update.await(([=[
        UPDATE `%s`
        SET `status` = 'claimed', `claimed_at` = CURRENT_TIMESTAMP
        WHERE `id` = ? AND `citizenid` = ? AND `status` = 'claiming'
    ]=]):format(namaTabel), {
        id,
        citizenid,
    })

    return berubah == 1
end
