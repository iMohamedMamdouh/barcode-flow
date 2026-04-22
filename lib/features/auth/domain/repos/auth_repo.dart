import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/auth_session_entity.dart';

abstract class AuthRepo {
  Future<Either<Failure, Unit>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, Unit>> restoreSession();

  Future<void> logout();

  AuthSessionEntity getLocalSession();
}
