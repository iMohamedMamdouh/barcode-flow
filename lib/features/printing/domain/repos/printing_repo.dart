import 'dart:typed_data';

abstract class PrintingRepo {
  /// 4×6 inch label = 101.6 × 152.4 mm
  static const double labelWidthMm = 101.6;
  static const double labelHeightMm = 152.4;

  Future<Uint8List> generatePdfLabel({
    required String productName,
    required String barcode,
    String? variantName,
    String? imageBase64,
    required int quantity,
  });
}
