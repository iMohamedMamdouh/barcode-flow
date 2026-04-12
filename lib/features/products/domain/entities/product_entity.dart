import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final int id;
  final String name;
  final String? defaultCode;
  final String? barcode;
  final double listPrice;
  final String? imageBase64;
  final List<int> variantIds;
  final int variantCount;

  const ProductEntity({
    required this.id,
    required this.name,
    this.defaultCode,
    this.barcode,
    required this.listPrice,
    this.imageBase64,
    required this.variantIds,
    required this.variantCount,
  });

  bool get hasVariants => variantCount > 1;

  @override
  List<Object?> get props => [
        id,
        name,
        defaultCode,
        barcode,
        listPrice,
        imageBase64,
        variantIds,
        variantCount,
      ];
}
