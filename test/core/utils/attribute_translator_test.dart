import 'package:flutter_test/flutter_test.dart';
import 'package:wasilaah_finishing/core/utils/attribute_translator.dart';

/// Characterization tests: they pin the current (furniture-specific)
/// behaviour so later refactors don't change printed variant text by accident.
void main() {
  group('AttributeTranslator.translate', () {
    test('translates known phrases before single words', () {
      expect(AttributeTranslator.translate('Light Wood'), 'خشب فاتح');
      expect(AttributeTranslator.translate('dark brown'), 'بني غامق');
    });

    test('translates single words case-insensitively', () {
      expect(AttributeTranslator.translate('Color: White'), 'اللون: أبيض');
    });

    test('keeps unknown text as is and trims', () {
      expect(AttributeTranslator.translate('  Walnut  '), 'Walnut');
    });
  });
}
