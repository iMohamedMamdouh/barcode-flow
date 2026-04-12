import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/repos/printing_repo.dart';

class LabelSizeSelectorWidget extends StatelessWidget {
  final LabelSize selectedSize;
  final ValueChanged<LabelSize> onChanged;

  const LabelSizeSelectorWidget({
    super.key,
    required this.selectedSize,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'حجم الملصق',
          style: GoogleFonts.tajawal(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: LabelSize.values.map((size) {
            final isSelected = size == selectedSize;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: size == LabelSize.values.last ? 0 : 6,
                  right: size == LabelSize.values.first ? 0 : 6,
                ),
                child: _buildSizeOption(size, isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSizeOption(LabelSize size, bool isSelected) {
    return Material(
      color: isSelected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onChanged(size),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.crop_landscape_rounded,
                color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
                size: 28,
              ),
              const SizedBox(height: 4),
              Text(
                size.displayName,
                style: GoogleFonts.tajawal(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
