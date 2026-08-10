import { useMemo, useState } from 'react'
import { FiBox, FiTruck } from 'react-icons/fi'
import type { Hadiah } from '../types/gacha'
import { ambilGambarHadiah } from '../lib/gambar'

type Props = {
  hadiah: Hadiah
  className?: string
}

export function GambarHadiah({ hadiah, className = '' }: Props) {
  const [gagal, setGagal] = useState(false)
  const sumber = useMemo(() => ambilGambarHadiah(hadiah), [hadiah])
  const Ikon = hadiah.jenis === 'vehicle' ? FiTruck : FiBox

  if (!sumber || gagal) {
    return (
      <div className={`flex items-center justify-center text-white/35 ${className}`} aria-label={hadiah.label}>
        <Ikon className="h-10 w-10" />
      </div>
    )
  }

  return (
    <img
      src={sumber}
      alt={hadiah.label}
      draggable={false}
      className={className}
      onError={() => setGagal(true)}
    />
  )
}
