import '../../../../core/utils/attribute_translator.dart';
import '../../domain/entities/product_variant_entity.dart';

class ProductVariantModel extends ProductVariantEntity {
  const ProductVariantModel({
    required super.id,
    required super.name,
    super.defaultCode,
    super.barcode,
    required super.listPrice,
    super.imageBase64,
    required super.attributeValues,
  });

  factory ProductVariantModel.fromOdoo(
    Map<String, dynamic> json, {
    List<Map<String, dynamic>> variantValueRecords = const [],
  }) {
    final variantValueIds = json['product_template_variant_value_ids'];
    final List<String> attributeValues;

    if (variantValueRecords.isNotEmpty) {
      attributeValues = variantValueRecords
          .map((r) => r['display_name']?.toString() ?? r['name']?.toString() ?? '')
          .where((v) => v.isNotEmpty)
          .map(AttributeTranslator.translate)
          .toList();
    } else if (variantValueIds is List && variantValueIds.isNotEmpty) {
      attributeValues = variantValueIds
          .map((v) => AttributeTranslator.translate(v.toString()))
          .toList();
    } else {
      attributeValues = [];
    }

    return ProductVariantModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      defaultCode: _parseString(json['default_code']),
      barcode: _parseString(json['barcode']),
      listPrice: (json['list_price'] as num?)?.toDouble() ?? 0.0,
      imageBase64: _parseString(json['image_128']),
      attributeValues: attributeValues,
    );
  }

  static String? _parseString(dynamic value) {
    if (value == null || value == false) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }
}
