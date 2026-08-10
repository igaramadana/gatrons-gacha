import { motion } from 'motion/react'
import type { DataBox } from '../types/gacha'
import { jalurAset } from '../lib/nui'
import { DaftarIsiBox } from './DaftarIsiBox'
import { PitaJudul } from './PitaJudul'
import { RelHadiah } from './RelHadiah'

type Props = {
  box: DataBox
  pasSelesai: () => void
}

export function LayarRoll({ box, pasSelesai }: Props) {
  return (
    <motion.section initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="flex min-h-0 flex-1 flex-col">
      <PitaJudul aksen={box.aksen}>{box.label}</PitaJudul>

      <div className="mx-auto flex w-full max-w-[1180px] flex-1 flex-col items-center justify-center px-5">
        <div className="mb-3 flex h-[104px] items-center justify-center">
          <motion.img
            src={jalurAset(box.gambarBuka)}
            alt={box.label}
            draggable={false}
            className="h-[125px] w-[190px] object-contain drop-shadow-[0_20px_30px_rgba(0,0,0,.65)]"
            animate={{ x: [0, -3, 3, -2, 2, 0], rotate: [0, -1, 1, -0.7, 0.7, 0], scale: [1, 1.03, 1] }}
            transition={{ duration: 0.62, repeat: 1 }}
          />
        </div>
        <p className="mb-4 text-[12px] font-bold uppercase tracking-[0.2em] text-white/70">Opening...</p>
        <RelHadiah box={box} pasSelesai={pasSelesai} />
        <p className="mt-3 text-[8px] uppercase tracking-[0.18em] text-white/25">result sudah dikunci server • jangan tutup nui saat roll</p>
      </div>

      <DaftarIsiBox box={box} />
    </motion.section>
  )
}
