local uiKebuka = false

local function aturUi(aktif)
    uiKebuka = aktif
    SetNuiFocus(aktif, aktif)
end

local function kirimKeUi(aksi, data)
    SendNUIMessage({
        aksi = aksi,
        data = data,
    })
end

exports('pakeBox', function(data, slot)
    if uiKebuka then
        return lib.notify({ type = 'error', description = 'Selesaikan gacha yang lagi kebuka dulu.' })
    end

    exports.ox_inventory:useItem(data, function()
        -- Consume bawaan sengaja dibatalkan server.
        -- UI dibuka lewat event gatrons-gacha:client:siapBuka.
    end)
end)

RegisterNetEvent('gatrons-gacha:client:siapBuka', function(payload)
    -- Karena ox_inventory use dibatalkan server, paksa tutup inventory sebelum fokus ke NUI.
    pcall(function()
        exports.ox_inventory:closeInventory()
    end)

    aturUi(true)
    kirimKeUi('buka', payload)
end)

RegisterNetEvent('gatrons-gacha:client:pending', function(payload)
    aturUi(true)
    kirimKeUi('pending', payload)
end)

RegisterNetEvent('gatrons-gacha:client:notif', function(pesan, tipe)
    lib.notify({
        type = tipe or 'inform',
        description = pesan,
    })
end)

CreateThread(function()
    Wait(3000)
    local pending = lib.callback.await('gatrons-gacha:server:cekPending', false)
    if pending then
        aturUi(true)
        kirimKeUi('pending', pending)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)

GachaClient = {
    aturUi = aturUi,
    kirimKeUi = kirimKeUi,
    lagiKebuka = function() return uiKebuka end,
}
