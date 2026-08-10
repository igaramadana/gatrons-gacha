local function notifShop(hasil)
    local sukses = hasil and hasil.oke == true

    lib.notify({
        title = 'Gatrons Case Shop',
        description = hasil and hasil.pesan or 'Server tidak merespons.',
        type = sukses and 'success' or 'error',
        duration = sukses and 3500 or 4500,
        position = 'top-right',
    })
end

RegisterNUICallback('tutup', function(_, cb)
    -- Kalau player baru berada di layar preview, batalkan sesi server.
    -- Kalau sudah rolling, server sengaja tidak membuang sesi tersebut.
    lib.callback.await('gatrons-gacha:server:batalSiap', false)

    GachaClient.aturUi(false)
    cb({ oke = true })
end)

RegisterNUICallback('bukaCase', function(data, cb)
    local token = data and data.token

    if type(token) ~= 'string' or token == '' then
        cb({ oke = false, kode = 'token_ngaco', pesan = 'Sesi opening tidak valid.' })
        return
    end

    local hasil = lib.callback.await('gatrons-gacha:server:bukaCase', false, token)
        or {
            oke = false,
            kode = 'server_ga_respon',
            pesan = 'Server tidak merespons.',
        }

    if not hasil.oke then
        lib.notify({
            title = 'Gatrons Case Opening',
            description = hasil.pesan or 'Gagal membuka box.',
            type = 'error',
            duration = 4500,
            position = 'top-right',
        })
    end

    cb(hasil)
end)

RegisterNUICallback('ambilHadiah', function(data, cb)
    local id = data and data.id
    if type(id) ~= 'string' then
        cb({ oke = false, pesan = 'ID opening tidak valid.' })
        return
    end

    local hasil = lib.callback.await('gatrons-gacha:server:klaim', false, id)
    cb(hasil or { oke = false, pesan = 'Server tidak merespons.' })
end)

RegisterNUICallback('siap', function(_, cb)
    cb({ oke = true })
end)

RegisterNUICallback('beliBox', function(data, cb)
    local namaBox = data and data.namaBox
    local jumlah = data and data.jumlah

    if type(namaBox) ~= 'string' or type(jumlah) ~= 'number' then
        local hasil = {
            oke = false,
            kode = 'payload_ngaco',
            pesan = 'Data pembelian tidak valid.',
        }

        notifShop(hasil)
        cb(hasil)
        return
    end

    local hasil = lib.callback.await('gatrons-gacha:server:beliBox', false, namaBox, jumlah)
        or {
            oke = false,
            kode = 'server_ga_respon',
            pesan = 'Server tidak merespons.',
        }

    notifShop(hasil)
    cb(hasil)
end)

RegisterNUICallback('refreshShop', function(_, cb)
    local hasil = lib.callback.await('gatrons-gacha:server:ambilShop', false)
    cb(hasil or { oke = false, pesan = 'Server tidak merespons.' })
end)
