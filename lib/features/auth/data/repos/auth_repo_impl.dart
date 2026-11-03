import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/odoo_client.dart';
import '../../../../core/services/auth_local_storage_service.dart';
import '../../../../core/tenant/tenant_config.dart';
import '../../domain/entities/auth_session_entity.dart';
import '../../domain/repos/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  AuthRepoImpl({
    required OdooClient odooClient,
    required AuthLocalStorageService localStorage,
    required TenantConfig tenant,
  }) : _odooClient = odooClient,
       _localStorage = localStorage,
       _tenant = tenant;

  final OdooClient _odooClient;
  final AuthLocalStorageService _localStorage;
  final TenantConfig _tenant;

  @override
  Future<Either<Failure, Unit>> login({
    required String username,
    required String password,
  }) async {
    try {
      await _odooClient.authenticate(
        url: _tenant.odoo.baseUrl,
        db: _tenant.odoo.database,
        login: username.trim(),
        password: password,
      );
      await _localStorage.saveCredentials(
        username: username.trim(),
        password: password,
      );
      return right(unit);
    } on AuthException catch (e) {
      return left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return left(ServerFailure(e.message));
    } catch (e) {
      return left(ServerFailure('خطأ غير متوقع: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> restoreSession() async {
    if (!_localStorage.isLoggedIn) {
      return left(const AuthFailure('غير مسجل الدخول'));
    }

    final username = _localStorage.username;
    final password = _localStorage.password;
    if (username == null || password == null) {
      return left(const CacheFailure('بيانات الجلسة غير متوفرة'));
    }

    return login(username: username, password: password);
  }

  @override
  Future<void> logout() async {
    _odooClient.logout();
    await _localStorage.clearSession();
  }

  @override
  AuthSessionEntity getLocalSession() {
    return AuthSessionEntity(
      username: _localStorage.username ?? '',
      isLoggedIn: _localStorage.isLoggedIn,
    );
  }
}
