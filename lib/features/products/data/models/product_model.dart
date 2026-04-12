import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    super.defaultCode,
    super.barcode,
    required super.listPrice,
    super.imageBase64,
    required super.variantIds,
    required super.variantCount,
  });

  factory ProductModel.fromOdoo(Map<String, dynamic> json) {
    final variantIds = json['product_variant_ids'];
    final List<int> parsedVariantIds;
    if (variantIds is List) {
      parsedVariantIds = variantIds.cast<int>();
    } else {
      parsedVariantIds = [];
    }

    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      defaultCode: _parseString(json['default_code']),
      barcode: _parseString(json['barcode']),
      listPrice: (json['list_price'] as num?)?.toDouble() ?? 0.0,
      imageBase64: _parseString(json['image_128']),
      variantIds: parsedVariantIds,
      variantCount: json['product_variant_count'] as int? ?? parsedVariantIds.length,
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null || value == false) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
