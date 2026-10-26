/// Konstanta aplikasi POS.
class AppConstants {
  const AppConstants._();

  static const String appName = 'POS Manajemen';
  static const String currencySymbol = 'Rp';
  static const String locale = 'id_ID';
  static const String timezone = 'Asia/Jakarta';

  /// Nama file basis data SQLite lokal.
  static const String localDbName = 'pos_local.db';

  /// Periode retry sinkronisasi (exponential backoff): 5s, 15s, 45s, 2m, 6m.
  static const List<Duration> syncBackoff = [
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 45),
    Duration(minutes: 2),
    Duration(minutes: 6),
  ];

  /// Jumlah percobaan maksimum sebelum operasi ditandai gagal permanen.
  static const int maxSyncRetries = 8;

  /// Interval sinkronisasi berkala saat aplikasi aktif.
  static const Duration periodicSyncInterval = Duration(minutes: 2);
}
