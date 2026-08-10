import { useCallback, useEffect, useMemo, useState } from 'react'
import { AnimatePresence, motion } from 'motion/react'
import { FiVolume2 } from 'react-icons/fi'
import { LogoGatrons } from './components/LogoGatrons'
import { LayarAwal } from './components/LayarAwal'
import { LayarHasil } from './components/LayarHasil'
import { LayarRoll } from './components/LayarRoll'
import { LayarShop } from './components/LayarShop'
import { PreviewDev } from './components/PreviewDev'
import { previewClassic, previewPremium, previewShop } from './data/preview'
import { usePesanNui } from './hooks/usePesanNui'
import { lagiDiFivem, nembakNui } from './lib/nui'
import type { DataShop, HasilBeliShop, HasilKlaim, PayloadBuka, PesanNui, ResponsBukaCase } from './types/gacha'

type Tahap = 'ngumpet' | 'shop' | 'siap' | 'ngocok' | 'hasil'

function App() {
  const browser = useMemo(() => !lagiDiFivem(), [])
  const [payload, setPayload] = useState<PayloadBuka | null>(browser ? previewClassic : null)
  const [shop, setShop] = useState<DataShop | null>(browser ? previewShop : null)
  const [tahap, setTahap] = useState<Tahap>(browser ? 'siap' : 'ngumpet')
  const [pending, setPending] = useState(false)
  const [lagiKlaim, setLagiKlaim] = useState(false)
  const [hasilKlaim, setHasilKlaim] = useState<HasilKlaim | null>(null)
  const [lagiBeli, setLagiBeli] = useState(false)
  const [lagiMulai, setLagiMulai] = useState(false)

  const masukPayload = useCallback((baru: PayloadBuka, dariPending = false) => {
    setPayload(baru)
    setPending(dariPending)
    setHasilKlaim(null)
    setLagiKlaim(false)
    setLagiMulai(false)
    setTahap(dariPending ? 'hasil' : 'siap')
  }, [])

  const masukShop = useCallback((baru: DataShop) => {
    setShop(baru)
    setLagiBeli(false)
    setTahap('shop')
  }, [])

  const pasPesan = useCallback((pesan: PesanNui) => {
    if (pesan.aksi === 'buka' && pesan.data) masukPayload(pesan.data, false)
    if (pesan.aksi === 'pending' && pesan.data) masukPayload(pesan.data, true)
    if (pesan.aksi === 'shop' && pesan.data) masukShop(pesan.data)
    if (pesan.aksi === 'coin' && pesan.data) {
      setShop((lama) => lama ? { ...lama, saldo: pesan.data!.saldo } : lama)
    }
    if (pesan.aksi === 'tutup') setTahap('ngumpet')
  }, [masukPayload, masukShop])

  usePesanNui(pasPesan)

  const tutup = useCallback(async () => {
    if (tahap === 'ngocok' || lagiBeli || lagiMulai) return
    try { await nembakNui('tutup') } catch { /* client tetap handle focus cleanup */ }
    setTahap('ngumpet')
  }, [lagiBeli, lagiMulai, tahap])

  const mulaiBukaCase = useCallback(async () => {
    if (!payload || lagiMulai) return

    if (browser) {
      setTahap('ngocok')
      return
    }

    setLagiMulai(true)

    try {
      const hasil = await nembakNui<ResponsBukaCase>('bukaCase', { token: payload.id })

      if (hasil.oke && hasil.payload?.box.menang) {
        setPayload(hasil.payload)
        setPending(false)
        setTahap('ngocok')
      }
    } catch {
      // Error detail ditampilkan client lewat ox_lib notify.
    } finally {
      setLagiMulai(false)
    }
  }, [browser, lagiMulai, payload])

  const klaim = useCallback(async () => {
    if (!payload || lagiKlaim) return
    setLagiKlaim(true)
    setHasilKlaim(null)

    try {
      const hasil = await nembakNui<HasilKlaim>('ambilHadiah', { id: payload.id })
      setHasilKlaim(hasil)
    } catch {
      setHasilKlaim({ oke: false, pesan: 'Gagal komunikasi dengan game client.' })
    } finally {
      setLagiKlaim(false)
    }
  }, [payload, lagiKlaim])

  const beliBox = useCallback(async (namaBox: string, jumlah: number) => {
    if (!shop || lagiBeli) return

    setLagiBeli(true)

    try {
      let hasil: HasilBeliShop

      if (browser) {
        const produk = shop.produk.find((item) => item.nama === namaBox)
        const total = (produk?.harga ?? 0) * jumlah

        hasil = shop.saldo >= total && total > 0
          ? {
              oke: true,
              pesan: `Browser preview: berhasil membeli ${jumlah}x ${produk?.label ?? namaBox}.`,
              saldo: shop.saldo - total,
              namaBox,
              jumlah,
              dimiliki: (produk?.dimiliki ?? 0) + jumlah,
            }
          : { oke: false, pesan: 'Gatrons Coin kamu tidak cukup.', saldo: shop.saldo }
      } else {
        hasil = await nembakNui<HasilBeliShop>('beliBox', { namaBox, jumlah })
      }

      if (typeof hasil.saldo === 'number') {
        setShop((lama) => {
          if (!lama) return lama

          return {
            ...lama,
            saldo: hasil.saldo ?? lama.saldo,
            produk: lama.produk.map((produk) =>
              hasil.oke && produk.nama === hasil.namaBox && typeof hasil.dimiliki === 'number'
                ? { ...produk, dimiliki: hasil.dimiliki }
                : produk,
            ),
          }
        })
      }
    } catch (error) {
      if (browser) console.warn('[gatrons-gacha] gagal beli box dari browser preview', error)
    } finally {
      setLagiBeli(false)
    }
  }, [browser, lagiBeli, shop])

  useEffect(() => {
    const pencet = (event: KeyboardEvent) => {
      if (event.key === 'Escape' && tahap !== 'ngocok' && !lagiBeli && !lagiMulai) void tutup()
    }
    window.addEventListener('keydown', pencet)
    return () => window.removeEventListener('keydown', pencet)
  }, [lagiBeli, lagiMulai, tahap, tutup])

  const gachaKelihatan = tahap !== 'ngumpet' && tahap !== 'shop' && payload
  const shopKelihatan = tahap === 'shop' && shop

  return (
    <>
      <AnimatePresence>
        {gachaKelihatan && payload && (
          <motion.main
            key="gatrons-gacha"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 flex min-h-screen flex-col overflow-hidden bg-[#1a1b22] text-white"
          >
            <div className="pointer-events-none absolute inset-0 bg-cover bg-center opacity-95" style={{ backgroundImage: "url('./reference/general-bg.png')" }} />
            <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_50%_48%,transparent_0%,rgba(7,8,11,.12)_48%,rgba(7,8,11,.72)_100%)]" />
            <div className="pointer-events-none absolute inset-0 bg-black/10" />

            <header className="relative z-20 flex h-[78px] shrink-0 items-center justify-between px-[3vw]">
              <LogoGatrons />
              <div className="flex items-center gap-4 text-[9px] uppercase tracking-[0.12em] text-white/35">
                <FiVolume2 className="text-sm" />
                <span className="h-4 w-px bg-white/10" />
                <span className="rounded-[4px] border border-white/15 bg-black/25 px-2 py-1 text-[8px] font-bold text-white/60">ESC</span>
                <span>{tahap === 'ngocok' ? 'Locked while rolling' : 'Close'}</span>
              </div>
            </header>

            <div className="relative z-10 flex min-h-0 flex-1 flex-col">
              <AnimatePresence mode="wait">
                {tahap === 'siap' && <LayarAwal key="siap" box={payload.box} lagiBuka={lagiMulai} pasBuka={() => void mulaiBukaCase()} />}
                {tahap === 'ngocok' && <LayarRoll key="ngocok" box={payload.box} pasSelesai={() => setTahap('hasil')} />}
                {tahap === 'hasil' && <LayarHasil key="hasil" box={payload.box} pending={pending} statusPending={payload.status} lagiKlaim={lagiKlaim} hasilKlaim={hasilKlaim} pasKlaim={() => void klaim()} pasTutup={() => void tutup()} />}
              </AnimatePresence>
            </div>
          </motion.main>
        )}
      </AnimatePresence>

      <AnimatePresence>
        {shopKelihatan && shop && (
          <LayarShop
            key="gatrons-shop"
            shop={shop}
            lagiBeli={lagiBeli}
            pasBeli={(namaBox, jumlah) => void beliBox(namaBox, jumlah)}
            pasTutup={() => void tutup()}
          />
        )}
      </AnimatePresence>

      {browser && (
        <PreviewDev
          pasShop={() => masukShop(previewShop)}
          pasClassic={() => masukPayload(previewClassic, false)}
          pasPremium={() => masukPayload(previewPremium, false)}
          pasRoll={() => { if (!payload) masukPayload(previewClassic, false); setTahap('ngocok') }}
          pasHasil={() => { if (!payload) masukPayload(previewClassic, false); setTahap('hasil') }}
        />
      )}
    </>
  )
}

export default App
