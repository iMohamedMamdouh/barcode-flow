import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repos/products_repo.dart';
import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final ProductsRepo _productsRepo;

  ProductDetailsCubit(this._productsRepo)
      : super(const ProductDetailsInitial());

  Future<void> loadVariants(int templateId) async {
    emit(const ProductVariantsLoading());

    final result = await _productsRepo.getProductVariants(templateId);

    if (isClosed) return;

    result.fold(
      (failure) => emit(ProductVariantsError(failure.message)),
      (variants) => emit(ProductVariantsLoaded(variants)),
    );
  }
}
