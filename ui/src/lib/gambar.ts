import type { Hadiah } from '../types/gacha'
import { jalurAset } from './nui'

const sumberLangsung = /^(https?:|data:|blob:)/i

const ubahNuiKeCfx = (nilai: string) => {
  if (!nilai.toLowerCase().startsWith('nui://')) return nilai

  const tanpaSkema = nilai.slice('nui://'.length)
  const potongan = tanpaSkema.split('/')
  const resource = potongan.shift()
  if (!resource) return nilai

  return `https://cfx-nui-${resource}/${potongan.join('/')}`
}

export const ambilGambarHadiah = (hadiah: Hadiah) => {
  if (!hadiah.gambar) {
    return hadiah.jenis === 'item' && hadiah.nama
      ? `https://cfx-nui-ox_inventory/web/images/${hadiah.nama}.png`
      : null
  }

  if (hadiah.gambar.toLowerCase().startsWith('nui://')) return ubahNuiKeCfx(hadiah.gambar)
  if (sumberLangsung.test(hadiah.gambar)) return hadiah.gambar
  if (hadiah.jenis === 'item') return `https://cfx-nui-ox_inventory/web/images/${hadiah.gambar.replace(/^\/+/, '')}`
  return jalurAset(hadiah.gambar)
}
