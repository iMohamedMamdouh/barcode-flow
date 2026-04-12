import 'package:equatable/equatable.dart';
import '../../../../core/constants/product_categories.dart';
import '../../domain/entities/product_entity.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();

  @override
  List<Object?> get props => [];
}

class ProductsInitial extends ProductsState {
  const ProductsInitial();
}

class ProductsLoading extends ProductsState {
  const ProductsLoading();
}

class ProductsLoaded extends ProductsState {
  final List<ProductEntity> products;
  final List<ProductEntity> filteredProducts;
  final String searchQuery;
  final ProductCategory selectedCategory;

  const ProductsLoaded({
    required this.products,
    required this.filteredProducts,
    this.searchQuery = '',
    this.selectedCategory = ProductCategories.all,
  });

  @override
  List<Object?> get props => [
    products,
    filteredProducts,
    searchQuery,
    selectedCategory,
  ];
}

class ProductsError extends ProductsState {
  final String message;

  const ProductsError(this.message);

  @override
  List<Object?> get props => [message];
}
