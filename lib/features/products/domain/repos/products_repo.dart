import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/product_entity.dart';
import '../entities/product_variant_entity.dart';

abstract class ProductsRepo {
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? searchQuery,
  });

  Future<Either<Failure, List<ProductVariantEntity>>> getProductVariants(
    int templateId,
  );
}
