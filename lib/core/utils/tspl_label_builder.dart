import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/label_dimensions.dart';

class TsplLabelBuilder {
  static const int dpi = 203;
  static const String _logoAssetPath = 'assets/images/logo.png';
  static const String _madeInEgyptAssetPath =
      'assets/images/made_in_egypt.jpeg';

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

    // 👇 تتحكم في عرض الباركود من هنا
    int fixedBarcodeWidth = 400,
  }) async {
    await _loadResources();

    final result = <int>[];
    final densityValue = density.clamp(1, 15);

    final barcodeType = _detectTsplBarcodeType(barcode);

    final barcodeHeight = (labelHeightDots * 0.24).round().clamp(130, 300);

    // Keep side margins so barcode can always be visually centered.
    const barcodeSidePaddingDots = 14;
    final maxBarcodeDrawableWidth = (labelWidthDots -
            (barcodeSidePaddingDots * 2))
        .clamp(120, labelWidthDots);
    // ✅ تثبيت عرض الباركود يدويًا ضمن المساحة المتاحة الفعلية
    final barcodeTargetWidth = fixedBarcodeWidth.clamp(
      120,
      maxBarcodeDrawableWidth,
    );

    final scaled = _scaleBarcodeToTargetWidth(
      barcode,
      barcodeType: barcodeType,
      targetWidthDots: barcodeTargetWidth,
    );

    final narrow = scaled.narrow;
    final wide = scaled.wide;
    final barcodeWidth = scaled.widthDots;

    // ✅ توسيط الباركود أفقيًا ومنع x السالب
    final barcodeX = ((labelWidthDots - barcodeWidth) ~/ 2).clamp(
      barcodeSidePaddingDots,
      labelWidthDots,
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
    const variantToBarcodeGapDots = 16;

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

    // ============================================================
    // ✅ الباركود يُثبَّت في منتصف الورقة رأسيًا — مستقل عن حجم نص المتغير
    // ============================================================
    const barcodeHumanTextHeightDots = 44;
    const barcodeHumanTextGapDots = 10;
    const madeInEgyptGapAfterBarcodeDots = 28;
    const madeInEgyptBottomMarginDots = 8;

    final barcodeBlockHeight =
        barcodeHeight + barcodeHumanTextGapDots + barcodeHumanTextHeightDots;

    final barcodeY = ((labelHeightDots - barcodeBlockHeight) ~/ 2).clamp(
      0,
      labelHeightDots - barcodeBlockHeight,
    );

    final barcodeDigitsY = barcodeY + barcodeHeight + barcodeHumanTextGapDots;

    // ============================================================
    // نص المتغير يملأ المسافة بين اسم المنتج وبداية الباركود تلقائيًا
    // ============================================================
    final productNameEndY =
        topTextY + productNameBlockHeightDots + productNameToVariantGapDots;

    final bottomTextX = _centerBitmapX(bottomTextWidthDots);
    final bottomTextY = productNameEndY;

    final availableForVariant = (barcodeY -
            variantToBarcodeGapDots -
            bottomTextY)
        .clamp(0, labelHeightDots);
    final bottomTextHeight =
        hasBottomText ? availableForVariant.clamp(60, 220) : 0;

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

    // ============================================================
    // "Made in Egypt" تحت الباركود مباشرة
    // ============================================================
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

    final madeInEgyptY = (barcodeDigitsY +
            barcodeHumanTextHeightDots +
            madeInEgyptGapAfterBarcodeDots)
        .clamp(
          0,
          labelHeightDots - madeInEgyptHeightDots - madeInEgyptBottomMarginDots,
        );

    // ============================================================
    // TSPL commands
    // ============================================================
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

    /// ✅ BARCODE (في المنتصف رأسيًا وأفقيًا بعرض ثابت)
    _addCommand(
      result,
      'BARCODE $barcodeX,$barcodeY,"$barcodeType",$barcodeHeight,0,0,$narrow,$wide,"$barcode"',
    );

    /// الرقم تحت الباركود
    _addCommand(
      result,
      'BLOCK $barcodeX,$barcodeDigitsY,$barcodeWidth,$barcodeHumanTextHeightDots,"3",0,1,1,1,"$barcode"',
    );

    /// MADE IN EGYPT
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
      'SIZE ${LabelDimensions.widthMm.toStringAsFixed(1)} mm,${LabelDimensions.heightMm.toStringAsFixed(1)} mm',
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

  /// Widen module bars until the barcode approaches full label width (centered).
  static ({int narrow, int wide, int widthDots}) _scaleBarcodeToTargetWidth(
    String barcode, {
    required String barcodeType,
    required int targetWidthDots,
  }) {
    final minNarrow = barcodeType == '128' ? 2 : 2;
    const maxNarrow = 16;
    const maxWide128 = 34;
    final baseW = _estimateBarcodeWidthDots(
      barcode,
      barcodeType: barcodeType,
      narrow: 3,
      wide: barcodeType == '128' ? 4 : 3,
    );
    final scale = targetWidthDots / baseW;
    var narrow = (3 * scale).round().clamp(minNarrow, maxNarrow);
    var wide =
        barcodeType == '128' ? (narrow * 2).clamp(4, maxWide128) : narrow;

    int currentWidth() => _estimateBarcodeWidthDots(
      barcode,
      barcodeType: barcodeType,
      narrow: narrow,
      wide: wide,
    );

    while (currentWidth() < targetWidthDots && narrow < maxNarrow) {
      narrow++;
      if (barcodeType == '128') {
        wide = (narrow * 2).clamp(4, maxWide128);
      } else {
        wide = narrow;
      }
    }

    while (narrow > minNarrow && currentWidth() > targetWidthDots) {
      narrow--;
      if (barcodeType == '128') {
        wide = (narrow * 2).clamp(4, maxWide128);
      } else {
        wide = narrow;
      }
    }

    return (narrow: narrow, wide: wide, widthDots: currentWidth());
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
