import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../../core/services/bluetooth_printer_service.dart';
import '../../../../core/utils/tspl_label_builder.dart';
import '../../domain/repos/printing_repo.dart';
import 'bluetooth_printer_state.dart';

class BluetoothPrinterCubit extends Cubit<BluetoothPrinterState> {
  final PrintingRepo _printingRepo;
  final BluetoothPrinterService _printerService;

  BluetoothPrinterCubit(this._printingRepo, this._printerService)
      : super(BtPrinterInitial());

  Future<bool> get isConnected => _printerService.isConnected;
  BluetoothInfo? get connectedDevice => _printerService.connectedDevice;

  Future<void> checkConnection() async {
    final connected = await _printerService.isConnected;
    if (isClosed) return;

    if (connected && _printerService.connectedDevice != null) {
      emit(BtPrinterConnected(_printerService.connectedDevice!));
    } else {
      final success = await _printerService.autoConnect();
      if (isClosed) return;
      if (success && _printerService.connectedDevice != null) {
        emit(BtPrinterConnected(_printerService.connectedDevice!));
      } else {
        emit(BtPrinterDisconnected());
      }
    }
  }

  Future<void> scanDevices() async {
    emit(BtPrinterScanning());
    try {
      final hasPermission = await _printerService.hasPermission;
      if (!hasPermission) {
        if (isClosed) return;
        emit(const BtPrinterError('يرجى السماح بصلاحية البلوتوث'));
        return;
      }

      final btOn = await _printerService.isBluetoothOn;
      if (!btOn) {
        if (isClosed) return;
        emit(const BtPrinterError('يرجى تشغيل البلوتوث'));
        return;
      }

      final devices = await _printerService.getPairedDevices();
      if (isClosed) return;
      emit(BtPrinterDevicesFound(devices));
    } catch (e) {
      if (isClosed) return;
      emit(BtPrinterError('فشل البحث عن الأجهزة: $e'));
    }
  }

  Future<void> connectToDevice(BluetoothInfo device) async {
    emit(BtPrinterConnecting());
    final success = await _printerService.connect(device);
    if (isClosed) return;
    if (success) {
      emit(BtPrinterConnected(device));
    } else {
      emit(const BtPrinterError('فشل الاتصال بالطابعة'));
    }
  }

  Future<void> disconnect() async {
    await _printerService.disconnect();
    if (isClosed) return;
    emit(BtPrinterDisconnected());
  }

  /// Generate PDF → rasterize to image → build TSPL → send raw bytes
  Future<void> printLabel({
    required String productName,
    required String barcode,
    String? variantName,
    String? imageBase64,
    required int quantity,
    int density = 8,
  }) async {
    final connected = await _printerService.isConnected;
    if (!connected) {
      emit(const BtPrinterError('الطابعة غير متصلة'));
      return;
    }

    emit(BtPrinterPrinting());
    try {
      if (kDebugMode) debugPrint('[PRINT] Generating PDF...');

      final pdfData = await _printingRepo.generatePdfLabel(
        productName: productName,
        barcode: barcode,
        variantName: variantName,
        imageBase64: imageBase64,
        quantity: 1,
      );

      if (kDebugMode) {
        debugPrint('[PRINT] PDF generated: ${pdfData.length} bytes');
        debugPrint('[PRINT] Converting to TSPL bitmap...');
      }

      final tsplBytes = await TsplLabelBuilder.buildFromPdf(
        pdfData,
        quantity: quantity,
        density: density,
      );

      if (kDebugMode) {
        debugPrint('[PRINT] TSPL data ready: ${tsplBytes.length} bytes');
        debugPrint('[PRINT] Sending to printer...');
      }

      final success = await _printerService.writeBytes(tsplBytes);
      if (isClosed) return;

      if (kDebugMode) debugPrint('[PRINT] Send result: $success');

      if (success) {
        emit(BtPrinterPrintSuccess());
      } else {
        emit(const BtPrinterError('فشل إرسال البيانات للطابعة'));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[PRINT] Error: $e');
      if (isClosed) return;
      emit(BtPrinterError('خطأ في الطباعة: $e'));
    }
  }
}
