import type { Hadiah, InfoRarity } from '../types/gacha'
import { GambarHadiah } from './GambarHadiah'

type Props = {
  hadiah: Hadiah
  info: InfoRarity
  aktif?: boolean
  mini?: boolean
}

export function KartuHadiah({ hadiah, info, aktif = false, mini = false }: Props) {
  return (
    <div
      className={[
        'relative shrink-0 overflow-hidden border border-white/[0.08] bg-[#171820]/90',
        mini ? 'h-[118px] w-[132px]' : 'h-[154px] w-[158px]',
        aktif ? 'z-10 scale-[1.035]' : '',
      ].join(' ')}
      style={{
        borderColor: aktif ? `${info.warna}CC` : `${info.warna}42`,
        boxShadow: aktif ? `0 0 30px ${info.warna}44, inset 0 -50px 60px ${info.warna}12` : `inset 0 -45px 55px ${info.warna}0F`,
      }}
    >
      <div className="absolute inset-0 opacity-70" style={{ background: `linear-gradient(180deg, transparent 45%, ${info.warna}14 100%)` }} />
      <div className="absolute bottom-0 left-0 h-[3px] w-full" style={{ backgroundColor: info.warna, boxShadow: `0 0 15px ${info.warna}` }} />

      <div className="relative flex h-full flex-col items-center px-3 pb-3 pt-2.5">
        <GambarHadiah hadiah={hadiah} className={`${mini ? 'h-[72px] w-[92px]' : 'h-[94px] w-[116px]'} object-contain drop-shadow-[0_12px_18px_rgba(0,0,0,0.55)]`} />
        <div className="mt-auto w-full text-center">
          <p className={`${mini ? 'text-[10px]' : 'text-[11px]'} truncate font-bold uppercase tracking-[0.02em] text-white/90`}>{hadiah.label}</p>
          <div className="mt-1 flex items-center justify-center gap-1.5 text-[8px] uppercase tracking-[0.12em] text-white/38">
            <span style={{ color: info.warna }}>{info.label}</span>
            <span>•</span>
            <span>{hadiah.jenis === 'item' ? `x${hadiah.jumlah}` : 'Vehicle'}</span>
          </div>
        </div>
      </div>
    </div>
  )
}
