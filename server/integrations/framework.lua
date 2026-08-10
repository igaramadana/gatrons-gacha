GachaFramework = {}

local frameworkAktif = nil
local qbCore = nil

local function resourceNyala(nama)
    return type(nama) == 'string' and nama ~= '' and GetResourceState(nama) == 'started'
end

local function ambilConfig()
    return Config.Framework or {}
end

local function tentuinFramework()
    local cfg = ambilConfig()
    local mode = type(cfg.mode) == 'string' and cfg.mode:lower() or 'auto'
    local resourceQbox = cfg.resourceQbox or 'qbx_core'
    local resourceQb = cfg.resourceQb or 'qb-core'

    if mode == 'qbox' then
        return resourceNyala(resourceQbox) and 'qbox' or nil
    end

    if mode == 'qb' then
        return resourceNyala(resourceQb) and 'qb' or nil
    end

    if resourceNyala(resourceQbox) then return 'qbox' end
    if resourceNyala(resourceQb) then return 'qb' end

    return nil
end

local function ambilQbCore()
    local cfg = ambilConfig()
    local resourceQb = cfg.resourceQb or 'qb-core'

    if not resourceNyala(resourceQb) then
        qbCore = nil
        return nil
    end

    if qbCore then return qbCore end

    local oke, core = pcall(function()
        return exports[resourceQb]:GetCoreObject()
    end)

    if not oke or not core then
        return nil
    end

    qbCore = core
    return qbCore
end

function GachaFramework.deteksi()
    local hasil = tentuinFramework()

    if hasil ~= frameworkAktif then
        frameworkAktif = hasil
        qbCore = nil

        if Config.Debug then
            print(('[gatrons-gacha] Framework aktif: %s'):format(frameworkAktif or 'ga_ketemu'))
        end
    end

    return frameworkAktif
end

function GachaFramework.ambilNama()
    return GachaFramework.deteksi()
end

function GachaFramework.ambilPlayer(source)
    local framework = GachaFramework.deteksi()
    local cfg = ambilConfig()

    if framework == 'qbox' then
        local resourceQbox = cfg.resourceQbox or 'qbx_core'
        local oke, player = pcall(function()
            return exports[resourceQbox]:GetPlayer(source)
        end)

        if oke then return player end
        return nil
    end

    if framework == 'qb' then
        local core = ambilQbCore()
        if not core or not core.Functions or not core.Functions.GetPlayer then return nil end
        return core.Functions.GetPlayer(source)
    end

    return nil
end

function GachaFramework.ambilCitizenId(source)
    local player = GachaFramework.ambilPlayer(source)
    local data = player and player.PlayerData
    local citizenid = data and data.citizenid

    if type(citizenid) ~= 'string' or citizenid == '' then
        return nil, 'citizenid_ga_ketemu'
    end

    return citizenid
end

function GachaFramework.ambilLicense(source)
    local player = GachaFramework.ambilPlayer(source)
    local data = player and player.PlayerData

    if data and type(data.license) == 'string' and data.license ~= '' then
        return data.license
    end

    local license = GetPlayerIdentifierByType(source, 'license')
    if type(license) == 'string' and license ~= '' then
        return license
    end

    return nil, 'license_ga_ketemu'
end



AddEventHandler('onResourceStart', function(resourceName)
    local cfg = ambilConfig()
    if resourceName == GetCurrentResourceName()
        or resourceName == (cfg.resourceQbox or 'qbx_core')
        or resourceName == (cfg.resourceQb or 'qb-core') then
        frameworkAktif = nil
        qbCore = nil
        GachaFramework.deteksi()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    local cfg = ambilConfig()
    if resourceName == (cfg.resourceQbox or 'qbx_core')
        or resourceName == (cfg.resourceQb or 'qb-core') then
        frameworkAktif = nil
        qbCore = nil
    end
end)
