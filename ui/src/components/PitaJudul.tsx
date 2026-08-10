import type { ReactNode } from 'react'

type Props = {
  children: ReactNode
  aksen: string
  kanan?: ReactNode
}

export function PitaJudul({ children, aksen, kanan }: Props) {
  return (
    <div className="relative flex h-[42px] w-full items-center justify-center overflow-hidden">
      <div className="absolute inset-x-0 top-1/2 h-px -translate-y-1/2 bg-gradient-to-r from-transparent via-white/18 to-transparent" />
      <div
        className="relative min-w-[240px] skew-x-[-16deg] border-x border-white/10 px-9 py-2 text-center shadow-[0_0_36px_rgba(0,0,0,0.35)]"
        style={{ background: `linear-gradient(90deg, ${aksen}18, ${aksen}B8, ${aksen}18)` }}
      >
        <div className="skew-x-[16deg] text-[15px] font-bold uppercase tracking-[0.16em] text-white">{children}</div>
      </div>
      {kanan && <div className="absolute right-[4vw] top-1/2 -translate-y-1/2">{kanan}</div>}
    </div>
  )
}
