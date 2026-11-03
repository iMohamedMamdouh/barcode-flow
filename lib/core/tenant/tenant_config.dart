import 'package:equatable/equatable.dart';

/// Everything that belongs to one company (tenant) using Barcode Flow.
///
/// Read at runtime instead of compile-time constants, so the app can serve
/// any company. For now the app ships with a single default tenant
/// ([DefaultTenant]); later it will be loaded from the company's account
/// (Supabase) after login — see REPORT.md, phases 1 and 3.
class TenantConfig extends Equatable {
  const TenantConfig({
    required this.id,
    required this.companyName,
    required this.odoo,
  });

  /// Stable identifier of the company account.
  final String id;

  /// Display name of the company (shown in the app and on labels).
  final String companyName;

  /// Where this company's products, categories and barcodes come from.
  final OdooConnectionConfig odoo;

  @override
  List<Object?> get props => [id, companyName, odoo];
}

/// Connection details of a company's own Odoo server.
class OdooConnectionConfig extends Equatable {
  const OdooConnectionConfig({required this.baseUrl, required this.database});

  /// e.g. `https://erp.example.com` (no trailing slash needed).
  final String baseUrl;

  /// Odoo database name.
  final String database;

  @override
  List<Object?> get props => [baseUrl, database];
}
