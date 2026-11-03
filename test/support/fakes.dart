import 'package:dartz/dartz.dart';
import 'package:wasilaah_finishing/core/errors/failures.dart';
import 'package:wasilaah_finishing/core/network/odoo_client.dart';
import 'package:wasilaah_finishing/features/products/domain/entities/product_entity.dart';
import 'package:wasilaah_finishing/features/products/domain/entities/product_variant_entity.dart';
import 'package:wasilaah_finishing/features/products/domain/repos/products_repo.dart';

/// Records `authenticate` calls instead of hitting a real Odoo server.
class FakeOdooClient extends OdooClient {
  FakeOdooClient({this.error});

  /// When set, `authenticate` throws it.
  Object? error;
  final List<Map<String, String>> calls = [];
  bool loggedOut = false;

  @override
  Future<int> authenticate({
    required String url,
    required String db,
    required String login,
    required String password,
  }) async {
    calls.add({'url': url, 'db': db, 'login': login, 'password': password});
    if (error != null) throw error!;
    uid = 2;
    return 2;
  }

  @override
  void logout() {
    loggedOut = true;
    super.logout();
  }
}

class FakeProductsRepo implements ProductsRepo {
  FakeProductsRepo(this.products);

  final List<ProductEntity> products;

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? searchQuery,
  }) async => Right(products);

  @override
  Future<Either<Failure, List<ProductVariantEntity>>> getProductVariants(
    int templateId,
  ) async => const Right([]);
}

ProductEntity product(
  int id,
  String name, {
  String? barcode,
  String? defaultCode,
}) => ProductEntity(
  id: id,
  name: name,
  barcode: barcode,
  defaultCode: defaultCode,
  listPrice: 0,
  variantIds: [id],
  variantCount: 1,
);
