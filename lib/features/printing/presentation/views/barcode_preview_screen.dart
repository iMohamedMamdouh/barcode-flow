import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/repos/printing_repo.dart';
import '../cubits/printing_cubit.dart';
import '../cubits/printing_state.dart';
import '../widgets/barcode_label_widget.dart';
import '../widgets/label_size_selector_widget.dart';

class BarcodePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const BarcodePreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PrintingCubit(sl<PrintingRepo>()),
      child: _BarcodePreviewBody(data: data),
    );
  }
}

class _BarcodePreviewBody extends StatefulWidget {
  final Map<String, dynamic> data;

  const _BarcodePreviewBody({required this.data});

  @override
  State<_BarcodePreviewBody> createState() => _BarcodePreviewBodyState();
}

class _BarcodePreviewBodyState extends State<_BarcodePreviewBody> {
  LabelSize _labelSize = LabelSize.medium;

  String get productName => widget.data['productName'] as String? ?? '';
  String get barcode => widget.data['barcode'] as String? ?? '';
  String? get sku => widget.data['defaultCode'] as String?;
  int get quantity => widget.data['quantity'] as int? ?? 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معاينة الملصق'),
      ),
      body: BlocConsumer<PrintingCubit, PrintingState>(
        listener: (context, state) {
          if (state is PrintingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: ResponsiveHelper.maxContentWidth,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPreviewSection(),
                    const SizedBox(height: 24),
                    LabelSizeSelectorWidget(
                      selectedSize: _labelSize,
                      onChanged: (size) => setState(() => _labelSize = size),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('عدد النسخ', '$quantity'),
                    const SizedBox(height: 32),
                    _buildGenerateButton(context, state),
                    const SizedBox(height: 12),
                    if (state is PrintingReady) _buildPrintButton(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      children: [
        Text(
          'معاينة الملصق',
          style: GoogleFonts.tajawal(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        BarcodeLabelWidget(
          productName: productName,
          barcode: barcode,
          sku: sku,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.tajawal(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton(BuildContext context, PrintingState state) {
    final isLoading = state is PrintingGenerating;
    return ElevatedButton.icon(
      onPressed: isLoading
          ? null
          : () {
              context.read<PrintingCubit>().generateLabel(
                    productName: productName,
                    barcode: barcode,
                    sku: sku,
                    quantity: quantity,
                    labelSize: _labelSize,
                  );
            },
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.onPrimary,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.picture_as_pdf_rounded),
      label: Text(isLoading ? 'جارٍ الإنشاء...' : 'إنشاء ملف PDF'),
    );
  }

  Widget _buildPrintButton(BuildContext context, PrintingReady state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: () async {
            await Printing.layoutPdf(
              onLayout: (_) async => state.pdfData,
              name: 'barcode_$barcode',
            );
          },
          icon: const Icon(Icons.print_rounded),
          label: const Text('طباعة'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            await Printing.sharePdf(
              bytes: state.pdfData,
              filename: 'barcode_$barcode.pdf',
            );
          },
          icon: const Icon(Icons.share_rounded),
          label: const Text('مشاركة / حفظ PDF'),
        ),
      ],
    );
  }
}
