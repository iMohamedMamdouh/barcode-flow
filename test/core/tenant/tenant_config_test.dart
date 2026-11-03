import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasilaah_finishing/core/tenant/default_tenant.dart';
import 'package:wasilaah_finishing/core/tenant/tenant_config.dart';
import 'package:wasilaah_finishing/core/utils/service_locator.dart';

void main() {
  test('service locator exposes the tenant it was given', () async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    const other = TenantConfig(
      id: 'other',
      companyName: 'Other Co',
      odoo: OdooConnectionConfig(baseUrl: 'https://x.test', database: 'x'),
    );
    setupServiceLocator(
      prefs: await SharedPreferences.getInstance(),
      tenant: other,
    );
    expect(sl<TenantConfig>(), other);
    await sl.reset();
  });

  test('default tenant is a complete config', () {
    const t = DefaultTenant.config;
    expect(t.id, isNotEmpty);
    expect(t.companyName, isNotEmpty);
    expect(Uri.parse(t.odoo.baseUrl).isScheme('https'), isTrue);
    expect(t.odoo.database, isNotEmpty);
  });

  // Guard rail: the company's Odoo server must only be configured in
  // default_tenant.dart, never hard-coded elsewhere in lib/.
  test('Odoo server URL is not hard-coded outside default_tenant.dart', () {
    final host = Uri.parse(DefaultTenant.config.odoo.baseUrl).host;
    final offenders =
        Directory('lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .where((f) => !f.path.endsWith('default_tenant.dart'))
            .where((f) => f.readAsStringSync().contains(host))
            .map((f) => f.path)
            .toList();
    expect(offenders, isEmpty);
  });
}
