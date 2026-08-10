import { useEffect } from 'react'
import type { PesanNui } from '../types/gacha'

export const usePesanNui = (pasAdaPesan: (pesan: PesanNui) => void) => {
  useEffect(() => {
    const dengerin = (event: MessageEvent<PesanNui>) => {
      if (!event.data || typeof event.data.aksi !== 'string') return
      pasAdaPesan(event.data)
    }

    window.addEventListener('message', dengerin)
    return () => window.removeEventListener('message', dengerin)
  }, [pasAdaPesan])
}
