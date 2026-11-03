import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasilaah_finishing/core/errors/exceptions.dart';
import 'package:wasilaah_finishing/core/errors/failures.dart';
import 'package:wasilaah_finishing/core/services/auth_local_storage_service.dart';
import 'package:wasilaah_finishing/core/tenant/tenant_config.dart';
import 'package:wasilaah_finishing/features/auth/data/repos/auth_repo_impl.dart';

import '../../support/fakes.dart';

/// Pins the current login behaviour (Odoo session login, credentials kept
/// locally) so the Supabase migration can replace it knowingly.
void main() {
  late FakeOdooClient odoo;
  late AuthLocalStorageService storage;
  late AuthRepoImpl repo;

  const tenant = TenantConfig(
    id: 'acme',
    companyName: 'Acme',
    odoo: OdooConnectionConfig(
      baseUrl: 'https://odoo.acme.test',
      database: 'acme_db',
    ),
  );

  Future<void> setUpRepo([Map<String, Object> prefs = const {}]) async {
    SharedPreferences.setMockInitialValues(prefs);
    storage = AuthLocalStorageService(await SharedPreferences.getInstance());
    odoo = FakeOdooClient();
    repo = AuthRepoImpl(
      odooClient: odoo,
      localStorage: storage,
      tenant: tenant,
    );
  }

  test("login authenticates against the tenant's Odoo server", () async {
    await setUpRepo();

    final result = await repo.login(username: ' a@b.com ', password: 'pw');

    expect(result.isRight(), isTrue);
    expect(odoo.calls.single, {
      'url': 'https://odoo.acme.test',
      'db': 'acme_db',
      'login': 'a@b.com',
      'password': 'pw',
    });
    expect(storage.isLoggedIn, isTrue);
    expect(storage.username, 'a@b.com');
    expect(repo.getLocalSession().isLoggedIn, isTrue);
  });

  test('maps exceptions to failures and stores nothing', () async {
    await setUpRepo();
    final cases = <Object, Type>{
      const AuthException('x'): AuthFailure,
      const NetworkException('x'): NetworkFailure,
      const ServerException('x'): ServerFailure,
      StateError('x'): ServerFailure,
    };

    for (final entry in cases.entries) {
      odoo.error = entry.key;
      final result = await repo.login(username: 'a', password: 'b');
      expect(
        result.fold((f) => f.runtimeType, (_) => null),
        entry.value,
        reason: '${entry.key}',
      );
    }
    expect(storage.isLoggedIn, isFalse);
  });

  test('restoreSession fails when not logged in', () async {
    await setUpRepo();
    final result = await repo.restoreSession();
    expect(result.fold((f) => f, (_) => null), isA<AuthFailure>());
    expect(odoo.calls, isEmpty);
  });

  test('restoreSession re-authenticates with saved credentials', () async {
    await setUpRepo({
      'auth_username': 'a@b.com',
      'auth_password': 'pw',
      'auth_is_logged_in': true,
    });
    final result = await repo.restoreSession();
    expect(result.isRight(), isTrue);
    expect(odoo.calls.single['password'], 'pw');
  });

  test('logout clears Odoo session and local storage', () async {
    await setUpRepo({
      'auth_username': 'a@b.com',
      'auth_password': 'pw',
      'auth_is_logged_in': true,
    });
    await repo.logout();
    expect(odoo.loggedOut, isTrue);
    expect(storage.isLoggedIn, isFalse);
    expect(storage.username, isNull);
    expect(storage.password, isNull);
  });
}
