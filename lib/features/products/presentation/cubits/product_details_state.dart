import 'package:equatable/equatable.dart';
import '../../domain/entities/product_variant_entity.dart';

abstract class ProductDetailsState extends Equatable {
  const ProductDetailsState();

  @override
  List<Object?> get props => [];
}

class ProductDetailsInitial extends ProductDetailsState {
  const ProductDetailsInitial();
}

class ProductVariantsLoading extends ProductDetailsState {
  const ProductVariantsLoading();
}

class ProductVariantsLoaded extends ProductDetailsState {
  final List<ProductVariantEntity> variants;

  const ProductVariantsLoaded(this.variants);

  @override
  List<Object?> get props => [variants];
}

class ProductVariantsError extends ProductDetailsState {
  final String message;

  const ProductVariantsError(this.message);

  @override
  List<Object?> get props => [message];
}
