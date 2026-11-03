import 'package:flutter_test/flutter_test.dart';
import 'package:wasilaah_finishing/core/constants/product_categories.dart';

void main() {
  group('ProductCategory.matchesProduct', () {
    test('matches keywords case-insensitively', () {
      expect(
        ProductCategories.shoeStorage.matchesProduct('Walnut shoe storage'),
        isTrue,
      );
      expect(ProductCategories.desks.matchesProduct('AKILA Office'), isTrue);
    });

    test('exclude keywords win over keywords', () {
      expect(ProductCategories.desks.matchesProduct('Laptop Desk'), isFalse);
      expect(ProductCategories.table.matchesProduct('Table Lamp'), isFalse);
      expect(ProductCategories.table.matchesProduct('Coffee Table'), isTrue);
    });

    test('no keyword means no match', () {
      expect(ProductCategories.mirrors.matchesProduct('Coffee Table'), isFalse);
    });
  });

  test('"all" is the first category and ids are unique', () {
    final values = ProductCategories.values;
    expect(values.first, ProductCategories.all);
    expect(values.map((c) => c.id).toSet().length, values.length);
  });

  test('every category except "all" has an icon asset', () {
    for (final c in ProductCategories.values.skip(1)) {
      expect(c.iconPath, isNotNull, reason: c.id);
    }
  });
}
