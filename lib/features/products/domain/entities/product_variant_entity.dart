import 'package:equatable/equatable.dart';

class ProductVariantEntity extends Equatable {
  final int id;
  final String name;
  final String? defaultCode;
  final String? barcode;
  final double listPrice;
  final String? imageBase64;
  final List<String> attributeValues;

  const ProductVariantEntity({
    required this.id,
    required this.name,
    this.defaultCode,
    this.barcode,
    required this.listPrice,
    this.imageBase64,
    required this.attributeValues,
  });

  String get attributesSummary =>
      attributeValues.isNotEmpty ? attributeValues.join(' • ') : '';

  @override
  List<Object?> get props => [
        id,
        name,
        defaultCode,
        barcode,
        listPrice,
        imageBase64,
        attributeValues,
      ];
}
