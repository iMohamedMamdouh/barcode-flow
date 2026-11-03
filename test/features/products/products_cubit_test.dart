import 'package:flutter_test/flutter_test.dart';
import 'package:wasilaah_finishing/core/constants/product_categories.dart';
import 'package:wasilaah_finishing/features/products/presentation/cubits/products_cubit.dart';
import 'package:wasilaah_finishing/features/products/presentation/cubits/products_state.dart';

import '../../support/fakes.dart';

void main() {
  final products = [
    product(1, 'Walnut Shoe Rack', barcode: '5901234123457'),
    product(2, 'AKILA Desk', defaultCode: 'DK-01'),
    product(3, 'Laptop Desk'),
    product(4, 'Coffee Table'),
  ];

  Future<ProductsCubit> loaded() async {
    final cubit = ProductsCubit(FakeProductsRepo(products));
    await cubit.loadProducts();
    return cubit;
  }

  List<int> ids(ProductsCubit c) =>
      (c.state as ProductsLoaded).filteredProducts.map((p) => p.id).toList();

  test('loadProducts shows everything', () async {
    final cubit = await loaded();
    expect(ids(cubit), [1, 2, 3, 4]);
    expect((cubit.state as ProductsLoaded).selectedCategory,
        ProductCategories.all);
  });

  test('filters by category keywords', () async {
    final cubit = await loaded();
    cubit.filterByCategory(ProductCategories.desks);
    expect(ids(cubit), [2]);
  });

  test('search matches name, barcode and SKU', () async {
    final cubit = await loaded();
    cubit.searchProducts('walnut');
    expect(ids(cubit), [1]);
    cubit.searchProducts('590123');
    expect(ids(cubit), [1]);
    cubit.searchProducts('dk-01');
    expect(ids(cubit), [2]);
  });

  test('category and search combine', () async {
    final cubit = await loaded();
    cubit.searchProducts('desk');
    expect(ids(cubit), [2, 3]);
    cubit.filterByCategory(ProductCategories.desks);
    expect(ids(cubit), [2]);
    cubit.filterByCategory(ProductCategories.all);
    expect(ids(cubit), [2, 3]);
  });
}
