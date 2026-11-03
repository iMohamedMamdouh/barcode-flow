import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wasilaah_finishing/core/utils/label_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('label fonts are bundled and parse as TTF', () async {
    final fonts = await Future.wait([
      LabelFonts.tajawalRegular(),
      LabelFonts.tajawalBold(),
      LabelFonts.notoSansArabicRegular(),
      LabelFonts.notoSansArabicBold(),
    ]);
    expect(fonts, hasLength(4));
    // Cached: loading again returns the same instance.
    expect(await LabelFonts.tajawalBold(), same(fonts[1]));
  });

  test('UI font weights used by the app are bundled for google_fonts',
      () async {
    for (final name in [
      'Tajawal-Regular', // w400
      'Tajawal-Medium', // w500
      'Tajawal-Bold', // w600 / w700
      'Tajawal-ExtraBold', // w800
    ]) {
      final data = await rootBundle.load('assets/fonts/$name.ttf');
      expect(data.lengthInBytes, greaterThan(10000), reason: name);
    }
  });
}
