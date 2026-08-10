import { motion } from 'motion/react'
import { FiCheck, FiPackage, FiTruck, FiX } from 'react-icons/fi'
import type { DataBox, HasilKlaim } from '../types/gacha'
import { GambarHadiah } from './GambarHadiah'

type Props = {
  box: DataBox
  pending?: boolean
  statusPending?: string
  lagiKlaim: boolean
  hasilKlaim?: HasilKlaim | null
  pasKlaim: () => void
  pasTutup: () => void
}

export function LayarHasil({ box, pending, statusPending, lagiKlaim, hasilKlaim, pasKlaim, pasTutup }: Props) {
  const hadiah = box.menang
  if (!hadiah) return null

  const info = box.rarity[hadiah.rarity]
  const Ikon = hadiah.jenis === 'vehicle' ? FiTruck : FiPackage
  const udahMasuk = hasilKlaim?.oke === true

  return (
    <motion.section initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="fixed inset-0 z-50 flex items-center justify-center bg-[#111219]/88 backdrop-blur-[3px]">
      <div className="relative flex w-full max-w-[650px] flex-col items-center px-6 text-center">
        <div className="pointer-events-none absolute left-1/2 top-[45%] h-[310px] w-[520px] -translate-x-1/2 -translate-y-1/2 rounded-full opacity-20 blur-[90px]" style={{ backgroundColor: info.warna }} />

        <p className="relative text-[38px] font-bold uppercase leading-none tracking-[-0.03em] text-[#67ff7d] drop-shadow-[0_0_22px_rgba(103,255,125,.25)]">Congratulations!</p>
        <p className="relative mt-2 text-[10px] uppercase tracking-[0.2em] text-white/38">{pending ? 'pending reward recovered' : 'you won a reward'}</p>

        <motion.div
          initial={{ y: 18, scale: 0.92, opacity: 0 }}
          animate={{ y: 0, scale: 1, opacity: 1 }}
          transition={{ delay: 0.08, duration: 0.45 }}
          className="relative mt-7 h-[280px] w-[310px] overflow-hidden border bg-[#181920]/94"
          style={{ borderColor: `${info.warna}AA`, boxShadow: `0 0 46px ${info.warna}30, inset 0 -85px 90px ${info.warna}15` }}
        >
          <div className="absolute inset-x-0 bottom-0 h-[5px]" style={{ backgroundColor: info.warna, boxShadow: `0 0 20px ${info.warna}` }} />
          <div className="flex h-full flex-col items-center px-5 py-5">
            <GambarHadiah hadiah={hadiah} className="h-[180px] w-[245px] object-contain drop-shadow-[0_18px_25px_rgba(0,0,0,.65)]" />
            <p className="mt-auto text-[17px] font-bold uppercase text-white">{hadiah.label}</p>
            <div className="mt-1 flex items-center gap-2 text-[9px] uppercase tracking-[0.13em]">
              <span style={{ color: info.warna }}>{info.label}</span>
              <span className="text-white/25">•</span>
              <span className="text-white/38">{hadiah.jenis === 'item' ? `x${hadiah.jumlah}` : 'Vehicle'}</span>
            </div>
          </div>
        </motion.div>

        <div className="relative mt-4 flex items-center gap-2 text-[9px] uppercase tracking-[0.11em] text-white/32">
          <Ikon />
          {hadiah.jenis === 'vehicle' ? 'kendaraan masuk ke garage saat diklaim' : 'item masuk ke ox_inventory saat diklaim'}
        </div>

        {statusPending === 'claiming' && (
          <div className="relative mt-4 w-full max-w-[520px] border border-amber-400/20 bg-amber-400/[0.06] px-4 py-2.5 text-[9px] text-amber-100/65">
            Status masih claiming. Klaim dikunci untuk mencegah duplicate reward.
          </div>
        )}

        {hasilKlaim?.pesan && (
          <div className={`relative mt-4 flex w-full max-w-[520px] items-center justify-center gap-2 border px-4 py-2.5 text-[9px] ${hasilKlaim.oke ? 'border-emerald-400/20 bg-emerald-400/[0.06] text-emerald-100/75' : 'border-red-400/20 bg-red-400/[0.06] text-red-100/75'}`}>
            {hasilKlaim.oke ? <FiCheck /> : <FiX />} {hasilKlaim.pesan}
          </div>
        )}

        <div className="relative mt-5 flex gap-2">
          <motion.button
            type="button"
            whileTap={{ scale: 0.985 }}
            disabled={lagiKlaim || udahMasuk || statusPending === 'claiming'}
            onClick={pasKlaim}
            className="min-w-[190px] rounded-[6px] px-5 py-3.5 text-[10px] font-bold uppercase tracking-[0.08em] text-black disabled:cursor-not-allowed disabled:opacity-45"
            style={{ backgroundColor: info.warna, boxShadow: `inset 0 0 22px rgba(0,0,0,.28)` }}
          >
            {lagiKlaim ? 'Processing...' : udahMasuk ? 'Reward claimed' : 'Claim reward'}
          </motion.button>
          <button type="button" onClick={pasTutup} className="min-w-[140px] rounded-[6px] border border-white/10 bg-[#24252d]/65 px-5 py-3.5 text-[10px] font-bold uppercase tracking-[0.08em] text-white/55 transition hover:bg-[#30313a] hover:text-white">
            Close
          </button>
        </div>
      </div>
    </motion.section>
  )
}
