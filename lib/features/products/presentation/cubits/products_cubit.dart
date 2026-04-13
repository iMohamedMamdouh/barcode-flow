import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/product_categories.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repos/products_repo.dart';
import 'products_state.dart';

class ProductsCubit extends Cubit<ProductsState> {
  final ProductsRepo _productsRepo;

  ProductsCubit(this._productsRepo) : super(const ProductsInitial());

  Future<void> loadProducts() async {
    emit(const ProductsLoading());

    final result = await _productsRepo.getProducts();

    if (isClosed) return;

    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(
        products: products,
        filteredProducts: products,
      )),
    );
  }

  void filterByCategory(ProductCategory category) {
    final currentState = state;
    if (currentState is! ProductsLoaded) return;

    final filtered = _applyFilters(
      currentState.products,
      currentState.searchQuery,
      category,
    );

    emit(ProductsLoaded(
      products: currentState.products,
      filteredProducts: filtered,
      searchQuery: currentState.searchQuery,
      selectedCategory: category,
    ));
  }

  void searchProducts(String query) {
    final currentState = state;
    if (currentState is! ProductsLoaded) return;

    final filtered = _applyFilters(
      currentState.products,
      query,
      currentState.selectedCategory,
    );

    emit(ProductsLoaded(
      products: currentState.products,
      filteredProducts: filtered,
      searchQuery: query,
      selectedCategory: currentState.selectedCategory,
    ));
  }

  List<ProductEntity> _applyFilters(
    List<ProductEntity> products,
    String searchQuery,
    ProductCategory category,
  ) {
    var result = products;

    if (category.id != ProductCategories.all.id) {
      result = result.where((p) => category.matchesProduct(p.name)).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final lowerQuery = searchQuery.toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(lowerQuery) ||
            (p.barcode?.toLowerCase().contains(lowerQuery) ?? false) ||
            (p.defaultCode?.toLowerCase().contains(lowerQuery) ?? false);
      }).toList();
    }

    return result;
  }

  Future<void> searchFromServer(String query) async {
    emit(const ProductsLoading());

    final result = await _productsRepo.getProducts(searchQuery: query);

    if (isClosed) return;

    result.fold(
      (failure) => emit(ProductsError(failure.message)),
      (products) => emit(ProductsLoaded(
        products: products,
        filteredProducts: products,
        searchQuery: query,
      )),
    );
  }
}
