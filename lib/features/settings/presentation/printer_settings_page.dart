import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_icons.dart';
import '../../../../app/theme/design_tokens.dart';
import '../../../../core/printer/printer_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../data/store_settings_repository.dart';

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

/// Halaman manajemen printer thermal Bluetooth.
class PrinterSettingsPage extends ConsumerStatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  ConsumerState<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends ConsumerState<PrinterSettingsPage> {
  final _printerService = PrinterService.instance;
  final List<BluetoothDeviceInfo> _devices = [];
  bool _isScanning = false;
  String? _selectedAddress;

  @override
  void initState() {
    super.initState();
    _loadCurrentPrinter();
  }

  @override
  void dispose() {
    _printerService.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPrinter() async {
    final repo = ref.read(storeSettingsRepositoryProvider);
    final settings = await repo.getSettings();
    if (mounted) {
      setState(() => _selectedAddress = settings.printerAddress);
    }
  }

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    try {
      final devices = await _printerService.scan(duration: const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _devices
            ..clear()
            ..addAll(devices.map((d) => BluetoothDeviceInfo(
                  id: d.id,
                  name: d.name,
                  address: d.address,
                )));
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal scan: $e')),
        );
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDeviceInfo device) async {
    try {
      setState(() => _isScanning = true);
      await _printerService.connect(device.id);

      // Simpan address ke settings
      final repo = ref.read(storeSettingsRepositoryProvider);
      final settings = await repo.getSettings();
      await repo.saveSettings(settings.copyWith(printerAddress: device.id));

      if (mounted) {
        setState(() {
          _selectedAddress = device.id;
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terhubung ke ${device.name}'),
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal terhubung: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _printerService.disconnect();

      final repo = ref.read(storeSettingsRepositoryProvider);
      final settings = await repo.getSettings();
      await repo.saveSettings(settings.copyWith(printerAddress: ''));

      if (mounted) {
        setState(() => _selectedAddress = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer terputus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal putuskan: $e')),
        );
      }
    }
  }

  Future<void> _printTest() async {
    if (_printerService.isConnected == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer belum terhubung')),
      );
      return;
    }

    try {
      await _printerService.printReceipt(
        items: [
          {'name': 'Produk Contoh 1', 'qty': 2, 'total': 20000},
          {'name': 'Produk Contoh 2', 'qty': 1, 'total': 15000},
        ],
        subtotal: 35000,
        tax: 3500,
        total: 38500,
        paymentMethod: 'Tunai',
        storeName: 'Toko Contoh',
        storeAddress: 'Jl. Contoh No. 1',
        invoiceNumber: 'TEST-0001',
        dateTime: DateTime.now(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Struk uji dicetak!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal cetak: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isConnected = _printerService.isConnected;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        AppIcons.printerRounded,
                        color: Color(0xFF16A34A),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.printerSettings,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isConnected
                                ? l10n.printerConnected
                                : l10n.printerDisconnected,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isConnected
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Printer address display
                if (_selectedAddress != null && _selectedAddress!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      children: [
                        const Icon(AppIcons.linkRounded, size: 16),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Printer: $_selectedAddress',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isConnected)
                          TextButton(
                            onPressed: _disconnect,
                            child: Text(l10n.disconnect),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Column(
              children: [
                // Scan button
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isScanning ? null : _startScan,
                      icon: _isScanning
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(AppIcons.bluetoothRounded),
                      label: Text(_isScanning
                          ? l10n.scanning
                          : l10n.scanPrinter),
                    ),
                  ),
                ),

                // Device list
                Expanded(
                  child: _devices.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                _isScanning
                                    ? l10n.scanning
                                    : l10n.noPrinterFound,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _devices.length,
                          itemBuilder: (context, index) {
                            final device = _devices[index];
                            final isSelected = _selectedAddress == device.id;
                            final isConnecting = _isScanning;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  isSelected
                                      ? AppIcons.linkRounded
                                      : AppIcons.bluetoothRounded,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                device.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(device.address),
                              trailing: isSelected && isConnected
                                  ? Icon(
                                      AppIcons.checkCircleRounded,
                                      color: theme.colorScheme.tertiary,
                                    )
                                  : null,
                              onTap: isConnecting
                                  ? null
                                  : () => _connectToDevice(device),
                            );
                          },
                        ),
                ),

                // Test print button
                if (_printerService.isConnected)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _printTest,
                        icon: const Icon(AppIcons.printerRounded),
                        label: Text(l10n.printTestReceipt),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
