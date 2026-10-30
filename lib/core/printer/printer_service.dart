import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hasil scan perangkat Bluetooth.
class BluetoothDeviceInfo {
  const BluetoothDeviceInfo({
    required this.id,
    required this.name,
    required this.address,
  });

  final String id;
  final String name;
  final String address;

  @override
  String toString() => '$name ($address)';
}

/// Service untuk manajemen printer thermal Bluetooth (ESC/POS).
class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _stateSubscription;

  /// Daftar perangkat Bluetooth yang ditemukan selama scan.
  final List<BluetoothDeviceInfo> discoveredDevices = [];

  /// Scan perangkat Bluetooth selama [duration] detik.
  Future<List<BluetoothDeviceInfo>> scan({
    Duration duration = const Duration(seconds: 8),
  }) async {
    discoveredDevices.clear();

    final stream = FlutterBluePlus.scanResults;
    final subscription = stream.listen((results) {
      for (final result in results) {
        final existing = discoveredDevices.any((d) => d.id == result.device.remoteId.toString());
        if (!existing) {
          discoveredDevices.add(BluetoothDeviceInfo(
            id: result.device.remoteId.toString(),
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            address: result.device.remoteId.toString(),
          ));
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: duration,
    );

    // Tunggu scan selesai
    await Future.delayed(duration);

    await subscription.cancel();
    await FlutterBluePlus.stopScan();

    return List.unmodifiable(discoveredDevices);
  }

  /// Hubungkan ke perangkat Bluetooth dengan [deviceId].
  Future<bool> connect(String deviceId) async {
    try {
      final device = BluetoothDevice.fromId(deviceId);
      await device.connect(license: License.nonprofit, timeout: const Duration(seconds: 10));
      _connectedDevice = device;

      _stateSubscription = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _connectedDevice = null;
        }
      });

      return true;
    } catch (e) {
      _connectedDevice = null;
      rethrow;
    }
  }

  /// Putuskan koneksi Bluetooth.
  Future<void> disconnect() async {
    await _stateSubscription?.cancel();
    _stateSubscription = null;
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
    }
  }

  /// Apakah printer sedang terkoneksi.
  bool get isConnected => _connectedDevice != null;

  /// Cetak data ESC/POS ke printer.
  /// [bytes] adalah data yang sudah diformat ESC/POS.
  Future<void> printBytes(Uint8List bytes) async {
    if (_connectedDevice == null) {
      throw StateError('Printer tidak terhubung. Silakan hubungkan terlebih dahulu.');
    }

    debugPrint('Printing ${bytes.length} bytes to thermal printer');

    // Kirim data via characteristic Write (untuk printer yang mendukung)
    final services = await _connectedDevice!.discoverServices();

    // Cari characteristic yang support write
    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          await characteristic.write(bytes);
          return;
        }
      }
    }

    throw StateError('Printer tidak memiliki characteristic yang support write');
  }

  /// Format struk penjualan menjadi data ESC/POS sederhana (tanpa library esc_pos_printer).
  /// Menggunakan format teks ESC/POS dasar yang kompatibel dengan printer thermal 58mm/80mm.
  Uint8List formatReceipt({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required String storeName,
    required String storeAddress,
    required String invoiceNumber,
    required DateTime dateTime,
  }) {
    final lines = <String>[];

    // Header toko
    lines.add(storeName.toUpperCase());
    lines.add(storeAddress);
    lines.add('-' * 32);
    lines.add('No Struk: $invoiceNumber');
    lines.add(
        '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}');
    lines.add('-' * 32);

    // Header tabel item
    lines.add('${'Item'.padRight(16)}${'Qty'.padRight(6)}${'Total'.padRight(10)}');
    lines.add('-' * 32);

    // Item-item
    for (final item in items) {
      final name = (item['name'] as String).padRight(16).substring(0, 16);
      final qty = item['qty'].toString().padRight(6);
      final price = item['total'].toStringAsFixed(0).padRight(10);
      lines.add('$name$qty$price');
    }

    lines.add('-' * 32);

    // Total
    lines.add('Subtotal: ${subtotal.toStringAsFixed(0)}');
    lines.add('Pajak: ${tax.toStringAsFixed(0)}');
    lines.add('Total: ${total.toStringAsFixed(0)}');
    lines.add('Pembayaran: $paymentMethod');
    lines.add('-' * 32);
    lines.add('Terima kasih telah berbelanja!');
    lines.add('');
    lines.add('');
    lines.add('');

    final allText = lines.join('\n');
    return Uint8List.fromList(allText.codeUnits);
  }

  /// Cetak struk penjualan.
  Future<void> printReceipt({
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double tax,
    required double total,
    required String paymentMethod,
    required String storeName,
    required String storeAddress,
    required String invoiceNumber,
    required DateTime dateTime,
  }) async {
    final bytes = formatReceipt(
      items: items,
      subtotal: subtotal,
      tax: tax,
      total: total,
      paymentMethod: paymentMethod,
      storeName: storeName,
      storeAddress: storeAddress,
      invoiceNumber: invoiceNumber,
      dateTime: dateTime,
    );
    await printBytes(bytes);
  }

  void dispose() {
    _stateSubscription?.cancel();
    _stateSubscription = null;
  }
}

/// Provider global untuk printer service.
final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService.instance;
});
