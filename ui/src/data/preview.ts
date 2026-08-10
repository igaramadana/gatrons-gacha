import type { DataBox, PayloadBuka } from '../types/gacha'

const rarity: DataBox['rarity'] = {
  common: { label: 'Common', warna: '#8B95A7' },
  uncommon: { label: 'Uncommon', warna: '#58D878' },
  rare: { label: 'Rare', warna: '#3E8BFF' },
  epic: { label: 'Epic', warna: '#C54CFF' },
  legendary: { label: 'Legendary', warna: '#FFBE2E' },
}

const isiClassic: DataBox['pool'] = [
  { jenis: 'item', nama: 'water', label: 'Water', jumlah: 3, rarity: 'common', weight: 3200, gambar: 'water.png' },
  { jenis: 'item', nama: 'bandage', label: 'Bandage', jumlah: 2, rarity: 'common', weight: 2800, gambar: 'bandage.png' },
  { jenis: 'item', nama: 'lockpick', label: 'Lockpick', jumlah: 1, rarity: 'uncommon', weight: 1700, gambar: 'lockpick.png' },
  { jenis: 'item', nama: 'repairkit', label: 'Repair Kit', jumlah: 1, rarity: 'rare', weight: 800, gambar: 'repairkit.png' },
  { jenis: 'item', nama: 'armor', label: 'Armor', jumlah: 1, rarity: 'epic', weight: 350, gambar: 'armor.png' },
  { jenis: 'vehicle', model: 'sultanrs', label: 'Karin Sultan RS', jumlah: 1, rarity: 'legendary', weight: 70 },
]

export const previewClassic: PayloadBuka = {
  id: 'preview_classic_001',
  box: {
    nama: 'classic_box',
    label: 'Classic Box',
    deskripsi: 'Standard Gatrons case. Open it to roll one random reward from the drop pool.',
    gambarTutup: 'gacha/classic-box-closed.png',
    gambarBuka: 'gacha/classic-box-open.png',
    aksen: '#58D878',
    rarity,
    odds: { common: 61.5, uncommon: 19.0, rare: 10.0, epic: 4.1, legendary: 0.8 },
    pool: isiClassic,
    menang: isiClassic[5],
  },
}

const isiPremium: DataBox['pool'] = [
  { jenis: 'item', nama: 'bandage', label: 'Bandage', jumlah: 5, rarity: 'uncommon', weight: 2400, gambar: 'bandage.png' },
  { jenis: 'item', nama: 'lockpick', label: 'Lockpick', jumlah: 3, rarity: 'uncommon', weight: 2200, gambar: 'lockpick.png' },
  { jenis: 'item', nama: 'repairkit', label: 'Repair Kit', jumlah: 2, rarity: 'rare', weight: 1500, gambar: 'repairkit.png' },
  { jenis: 'item', nama: 'armor', label: 'Armor', jumlah: 2, rarity: 'epic', weight: 550, gambar: 'armor.png' },
  { jenis: 'vehicle', model: 'comet6', label: 'Pfister Comet S2', jumlah: 1, rarity: 'epic', weight: 260 },
  { jenis: 'vehicle', model: 'jester4', label: 'Dinka Jester RR', jumlah: 1, rarity: 'legendary', weight: 90 },
]

export const previewPremium: PayloadBuka = {
  id: 'preview_premium_001',
  box: {
    nama: 'premium_box',
    label: 'Premium Box',
    deskripsi: 'Premium Gatrons case with a stronger rare, epic, and legendary drop pool.',
    gambarTutup: 'gacha/premium-box-closed.png',
    gambarBuka: 'gacha/premium-box-open.png',
    aksen: '#F0BC45',
    rarity,
    odds: { uncommon: 54.5, rare: 22.5, epic: 12.5, legendary: 2.2 },
    pool: isiPremium,
    menang: isiPremium[5],
  },
}

export const previewShop = {
  namaPlayer: 'Jerry',
  citizenid: 'GTR72841',
  saldo: 2450,
  labelCoin: 'GATRONS COIN',
  maksimalJumlah: 10,
  produk: [
    {
      nama: 'classic_box',
      label: 'Classic Box',
      deskripsi: 'Standard case dengan drop pool utility dan vehicle langka.',
      harga: 250,
      gambar: 'gacha/classic-box-closed.png',
      aksen: '#58D878',
      dimiliki: 2,
    },
    {
      nama: 'premium_box',
      label: 'Premium Box',
      deskripsi: 'Case premium dengan peluang rare dan legendary lebih tinggi.',
      harga: 750,
      gambar: 'gacha/premium-box-closed.png',
      aksen: '#F0BC45',
      dimiliki: 1,
    },
  ],
}
