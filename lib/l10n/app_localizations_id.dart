// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Aplikasi POS';

  @override
  String get home => 'Beranda';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get pos => 'POS / Kasir';

  @override
  String get sales => 'Penjualan';

  @override
  String get purchases => 'Pembelian';

  @override
  String get products => 'Produk';

  @override
  String get categories => 'Kategori';

  @override
  String get inventory => 'Inventaris';

  @override
  String get suppliers => 'Supplier';

  @override
  String get customers => 'Pelanggan';

  @override
  String get returns => 'Retur';

  @override
  String get expenses => 'Pengeluaran';

  @override
  String get income => 'Pemasukan';

  @override
  String get cashManagement => 'Manajemen Kas';

  @override
  String get debts => 'Hutang & Piutang';

  @override
  String get reports => 'Laporan';

  @override
  String get users => 'Pengguna';

  @override
  String get settings => 'Pengaturan';

  @override
  String get login => 'Masuk';

  @override
  String get logout => 'Keluar';

  @override
  String get language => 'Bahasa';

  @override
  String get indonesian => 'Bahasa Indonesia';

  @override
  String get english => 'Bahasa Inggris';

  @override
  String get save => 'Simpan';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get edit => 'Ubah';

  @override
  String get add => 'Tambah';

  @override
  String get search => 'Cari';

  @override
  String get filter => 'Filter';

  @override
  String get date => 'Tanggal';

  @override
  String get amount => 'Jumlah';

  @override
  String get total => 'Total';

  @override
  String get status => 'Status';

  @override
  String get createdBy => 'Dibuat Oleh';

  @override
  String get createdAt => 'Dibuat Pada';

  @override
  String get updatedBy => 'Diperbarui Oleh';

  @override
  String get updatedAt => 'Diperbarui Pada';

  @override
  String get customerTier => 'Tingkat Pelanggan';

  @override
  String get rewardPoints => 'Poin Reward';

  @override
  String get permission => 'Izin';

  @override
  String get access => 'Akses';

  @override
  String get name => 'Nama';

  @override
  String get stock => 'Stok';

  @override
  String get stockMovements => 'Pergerakan Stok';

  @override
  String get adjustStock => 'Sesuaikan Stok';

  @override
  String get active => 'Aktif';

  @override
  String get inactive => 'Tidak Aktif';

  @override
  String get offline => 'Offline';

  @override
  String get online => 'Online';

  @override
  String get syncStatus => 'Status Sinkronisasi';

  @override
  String get syncQueue => 'Antrian Sinkron';

  @override
  String get error => 'Error';

  @override
  String get success => 'Berhasil';

  @override
  String get warning => 'Peringatan';

  @override
  String get info => 'Informasi';

  @override
  String get loading => 'Memuat';

  @override
  String get noData => 'Tidak Ada Data';

  @override
  String get confirmDelete => 'Apakah Anda yakin ingin menghapus item ini?';

  @override
  String get insufficientStock => 'Stok tidak mencukupi';

  @override
  String get transactionSaved => 'Transaksi disimpan';

  @override
  String get transactionFailed => 'Transaksi gagal';

  @override
  String get accessDenied =>
      'Akses ditolak. Anda tidak memiliki izin untuk mengakses fitur ini.';

  @override
  String get appDisplayName => 'PrimePOS';

  @override
  String get appVersion => 'v0.1.0';

  @override
  String get email => 'Email';

  @override
  String get password => 'Kata sandi';

  @override
  String get invalidEmail => 'Email tidak valid';

  @override
  String get minPasswordLength => 'Minimal 6 karakter';

  @override
  String loginFailed(Object error) {
    return 'Gagal masuk: $error';
  }

  @override
  String get offlineMode => 'Mode offline — data tersimpan di perangkat ini.';

  @override
  String get onlineMode => 'Online — data tersimpan di awan.';

  @override
  String get offlineSubtitle =>
      'Masuk dengan akun toko Anda atau gunakan mode offline.';

  @override
  String get registerAccount => 'Daftar Akun';

  @override
  String get registerSubtitle => 'Buat akun baru untuk toko Anda.';

  @override
  String get fullName => 'Nama Lengkap';

  @override
  String get role => 'Peran';

  @override
  String get backToLogin => 'Kembali ke masuk';

  @override
  String registrationFailed(Object error) {
    return 'Gagal mendaftar: $error';
  }

  @override
  String get loginSubtitle => 'Masuk dengan akun toko Anda.';

  @override
  String get syncNow => 'Sinkronkan sekarang';

  @override
  String get newTransaction => 'Transaksi Baru';

  @override
  String get syncInterrupted => 'Sinkronisasi terganggu';

  @override
  String offlinePending(Object pending) {
    return 'Offline · $pending perubahan menunggu antrean';
  }

  @override
  String get offlineSaved => 'Offline · semua data tersimpan lokal';

  @override
  String syncing(Object count) {
    return 'Sedang sinkronisasi… ($count item)';
  }

  @override
  String syncError(Object message) {
    return 'Galat sync: $message';
  }

  @override
  String get syncReady => 'Siap · tersimpan lokal';

  @override
  String syncSynced(Object ago) {
    return 'Tersinkron · terakhir $ago';
  }

  @override
  String get agoJustNow => 'baru saja';

  @override
  String agoMinutes(Object n) {
    return '$n mnt lalu';
  }

  @override
  String agoHours(Object n) {
    return '$n jam lalu';
  }

  @override
  String get revenueToday => 'Pendapatan Hari Ini';

  @override
  String get subtitleInvoice => 'invoice selesai';

  @override
  String get grossProfitToday => 'Laba Kotor Hari Ini';

  @override
  String get subtitleCogs => 'setelah HPP';

  @override
  String get activeProducts => 'Produk Aktif';

  @override
  String lowStockCount(Object count) {
    return '$count perlu restok';
  }

  @override
  String get stockSafe => 'stok aman';

  @override
  String get chartSales => 'Grafik Penjualan';

  @override
  String get chartSubtitle => '14 hari terakhir';

  @override
  String get lowStockTitle => 'Stok Menipis';

  @override
  String get noActivity => 'Belum ada aktivitas.';

  @override
  String get recentActivity => 'Aktivitas Terbaru';

  @override
  String get allStockSafe => 'Semua stok aman';

  @override
  String get retry => 'Coba lagi';

  @override
  String get greetingMorning => 'Selamat pagi';

  @override
  String get greetingAfternoon => 'Selamat siang';

  @override
  String get greetingEvening => 'Selamat sore';

  @override
  String get greetingNight => 'Selamat malam';

  @override
  String greetingRole(Object greet, Object role) {
    return '$greet · role $role';
  }

  @override
  String comingSoon(Object title) {
    return '$title akan hadir di fase berikutnya.';
  }

  @override
  String get tooltipOpenSidebar => 'Buka sidebar';

  @override
  String get tooltipCollapseSidebar => 'Ciutkan sidebar';

  @override
  String get outOfStock => 'Habis';

  @override
  String get transactionsToday => 'Transaksi Hari Ini';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get diskon => 'Diskon';

  @override
  String get pajak => 'Pajak';

  @override
  String get keranjang => 'Keranjang';

  @override
  String get keranjangKosong => 'Keranjang Kosong';

  @override
  String get pembayaran => 'Pembayaran';

  @override
  String get metodePembayaran => 'Metode Pembayaran';

  @override
  String get checkout => 'Checkout';

  @override
  String get batal => 'Batal';

  @override
  String get cashRegister => 'Register Kasir';

  @override
  String get openSession => 'Buka Sesi';

  @override
  String get activeSession => 'Sesi Aktif';

  @override
  String get openedBy => 'Dibuka oleh';

  @override
  String get openingBalance => 'Saldo Awal';

  @override
  String get closeSession => 'Tutup Sesi';

  @override
  String get actualBalance => 'Saldo Aktual';

  @override
  String get close => 'Tutup';

  @override
  String get register => 'Register';

  @override
  String get open => 'Buka';

  @override
  String get accounts => 'Rekening';

  @override
  String get cashSessions => 'Sesi Kasir';

  @override
  String get accountType => 'Tipe Rekening';

  @override
  String get accountTypeCash => 'Kas';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeEWallet => 'E-Wallet';

  @override
  String get accountBalance => 'Saldo Rekening';

  @override
  String get expenseDeleted => 'Pengeluaran dihapus';

  @override
  String get incomeDeleted => 'Pemasukan dihapus';

  @override
  String get descriptionRequired => 'Deskripsi wajib diisi';

  @override
  String get amountRequired => 'Jumlah wajib diisi';

  @override
  String get amountInvalid => 'Jumlah tidak valid';

  @override
  String get nameRequired => 'Nama wajib diisi';

  @override
  String get noCategory => 'Tanpa Kategori';

  @override
  String get selectRegister => 'Pilih register';

  @override
  String get balanceRequired => 'Saldo wajib diisi';

  @override
  String get balanceInvalid => 'Saldo tidak valid';

  @override
  String get paymentMethodCash => 'Tunai';

  @override
  String get paymentMethodTransfer => 'Transfer';

  @override
  String get paymentMethodQris => 'QRIS';

  @override
  String get paymentMethodCard => 'Kartu';

  @override
  String get paymentMethodOther => 'Lainnya';

  @override
  String get themePreset => 'Preset Tema';

  @override
  String get themePresetSubtitle => 'Pilih tema warna favorit Anda';

  @override
  String get themeMode => 'Mode Tema';

  @override
  String get themeModeSubtitle => 'Pilih terang, gelap, atau default sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get languageSubtitle => 'Pilih bahasa aplikasi';

  @override
  String languageChanged(Object language) {
    return 'Bahasa diubah ke $language';
  }

  @override
  String get sync => 'Sinkronisasi';

  @override
  String get syncSubtitle => 'Kelola sinkronisasi data';

  @override
  String get manualSync => 'Sinkron Manual';

  @override
  String get manualSyncDesc => 'Picu sinkronisasi ke server sekarang';

  @override
  String get syncQueueDesc => 'Lihat operasi sinkron tertunda';

  @override
  String get about => 'Tentang';

  @override
  String get aboutSubtitle => 'Informasi aplikasi';

  @override
  String version(Object version) {
    return 'Versi $version';
  }

  @override
  String get aboutDescription =>
      'Sistem POS offline-first modern dibangun dengan Flutter, Drift, Riverpod, dan Supabase.';

  @override
  String get techStack => 'Teknologi';

  @override
  String get startDate => 'Tanggal Mulai';

  @override
  String get endDate => 'Tanggal Akhir';

  @override
  String get apply => 'Terapkan';

  @override
  String get exportCSV => 'Ekspor CSV';

  @override
  String get exportPDF => 'Ekspor PDF';

  @override
  String get financial => 'Keuangan';

  @override
  String get totalSales => 'Total Penjualan';

  @override
  String get transactions => 'Transaksi';

  @override
  String get grossProfit => 'Laba Kotor';

  @override
  String get salesChart => 'Grafik Penjualan';

  @override
  String get detail => 'Detail';

  @override
  String get period => 'Periode';

  @override
  String get revenue => 'Pendapatan';

  @override
  String get avgTransaction => 'Rata-rata Transaksi';

  @override
  String get topProducts => 'Produk Terlaris';

  @override
  String get product => 'Produk';

  @override
  String get category => 'Kategori';

  @override
  String get qtySold => 'Terjual';

  @override
  String get profit => 'Laba';

  @override
  String get totalStockValue => 'Total Nilai Stok';

  @override
  String get lowStockItems => 'Stok Menipis';

  @override
  String get totalProducts => 'Total Produk';

  @override
  String get stockDetail => 'Detail Stok';

  @override
  String get minStock => 'Stok Min';

  @override
  String get stockValue => 'Nilai Stok';

  @override
  String get profitLoss => 'Laba Rugi';

  @override
  String get cashFlow => 'Arus Kas';

  @override
  String get oopsSomethingWrong => 'Ups! Terjadi kesalahan';

  @override
  String noResultsFound(Object query) {
    return 'Tidak ada hasil untuk \"$query\"';
  }

  @override
  String get tryDifferentSearch => 'Coba kata kunci atau filter lain';

  @override
  String get clearSearch => 'Hapus pencarian';

  @override
  String get connectionError => 'Tidak dapat terhubung ke server';

  @override
  String get retryConnection => 'Coba sambungkan lagi';

  @override
  String get goOnline => 'Buat online';

  @override
  String get sessionExpired =>
      'Sesi Anda telah berakhir. Silakan masuk kembali.';

  @override
  String get resourceNotFound => 'Sumber daya yang diminta tidak ditemukan';

  @override
  String get serverError => 'Galat server. Silakan coba lagi nanti.';

  @override
  String serverErrorCode(Object code) {
    return 'Galat server (kode: $code)';
  }

  @override
  String get auditLog => 'Log Audit';

  @override
  String get user => 'Pengguna';

  @override
  String get action => 'Aksi';

  @override
  String get entityType => 'Tipe Entitas';

  @override
  String get entityId => 'ID Entitas';

  @override
  String get timestamp => 'Waktu';

  @override
  String get oldValue => 'Nilai Lama';

  @override
  String get newValue => 'Nilai Baru';

  @override
  String get changes => 'Perubahan';

  @override
  String get viewDetail => 'Lihat Detail';

  @override
  String get viewChanges => 'Lihat Perubahan';

  @override
  String get clearFilters => 'Hapus Filter';

  @override
  String get selectDate => 'Pilih Tanggal';

  @override
  String get noAuditLogs => 'Tidak ada log audit';

  @override
  String get auditLogTitle => 'Log Audit';

  @override
  String get auditLogSubtitle => 'Lacak semua aktivitas sistem';

  @override
  String get previousPage => 'Halaman Sebelumnya';

  @override
  String get nextPage => 'Halaman Selanjutnya';

  @override
  String get kredit => 'Kredit';

  @override
  String get holdTransaction => 'Tahan Transaksi';

  @override
  String get transactionsTertahan => 'Transaksi Ditahan';

  @override
  String get lanjutkanTransaksi => 'Lanjutkan Transaksi';
}
