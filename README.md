# PrimePOS - Modern Offline-First Point of Sale System

Sistem Point of Sale (POS) modern, offline-first, dibangun dengan Flutter + Drift (SQLite) + Supabase.

## ✨ Fitur Utama

### 🏪 Manajemen Operasional
- **Produk & Kategori** - CRUD lengkap, pencarian SKU/barcode/nama, stok minimum, pagination
- **Supplier & Pelanggan** - Manajemen kontak, tier pelanggan, poin reward
- **Inventaris** - Stock movements, penyesuaian stok, stock opname
- **Pembelian** - Tunai/kredit, penerimaan barang, update stok otomatis
- **POS/Kasir** - Keranjang, diskon, pajak, pembayaran campuran, checkout atomik
- **Penjualan & Retur** - Riwayat transaksi, detail, retur penuh/sebagian

### 💰 Manajemen Keuangan
- **Pengeluaran & Pemasukan** - Kategori, metode pembayaran, CRUD lengkap
- **Hutang & Piutang** - Supplier/Customer, jatuh tempo, pelunasan bertahap
- **Kas & Rekening** - Register kasir, sesi kasir, multi-rekening (kas/bank/e-wallet)
- **Dashboard** - Statistik real-time, grafik penjualan, stok menipis, aktivitas terbaru
- **Laporan** - Penjualan, produk terlaris, stok, keuangan (laba rugi, arus kas)

### ⚙️ Sistem & Keamanan
- **Autentikasi** - Supabase Auth, role-based access (Owner/Admin/Manager/Kasir/Staff Gudang)
- **Izin Granular** - Permission matrix per fitur, guard navigasi adaptif
- **Audit Log** - Tracking create/update/delete/login/payment/stock adjustment
- **Sinkronisasi Offline-First** - Outbox pattern, exponential backoff, conflict resolution LWW
- **Theme System** - 7 preset warna OKLCH (Ocean/Forest/Sunset/Sakura/Cotton Candy/Midnight/Inferno), light/dark mode

## 🏗️ Arsitektur

```
lib/
├── main.dart                 # Entry point, providers, theme
├── app/
│   ├── router/               # GoRouter + ShellRoute (responsive)
│   ├── theme/                # Material 3, design tokens, 7 preset OKLCH
│   └── responsive/           # ResponsiveLayout, NavigationRail/NavigationBar
├── core/
│   ├── database/             # Drift tables, DAO, SyncEngine, outbox
│   ├── network/              # Supabase config, connectivity
│   └── widgets/              # Skeletons, EmptyState, ErrorState, Pagination
├── features/
│   ├── auth/                 # Login, role, permission guard
│   ├── dashboard/            # Stats cards, charts, sync status
│   ├── products/             # CRUD + pagination + category filter
│   ├── categories/           # CRUD kategori
│   ├── suppliers/            # CRUD supplier
│   ├── customers/            # CRUD + tier + reward points
│   ├── inventory/            # Stock movements, adjustments, opname
│   ├── purchases/            # Cash/credit, receiving
│   ├── pos/                  # Cart, checkout, payment
│   ├── sales/                # History, returns
│   ├── expenses/             # CRUD + categories
│   ├── income/               # CRUD + categories
│   ├── debts/                # Payable/receivable + payments
│   ├── cash/                 # Registers, accounts, sessions
│   ├── reports/              # Sales, products, inventory, financial
│   ├── settings/             # Theme presets, mode, sync, about
│   └── audit/                # Audit log viewer + filters
├── l10n/                     # ARB files (ID/EN)
└── shared/providers/         # Riverpod providers (DB, sync, auth)
```

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter 3.24+, Dart 3.5+ |
| **State** | Riverpod 2.6+ (Notifier, StreamProvider, FutureProvider) |
| **Routing** | GoRouter 14+ (ShellRoute, redirect guard) |
| **Local DB** | Drift 2.21+ (SQLite, type-safe, migrations) |
| **Remote DB** | Supabase (PostgreSQL, Auth, Realtime) |
| **Charts** | fl_chart 0.68+ |
| **Sync** | Custom outbox pattern, exponential backoff, LWW conflict resolution |
| **Localization** | flutter_localizations + ARB (ID/EN) |
| **Icons** | Material Icons (centralized in AppIcons) |

## 📋 Prasyarat

- Flutter SDK 3.24+
- Dart SDK 3.5+
- Android Studio / VS Code
- Supabase account (untuk backend cloud)
- Linux: `libsqlite3-dev` (untuk build)

## 🚀 Instalasi & Menjalankan

```bash
# 1. Clone repository
git clone <repo-url>
cd pos_den/qwen-repotest

# 2. Install dependencies
flutter pub get

# 3. Generate code (Drift, l10n)
dart run build_runner build --delete-conflicting-outputs

# 4. Setup Supabase (opsional - untuk mode online)
# Copy .env.example to .env dan isi SUPABASE_URL + SUPABASE_ANON_KEY

# 5. Jalankan aplikasi
flutter run -d linux    # Linux desktop
flutter run -d android  # Android device/emulator
flutter run -d windows  # Windows desktop
```

### Build Release

```bash
# Linux
flutter build linux --release

# Android
flutter build apk --release
flutter build appbundle --release

# Windows
flutter build windows --release
```

## 🗄️ Database & Sinkronisasi

### Skema Lokal (Drift)
- **42 tabel** mencakup: businesses, stores, profiles, products, categories, suppliers, customers, sales, purchases, inventory, cash, debts, audit_logs, sync_queue, dll.
- **Soft delete** dengan `deletedAt` + `syncStatus` untuk sinkronisasi
- **Version column** untuk optimistic locking

### Sinkronisasi (Offline-First)
1. **Outbox Pattern** - Setiap perubahan lokal masuk ke `sync_queue`
2. **Push** - Upload perubahan lokal ke Supabase (batch, idempotent)
3. **Pull** - Download perubahan remote (server wins untuk konflik sederhana)
4. **Retry** - Exponential backoff (max 5x, 30s base)
4. **Conflict Resolution** - Last-Write-Wins (LWW) berdasarkan `updatedAt`

### Mode Operasi
| Mode | Deskripsi |
|------|-----------|
| **Online** | Supabase connected, sync real-time |
| **Offline** | SQLite lokal penuh, antrian sync |
| **Hybrid** | Lokal dulu, sync saat online |

## 🎨 Theme Presets (7 OKLCH)

| Preset | Warna Utama | Cocok Untuk |
|--------|-------------|-------------|
| **Ocean** | Biru laut (#0369A1) | Profesional, corporate |
| **Forest** | Hijau hutan (#166534) | Default, natural, seimbang |
| **Sunset** | Oranye-merah (#EA580C) | Enerjik, retail, F&B |
| **Sakura** | Pink lembut (#DB2777) | Fashion, beauty, boutique |
| **Cotton Candy** | Pastel ungu (#A855F7) | Creative, kids, lifestyle |
| **Midnight** | Gelap premium (#312E81) | Dark mode default, premium |
| **Inferno** | Merah gelap (#991B1B) | Bold, automotive, industrial |

## 🌐 Internasionalisasi

- **Bahasa Indonesia** (default) - `app_id.arb`
- **English** - `app_en.arb`
- Format mata uang: Rupiah (Rp) dengan locale `id_ID`
- Format tanggal: DD/MM/YYYY

## 🔐 Hak Akses (Permission Matrix)

| Fitur | Owner | Admin | Manager | Kasir | Staff Gudang |
|-------|-------|-------|---------|-------|--------------|
| Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ |
| Produk (CRUD) | ✅ | ✅ | ✅ | 👁️ | 👁️ |
| POS/Kasir | ✅ | ✅ | ✅ | ✅ | ❌ |
| Penjualan | ✅ | ✅ | ✅ | 👁️ | ❌ |
| Pembelian | ✅ | ✅ | ✅ | ❌ | ✅ |
| Inventaris | ✅ | ✅ | ✅ | ❌ | ✅ |
| Keuangan | ✅ | ✅ | ✅ | ❌ | ❌ |
| Laporan | ✅ | ✅ | ✅ | ❌ | ❌ |
| User Management | ✅ | ✅ | ❌ | ❌ | ❌ |
| Settings | ✅ | ✅ | ❌ | ❌ | ❌ |
| Audit Log | ✅ | ✅ | 👁️ | ❌ | ❌ |

## 🧪 Testing

```bash
# Unit & Widget tests
flutter test

# Integration test (perlu device/emulator)
flutter test integration_test/app_test.dart

# Coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

## 📁 Struktur Environment

```bash
.env.example          # Template konfigurasi
.env                  # Konfigurasi lokal (gitignored)
```

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

## 📝 Lisensi

MIT License - bebas digunakan untuk komersial maupun pribadi.

## 🤝 Kontribusi

1. Fork repository
2. Buat branch fitur (`git checkout -b feature/nama-fitur`)
3. Commit perubahan (`git commit -m 'feat: tambah fitur X'`)
4. Push ke branch (`git push origin feature/nama-fitur`)
5. Buat Pull Request

## 📞 Dukungan

- Issue tracker: GitHub Issues
- Dokumentasi: Wiki repository
- Email: support@primepos.example.com

---

**PrimePOS** - Modern offline-first POS untuk bisnis modern 🚀