import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/routes/app_routes.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/service_locator.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureBundledFonts();
  final prefs = await SharedPreferences.getInstance();
  setupServiceLocator(prefs: prefs);
  runApp(const WasilaahApp());
}

/// Fonts ship as assets (see `assets/fonts/`): never download them at runtime.
void configureBundledFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    for (final entry in const {
      'Tajawal': 'assets/fonts/OFL-Tajawal.txt',
      'Noto Sans Arabic': 'assets/fonts/OFL-NotoSansArabic.txt',
    }.entries) {
      yield LicenseEntryWithLineBreaks(
        [entry.key],
        await rootBundle.loadString(entry.value),
      );
    }
  });
}

class WasilaahApp extends StatelessWidget {
  const WasilaahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [routeObserver],
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
  }
}
