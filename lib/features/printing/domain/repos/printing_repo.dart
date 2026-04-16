import 'dart:typed_data';

abstract class PrintingRepo {
  /// Current label size = 40 × 30 mm
  static const double labelWidthMm = 40;
  static const double labelHeightMm = 30;

  Future<Uint8List> generatePdfLabel({
    required String productName,
    required String barcode,
    String? variantName,
    String? imageBase64,
    required int quantity,
  });
}
