import type { DataBox } from '../types/gacha'
import { KartuHadiah } from './KartuHadiah'
import { PitaJudul } from './PitaJudul'

type Props = { box: DataBox }

export function DaftarIsiBox({ box }: Props) {
  return (
    <div className="min-h-0 w-full">
      <PitaJudul
        aksen={box.aksen}
        kanan={<span className="text-[9px] font-bold uppercase tracking-[0.16em] text-white/35">Items&nbsp; {box.pool.length}</span>}
      >
        Case items
      </PitaJudul>
      <div className="mx-auto mt-3 flex max-w-[1180px] flex-wrap justify-center gap-[3px] overflow-hidden px-6">
        {box.pool.map((hadiah, index) => (
          <KartuHadiah key={`${hadiah.jenis}-${hadiah.nama ?? hadiah.model}-${index}`} hadiah={hadiah} info={box.rarity[hadiah.rarity]} mini />
        ))}
      </div>
    </div>
  )
}
