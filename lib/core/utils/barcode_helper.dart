import 'package:barcode/barcode.dart';

class BarcodeHelper {
  BarcodeHelper._();

  static Barcode detectType(String data) {
    if (RegExp(r'^\d+$').hasMatch(data)) {
      if (data.length == 13 && _isValidEan13(data)) {
        return Barcode.ean13();
      }
      if (data.length == 8 && _isValidEan8(data)) {
        return Barcode.ean8();
      }
    }
    return Barcode.code128();
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
}
