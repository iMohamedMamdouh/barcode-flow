import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

class TsplLabelBuilder {
  static const int dpi = 203;
  static const double labelWidthMm = 101.6; // 4 inch
  static const double labelHeightMm = 152.4; // 6 inch

  static int get labelWidthDots => (labelWidthMm / 25.4 * dpi).round();
  static int get labelHeightDots => (labelHeightMm / 25.4 * dpi).round();

  /// Converts PDF → raster image → TSPL commands with bitmap
  static Future<List<int>> buildFromPdf(
    Uint8List pdfData, {
    int quantity = 1,
    double gapMm = 3.0,
    int density = 8,
  }) async {
    final rasterPages = Printing.raster(
      pdfData,
      pages: [0],
      dpi: dpi.toDouble(),
    );

    img.Image? labelImage;
    await for (final page in rasterPages) {
      final pngBytes = await page.toPng();
      labelImage = img.decodePng(pngBytes);
      break;
    }

    if (labelImage == null) {
      throw Exception('Failed to rasterize PDF');
    }

    // Composite on white background to handle transparency
    final composited = _compositeOnWhite(labelImage);

    return _buildTsplBytes(
      composited,
      quantity: quantity,
      gapMm: gapMm,
      density: density,
    );
  }

  /// Creates a thermal-like monochrome preview image from the same
  /// rasterization pipeline used for TSPL printing.
  static Future<Uint8List> buildThermalPreviewFromPdf(
    Uint8List pdfData, {
    int threshold = 128,
  }) async {
    final rasterPages = Printing.raster(
      pdfData,
      pages: [0],
      dpi: dpi.toDouble(),
    );

    img.Image? labelImage;
    await for (final page in rasterPages) {
      final pngBytes = await page.toPng();
      labelImage = img.decodePng(pngBytes);
      break;
    }

    if (labelImage == null) {
      throw Exception('Failed to rasterize PDF');
    }

    final composited = _compositeOnWhite(labelImage);
    final resized = img.copyResize(
      composited,
      width: labelWidthDots,
      height: labelHeightDots,
      interpolation: img.Interpolation.average,
    );
    final preview = _toMonochromePreviewImage(
      resized,
      threshold: threshold.clamp(0, 255),
    );
    final png = img.encodePng(preview);
    return Uint8List.fromList(png);
  }

  static img.Image _compositeOnWhite(img.Image source) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);

    // Fill with white
    img.fill(result, color: img.ColorRgba8(255, 255, 255, 255));

    // Draw source on top (composites alpha automatically)
    img.compositeImage(result, source);

    return result;
  }

  static List<int> _buildTsplBytes(
    img.Image image, {
    required int quantity,
    required double gapMm,
    required int density,
  }) {
    final resized = img.copyResize(
      image,
      width: labelWidthDots,
      height: labelHeightDots,
      interpolation: img.Interpolation.average,
    );

    final monoBytes = _imageToMonoBitmap(resized);
    final widthBytes = (labelWidthDots + 7) ~/ 8;

    final result = <int>[];

    // ✅ SIZE بالـ mm لضمان التوافق مع XPrinter
    _addCommand(
      result,
      'SIZE ${labelWidthMm.toStringAsFixed(1)} mm,${labelHeightMm.toStringAsFixed(1)} mm',
    );
    _addCommand(result, 'GAP ${gapMm.toStringAsFixed(1)} mm,0');
    _addCommand(result, 'SPEED 4');
    final densityValue = density.clamp(1, 15);
    _addCommand(result, 'DENSITY $densityValue');
    _addCommand(result, 'DIRECTION 0');
    _addCommand(result, 'CLS');

    // ✅ mode=1 لتجنب الخطوط بالعرض
    _addRaw(result, 'BITMAP 0,0,$widthBytes,$labelHeightDots,1,');
    result.addAll(monoBytes);
    _addRaw(result, '\r\n');

    _addCommand(result, 'PRINT $quantity,1');

    return result;
  }

  static void _addCommand(List<int> buffer, String cmd) {
    buffer.addAll(utf8.encode('$cmd\r\n'));
  }

  static void _addRaw(List<int> buffer, String text) {
    buffer.addAll(utf8.encode(text));
  }

  /// Convert image to 1-bit monochrome bitmap.
  /// في TSPL: بت = 0 → طباعة (أسود) | بت = 1 → بدون طباعة (أبيض)
  static Uint8List _imageToMonoBitmap(img.Image image) {
    final width = image.width;
    final height = image.height;
    final widthBytes = (width + 7) ~/ 8;
    // ✅ ابدأ بكل البتات = 0 (أسود) ثم اضبط الأبيض على 1
    final data = Uint8List(widthBytes * height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        final a = pixel.a.toInt();
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        // Blend with white background for any remaining alpha
        final rr = (r * a + 255 * (255 - a)) ~/ 255;
        final gg = (g * a + 255 * (255 - a)) ~/ 255;
        final bb = (b * a + 255 * (255 - a)) ~/ 255;

        final luminance = 0.299 * rr + 0.587 * gg + 0.114 * bb;

        // ✅ إصلاح الألوان المعكوسة:
        // بكسل فاتح (أبيض) → بت = 1 (بدون طباعة)
        // بكسل داكن (أسود) → بت = 0 (طباعة) — القيمة الافتراضية
        if (luminance >= 128) {
          final byteIndex = y * widthBytes + (x ~/ 8);
          final bitIndex = 7 - (x % 8);
          data[byteIndex] |= (1 << bitIndex);
        }
      }
    }

    return data;
  }

  static img.Image _toMonochromePreviewImage(
    img.Image image, {
    required int threshold,
  }) {
    final width = image.width;
    final height = image.height;
    final result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);

        final a = pixel.a.toInt();
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        final rr = (r * a + 255 * (255 - a)) ~/ 255;
        final gg = (g * a + 255 * (255 - a)) ~/ 255;
        final bb = (b * a + 255 * (255 - a)) ~/ 255;
        final luminance = 0.299 * rr + 0.587 * gg + 0.114 * bb;

        final isBlack = luminance < threshold;
        result.setPixel(
          x,
          y,
          isBlack ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255),
        );
      }
    }

    return result;
  }
}
