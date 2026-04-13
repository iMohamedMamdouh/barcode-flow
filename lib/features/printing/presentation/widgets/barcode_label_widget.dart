import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/barcode_helper.dart';

class BarcodeLabelWidget extends StatelessWidget {
  final String productName;
  final String barcode;
  final String? variantName;

  const BarcodeLabelWidget({
    super.key,
    required this.productName,
    required this.barcode,
    this.variantName,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              productName,
              textAlign: TextAlign.center,
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (variantName != null && variantName!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                variantName!,
                textAlign: TextAlign.center,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 22),
            BarcodeWidget(
              barcode: BarcodeHelper.detectType(barcode),
              data: barcode,
              width: 220,
              height: 80,
              drawText: true,
              style: const TextStyle(
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
