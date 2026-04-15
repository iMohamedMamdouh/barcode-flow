import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import '../../../../core/services/bluetooth_printer_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/utils/service_locator.dart';
import '../../domain/repos/printing_repo.dart' show PrintingRepo;
import '../cubits/bluetooth_printer_cubit.dart';
import '../cubits/bluetooth_printer_state.dart';
import '../cubits/printing_cubit.dart';
import '../cubits/printing_state.dart';
import '../widgets/barcode_label_widget.dart';
import '../widgets/printer_selector_widget.dart';

class BarcodePreviewScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const BarcodePreviewScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => PrintingCubit(sl<PrintingRepo>())),
        BlocProvider(
          create: (_) => BluetoothPrinterCubit(
            sl<PrintingRepo>(),
            sl<BluetoothPrinterService>(),
          )..checkConnection(),
        ),
      ],
      child: _BarcodePreviewBody(data: data),
    );
  }
}

class _BarcodePreviewBody extends StatelessWidget {
  final Map<String, dynamic> data;

  const _BarcodePreviewBody({required this.data});

  String get productName => data['productName'] as String? ?? '';
  String get barcode => data['barcode'] as String? ?? '';
  String? get variantName => data['variantName'] as String?;
  String? get imageBase64 => data['imageBase64'] as String?;
  int get quantity => data['quantity'] as int? ?? 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('معاينة الملصق')),
      body: BlocListener<BluetoothPrinterCubit, BluetoothPrinterState>(
        listener: (context, state) {
          if (state is BtPrinterPrintSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم الطباعة بنجاح',
                  style: GoogleFonts.tajawal(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is BtPrinterError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: GoogleFonts.tajawal(),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocConsumer<PrintingCubit, PrintingState>(
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
                      _buildInfoRow('حجم الورقة', '4 × 6 بوصة'),
                      const SizedBox(height: 12),
                      _buildInfoRow('عدد النسخ', '$quantity'),
                      const SizedBox(height: 16),
                      _buildConnectionStatus(context),
                      const SizedBox(height: 24),
                      _buildDirectPrintButton(context),
                      const SizedBox(height: 12),
                      _buildGenerateButton(context, state),
                      const SizedBox(height: 12),
                      if (state is PrintingReady)
                        _buildShareButton(context, state),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
          variantName: variantName,
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

  Widget _buildConnectionStatus(BuildContext context) {
    return BlocBuilder<BluetoothPrinterCubit, BluetoothPrinterState>(
      builder: (context, state) {
        final isConnected = state is BtPrinterConnected;
        final deviceName = isConnected ? state.device.name : null;

        return GestureDetector(
          onTap: () => PrinterSelectorWidget.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withValues(alpha: 0.08)
                  : Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isConnected
                    ? Colors.green.withValues(alpha: 0.4)
                    : Colors.orange.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isConnected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  size: 22,
                  color: isConnected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isConnected
                        ? 'متصل: ${deviceName ?? "طابعة"}'
                        : 'غير متصل — اضغط لاختيار الطابعة',
                    style: GoogleFonts.tajawal(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
                Icon(
                  isConnected ? Icons.check_circle : Icons.arrow_forward_ios,
                  size: 16,
                  color: isConnected ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDirectPrintButton(BuildContext context) {
    return BlocBuilder<BluetoothPrinterCubit, BluetoothPrinterState>(
      builder: (context, state) {
        final isPrinting = state is BtPrinterPrinting;
        return ElevatedButton.icon(
          onPressed: isPrinting ? null : () => _directPrint(context),
          icon: isPrinting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.print_rounded),
          label: Text(isPrinting ? 'جارٍ الطباعة...' : 'طباعة فورية'),
        );
      },
    );
  }

  void _directPrint(BuildContext context) async {
    final btCubit = context.read<BluetoothPrinterCubit>();
    final connected = await btCubit.isConnected;

    if (!connected) {
      if (!context.mounted) return;
      final didConnect = await PrinterSelectorWidget.show(context);
      if (!didConnect) return;
    }

    await btCubit.printLabel(
      productName: productName,
      barcode: barcode,
      variantName: variantName,
      imageBase64: imageBase64,
      quantity: quantity,
    );
  }

  Widget _buildGenerateButton(BuildContext context, PrintingState state) {
    final isLoading = state is PrintingGenerating;
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () {
              context.read<PrintingCubit>().generateLabel(
                    productName: productName,
                    barcode: barcode,
                    variantName: variantName,
                    imageBase64: imageBase64,
                    quantity: quantity,
                  );
            },
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_rounded),
      label: Text(isLoading ? 'جارٍ الإنشاء...' : 'إنشاء ملف PDF'),
    );
  }

  Widget _buildShareButton(BuildContext context, PrintingReady state) {
    return OutlinedButton.icon(
      onPressed: () async {
        await Printing.sharePdf(
          bytes: state.pdfData,
          filename: 'barcode_$barcode.pdf',
        );
      },
      icon: const Icon(Icons.share_rounded),
      label: const Text('مشاركة / حفظ PDF'),
    );
  }
}
