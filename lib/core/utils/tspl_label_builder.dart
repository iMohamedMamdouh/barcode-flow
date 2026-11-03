import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/label_dimensions.dart';
import 'label_fonts.dart';

class TsplLabelBuilder {
  static const int dpi = 203;
  static const String _logoAssetPath = 'assets/images/logo.png';
  static const String _madeInEgyptAssetPath =
      'assets/images/made_in_egypt.jpeg';

  // نسبة أبعاد اللوجو الأصلية 874/306
  static const double _logoAspectRatio = 874.0 / 306.0;

  static int get labelWidthDots =>
      (LabelDimensions.widthMm / 25.4 * dpi).round();
  static int get labelHeightDots =>
      (LabelDimensions.heightMm / 25.4 * dpi).round();
  static pw.Font? _fontBold;
  static pw.Font? _fontRegular;
  static pw.Font? _fontNotoBold;
  static pw.Font? _fontNotoRegular;
  static pw.MemoryImage? _logoImage;
  static pw.MemoryImage? _madeInEgyptImage;

  /// Horizontal center on the label. [x] snapped to 8-dot steps (TSC BITMAP-friendly).
  static int _centerBitmapX(int bitmapWidthDots) {
    final maxX = (labelWidthDots - bitmapWidthDots).clamp(0, labelWidthDots);
    if (bitmapWidthDots <= 0 || bitmapWidthDots >= labelWidthDots) {
      return 0;
    }
    final raw = (labelWidthDots - bitmapWidthDots) ~/ 2;
    var aligned = ((raw + 4) ~/ 8) * 8;
    if (aligned > maxX) aligned = (maxX ~/ 8) * 8;
    return aligned.clamp(0, maxX);
  }

  static Future<void> _loadResources() async {
    _fontBold ??= await LabelFonts.tajawalBold();
    _fontRegular ??= await LabelFonts.tajawalRegular();
    _fontNotoBold ??= await LabelFonts.notoSansArabicBold();
    _fontNotoRegular ??= await LabelFonts.notoSansArabicRegular();
    if (_logoImage == null) {
      final logoData = await rootBundle.load(_logoAssetPath);
      _logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    }
    if (_madeInEgyptImage == null) {
      final madeInEgyptData = await rootBundle.load(_madeInEgyptAssetPath);
      _madeInEgyptImage = pw.MemoryImage(madeInEgyptData.buffer.asUint8List());
    }
  }

  static Future<List<int>> buildBarcodeLabel(
    String barcode, {
    required String productName,
    String? variantName,
    int quantity = 1,
    double gapMm = 3.0,
    int density = 8,
    int threshold = 128,

    // 👇 تتحكم في عرض الباركود من هنا
    int fixedBarcodeWidth = 240,
  }) async {
    await _loadResources();

    final result = <int>[];
    final densityValue = density.clamp(1, 15);

    final barcodeHeight = (labelHeightDots * 0.24).round().clamp(130, 300);

    final barcodeType = _detectTsplBarcodeType(barcode);
    final barcodeWidthDots = fixedBarcodeWidth.clamp(120, labelWidthDots);
    final barcodeWidthBytes = (barcodeWidthDots ~/ 8).clamp(
      1,
      labelWidthDots ~/ 8,
    );
    final barcodeWidthAlignedDots = barcodeWidthBytes * 8;
    final barcodeX = _centerBitmapX(barcodeWidthAlignedDots);
    final barcodeBitmap = await _renderBarcodeAsBitmap(
      data: barcode,
      barcodeType: barcodeType,
      widthDots: barcodeWidthAlignedDots,
      heightDots: barcodeHeight,
      threshold: threshold,
    );

    final textAreaWidthBytes = (labelWidthDots ~/ 8).clamp(
      1,
      labelWidthDots ~/ 8,
    );
    final textAreaWidthAlignedDots = textAreaWidthBytes * 8;

    final logoWidthDots = (textAreaWidthAlignedDots * 0.58).round().clamp(
      120,
      textAreaWidthAlignedDots,
    );

    final logoHeightDots = (logoWidthDots / _logoAspectRatio).round().clamp(
      36,
      90,
    );

    final logoY = (labelHeightDots * 0.045).round();

    final logoWidthBytes = (logoWidthDots ~/ 8).clamp(1, labelWidthDots ~/ 8);

    final logoWidthAlignedDots = logoWidthBytes * 8;

    final logoX = _centerBitmapX(logoWidthAlignedDots);

    final logoBitmap = await _renderLogoAsBitmap(
      widthDots: logoWidthAlignedDots,
      heightDots: logoHeightDots,
      threshold: threshold,
    );

    final topText =
        productName.trim().isEmpty
            ? 'Walnut shoe storage bench'
            : productName.trim();

    final bottomText =
        (variantName ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();

    final hasBottomText = bottomText.isNotEmpty;

    final bottomTextFontSize = _resolveArabicFontSize(bottomText);

    const logoToProductNameGapDots = 28;
    const productNameBlockHeightDots = 82;
    const productNameToVariantGapDots = 8;

    final topTextY = logoY + logoHeightDots + logoToProductNameGapDots;

    final bottomTextWidthBytes = textAreaWidthBytes;
    final bottomTextWidthDots = textAreaWidthAlignedDots;

    final productNameBitmap = await _renderTextLineAsBitmap(
      text: topText,
      widthDots: bottomTextWidthDots,
      heightDots: productNameBlockHeightDots,
      fontSize: 11,
      threshold: threshold,
      maxLines: 3,
      textDirection: pw.TextDirection.ltr,
      font: _fontBold,
      fallback: [_fontRegular, _fontNotoRegular, _fontNotoBold],
    );

    final productNameX = _centerBitmapX(bottomTextWidthDots);

    final bottomTextX = _centerBitmapX(bottomTextWidthDots);

    final bottomTextY = (topTextY +
            productNameBlockHeightDots +
            productNameToVariantGapDots)
        .clamp(0, labelHeightDots - 280);

    const bottomTextHeight = 188;

    final bottomTextBitmap =
        hasBottomText
            ? await _renderTextLineAsBitmap(
              text: bottomText,
              widthDots: bottomTextWidthDots,
              heightDots: bottomTextHeight,
              fontSize: bottomTextFontSize,
              threshold: threshold,
              maxLines: 2,
              textDirection: pw.TextDirection.rtl,
              font: _fontNotoRegular,
              fallback: [_fontNotoBold, _fontRegular, _fontBold],
              contentPadding: const pw.EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 6,
              ),
              lineSpacing: 1.22,
            )
            : null;

    final madeInEgyptWidthDots = (textAreaWidthAlignedDots * 0.54)
        .round()
        .clamp(100, textAreaWidthAlignedDots);
    final madeInEgyptHeightDots = (madeInEgyptWidthDots * 0.45).round().clamp(
      40,
      100,
    );
    final madeInEgyptWidthBytes = (madeInEgyptWidthDots ~/ 8).clamp(
      1,
      labelWidthDots ~/ 8,
    );
    final madeInEgyptWidthAlignedDots = madeInEgyptWidthBytes * 8;
    final madeInEgyptX = _centerBitmapX(madeInEgyptWidthAlignedDots);
    final madeInEgyptBitmap = await _renderMadeInEgyptAsBitmap(
      widthDots: madeInEgyptWidthAlignedDots,
      heightDots: madeInEgyptHeightDots,
      threshold: threshold,
    );

    const barcodeHumanTextHeightDots = 44;
    const barcodeHumanTextGapDots = 10;
    const madeInEgyptGapAfterBarcodeDots = 28;
    const madeInEgyptBottomMarginDots = 8;

    final barcodeTopY =
        hasBottomText ? (bottomTextY + bottomTextHeight + 16) : (topTextY + 92);
    final maxBarcodeY = (labelHeightDots -
            barcodeHeight -
            barcodeHumanTextHeightDots -
            barcodeHumanTextGapDots -
            madeInEgyptHeightDots -
            madeInEgyptGapAfterBarcodeDots -
            madeInEgyptBottomMarginDots)
        .clamp(0, labelHeightDots);
    final barcodeY = barcodeTopY.clamp(0, maxBarcodeY);

    final barcodeDigitsY = barcodeY + barcodeHeight + barcodeHumanTextGapDots;
    final madeInEgyptY = (barcodeDigitsY +
            barcodeHumanTextHeightDots +
            madeInEgyptGapAfterBarcodeDots)
        .clamp(
          0,
          labelHeightDots - madeInEgyptHeightDots - madeInEgyptBottomMarginDots,
        );

    _addCommand(
      result,
      'SIZE ${LabelDimensions.widthMm.toStringAsFixed(1)} mm,${LabelDimensions.heightMm.toStringAsFixed(1)} mm',
    );

    _addCommand(result, 'GAP ${gapMm.toStringAsFixed(1)} mm,0');
    _addCommand(result, 'SPEED 4');
    _addCommand(result, 'DENSITY $densityValue');
    _addCommand(result, 'DIRECTION 0');
    _addCommand(result, 'REFERENCE 0,0');
    _addCommand(result, 'CODEPAGE UTF-8');
    _addCommand(result, 'CLS');

    /// LOGO
    _addRaw(result, 'BITMAP $logoX,$logoY,$logoWidthBytes,$logoHeightDots,0,');
    result.addAll(logoBitmap);
    _addRaw(result, '\r\n');

    /// PRODUCT NAME
    _addRaw(
      result,
      'BITMAP $productNameX,$topTextY,$bottomTextWidthBytes,$productNameBlockHeightDots,0,',
    );
    result.addAll(productNameBitmap);
    _addRaw(result, '\r\n');

    /// VARIANT
    if (hasBottomText && bottomTextBitmap != null) {
      _addRaw(
        result,
        'BITMAP $bottomTextX,$bottomTextY,$bottomTextWidthBytes,$bottomTextHeight,0,',
      );
      result.addAll(bottomTextBitmap);
      _addRaw(result, '\r\n');
    }

    /// ✅ BARCODE (في المنتصف + عرض ثابت)
    _addCommand(
      result,
      'BITMAP $barcodeX,$barcodeY,$barcodeWidthBytes,$barcodeHeight,0,',
    );
    result.addAll(barcodeBitmap);
    _addRaw(result, '\r\n');

    /// الرقم تحت الباركود
    _addCommand(
      result,
      'BLOCK $barcodeX,$barcodeDigitsY,$barcodeWidthAlignedDots,$barcodeHumanTextHeightDots,"3",0,1,1,1,"$barcode"',
    );

    _addRaw(
      result,
      'BITMAP $madeInEgyptX,$madeInEgyptY,$madeInEgyptWidthBytes,$madeInEgyptHeightDots,0,',
    );
    result.addAll(madeInEgyptBitmap);
    _addRaw(result, '\r\n');

    _addCommand(result, 'PRINT $quantity,1');

    return result;
  }

  static Future<Uint8List> _renderTextLineAsBitmap({
    required String text,
    required int widthDots,
    required int heightDots,
    required double fontSize,
    required int threshold,
    int maxLines = 2,
    required pw.TextDirection textDirection,
    pw.Font? font,
    List<pw.Font?> fallback = const [],
    pw.EdgeInsets contentPadding = const pw.EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 6,
    ),
    double lineSpacing = 1.1,
  }) async {
    final widthMm = widthDots / dpi * 25.4;
    final heightMm = heightDots / dpi * 25.4;
    final rasterDpi = dpi.toDouble();
    final fonts = <pw.Font>[
      if (font != null) font,
      for (final item in fallback)
        if (item != null) item,
      pw.Font.helvetica(),
    ];

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          widthMm * PdfPageFormat.mm,
          heightMm * PdfPageFormat.mm,
          marginAll: 0,
        ),
        build: (_) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            padding: contentPadding,
            alignment: pw.Alignment.center,
            child: pw.Center(
              child: pw.Text(
                text,
                textAlign: pw.TextAlign.center,
                textDirection: textDirection,
                maxLines: maxLines,
                softWrap: true,
                overflow: pw.TextOverflow.clip,
                style: pw.TextStyle(
                  font: fonts.first,
                  fontFallback: fonts.skip(1).toList(),
                  fontSize: fontSize,
                  lineSpacing: lineSpacing,
                ),
              ),
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final rasterPages = Printing.raster(pdfBytes, pages: [0], dpi: rasterDpi);

    img.Image? pageImage;
    await for (final page in rasterPages) {
      final pngBytes = await page.toPng();
      pageImage = img.decodePng(pngBytes);
      break;
    }

    if (pageImage == null) {
      return Uint8List(((widthDots + 7) ~/ 8) * heightDots);
    }

    final composited = _compositeOnWhite(pageImage);
    final rendered =
        (composited.width == widthDots && composited.height == heightDots)
            ? composited
            : img.copyResize(
              composited,
              width: widthDots,
              height: heightDots,
              interpolation: img.Interpolation.average,
            );
    return _imageToMonoBitmap(rendered, threshold: threshold.clamp(0, 255));
  }

  static Future<Uint8List> _renderLogoAsBitmap({
    required int widthDots,
    required int heightDots,
    required int threshold,
  }) async {
    if (_logoImage == null) {
      return Uint8List(((widthDots + 7) ~/ 8) * heightDots);
    }

    final widthMm = widthDots / dpi * 25.4;
    final heightMm = heightDots / dpi * 25.4;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          widthMm * PdfPageFormat.mm,
          heightMm * PdfPageFormat.mm,
          marginAll: 0,
        ),
        build: (_) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            alignment: pw.Alignment.center,
            child: pw.Image(_logoImage!, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final rasterPages = Printing.raster(
      pdfBytes,
      pages: [0],
      dpi: dpi.toDouble(),
    );

    img.Image? pageImage;
    await for (final page in rasterPages) {
      final pngBytes = await page.toPng();
      pageImage = img.decodePng(pngBytes);
      break;
    }

    if (pageImage == null) {
      return Uint8List(((widthDots + 7) ~/ 8) * heightDots);
    }

    final composited = _compositeOnWhite(pageImage);
    final rendered =
        (composited.width == widthDots && composited.height == heightDots)
            ? composited
            : img.copyResize(
              composited,
              width: widthDots,
              height: heightDots,
              interpolation: img.Interpolation.average,
            );

    return _imageToMonoBitmap(rendered, threshold: threshold.clamp(0, 255));
  }

  static Future<Uint8List> _renderBarcodeAsBitmap({
    required String data,
    required String barcodeType,
    required int widthDots,
    required int heightDots,
    required int threshold,
  }) async {
    final widthMm = widthDots / dpi * 25.4;
    final heightMm = heightDots / dpi * 25.4;
    final barcodeSpec = switch (barcodeType) {
      'EAN13' => pw.Barcode.ean13(),
      'EAN8' => pw.Barcode.ean8(),
      _ => pw.Barcode.code128(),
    };

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          widthMm * PdfPageFormat.mm,
          heightMm * PdfPageFormat.mm,
          marginAll: 0,
        ),
        build: (_) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            alignment: pw.Alignment.center,
            child: pw.BarcodeWidget(
              data: data,
              barcode: barcodeSpec,
              drawText: false,
              width: widthMm * PdfPageFormat.mm,
              height: heightMm * PdfPageFormat.mm,
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final rasterPages = Printing.raster(
      pdfBytes,
      pages: [0],
      dpi: dpi.toDouble(),
    );

    img.Image? pageImage;
    await for (final page in rasterPages) {
      final pngBytes = await page.toPng();
      pageImage = img.decodePng(pngBytes);
      break;
    }

    if (pageImage == null) {
      return Uint8List(((widthDots + 7) ~/ 8) * heightDots);
    }

    final composited = _compositeOnWhite(pageImage);
    final rendered =
        (composited.width == widthDots && composited.height == heightDots)
            ? composited
            : img.copyResize(
              composited,
              width: widthDots,
              height: heightDots,
              interpolation: img.Interpolation.average,
            );

    return _imageToMonoBitmap(rendered, threshold: threshold.clamp(0, 255));
  }

  static Future<Uint8List> _renderMadeInEgyptAsBitmap({
    required int widthDots,
    required int heightDots,
    required int threshold,
  }) async {
    if (_madeInEgyptImage == null) {
      return Uint8List(((widthDots + 7) ~/ 8) * heightDots);
    }

    final widthMm = widthDots / dpi * 25.4;
    final heightMm = heightDots / dpi * 25.4;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          widthMm * PdfPageFormat.mm,
          heightMm * PdfPageFormat.mm,
          marginAll: 0,
        ),
        build: (_) {
          return pw.Container(
            width: double.infinity,
            height: double.infinity,
            alignment: pw.Alignment.center,
            child: pw.Image(_madeInEgyptImage!, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    final rasterPages = Printing.raster(
      pdfBytes,
      pages: [0],
      dpi: dpi.toDouble(),
    );

    img.Image? pageImage;
    await for (final page in rasterPages) {
      final pngBytes = await page.toPng();
      pageImage = img.decodePng(pngBytes);
      break;
    }

    if (pageImage == null) {
      return Uint8List(((widthDots + 7) ~/ 8) * heightDots);
    }

    final composited = _compositeOnWhite(pageImage);
    final rendered =
        (composited.width == widthDots && composited.height == heightDots)
            ? composited
            : img.copyResize(
              composited,
              width: widthDots,
              height: heightDots,
              interpolation: img.Interpolation.average,
            );

    return _imageToMonoBitmap(rendered, threshold: threshold.clamp(0, 255));
  }

  static double _resolveArabicFontSize(String text) {
    final length = text.length;
    if (length <= 32) return 13;
    if (length <= 48) return 12;
    if (length <= 68) return 11;
    if (length <= 90) return 10;
    return 9;
  }

  static img.Image _compositeOnWhite(img.Image source) {
    final w = source.width;
    final h = source.height;
    final result = img.Image(width: w, height: h);
    img.fill(result, color: img.ColorRgba8(255, 255, 255, 255));
    img.compositeImage(result, source);
    return result;
  }

  static void _addCommand(List<int> buffer, String cmd) {
    buffer.addAll(utf8.encode('$cmd\r\n'));
  }

  static void _addRaw(List<int> buffer, String text) {
    buffer.addAll(utf8.encode(text));
  }

  static String _detectTsplBarcodeType(String data) {
    if (RegExp(r'^\d{13}$').hasMatch(data) && _isValidEan13(data)) {
      return 'EAN13';
    }
    if (RegExp(r'^\d{8}$').hasMatch(data) && _isValidEan8(data)) {
      return 'EAN8';
    }
    return '128';
  }

  static bool _isValidEan13(String data) {
    final digits = data.codeUnits.map((c) => c - 48).toList();
    int sum = 0;
    for (int i = 0; i < 12; i++) {
      sum += digits[i] * (i.isEven ? 1 : 3);
    }
    final checksum = (10 - (sum % 10)) % 10;
    return digits[12] == checksum;
  }

  static bool _isValidEan8(String data) {
    final digits = data.codeUnits.map((c) => c - 48).toList();
    int sum = 0;
    for (int i = 0; i < 7; i++) {
      sum += digits[i] * (i.isEven ? 3 : 1);
    }
    final checksum = (10 - (sum % 10)) % 10;
    return digits[7] == checksum;
  }

  static Uint8List _imageToMonoBitmap(img.Image image, {int threshold = 128}) {
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

        final rr = (r * a + 255 * (255 - a)) ~/ 255;
        final gg = (g * a + 255 * (255 - a)) ~/ 255;
        final bb = (b * a + 255 * (255 - a)) ~/ 255;

        final luminance = 0.299 * rr + 0.587 * gg + 0.114 * bb;

        if (luminance >= threshold) {
          final byteIndex = y * widthBytes + (x ~/ 8);
          final bitIndex = 7 - (x % 8);
          data[byteIndex] |= (1 << bitIndex);
        }
      }
    }

    return data;
  }
}
