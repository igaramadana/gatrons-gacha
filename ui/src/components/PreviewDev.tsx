import { FiCode } from 'react-icons/fi'

type Props = {
  pasShop: () => void
  pasClassic: () => void
  pasPremium: () => void
  pasRoll: () => void
  pasHasil: () => void
}

export function PreviewDev({ pasShop, pasClassic, pasPremium, pasRoll, pasHasil }: Props) {
  return (
    <div className="fixed bottom-5 right-5 z-[100] rounded-xl border border-white/10 bg-[#05080C]/90 p-2 shadow-2xl backdrop-blur-xl">
      <div className="mb-2 flex items-center gap-2 px-2 py-1 text-[9px] font-bold uppercase tracking-[0.18em] text-white/35">
        <FiCode /> Browser preview
      </div>
      <div className="grid grid-cols-2 gap-1.5">
        {[
          ['Shop', pasShop],
          ['Classic', pasClassic],
          ['Premium', pasPremium],
          ['Roll', pasRoll],
          ['Result', pasHasil],
        ].map(([label, aksi]) => (
          <button key={label as string} onClick={aksi as () => void} className="rounded-md border border-white/10 bg-white/[0.035] px-3 py-2 text-[9px] font-bold uppercase tracking-[0.1em] text-white/55 hover:bg-white/[0.08] hover:text-white">
            {label as string}
          </button>
        ))}
      </div>
    </div>
  )
}
