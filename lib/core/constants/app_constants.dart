/// Product identity of Barcode Flow itself — the same for every company.
///
/// Nothing company-specific belongs here: a company's name, Odoo server,
/// branding, categories and label settings live in [TenantConfig]
/// (`lib/core/tenant/tenant_config.dart`).
class AppConstants {
  AppConstants._();

  static const String appName = "باركود فلو";
  static const String appNameEn = 'Barcode Flow';
  static const String appTagline = 'اطبع ليبلات منتجاتك من Odoo في ثوانٍ';
  static const String appTaglineEn = 'Print Odoo product labels in seconds';

  static const Duration splashDuration = Duration(seconds: 3);
  static const int productsPageSize = 80;
}
