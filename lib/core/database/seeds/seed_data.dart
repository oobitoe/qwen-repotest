import 'dart:math';

import 'package:drift/drift.dart';
import '../app_database.dart';

/// PocketBase pakai ID base58url 22 karakter (tanpa strip),
/// bukan UUID standar 36 karakter dengan strip seperti Supabase.
/// Generator ini menghasilkan ID 22 karakter yang aman untuk kolom
/// teks di Drift dan cocok dengan format ID PocketBase.
const _pbAlphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
final _pbRandom = Random.secure();

String _pbId() => List.generate(22, (_) => _pbAlphabet[_pbRandom.nextInt(_pbAlphabet.length)]).join();

/// Seed data alat listrik — dijalankan sekali saat DB pertama kali dibuat.
/// Minimal 3 bulan transaksi agar laporan/reporting bisa dites.
Future<void> seedDatabase(AppDatabase db) async {
  // Cek apakah sudah ada data
  final existingProducts = await db.select(db.products).get();
  if (existingProducts.isNotEmpty) return;

  final now = DateTime.now();
  final threeMonthsAgo = now.subtract(const Duration(days: 90));

  // ---------- Kategori ----------
  final categoryIds = {
    'Kabel & Konduktor': _pbId(),
    'Saklar & Stop Kontak': _pbId(),
    'Lampu & Pencahayaan': _pbId(),
    'MCB & Proteksi': _pbId(),
    'Alat Ukur': _pbId(),
    'Aksesoris Instalasi': _pbId(),
  };
  for (final entry in categoryIds.entries) {
    await db.into(db.categories).insert(CategoriesCompanion.insert(
          id: entry.value,
          name: entry.key,
          businessId: const Value('local'),
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
  }

  // ---------- Unit ----------
  final unitIds = {
    'pcs': _pbId(),
    'meter': _pbId(),
    'roll': _pbId(),
    'box': _pbId(),
    'set': _pbId(),
  };
  for (final entry in unitIds.entries) {
    await db.into(db.units).insert(UnitsCompanion.insert(
          id: entry.value,
          name: entry.key,
          abbreviation: entry.key,
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
  }

  // ---------- Supplier ----------
  final supplierIds = {
    'PT Sinar Jaya Elektrik': _pbId(),
    'CV Mega Listrik': _pbId(),
    'UD Berkah Elektrik': _pbId(),
  };
  for (final entry in supplierIds.entries) {
    await db.into(db.suppliers).insert(SuppliersCompanion.insert(
          id: entry.value,
          name: entry.key,
          phone: Value('08${_pbId().substring(0, 8)}'),
          email: Value('${entry.key.toLowerCase().replaceAll(' ', '')}@email.com'),
          address: const Value('Jakarta'),
          notes: const Value('Supplier alat listrik terpercaya'),
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
  }

  // ---------- Produk alat listrik ----------
  final products = <Map<String, dynamic>>[
    // Kabel & Konduktor
    {'name': 'Kabel NYA 1.5mm', 'sku': 'KBL-001', 'barcode': '8991234001001', 'cat': 'Kabel & Konduktor', 'unit': 'meter', 'cost': 3500.0, 'sell': 5000.0, 'wholesale': 4200.0, 'min': 100.0, 'stock': 500.0, 'desc': 'Kabel NYA 1.5mm 90 meter per roll'},
    {'name': 'Kabel NYA 2.5mm', 'sku': 'KBL-002', 'barcode': '8991234001002', 'cat': 'Kabel & Konduktor', 'unit': 'meter', 'cost': 5500.0, 'sell': 7500.0, 'wholesale': 6500.0, 'min': 100.0, 'stock': 400.0, 'desc': 'Kabel NYA 2.5mm 90 meter per roll'},
    {'name': 'Kabel NYY 3x1.5mm', 'sku': 'KBL-003', 'barcode': '8991234001003', 'cat': 'Kabel & Konduktor', 'unit': 'meter', 'cost': 12000.0, 'sell': 16000.0, 'wholesale': 14000.0, 'min': 50.0, 'stock': 200.0, 'desc': 'Kabel NYY 3x1.5mm 100 meter per roll'},
    {'name': 'Kabel NYY 4x2.5mm', 'sku': 'KBL-004', 'barcode': '8991234001004', 'cat': 'Kabel & Konduktor', 'unit': 'meter', 'cost': 25000.0, 'sell': 32000.0, 'wholesale': 28000.0, 'min': 30.0, 'stock': 150.0, 'desc': 'Kabel NYY 4x2.5mm 100 meter per roll'},
    {'name': 'Kabel Roll 3x1.5mm 50m', 'sku': 'KBL-005', 'barcode': '8991234001005', 'cat': 'Kabel & Konduktor', 'unit': 'roll', 'cost': 350000.0, 'sell': 450000.0, 'wholesale': 400000.0, 'min': 5.0, 'stock': 20.0, 'desc': 'Kabel Roll 3x1.5mm 50 meter'},
    // Saklar & Stop Kontak
    {'name': 'Saklar Tunggal Panasonic', 'sku': 'SKL-001', 'barcode': '8991234002001', 'cat': 'Saklar & Stop Kontak', 'unit': 'pcs', 'cost': 15000.0, 'sell': 25000.0, 'wholesale': 20000.0, 'min': 10.0, 'stock': 50.0, 'desc': 'Saklar tunggal Panasonic'},
    {'name': 'Saklar Ganda Panasonic', 'sku': 'SKL-002', 'barcode': '8991234002002', 'cat': 'Saklar & Stop Kontak', 'unit': 'pcs', 'cost': 22000.0, 'sell': 35000.0, 'wholesale': 28000.0, 'min': 10.0, 'stock': 40.0, 'desc': 'Saklar ganda Panasonic'},
    {'name': 'Stop Kontak Universal', 'sku': 'SKL-003', 'barcode': '8991234002003', 'cat': 'Saklar & Stop Kontak', 'unit': 'pcs', 'cost': 18000.0, 'sell': 30000.0, 'wholesale': 24000.0, 'min': 10.0, 'stock': 60.0, 'desc': 'Stop kontak universal 2 soket'},
    {'name': 'Stop Kontak + Saklar', 'sku': 'SKL-004', 'barcode': '8991234002004', 'cat': 'Saklar & Stop Kontak', 'unit': 'pcs', 'cost': 28000.0, 'sell': 45000.0, 'wholesale': 36000.0, 'min': 8.0, 'stock': 35.0, 'desc': 'Stop kontak dengan saklar'},
    {'name': 'Saklar Seri 4 Gang', 'sku': 'SKL-005', 'barcode': '8991234002005', 'cat': 'Saklar & Stop Kontak', 'unit': 'pcs', 'cost': 45000.0, 'sell': 70000.0, 'wholesale': 56000.0, 'min': 5.0, 'stock': 20.0, 'desc': 'Saklar seri 4 gang'},
    // Lampu & Pencahayaan
    {'name': 'Lampu LED 9W Philips', 'sku': 'LMP-001', 'barcode': '8991234003001', 'cat': 'Lampu & Pencahayaan', 'unit': 'pcs', 'cost': 25000.0, 'sell': 40000.0, 'wholesale': 32000.0, 'min': 20.0, 'stock': 100.0, 'desc': 'Lampu LED 9W Philips'},
    {'name': 'Lampu LED 12W Philips', 'sku': 'LMP-002', 'barcode': '8991234003002', 'cat': 'Lampu & Pencahayaan', 'unit': 'pcs', 'cost': 32000.0, 'sell': 50000.0, 'wholesale': 40000.0, 'min': 15.0, 'stock': 80.0, 'desc': 'Lampu LED 12W Philips'},
    {'name': 'Lampu LED 18W Philips', 'sku': 'LMP-003', 'barcode': '8991234003003', 'cat': 'Lampu & Pencahayaan', 'unit': 'pcs', 'cost': 45000.0, 'sell': 70000.0, 'wholesale': 56000.0, 'min': 10.0, 'stock': 60.0, 'desc': 'Lampu LED 18W Philips'},
    {'name': 'Lampu TL 18W', 'sku': 'LMP-004', 'barcode': '8991234003004', 'cat': 'Lampu & Pencahayaan', 'unit': 'pcs', 'cost': 15000.0, 'sell': 25000.0, 'wholesale': 20000.0, 'min': 20.0, 'stock': 75.0, 'desc': 'Lampu TL 18W'},
    {'name': 'Lampu Emergency 10W', 'sku': 'LMP-005', 'barcode': '8991234003005', 'cat': 'Lampu & Pencahayaan', 'unit': 'pcs', 'cost': 85000.0, 'sell': 125000.0, 'wholesale': 100000.0, 'min': 5.0, 'stock': 30.0, 'desc': 'Lampu emergency 10W baterai'},
    // MCB & Proteksi
    {'name': 'MCB 6A Schneider', 'sku': 'MCB-001', 'barcode': '8991234004001', 'cat': 'MCB & Proteksi', 'unit': 'pcs', 'cost': 45000.0, 'sell': 75000.0, 'wholesale': 60000.0, 'min': 10.0, 'stock': 40.0, 'desc': 'MCB 6A Schneider'},
    {'name': 'MCB 10A Schneider', 'sku': 'MCB-002', 'barcode': '8991234004002', 'cat': 'MCB & Proteksi', 'unit': 'pcs', 'cost': 48000.0, 'sell': 80000.0, 'wholesale': 64000.0, 'min': 10.0, 'stock': 35.0, 'desc': 'MCB 10A Schneider'},
    {'name': 'MCB 16A Schneider', 'sku': 'MCB-003', 'barcode': '8991234004003', 'cat': 'MCB & Proteksi', 'unit': 'pcs', 'cost': 52000.0, 'sell': 85000.0, 'wholesale': 68000.0, 'min': 10.0, 'stock': 30.0, 'desc': 'MCB 16A Schneider'},
    {'name': 'MCB 20A Schneider', 'sku': 'MCB-004', 'barcode': '8991234004004', 'cat': 'MCB & Proteksi', 'unit': 'pcs', 'cost': 55000.0, 'sell': 90000.0, 'wholesale': 72000.0, 'min': 8.0, 'stock': 25.0, 'desc': 'MCB 20A Schneider'},
    {'name': 'Surge Arrester 40kA', 'sku': 'MCB-005', 'barcode': '8991234004005', 'cat': 'MCB & Proteksi', 'unit': 'pcs', 'cost': 120000.0, 'sell': 185000.0, 'wholesale': 150000.0, 'min': 3.0, 'stock': 15.0, 'desc': 'Surge arrester 40kA'},
    // Alat Ukur
    {'name': 'Multimeter Digital', 'sku': 'UKR-001', 'barcode': '8991234005001', 'cat': 'Alat Ukur', 'unit': 'pcs', 'cost': 150000.0, 'sell': 250000.0, 'wholesale': 200000.0, 'min': 3.0, 'stock': 15.0, 'desc': 'Multimeter digital handheld'},
    {'name': 'Tang Ampere', 'sku': 'UKR-002', 'barcode': '8991234005002', 'cat': 'Alat Ukur', 'unit': 'pcs', 'cost': 280000.0, 'sell': 450000.0, 'wholesale': 360000.0, 'min': 2.0, 'stock': 8.0, 'desc': 'Tang ampere digital'},
    {'name': 'Tespen', 'sku': 'UKR-003', 'barcode': '8991234005003', 'cat': 'Alat Ukur', 'unit': 'pcs', 'cost': 15000.0, 'sell': 30000.0, 'wholesale': 24000.0, 'min': 10.0, 'stock': 40.0, 'desc': 'Tespen pemeriksa listrik'},
    {'name': 'Lux Meter', 'sku': 'UKR-004', 'barcode': '8991234005004', 'cat': 'Alat Ukur', 'unit': 'pcs', 'cost': 350000.0, 'sell': 550000.0, 'wholesale': 440000.0, 'min': 2.0, 'stock': 5.0, 'desc': 'Lux meter pengukur cahaya'},
    // Aksesoris Instalasi
    {'name': 'Isolasi Hitam 10m', 'sku': 'AKS-001', 'barcode': '8991234006001', 'cat': 'Aksesoris Instalasi', 'unit': 'pcs', 'cost': 8000.0, 'sell': 15000.0, 'wholesale': 12000.0, 'min': 20.0, 'stock': 100.0, 'desc': 'Isolasi hitam 10 meter'},
    {'name': 'Klem Kabel 1/2"', 'sku': 'AKS-002', 'barcode': '8991234006002', 'cat': 'Aksesoris Instalasi', 'unit': 'pcs', 'cost': 2000.0, 'sell': 5000.0, 'wholesale': 4000.0, 'min': 50.0, 'stock': 200.0, 'desc': 'Klem kabel 1/2 inci'},
    {'name': 'Duct Tape 2"', 'sku': 'AKS-003', 'barcode': '8991234006003', 'cat': 'Aksesoris Instalasi', 'unit': 'pcs', 'cost': 12000.0, 'sell': 20000.0, 'wholesale': 16000.0, 'min': 15.0, 'stock': 60.0, 'desc': 'Duct tape 2 inci'},
    {'name': 'Conduit 3/4" 4m', 'sku': 'AKS-004', 'barcode': '8991234006004', 'cat': 'Aksesoris Instalasi', 'unit': 'pcs', 'cost': 18000.0, 'sell': 30000.0, 'wholesale': 24000.0, 'min': 20.0, 'stock': 80.0, 'desc': 'Conduit 3/4 inci 4 meter'},
    {'name': 'Box Panel 4 Modul', 'sku': 'AKS-005', 'barcode': '8991234006005', 'cat': 'Aksesoris Instalasi', 'unit': 'pcs', 'cost': 35000.0, 'sell': 55000.0, 'wholesale': 44000.0, 'min': 5.0, 'stock': 25.0, 'desc': 'Box panel 4 modul'},
  ];

  final productIds = <String, String>{};
  for (final p in products) {
    final id = _pbId();
    productIds[p['sku'] as String] = id;
    await db.into(db.products).insert(ProductsCompanion.insert(
          id: id,
          businessId: const Value('local'),
          sku: p['sku'] as String,
          barcode: Value(p['barcode'] as String),
          name: p['name'] as String,
          description: Value(p['desc'] as String),
          categoryId: Value(categoryIds[p['cat'] as String]),
          unitId: Value(unitIds[p['unit'] as String]),
          costPrice: Value(p['cost'] as double),
          sellPrice: p['sell'] as double,
          wholesalePrice: Value(p['wholesale'] as double),
          minStock: Value(p['min'] as double),
          stock: Value(p['stock'] as double),
          isActive: const Value(true),
          imageUrl: const Value('https://via.placeholder.com/300x300.png?text=Produk'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
  }

  // ---------- Customer ----------
  final customerIds = <String>[];
  final customerNames = [
    'Budi Santoso',
    'Ani Wijaya',
    'Cahyo Pratama',
    'Dewi Lestari',
    'Eko Saputra',
    'Fitri Handayani',
    'Gunawan Hadi',
    'Hesti Rahayu',
  ];
  for (final name in customerNames) {
    final id = _pbId();
    customerIds.add(id);
    await db.into(db.customers).insert(CustomersCompanion.insert(
          id: id,
          code: Value('C${customerIds.length.toString().padLeft(3, '0')}'),
          name: name,
          phone: Value('08${_pbId().substring(0, 8)}'),
          email: Value('${name.toLowerCase().replaceAll(' ', '')}@email.com'),
          address: const Value('Jakarta'),
          notes: const Value('Pelanggan reguler'),
          tier: Value(['Regular', 'VIP', 'Wholesale'][_pbId().hashCode % 3]),
          rewardPoints: const Value(0),
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
  }

  // ---------- Expense Categories ----------
  final expenseCatIds = {
    'Listrik & Air': _pbId(),
    'Gaji Karyawan': _pbId(),
    'Sewa Toko': _pbId(),
    'Transportasi': _pbId(),
    'Peralatan': _pbId(),
  };
  for (final entry in expenseCatIds.entries) {
    await db.into(db.expenseCategories).insert(ExpenseCategoriesCompanion.insert(
          id: entry.value,
          name: entry.key,
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
  }

  // ---------- Income Categories ----------
  final incomeCatIds = {
    'Penjualan': _pbId(),
    'Jasa Instalasi': _pbId(),
    'Lain-lain': _pbId(),
  };
  for (final entry in incomeCatIds.entries) {
    await db.into(db.incomeCategories).insert(IncomeCategoriesCompanion.insert(
          id: entry.value,
          name: entry.key,
          isActive: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
  }

  // ---------- Cash Register ----------
  final registerId = _pbId();
  await db.into(db.cashRegisters).insert(CashRegistersCompanion.insert(
        id: registerId,
        businessId: const Value('local'),
        name: 'Kasir Utama',
        openingBalance: const Value(500000.0),
        isActive: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

  // ---------- Transaksi penjualan 3 bulan terakhir ----------
  final random = _SeededRandom(42);
  final paymentMethods = ['cash', 'card', 'qris', 'transfer'];
  final skus = productIds.keys.toList();
  int invoiceCounter = 1;

  // Generate sales per hari selama 3 bulan (random 3-8 transaksi/hari)
  var currentDate = threeMonthsAgo;
  while (currentDate.isBefore(now)) {
    final txCount = 3 + random.nextInt(6);
    for (int t = 0; t < txCount; t++) {
      final saleId = _pbId();
      final invoiceNumber = 'INV-${currentDate.year}${currentDate.month.toString().padLeft(2, '0')}${currentDate.day.toString().padLeft(2, '0')}-${invoiceCounter.toString().padLeft(4, '0')}';
      invoiceCounter++;

      // Pilih 1-5 item per transaksi
      final itemCount = 1 + random.nextInt(5);
      final selectedSkus = <String>[];
      for (int i = 0; i < itemCount; i++) {
        selectedSkus.add(skus[random.nextInt(skus.length)]);
      }

      double subtotal = 0;
      final saleItemsCompanions = <SaleItemsCompanion>[];
      for (final sku in selectedSkus.toSet()) {
        final productId = productIds[sku]!;
        final product = products.firstWhere((p) => p['sku'] == sku);
        final qty = (1 + random.nextInt(5)).toDouble();
        final unitPrice = product['sell'] as double;
        final lineTotal = qty * unitPrice;
        subtotal += lineTotal;

        saleItemsCompanions.add(SaleItemsCompanion.insert(
              id: _pbId(),
              saleId: saleId,
              productId: productId,
              productName: product['name'] as String,
              sku: Value(sku),
              unitPrice: unitPrice,
              costPrice: Value(product['cost'] as double),
              quantity: qty,
              discount: const Value(0.0),
              lineTotal: lineTotal,
              createdAt: Value(currentDate),
            ));
      }

      final discount = random.nextDouble() < 0.3 ? (subtotal * 0.05).roundToDouble() : 0.0;
      final tax = (subtotal - discount) * 0.11;
      final total = subtotal - discount + tax;
      final paid = total + (random.nextDouble() < 0.2 ? random.nextInt(50000) : 0);
      final changeDue = paid - total;
      final isCredit = random.nextDouble() < 0.1;
      final paymentMethod = paymentMethods[random.nextInt(paymentMethods.length)];
      final customerName = random.nextDouble() < 0.6 ? customerNames[random.nextInt(customerNames.length)] : null;

      final saleDate = currentDate.add(Duration(hours: 8 + random.nextInt(10), minutes: random.nextInt(60)));

      await db.into(db.sales).insert(SalesCompanion.insert(
            id: saleId,
            invoiceNumber: invoiceNumber,
            customerNameSnapshot: Value(customerName),
            subtotal: subtotal,
            discount: Value(discount),
            tax: Value(tax),
            total: total,
            paid: Value(paid),
            changeDue: Value(changeDue),
            paymentMethod: Value(paymentMethod),
            isCredit: Value(isCredit),
            status: const Value('completed'),
            cashierId: const Value('local'),
            note: const Value('Transaksi seed data'),
            createdAt: Value(saleDate),
            updatedAt: Value(saleDate),
          ));

      for (final item in saleItemsCompanions) {
        await db.into(db.saleItems).insert(item);
      }

      // Stock movement untuk setiap item
      for (final sku in selectedSkus.toSet()) {
        final product = products.firstWhere((p) => p['sku'] == sku);
        final qty = saleItemsCompanions
            .firstWhere((i) => i.productName.value == product['name'])
            .quantity
            .value;
        await db.into(db.stockMovements).insert(StockMovementsCompanion.insert(
              id: _pbId(),
              productId: productIds[sku]!,
              type: 'sale',
              quantity: -qty,
              balanceAfter: (product['stock'] as double) - qty,
              referenceType: const Value('sale'),
              referenceId: Value(saleId),
              note: const Value('Penjualan'),
              createdBy: const Value('local'),
              createdAt: Value(saleDate),
            ));
      }

      // Cash movement
      await db.into(db.cashMovements).insert(CashMovementsCompanion.insert(
            id: _pbId(),
            type: 'sale',
            amount: total,
            referenceType: const Value('sale'),
            referenceId: Value(saleId),
            note: const Value('Penerimaan penjualan'),
            createdBy: const Value('local'),
            createdAt: Value(saleDate),
          ));
    }

    currentDate = currentDate.add(const Duration(days: 1));
  }

  // ---------- Pengeluaran (bulanan) ----------
  final expenseDescs = [
    'Bayar listrik bulan ini',
    'Gaji karyawan',
    'Sewa toko bulanan',
    'Bensin pengiriman',
    'Beli rak display baru',
    'Perbaikan AC',
    'Internet & telepon',
  ];
  for (int m = 0; m < 3; m++) {
    final monthDate = now.subtract(Duration(days: 30 * (2 - m)));
    for (int e = 0; e < 5; e++) {
      final catKeys = expenseCatIds.keys.toList();
      final catKey = catKeys[random.nextInt(catKeys.length)];
      final amount = (50000 + random.nextInt(500000)).toDouble();
      await db.into(db.expenses).insert(ExpensesCompanion.insert(
            id: _pbId(),
            categoryId: Value(expenseCatIds[catKey]),
            description: expenseDescs[random.nextInt(expenseDescs.length)],
            amount: amount,
            paymentMethod: const Value('cash'),
            createdBy: const Value('local'),
            createdAt: Value(monthDate.add(Duration(days: random.nextInt(28)))),
            updatedAt: Value(now),
          ));
    }
  }

  // ---------- Pemasukan lain ----------
  for (int i = 0; i < 15; i++) {
    final catKeys = incomeCatIds.keys.toList();
    final catKey = catKeys[random.nextInt(catKeys.length)];
    final amount = (100000 + random.nextInt(1000000)).toDouble();
    await db.into(db.incomeEntries).insert(IncomeEntriesCompanion.insert(
          id: _pbId(),
          categoryId: Value(incomeCatIds[catKey]),
          description: 'Pemasukan ${catKey.toLowerCase()}',
          amount: amount,
          paymentMethod: const Value('cash'),
          createdBy: const Value('local'),
          createdAt: Value(threeMonthsAgo.add(Duration(days: random.nextInt(90)))),
          updatedAt: Value(now),
        ));
  }

  // ---------- Hutang/Piutang sample ----------
  final debtId = _pbId();
  await db.into(db.debts).insert(DebtsCompanion.insert(
        id: debtId,
        businessId: const Value('local'),
        supplierId: Value(supplierIds.values.first),
        customerId: const Value(null),
        type: 'payable',
        amount: const Value(5000000.0),
        paidAmount: const Value(2000000.0),
        status: const Value('partially_paid'),
        dueDate: Value(now.add(const Duration(days: 30))),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));
  await db.into(db.debtPayments).insert(DebtPaymentsCompanion.insert(
        id: _pbId(),
        debtId: debtId,
        amount: 2000000.0,
        paidAt: Value(now),
        createdBy: const Value('local'),
      ));

  // ---------- Audit log sample ----------
  final auditEntries = <Map<String, dynamic>>[
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'dataImport',
      'entityType': 'system',
      'entityId': 'seed',
      'description': 'Seed data awal alat listrik + 3 bulan transaksi',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(days: 1)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'create',
      'entityType': 'supplier',
      'entityId': supplierIds.values.first,
      'description': 'Menambahkan supplier PT Sinar Jaya Elektrik',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(hours: 5)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'create',
      'entityType': 'supplier',
      'entityId': supplierIds.values.elementAt(1),
      'description': 'Menambahkan supplier CV Mega Listrik',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(hours: 4)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'update',
      'entityType': 'product',
      'entityId': productIds.values.first,
      'description': 'Mengubah harga jual Kabel NYA 1.5mm dari Rp 4.500 menjadi Rp 5.000',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(hours: 3)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'login',
      'entityType': 'auth',
      'entityId': _pbId(),
      'description': 'Admin masuk ke aplikasi',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(hours: 2)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'sale',
      'entityType': 'sale',
      'entityId': _pbId(),
      'description': 'Transaksi penjualan sebesar Rp 125.000',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(hours: 1)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'stockAdjustment',
      'entityType': 'stock_adjustment',
      'entityId': _pbId(),
      'description': 'Penyesuaian stok Multimeter Digital: 15 → 12',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(minutes: 45)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'logout',
      'entityType': 'auth',
      'entityId': _pbId(),
      'description': 'Admin keluar dari aplikasi',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(minutes: 30)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'create',
      'entityType': 'customer',
      'entityId': customerIds.first,
      'description': 'Menambahkan pelanggan Budi Santoso',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(minutes: 15)),
    },
    {
      'userId': 'local',
      'userName': 'Admin',
      'action': 'settingsChange',
      'entityType': 'settings',
      'entityId': _pbId(),
      'description': 'Mengubah preset tema dari forest menjadi sunset',
      'createdAt': DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
    },
  ];

  for (final entry in auditEntries) {
    await db.into(db.auditLogs).insert(AuditLogsCompanion.insert(
      id: _pbId(),
      userId: entry['userId'] as String,
      userName: entry['userName'] as String,
      action: entry['action'] as String,
      entityType: entry['entityType'] as String,
      entityId: entry['entityId'] as String,
      description: entry['description'] as String,
      oldValue: const Value(null),
      newValue: const Value(null),
      ipAddress: const Value(null),
      deviceInfo: const Value(null),
      createdAt: Value(entry['createdAt'] as DateTime),
    ));
  }
}

/// Simple seeded random untuk reproducibility.
class _SeededRandom {
  int _state;
  _SeededRandom(this._state);

  int nextInt(int max) {
    _state = (_state * 1103515245 + 12345) & 0x7fffffff;
    return _state % max;
  }

  double nextDouble() {
    return nextInt(10000) / 10000.0;
  }
}
