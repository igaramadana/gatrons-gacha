local function notifPlayer(source, data)
    if source == 0 then
        print(('[gatrons-gacha] %s'):format(data.description or data.title or ''))
        return
    end

    TriggerClientEvent('ox_lib:notify', source, data)
end

local function bolehPakeCommand(source)
    -- Server console selalu boleh.
    if source == 0 then
        return true
    end

    return IsPlayerAceAllowed(source, 'group.admin')
end

local function namaPlayer(source)
    if source == 0 then
        return 'CONSOLE'
    end

    return GetPlayerName(source) or ('ID %s'):format(source)
end

lib.addCommand('setcoin', {
    help = 'Set saldo Gatrons Coin player',
    params = {
        {
            name = 'id',
            type = 'playerId',
            help = 'Server ID player',
        },
        {
            name = 'amount',
            type = 'number',
            help = 'Saldo Gatrons Coin baru',
        },
    },
}, function(source, args)
    if not bolehPakeCommand(source) then
        notifPlayer(source, {
            title = 'Gatrons Coin',
            description = 'Kamu tidak punya permission untuk command ini.',
            type = 'error',
            duration = 4500,
            position = 'top-right',
        })

        print(('^1[gatrons-gacha] %s (%s) mencoba /setcoin tanpa permission.^7'):format(
            namaPlayer(source),
            source
        ))
        return
    end

    local target = math.floor(tonumber(args.id) or 0)
    local amount = math.floor(tonumber(args.amount) or -1)

    if target <= 0 or GetPlayerPing(target) <= 0 then
        notifPlayer(source, {
            title = 'Gatrons Coin',
            description = ('Player ID %s tidak online.'):format(target),
            type = 'error',
            duration = 4500,
            position = 'top-right',
        })
        return
    end

    local cfgCoin = Config.Coin or {}
    local maksimalSaldo = tonumber(cfgCoin.maksimalSaldo) or 2000000000

    if amount < 0 or amount > maksimalSaldo then
        notifPlayer(source, {
            title = 'Gatrons Coin',
            description = ('Amount harus 0 - %s.'):format(maksimalSaldo),
            type = 'error',
            duration = 4500,
            position = 'top-right',
        })
        return
    end

    local oke, hasil, citizenid = GachaCoin.set(
        target,
        amount,
        ('admin_setcoin:%s'):format(source)
    )

    if not oke then
        notifPlayer(source, {
            title = 'Gatrons Coin',
            description = ('Gagal set coin: %s'):format(tostring(hasil)),
            type = 'error',
            duration = 5000,
            position = 'top-right',
        })
        return
    end

    local targetName = namaPlayer(target)
    local adminName = namaPlayer(source)

    notifPlayer(source, {
        title = 'Gatrons Coin',
        description = ('Saldo %s [ID %s] diset menjadi %s coin.'):format(
            targetName,
            target,
            hasil
        ),
        type = 'success',
        duration = 4500,
        position = 'top-right',
    })

    notifPlayer(target, {
        title = 'Gatrons Coin',
        description = ('Saldo kamu sekarang %s coin.'):format(hasil),
        type = 'success',
        duration = 4000,
        position = 'top-right',
    })

    print(('^2[gatrons-gacha] %s (%s) set coin %s [ID %s | citizenid=%s] -> %s^7'):format(
        adminName,
        source,
        targetName,
        target,
        tostring(citizenid),
        hasil
    ))
end)
