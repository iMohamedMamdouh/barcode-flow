import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';

class TsplLabelBuilder {
  static const int dpi = 203;
  static const double labelWidthInch = 4.0;
  static const double labelHeightInch = 6.0;

  static int get labelWidthDots => (labelWidthInch * dpi).round();
  static int get labelHeightDots => (labelHeightInch * dpi).round();

  /// Converts PDF → raster image → TSPL commands with bitmap
  static Future<List<int>> buildFromPdf(
    Uint8List pdfData, {
    int quantity = 1,
    double gapMm = 3.0,
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

    return _buildTsplBytes(
      labelImage,
      quantity: quantity,
      gapMm: gapMm,
    );
  }

  static List<int> _buildTsplBytes(
    img.Image image, {
    required int quantity,
    required double gapMm,
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

    _addCommand(result, 'SIZE $labelWidthInch,$labelHeightInch');
    _addCommand(result, 'GAP ${gapMm.toStringAsFixed(1)} mm,0');
    _addCommand(result, 'SPEED 4');
    _addCommand(result, 'DENSITY 8');
    _addCommand(result, 'DIRECTION 0');
    _addCommand(result, 'CLS');

    _addRaw(result, 'BITMAP 0,0,$widthBytes,$labelHeightDots,0,');
    result.addAll(monoBytes);

    _addCommand(result, 'PRINT $quantity,1');

    return result;
  }

  static void _addCommand(List<int> buffer, String cmd) {
    buffer.addAll(utf8.encode('$cmd\r\n'));
  }

  static void _addRaw(List<int> buffer, String text) {
    buffer.addAll(utf8.encode(text));
  }

  /// Convert image to 1-bit monochrome bitmap (MSB first, dark pixel = 1).
  /// Assumes the image has already been composited on a white background.
  static Uint8List _imageToMonoBitmap(img.Image image) {
    final width = image.width;
    final height = image.height;
    final widthBytes = (width + 7) ~/ 8;
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

        // Dark pixel → bit 1 → black dot on label
        if (luminance < 128) {
          final byteIndex = y * widthBytes + (x ~/ 8);
          final bitIndex = 7 - (x % 8);
          data[byteIndex] |= (1 << bitIndex);
        }
      }
    }

    return data;
  }
}
