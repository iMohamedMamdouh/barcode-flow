import 'dart:typed_data';

import '../../../../core/constants/label_dimensions.dart';

abstract class PrintingRepo {
  /// Same physical size as [TsplLabelBuilder] / Bluetooth TSPL commands.
  static const double labelWidthMm = LabelDimensions.widthMm;
  static const double labelHeightMm = LabelDimensions.heightMm;

  Future<Uint8List> generatePdfLabel({
    required String productName,
    required String barcode,
    String? variantName,
    String? imageBase64,
    required int quantity,
  });
}
