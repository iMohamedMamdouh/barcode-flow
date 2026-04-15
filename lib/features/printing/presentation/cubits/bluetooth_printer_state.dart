import 'package:equatable/equatable.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

abstract class BluetoothPrinterState extends Equatable {
  const BluetoothPrinterState();

  @override
  List<Object?> get props => [];
}

class BtPrinterInitial extends BluetoothPrinterState {}

class BtPrinterScanning extends BluetoothPrinterState {}

class BtPrinterDevicesFound extends BluetoothPrinterState {
  final List<BluetoothInfo> devices;

  const BtPrinterDevicesFound(this.devices);

  @override
  List<Object?> get props => [devices];
}

class BtPrinterConnecting extends BluetoothPrinterState {}

class BtPrinterConnected extends BluetoothPrinterState {
  final BluetoothInfo device;

  const BtPrinterConnected(this.device);

  @override
  List<Object?> get props => [device];
}

class BtPrinterDisconnected extends BluetoothPrinterState {}

class BtPrinterPrinting extends BluetoothPrinterState {}

class BtPrinterPrintSuccess extends BluetoothPrinterState {}

class BtPrinterError extends BluetoothPrinterState {
  final String message;

  const BtPrinterError(this.message);

  @override
  List<Object?> get props => [message];
}
