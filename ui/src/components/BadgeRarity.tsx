import type { InfoRarity, NamaRarity } from '../types/gacha'

type Props = {
  nama: NamaRarity
  info: InfoRarity
  persen?: number
}

export function BadgeRarity({ nama, info, persen }: Props) {
  return (
    <div
      className="min-w-[92px] rounded-lg border bg-black/30 px-3 py-2 text-left backdrop-blur-sm"
      style={{ borderColor: `${info.warna}55`, boxShadow: `inset 0 0 24px ${info.warna}0C` }}
    >
      <div className="flex items-center gap-2">
        <span className="h-1.5 w-1.5 rounded-full" style={{ backgroundColor: info.warna, boxShadow: `0 0 10px ${info.warna}` }} />
        <span className="text-[10px] font-bold uppercase tracking-[0.16em] text-white/55">{nama}</span>
      </div>
      <p className="mt-1.5 text-sm font-bold text-white">{persen?.toFixed(persen < 1 ? 2 : 1) ?? '0'}%</p>
    </div>
  )
}
