import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wasilaah_finishing/core/constants/app_constants.dart';
import 'package:wasilaah_finishing/core/utils/service_locator.dart';
import 'package:wasilaah_finishing/main.dart';

void main() {
  setUp(() async {
    await sl.reset();
    SharedPreferences.setMockInitialValues({});
    setupServiceLocator(prefs: await SharedPreferences.getInstance());
    configureBundledFonts();
  });

  testWidgets('splash shows the app name then goes to login when logged out',
      (tester) async {
    await tester.pumpWidget(const WasilaahApp());
    await tester.pump();
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('جارٍ التحقق من الجلسة...'), findsOneWidget);

    // Splash waits 1.5s before checking the session.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1)); // route transition

    expect(find.text('أدخل بريدك وكلمة المرور المرتبطة بحساب Odoo'),
        findsOneWidget);
  });
}
