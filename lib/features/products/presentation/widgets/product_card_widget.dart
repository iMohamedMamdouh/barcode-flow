import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../domain/entities/product_entity.dart';

class ProductCardWidget extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  final bool compactMargin;
  final double screenWidth;

  const ProductCardWidget({
    super.key,
    required this.product,
    required this.onTap,
    this.compactMargin = false,
    this.screenWidth = 400,
  });

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveHelper.cardPadding(screenWidth);

    return Card(
      margin: compactMargin
          ? const EdgeInsets.all(2)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              _buildImage(),
              const SizedBox(width: 14),
              Expanded(child: _buildInfo()),
              _buildArrow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final size = ResponsiveHelper.imageSize(screenWidth);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child:
          product.imageBase64 != null
              ? Image.memory(
                base64Decode(product.imageBase64!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildPlaceholder(),
              )
              : _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.textSecondary,
        size: 30,
      ),
    );
  }

  Widget _buildInfo() {
    final titleSize = ResponsiveHelper.fontSize(screenWidth, base: 14);
    final subSize = ResponsiveHelper.fontSize(screenWidth, base: 12);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          product.name,
          style: GoogleFonts.tajawal(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        if (product.defaultCode != null)
          _buildChip(Icons.tag, product.defaultCode!, subSize),
        if (product.barcode != null) ...[
          const SizedBox(height: 2),
          _buildChip(Icons.qr_code_2_rounded, product.barcode!, subSize),
        ],
        if (product.hasVariants) ...[
          const SizedBox(height: 4),
          Text(
            '${product.variantCount} متغيرات',
            style: GoogleFonts.tajawal(
              fontSize: subSize,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(IconData icon, String text, double fontSize) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.tajawal(
              fontSize: fontSize,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return const Padding(
      padding: EdgeInsets.only(right: 4),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.textSecondary,
      ),
    );
  }
}
