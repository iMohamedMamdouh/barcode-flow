import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';
import '../../domain/repos/products_repo.dart';
import '../cubits/product_details_cubit.dart';
import '../cubits/product_details_state.dart';
import '../widgets/print_action_dialog_widget.dart';

class ProductVariantsScreen extends StatelessWidget {
  final ProductEntity product;

  const ProductVariantsScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (_) =>
              ProductDetailsCubit(sl<ProductsRepo>())..loadVariants(product.id),
      child: Scaffold(
        appBar: AppBar(title: Text(product.name)),
        body: BlocBuilder<ProductDetailsCubit, ProductDetailsState>(
          builder: (context, state) {
            if (state is ProductVariantsLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state is ProductVariantsError) {
              return _buildError(context, state.message);
            }
            if (state is ProductVariantsLoaded) {
              return _buildVariantsList(context, state.variants);
            }
            return const SizedBox.shrink();
          },
        ),
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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  () => context.read<ProductDetailsCubit>().loadVariants(
                    product.id,
                  ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantsList(
    BuildContext context,
    List<ProductVariantEntity> variants,
  ) {
    if (variants.isEmpty) {
      return const Center(child: Text('لا توجد متغيرات'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = ResponsiveHelper.isTablet(constraints.maxWidth);

        final screenWidth = constraints.maxWidth;

        if (isTablet) {
          final columns = ResponsiveHelper.gridColumns(screenWidth);
          final rows = <Widget>[];

          for (var i = 0; i < variants.length; i += columns) {
            final rowItems = variants.sublist(
              i,
              (i + columns) > variants.length ? variants.length : i + columns,
            );

            rows.add(
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var j = 0; j < columns; j++) ...[
                      if (j > 0) const SizedBox(width: 8),
                      Expanded(
                        child:
                            j < rowItems.length
                                ? _buildVariantCard(
                                  context,
                                  rowItems[j],
                                  screenWidth: screenWidth,
                                )
                                : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(children: rows),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: variants.length,
          itemBuilder: (context, index) {
            return _buildVariantCard(
              context,
              variants[index],
              screenWidth: screenWidth,
            );
          },
        );
      },
    );
  }

  Widget _buildVariantCard(
    BuildContext context,
    ProductVariantEntity variant, {
    double screenWidth = 400,
  }) {
    final imgSize = ResponsiveHelper.imageSize(screenWidth);
    final padding = ResponsiveHelper.cardPadding(screenWidth);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          PrintActionDialogWidget.show(
            context,
            productName: variant.name,
            barcode: variant.barcode,
            defaultCode: variant.defaultCode,
            imageBase64: variant.imageBase64,
            variantName: variant.attributesSummary,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              _buildVariantImage(variant, imgSize),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (variant.attributesSummary.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          variant.attributesSummary,
                          style: GoogleFonts.tajawal(
                            fontSize: ResponsiveHelper.fontSize(
                              screenWidth,
                              base: 12,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (variant.defaultCode != null)
                      Text(
                        'الرمز: ${variant.defaultCode}',
                        style: GoogleFonts.tajawal(
                          fontSize: ResponsiveHelper.fontSize(
                            screenWidth,
                            base: 12,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (variant.barcode != null)
                      Text(
                        'الباركود: ${variant.barcode}',
                        style: GoogleFonts.tajawal(
                          fontSize: ResponsiveHelper.fontSize(
                            screenWidth,
                            base: 12,
                          ),
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariantImage(ProductVariantEntity variant, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          variant.imageBase64 != null
              ? Image.memory(
                base64Decode(variant.imageBase64!),
                fit: BoxFit.cover,
                errorBuilder:
                    (_, _, _) => const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.textSecondary,
                    ),
              )
              : const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.textSecondary,
              ),
    );
  }
}
