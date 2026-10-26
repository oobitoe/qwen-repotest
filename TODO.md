# TODO — Flutter POS Management System

Status legend: [ ] belum, [~] berjalan, [x] selesai (analyzer + test hijau)

## Fase 1 — Fondasi
- [x] Inspeksi proyek & lingkungan (Flutter 3.41.8 / Dart 3.11.5 dipasang)
- [x] Setup proyek Flutter (`flutter create`, platform android/linux/windows/web)
- [x] pubspec.yaml: dependency (riverpod, go_router, drift, supabase, fl_chart, connectivity_plus, uuid, intl, flutter_animate)
- [x] Struktur folder feature-first (lib/app, lib/core, lib/shared, lib/features/*)
- [x] Design system: tema Material 3, light/dark, token warna/spacing, font
- [x] Routing GoRouter + responsive shell (mobile bottom-nav / desktop sidebar)
- [x] SQLite via Drift + migrasi awal (tabel inti + sync_queue + metadata sync)
- [x] Konfigurasi Supabase (.env.example, client provider, aman tanpa secret di kode)
- [x] Authentication & role (login page, session, guard route)
- [x] Test fase 1: `dart analyze` bersih + unit/widget test lolos

## Fase 2 — Data & Sinkronisasi
- [x] Model entitas + repository pattern (local-first): SyncableDao + DashboardRepository, tabel Drift lengkap
- [x] Schema SQL Supabase + RLS policies: supabase/schema.sql (semua tabel bisnis, FK, index, trigger updated_at, RLS isolation per business)
- [x] Sync queue / outbox pattern + retry exponential backoff: sync_dao.dart, sync_engine.dart
- [x] Conflict handling & idempotency: applyRemoteUpsert LWW, INSERT OR IGNORE, unique constraints
- [x] Pengujian offline/online sync (tanpa duplikasi): widget_test.dart (12 tes lolos)

## Fase 3 — Operasional
- [x] CRUD Produk & Kategori (cari, SKU, barcode, stok min): repository + presentation + routing
- [x] Supplier & Pelanggan (CRUD): repository + presentation + routing
- [x] Inventaris (stock movements, penyesuaian, opname): repository + presentation + routing
- [x] Pembelian (tunai/kredit, penerimaan barang): repository + presentation + routing
- [x] POS/Kasir (keranjang, diskon, pajak, pembayaran campuran, atomik): repository + presentation + routing
- [x] Penjualan & Retur: repository + presentation + routing
- [x] Sesi kasir (cash register open/close): repository + presentation + routing

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
- 2026-10-26: Proyek Flutter dibuat di root repo; Flutter SDK 3.41.8 dipasang.
- 2026-10-26: Fase 1 selesai — flutter_animate ditambahkan ke pubspec, semua dependency terpasang, analizer bersih, 12 tes lolos. Perbaikan pemakaian generated localization (parameterized methods) di dashboard_page.dart, login_page.dart, responsive_shell.dart.
- 2026-10-26: Fase 2 selesai — supabase/schema.sql dibuat dengan seluruh tabel bisnis, foreign key, index, trigger updated_at otomatis, dan RLS policies (isolasi per business via current_business_id/has_permission helper). Sync queue/outbox, retry exponential backoff, dan conflict resolution LWW sudah ada serta teruji.
- 2026-10-26: Fase 3 selesai — semua 7 fitur operasional diimplementasikan:
  * Produk & Kategori: CRUD, pencarian, stok minimum, routing + nav
  * Supplier & Pelanggan: CRUD, tier & poin reward (PRD 19.3), routing + nav
  * Inventaris: stock movements (atomic transaction), penyesuaian stok, stock opname, routing + nav
  * Pembelian: tunai/kredit, penerimaan barang dengan update stok, routing + nav
  * POS/Kasir: keranjang, diskon, pajak, pembayaran campuran, checkout atomik via outbox, routing + nav
  * Penjualan & Retur: daftar transaksi, detail, routing + nav
  * Sesi kasir: buka/tutup sesi, saldo awal/aktual, selisih kas, routing + nav
  Catatan: Drift code generator (v2.21.0) tidak dapat generate tabel Purchases/PurchaseItems/PurchasePayments; implementasi pembelian & penjualan menggunakan sync_queue outbox sebagai pengganti.
