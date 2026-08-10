import { useEffect, useMemo, useState } from "react";
import { motion } from "motion/react";
import {
  FiBox,
  FiChevronLeft,
  FiChevronRight,
  FiShoppingBag,
  FiX,
} from "react-icons/fi";
import { jalurAset } from "../lib/nui";
import type { DataShop } from "../types/gacha";

type Props = {
  shop: DataShop;
  lagiBeli: boolean;
  pasBeli: (namaBox: string, jumlah: number) => void;
  pasTutup: () => void;
};

const formatAngka = (nilai: number) =>
  new Intl.NumberFormat("id-ID").format(Math.max(0, Math.floor(nilai)));
const GAMBAR_COIN = "/images/gatrons-coin.png";
const AKSEN = "#88E52B";
const BENTUK_OKTAGON =
  "polygon(12px 0, calc(100% - 12px) 0, 100% 12px, 100% calc(100% - 12px), calc(100% - 12px) 100%, 12px 100%, 0 calc(100% - 12px), 0 12px)";
const BENTUK_OKTAGON_KECIL =
  "polygon(7px 0, calc(100% - 7px) 0, 100% 7px, 100% calc(100% - 7px), calc(100% - 7px) 100%, 7px 100%, 0 calc(100% - 7px), 0 7px)";
const BENTUK_OKTAGON_DALAM =
  "polygon(11px 0, calc(100% - 11px) 0, 100% 11px, 100% calc(100% - 11px), calc(100% - 11px) 100%, 11px 100%, 0 calc(100% - 11px), 0 11px)";
const BENTUK_OKTAGON_KECIL_DALAM =
  "polygon(6px 0, calc(100% - 6px) 0, 100% 6px, 100% calc(100% - 6px), calc(100% - 6px) 100%, 6px 100%, 0 calc(100% - 6px), 0 6px)";

export function LayarShop({ shop, lagiBeli, pasBeli, pasTutup }: Props) {
  const [pilihan, setPilihan] = useState(shop.produk[0]?.nama ?? "");
  const [jumlah, setJumlah] = useState(1);

  const produk = useMemo(
    () => shop.produk.find((item) => item.nama === pilihan) ?? shop.produk[0],
    [pilihan, shop.produk],
  );

  useEffect(() => {
    if (!produk && shop.produk[0]) setPilihan(shop.produk[0].nama);
  }, [produk, shop.produk]);

  useEffect(() => {
    setJumlah((lama) => Math.min(Math.max(1, lama), shop.maksimalJumlah));
  }, [shop.maksimalJumlah]);

  if (!produk) return null;

  const total = produk.harga * jumlah;
  const coinCukup = shop.saldo >= total;
  const bisaBeli = !lagiBeli && coinCukup && total > 0;

  const geserJumlah = (arah: -1 | 1) => {
    setJumlah((lama) =>
      Math.min(shop.maksimalJumlah, Math.max(1, lama + arah)),
    );
  };

  return (
    <div className="pointer-events-none fixed inset-0 z-[70] overflow-hidden bg-transparent">
      <div className="flex h-full items-center justify-end px-[5vw] py-8">
        <div
          className="pointer-events-none"
          style={{ perspective: "850px", perspectiveOrigin: "100% 50%" }}
        >
          <motion.section
            initial={{ x: 120, rotateY: -24, scale: 0.97, opacity: 0 }}
            animate={{ x: 0, rotateY: -11, scale: 1, opacity: 1 }}
            exit={{ x: 120, rotateY: -24, scale: 0.97, opacity: 0 }}
            transition={{ duration: 0.68, ease: [0.2, 0.8, 0.2, 1] }}
            style={{
              transformOrigin: "100% 50%",
              transformStyle: "preserve-3d",
              backfaceVisibility: "hidden",
              clipPath: BENTUK_OKTAGON,
              background: "rgba(136,229,43,.28)",
              padding: "1px",
              boxShadow:
                "0 24px 80px rgba(0,0,0,.5), 0 0 32px rgba(136,229,43,.06)",
            }}
            className="pointer-events-auto h-fit w-[min(92vw,27rem)] overflow-visible"
          >
            <div
              className="flex h-fit flex-col gap-4 overflow-visible bg-[rgba(7,10,8,.96)] p-6"
              style={{ clipPath: BENTUK_OKTAGON_DALAM }}
            >
              <div className="flex items-center justify-between gap-4">
                <div>
                  <p className="text-[11px] font-bold uppercase tracking-[0.09em] text-[#88E52B]/70">
                    Gatrons Development
                  </p>
                  <h2 className="mt-1 text-[17px] font-bold uppercase tracking-[0.04em] text-white">
                    Case Shop
                  </h2>
                </div>
                <button
                  type="button"
                  onClick={pasTutup}
                  disabled={lagiBeli}
                  className="grid size-9 place-items-center rounded-[4px] border border-[#88E52B]/20 bg-[#88E52B]/[0.035] text-white/45 transition hover:border-[#88E52B]/60 hover:bg-[#88E52B]/10 hover:text-[#88E52B] disabled:cursor-not-allowed disabled:opacity-30"
                  aria-label="Tutup shop"
                >
                  <FiX />
                </button>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div
                  className="bg-white/10 p-px"
                  style={{ clipPath: BENTUK_OKTAGON_KECIL }}
                >
                  <div
                    className="h-full bg-[rgba(11,14,12,.98)] p-3.5"
                    style={{ clipPath: BENTUK_OKTAGON_KECIL_DALAM }}
                  >
                    <span className="block text-[9px] font-bold uppercase tracking-[0.06em] text-white/35">
                      Welcome
                    </span>
                    <strong className="mt-1 block truncate text-[13px] font-normal text-white">
                      {shop.namaPlayer}
                    </strong>
                    <span className="mt-1 block truncate text-[8px] uppercase tracking-[0.06em] text-white/25">
                      {shop.citizenid}
                    </span>
                  </div>
                </div>
                <div
                  className="bg-[#88E52B]/35 p-px"
                  style={{ clipPath: BENTUK_OKTAGON_KECIL }}
                >
                  <div
                    className="h-full bg-[rgba(16,22,12,.98)] p-3.5"
                    style={{ clipPath: BENTUK_OKTAGON_KECIL_DALAM }}
                  >
                    <span className="block text-[9px] font-bold uppercase tracking-[0.06em] text-[#88E52B]">
                      {shop.labelCoin}
                    </span>
                    <div className="mt-1 flex items-center gap-2">
                      <img
                        src={jalurAset(GAMBAR_COIN)}
                        alt="Gatrons Coin"
                        className="size-7 shrink-0 object-contain"
                        draggable={false}
                      />
                      <strong className="block text-[18px] font-normal text-white">
                        {formatAngka(shop.saldo)}
                      </strong>
                    </div>
                    <span className="mt-1 block text-[8px] uppercase tracking-[0.06em] text-white/25">
                      Available balance
                    </span>
                  </div>
                </div>
              </div>

              <div>
                <div className="mb-2 flex items-center justify-between">
                  <span className="text-[9px] font-bold uppercase tracking-[0.08em] text-white/40">
                    Pilih Box
                  </span>
                  <span className="text-[8px] uppercase tracking-[0.06em] text-[#88E52B]/45">
                    {shop.produk.length} Products
                  </span>
                </div>

                <div
                  className="bg-white/10 p-px"
                  style={{ clipPath: BENTUK_OKTAGON_KECIL }}
                >
                  <div
                    className="flex flex-col gap-2 bg-black/20 p-2"
                    style={{ clipPath: BENTUK_OKTAGON_KECIL_DALAM }}
                  >
                    {shop.produk.map((item) => {
                      const aktif = item.nama === produk.nama;
                      return (
                        <div
                          key={item.nama}
                          className="p-px"
                          style={{
                            clipPath: BENTUK_OKTAGON_KECIL,
                            background: aktif ? AKSEN : "rgba(255,255,255,.09)",
                          }}
                        >
                          <button
                            type="button"
                            onClick={() => setPilihan(item.nama)}
                            className="flex min-h-[4.4rem] w-full items-center gap-3 p-2.5 text-left transition"
                            style={{
                              background: aktif
                                ? "rgba(16,24,10,.98)"
                                : "rgba(8,10,7,.98)",
                              clipPath: BENTUK_OKTAGON_KECIL_DALAM,
                            }}
                          >
                            <div
                              className="grid size-14 shrink-0 place-items-center overflow-hidden bg-black/30"
                              style={{ clipPath: BENTUK_OKTAGON_KECIL_DALAM }}
                            >
                              <img
                                src={jalurAset(item.gambar)}
                                alt={item.label}
                                className="h-[92%] w-[92%] object-contain"
                                draggable={false}
                              />
                            </div>

                            <div className="min-w-0 flex-1">
                              <span className="block truncate text-[11px] font-bold uppercase tracking-[0.03em] text-white">
                                {item.label}
                              </span>
                              <span className="mt-1 block line-clamp-2 text-[8px] leading-3 text-white/35">
                                {item.deskripsi}
                              </span>
                              <span className="mt-1.5 block text-[8px] uppercase tracking-[0.05em] text-white/30">
                                Owned {item.dimiliki}
                              </span>
                            </div>

                            <div className="shrink-0 text-right">
                              <div className="flex items-center justify-end gap-1.5">
                                <img
                                  src={jalurAset(GAMBAR_COIN)}
                                  alt=""
                                  className="size-[18px] object-contain"
                                  draggable={false}
                                />
                                <strong className="block text-[12px] font-normal text-white">
                                  {formatAngka(item.harga)}
                                </strong>
                              </div>
                              <span className="text-[7px] font-bold uppercase tracking-[0.06em] text-white/30">
                                Gatrons Coin
                              </span>
                            </div>
                          </button>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>

              <div className="flex flex-col gap-2">
                <span className="text-[9px] font-bold uppercase tracking-[0.08em] text-white/35">
                  Quantity
                </span>
                <div
                  className="bg-[#88E52B]/15 p-px"
                  style={{ clipPath: BENTUK_OKTAGON_KECIL }}
                >
                  <div
                    className="flex min-h-12 items-center bg-black/40"
                    style={{ clipPath: BENTUK_OKTAGON_KECIL_DALAM }}
                  >
                    <button
                      type="button"
                      onClick={() => geserJumlah(-1)}
                      disabled={jumlah <= 1 || lagiBeli}
                      className="grid h-12 w-12 place-items-center border-r border-white/10 text-white/45 transition hover:bg-[#88E52B]/[0.07] hover:text-[#88E52B] disabled:opacity-20"
                    >
                      <FiChevronLeft />
                    </button>
                    <div className="flex min-w-0 flex-1 items-center justify-center gap-2">
                      <FiBox className="text-white/30" />
                      <strong className="text-[15px] font-normal">
                        {jumlah}
                      </strong>
                      <span className="text-[8px] uppercase tracking-[0.06em] text-white/30">
                        / {shop.maksimalJumlah}
                      </span>
                    </div>
                    <button
                      type="button"
                      onClick={() => geserJumlah(1)}
                      disabled={jumlah >= shop.maksimalJumlah || lagiBeli}
                      className="grid h-12 w-12 place-items-center border-l border-white/10 text-white/45 transition hover:bg-[#88E52B]/[0.07] hover:text-[#88E52B] disabled:opacity-20"
                    >
                      <FiChevronRight />
                    </button>
                  </div>
                </div>
              </div>

              <div className="flex items-end justify-between gap-4 border-t border-[#88E52B]/15 pt-4">
                <div>
                  <span className="block text-[8px] font-bold uppercase tracking-[0.08em] text-white/30">
                    Total Payment
                  </span>
                  <div className="mt-1 flex items-center gap-2">
                    <img
                      src={jalurAset(GAMBAR_COIN)}
                      alt=""
                      className="size-6 object-contain"
                      draggable={false}
                    />
                    <strong className="block text-[19px] font-normal text-white">
                      {formatAngka(total)}
                    </strong>
                    <span className="text-[9px] text-white/35">COIN</span>
                  </div>
                </div>
                <span
                  className={`text-[8px] uppercase tracking-[0.06em] ${coinCukup ? "text-[#88E52B]" : "text-[#fd7272]"}`}
                >
                  {coinCukup ? "Balance ready" : "Coin kurang"}
                </span>
              </div>

              <div
                className={bisaBeli ? "bg-[#88E52B] p-px" : "bg-white/10 p-px"}
                style={{ clipPath: BENTUK_OKTAGON_KECIL }}
              >
                <button
                  type="button"
                  disabled={!bisaBeli}
                  onClick={() => pasBeli(produk.nama, jumlah)}
                  className="flex min-h-12 w-full items-center justify-center gap-2 bg-[#88E52B] px-4 text-[10px] font-bold uppercase tracking-[0.08em] text-[#0A0D08] transition hover:brightness-110 disabled:cursor-not-allowed disabled:bg-[rgba(12,14,12,.98)] disabled:text-white/25"
                  style={{ clipPath: BENTUK_OKTAGON_KECIL_DALAM }}
                >
                  <FiShoppingBag />
                  {lagiBeli ? "Processing..." : `Buy ${produk.label}`}
                </button>
              </div>
            </div>
          </motion.section>
        </div>
      </div>
    </div>
  );
}
