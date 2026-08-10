import { motion } from 'motion/react'
import { FiPackage } from 'react-icons/fi'
import type { DataBox, NamaRarity } from '../types/gacha'
import { jalurAset } from '../lib/nui'
import { DaftarIsiBox } from './DaftarIsiBox'
import { PitaJudul } from './PitaJudul'

const urutanRarity: NamaRarity[] = ['common', 'uncommon', 'rare', 'epic', 'legendary']

type Props = {
  box: DataBox
  lagiBuka?: boolean
  pasBuka: () => void
}

export function LayarAwal({ box, lagiBuka = false, pasBuka }: Props) {
  return (
    <motion.section
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      transition={{ duration: 0.28 }}
      className="flex min-h-0 flex-1 flex-col"
    >
      <PitaJudul aksen={box.aksen}>{box.label}</PitaJudul>

      <div className="mx-auto flex w-full max-w-[1060px] flex-1 items-center justify-center px-6 py-2">
        <div className="grid w-full grid-cols-[minmax(0,1.35fr)_minmax(250px,0.65fr)] items-center gap-8">
          <div className="relative flex h-[310px] items-center justify-center">
            <div className="pointer-events-none absolute h-[250px] w-[430px] rounded-full opacity-40 blur-[70px]" style={{ backgroundColor: box.aksen }} />
            <motion.img
              src={jalurAset(box.gambarTutup)}
              alt={box.label}
              draggable={false}
              className="relative z-10 h-full w-full max-w-[610px] object-contain drop-shadow-[0_28px_40px_rgba(0,0,0,0.75)]"
              initial={{ scale: 0.9, y: 12 }}
              animate={{ scale: 1, y: [0, -5, 0] }}
              transition={{ scale: { duration: 0.45 }, y: { duration: 4, repeat: Infinity, ease: 'easeInOut' } }}
            />
          </div>

          <div className="flex flex-col justify-center">
            <p className="text-[9px] font-bold uppercase tracking-[0.24em] text-white/30">Ready to open</p>
            <h1 className="mt-2 text-[30px] font-bold uppercase leading-none text-white">{box.label}</h1>
            <p className="mt-3 max-w-[330px] text-[11px] leading-5 text-white/40">{box.deskripsi}</p>

            <div className="mt-5 grid grid-cols-5 gap-1">
              {urutanRarity.map((rarity) => {
                const info = box.rarity[rarity]
                const odds = box.odds[rarity] ?? 0
                if (odds <= 0) return null
                return (
                  <div key={rarity} className="border border-white/[0.06] bg-black/25 px-2 py-2 text-center">
                    <span className="mx-auto block h-1.5 w-1.5 rounded-full" style={{ backgroundColor: info.warna, boxShadow: `0 0 10px ${info.warna}` }} />
                    <p className="mt-1 text-[7px] uppercase tracking-[0.08em] text-white/35">{info.label}</p>
                    <p className="mt-0.5 text-[10px] font-bold text-white/80">{odds.toFixed(odds < 1 ? 2 : 1)}%</p>
                  </div>
                )
              })}
            </div>

            <motion.button
              type="button"
              onClick={pasBuka}
              disabled={lagiBuka}
              whileTap={lagiBuka ? undefined : { scale: 0.985 }}
              whileHover={lagiBuka ? undefined : { scale: 1.01 }}
              className="mt-5 flex h-[48px] w-full items-center justify-center gap-2 rounded-[7px] border border-white/10 text-[12px] font-bold uppercase tracking-[0.08em] text-black disabled:cursor-wait disabled:opacity-60"
              style={{
                background: `linear-gradient(178deg, ${box.aksen}CC 0%, ${box.aksen} 100%)`,
                boxShadow: `inset 0 0 24px rgba(0,0,0,.34), 0 0 30px ${box.aksen}16`,
              }}
            >
              <FiPackage /> {lagiBuka ? 'Preparing...' : 'Open case'}
            </motion.button>

            <div className="mt-4 flex items-center gap-3 text-[8px] uppercase tracking-[0.12em] text-white/24">
              <span className="h-px flex-1 bg-white/10" />
              box dipakai saat open case
              <span className="h-px flex-1 bg-white/10" />
            </div>
          </div>
        </div>
      </div>

      <DaftarIsiBox box={box} />
    </motion.section>
  )
}
