import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repos/auth_repo.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepo) : super(const AuthState());

  final AuthRepo _authRepo;

  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(state.copyWith(isLoading: true, clearError: true));

    final result = await _authRepo.login(
      username: username,
      password: password,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: false,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          clearError: true,
        ),
      ),
    );
  }
}
