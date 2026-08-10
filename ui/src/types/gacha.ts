export type NamaRarity = 'common' | 'uncommon' | 'rare' | 'epic' | 'legendary'

export type InfoRarity = {
  label: string
  warna: string
}

export type Hadiah = {
  jenis: 'item' | 'vehicle'
  nama?: string
  model?: string
  label: string
  jumlah: number
  rarity: NamaRarity
  weight: number
  ikon?: string
  gambar?: string
  garasi?: string
}

export type DataBox = {
  nama: string
  label: string
  deskripsi: string
  gambarTutup: string
  gambarBuka: string
  aksen: string
  odds: Partial<Record<NamaRarity, number>>
  rarity: Record<NamaRarity, InfoRarity>
  pool: Hadiah[]
  // Pada preview awal belum ada pemenang.
  // Field ini baru dikirim server setelah tombol Open Case berhasil consume 1 box.
  menang?: Hadiah
}

export type PayloadBuka = {
  id: string
  status?: 'rolling' | 'ready' | 'claiming'
  box: DataBox
}

export type ResponsBukaCase = {
  oke: boolean
  kode?: string
  pesan?: string
  payload?: PayloadBuka
}

export type ProdukShop = {
  nama: string
  label: string
  deskripsi: string
  harga: number
  gambar: string
  aksen: string
  dimiliki: number
}

export type DataShop = {
  namaPlayer: string
  citizenid: string
  saldo: number
  labelCoin: string
  maksimalJumlah: number
  produk: ProdukShop[]
}

export type PesanNui =
  | { aksi: 'buka'; data?: PayloadBuka }
  | { aksi: 'pending'; data?: PayloadBuka }
  | { aksi: 'shop'; data?: DataShop }
  | { aksi: 'coin'; data?: { saldo: number } }
  | { aksi: 'tutup' }

export type HasilKlaim = {
  oke: boolean
  kode?: string
  pesan?: string
  hadiah?: Hadiah
  info?: unknown
}

export type HasilBeliShop = {
  oke: boolean
  kode?: string
  pesan?: string
  saldo?: number
  namaBox?: string
  jumlah?: number
  dimiliki?: number
}

export type ResponsShop = {
  oke: boolean
  kode?: string
  pesan?: string
  data?: DataShop
}
