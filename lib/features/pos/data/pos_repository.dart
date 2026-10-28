import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/sync_dao.dart';
import '../../../shared/providers/core_providers.dart';
import 'pos_entity.dart';

/// Manajemen keranjang belanja dan checkout (POS).
class PosRepository {
  PosRepository(this._dao);

  final SyncableDao _dao;
  final List<CartItem> _cart = [];

  List<CartItem> get cart => List.unmodifiable(_cart);

  double get subtotal => _cart.fold(0, (sum, i) => sum + i.lineTotal);

  void addItem(CartItem item) {
    final existing = _cart.indexWhere((c) => c.productId == item.productId);
    if (existing >= 0) {
      _cart[existing] = _cart[existing].copyWith(
        quantity: _cart[existing].quantity + item.quantity,
      );
    } else {
      _cart.add(item);
    }
  }

  void removeItem(String productId) {
    _cart.removeWhere((c) => c.productId == productId);
  }

  void updateQuantity(String productId, double quantity) {
    final idx = _cart.indexWhere((c) => c.productId == productId);
    if (idx >= 0) {
      _cart[idx] = _cart[idx].copyWith(quantity: quantity);
      if (quantity <= 0) _cart.removeAt(idx);
    }
  }

  void clear() {
    _cart.clear();
  }

  Future<void> checkout({
    required double discount,
    required double tax,
    required String paymentMethod,
    required bool isCredit,
    required String cashierId,
    required Map<String, double> paymentBreakdown,
  }) async {
    final total = subtotal - discount + tax;
    final saleId = const Uuid().v4();

    await _dao.enqueue(
      entityType: 'sale',
      entityId: saleId,
      operation: 'upsert',
      payload: {
        'id': saleId,
        'invoice_number': 'INV-${DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '')}',
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'payment_method': paymentMethod,
        'is_credit': isCredit,
        'cashier_id': cashierId,
        'payment_breakdown': paymentBreakdown,
        'items': [
          for (final item in _cart)
            {
              'product_id': item.productId,
              'product_name': item.productName,
              'sku': item.sku,
              'unit_price': item.unitPrice,
              'cost_price': item.costPrice,
              'quantity': item.quantity,
              'line_total': item.lineTotal,
            },
        ],
      },
    );

    clear();
  }
}

final posRepositoryProvider = Provider<PosRepository>((ref) {
  final dao = ref.watch(syncDaoProvider);
  return PosRepository(dao);
});

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier(ref.read(posRepositoryProvider));
});

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier(this._repo) : super([]);

  final PosRepository _repo;

  List<CartItem> get cart => _repo.cart;

  double get subtotal => _repo.subtotal;

  void addItem(CartItem item) {
    _repo.addItem(item);
    state = [..._repo.cart];
  }

  void removeItem(String productId) {
    _repo.removeItem(productId);
    state = [..._repo.cart];
  }

  void updateQuantity(String productId, double quantity) {
    _repo.updateQuantity(productId, quantity);
    state = [..._repo.cart];
  }

  void clear() {
    _repo.clear();
    state = [];
  }
}
