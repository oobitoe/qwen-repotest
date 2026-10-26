/// Token desain terpusat. Jangan hardcode warna/spacing di widget.
/// Semua tampilan harus mengambil nilai dari sini atau dari Theme.of(context).
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class AppBreakpoints {
  const AppBreakpoints._();

  /// < mobile, >= tablet, >= desktop
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}
