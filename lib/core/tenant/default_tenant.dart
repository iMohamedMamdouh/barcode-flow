import 'tenant_config.dart';

/// The tenant the app uses until company accounts exist (REPORT.md, phase 3).
///
/// This is the ONLY place in `lib/` that knows about a specific company.
/// To point the app at another company's Odoo for now, change it here.
class DefaultTenant {
  DefaultTenant._();

  static const TenantConfig config = TenantConfig(
    id: 'wasilaah',
    companyName: 'وسيلة',
    odoo: OdooConnectionConfig(
      baseUrl: 'https://erp.wasilaahteam.com',
      database: 'erp',
    ),
  );
}
