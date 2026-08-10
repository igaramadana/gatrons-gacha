let konteks: AudioContext | null = null
let noiseBuffer: AudioBuffer | null = null

const ambilKonteks = () => {
  konteks ??= new AudioContext()

  if (konteks.state === 'suspended') {
    void konteks.resume().catch(() => undefined)
  }

  return konteks
}

const ambilNoise = (ctx: AudioContext) => {
  if (noiseBuffer && noiseBuffer.sampleRate === ctx.sampleRate) return noiseBuffer

  const panjang = Math.floor(ctx.sampleRate * 0.06)
  const buffer = ctx.createBuffer(1, panjang, ctx.sampleRate)
  const data = buffer.getChannelData(0)

  for (let i = 0; i < panjang; i += 1) {
    data[i] = Math.random() * 2 - 1
  }

  noiseBuffer = buffer
  return buffer
}

const bikinGain = (ctx: AudioContext, volume: number, durasi: number) => {
  const gain = ctx.createGain()
  const mulai = ctx.currentTime

  gain.gain.setValueAtTime(Math.max(0.0001, volume), mulai)
  gain.gain.exponentialRampToValueAtTime(0.0001, mulai + durasi)

  return gain
}

/**
 * Klik mekanikal pendek buat tiap kartu yang lewat marker.
 * Tetap pakai WebAudio biar resource gak perlu file audio eksternal.
 */
export const bunyiTik = (nada = 560, durasi = 0.035, volume = 0.032) => {
  try {
    const ctx = ambilKonteks()
    const mulai = ctx.currentTime

    const badan = ctx.createOscillator()
    const badanGain = bikinGain(ctx, volume, durasi)
    badan.type = 'triangle'
    badan.frequency.setValueAtTime(nada, mulai)
    badan.frequency.exponentialRampToValueAtTime(Math.max(120, nada * 0.62), mulai + durasi)
    badan.connect(badanGain)
    badanGain.connect(ctx.destination)

    const klik = ctx.createBufferSource()
    const klikFilter = ctx.createBiquadFilter()
    const klikGain = bikinGain(ctx, volume * 0.7, Math.min(0.018, durasi))
    klik.buffer = ambilNoise(ctx)
    klikFilter.type = 'highpass'
    klikFilter.frequency.value = 1800
    klikFilter.Q.value = 0.8
    klik.connect(klikFilter)
    klikFilter.connect(klikGain)
    klikGain.connect(ctx.destination)

    badan.start(mulai)
    badan.stop(mulai + durasi + 0.01)
    klik.start(mulai)
    klik.stop(mulai + Math.min(0.025, durasi))
  } catch {
    // Audio bukan bagian kritis. CEF/browser boleh memblokir autoplay.
  }
}

const bunyiNadaMenang = (ctx: AudioContext, nada: number, mulaiDalam: number, volume: number) => {
  const mulai = ctx.currentTime + mulaiDalam
  const durasi = 0.38
  const osc = ctx.createOscillator()
  const gain = ctx.createGain()

  osc.type = 'sine'
  osc.frequency.setValueAtTime(nada, mulai)
  gain.gain.setValueAtTime(0.0001, mulai)
  gain.gain.exponentialRampToValueAtTime(volume, mulai + 0.018)
  gain.gain.exponentialRampToValueAtTime(0.0001, mulai + durasi)

  osc.connect(gain)
  gain.connect(ctx.destination)
  osc.start(mulai)
  osc.stop(mulai + durasi + 0.02)
}

export const bunyiMenang = () => {
  try {
    const ctx = ambilKonteks()
    const mulai = ctx.currentTime

    // Impact rendah ketika reel benar-benar berhenti.
    const gebuk = ctx.createOscillator()
    const gebukGain = ctx.createGain()
    gebuk.type = 'sine'
    gebuk.frequency.setValueAtTime(128, mulai)
    gebuk.frequency.exponentialRampToValueAtTime(62, mulai + 0.16)
    gebukGain.gain.setValueAtTime(0.06, mulai)
    gebukGain.gain.exponentialRampToValueAtTime(0.0001, mulai + 0.2)
    gebuk.connect(gebukGain)
    gebukGain.connect(ctx.destination)
    gebuk.start(mulai)
    gebuk.stop(mulai + 0.22)

    // Chime pendek, lebih berisi daripada square-beep lama.
    bunyiNadaMenang(ctx, 523.25, 0.035, 0.035)
    bunyiNadaMenang(ctx, 659.25, 0.11, 0.032)
    bunyiNadaMenang(ctx, 783.99, 0.19, 0.03)
  } catch {
    // Boleh gagal diam-diam kalau browser/CEF menahan AudioContext.
  }
}
