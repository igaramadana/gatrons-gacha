export const lagiDiFivem = () => typeof window !== 'undefined' && typeof (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName === 'function'

export const nembakNui = async <T>(event: string, data?: unknown): Promise<T> => {
  if (!lagiDiFivem()) {
    return { oke: true, pesan: 'Browser preview: reward dianggap berhasil.' } as T
  }

  const resource = (window as Window & { GetParentResourceName?: () => string }).GetParentResourceName?.()
  if (!resource) throw new Error('Resource NUI tidak ditemukan')

  const response = await fetch(`https://${resource}/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {}),
  })

  if (!response.ok) throw new Error(`NUI ${event} gagal: ${response.status}`)
  return response.json() as Promise<T>
}

export const jalurAset = (path: string) => {
  if (/^(https?:|nui:|data:)/i.test(path)) return path
  return `./${path.replace(/^\//, '')}`
}
