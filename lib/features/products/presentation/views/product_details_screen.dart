import 'dart:convert';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/barcode_helper.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../widgets/print_action_dialog_widget.dart';
import '../widgets/product_info_row_widget.dart';
import '../widgets/quantity_selector_widget.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const ProductDetailsScreen({super.key, required this.productData});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  String get productName => widget.productData['productName'] as String? ?? '';
  String? get barcode => widget.productData['barcode'] as String?;
  String? get defaultCode => widget.productData['defaultCode'] as String?;
  String? get imageBase64 => widget.productData['imageBase64'] as String?;
  List<String> get attributeValues =>
      (widget.productData['attributeValues'] as List<String>?) ?? [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المنتج'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: ResponsiveHelper.maxContentWidth,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProductImage(),
                const SizedBox(height: 20),
                _buildProductName(),
                const SizedBox(height: 16),
                _buildInfoSection(),
                if (barcode != null && barcode!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildBarcodePreview(),
                ],
                const SizedBox(height: 24),
                _buildQuantitySection(),
                const SizedBox(height: 32),
                _buildPrintButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    return Center(
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: imageBase64 != null
            ? Image.memory(
                base64Decode(imageBase64!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildImagePlaceholder(),
              )
            : _buildImagePlaceholder(),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        size: 60,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildProductName() {
    return Text(
      productName,
      textAlign: TextAlign.center,
      style: GoogleFonts.tajawal(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (defaultCode != null)
              ProductInfoRowWidget(
                icon: Icons.tag,
                label: 'الرمز الداخلي (SKU)',
                value: defaultCode!,
              ),
            if (barcode != null)
              ProductInfoRowWidget(
                icon: Icons.qr_code_2_rounded,
                label: 'الباركود',
                value: barcode!,
              ),
            if (attributeValues.isNotEmpty)
              ProductInfoRowWidget(
                icon: Icons.style_rounded,
                label: 'المتغيرات',
                value: attributeValues.join(' • '),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodePreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'معاينة الباركود',
              style: GoogleFonts.tajawal(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            BarcodeWidget(
              barcode: BarcodeHelper.detectType(barcode!),
              data: barcode!,
              width: 220,
              height: 80,
              drawText: true,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'عدد النسخ',
              style: GoogleFonts.tajawal(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            QuantitySelectorWidget(
              quantity: _quantity,
              onChanged: (value) => setState(() => _quantity = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintButton() {
    final hasBarcode = barcode != null && barcode!.isNotEmpty;
    return ElevatedButton.icon(
      onPressed: hasBarcode
          ? () {
              PrintActionDialogWidget.show(
                context,
                productName: productName,
                barcode: barcode,
                defaultCode: defaultCode,
                imageBase64: imageBase64,
                variantName: attributeValues.isNotEmpty
                    ? attributeValues.join(' • ')
                    : null,
              );
            }
          : null,
      icon: const Icon(Icons.print_rounded),
      label: Text(hasBarcode ? 'طباعة الباركود' : 'لا يوجد باركود للطباعة'),
    );
  }

}
