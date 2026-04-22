class AppConstants {
  AppConstants._();

  static const String appName = 'تغليف وسيلة';
  static const String appNameEn = 'Wasilaah Packaging';
  static const String companyName = 'وسيلة';
  static const Duration splashDuration = Duration(seconds: 3);
  static const int productsPageSize = 80;

  // ── Odoo API Connection ──────────────────────────────────
  // غيّر هذه القيم حسب إعدادات خادم Odoo الخاص بك
  static const String odooUrl = 'https://erp.wasilaahteam.com';
  static const String odooDatabase = 'erp';
}
