import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;

/// Arabic fonts used to render labels (PDF + TSPL bitmaps).
///
/// Bundled as assets so label generation works offline. The files are the
/// exact same TTFs that `PdfGoogleFonts` used to download at runtime, so the
/// printed output is unchanged.
class LabelFonts {
  LabelFonts._();

  static const String _dir = 'assets/fonts/label';
  static const String tajawalRegularAsset = '$_dir/tajawal_regular.ttf';
  static const String tajawalBoldAsset = '$_dir/tajawal_bold.ttf';
  static const String notoSansArabicRegularAsset =
      '$_dir/noto_sans_arabic_regular.ttf';
  static const String notoSansArabicBoldAsset =
      '$_dir/noto_sans_arabic_bold.ttf';

  static final Map<String, pw.Font> _cache = {};

  static Future<pw.Font> tajawalRegular() => _load(tajawalRegularAsset);
  static Future<pw.Font> tajawalBold() => _load(tajawalBoldAsset);
  static Future<pw.Font> notoSansArabicRegular() =>
      _load(notoSansArabicRegularAsset);
  static Future<pw.Font> notoSansArabicBold() =>
      _load(notoSansArabicBoldAsset);

  static Future<pw.Font> _load(String asset) async {
    final cached = _cache[asset];
    if (cached != null) return cached;
    final data = await rootBundle.load(asset);
    return _cache[asset] = pw.Font.ttf(data);
  }
}
