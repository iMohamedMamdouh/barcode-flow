import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../../../../core/theme/app_colors.dart';
import '../cubits/bluetooth_printer_cubit.dart';
import '../cubits/bluetooth_printer_state.dart';

class PrinterSelectorWidget extends StatelessWidget {
  const PrinterSelectorWidget({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BluetoothPrinterCubit>(),
        child: const PrinterSelectorWidget(),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'اختيار الطابعة',
            style: GoogleFonts.tajawal(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'اختر الطابعة المقترنة بالبلوتوث',
            style: GoogleFonts.tajawal(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildScanButton(),
          const SizedBox(height: 12),
          Flexible(child: _buildDeviceList()),
        ],
      ),
    );
  }

  Widget _buildScanButton() {
    return BlocBuilder<BluetoothPrinterCubit, BluetoothPrinterState>(
      builder: (context, state) {
        final isScanning = state is BtPrinterScanning;
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isScanning
                ? null
                : () => context.read<BluetoothPrinterCubit>().scanDevices(),
            icon: isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(isScanning ? 'جارٍ البحث...' : 'عرض الأجهزة المقترنة'),
          ),
        );
      },
    );
  }

  Widget _buildDeviceList() {
    return BlocConsumer<BluetoothPrinterCubit, BluetoothPrinterState>(
      listener: (context, state) {
        if (state is BtPrinterConnected) {
          Navigator.of(context).pop(true);
        }
        if (state is BtPrinterError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is BtPrinterDevicesFound) {
          if (state.devices.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bluetooth_disabled,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لم يتم العثور على أجهزة\nتأكد من اقتران الطابعة بالبلوتوث',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.tajawal(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            shrinkWrap: true,
            itemCount: state.devices.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final device = state.devices[index];
              return _DeviceTile(device: device);
            },
          );
        }
        if (state is BtPrinterConnecting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BluetoothInfo device;

  const _DeviceTile({required this.device});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.print_rounded, color: AppColors.primary),
      title: Text(
        device.name.isEmpty ? 'جهاز غير معروف' : device.name,
        style: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        device.macAdress,
        style: GoogleFonts.tajawal(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.bluetooth, size: 20),
      onTap: () {
        context.read<BluetoothPrinterCubit>().connectToDevice(device);
      },
    );
  }
}
