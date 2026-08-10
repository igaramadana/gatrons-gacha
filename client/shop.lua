local npcAktif = {}
local lagiBikin = {}

local function logShop(pesan, warna)
    local cfg = Config.Shop or {}

    if cfg.debugSpawn == false and warna ~= '^1' then
        return
    end

    print(('%s[gatrons-gacha:shop] %s^7'):format(warna or '^3', pesan))
end

local function notif(pesan, tipe)
    lib.notify({
        title = 'Gatrons Case Shop',
        type = tipe or 'inform',
        description = pesan,
    })
end

local function bukaShop()
    if not GachaClient or type(GachaClient.lagiKebuka) ~= 'function' then
        notif('Gacha client belum siap.', 'error')
        return
    end

    if GachaClient.lagiKebuka() then
        notif('Tutup UI yang sedang terbuka dulu.', 'error')
        return
    end

    local respons = lib.callback.await('gatrons-gacha:server:ambilShop', false)

    if not respons or not respons.oke or not respons.data then
        notif(respons and respons.pesan or 'Case shop belum siap.', 'error')
        return
    end

    GachaClient.aturUi(true)
    GachaClient.kirimKeUi('shop', respons.data)
end

local function mintaModel(model)
    local hash = type(model) == 'number' and model or joaat(model)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return nil, 'model_ga_valid'
    end

    RequestModel(hash)

    local batas = GetGameTimer() + 10000

    while not HasModelLoaded(hash) do
        if GetGameTimer() >= batas then
            return nil, 'model_timeout'
        end

        Wait(25)
    end

    return hash
end

local function hapusNpc(index)
    local data = npcAktif[index]
    if not data then return end

    if data.ped and DoesEntityExist(data.ped) then
        pcall(function()
            exports.ox_target:removeLocalEntity(data.ped, data.namaTarget)
        end)

        SetEntityAsMissionEntity(data.ped, true, true)
        DeletePed(data.ped)
    end

    npcAktif[index] = nil
end

local function bikinNpc(index, data)
    if npcAktif[index] or lagiBikin[index] then
        return
    end

    if type(data) ~= 'table' or not data.model or not data.coords then
        logShop(('NPC #%s config tidak valid.'):format(index), '^1')
        return
    end

    lagiBikin[index] = true

    CreateThread(function()
        local hash, errModel = mintaModel(data.model)

        if not hash then
            lagiBikin[index] = nil
            logShop(
                ('NPC #%s gagal load model %s (%s).'):format(
                    index,
                    tostring(data.model),
                    tostring(errModel)
                ),
                '^1'
            )
            return
        end

        local coords = data.coords
        local x = tonumber(coords.x)
        local y = tonumber(coords.y)
        local z = tonumber(coords.z)
        local heading = tonumber(coords.w) or 0.0
        local zOffset = tonumber(data.zOffset) or 0.0

        if not x or not y or not z then
            SetModelAsNoLongerNeeded(hash)
            lagiBikin[index] = nil
            logShop(('NPC #%s coords tidak valid.'):format(index), '^1')
            return
        end

        local spawnZ = z + zOffset

        -- NPC baru dibuat saat player sudah dekat, jadi collision area mestinya sudah streaming.
        RequestCollisionAtCoord(x, y, spawnZ)

        local batasCollision = GetGameTimer() + 3000
        while GetGameTimer() < batasCollision do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local jarak = #(playerCoords - vector3(x, y, spawnZ))

            if jarak <= 100.0 then
                break
            end

            Wait(50)
        end

        local ped = CreatePed(
            4,
            hash,
            x,
            y,
            spawnZ,
            heading,
            false,
            false
        )

        if not ped or ped == 0 or not DoesEntityExist(ped) then
            SetModelAsNoLongerNeeded(hash)
            lagiBikin[index] = nil
            logShop(('NPC #%s CreatePed gagal.'):format(index), '^1')
            return
        end

        SetEntityAsMissionEntity(ped, true, true)
        SetEntityCoordsNoOffset(ped, x, y, spawnZ, false, false, false)
        SetEntityHeading(ped, heading)
        SetEntityVisible(ped, true, false)
        SetEntityAlpha(ped, 255, false)

        SetEntityInvincible(ped, true)
        SetEntityCanBeDamaged(ped, false)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedCanRagdoll(ped, false)
        SetPedDiesWhenInjured(ped, false)
        SetPedFleeAttributes(ped, 0, false)
        SetPedDropsWeaponsWhenDead(ped, false)

        if type(data.scenario) == 'string' and data.scenario ~= '' then
            TaskStartScenarioInPlace(ped, data.scenario, 0, true)
        end

        FreezeEntityPosition(ped, true)

        local namaTarget = ('gatrons_gacha_shop_%s'):format(index)

        local targetOke, targetErr = pcall(function()
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = namaTarget,
                    icon = data.icon or 'fa-solid fa-box-open',
                    label = data.label or 'Buka Gatrons Case Shop',
                    distance = math.max(0.5, tonumber(data.distance) or 2.0),
                    onSelect = bukaShop,
                },
            })
        end)

        if not targetOke then
            DeletePed(ped)
            SetModelAsNoLongerNeeded(hash)
            lagiBikin[index] = nil

            logShop(
                ('NPC #%s gagal daftar ox_target: %s'):format(
                    index,
                    tostring(targetErr)
                ),
                '^1'
            )
            return
        end

        npcAktif[index] = {
            ped = ped,
            namaTarget = namaTarget,
        }

        lagiBikin[index] = nil
        SetModelAsNoLongerNeeded(hash)

        logShop(
            ('NPC #%s SPAWNED | ped=%s | model=%s | %.2f %.2f %.2f | heading=%.2f'):format(
                index,
                ped,
                tostring(data.model),
                x,
                y,
                spawnZ,
                heading
            ),
            '^2'
        )
    end)
end

local function cekNpcSekitar()
    local cfg = Config.Shop or {}

    if cfg.aktif == false then
        return
    end

    if GetResourceState('ox_target') ~= 'started' then
        return
    end

    local playerPed = PlayerPedId()
    if not playerPed or playerPed == 0 then
        return
    end

    local playerCoords = GetEntityCoords(playerPed)

    for index, data in ipairs(cfg.npc or {}) do
        local coords = data.coords

        if coords then
            local tujuan = vector3(
                tonumber(coords.x) or 0.0,
                tonumber(coords.y) or 0.0,
                (tonumber(coords.z) or 0.0) + (tonumber(data.zOffset) or 0.0)
            )

            local jarak = #(playerCoords - tujuan)
            local spawnDistance = math.max(10.0, tonumber(data.spawnDistance) or 80.0)
            local despawnDistance = math.max(spawnDistance + 10.0, tonumber(data.despawnDistance) or 120.0)
            local aktif = npcAktif[index]

            if jarak <= spawnDistance then
                if not aktif or not aktif.ped or not DoesEntityExist(aktif.ped) then
                    bikinNpc(index, data)
                end
            elseif jarak >= despawnDistance and aktif then
                hapusNpc(index)
                logShop(('NPC #%s despawn karena player menjauh (%.1fm).'):format(index, jarak), '^3')
            end
        end
    end
end

RegisterNetEvent('gatrons-gacha:client:coinUpdate', function(saldo)
    if not GachaClient then return end

    GachaClient.kirimKeUi('coin', {
        saldo = math.max(0, math.floor(tonumber(saldo) or 0)),
    })
end)

CreateThread(function()
    while not NetworkIsSessionStarted() do
        Wait(250)
    end

    while true do
        cekNpcSekitar()
        Wait(750)
    end
end)

-- Kalau ox_target direstart saat player masih dekat, target dibangun ulang.
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= 'ox_target' then return end

    for index in pairs(npcAktif) do
        hapusNpc(index)
    end

    Wait(1000)
    cekNpcSekitar()
end)

RegisterCommand('gachashoprespawn', function()
    for index in pairs(npcAktif) do
        hapusNpc(index)
    end

    Wait(250)
    cekNpcSekitar()
end, false)

RegisterCommand('gachashopdebug', function()
    local cfg = Config.Shop or {}
    local playerCoords = GetEntityCoords(PlayerPedId())

    print(('^3[gatrons-gacha:shop] ox_target=%s, shopAktif=%s^7'):format(
        GetResourceState('ox_target'),
        tostring(cfg.aktif ~= false)
    ))

    for index, data in ipairs(cfg.npc or {}) do
        local coords = data.coords

        if coords then
            local tujuan = vector3(
                coords.x,
                coords.y,
                coords.z + (tonumber(data.zOffset) or 0.0)
            )

            local jarak = #(playerCoords - tujuan)
            local aktif = npcAktif[index]
            local ped = aktif and aktif.ped or 0

            print(('^3[gatrons-gacha:shop] #%s jarak=%.1fm ped=%s exists=%s^7'):format(
                index,
                jarak,
                ped,
                tostring(ped ~= 0 and DoesEntityExist(ped))
            ))
        end
    end
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for index in pairs(npcAktif) do
        hapusNpc(index)
    end
end)
