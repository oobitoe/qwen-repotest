import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../products/data/product_repository.dart';
import '../data/pos_entity.dart';
import '../data/pos_repository.dart';

/// Halaman POS/Kasir: keranjang belanja, diskon, pajak, pembayaran campuran,
/// dan checkout atomik.
class PosPage extends ConsumerStatefulWidget {
  const PosPage({super.key});

  @override
  ConsumerState<PosPage> createState() => _PosPageState();
}

class _PosPageState extends ConsumerState<PosPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  double _discount = 0;
  double _tax = 0;
  String _paymentMethod = 'cash';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);

    final subtotal = cart.fold(0.0, (s, i) => s + i.lineTotal);
    final total = subtotal - _discount + _tax;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pos)),
      body: Row(
        children: [
          // Left: product search & selection
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _ProductSearch(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  l10n: l10n,
                ),
                Expanded(
                  child: _ProductList(query: _query, l10n: l10n),
                ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          // Right: cart & checkout
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _CartSummary(
                  cart: cart,
                  subtotal: subtotal,
                  discount: _discount,
                  tax: _tax,
                  total: total,
                  l10n: l10n,
                  onDiscountChanged: (v) =>
                      setState(() => _discount = double.tryParse(v) ?? 0),
                  onTaxChanged: (v) =>
                      setState(() => _tax = double.tryParse(v) ?? 0),
                ),
                const Divider(height: 1),
                _PaymentSection(
                  l10n: l10n,
                  paymentMethod: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v),
                ),
                const Spacer(),
                _CheckoutBar(
                  l10n: l10n,
                  cart: cart,
                  total: total,
                  discount: _discount,
                  tax: _tax,
                  paymentMethod: _paymentMethod,
                  onCheckout: () => _checkout(context, cart, total, l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(
    BuildContext context,
    List<CartItem> cart,
    double total,
    AppLocalizations l10n,
  ) async {
    if (cart.isEmpty) return;

    final repo = ref.read(posRepositoryProvider);
    await repo.checkout(
      discount: _discount,
      tax: _tax,
      paymentMethod: _paymentMethod,
      isCredit: false,
      cashierId: 'kasir',
      paymentBreakdown: {_paymentMethod: total},
    );

    if (mounted) {
      setState(() {
        _discount = 0;
        _tax = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.checkout} berhasil')),
      );
    }
  }
}

class _ProductSearch extends ConsumerWidget {
  const _ProductSearch({
    required this.controller,
    required this.onChanged,
    required this.l10n,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: '${l10n.search} produk',
          prefixIcon: const Icon(AppIcons.search),
          filled: true,
          fillColor: themeColor(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ProductList extends ConsumerWidget {
  const _ProductList({required this.query, required this.l10n});

  final String query;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);

    return products.when(
      data: (items) {
        final filtered = query.isEmpty
            ? items.take(20).toList()
            : items.where((p) {
                  final q = query.toLowerCase();
                  return p.name.toLowerCase().contains(q) ||
                      p.sku.toLowerCase().contains(q);
                }).toList();
        if (filtered.isEmpty) {
          return Center(
            child: Text(l10n.noData, style: Theme.of(context).textTheme.bodyMedium),
          );
        }
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final p = filtered[i];
            return ListTile(
              leading: CircleAvatar(
                child: Text(p.sku.substring(0, 1).toUpperCase()),
              ),
              title: Text(p.name),
              subtitle: Text(_idr(p.sellPrice)),
              trailing: const Icon(AppIcons.add),
              onTap: () {
                ref.read(cartProvider.notifier).addItem(CartItem(
                  productId: p.id,
                  productName: p.name,
                  sku: p.sku,
                  unitPrice: p.sellPrice,
                  costPrice: p.costPrice,
                  quantity: 1,
                ));
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('$e')),
    );
  }

  String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.cart,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.l10n,
    required this.onDiscountChanged,
    required this.onTaxChanged,
  });

  final List<CartItem> cart;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final AppLocalizations l10n;
  final ValueChanged<String> onDiscountChanged;
  final ValueChanged<String> onTaxChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.keranjang, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          if (cart.isEmpty)
            Text('${l10n.keranjangKosong}',
                style: theme.textTheme.bodyMedium)
          else
            Column(
              children: [
                for (final item in cart)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName,
                        style: theme.textTheme.bodyMedium),
                    subtitle: Text('${item.sku}',
                        style: theme.textTheme.bodySmall),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${item.quantity}',
                            style: theme.textTheme.bodyMedium),
                        Text(_idr(item.lineTotal),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                _RowLabel(l10n.subtotal, _idr(subtotal), theme),
                _RowLabel('${l10n.diskon}', _idr(discount), theme,
                    isNegative: true),
                _RowLabel('${l10n.pajak}', _idr(tax), theme),
                const Divider(height: 1),
                _RowLabel(l10n.total, _idr(total), theme,
                    isBold: true, isPrimary: true),
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: '${l10n.diskon} (Rp)',
              prefixIcon: const Icon(AppIcons.discountRounded),
            ),
            keyboardType: TextInputType.number,
            onChanged: onDiscountChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            decoration: InputDecoration(
              labelText: '${l10n.pajak} (Rp)',
              prefixIcon: const Icon(AppIcons.taxRounded),
            ),
            keyboardType: TextInputType.number,
            onChanged: onTaxChanged,
          ),
        ],
      ),
    );
  }

  Widget _RowLabel(String label, String value, ThemeData theme,
      {bool isBold = false, bool isPrimary = false, bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPrimary
                    ? theme.colorScheme.primary
                    : isNegative
                        ? AppTheme.error
                        : null,
              )),
        ],
      ),
    );
  }

  String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }
}

ThemeData themeColor(BuildContext context) => Theme.of(context);

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.l10n,
    required this.paymentMethod,
    required this.onChanged,
  });

  final AppLocalizations l10n;
  final String paymentMethod;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.pembayaran, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: paymentMethod,
            decoration: InputDecoration(
              labelText: l10n.metodePembayaran,
              prefixIcon: const Icon(AppIcons.paymentRounded),
            ),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Tunai')),
              DropdownMenuItem(value: 'transfer', child: Text('Transfer')),
              DropdownMenuItem(value: 'qris', child: Text('QRIS')),
              DropdownMenuItem(value: 'card', child: Text('Kartu')),
              DropdownMenuItem(value: 'other', child: Text('Lainnya')),
            ],
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.l10n,
    required this.cart,
    required this.total,
    required this.discount,
    required this.tax,
    required this.paymentMethod,
    required this.onCheckout,
  });

  final AppLocalizations l10n;
  final List<CartItem> cart;
  final double total;
  final double discount;
  final double tax;
  final String paymentMethod;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _idr(total),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: cart.isEmpty ? null : onCheckout,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.checkoutRounded),
                    const SizedBox(width: AppSpacing.md),
                    Text(l10n.checkout,
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(
            onPressed: cart.isEmpty ? null : () {},
            child: Text(l10n.batal),
          ),
        ],
      ),
    );
  }

  String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }
}
