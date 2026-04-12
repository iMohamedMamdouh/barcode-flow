import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/utils/barcode_helper.dart';
import '../../domain/repos/printing_repo.dart';

class PrintingRepoImpl implements PrintingRepo {
  pw.Font? _arabicRegular;
  pw.Font? _arabicBold;

  Future<void> _loadFonts() async {
    _arabicRegular ??= await PdfGoogleFonts.tajawalRegular();
    _arabicBold ??= await PdfGoogleFonts.tajawalBold();
  }

  @override
  Future<Uint8List> generatePdfLabel({
    required String companyName,
    required String productName,
    required String barcode,
    String? sku,
    required int quantity,
    required LabelSize labelSize,
  }) async {
    await _loadFonts();

    final pdf = pw.Document();

    final pageWidth = labelSize.widthMm * PdfPageFormat.mm;
    final pageHeight = labelSize.heightMm * PdfPageFormat.mm;

    final pageFormat = PdfPageFormat(
      pageWidth,
      pageHeight,
      marginAll: 2 * PdfPageFormat.mm,
    );

    final barcodeType = BarcodeHelper.detectType(barcode);
    final isSmall = labelSize == LabelSize.small;

    final boldStyle = pw.TextStyle(
      font: _arabicBold,
      fontFallback: [_arabicRegular!],
      fontSize: isSmall ? 6 : 8,
    );

    final regularStyle = pw.TextStyle(
      font: _arabicRegular,
      fontFallback: [_arabicBold!],
      fontSize: isSmall ? 5 : 7,
    );

    final smallStyle = pw.TextStyle(
      font: _arabicRegular,
      fontSize: isSmall ? 4 : 5,
    );

    for (int i = 0; i < quantity; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          textDirection: pw.TextDirection.rtl,
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  companyName,
                  style: boldStyle,
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl,
                ),
                pw.SizedBox(height: isSmall ? 1 : 2),
                pw.Text(
                  productName,
                  style: regularStyle,
                  textAlign: pw.TextAlign.center,
                  textDirection: pw.TextDirection.rtl,
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
                if (sku != null) ...[
                  pw.SizedBox(height: 1),
                  pw.Text(
                    sku,
                    style: smallStyle,
                    textAlign: pw.TextAlign.center,
                  ),
                ],
                pw.SizedBox(height: isSmall ? 2 : 3),
                pw.BarcodeWidget(
                  barcode: barcodeType,
                  data: barcode,
                  width: isSmall ? 38 * PdfPageFormat.mm : 56 * PdfPageFormat.mm,
                  height: isSmall ? 12 * PdfPageFormat.mm : 16 * PdfPageFormat.mm,
                  drawText: true,
                  textStyle: pw.TextStyle(
                    font: _arabicRegular,
                    fontSize: isSmall ? 5 : 6,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }
}
