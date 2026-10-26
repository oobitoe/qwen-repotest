# MASTER PROMPT — FLUTTER POS MANAGEMENT SYSTEM

## 1. Peran dan Tujuan

Kamu adalah Senior Flutter Engineer, Software Architect, UI/UX Designer, Database Engineer, dan QA Engineer yang bertanggung jawab membangun aplikasi Point of Sale (POS) modern, lengkap, profesional, dan siap dikembangkan menjadi aplikasi produksi.

Bangun aplikasi POS menggunakan Flutter dan Dart dengan fokus pada:

- Manajemen penjualan dan kasir.
- Manajemen produk, kategori, stok, dan inventaris.
- Manajemen pembelian barang dan supplier.
- Manajemen pelanggan.
- Manajemen pengeluaran dan pemasukan.
- Laporan keuangan dan analisis bisnis.
- Dashboard interaktif dengan statistik real-time.
- Sistem offline-first dengan SQLite.
- Sinkronisasi otomatis ke Supabase ketika jaringan tersedia.
- UI/UX modern, responsif, animatif, dan konsisten.
- Arsitektur kode modular, aman, mudah dipelihara, dan scalable.

**Aturan utama:** Jangan hanya membuat mockup, prototype, atau halaman statis. Implementasikan fitur, database, validasi, navigasi, state management, transaksi, sinkronisasi, dan pengujian secara nyata.

Periksa proyek yang sudah ada sebelum melakukan perubahan. Jika proyek masih kosong, buat struktur aplikasi dari awal. Pertahankan kode yang masih berguna dan hindari menimpa konfigurasi penting tanpa alasan.

## 2. Teknologi Utama

Gunakan teknologi berikut:

- **Frontend:** Flutter stable dan Dart stable.
- **Online database:** Supabase PostgreSQL.
- **Authentication:** Supabase Auth.
- **Offline database:** SQLite menggunakan `drift` atau `sqflite`; prioritaskan Drift jika cocok dengan kebutuhan proyek.
- **State management:** Riverpod.
- **Routing:** GoRouter.
- **Dependency injection:** Riverpod providers atau pendekatan terstruktur yang setara.
- **Charts:** `fl_chart`.
- **Icons:** Material Symbols atau Material Icons.
- **Localization (i18n):** Bahasa Indonesia dan Inggris menggunakan `flutter_localizations` (SDK Flutter), `intl`, dan file ARB di `lib/l10n/`. Konfigurasi di `l10n.yaml`.
- **Animations:** Flutter implicit animations, `AnimationController`, `TweenAnimationBuilder`, dan `flutter_animate` jika diperlukan.
- **Networking:** Supabase Flutter SDK.
- **Connectivity:** `connectivity_plus`, disertai pemeriksaan koneksi nyata sebelum melakukan sinkronisasi.
- **Data models:** Model Dart yang memiliki serialisasi JSON, validasi, dan dukungan `copyWith`.
- **Code generation:** Gunakan generator yang sesuai untuk Drift, model, dan dependency terkait.
- **Testing:** Flutter unit tests, widget tests, dan integration tests.

Pilih versi package yang kompatibel dengan Flutter SDK pada lingkungan proyek. Jangan menggunakan API package yang sudah deprecated tanpa alasan.

## 3. Arsitektur Aplikasi

Gunakan arsitektur feature-first dengan pemisahan tanggung jawab yang jelas.

Contoh struktur direktori:

```text
lib/
├── main.dart
├── bootstrap.dart
├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme/
│   └── responsive/
├── core/
│   ├── constants/
│   ├── database/
│   │   ├── local/
│   │   └── migrations/
│   ├── network/
│   ├── sync/
│   ├── errors/
│   ├── utils/
│   ├── formatters/
│   └── widgets/
├── shared/
│   ├── models/
│   ├── providers/
│   └── widgets/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── pos/
│   ├── products/
│   ├── categories/
│   ├── inventory/
│   ├── suppliers/
│   ├── customers/
│   ├── purchases/
│   ├── sales/
│   ├── returns/
│   ├── expenses/
│   ├── income/
│   ├── finance/
│   ├── debts/
│   ├── reports/
│   ├── cash_management/
│   ├── users/
│   └── settings/
└── l10n/
```

Setiap feature sebaiknya memiliki struktur seperti:

```text
products/
├── data/
│   ├── datasources/
│   ├── repositories/
│   └── models/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    └── providers/
```

Pisahkan UI, business logic, local database, remote database, dan sync engine. Widget tidak boleh mengakses Supabase atau SQL secara langsung.

Gunakan repository pattern agar sumber data lokal dan online dapat diganti atau diuji secara independen.

## 4. Sistem Offline-First dan Sinkronisasi

Ini merupakan bagian paling penting dari aplikasi.

**SQLite adalah sumber data utama untuk operasi harian di perangkat.** Semua transaksi kasir dan perubahan data harus bisa berjalan tanpa internet.

Supabase menjadi database pusat untuk menyimpan data yang disinkronkan antarperangkat dan pengguna yang memiliki izin.

### Perilaku offline

- Aplikasi dapat dibuka tanpa internet setelah konfigurasi awal.
- Produk, kategori, harga, stok lokal, pelanggan, transaksi, dan laporan tersedia dari SQLite.
- Kasir bisa menyelesaikan penjualan tanpa internet.
- Perubahan data disimpan secara lokal terlebih dahulu.
- Setiap perubahan yang belum tersinkronisasi dimasukkan ke antrean sinkronisasi.
- UI langsung diperbarui setelah transaksi lokal berhasil.
- Jangan memblokir penjualan hanya karena server tidak tersedia.
- Jangan menganggap status jaringan dari `connectivity_plus` sebagai bukti bahwa Supabase dapat dijangkau.

### Sync engine

Implementasikan sync engine yang menangani:

1. Deteksi perubahan koneksi.
2. Pemeriksaan koneksi ke server Supabase.
3. Sinkronisasi otomatis saat aplikasi dibuka.
4. Sinkronisasi setelah koneksi kembali tersedia.
5. Sinkronisasi manual melalui tombol di UI.
6. Sinkronisasi berkala saat aplikasi aktif.
7. Upload perubahan lokal yang belum tersinkronisasi.
8. Download perubahan terbaru dari server.
9. Retry dengan exponential backoff.
10. Idempotency agar retry tidak menggandakan transaksi.
11. Penanganan konflik data.
12. Pencatatan error dan status sinkronisasi.
13. Pemulihan antrean setelah aplikasi ditutup atau crash.
14. Penanganan perubahan dan penghapusan data.
15. Pengurutan operasi berdasarkan dependensi data.

Buat tabel lokal seperti `sync_queue` dengan kolom minimal:

- `id`
- `entity_type`
- `entity_id`
- `operation`
- `payload`
- `created_at`
- `retry_count`
- `last_error`
- `status`

Tambahkan metadata sinkronisasi pada tabel yang relevan:

- `id`
- `created_at`
- `updated_at`
- `deleted_at`
- `version`
- `sync_status`

Gunakan UUID yang dibuat di perangkat sebagai ID entitas agar transaksi offline dapat langsung memperoleh identitas stabil.

Gunakan soft delete atau tombstone untuk memastikan penghapusan data ikut tersinkronisasi.

### Penanganan konflik

Tentukan strategi konflik per jenis data:

- Data konfigurasi sederhana: gunakan versioning dan kebijakan konflik yang jelas.
- Produk dan pelanggan: deteksi perubahan bersamaan, tampilkan konflik jika perlu.
- Transaksi penjualan dan pembelian: catatan transaksi yang sudah tercatat tidak boleh ditimpa sembarangan.
- Stok: gunakan stock movement atau ledger pergerakan stok, bukan sekadar menimpa nilai stok.
- Pembayaran dan pelunasan: gunakan transaksi finansial yang immutable dengan mekanisme koreksi.
- Jangan menggunakan `last-write-wins` secara membabi buta untuk transaksi keuangan.

Pastikan operasi sinkronisasi aman untuk dijalankan berkali-kali. Gunakan ID operasi unik dan unique constraints pada server.

Perhatikan bahwa background sync pada Android, iOS, dan desktop memiliki batasan berbeda. Implementasikan foreground sync yang andal, dan gunakan background task sesuai dukungan platform.

### Konsistensi transaksi

Simpan penjualan, item penjualan, pembayaran, pergerakan stok, dan perubahan saldo yang berkaitan dalam satu transaksi database lokal.

Jika salah satu langkah gagal, rollback seluruh transaksi lokal.

Pada server, gunakan PostgreSQL transactions dan database functions/RPC untuk operasi yang memerlukan atomicity. Jangan mengandalkan rangkaian request terpisah yang bisa berhenti di tengah proses.

## 5. Database dan Relasi

Buat migrasi SQL Supabase yang lengkap, constraint, index, foreign key, trigger, dan Row Level Security (RLS).

Gunakan UUID untuk primary key, timestamp yang konsisten dalam UTC, dan numeric/decimal untuk nilai uang.

Setiap data bisnis harus memiliki `business_id` atau `store_id` agar mendukung banyak toko pada masa depan. Jangan mencampur data antarbisnis.

Buat tabel minimal berikut.

### A. Organisasi dan pengguna

- `businesses`
- `stores`
- `profiles`
- `business_members`
- `roles`
- `permissions`
- `user_store_access`

Role awal:

- Owner
- Admin
- Manager
- Kasir
- Staff gudang

Implementasikan permission granular untuk melihat laporan, mengubah harga, mengelola stok, menghapus data, mengelola pengguna, dan melakukan refund.

Jangan menyimpan password sendiri. Gunakan Supabase Auth.

### B. Produk

- `categories`
- `products`
- `product_variants`
- `product_barcodes`
- `product_prices`
- `units`
- `product_images`

Fitur produk:

- SKU unik sesuai lingkup bisnis.
- Barcode.
- Nama dan deskripsi.
- Kategori.
- Satuan.
- Harga modal.
- Harga jual.
- Harga grosir jika diperlukan.
- Minimum stok.
- Stok saat ini sebagai nilai turunan atau cache yang konsisten.
- Status aktif/nonaktif.
- Varian produk.
- Produk dengan tanggal kedaluwarsa jika relevan.
- Pencarian cepat berdasarkan nama, SKU, dan barcode.
- Import dan export CSV.

### C. Inventaris

- `stock_movements`
- `stock_adjustments`
- `stock_adjustment_items`
- `stock_opnames`
- `stock_opname_items`
- `stock_transfers`
- `stock_transfer_items`

Jenis pergerakan stok minimal:

- Stok awal.
- Pembelian.
- Penjualan.
- Retur penjualan.
- Retur pembelian.
- Penyesuaian.
- Transfer masuk.
- Transfer keluar.
- Pembatalan atau koreksi transaksi.

Semua perubahan stok harus dapat ditelusuri. Jangan mengubah stok tanpa mencatat alasan dan sumber perubahannya.

### D. Supplier dan pelanggan

- `suppliers`
- `customers`
- `customer_addresses`

Simpan informasi kontak, alamat, catatan, kode pelanggan, dan histori transaksi.

### E. Pembelian

- `purchase_orders`
- `purchase_order_items`
- `purchases`
- `purchase_items`
- `purchase_payments`
- `purchase_returns`
- `purchase_return_items`

Fitur:

- Pencatatan pembelian.
- Penerimaan barang.
- Perhitungan modal.
- Diskon.
- Pajak jika diperlukan.
- Pembayaran tunai atau kredit.
- Hutang supplier.
- Pelunasan bertahap.
- Retur pembelian.
- Histori harga modal.

### F. Penjualan dan POS

- `sales`
- `sale_items`
- `sale_payments`
- `sale_returns`
- `sale_return_items`
- `sale_sequences`

Fitur:

- Keranjang belanja.
- Pencarian dan scan barcode.
- Banyak item per transaksi.
- Perubahan kuantitas.
- Diskon item dan transaksi.
- Pajak yang dapat dikonfigurasi.
- Pembulatan uang sesuai kebijakan bisnis.
- Tunai, transfer, QRIS, kartu, dan metode pembayaran lain.
- Pembayaran campuran.
- Kembalian.
- Transaksi ditahan dan dilanjutkan.
- Cetak atau ekspor struk.
- Riwayat transaksi.
- Pembatalan dengan izin.
- Retur penuh maupun sebagian.
- Refund dan koreksi transaksi.
- Transaksi tunai maupun kredit.

Gunakan nomor transaksi yang unik dan dapat dibaca manusia, tetapi jangan bergantung pada nomor urut server saat offline. Gunakan ID UUID dan identitas perangkat atau prefix lokal bila diperlukan. Finalisasi nomor struk harus tetap aman terhadap benturan antarperangkat.

Simpan snapshot nama produk, SKU, harga, diskon, pajak, dan kuantitas pada item transaksi agar histori tidak berubah ketika informasi produk diedit.

### G. Kas dan keuangan

- `cash_registers`
- `cash_sessions`
- `cash_movements`
- `expenses`
- `expense_categories`
- `income_entries`
- `income_categories`
- `accounts`
- `account_transactions`
- `debts`
- `debt_payments`
- `financial_adjustments`

Fitur:

- Buka dan tutup kasir.
- Saldo awal kas.
- Kas masuk dan keluar.
- Pengeluaran operasional.
- Pemasukan nonpenjualan.
- Transfer antar-akun.
- Hutang dan piutang.
- Pembayaran bertahap.
- Rekonsiliasi kas.
- Selisih kas.
- Histori pembayaran.
- Laporan arus kas.

Setiap perubahan saldo harus dapat ditelusuri ke transaksi sumbernya. Hindari menghitung saldo hanya dari field yang bisa diubah langsung tanpa ledger atau mekanisme rekonsiliasi.

### H. Konfigurasi dan sinkronisasi

- `business_settings`
- `store_settings`
- `payment_methods`
- `tax_settings`
- `devices`
- `audit_logs`
- `sync_metadata`

Konfigurasi minimal mencakup nama toko, logo, alamat, mata uang IDR, zona waktu, format tanggal, pajak, diskon, dan format struk.

Jangan mengirim data sensitif atau konfigurasi yang tidak diperlukan ke perangkat kasir.

## 6. Fitur Dashboard

Buat dashboard modern yang mengambil data nyata dari repository, bukan angka dummy.

Kartu statistik:

- Total penjualan hari ini.
- Total penjualan bulan ini.
- Omzet bersih.
- Estimasi laba kotor.
- Total transaksi.
- Rata-rata nilai transaksi.
- Total pengeluaran.
- Estimasi laba bersih.
- Piutang pelanggan.
- Hutang supplier.
- Nilai persediaan.
- Produk hampir habis.

Grafik:

- Penjualan 7 hari terakhir.
- Tren penjualan bulanan.
- Perbandingan omzet dan pengeluaran.
- Produk terlaris.
- Kategori dengan penjualan tertinggi.
- Metode pembayaran.
- Perbandingan periode sebelumnya.

Komponen tambahan:

- Transaksi terbaru.
- Produk terlaris.
- Stok menipis.
- Ringkasan kas.
- Aktivitas terbaru.
- Status online/offline.
- Status sinkronisasi dan jumlah antrean tertunda.

Sediakan filter tanggal, rentang periode, dan toko sesuai hak akses.

Hitung semua metrik dengan aturan yang konsisten. Omzet, retur, pajak, modal barang terjual, biaya operasional, dan laba bersih harus dibedakan dengan jelas. Jangan menyamakan total pembayaran dengan laba.

Dashboard harus tetap dapat digunakan secara offline menggunakan data lokal yang tersedia, dengan penanda waktu pembaruan data.

## 7. Tampilan UI/UX

Rancang aplikasi dengan gaya modern, elegan, premium, bersih, dan profesional, terinspirasi dari dashboard aplikasi SaaS modern.

### Prinsip desain

- Gunakan Material 3.
- Gunakan Material Icons atau Material Symbols secara konsisten.
- Buat design system dengan warna, tipografi, spacing, radius, elevation, dan komponen yang terstandarisasi.
- Gunakan font modern seperti Inter jika tersedia secara lokal.
- Gunakan whitespace yang cukup.
- Buat hierarki informasi yang jelas.
- Gunakan warna status untuk sukses, peringatan, error, dan informasi.
- Hindari terlalu banyak gradien, shadow berat, dan warna mencolok.
- Jangan menggunakan emoji sebagai pengganti ikon antarmuka.
- Buat dark mode dan light mode.
- Buat preset warna thema pakai OKLCH colors, bikin minimal 7 preset thema warna
- Buat satu file yang berisi seluruh warna yang dipakai dalam aplikasi agar memudahkan penggantian warna.
- Buat satu file untuk seluruh icon yang dipakai dalam aplikasi
- Bahasa aplikasi terdiri dari indonesia dan inggris.
- Format mata uang dalam Rupiah dengan formatter yang konsisten.

Jangan menyebarkan warna hardcoded di seluruh widget. Gunakan `ThemeData`, `ColorScheme`, dan token desain.
Jangan hardcoded icon langsung.

### Komponen visual

Buat reusable widgets untuk:

- Stat cards.
- Chart cards.
- Data tables.
- Search field.
- Filter bar.
- Date range picker.
- Status chips.
- Product cards.
- Product grid.
- Empty states.
- Error states.
- Loading skeleton.
- Confirmation dialog.
- Bottom sheet.
- Form fields.
- Pagination.
- Toast.
- Sync status indicator.
- Offline banner.

### Animasi

Gunakan animasi halus dan bermakna:

- Transisi halaman.
- Fade dan slide saat konten muncul.
- Animasi angka statistik.
- Perubahan state tombol.
- Animasi penambahan item ke keranjang.
- Transisi kartu dan dialog.
- Loading skeleton.
- Feedback sukses atau gagal.
- Animasi chart saat data dimuat.

Durasi umum sekitar 150–350 ms sesuai jenis animasi. Hindari animasi berlebihan yang memperlambat kasir. Hormati pengaturan reduced motion jika memungkinkan.

### Responsive design

Dukung:

- Android smartphone.
- Tablet Android.
- Windows desktop.
- Linux desktop.
- Web jika tidak bertentangan dengan kebutuhan keamanan dan akses perangkat.

Gunakan `LayoutBuilder`, `MediaQuery`, dan breakpoint yang konsisten.

Perilaku layout:

- Mobile: navigasi bawah atau drawer, daftar berbentuk kartu, form adaptif, dan POS satu kolom.
- Tablet: layout dua kolom, navigasi samping, dan grid produk.
- Desktop: sidebar yang dapat diciutkan, top bar, dashboard multi-kolom, tabel lengkap, dan POS dua panel dengan katalog di satu sisi serta keranjang di sisi lain.

Jangan sekadar memperbesar tampilan mobile pada desktop. Desain ulang komposisi sesuai ukuran layar.

## 8. Navigasi Utama

Buat navigasi yang terstruktur:

1. Dashboard
2. Kasir / POS
3. Penjualan
4. Pembelian
5. Produk
6. Kategori
7. Inventaris
8. Supplier
9. Pelanggan
10. Retur
11. Pengeluaran
12. Pemasukan
13. Kas dan rekening
14. Hutang dan piutang
15. Laporan
16. Pengguna dan hak akses
17. Pengaturan

Navigasi harus adaptif terhadap role pengguna. Kasir hanya melihat fitur yang diizinkan.

Setiap menu harus memiliki halaman nyata, bukan placeholder kosong.

## 9. Halaman POS

Halaman kasir adalah salah satu halaman utama dan harus dioptimalkan untuk penggunaan cepat.

Desktop:

- Sidebar atau header navigasi.
- Pencarian produk.
- Input barcode.
- Filter kategori.
- Grid produk dengan gambar, nama, harga, dan stok.
- Panel keranjang di sisi kanan.
- Pengubahan kuantitas.
- Penghapusan item.
- Diskon.
- Ringkasan subtotal, pajak, dan total.
- Pemilihan pembayaran.
- Tombol pembayaran yang jelas dan mudah dijangkau.

Mobile:

- Pencarian di bagian atas.
- Grid produk responsif.
- Keranjang melalui panel atau bottom sheet.
- Tombol checkout yang mudah digunakan.
- Input angka yang nyaman.
- Dialog pembayaran yang tidak terpotong.

Alur transaksi:

1. Pilih atau scan produk.
2. Masukkan jumlah.
3. Validasi stok dan harga.
4. Hitung subtotal, diskon, pajak, dan total.
5. Pilih pelanggan bila diperlukan.
6. Pilih metode pembayaran.
7. Masukkan nominal pembayaran.
8. Validasi pembayaran dan kembalian.
9. Simpan transaksi secara atomik di SQLite.
10. Catat pergerakan stok dan pembayaran.
11. Tampilkan hasil transaksi.
12. Tawarkan cetak atau bagikan struk.
13. Masukkan operasi ke antrean sinkronisasi.

Untuk mode kredit, validasi syarat kredit dan catat piutang dengan benar.

## 10. Manajemen Produk dan Inventaris

Implementasikan:

- CRUD produk.
- CRUD kategori.
- Upload gambar produk ketika online.
- Cache gambar yang sudah diunduh.
- Pencarian dan filter.
- Sorting.
- Pagination atau lazy loading.
- Import/export CSV.
- Bulk update harga.
- Penyesuaian stok.
- Stock opname.
- Riwayat pergerakan stok.
- Notifikasi stok minimum.
- Histori harga modal.
- Dukungan produk dengan varian.
- Dukungan barcode.
- Retur dan koreksi stok.

Validasi SKU dan barcode sesuai kebijakan bisnis. Tangani produk nonaktif yang masih muncul dalam transaksi historis.

## 11. Laporan Keuangan

Buat laporan dengan filter tanggal, periode, kategori, toko, kasir, dan metode pembayaran sesuai izin.

Laporan minimal:

- Ringkasan penjualan.
- Penjualan per hari, minggu, dan bulan.
- Detail transaksi.
- Penjualan per produk.
- Penjualan per kategori.
- Penjualan per kasir.
- Penjualan per metode pembayaran.
- Retur penjualan.
- Pembelian barang.
- Retur pembelian.
- Laba kotor.
- Pengeluaran operasional.
- Pemasukan lainnya.
- Laba rugi.
- Arus kas.
- Posisi kas dan rekening.
- Hutang supplier.
- Piutang pelanggan.
- Persediaan dan nilai stok.
- Produk terlaris.
- Produk lambat terjual.
- Selisih kas.
- Audit aktivitas pengguna.

Sediakan ekspor CSV dan PDF.

Definisikan rumus laporan secara eksplisit. Contohnya:

- Omzet bersih = penjualan setelah diskon dikurangi retur penjualan, dengan perlakuan pajak yang didefinisikan konsisten.
- Laba kotor = pendapatan penjualan bersih dikurangi harga pokok barang terjual.
- Laba operasional = laba kotor ditambah pendapatan operasional lain dikurangi beban operasional sesuai klasifikasi.
- Arus kas = kas masuk aktual dikurangi kas keluar aktual pada periode yang dipilih.

Bedakan transaksi kredit dari penerimaan kas. Pembelian stok tidak boleh otomatis dianggap sebagai seluruh beban laba rugi pada periode pembelian; gunakan harga pokok barang yang terjual untuk menghitung laba kotor.

Dokumentasikan perlakuan pajak, diskon, retur, pembatalan, dan biaya pembayaran.

## 12. Keamanan

- Gunakan Supabase Auth.
- Terapkan Row Level Security pada seluruh tabel bisnis.
- Pastikan pengguna hanya mengakses data bisnis dan toko yang diizinkan.
- Validasi role dan permission di server, bukan hanya menyembunyikan menu.
- Jangan menaruh `service_role` key dalam aplikasi Flutter.
- Gunakan public/anon key yang sesuai dengan RLS.
- Jangan menyimpan password atau token sensitif dalam plaintext.
- Gunakan secure storage untuk data autentikasi yang memerlukannya.
- Validasi input dan otorisasi sebelum perubahan finansial.
- Terapkan audit log untuk aktivitas sensitif.
- Lindungi operasi refund, penghapusan, penyesuaian stok, dan perubahan harga.
- Pisahkan konfigurasi environment untuk development dan production.

Jangan menganggap SQLite lokal aman dari manipulasi. Untuk lingkungan multi-kasir, terapkan kebijakan operasional dan rekonsiliasi ketika perangkat kembali online.

## 13. Error Handling dan Kualitas

Buat sistem error handling yang konsisten.

Tangani:

- Internet terputus.
- Supabase timeout.
- Token kedaluwarsa.
- Konflik sinkronisasi.
- Data tidak valid.
- SKU duplikat.
- Stok tidak mencukupi.
- Pembayaran gagal.
- Database migration gagal.
- Disk lokal penuh.
- Kegagalan ekspor.
- Printer tidak tersedia.
- Session pengguna tidak valid.

Tampilkan pesan error yang mudah dipahami pengguna, sementara detail teknis dicatat dalam log tanpa membocorkan data sensitif.

Semua form harus memiliki validasi, loading state, error state, dan feedback sukses.

Hindari `setState` setelah widget disposed, operasi async yang tidak aman, query berulang yang tidak perlu, dan pemanggilan database langsung dari widget.

## 14. Pengujian

Buat pengujian untuk:

- Kalkulasi subtotal, diskon, pajak, dan total.
- Pembayaran campuran dan kembalian.
- Stok masuk dan keluar.
- Retur.
- Pembelian kredit.
- Pelunasan hutang dan piutang.
- Laporan laba rugi.
- Perhitungan arus kas.
- Sinkronisasi berulang tanpa duplikasi.
- Konflik data.
- Offline transaction queue.
- Pemulihan antrean setelah restart.
- Permission pengguna.
- RLS Supabase.
- Responsive layout.
- Form validation.

Uji skenario penting berikut:

1. Penjualan ketika online.
2. Penjualan ketika offline.
3. Membuat beberapa transaksi offline.
4. Menutup aplikasi sebelum sinkronisasi.
5. Membuka kembali aplikasi.
6. Mengaktifkan internet.
7. Menyinkronkan antrean.
8. Mengulangi sync.
9. Memastikan tidak ada transaksi atau stok yang terduplikasi.
10. Memastikan perangkat kedua menerima data yang benar.

Jangan mengklaim pengujian berhasil jika belum benar-benar dijalankan.

## 15. Performa

- Gunakan pagination untuk daftar besar.
- Hindari membaca seluruh database setiap kali widget dibangun.
- Gunakan indeks SQLite dan PostgreSQL yang sesuai.
- Gunakan query agregasi untuk laporan besar bila diperlukan.
- Gunakan cache dan invalidasi cache yang benar.
- Hindari blocking main isolate.
- Optimalkan gambar produk.
- Gunakan list/grid builder untuk katalog.
- Minimalkan rebuild widget.
- Pisahkan operasi database berat dari rendering UI.

## 16. Deliverables

Hasil akhir harus mencakup:

1. Source code Flutter lengkap.
2. Struktur folder modular.
3. `pubspec.yaml` yang valid.
4. Implementasi seluruh halaman utama.
5. Design system dan reusable widgets.
6. Database SQLite dan migrasinya.
7. SQL schema Supabase.
8. Foreign key, indexes, constraints, dan RLS policies.
9. Supabase Auth dan role management.
10. Sync engine beserta retry, conflict handling, dan logging.
11. Repository, model, dan business logic.
12. Dashboard dengan data nyata.
13. Sistem POS lengkap.
14. Manajemen produk dan inventaris.
15. Laporan keuangan.
16. Pengujian unit, widget, dan integrasi yang relevan.
17. `.env.example` tanpa secret.
18. Dokumentasi instalasi dan konfigurasi.
19. Dokumentasi setup Supabase.
20. Dokumentasi build Android, Linux, dan Windows sesuai dukungan lingkungan.
21. Data seed untuk development.
22. Petunjuk migrasi database.
23. Daftar fitur yang sudah selesai dan yang masih memiliki keterbatasan.

Sertakan README yang menjelaskan:

- Persyaratan SDK.
- Instalasi dependency.
- Konfigurasi Supabase.
- Cara menjalankan migrasi.
- Cara menjalankan aplikasi.
- Cara menjalankan pengujian.
- Cara membuat build.
- Cara menguji mode offline.
- Cara memantau status sinkronisasi.

## 17. Urutan Implementasi

Kerjakan dalam fase yang terstruktur.

**Fase 1 — Fondasi**

- Inspeksi proyek.
- Setup Flutter.
- Arsitektur folder.
- Theme dan design system.
- Routing.
- Responsive shell.
- SQLite dan migrasi awal.
- Konfigurasi Supabase.
- Authentication dan role.

**Fase 2 — Data dan Sinkronisasi**

- Model dan repository.
- Schema Supabase.
- RLS.
- Sync queue.
- Outbox pattern.
- Retry dan conflict resolution.
- Pengujian offline/online.

**Fase 3 — Operasional**

- Produk dan kategori.
- Supplier dan pelanggan.
- Inventaris.
- Pembelian.
- POS dan penjualan.
- Pembayaran.
- Retur.
- Kasir dan sesi kas.

**Fase 4 — Keuangan**

- Pengeluaran dan pemasukan.
- Hutang dan piutang.
- Rekening dan mutasi.
- Dashboard.
- Laporan keuangan.
- Ekspor laporan.

**Fase 5 — Penyempurnaan**

- Animasi.
- Responsive refinement.
- Dark mode.
- Loading, empty, dan error states.
- Audit keamanan.
- Optimasi performa.
- Pengujian dan dokumentasi.

Di setiap fase, pastikan hasilnya dapat dianalisis, diuji, dan dijalankan sebelum berpindah ke fase berikutnya.

## 18. Aturan Kerja Coding Agent

- Mulai dengan memeriksa struktur proyek dan lingkungan yang tersedia.
- Buat rencana implementasi dan checklist fitur.
- Kerjakan langsung pada file proyek.
- Jangan hanya memberikan contoh kode atau daftar instruksi.
- Jangan membuat semua fitur dalam satu file besar.
- Jangan menggunakan dummy data sebagai pengganti fitur produksi, kecuali untuk seed development yang diberi label jelas.
- Jangan meninggalkan tombol yang tidak berfungsi.
- Jangan menyembunyikan error dengan catch kosong.
- Jangan membuat asumsi diam-diam tentang rumus keuangan atau kebijakan bisnis.
- Jika ada detail yang belum ditentukan, gunakan default yang masuk akal, dokumentasikan, dan buat konfigurasi jika sesuai.
- Jalankan formatter, analyzer, dan test setelah implementasi setiap fase.
- Perbaiki error yang ditemukan sebelum melanjutkan.
- Periksa ulang kompatibilitas package dan platform.
- Jangan menghapus pekerjaan yang sudah ada tanpa alasan.
- Jangan pernah menaruh secret Supabase dalam source code.
- Jika konteks atau waktu terbatas, prioritaskan fondasi dan fitur end-to-end yang benar-benar berjalan daripada membuat banyak halaman setengah jadi.

**Definition of Done:**

Aplikasi dinyatakan selesai hanya jika alur produk → stok → penjualan → pembayaran → pencatatan keuangan → laporan berjalan konsisten, baik offline maupun online; sinkronisasi tidak menggandakan transaksi; izin pengguna diterapkan dengan benar; UI responsif; dan pengujian utama telah dijalankan.

## 19. Aturan Tambahan

### 19.1 Audit dan Pelacakan Transaksi

Setiap transaksi (penjualan, pembelian, retur, pembayaran, penyesuaian stok, pengeluaran, pemasukan, dan lainnya) harus mencatat:

- `created_by`: ID pengguna yang melakukan transaksi.
- `created_at`: waktu transaksi terjadi dalam UTC.
- `updated_by` dan `updated_at` untuk perubahan data.
- Semua tabel transaksi harus memiliki kolom audit agar siapa dan kapan transaksi dilakukan dapat ditelusuki sepenuhnya.

### 19.2 Izin Akses per Fitur

Setiap fitur harus memiliki izin (permission) untuk dapat dilihat atau diakses. Izin ini harus:

- Ditetapkan melalui tabel `roles` dan `permissions` yang sudah ada.
- Dicek di sisi server (RLS/Supabase) dan di sisi klien sebelum menampilkan menu atau membuka halaman.
- Tidak cukup hanya menyembunyikan menu; validasi otorisasi harus dilakukan sebelum setiap perubahan data.
- Role awal (Owner, Admin, Manager, Kasir, Staff gudang) harus memiliki konfigurasi izin yang jelas per fitur.

### 19.3 Manajemen Pelanggan (Tier dan Poin Reward)

- Tambahkan `customer_tier` pada tabel pelanggan (misalnya: Regular, Silver, Gold, Platinum).
- Tambahkan `reward_points` atau poin reward yang terkumpul pada setiap pelanggan.
- Semua poin reward, batasan pembelian, dan aturan penarikan poin harus dapat diatur melalui halaman **Pengaturan** (settings), bukan hardcoded.
- Poin dan batasan pembelian harus tersimpan dalam tabel konfigurasi yang bisa diubah oleh admin melalui UI settings.

### 19.4 Manajemen Ikon Aplikasi

- Semua ikon yang digunakan dalam aplikasi harus ditempatkan dalam satu file khusus (satu file ikon terpusat).
- Dilarang hardcoded icon langsung di dalam widget (misalnya `Icons.home` atau `MaterialIcons.xxx` langsung di widget).
- Buat satu file konstanta ikon yang berisi seluruh ikon aplikasi, lalu gunakan konstanta tersebut di seluruh widget.

Mulai sekarang dengan menginspeksi proyek, menyusun checklist, dan mengimplementasikan Fase 1. Lanjutkan fase berikutnya secara bertahap, bukan berhenti setelah membuat dashboard atau tampilan awal.
