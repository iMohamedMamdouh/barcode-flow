import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/barcode_helper.dart';

class BarcodeLabelWidget extends StatelessWidget {
  final String productName;
  final String barcode;
  final String? sku;

  const BarcodeLabelWidget({
    super.key,
    required this.productName,
    required this.barcode,
    this.sku,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppConstants.appName,
            style: GoogleFonts.tajawal(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            productName,
            textAlign: TextAlign.center,
            style: GoogleFonts.tajawal(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (sku != null) ...[
            const SizedBox(height: 2),
            Text(
              sku!,
              style: GoogleFonts.tajawal(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          BarcodeWidget(
            barcode: BarcodeHelper.detectType(barcode),
            data: barcode,
            width: 200,
            height: 70,
            drawText: true,
            style: const TextStyle(fontSize: 13, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

}
