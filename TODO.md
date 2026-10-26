# TODO — Flutter POS Management System

Status legend: [ ] belum, [~] berjalan, [x] selesai (analyzer + test hijau)

## Fase 1 — Fondasi
- [x] Inspeksi proyek & lingkungan (Flutter 3.24.5 / Dart 3.5.4 dipasang)
- [x] Setup proyek Flutter (`flutter create`, platform android/linux/windows/web)
- [ ] pubspec.yaml: dependency (riverpod, go_router, drift, supabase, fl_chart, connectivity_plus, uuid, intl, flutter_animate)
- [ ] Struktur folder feature-first (lib/app, lib/core, lib/shared, lib/features/*)
- [ ] Design system: tema Material 3, light/dark, token warna/spacing, font
- [ ] Routing GoRouter + responsive shell (mobile bottom-nav / desktop sidebar)
- [ ] SQLite via Drift + migrasi awal (tabel inti + sync_queue + metadata sync)
- [ ] Konfigurasi Supabase (.env.example, client provider, aman tanpa secret di kode)
- [ ] Authentication & role (login page, session, guard route)
- [ ] Test fase 1: `dart analyze` bersih + unit/widget test lolos

## Fase 2 — Data & Sinkronisasi
- [ ] Model entitas + repository pattern (local-first)
- [ ] Schema SQL Supabase + RLS policies
- [ ] Sync queue / outbox pattern + retry exponential backoff
- [ ] Conflict handling & idempotency
- [ ] Pengujian offline/online sync (tanpa duplikasi)

## Fase 3 — Operasional
- [ ] CRUD Produk & Kategori (cari, SKU, barcode, stok min)
- [ ] Supplier & Pelanggan
- [ ] Inventaris: stock movements, penyesuaian, opname
- [ ] Pembelian (tunai/kredit, penerimaan barang)
- [ ] POS/Kasir: keranjang, diskon, pajak, pembayaran campuran, atomik
- [ ] Penjualan & Retur
- [ ] Sesi kasir (cash register open/close)

## Fase 4 — Keuangan
- [ ] Pengeluaran & Pemasukan (+ kategori)
- [ ] Hutang supplier & Piutang pelanggan + pelunasan
- [ ] Rekening & mutasi kas
- [ ] Dashboard dengan data nyata (kartu statistik + grafik)
- [ ] Laporan keuangan + ekspor CSV/PDF

## Fase 5 — Penyempurnaan
- [ ] Animasi halus & reduced motion
- [ ] Responsive refinement (mobile/tablet/desktop)
- [ ] Dark mode polish, loading skeleton, empty/error states
- [ ] Audit keamanan (permission granular, audit log)
- [ ] Optimasi performa (pagination, indeks, agregasi)
- [ ] Suite pengujian lengkap + dokumentasi README

## Catatan Kemajuan
- 2026-10-26: Proyek Flutter dibuat di root repo; Flutter SDK 3.24.5 dipasang di /opt/flutter.
