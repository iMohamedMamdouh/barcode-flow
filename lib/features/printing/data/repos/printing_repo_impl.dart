import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/barcode_helper.dart';
import '../../domain/repos/printing_repo.dart';

class PrintingRepoImpl implements PrintingRepo {
  pw.Font? _arabicRegular;
  pw.Font? _arabicBold;
  pw.Font? _notoArabicRegular;
  pw.Font? _notoArabicBold;
  pw.MemoryImage? _logoImage;

  List<pw.Font> get _fallbackFonts => [
        _arabicRegular!,
        _arabicBold!,
        _notoArabicRegular!,
        _notoArabicBold!,
        pw.Font.helvetica(),
        pw.Font.helveticaBold(),
      ];

  Future<void> _loadAssets() async {
    _arabicRegular ??= await PdfGoogleFonts.tajawalRegular();
    _arabicBold ??= await PdfGoogleFonts.tajawalBold();
    _notoArabicRegular ??= await PdfGoogleFonts.notoSansArabicRegular();
    _notoArabicBold ??= await PdfGoogleFonts.notoSansArabicBold();
    if (_logoImage == null) {
      final logoData = await rootBundle.load('assets/images/logo.png');
      _logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    }
  }

  @override
  Future<Uint8List> generatePdfLabel({
    required String productName,
    required String barcode,
    String? variantName,
    String? imageBase64,
    required int quantity,
  }) async {
    await _loadAssets();

    final pdf = pw.Document();

    final pageFormat = PdfPageFormat(
      PrintingRepo.labelWidthMm * PdfPageFormat.mm,
      PrintingRepo.labelHeightMm * PdfPageFormat.mm,
      marginAll: 5 * PdfPageFormat.mm,
    );

    final barcodeType = BarcodeHelper.detectType(barcode);

    final barcodeTextStyle = pw.TextStyle(
      font: _arabicRegular,
      fontFallback: _fallbackFonts,
      fontSize: 10,
      letterSpacing: 1.5,
    );

    for (int i = 0; i < quantity; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  // Temporarily hide all non-barcode content in the PDF label.
                  // pw.Image(
                  //   _logoImage!,
                  //   width: 45 * PdfPageFormat.mm,
                  //   fit: pw.BoxFit.contain,
                  // ),
                  // pw.SizedBox(height: 14),
                  // pw.SizedBox(
                  //   width: double.infinity,
                  //   child: pw.Text(
                  //     productName,
                  //     style: productNameStyle,
                  //     textAlign: pw.TextAlign.center,
                  //     textDirection: pw.TextDirection.rtl,
                  //     maxLines: 3,
                  //     overflow: pw.TextOverflow.clip,
                  //   ),
                  // ),
                  // if (variantName != null && variantName.isNotEmpty) ...[
                  //   pw.SizedBox(height: 6),
                  //   pw.SizedBox(
                  //     width: double.infinity,
                  //     child: pw.Text(
                  //       variantName,
                  //       style: variantStyle,
                  //       textAlign: pw.TextAlign.center,
                  //       textDirection: pw.TextDirection.rtl,
                  //       maxLines: 2,
                  //       overflow: pw.TextOverflow.clip,
                  //     ),
                  //   ),
                  // ],
                  pw.BarcodeWidget(
                    barcode: barcodeType,
                    data: barcode,
                    width: 34 * PdfPageFormat.mm,
                    height: 16 * PdfPageFormat.mm,
                    drawText: true,
                    textStyle: barcodeTextStyle,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
