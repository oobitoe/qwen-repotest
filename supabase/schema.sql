-- Schema Supabase untuk POS Manajemen (offline-first).
-- Semua tabel menggunakan UUID sebagai primary key, timestamp UTC,
-- dan numeric/decimal untuk nilai uang.
-- RLS diaktifkan pada seluruh tabel bisnis.
--
-- Jalankan migrasi ini di SQL Editor Supabase project Anda.

-- ============================================================
-- 1. Ekstensi & tipe enum
-- ============================================================
create extension if not exists "uuid-ossp";

create type business_role as enum ('owner', 'admin', 'manager', 'kasir', 'staff_gudang');

create type payment_method as enum ('cash', 'transfer', 'qris', 'card', 'other');

create type stock_movement_type as enum (
  'initial', 'purchase', 'sale', 'sale_return', 'purchase_return',
  'adjustment', 'transfer_in', 'transfer_out', 'correction'
);

create type sync_status as enum ('pending', 'synced', 'conflict', 'error');

create type sync_operation as enum ('upsert', 'delete');

create type sync_queue_status as enum ('waiting', 'in_progress', 'done', 'failed');

-- ============================================================
-- 2. Organisasi & pengguna
-- ============================================================
create table if not exists businesses (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  currency text not null default 'IDR',
  timezone text not null default 'Asia/Jakarta',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists stores (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  address text,
  phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  role business_role not null default 'kasir',
  business_id uuid references businesses(id),
  store_id uuid references stores(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists business_members (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role business_role not null default 'kasir',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(business_id, user_id)
);

create table if not exists roles (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  description text,
  is_system boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists permissions (
  id uuid primary key default uuid_generate_v4(),
  code text not null unique,
  description text,
  created_at timestamptz not null default now()
);

create table if not exists role_permissions (
  id uuid primary key default uuid_generate_v4(),
  role_id uuid not null references roles(id) on delete cascade,
  permission_id uuid not null references permissions(id) on delete cascade,
  unique(role_id, permission_id)
);

create table if not exists user_store_access (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references auth.users(id) on delete cascade,
  store_id uuid not null references stores(id) on delete cascade,
  unique(user_id, store_id)
);

-- Seed permission codes dasar
insert into permissions (code, description) values
  ('dashboard.view', 'Lihat dashboard'),
  ('products.view', 'Lihat produk'),
  ('products.manage', 'Kelola produk'),
  ('stock.manage', 'Kelola stok'),
  ('pos.use', 'Gunakan POS'),
  ('sales.view', 'Lihat penjualan'),
  ('expenses.manage', 'Kelola pengeluaran'),
  ('income.manage', 'Kelola pemasukan'),
  ('reports.view', 'Lihat laporan'),
  ('users.manage', 'Kelola pengguna'),
  ('settings.manage', 'Kelola pengaturan'),
  ('purchases.view', 'Lihat pembelian'),
  ('customers.manage', 'Kelola pelanggan'),
  ('suppliers.manage', 'Kelola supplier')
on conflict (code) do nothing;

-- ============================================================
-- 3. Produk
-- ============================================================
create table if not exists categories (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists units (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  abbreviation text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists products (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  sku text not null,
  barcode text,
  name text not null,
  description text,
  category_id uuid references categories(id) on delete set null,
  unit_id uuid references units(id) on delete set null,
  cost_price numeric(18,4) not null default 0,
  sell_price numeric(18,4) not null,
  wholesale_price numeric(18,4),
  min_stock numeric(18,4) not null default 0,
  stock numeric(18,4) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending',
  unique(business_id, sku)
);

create table if not exists product_variants (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id) on delete cascade,
  name text not null,
  sku text,
  price_modifier numeric(18,4) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists product_barcodes (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id) on delete cascade,
  barcode text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists product_prices (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id) on delete cascade,
  price numeric(18,4) not null,
  start_date date,
  end_date date,
  created_at timestamptz not null default now()
);

create table if not exists product_images (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id) on delete cascade,
  url text not null,
  storage_path text,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 4. Inventaris
-- ============================================================
create table if not exists stock_movements (
  id uuid primary key default uuid_generate_v4(),
  product_id uuid not null references products(id) on delete cascade,
  type stock_movement_type not null,
  quantity numeric(18,4) not null,
  balance_after numeric(18,4) not null,
  reference_type text,
  reference_id uuid,
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists stock_adjustments (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  reference_number text not null,
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists stock_adjustment_items (
  id uuid primary key default uuid_generate_v4(),
  adjustment_id uuid not null references stock_adjustments(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  quantity_before numeric(18,4) not null,
  quantity_after numeric(18,4) not null,
  reason text
);

create table if not exists stock_opnames (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  reference_number text not null,
  status text not null default 'draft', -- draft | counted | approved
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  deleted_at timestamptz
);

create table if not exists stock_opname_items (
  id uuid primary key default uuid_generate_v4(),
  opname_id uuid not null references stock_opnames(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  system_stock numeric(18,4) not null,
  counted_stock numeric(18,4) not null,
  difference numeric(18,4) generated always as (counted_stock - system_stock) stored
);

create table if not exists stock_transfers (
  id uuid primary key default uuid_generate_v4(),
  from_store_id uuid references stores(id) on delete set null,
  to_store_id uuid references stores(id) on delete set null,
  reference_number text not null,
  status text not null default 'pending', -- pending | shipped | received | cancelled
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists stock_transfer_items (
  id uuid primary key default uuid_generate_v4(),
  transfer_id uuid not null references stock_transfers(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  quantity numeric(18,4) not null
);

-- ============================================================
-- 5. Supplier & Pelanggan
-- ============================================================
create table if not exists suppliers (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  phone text,
  email text,
  address text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists customers (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  code text,
  name text not null,
  phone text,
  email text,
  address text,
  notes text,
  tier text not null default 'Regular',
  reward_points int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists customer_addresses (
  id uuid primary key default uuid_generate_v4(),
  customer_id uuid not null references customers(id) on delete cascade,
  label text not null,
  address text not null,
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 6. Pembelian
-- ============================================================
create table if not exists purchase_orders (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  supplier_id uuid not null references suppliers(id) on delete cascade,
  reference_number text not null,
  status text not null default 'draft', -- draft | ordered | received | cancelled
  subtotal numeric(18,4) not null default 0,
  discount numeric(18,4) not null default 0,
  tax numeric(18,4) not null default 0,
  total numeric(18,4) not null default 0,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists purchase_order_items (
  id uuid primary key default uuid_generate_v4(),
  order_id uuid not null references purchase_orders(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  product_name_snapshot text not null,
  sku text,
  unit_price numeric(18,4) not null,
  quantity numeric(18,4) not null,
  received_quantity numeric(18,4) not null default 0,
  line_total numeric(18,4) not null
);

create table if not exists purchases (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  supplier_id uuid not null references suppliers(id) on delete cascade,
  reference_number text not null,
  subtotal numeric(18,4) not null default 0,
  discount numeric(18,4) not null default 0,
  tax numeric(18,4) not null default 0,
  total numeric(18,4) not null default 0,
  payment_method payment_method not null default 'cash',
  is_credit boolean not null default false,
  status text not null default 'completed',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists purchase_items (
  id uuid primary key default uuid_generate_v4(),
  purchase_id uuid not null references purchases(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  product_name_snapshot text not null,
  sku text,
  unit_price numeric(18,4) not null,
  cost_price numeric(18,4) not null,
  quantity numeric(18,4) not null,
  line_total numeric(18,4) not null
);

create table if not exists purchase_payments (
  id uuid primary key default uuid_generate_v4(),
  purchase_id uuid not null references purchases(id) on delete cascade,
  amount numeric(18,4) not null,
  payment_method payment_method not null default 'cash',
  paid_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table if not exists purchase_returns (
  id uuid primary key default uuid_generate_v4(),
  purchase_id uuid not null references purchases(id) on delete cascade,
  reference_number text not null,
  total numeric(18,4) not null default 0,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists purchase_return_items (
  id uuid primary key default uuid_generate_v4(),
  return_id uuid not null references purchase_returns(id) on delete cascade,
  product_id uuid not null references products(id) on delete cascade,
  quantity numeric(18,4) not null,
  unit_price numeric(18,4) not null
);

-- ============================================================
-- 7. Penjualan & POS
-- ============================================================
create table if not exists sale_sequences (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  store_id uuid references stores(id),
  prefix text not null default 'INV',
  last_number int not null default 0,
  date date not null default current_date,
  unique(business_id, store_id, date)
);

create table if not exists sales (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  store_id uuid references stores(id),
  invoice_number text not null,
  customer_id uuid references customers(id) on delete set null,
  customer_name_snapshot text,
  subtotal numeric(18,4) not null default 0,
  discount numeric(18,4) not null default 0,
  tax numeric(18,4) not null default 0,
  total numeric(18,4) not null default 0,
  paid numeric(18,4) not null default 0,
  change_due numeric(18,4) not null default 0,
  payment_method payment_method not null default 'cash',
  is_credit boolean not null default false,
  status text not null default 'completed', -- completed | voided
  cashier_id uuid references auth.users(id),
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  version int not null default 1,
  sync_status sync_status not null default 'pending',
  unique(business_id, invoice_number)
);

create table if not exists sale_items (
  id uuid primary key default uuid_generate_v4(),
  sale_id uuid not null references sales(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  product_name_snapshot text not null,
  sku text,
  unit_price numeric(18,4) not null,
  cost_price numeric(18,4) not null default 0,
  quantity numeric(18,4) not null,
  discount numeric(18,4) not null default 0,
  line_total numeric(18,4) not null,
  created_at timestamptz not null default now(),
  version int not null default 1,
  sync_status sync_status not null default 'pending'
);

create table if not exists sale_payments (
  id uuid primary key default uuid_generate_v4(),
  sale_id uuid not null references sales(id) on delete cascade,
  amount numeric(18,4) not null,
  payment_method payment_method not null default 'cash',
  paid_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table if not exists sale_returns (
  id uuid primary key default uuid_generate_v4(),
  sale_id uuid not null references sales(id) on delete cascade,
  reference_number text not null,
  total numeric(18,4) not null default 0,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists sale_return_items (
  id uuid primary key default uuid_generate_v4(),
  return_id uuid not null references sale_returns(id) on delete cascade,
  product_id uuid references products(id) on delete set null,
  quantity numeric(18,4) not null,
  unit_price numeric(18,4) not null
);

-- ============================================================
-- 8. Kas & keuangan
-- ============================================================
create table if not exists cash_registers (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  store_id uuid references stores(id),
  name text not null,
  opening_balance numeric(18,4) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists cash_sessions (
  id uuid primary key default uuid_generate_v4(),
  register_id uuid not null references cash_registers(id) on delete cascade,
  opened_by uuid references auth.users(id),
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  opening_balance numeric(18,4) not null default 0,
  expected_balance numeric(18,4),
  actual_balance numeric(18,4),
  difference numeric(18,4),
  status text not null default 'open', -- open | closed
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists cash_movements (
  id uuid primary key default uuid_generate_v4(),
  session_id uuid references cash_sessions(id) on delete set null,
  type text not null, -- sale | expense | income | transfer | adjustment
  amount numeric(18,4) not null,
  reference_type text,
  reference_id uuid,
  note text,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists expense_categories (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists expenses (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  category_id uuid references expense_categories(id) on delete set null,
  description text not null,
  amount numeric(18,4) not null,
  payment_method payment_method not null default 'cash',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists income_categories (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists income_entries (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  category_id uuid references income_categories(id) on delete set null,
  description text not null,
  amount numeric(18,4) not null,
  payment_method payment_method not null default 'cash',
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists accounts (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  type text not null, -- cash | bank | e_wallet
  balance numeric(18,4) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists account_transactions (
  id uuid primary key default uuid_generate_v4(),
  account_id uuid not null references accounts(id) on delete cascade,
  type text not null, -- debit | credit
  amount numeric(18,4) not null,
  reference_type text,
  reference_id uuid,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

create table if not exists debts (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  supplier_id uuid references suppliers(id) on delete set null,
  customer_id uuid references customers(id) on delete set null,
  type text not null, -- payable | receivable
  amount numeric(18,4) not null default 0,
  paid_amount numeric(18,4) not null default 0,
  status text not null default 'open', -- open | partially_paid | paid
  due_date date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists debt_payments (
  id uuid primary key default uuid_generate_v4(),
  debt_id uuid not null references debts(id) on delete cascade,
  amount numeric(18,4) not null,
  paid_at timestamptz not null default now(),
  created_by uuid references auth.users(id)
);

create table if not exists financial_adjustments (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  description text not null,
  amount numeric(18,4) not null,
  type text not null, -- credit | debit
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now()
);

-- ============================================================
-- 9. Konfigurasi & sinkronisasi
-- ============================================================
create table if not exists business_settings (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  key text not null,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique(business_id, key)
);

create table if not exists store_settings (
  id uuid primary key default uuid_generate_v4(),
  store_id uuid not null references stores(id) on delete cascade,
  key text not null,
  value jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique(store_id, key)
);

create table if not exists payment_methods_config (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  code payment_method not null,
  name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists tax_settings (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid not null references businesses(id) on delete cascade,
  name text not null,
  rate numeric(9,4) not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists devices (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid references businesses(id),
  device_id text not null unique,
  name text,
  last_seen_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists audit_logs (
  id uuid primary key default uuid_generate_v4(),
  business_id uuid references businesses(id),
  user_id uuid references auth.users(id),
  action text not null,
  entity_type text,
  entity_id uuid,
  old_values jsonb,
  new_values jsonb,
  created_at timestamptz not null default now()
);

create table if not exists sync_metadata (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

-- Antrean sinkronisasi outbox (lokal-first mirror, juga tersimpan server)
create table if not exists sync_queue (
  id uuid primary key default uuid_generate_v4(),
  entity_type text not null,
  entity_id uuid not null,
  operation sync_operation not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  retry_count int not null default 0,
  last_error text,
  status sync_queue_status not null default 'waiting',
  next_retry_at timestamptz not null default now()
);

-- Index untuk performa sinkronisasi & query bisnis
create index if not exists idx_businesses_deleted_at on businesses(deleted_at);
create index if not exists idx_stores_business_id on stores(business_id);
create index if not exists idx_profiles_business_id on profiles(business_id);
create index if not exists idx_categories_business_id on categories(business_id);
create index if not exists idx_products_business_id on products(business_id);
create index if not exists idx_products_sku on products(sku);
create index if not exists idx_products_barcode on products(barcode);
create index if not exists idx_stock_movements_product_id on stock_movements(product_id);
create index if not exists idx_stock_movements_created_at on stock_movements(created_at);
create index if not exists idx_suppliers_business_id on suppliers(business_id);
create index if not exists idx_customers_business_id on customers(business_id);
create index if not exists idx_sales_business_id on sales(business_id);
create index if not exists idx_sales_invoice_number on sales(invoice_number);
create index if not exists idx_sales_created_at on sales(created_at);
create index if not exists idx_sale_items_sale_id on sale_items(sale_id);
create index if not exists idx_purchases_business_id on purchases(business_id);
create index if not exists idx_expenses_business_id on expenses(business_id);
create index if not exists idx_income_entries_business_id on income_entries(business_id);
create index if not exists idx_cash_sessions_register_id on cash_sessions(register_id);
create index if not exists idx_cash_movements_session_id on cash_movements(session_id);
create index if not exists idx_sync_queue_status on sync_queue(status, next_retry_at);
create index if not exists idx_sync_queue_entity on sync_queue(entity_type, entity_id);
create index if not exists idx_audit_logs_created_at on audit_logs(created_at);
create index if not exists idx_audit_logs_user_id on audit_logs(user_id);

-- Trigger updated_at otomatis
create or replace function update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language 'plpgsql';

do $$
declare tbl text;
begin
  for tbl in (
    select tablename from pg_tables where schemaname = 'public'
  ) loop
    execute format($f$
      create trigger if not exists update_%I_updated_at
      before update on %I
      for each row execute function update_updated_at_column();
    $f$, tbl, tbl);
  end loop;
end $$;

-- ============================================================
-- 10. Row Level Security (RLS)
-- ============================================================
alter table businesses enable row level security;
alter table stores enable row level security;
alter table profiles enable row level security;
alter table business_members enable row level security;
alter table roles enable row level security;
alter table role_permissions enable row level security;
alter table user_store_access enable row level security;
alter table categories enable row level security;
alter table units enable row level security;
alter table products enable row level security;
alter table product_variants enable row level security;
alter table product_barcodes enable row level security;
alter table product_prices enable row level security;
alter table product_images enable row level security;
alter table stock_movements enable row level security;
alter table stock_adjustments enable row level security;
alter table stock_adjustment_items enable row level security;
alter table stock_opnames enable row level security;
alter table stock_opname_items enable row level security;
alter table stock_transfers enable row level security;
alter table stock_transfer_items enable row level security;
alter table suppliers enable row level security;
alter table customers enable row level security;
alter table customer_addresses enable row level security;
alter table purchase_orders enable row level security;
alter table purchase_order_items enable row level security;
alter table purchases enable row level security;
alter table purchase_items enable row level security;
alter table purchase_payments enable row level security;
alter table purchase_returns enable row level security;
alter table purchase_return_items enable row level security;
alter table sale_sequences enable row level security;
alter table sales enable row level security;
alter table sale_items enable row level security;
alter table sale_payments enable row level security;
alter table sale_returns enable row level security;
alter table sale_return_items enable row level security;
alter table cash_registers enable row level security;
alter table cash_sessions enable row level security;
alter table cash_movements enable row level security;
alter table expense_categories enable row level security;
alter table expenses enable row level security;
alter table income_categories enable row level security;
alter table income_entries enable row level security;
alter table accounts enable row level security;
alter table account_transactions enable row level security;
alter table debts enable row level security;
alter table debt_payments enable row level security;
alter table financial_adjustments enable row level security;
alter table business_settings enable row level security;
alter table store_settings enable row level security;
alter table payment_methods_config enable row level security;
alter table tax_settings enable row level security;
alter table devices enable row level security;
alter table audit_logs enable row level security;
alter table sync_metadata enable row level security;
alter table sync_queue enable row level security;

-- Helper: ambil business_id dari profile user yang login
create or replace function current_business_id()
returns uuid as $$
declare
  rec record;
begin
  select business_id into rec from profiles where id = auth.uid() limit 1;
  return rec.business_id;
end;
$$ language 'plpgsql' stable;

-- Helper: cek apakah user milik business tertentu
create or replace function business_member(target_business_id uuid)
returns boolean as $$
declare
  bid uuid;
begin
  select current_business_id() into bid;
  return bid = target_business_id;
end;
$$ language 'plpgsql' stable;

-- Helper: cek permission user
create or replace function has_permission(perm_code text)
returns boolean as $$
declare
  cnt int;
begin
  select count(*) into cnt
  from role_permissions rp
  join permissions p on p.id = rp.permission_id
  join roles r on r.id = rp.role_id
  join profiles pr on pr.business_id = r.business_id
  where p.code = perm_code
    and pr.id = auth.uid()
    and r.deleted_at is null
    and pr.is_active = true;
  return cnt > 0;
end;
$$ language 'plpgsql' stable;

-- Polis RLS generik: user hanya akses data milik businessnya
do $$
declare tbl text;
begin
  for tbl in (
    'businesses','stores','categories','units','products','suppliers','customers',
    'purchases','sales','expenses','income_entries','cash_registers','cash_sessions',
    'cash_movements','accounts','account_transactions','debts','debt_payments',
    'business_settings','store_settings','payment_methods_config','tax_settings',
    'devices','audit_logs','sync_metadata','sync_queue'
  ) loop
    execute format($f$
      create policy if not exists "%s_business_isolation" on %s
      for all
      using (business_member(%L::uuid))
    $f$, tbl, tbl, tbl);
  end loop;
end $$;

-- Profiles: user bisa baca profile sendiri, dan business lain tidak bisa lihat
create policy if not exists "profiles_own_or_business" on profiles
for all using (
  auth.uid() = id or business_member(business_id)
);

-- user_store_access: user bisa lihat akses toko miliknya
create policy if not exists "user_store_access_own" on user_store_access
for all using (auth.uid() = user_id);

-- business_members: anggota bisa lihat businessnya
create policy if not exists "business_members_own" on business_members
for all using (business_member(business_id));

-- sync_queue: milik device / business yang login
create policy if not exists "sync_queue_business" on sync_queue
for all using (business_member(current_business_id()));

-- ============================================================
-- 11. Seed role awal (idempoten)
-- ============================================================
insert into roles (business_id, name, description, is_system) values
  (null, 'owner', 'Pemilik bisnis, akses penuh', true),
  (null, 'admin', 'Admin, akses hampir penuh kecuali owner-only', true),
  (null, 'manager', 'Manajer, laporan dan operasi', true),
  (null, 'kasir', 'Kasir, POS dan penjualan', true),
  (null, 'staff_gudang', 'Staff gudang, inventaris dan stok', true)
on conflict do nothing;

-- ============================================================
-- 12. Documentasi: catat versi skema
-- ============================================================
insert into sync_metadata (key, value) values
  ('schema_version', '1.0.0'),
  ('schema_applied_at', now()::text)
on conflict (key) do update set value = excluded.value, updated_at = now();
