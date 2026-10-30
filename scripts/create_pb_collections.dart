/// Skrip otomatisasi pembuatan koleksi PocketBase sesuai tabel Drift di proyek POS.
///
/// Cara pakai:
///   dart run scripts/create_pb_collections.dart
///
/// Pastikan server PocketBase berjalan di http://127.0.0.1:8090
/// dan admin sudah terdaftar (email/password di bawah).
// ignore_for_file: avoid_print
library;

import 'package:pocketbase/pocketbase.dart';

const pbUrl = 'http://127.0.0.1:8090';
const adminEmail = 'qsk3.me@gmail.com';
const adminPassword = 'qwerty123';

/// Definisi koleksi: [nama] -> daftar [field] (nama, tipe, opsi).
/// Tipe yang didukung: text, email, number, bool, date, json, relation.
final Map<String, List<Map<String, dynamic>>> collections = {
  // ---------- Organisasi & pengguna ----------
  'businesses': [
    {'name': 'name', 'type': 'text'},
    {'name': 'currency', 'type': 'text'},
    {'name': 'timezone', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'stores': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'name', 'type': 'text'},
    {'name': 'address', 'type': 'text'},
    {'name': 'phone', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'profiles': [
    {'name': 'email', 'type': 'email'},
    {'name': 'full_name', 'type': 'text'},
    {'name': 'role', 'type': 'text'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],

  // ---------- Produk ----------
  'categories': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'name', 'type': 'text'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'units': [
    {'name': 'name', 'type': 'text'},
    {'name': 'abbreviation', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'products': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'sku', 'type': 'text'},
    {'name': 'barcode', 'type': 'text'},
    {'name': 'name', 'type': 'text'},
    {'name': 'description', 'type': 'text'},
    {'name': 'category', 'type': 'relation', 'collection': 'categories'},
    {'name': 'unit', 'type': 'relation', 'collection': 'units'},
    {'name': 'cost_price', 'type': 'number'},
    {'name': 'sell_price', 'type': 'number'},
    {'name': 'wholesale_price', 'type': 'number'},
    {'name': 'min_stock', 'type': 'number'},
    {'name': 'stock', 'type': 'number'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
    {'name': 'image_url', 'type': 'text'},
  ],
  'product_variants': [
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'name', 'type': 'text'},
    {'name': 'sku', 'type': 'text'},
    {'name': 'price_modifier', 'type': 'number'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'product_barcodes': [
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'barcode', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'product_prices': [
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'price', 'type': 'number'},
    {'name': 'start_date', 'type': 'date'},
    {'name': 'end_date', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'product_images': [
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'url', 'type': 'text'},
    {'name': 'storage_path', 'type': 'text'},
    {'name': 'is_primary', 'type': 'bool'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'stock_movements': [
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'type', 'type': 'text'},
    {'name': 'quantity', 'type': 'number'},
    {'name': 'balance_after', 'type': 'number'},
    {'name': 'reference_type', 'type': 'text'},
    {'name': 'reference_id', 'type': 'text'},
    {'name': 'note', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],

  // ---------- Pelanggan & Supplier ----------
  'suppliers': [
    {'name': 'name', 'type': 'text'},
    {'name': 'phone', 'type': 'text'},
    {'name': 'email', 'type': 'email'},
    {'name': 'address', 'type': 'text'},
    {'name': 'notes', 'type': 'text'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'customers': [
    {'name': 'code', 'type': 'text'},
    {'name': 'name', 'type': 'text'},
    {'name': 'phone', 'type': 'text'},
    {'name': 'email', 'type': 'email'},
    {'name': 'address', 'type': 'text'},
    {'name': 'notes', 'type': 'text'},
    {'name': 'tier', 'type': 'text'},
    {'name': 'reward_points', 'type': 'number'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'customer_addresses': [
    {'name': 'customer', 'type': 'relation', 'collection': 'customers'},
    {'name': 'label', 'type': 'text'},
    {'name': 'address', 'type': 'text'},
    {'name': 'is_default', 'type': 'bool'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],

  // ---------- Inventaris ----------
  'stock_adjustments': [
    {'name': 'reference_number', 'type': 'text'},
    {'name': 'note', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'stock_adjustment_items': [
    {'name': 'adjustment', 'type': 'relation', 'collection': 'stock_adjustments'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'quantity_before', 'type': 'number'},
    {'name': 'quantity_after', 'type': 'number'},
    {'name': 'reason', 'type': 'text'},
  ],
  'stock_opnames': [
    {'name': 'reference_number', 'type': 'text'},
    {'name': 'status', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'approved_at', 'type': 'date'},
  ],
  'stock_opname_items': [
    {'name': 'opname', 'type': 'relation', 'collection': 'stock_opnames'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'system_stock', 'type': 'number'},
    {'name': 'counted_stock', 'type': 'number'},
  ],
  'stock_transfers': [
    {'name': 'from_store', 'type': 'relation', 'collection': 'stores'},
    {'name': 'to_store', 'type': 'relation', 'collection': 'stores'},
    {'name': 'reference_number', 'type': 'text'},
    {'name': 'status', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'stock_transfer_items': [
    {'name': 'transfer', 'type': 'relation', 'collection': 'stock_transfers'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'quantity', 'type': 'number'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],

  // ---------- Penjualan (POS) ----------
  'sales': [
    {'name': 'invoice_number', 'type': 'text'},
    {'name': 'customer_name_snapshot', 'type': 'text'},
    {'name': 'subtotal', 'type': 'number'},
    {'name': 'discount', 'type': 'number'},
    {'name': 'tax', 'type': 'number'},
    {'name': 'total', 'type': 'number'},
    {'name': 'paid', 'type': 'number'},
    {'name': 'change_due', 'type': 'number'},
    {'name': 'payment_method', 'type': 'text'},
    {'name': 'is_credit', 'type': 'bool'},
    {'name': 'status', 'type': 'text'},
    {'name': 'cashier_id', 'type': 'text'},
    {'name': 'note', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'sale_items': [
    {'name': 'sale', 'type': 'relation', 'collection': 'sales'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'product_name', 'type': 'text'},
    {'name': 'sku', 'type': 'text'},
    {'name': 'unit_price', 'type': 'number'},
    {'name': 'cost_price', 'type': 'number'},
    {'name': 'quantity', 'type': 'number'},
    {'name': 'discount', 'type': 'number'},
    {'name': 'line_total', 'type': 'number'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'sale_payments': [
    {'name': 'sale', 'type': 'relation', 'collection': 'sales'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'payment_method', 'type': 'text'},
    {'name': 'paid_at', 'type': 'date'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'sale_returns': [
    {'name': 'sale', 'type': 'relation', 'collection': 'sales'},
    {'name': 'reference_number', 'type': 'text'},
    {'name': 'total', 'type': 'number'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'sale_return_items': [
    {'name': 'return', 'type': 'relation', 'collection': 'sale_returns'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'quantity', 'type': 'number'},
    {'name': 'unit_price', 'type': 'number'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],

  // ---------- Pembelian ----------
  'purchases': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'reference_number', 'type': 'text'},
    {'name': 'supplier', 'type': 'relation', 'collection': 'suppliers'},
    {'name': 'supplier_name', 'type': 'text'},
    {'name': 'status', 'type': 'text'},
    {'name': 'subtotal', 'type': 'number'},
    {'name': 'discount', 'type': 'number'},
    {'name': 'tax', 'type': 'number'},
    {'name': 'total', 'type': 'number'},
    {'name': 'payment_method', 'type': 'text'},
    {'name': 'is_credit', 'type': 'bool'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'purchase_items': [
    {'name': 'purchase', 'type': 'relation', 'collection': 'purchases'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'product_name', 'type': 'text'},
    {'name': 'sku', 'type': 'text'},
    {'name': 'unit_price', 'type': 'number'},
    {'name': 'cost_price', 'type': 'number'},
    {'name': 'quantity', 'type': 'number'},
    {'name': 'received_quantity', 'type': 'number'},
    {'name': 'line_total', 'type': 'number'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'purchase_payments': [
    {'name': 'purchase', 'type': 'relation', 'collection': 'purchases'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'payment_method', 'type': 'text'},
    {'name': 'paid_at', 'type': 'date'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'purchase_orders': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'supplier', 'type': 'relation', 'collection': 'suppliers'},
    {'name': 'reference_number', 'type': 'text'},
    {'name': 'status', 'type': 'text'},
    {'name': 'subtotal', 'type': 'number'},
    {'name': 'discount', 'type': 'number'},
    {'name': 'tax', 'type': 'number'},
    {'name': 'total', 'type': 'number'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'purchase_order_items': [
    {'name': 'order', 'type': 'relation', 'collection': 'purchase_orders'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'product_name_snapshot', 'type': 'text'},
    {'name': 'sku', 'type': 'text'},
    {'name': 'unit_price', 'type': 'number'},
    {'name': 'quantity', 'type': 'number'},
    {'name': 'received_quantity', 'type': 'number'},
    {'name': 'line_total', 'type': 'number'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'purchase_returns': [
    {'name': 'purchase', 'type': 'relation', 'collection': 'purchases'},
    {'name': 'reference_number', 'type': 'text'},
    {'name': 'total', 'type': 'number'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'purchase_return_items': [
    {'name': 'return', 'type': 'relation', 'collection': 'purchase_returns'},
    {'name': 'product', 'type': 'relation', 'collection': 'products'},
    {'name': 'quantity', 'type': 'number'},
    {'name': 'unit_price', 'type': 'number'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],

  // ---------- Keuangan ----------
  'expense_categories': [
    {'name': 'name', 'type': 'text'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'expenses': [
    {'name': 'category', 'type': 'relation', 'collection': 'expense_categories'},
    {'name': 'description', 'type': 'text'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'payment_method', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'income_categories': [
    {'name': 'name', 'type': 'text'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'income_entries': [
    {'name': 'category', 'type': 'relation', 'collection': 'income_categories'},
    {'name': 'description', 'type': 'text'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'payment_method', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'cash_registers': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'name', 'type': 'text'},
    {'name': 'opening_balance', 'type': 'number'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'cash_sessions': [
    {'name': 'register', 'type': 'relation', 'collection': 'cash_registers'},
    {'name': 'opened_by', 'type': 'text'},
    {'name': 'opened_at', 'type': 'date'},
    {'name': 'closed_at', 'type': 'date'},
    {'name': 'opening_balance', 'type': 'number'},
    {'name': 'expected_balance', 'type': 'number'},
    {'name': 'actual_balance', 'type': 'number'},
    {'name': 'difference', 'type': 'number'},
    {'name': 'status', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'cash_movements': [
    {'name': 'session', 'type': 'relation', 'collection': 'cash_sessions'},
    {'name': 'type', 'type': 'text'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'reference_type', 'type': 'text'},
    {'name': 'reference_id', 'type': 'text'},
    {'name': 'note', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'accounts': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'name', 'type': 'text'},
    {'name': 'type', 'type': 'text'},
    {'name': 'balance', 'type': 'number'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'account_transactions': [
    {'name': 'account', 'type': 'relation', 'collection': 'accounts'},
    {'name': 'type', 'type': 'text'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'reference_type', 'type': 'text'},
    {'name': 'reference_id', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'debts': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'supplier', 'type': 'relation', 'collection': 'suppliers'},
    {'name': 'customer', 'type': 'relation', 'collection': 'customers'},
    {'name': 'type', 'type': 'text'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'paid_amount', 'type': 'number'},
    {'name': 'status', 'type': 'text'},
    {'name': 'due_date', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'debt_payments': [
    {'name': 'debt', 'type': 'relation', 'collection': 'debts'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'paid_at', 'type': 'date'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'financial_adjustments': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'description', 'type': 'text'},
    {'name': 'amount', 'type': 'number'},
    {'name': 'type', 'type': 'text'},
    {'name': 'created_by', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],

  // ---------- Konfigurasi & Akses ----------
  'business_settings': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'key', 'type': 'text'},
    {'name': 'value', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'store_settings': [
    {'name': 'store', 'type': 'relation', 'collection': 'stores'},
    {'name': 'key', 'type': 'text'},
    {'name': 'value', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'tax_settings': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'name', 'type': 'text'},
    {'name': 'rate', 'type': 'number'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'payment_methods_config': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'code', 'type': 'text'},
    {'name': 'name', 'type': 'text'},
    {'name': 'is_active', 'type': 'bool'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'devices': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'device_id', 'type': 'text'},
    {'name': 'name', 'type': 'text'},
    {'name': 'last_seen_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'roles': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'name', 'type': 'text'},
    {'name': 'description', 'type': 'text'},
    {'name': 'is_system', 'type': 'bool'},
    {'name': 'deleted_at', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'permissions': [
    {'name': 'code', 'type': 'text'},
    {'name': 'description', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'role_permissions': [
    {'name': 'role', 'type': 'relation', 'collection': 'roles'},
    {'name': 'permission', 'type': 'relation', 'collection': 'permissions'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'business_members': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'user_id', 'type': 'text'},
    {'name': 'role', 'type': 'text'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'user_store_access': [
    {'name': 'user_id', 'type': 'text'},
    {'name': 'store', 'type': 'relation', 'collection': 'stores'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'sale_sequences': [
    {'name': 'business', 'type': 'relation', 'collection': 'businesses'},
    {'name': 'store', 'type': 'relation', 'collection': 'stores'},
    {'name': 'prefix', 'type': 'text'},
    {'name': 'last_number', 'type': 'number'},
    {'name': 'date', 'type': 'date'},
    {'name': 'version', 'type': 'number'},
    {'name': 'sync_status', 'type': 'text'},
  ],
  'audit_logs': [
    {'name': 'user_id', 'type': 'text'},
    {'name': 'user_name', 'type': 'text'},
    {'name': 'action', 'type': 'text'},
    {'name': 'entity_type', 'type': 'text'},
    {'name': 'entity_id', 'type': 'text'},
    {'name': 'description', 'type': 'text'},
    {'name': 'old_value', 'type': 'text'},
    {'name': 'new_value', 'type': 'text'},
    {'name': 'ip_address', 'type': 'text'},
    {'name': 'device_info', 'type': 'text'},
  ],
};

/// Urutan pembuatan agar relasi terpenuhi (koleksi tujuan dibuat dulu).
final List<String> order = [
  'businesses', 'stores', 'profiles',
  'categories', 'units', 'products', 'product_variants', 'product_barcodes',
  'product_prices', 'product_images', 'stock_movements',
  'suppliers', 'customers', 'customer_addresses',
  'stock_adjustments', 'stock_opnames', 'stock_transfers',
  'sales', 'purchases', 'purchase_orders', 'expense_categories',
  'income_categories', 'cash_registers', 'accounts', 'debts',
  'financial_adjustments', 'roles', 'permissions',
  'stock_adjustment_items', 'stock_opname_items', 'stock_transfer_items',
  'sale_items', 'sale_payments', 'sale_returns', 'sale_return_items',
  'purchase_items', 'purchase_payments', 'purchase_order_items',
  'purchase_returns', 'purchase_return_items',
  'expenses', 'income_entries', 'cash_sessions', 'cash_movements',
  'account_transactions', 'debt_payments',
  'business_settings', 'store_settings', 'tax_settings',
  'payment_methods_config', 'devices', 'role_permissions',
  'business_members', 'user_store_access', 'sale_sequences', 'audit_logs',
];

Future<void> main() async {
  final pb = PocketBase(pbUrl);

  // 1. Autentikasi admin
  print('🔐 Mengautentikasi admin PocketBase...');
  try {
    await pb.admins.authWithPassword(adminEmail, adminPassword);
    print('✅ Berhasil login sebagai admin.');
  } catch (e) {
    print('❌ Gagal login admin: $e');
    print('   Pastikan admin sudah terdaftar di PocketBase Admin UI.');
    return;
  }

  // 2. Buat koleksi yang belum ada
  int created = 0;
  int skipped = 0;

  for (final collName in order) {
    final fields = collections[collName]!;
    final existing = pb.collections.getList(
      filter: 'name = "$collName"',
      perPage: 1,
    );

    final list = await existing;
    if (list.items.isNotEmpty) {
      print('⏭️  Lewati (sudah ada): $collName');
      skipped++;
      continue;
    }

    try {
      final pbFields = <Map<String, dynamic>>[];
      for (final f in fields) {
        final type = f['type'] as String;
        final fieldDef = <String, dynamic>{
          'name': f['name'],
          'type': type,
        };
        if (type == 'relation') {
          fieldDef['collectionId'] = f['collection'];
          fieldDef['cascadeDelete'] = false;
          fieldDef['minSelect'] = null;
          fieldDef['maxSelect'] = 1;
          fieldDef['hidden'] = false;
        }
        pbFields.add(fieldDef);
      }

      await pb.collections.create(
        body: {
          'name': collName,
          'type': 'base',
          'schema': pbFields,
          'listRule': '',
          'viewRule': '',
          'createRule': '',
          'updateRule': '',
          'deleteRule': '',
        },
      );
      print('✅ Dibuat: $collName (${fields.length} field)');
      created++;
    } catch (e) {
      print('❌ Gagal membuat $collName: $e');
    }
  }

  print('\n📊 Selesai: $created koleksi dibuat, $skipped dilewati, ${collections.length} total target.');
}
