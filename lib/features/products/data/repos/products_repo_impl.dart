import 'package:dartz/dartz.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/odoo_client.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../../domain/repos/products_repo.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';

class ProductsRepoImpl implements ProductsRepo {
  final OdooClient odooClient;

  const ProductsRepoImpl({required this.odooClient});

  @override
  Future<Either<Failure, List<ProductEntity>>> getProducts({
    String? searchQuery,
  }) async {
    try {
      List<dynamic> domain = [
        ['image_1920', '!=', false],
      ];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim();
        domain = [
          '&',
          ['image_1920', '!=', false],
          '|',
          '|',
          ['name', 'ilike', query],
          ['barcode', 'ilike', query],
          ['default_code', 'ilike', query],
        ];
      }

      final records = await odooClient.searchRead(
        model: ApiConstants.productTemplateModel,
        domain: domain,
        fields: ApiConstants.productTemplateFields,
        order: 'name asc',
      );

      final products =
          records
              .map((r) => ProductModel.fromOdoo(r as Map<String, dynamic>))
              .toList();

      return Right(products);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ في جلب المنتجات: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductVariantEntity>>> getProductVariants(
    int templateId,
  ) async {
    try {
      final records = await odooClient.searchRead(
        model: ApiConstants.productProductModel,
        domain: [
          ['product_tmpl_id', '=', templateId],
        ],
        fields: ApiConstants.productVariantFields,
      );

      final variants = <ProductVariantEntity>[];

      for (final record in records) {
        final json = record as Map<String, dynamic>;
        final variantValueIds = json['product_template_variant_value_ids'];

        List<Map<String, dynamic>> valueRecords = [];
        if (variantValueIds is List && variantValueIds.isNotEmpty) {
          final ids = variantValueIds.cast<int>();
          final values = await odooClient.read(
            model: 'product.template.attribute.value',
            ids: ids,
            fields: ApiConstants.variantValueFields,
          );
          valueRecords = values.cast<Map<String, dynamic>>();
        }

        variants.add(
          ProductVariantModel.fromOdoo(json, variantValueRecords: valueRecords),
        );
      }

      return Right(variants);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('خطأ في جلب المتغيرات: $e'));
    }
  }
}
