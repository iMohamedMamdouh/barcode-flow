import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/constants/product_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repos/products_repo.dart';
import '../cubits/products_cubit.dart';
import '../cubits/products_state.dart';
import '../widgets/category_filter_widget.dart';
import '../widgets/product_card_widget.dart';
import '../widgets/products_search_bar_widget.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProductsCubit(sl<ProductsRepo>())..loadProducts(),
      child: const _ProductsScreenBody(),
    );
  }
}

class _ProductsScreenBody extends StatelessWidget {
  const _ProductsScreenBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المنتجات'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ProductsCubit>().loadProducts(),
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Column(
        children: [
          ProductsSearchBarWidget(
            onSearch: (query) {
              context.read<ProductsCubit>().searchProducts(query);
            },
          ),
          BlocSelector<ProductsCubit, ProductsState, ProductCategory>(
            selector: (state) {
              if (state is ProductsLoaded) return state.selectedCategory;
              return ProductCategories.all;
            },
            builder: (context, selectedCategory) {
              return CategoryFilterWidget(
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  context.read<ProductsCubit>().filterByCategory(category);
                },
              );
            },
          ),
          const SizedBox(height: 4),
          Expanded(
            child: BlocBuilder<ProductsCubit, ProductsState>(
              builder: (context, state) {
                if (state is ProductsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                if (state is ProductsError) {
                  return _buildError(context, state.message);
                }
                if (state is ProductsLoaded) {
                  return _buildProductsList(context, state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<ProductsCubit>().loadProducts(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(BuildContext context, ProductsLoaded state) {
    final products = state.filteredProducts;

    if (products.isEmpty) {
      final isFiltered =
          state.selectedCategory.id != ProductCategories.all.id ||
          state.searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFiltered
                  ? Icons.search_off_rounded
                  : Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'لا توجد منتجات في هذه الفئة' : 'لا توجد منتجات',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = ResponsiveHelper.isTablet(constraints.maxWidth);
        final screenWidth = constraints.maxWidth;

        return RefreshIndicator(
          onRefresh: () => context.read<ProductsCubit>().loadProducts(),
          color: AppColors.primary,
          child:
              isTablet
                  ? _buildTabletGrid(context, products, screenWidth)
                  : ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCardWidget(
                        product: product,
                        onTap: () => _onProductTap(context, product),
                        screenWidth: screenWidth,
                      );
                    },
                  ),
        );
      },
    );
  }

  Widget _buildTabletGrid(
    BuildContext context,
    List<ProductEntity> products,
    double screenWidth,
  ) {
    final columns = ResponsiveHelper.gridColumns(screenWidth);
    final rows = <Widget>[];

    for (var i = 0; i < products.length; i += columns) {
      final rowItems = products.sublist(
        i,
        (i + columns) > products.length ? products.length : i + columns,
      );

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < columns; j++) ...[
                  if (j > 0) const SizedBox(width: 8),
                  Expanded(
                    child:
                        j < rowItems.length
                            ? ProductCardWidget(
                              product: rowItems[j],
                              onTap: () => _onProductTap(context, rowItems[j]),
                              compactMargin: true,
                              screenWidth: screenWidth,
                            )
                            : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(children: rows),
    );
  }

  void _onProductTap(BuildContext context, ProductEntity product) {
    if (product.hasVariants) {
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.productVariants, arguments: product);
    } else if (product.variantIds.isNotEmpty) {
      Navigator.of(context).pushNamed(
        AppRoutes.productDetails,
        arguments: {
          'productName': product.name,
          'variantId': product.variantIds.first,
          'barcode': product.barcode,
          'defaultCode': product.defaultCode,
          'imageBase64': product.imageBase64,
        },
      );
    }
  }
}
