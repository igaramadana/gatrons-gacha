GachaInventory = {}

local ox = exports.ox_inventory
local cacheItem = {}

local function ambilInfoItem(nama)
    if cacheItem[nama] ~= nil then
        return cacheItem[nama] or nil
    end

    local item = ox:Items(nama)
    cacheItem[nama] = item or false
    return item
end

local function gabungPathGambar(base, namaFile)
    if type(namaFile) ~= 'string' or namaFile == '' then return nil end
    if namaFile:match('^https?://') or namaFile:match('^nui://') or namaFile:match('^data:') then
        return namaFile
    end

    base = type(base) == 'string' and base ~= '' and base or 'nui://ox_inventory/web/images'
    return base:gsub('/+$', '') .. '/' .. namaFile:gsub('^/+', '')
end

function GachaInventory.itemAda(nama)
    return ambilInfoItem(nama) ~= nil
end

function GachaInventory.ambilVisualItem(nama)
    local item = ambilInfoItem(nama)
    if not item then return nil end

    local namaGambar = nil
    if type(item.client) == 'table' and type(item.client.image) == 'string' and item.client.image ~= '' then
        namaGambar = item.client.image
    end

    local imagePath = GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images')

    return {
        label = item.label or nama,
        gambar = gabungPathGambar(imagePath, namaGambar or (nama .. '.png')),
    }
end

function GachaInventory.bisaNampung(source, nama, jumlah, metadata)
    return ox:CanCarryItem(source, nama, jumlah, metadata)
end

function GachaInventory.kasihItem(source, nama, jumlah, metadata)
    if not GachaInventory.itemAda(nama) then
        return false, 'item_ga_ada'
    end

    if not GachaInventory.bisaNampung(source, nama, jumlah, metadata) then
        return false, 'inventory_penuh'
    end

    local oke, respons = ox:AddItem(source, nama, jumlah, metadata)
    if not oke then
        return false, respons or 'gagal_nambah_item'
    end

    return true, respons
end

function GachaInventory.ambilSlot(source, slot)
    slot = tonumber(slot)
    if not slot then return nil end

    return ox:GetSlot(source, slot)
end

function GachaInventory.hapusBox(source, nama, slot, metadata)
    if not GachaInventory.itemAda(nama) then
        return false, 'box_ga_ada'
    end

    local dataSlot = GachaInventory.ambilSlot(source, slot)
    if not dataSlot or dataSlot.name ~= nama or (tonumber(dataSlot.count) or 0) < 1 then
        return false, 'box_ga_ada_di_slot'
    end

    local metadataTarget = metadata
    if type(metadataTarget) ~= 'table' then
        metadataTarget = dataSlot.metadata
    end

    local oke, respons = ox:RemoveItem(
        source,
        nama,
        1,
        metadataTarget,
        slot,
        false,
        true
    )

    if not oke then
        return false, respons or 'gagal_hapus_box'
    end

    return true
end

function GachaInventory.balikinBox(source, nama, metadata)
    local oke, respons = ox:AddItem(source, nama, 1, metadata)
    if not oke then
        print(('^1[gatrons-gacha] CRITICAL: gagal balikin box %s ke source %s (%s).^7'):format(
            tostring(nama),
            tostring(source),
            tostring(respons)
        ))
        return false, respons
    end

    return true
end

function GachaInventory.hitungItem(source, nama, metadata)
    if not GachaInventory.itemAda(nama) then return 0 end
    return math.max(0, tonumber(ox:GetItemCount(source, nama, metadata)) or 0)
end
