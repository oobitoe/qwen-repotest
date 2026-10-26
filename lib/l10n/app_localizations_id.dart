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
  String get syncQueue => 'Antrian Sinkronisasi';

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
  String get appDisplayName => 'POSku';

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
}
