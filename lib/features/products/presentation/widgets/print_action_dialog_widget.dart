import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../core/services/bluetooth_printer_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/service_locator.dart';
import '../../../printing/domain/repos/printing_repo.dart';
import '../../../printing/presentation/cubits/bluetooth_printer_cubit.dart';
import '../../../printing/presentation/cubits/bluetooth_printer_state.dart';
import '../../../printing/presentation/cubits/printing_cubit.dart';
import '../../../printing/presentation/cubits/printing_state.dart';
import '../../../printing/presentation/widgets/printer_selector_widget.dart';
import 'quantity_selector_widget.dart';

class PrintActionDialogWidget extends StatefulWidget {
  final String productName;
  final String? barcode;
  final String? defaultCode;
  final String? imageBase64;
  final String? variantName;

  const PrintActionDialogWidget({
    super.key,
    required this.productName,
    this.barcode,
    this.defaultCode,
    this.imageBase64,
    this.variantName,
  });

  static Future<void> show(
    BuildContext context, {
    required String productName,
    String? barcode,
    String? defaultCode,
    String? imageBase64,
    String? variantName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PrintActionDialogWidget(
        productName: productName,
        barcode: barcode,
        defaultCode: defaultCode,
        imageBase64: imageBase64,
        variantName: variantName,
      ),
    );
  }

  @override
  State<PrintActionDialogWidget> createState() =>
      _PrintActionDialogWidgetState();
}

class _PrintActionDialogWidgetState extends State<PrintActionDialogWidget> {
  int _quantity = 1;

  bool get _hasBarcode =>
      widget.barcode != null && widget.barcode!.isNotEmpty;

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
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHandle(),
              const SizedBox(height: 8),
              _buildProductHeader(),
              const Divider(height: 32),
              if (!_hasBarcode)
                _buildNoBarcode()
              else ...[
                _buildQuantitySection(),
                const SizedBox(height: 16),
                _buildConnectionStatus(),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildImage(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productName,
                  style: GoogleFonts.tajawal(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.variantName != null &&
                    widget.variantName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.variantName!,
                      style: GoogleFonts.tajawal(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
                if (widget.defaultCode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'الرمز: ${widget.defaultCode}',
                    style: GoogleFonts.tajawal(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.imageBase64 != null
          ? Image.memory(
              base64Decode(widget.imageBase64!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
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

  Widget _buildNoBarcode() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          const Icon(
            Icons.qr_code_rounded,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          Text(
            'لا يوجد باركود لهذا المنتج',
            style: GoogleFonts.tajawal(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantitySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            'عدد النسخ',
            style: GoogleFonts.tajawal(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          QuantitySelectorWidget(
            quantity: _quantity,
            onChanged: (value) => setState(() => _quantity = value),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return BlocBuilder<BluetoothPrinterCubit, BluetoothPrinterState>(
      builder: (context, state) {
        final isConnected = state is BtPrinterConnected;
        final deviceName = isConnected ? state.device.name : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => PrinterSelectorWidget.show(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    size: 20,
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
                    isConnected
                        ? Icons.check_circle
                        : Icons.arrow_forward_ios,
                    size: 16,
                    color: isConnected ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return BlocConsumer<BluetoothPrinterCubit, BluetoothPrinterState>(
      listener: (context, state) {
        if (state is BtPrinterPrintSuccess) {
          Navigator.of(context).pop();
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
      builder: (context, state) {
        final isPrinting = state is BtPrinterPrinting;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isPrinting ? null : () => _openPreview(context),
                  icon: isPrinting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.print_rounded),
                  label: Text(
                    isPrinting ? 'جارٍ الطباعة...' : 'معاينة قبل الطباعة',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPrinting
                      ? null
                      : () => _generateAndShare(context),
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('مشاركة'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPreview(BuildContext context) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.barcodePreview,
      arguments: {
        'productName': widget.productName,
        'barcode': widget.barcode,
        'imageBase64': widget.imageBase64,
        'variantName': widget.variantName,
        'quantity': _quantity,
      },
    );
  }

  void _generateAndShare(BuildContext context) async {
    final cubit = context.read<PrintingCubit>();
    final nav = Navigator.of(context);
    await cubit.generateLabel(
      productName: widget.productName,
      barcode: widget.barcode!,
      variantName: widget.variantName,
      imageBase64: widget.imageBase64,
      quantity: _quantity,
    );

    if (!mounted) return;
    final state = cubit.state;
    if (state is PrintingReady) {
      nav.pop();
      await Printing.sharePdf(
        bytes: state.pdfData,
        filename: 'barcode_${widget.barcode}.pdf',
      );
    }
  }
}
