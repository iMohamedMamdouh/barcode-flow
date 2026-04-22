import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TsplLabelBuilder {
  static const int dpi = 203;
  static const double labelWidthMm = 75;
  static const double labelHeightMm = 130;
  static const String _logoAssetPath = 'assets/images/logo.png';
  static const String _madeInEgyptAssetPath =
      'assets/images/made_in_egypt.jpeg';

  // نسبة أبعاد اللوجو الأصلية 874/306
  static const double _logoAspectRatio = 874.0 / 306.0;

  static int get labelWidthDots => (labelWidthMm / 25.4 * dpi).round();
  static int get labelHeightDots => (labelHeightMm / 25.4 * dpi).round();
  static pw.Font? _fontBold;
  static pw.Font? _fontRegular;
  static pw.Font? _fontNotoBold;
  static pw.Font? _fontNotoRegular;
  static pw.MemoryImage? _logoImage;
  static pw.MemoryImage? _madeInEgyptImage;

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

    final composited = _compositeOnWhite(labelImage);

    return _buildTsplBytes(
      composited,
      quantity: quantity,
      gapMm: gapMm,
      density: density,
    );
  }

  // ignore: unused_element
  static Future<void> _loadResources() async {
    _fontBold ??= await PdfGoogleFonts.tajawalBold();
    _fontRegular ??= await PdfGoogleFonts.tajawalRegular();
    _fontNotoBold ??= await PdfGoogleFonts.notoSansArabicBold();
    _fontNotoRegular ??= await PdfGoogleFonts.notoSansArabicRegular();
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
    int horizontalMarginDots = 16,
  }) async {
    await _loadResources();

    final result = <int>[];
    final densityValue = density.clamp(1, 15);
    final barcodeType = _detectTsplBarcodeType(barcode);
    final barcodeHeight = (labelHeightDots * 0.24).round().clamp(130, 300);
    final leftMargin = ((horizontalMarginDots.clamp(0, 120) ~/ 8) * 8).clamp(
      0,
      labelWidthDots - 8,
    );
    final barcodeTargetWidth = (labelWidthDots - (leftMargin * 2)).clamp(
      160,
      labelWidthDots,
    );
    final baseBarcodeWidth = _estimateBarcodeWidthDots(
      barcode,
      barcodeType: barcodeType,
      narrow: 3,
      wide: barcodeType == '128' ? 6 : 3,
    );
    final widthScale = barcodeTargetWidth / baseBarcodeWidth;
    final narrow = (3 * widthScale).round().clamp(3, 7);
    final wide = barcodeType == '128' ? (narrow * 2).clamp(6, 14) : narrow;
    final barcodeWidth = _estimateBarcodeWidthDots(
      barcode,
      barcodeType: barcodeType,
      narrow: narrow,
      wide: wide,
    );
    final barcodeX = ((labelWidthDots - barcodeWidth) ~/ 2).clamp(
      leftMargin,
      (labelWidthDots - leftMargin - barcodeWidth).clamp(
        leftMargin,
        labelWidthDots,
      ),
    );
    final textAreaWidthDots = (labelWidthDots - (leftMargin * 2)).clamp(
      8,
      labelWidthDots,
    );
    final textAreaWidthBytes = (textAreaWidthDots ~/ 8).clamp(
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
    final logoX = ((labelWidthDots - logoWidthDots) ~/ 2).clamp(
      0,
      labelWidthDots - 8,
    );
    final logoY = (labelHeightDots * 0.045).round();
    final logoWidthBytes = (logoWidthDots ~/ 8).clamp(1, labelWidthDots ~/ 8);
    final logoWidthAlignedDots = logoWidthBytes * 8;
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
    final topTextX = 0;
    final topTextY = logoY + logoHeightDots + 14;
    final topTextWidth = labelWidthDots;
    final bottomTextWidthBytes = (labelWidthDots ~/ 8).clamp(
      1,
      labelWidthDots ~/ 8,
    );
    final bottomTextWidthDots = bottomTextWidthBytes * 8;
    final bottomTextX = ((labelWidthDots - bottomTextWidthDots) ~/ 2).clamp(
      0,
      labelWidthDots - 8,
    );
    final bottomTextY = (topTextY + 84).clamp(0, labelHeightDots - 280);
    const bottomTextHeight = 160;
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
    final madeInEgyptX = ((labelWidthDots - madeInEgyptWidthAlignedDots) ~/ 2)
        .clamp(0, labelWidthDots - 8);
    final madeInEgyptY = (labelHeightDots - madeInEgyptHeightDots - 14).clamp(
      bottomTextY + bottomTextHeight + 6,
      labelHeightDots - madeInEgyptHeightDots,
    );
    final madeInEgyptBitmap = await _renderMadeInEgyptAsBitmap(
      widthDots: madeInEgyptWidthAlignedDots,
      heightDots: madeInEgyptHeightDots,
      threshold: threshold,
    );
    final barcodeTopY =
        hasBottomText ? (bottomTextY + bottomTextHeight + 16) : (topTextY + 92);
    final barcodeY = barcodeTopY.clamp(
      0,
      (madeInEgyptY - barcodeHeight - 16).clamp(0, labelHeightDots),
    );

    _addCommand(
      result,
      'SIZE ${labelWidthMm.toStringAsFixed(1)} mm,${labelHeightMm.toStringAsFixed(1)} mm',
    );
    _addCommand(result, 'GAP ${gapMm.toStringAsFixed(1)} mm,0');
    _addCommand(result, 'SPEED 4');
    _addCommand(result, 'DENSITY $densityValue');
    _addCommand(result, 'DIRECTION 0');
    _addCommand(result, 'REFERENCE 0,0');
    _addCommand(result, 'CODEPAGE UTF-8');
    _addCommand(result, 'CLS');

    _addRaw(result, 'BITMAP $logoX,$logoY,$logoWidthBytes,$logoHeightDots,0,');
    result.addAll(logoBitmap);
    _addRaw(result, '\r\n');

    _addCommand(
      result,
      'BLOCK $topTextX,$topTextY,$topTextWidth,150,"3",0,1,1,2,"$topText"',
    );

    if (hasBottomText && bottomTextBitmap != null) {
      _addRaw(
        result,
        'BITMAP $bottomTextX,$bottomTextY,$bottomTextWidthBytes,$bottomTextHeight,0,',
      );
      result.addAll(bottomTextBitmap);
      _addRaw(result, '\r\n');
    }

    _addCommand(
      result,
      'BARCODE $barcodeX,$barcodeY,"$barcodeType",$barcodeHeight,1,0,$narrow,$wide,"$barcode"',
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

  // ignore: unused_element
  static Future<Uint8List> _renderHeaderAsBitmap({
    required String productName,
    String? variantName,
    required int widthDots,
    required int heightDots,
    required int threshold,
  }) async {
    // ✅ احسب أبعاد اللوجو بالـ dots من النسبة الأصلية
    final logoHeightDots = (heightDots * 0.30).round().clamp(40, 120);
    final logoWidthDots = (logoHeightDots * _logoAspectRatio).round();

    // ✅ لو العرض أكبر من المتاح، قلص مع الحفاظ على النسبة
    final finalLogoWidthDots = logoWidthDots.clamp(1, widthDots);
    final finalLogoHeightDots = (finalLogoWidthDots / _logoAspectRatio).round();

    // ✅ حول dots → mm للـ PDF
    final logoWmm = finalLogoWidthDots / dpi * 25.4;
    final logoHmm = finalLogoHeightDots / dpi * 25.4;

    final widthMm = widthDots / dpi * 25.4;
    final heightMm = heightDots / dpi * 25.4;
    final productFontSize = (heightMm * 0.11).clamp(8.0, 12.0);
    final variantFontSize = (heightMm * 0.08).clamp(7.0, 10.0);

    final rasterDpi = (dpi * 2).toDouble();
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
            alignment: pw.Alignment.topCenter,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (_logoImage != null)
                  // ✅ SizedBox بأبعاد دقيقة من النسبة الأصلية - fit.contain لضمان عدم التمديد
                  pw.SizedBox(
                    width: logoWmm * PdfPageFormat.mm,
                    height: logoHmm * PdfPageFormat.mm,
                    child: pw.Image(
                      _logoImage!,
                      fit: pw.BoxFit.contain, // ✅ contain وليس fill
                    ),
                  ),
                pw.SizedBox(height: 2),
                pw.Text(
                  productName,
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl,
                  maxLines: 3,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    font: _fontBold,
                    fontFallback: [
                      _fontNotoRegular!,
                      _fontRegular!,
                      pw.Font.helveticaBold(),
                    ],
                    fontSize: productFontSize,
                  ),
                ),
                if (variantName != null) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    variantName,
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                    maxLines: 3,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      font: _fontRegular,
                      fontFallback: [
                        _fontNotoBold!,
                        _fontBold!,
                        pw.Font.helvetica(),
                      ],
                      fontSize: variantFontSize,
                      color: PdfColors.grey800,
                    ),
                  ),
                ],
              ],
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

    // ✅ resize الهيدر كامل فقط - اللوجو محمي بالـ SizedBox بداخله
    final rendered = img.copyResize(
      composited,
      width: widthDots,
      height: heightDots,
      interpolation: img.Interpolation.linear,
    );

    return _imageToMonoBitmap(rendered, threshold: threshold.clamp(0, 255));
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
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                  lineSpacing: 1.1,
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
    if (length <= 36) return 11;
    if (length <= 55) return 10;
    if (length <= 75) return 9;
    return 8;
  }

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
    img.fill(result, color: img.ColorRgba8(255, 255, 255, 255));
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

  static String _detectTsplBarcodeType(String data) {
    if (RegExp(r'^\d{13}$').hasMatch(data) && _isValidEan13(data)) {
      return 'EAN13';
    }
    if (RegExp(r'^\d{8}$').hasMatch(data) && _isValidEan8(data)) {
      return 'EAN8';
    }
    return '128';
  }

  static int _estimateBarcodeWidthDots(
    String barcode, {
    required String barcodeType,
    required int narrow,
    required int wide,
  }) {
    switch (barcodeType) {
      case 'EAN13':
        return 95 * narrow + 24;
      case 'EAN8':
        return 67 * narrow + 24;
      default:
        return ((barcode.length * 11) + 35) * (narrow + wide) ~/ 2;
    }
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
