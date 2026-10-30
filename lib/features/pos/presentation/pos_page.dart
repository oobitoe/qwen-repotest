import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:intl/intl.dart';

import '../../../app/theme/app_icons.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/design_tokens.dart';
import '../../../features/auth/application/auth_controller.dart';
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
  bool _isCredit = false;
  List<HoldTransactionEntity> _heldTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadHeldTransactions();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHeldTransactions() async {
    final repo = ref.read(posRepositoryProvider);
    final held = await repo.getHoldTransactions();
    if (mounted) {
      setState(() => _heldTransactions = held);
    }
  }

  String? _getCashierId(WidgetRef ref) {
    final auth = ref.read(authProvider);
    if (auth is AuthSignedIn) return auth.userId;
    return null;
  }

  Future<void> _checkout(
    WidgetRef ref,
    List<CartItem> cart,
    double total,
    AppLocalizations l10n,
  ) async {
    if (cart.isEmpty) return;

    final cashierId = _getCashierId(ref);
    if (cashierId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kasir belum login, tidak bisa checkout'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final repo = ref.read(posRepositoryProvider);
    try {
      await repo.checkout(
        discount: _discount,
        tax: _tax,
        paymentMethod: _paymentMethod,
        isCredit: _isCredit,
        cashierId: cashierId,
        paymentBreakdown: {_paymentMethod: total},
      );

      if (!mounted) return;
      setState(() {
        _discount = 0;
        _tax = 0;
        _isCredit = false;
        _paymentMethod = 'cash';
      });
      _loadHeldTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.checkout} berhasil'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Checkout gagal: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _holdTransaction(
    WidgetRef ref,
    List<CartItem> cart,
    double total,
    AppLocalizations l10n,
  ) async {
    if (cart.isEmpty) return;

    final cashierId = _getCashierId(ref);
    if (cashierId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kasir belum login, tidak bisa simpan transaksi'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final repo = ref.read(posRepositoryProvider);
    try {
      await repo.holdTransaction(
        discount: _discount,
        tax: _tax,
        paymentMethod: _paymentMethod,
        isCredit: _isCredit,
        cashierId: cashierId,
      );

      if (!mounted) return;
      setState(() {
        _discount = 0;
        _tax = 0;
        _isCredit = false;
        _paymentMethod = 'cash';
      });
      _loadHeldTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaksi ditahan'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menahan transaksi: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cart = ref.watch(cartProvider);

    final subtotal = cart.fold(0.0, (s, i) => s + i.lineTotal);
    final total = subtotal - _discount + _tax;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.tablet;
          return isWide
              ? _WideLayout(
                  l10n: l10n,
                  controller: _searchCtrl,
                  query: _query,
                  onQueryChanged: (v) => setState(() => _query = v),
                  cart: cart,
                  subtotal: subtotal,
                  discount: _discount,
                  tax: _tax,
                  total: total,
                  onDiscountChanged: (v) =>
                      setState(() => _discount = double.tryParse(v) ?? 0),
                  onTaxChanged: (v) =>
                      setState(() => _tax = double.tryParse(v) ?? 0),
                  paymentMethod: _paymentMethod,
                  onPaymentChanged: (v) =>
                      setState(() => _paymentMethod = v),
                  isCredit: _isCredit,
                  onCreditChanged: (v) => setState(() => _isCredit = v),
                   onCheckout: () => _checkout(ref, cart, total, l10n),
                   onHold: () => _holdTransaction(
                    ref, cart, total, l10n,
                  ),
                  heldTransactions: _heldTransactions,
                   onResumeHold: (holdId) => _resumeHold(ref, holdId),
                )
              : _NarrowLayout(
                  l10n: l10n,
                  controller: _searchCtrl,
                  query: _query,
                  onQueryChanged: (v) => setState(() => _query = v),
                  cart: cart,
                  subtotal: subtotal,
                  discount: _discount,
                  tax: _tax,
                  total: total,
                  onDiscountChanged: (v) =>
                      setState(() => _discount = double.tryParse(v) ?? 0),
                  onTaxChanged: (v) =>
                      setState(() => _tax = double.tryParse(v) ?? 0),
                  paymentMethod: _paymentMethod,
                  onPaymentChanged: (v) =>
                      setState(() => _paymentMethod = v),
                  isCredit: _isCredit,
                  onCreditChanged: (v) => setState(() => _isCredit = v),
                   onCheckout: () => _checkout(ref, cart, total, l10n),
                   onHold: () => _holdTransaction(
                    ref, cart, total, l10n,
                  ),
                  heldTransactions: _heldTransactions,
                   onResumeHold: (holdId) => _resumeHold(ref, holdId),
                );
        },
      ),
    );
  }

  Future<void> _resumeHold(
    WidgetRef ref,
    String holdId,
  ) async {
    final repo = ref.read(posRepositoryProvider);
    try {
      await repo.resumeHoldTransaction(holdId);
      if (!mounted) return;
      setState(() {
        _discount = 0;
        _tax = 0;
        _isCredit = false;
        _paymentMethod = 'cash';
      });
      _loadHeldTransactions();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Transaksi ditangguhkan dimuat ulang ke keranjang'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat ulang transaksi: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
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
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  static String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }
}

/// Layout layar lebar (tablet/desktop): produk di kiri, keranjang di kanan.
class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.l10n,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.cart,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onDiscountChanged,
    required this.onTaxChanged,
    required this.paymentMethod,
    required this.onPaymentChanged,
    required this.isCredit,
    required this.onCreditChanged,
    required this.onCheckout,
    required this.onHold,
    required this.heldTransactions,
    required this.onResumeHold,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<CartItem> cart;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final ValueChanged<String> onDiscountChanged;
  final ValueChanged<String> onTaxChanged;
  final String paymentMethod;
  final ValueChanged<String> onPaymentChanged;
  final bool isCredit;
  final ValueChanged<bool> onCreditChanged;
  final VoidCallback onCheckout;
  final VoidCallback onHold;
  final List<HoldTransactionEntity> heldTransactions;
  final ValueChanged<String> onResumeHold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _ProductSearch(
                controller: controller,
                onChanged: onQueryChanged,
                l10n: l10n,
              ),
              Expanded(
                child: _ProductList(query: query, l10n: l10n),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _CartSummary(
                cart: cart,
                subtotal: subtotal,
                discount: discount,
                tax: tax,
                total: total,
                l10n: l10n,
                onDiscountChanged: onDiscountChanged,
                onTaxChanged: onTaxChanged,
              ),
              const Divider(height: 1),
              _PaymentSection(
                l10n: l10n,
                paymentMethod: paymentMethod,
                onChanged: onPaymentChanged,
                isCredit: isCredit,
                onCreditChanged: onCreditChanged,
              ),
              if (heldTransactions.isNotEmpty) ...[
                const Divider(height: 1),
                _HeldTransactionsList(
                  l10n: l10n,
                  transactions: heldTransactions,
                  onResume: onResumeHold,
                ),
              ],
              const Spacer(),
              _CheckoutBar(
                l10n: l10n,
                cart: cart,
                total: total,
                discount: discount,
                tax: tax,
                paymentMethod: paymentMethod,
                isCredit: isCredit,
                onCheckout: onCheckout,
                onHold: onHold,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Layout layar sempit (mobile): produk di atas, keranjang di bawah.
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.l10n,
    required this.controller,
    required this.query,
    required this.onQueryChanged,
    required this.cart,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.onDiscountChanged,
    required this.onTaxChanged,
    required this.paymentMethod,
    required this.onPaymentChanged,
    required this.isCredit,
    required this.onCreditChanged,
    required this.onCheckout,
    required this.onHold,
    required this.heldTransactions,
    required this.onResumeHold,
  });

  final AppLocalizations l10n;
  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;
  final List<CartItem> cart;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final ValueChanged<String> onDiscountChanged;
  final ValueChanged<String> onTaxChanged;
  final String paymentMethod;
  final ValueChanged<String> onPaymentChanged;
  final bool isCredit;
  final ValueChanged<bool> onCreditChanged;
  final VoidCallback onCheckout;
  final VoidCallback onHold;
  final List<HoldTransactionEntity> heldTransactions;
  final ValueChanged<String> onResumeHold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _ProductSearch(
                controller: controller,
                onChanged: onQueryChanged,
                l10n: l10n,
              ),
              Expanded(
                child: _ProductList(query: query, l10n: l10n),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _CartSummary(
                cart: cart,
                subtotal: subtotal,
                discount: discount,
                tax: tax,
                total: total,
                l10n: l10n,
                onDiscountChanged: onDiscountChanged,
                onTaxChanged: onTaxChanged,
              ),
              const Divider(height: 1),
              _PaymentSection(
                l10n: l10n,
                paymentMethod: paymentMethod,
                onChanged: onPaymentChanged,
                isCredit: isCredit,
                onCreditChanged: onCreditChanged,
              ),
              if (heldTransactions.isNotEmpty) ...[
                const Divider(height: 1),
                _HeldTransactionsList(
                  l10n: l10n,
                  transactions: heldTransactions,
                  onResume: onResumeHold,
                ),
              ],
              const Spacer(),
              _CheckoutBar(
                l10n: l10n,
                cart: cart,
                total: total,
                discount: discount,
                tax: tax,
                paymentMethod: paymentMethod,
                isCredit: isCredit,
                onCheckout: onCheckout,
                onHold: onHold,
              ),
            ],
          ),
        ),
      ],
    );
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
            Text(l10n.keranjangKosong,
                style: theme.textTheme.bodyMedium)
          else
            Column(
              children: [
                for (final item in cart)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.productName,
                        style: theme.textTheme.bodyMedium),
                    subtitle: Text(item.sku,
                        style: theme.textTheme.bodySmall),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${item.quantity}',
                            style: theme.textTheme.bodyMedium),
                        Text(_CartSummary._idr(item.lineTotal),
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                const Divider(height: 1),
                _rowLabel(l10n.subtotal, _CartSummary._idr(subtotal), theme),
                _rowLabel(l10n.diskon, _CartSummary._idr(discount), theme,
                    isNegative: true),
                _rowLabel(l10n.pajak, _CartSummary._idr(tax), theme),
                const Divider(height: 1),
                _rowLabel(l10n.total, _CartSummary._idr(total), theme,
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

  Widget _rowLabel(String label, String value, ThemeData theme,
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

  static String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.l10n,
    required this.paymentMethod,
    required this.onChanged,
    required this.isCredit,
    required this.onCreditChanged,
  });

  final AppLocalizations l10n;
  final String paymentMethod;
  final ValueChanged<String> onChanged;
  final bool isCredit;
  final ValueChanged<bool> onCreditChanged;

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
            initialValue: paymentMethod,
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
          const SizedBox(height: AppSpacing.md),
          CheckboxListTile(
            title: Text(l10n.kredit),
            value: isCredit,
            onChanged: (v) => onCreditChanged(v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
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
    required this.isCredit,
    required this.onCheckout,
    required this.onHold,
  });

  final AppLocalizations l10n;
  final List<CartItem> cart;
  final double total;
  final double discount;
  final double tax;
  final String paymentMethod;
  final bool isCredit;
  final VoidCallback onCheckout;
  final VoidCallback onHold;

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
                  _CheckoutBar._idr(total),
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: cart.isEmpty ? null : onHold,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.clockRounded),
                    const SizedBox(width: AppSpacing.md),
                    Text(l10n.holdTransaction,
                        style: const TextStyle(fontSize: 14)),
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

  static String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }
}

/// Daftar transaksi yang ditahan (hold) untuk dilanjutkan.
class _HeldTransactionsList extends StatelessWidget {
  const _HeldTransactionsList({
    required this.l10n,
    required this.transactions,
    required this.onResume,
  });

  final AppLocalizations l10n;
  final List<HoldTransactionEntity> transactions;
  final ValueChanged<String> onResume;

  static String _idr(double v) {
    final nf = NumberFormat.simpleCurrency(
        locale: 'id_ID', name: 'Rp ', decimalDigits: 0);
    return nf.format(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.transactionsTertahan,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warning,
                  )),
              Text('${transactions.length}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.warning,
                  )),
            ],
          ),
        ),
        ...transactions.map((t) => ListTile(
          dense: true,
          leading: CircleAvatar(
            radius: 14,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            child: Text(t.invoiceNumber.substring(0, 1),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                )),
          ),
          title: Text(t.invoiceNumber,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              )),
          subtitle: Text(_idr(t.total),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          trailing: IconButton(
            icon: const Icon(AppIcons.playArrowRounded),
            onPressed: () => onResume(t.id),
            tooltip: l10n.lanjutkanTransaksi,
          ),
        )),
      ],
    );
  }
}
