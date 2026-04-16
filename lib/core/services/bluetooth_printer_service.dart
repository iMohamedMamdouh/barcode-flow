import 'dart:async';

import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BluetoothPrinterService {
  BluetoothPrinterService._();
  static final instance = BluetoothPrinterService._();

  BluetoothInfo? _connectedDevice;
  BluetoothInfo? get connectedDevice => _connectedDevice;

  static const _savedMacKey = 'saved_printer_mac';
  static const _savedNameKey = 'saved_printer_name';

  Future<bool> get isConnected => PrintBluetoothThermal.connectionStatus;

  Future<bool> get isBluetoothOn => PrintBluetoothThermal.bluetoothEnabled;

  Future<bool> get hasPermission =>
      PrintBluetoothThermal.isPermissionBluetoothGranted;

  Future<List<BluetoothInfo>> getPairedDevices() async {
    return PrintBluetoothThermal.pairedBluetooths;
  }

  Future<bool> connect(BluetoothInfo device) async {
    try {
      final result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAdress,
      );
      if (result) {
        _connectedDevice = device;
        await _saveDevice(device);
      }
      return result;
    } catch (_) {
      return false;
    }
  }

  Future<bool> disconnect() async {
    _connectedDevice = null;
    return PrintBluetoothThermal.disconnect;
  }

  /// Send bytes in chunks to avoid Bluetooth buffer overflow.
  Future<bool> writeBytes(List<int> bytes) async {
    final connected = await isConnected;
    if (!connected) return false;
    try {
      const chunkSize = 500;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final end =
            (i + chunkSize > bytes.length) ? bytes.length : i + chunkSize;
        final chunk = bytes.sublist(i, end);
        final result = await PrintBluetoothThermal.writeBytes(chunk);
        if (!result) return false;
        if (i + chunkSize < bytes.length) {
          await Future.delayed(const Duration(milliseconds: 10));
        }
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveDevice(BluetoothInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedMacKey, device.macAdress);
    await prefs.setString(_savedNameKey, device.name);
  }

  Future<BluetoothInfo?> getSavedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_savedMacKey);
    final name = prefs.getString(_savedNameKey);
    if (mac == null || mac.isEmpty) return null;
    return BluetoothInfo(name: name ?? '', macAdress: mac);
  }

  Future<bool> autoConnect() async {
    final saved = await getSavedDevice();
    if (saved == null) return false;
    return connect(saved);
  }
}
