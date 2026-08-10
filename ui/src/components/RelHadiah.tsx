import { useLayoutEffect, useMemo, useRef, useState } from 'react'
import { motion } from 'motion/react'
import type { DataBox, Hadiah } from '../types/gacha'
import { bunyiMenang, bunyiTik } from '../lib/suara'
import { KartuHadiah } from './KartuHadiah'

const LEBAR_KARTU = 158
const GAP = 3
const TARGET = 36
const TOTAL = 48
const DURASI_ROLL = 10.8
const DELAY_ROLL = 0.18
const DELAY_HASIL = 1000

// Satu kurva continuous dari awal sampai akhir.
// Awal langsung kenceng, lalu velocity turun terus secara halus sampai 0.
// Jangan pecah jadi beberapa keyframe karena sambungan keyframe bikin reel terasa snap/loncat.
const KURVA_NGEREM = [0.14, 0.75, 0.2, 1] as const

type Props = {
  box: DataBox
  pasSelesai: () => void
}

const hadiahSama = (a: Hadiah, b: Hadiah) =>
  a.jenis === b.jenis && (a.nama ?? a.model) === (b.nama ?? b.model)

const ngacakVisual = (pool: Hadiah[], menang: Hadiah) => {
  const aman = pool.length > 0 ? pool : [menang]
  const bukanMenang = aman.filter((hadiah) => !hadiahSama(hadiah, menang))
  const kandidatSekitar = bukanMenang.length > 0 ? bukanMenang : aman

  const daftar = Array.from(
    { length: TOTAL },
    () => aman[Math.floor(Math.random() * aman.length)] ?? menang,
  )

  // Biar pas berhenti reward pemenang kebaca jelas dan nggak ketuker
  // sama card kembar persis di kiri/kanannya.
  for (let offset = -2; offset <= 2; offset += 1) {
    if (offset === 0) continue

    const index = TARGET + offset
    daftar[index] =
      kandidatSekitar[Math.floor(Math.random() * kandidatSekitar.length)] ?? menang
  }

  daftar[TARGET] = menang
  return daftar
}

export function RelHadiah({ box, pasSelesai }: Props) {
  const areaRef = useRef<HTMLDivElement>(null)
  const timerHasilRef = useRef<number | null>(null)
  const indeksTikTerakhir = useRef<number | null>(null)
  const udahNembakHasilRef = useRef(false)

  const [geserAkhir, setGeserAkhir] = useState<number | null>(null)
  const [udahBerhenti, setUdahBerhenti] = useState(false)

  // Pool visual dibikin sekali untuk opening ini. Jangan diacak ulang sepanjang roll.
  const daftar = useMemo(() => box.menang ? ngacakVisual(box.pool, box.menang) : [], [box])

  useLayoutEffect(() => {
    const hitungPosisi = () => {
      const lebarArea = areaRef.current?.clientWidth ?? 1050
      const jarakSatuKartu = LEBAR_KARTU + GAP
      const titikTengahPemenang = TARGET * jarakSatuKartu + LEBAR_KARTU / 2

      // Pemenang berhenti PERSIS di tengah marker.
      setGeserAkhir(lebarArea / 2 - titikTengahPemenang)
    }

    indeksTikTerakhir.current = null
    udahNembakHasilRef.current = false
    setUdahBerhenti(false)
    hitungPosisi()

    window.addEventListener('resize', hitungPosisi)

    return () => {
      window.removeEventListener('resize', hitungPosisi)

      if (timerHasilRef.current !== null) {
        window.clearTimeout(timerHasilRef.current)
      }
    }
  }, [box])

  const pasGerak = (terbaru: Record<string, string | number>) => {
    if (!areaRef.current || geserAkhir === null || udahBerhenti) return

    const xMentah = terbaru.x
    const x =
      typeof xMentah === 'number' ? xMentah : Number.parseFloat(String(xMentah))

    if (!Number.isFinite(x)) return

    const jarakSatuKartu = LEBAR_KARTU + GAP
    const tengahArea = areaRef.current.clientWidth / 2
    const indeksDiMarker = Math.max(
      0,
      Math.floor((tengahArea - x) / jarakSatuKartu),
    )

    if (indeksTikTerakhir.current === null) {
      indeksTikTerakhir.current = indeksDiMarker
      return
    }

    if (indeksDiMarker === indeksTikTerakhir.current) return

    indeksTikTerakhir.current = indeksDiMarker
    bunyiTik(520, 0.028, 0.025)
  }

  const pasRollBeneranBerhenti = () => {
    if (geserAkhir === null || udahNembakHasilRef.current) return

    udahNembakHasilRef.current = true

    // Callback ini baru jalan setelah satu tween continuous selesai total,
    // jadi transform sudah benar-benar diam di posisi hadiah pemenang.
    setUdahBerhenti(true)
    bunyiMenang()

    window.requestAnimationFrame(() => {
      timerHasilRef.current = window.setTimeout(() => {
        pasSelesai()
      }, DELAY_HASIL)
    })
  }

  return (
    <div
      ref={areaRef}
      className="relative h-[194px] w-full overflow-hidden border-y border-white/[0.08] bg-black/30 py-5"
    >
      <div className="pointer-events-none absolute inset-y-0 left-0 z-20 w-[17%] bg-gradient-to-r from-[#181921] via-[#181921]/70 to-transparent" />
      <div className="pointer-events-none absolute inset-y-0 right-0 z-20 w-[17%] bg-gradient-to-l from-[#181921] via-[#181921]/70 to-transparent" />

      <div
        className="pointer-events-none absolute left-1/2 top-0 z-30 h-full w-px -translate-x-1/2 bg-white/80"
        style={{
          boxShadow: udahBerhenti
            ? `0 0 22px ${box.aksen}`
            : '0 0 12px rgba(255,255,255,0.45)',
        }}
      />
      <div
        className="pointer-events-none absolute left-1/2 top-0 z-30 -translate-x-1/2 border-x-[10px] border-t-[13px] border-x-transparent"
        style={{ borderTopColor: box.aksen }}
      />
      <div
        className="pointer-events-none absolute bottom-0 left-1/2 z-30 -translate-x-1/2 border-x-[10px] border-b-[13px] border-x-transparent"
        style={{ borderBottomColor: box.aksen }}
      />

      {geserAkhir !== null && box.menang && (
        <motion.div
          className="flex gap-[3px] will-change-transform"
          style={{ backfaceVisibility: 'hidden' }}
          initial={{ x: 0 }}
          animate={{ x: geserAkhir }}
          transition={{
            duration: DURASI_ROLL,
            delay: DELAY_ROLL,
            ease: KURVA_NGEREM,
          }}
          onUpdate={pasGerak}
          onAnimationComplete={pasRollBeneranBerhenti}
        >
          {daftar.map((hadiah, index) => (
            <KartuHadiah
              key={`${hadiah.jenis}-${hadiah.nama ?? hadiah.model}-${index}`}
              hadiah={hadiah}
              info={box.rarity[hadiah.rarity]}
              aktif={udahBerhenti && index === TARGET}
            />
          ))}
        </motion.div>
      )}
    </div>
  )
}
