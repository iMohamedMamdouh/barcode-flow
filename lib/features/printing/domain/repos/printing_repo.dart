import 'dart:typed_data';

enum LabelSize {
  small('50 × 30 mm', 50, 30),
  medium('70 × 40 mm', 70, 40);

  final String displayName;
  final double widthMm;
  final double heightMm;

  const LabelSize(this.displayName, this.widthMm, this.heightMm);
}

abstract class PrintingRepo {
  Future<Uint8List> generatePdfLabel({
    required String companyName,
    required String productName,
    required String barcode,
    String? sku,
    required int quantity,
    required LabelSize labelSize,
  });
}
