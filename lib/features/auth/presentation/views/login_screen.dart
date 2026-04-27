import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/repos/auth_repo.dart';
import '../cubits/auth_cubit.dart';
import '../cubits/auth_state.dart';
import '../widgets/login_form_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthCubit(sl<AuthRepo>()),
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen:
            (previous, current) =>
                previous.isAuthenticated != current.isAuthenticated,
        listener: (context, state) {
          if (state.isAuthenticated) {
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRoutes.products, (route) => false);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 26),
                      const Icon(
                        Icons.inventory_2_rounded,
                        size: 74,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.appNameEn,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 52),
                      Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'أدخل بريدك وكلمة المرور المرتبطة بحساب Odoo',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const LoginFormWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
