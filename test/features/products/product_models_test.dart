import 'package:flutter_test/flutter_test.dart';
import 'package:wasilaah_finishing/features/products/data/models/product_model.dart';
import 'package:wasilaah_finishing/features/products/data/models/product_variant_model.dart';

void main() {
  group('ProductModel.fromOdoo', () {
    test('parses a full product.template record', () {
      final p = ProductModel.fromOdoo({
        'id': 7,
        'name': 'Shoe Rack',
        'default_code': 'SR-01',
        'barcode': '5901234123457',
        'list_price': 1250,
        'image_128': 'aGVsbG8=',
        'product_variant_ids': [11, 12],
        'product_variant_count': 2,
      });

      expect(p.id, 7);
      expect(p.name, 'Shoe Rack');
      expect(p.defaultCode, 'SR-01');
      expect(p.barcode, '5901234123457');
      expect(p.listPrice, 1250.0);
      expect(p.imageBase64, 'aGVsbG8=');
      expect(p.variantIds, [11, 12]);
      expect(p.hasVariants, isTrue);
    });

    // `name` and `list_price` are required in Odoo; optional fields come
    // back as `false` when empty.
    test('Odoo `false` values for optional fields become null', () {
      final p = ProductModel.fromOdoo({
        'id': 1,
        'name': 'Plain',
        'default_code': false,
        'barcode': false,
        'list_price': 0,
        'image_128': false,
        'product_variant_ids': false,
        'product_variant_count': 1,
      });

      expect(p.name, 'Plain');
      expect(p.defaultCode, isNull);
      expect(p.barcode, isNull);
      expect(p.imageBase64, isNull);
      expect(p.listPrice, 0.0);
      expect(p.variantIds, isEmpty);
      expect(p.hasVariants, isFalse);
    });

    test('variant count falls back to the number of variant ids', () {
      final p = ProductModel.fromOdoo({
        'id': 1,
        'name': 'X',
        'product_variant_ids': [1, 2, 3],
      });
      expect(p.variantCount, 3);
    });
  });

  group('ProductVariantModel.fromOdoo', () {
    final record = {
      'id': 21,
      'name': 'Desk',
      'default_code': 'DK-1',
      'barcode': '96385074',
      'list_price': 99.5,
      'image_128': false,
      'product_template_variant_value_ids': [3, 4],
    };

    test('uses display_name of attribute values, translated', () {
      final v = ProductVariantModel.fromOdoo(
        record,
        variantValueRecords: [
          {'id': 3, 'name': 'Wood', 'display_name': 'Light Wood'},
          {'id': 4, 'name': 'White', 'display_name': 'Color: White'},
        ],
      );

      expect(v.id, 21);
      expect(v.barcode, '96385074');
      expect(v.imageBase64, isNull);
      expect(v.attributeValues, ['خشب فاتح', 'اللون: أبيض']);
    });

    test('summary joins attribute values with a bullet', () {
      final v = ProductVariantModel.fromOdoo(
        record,
        variantValueRecords: [
          {'id': 3, 'name': 'Small', 'display_name': 'Size: Small'},
          {'id': 4, 'name': 'Black', 'display_name': 'Color: Black'},
        ],
      );
      expect(v.attributesSummary, 'المقاس: صغير • اللون: أسود');
    });

    test('no attribute values gives an empty summary', () {
      final v = ProductVariantModel.fromOdoo({
        ...record,
        'product_template_variant_value_ids': <int>[],
      });
      expect(v.attributeValues, isEmpty);
      expect(v.attributesSummary, '');
    });
  });
}
