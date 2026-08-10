GachaUtils = {}

function GachaUtils.copyTabel(asli)
    if type(asli) ~= 'table' then return asli end

    local salinan = {}
    for k, v in pairs(asli) do
        salinan[k] = GachaUtils.copyTabel(v)
    end

    return salinan
end

function GachaUtils.bersihinTeks(nilai, maksimal)
    if type(nilai) ~= 'string' then return nil end
    if #nilai == 0 or #nilai > maksimal then return nil end
    return nilai
end

function GachaUtils.debugPrint(...)
    if not Config.Debug then return end
    print('^3[gatrons-gacha]^7', ...)
end
