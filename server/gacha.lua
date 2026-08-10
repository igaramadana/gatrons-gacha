GachaMesin = {}

local poolCache = {}

local function hadiahMasihValid(hadiah)
    if type(hadiah) ~= 'table' or type(hadiah.weight) ~= 'number' or hadiah.weight <= 0 then
        return false
    end

    if not Config.Rarity[hadiah.rarity] then
        return false
    end

    if hadiah.jenis == 'item' then
        return type(hadiah.nama) == 'string' and GachaInventory.itemAda(hadiah.nama)
    end

    if hadiah.jenis == 'vehicle' then
        return type(hadiah.model) == 'string' and #hadiah.model > 0
    end

    return false
end

local function siapinHadiahUi(hadiah)
    if type(hadiah) ~= 'table' then return nil end

    local siap = GachaUtils.copyTabel(hadiah)

    if siap.jenis == 'item' then
        local visual = GachaInventory.ambilVisualItem(siap.nama)
        if visual then
            siap.label = siap.label or visual.label
            siap.gambar = siap.gambar or visual.gambar
        end
    end

    return siap
end

local function bikinDataDasar(namaBox)
    local box = Config.Box[namaBox]
    if not box then return nil end

    local poolUi = {}
    local pool = GachaMesin.ambilPoolValid(namaBox) or {}

    for i = 1, #pool do
        poolUi[#poolUi + 1] = siapinHadiahUi(pool[i])
    end

    return {
        nama = namaBox,
        label = box.label,
        deskripsi = box.deskripsi,
        gambarTutup = box.gambarTutup,
        gambarBuka = box.gambarBuka,
        aksen = box.aksen,
        odds = GachaMesin.hitungOdds(namaBox),
        rarity = Config.Rarity,
        pool = poolUi,
    }
end

function GachaMesin.ambilPoolValid(namaBox)
    if poolCache[namaBox] then
        return poolCache[namaBox]
    end

    local box = Config.Box[namaBox]
    if not box then return nil end

    local pool = {}
    for i = 1, #box.hadiah do
        local hadiah = box.hadiah[i]
        if hadiahMasihValid(hadiah) then
            pool[#pool + 1] = GachaUtils.copyTabel(hadiah)
        else
            print(('^3[gatrons-gacha] Lewatin reward invalid di %s index %s.^7'):format(namaBox, i))
        end
    end

    poolCache[namaBox] = pool
    return pool
end

function GachaMesin.acakHadiah(namaBox)
    local pool = GachaMesin.ambilPoolValid(namaBox)
    if not pool or #pool == 0 then return nil, 'pool_kosong' end

    local total = 0
    for i = 1, #pool do
        total = total + math.floor(pool[i].weight)
    end

    if total <= 0 then return nil, 'weight_ngaco' end

    local angka = math.random(1, total)
    local jalan = 0

    for i = 1, #pool do
        jalan = jalan + math.floor(pool[i].weight)
        if angka <= jalan then
            return GachaUtils.copyTabel(pool[i])
        end
    end

    return GachaUtils.copyTabel(pool[#pool])
end

function GachaMesin.hitungOdds(namaBox)
    local pool = GachaMesin.ambilPoolValid(namaBox) or {}
    local total = 0
    local perRarity = {}

    for i = 1, #pool do
        local hadiah = pool[i]
        total = total + hadiah.weight
        perRarity[hadiah.rarity] = (perRarity[hadiah.rarity] or 0) + hadiah.weight
    end

    local odds = {}
    if total > 0 then
        for rarity, weight in pairs(perRarity) do
            odds[rarity] = math.floor((weight / total) * 10000 + 0.5) / 100
        end
    end

    return odds
end

-- Dipakai saat player baru USE box.
-- Belum ada reward pemenang di payload ini.
function GachaMesin.bikinDataPreview(namaBox)
    return bikinDataDasar(namaBox)
end

-- Dipakai sesudah player klik OPEN CASE dan server sudah menghapus 1 box.
function GachaMesin.bikinDataUi(namaBox, hadiahMenang)
    local data = bikinDataDasar(namaBox)
    if not data or type(hadiahMenang) ~= 'table' then return nil end

    data.menang = siapinHadiahUi(hadiahMenang)
    return data
end
