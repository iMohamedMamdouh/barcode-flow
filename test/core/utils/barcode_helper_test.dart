import 'package:flutter_test/flutter_test.dart';
import 'package:wasilaah_finishing/core/utils/barcode_helper.dart';

void main() {
  group('BarcodeHelper.detectType', () {
    test('valid EAN-13 is detected as EAN 13', () {
      expect(BarcodeHelper.detectType('5901234123457').name, 'EAN 13');
    });

    test('13 digits with a wrong checksum fall back to Code128', () {
      expect(BarcodeHelper.detectType('5901234123458').name, 'CODE 128');
    });

    test('valid EAN-8 is detected as EAN 8', () {
      expect(BarcodeHelper.detectType('96385074').name, 'EAN 8');
    });

    test('8 digits with a wrong checksum fall back to Code128', () {
      expect(BarcodeHelper.detectType('96385075').name, 'CODE 128');
    });

    test('alphanumeric SKU uses Code128', () {
      expect(BarcodeHelper.detectType('WS-DESK-001').name, 'CODE 128');
    });

    test('other digit lengths use Code128', () {
      expect(BarcodeHelper.detectType('123456').name, 'CODE 128');
      expect(BarcodeHelper.detectType('012345678905').name, 'CODE 128');
    });
  });
}
