-- ============================================================
-- Seed profil pengguna untuk Supabase Auth (Opsi 2)
-- ============================================================
-- CARA PAKAI:
-- 1. Buat user di Supabase Authentication > Users (Add user)
--    - Isi Email dan Password (Auto Confirm User = ON)
-- 2. Catat UUID user yang baru dibuat
-- 3. Jalankan SQL ini di Supabase SQL Editor, ganti <USER_ID>
--    dengan UUID user yang baru dibuat
-- 4. Profil akan tersinkronkan otomatis ke aplikasi Flutter
-- ============================================================

-- Contoh: ganti '<USER_ID>' dengan UUID asli dari Supabase Auth
-- INSERT INTO profiles (
--   id, email, full_name, role, business_id, store_id, is_active,
--   created_at, updated_at, version, sync_status
-- ) VALUES (
--   '<USER_ID>',
--   'owner@tokosaya.com',
--   'Owner Utama',
--   'owner',
--   null,
--   null,
--   true,
--   now(),
--   now(),
--   1,
--   'synced'
-- );

-- ============================================================
-- Petunjuk cepat untuk masing-masing role:
-- ============================================================
-- Role owner   -> akses penuh (semua fitur)
-- Role admin   -> akses hampir penuh kecuali owner-only
-- Role manager -> laporan dan operasi
-- Role kasir   -> POS dan penjualan
-- Role staff_gudang -> inventaris dan stok
-- ============================================================

-- Buat bisnis default dulu jika belum ada:
INSERT INTO businesses (id, name, currency, timezone, created_at, updated_at, version, sync_status)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'Toko Utama',
  'IDR',
  'Asia/Jakarta',
  now(),
  now(),
  1,
  'synced'
)
ON CONFLICT (id) DO NOTHING;

-- Buat toko default jika belum ada:
INSERT INTO stores (id, business_id, name, address, phone, created_at, updated_at, version, sync_status)
VALUES (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'Toko Pusat',
  'Jl. Contoh No. 1, Kota',
  '08123456789',
  now(),
  now(),
  1,
  'synced'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Contoh profil untuk masing-masing role (ganti <USER_ID>):
-- ============================================================

-- Owner
INSERT INTO profiles (
  id, email, full_name, role, business_id, store_id, is_active,
  created_at, updated_at, version, sync_status
) VALUES (
  '<USER_ID_OWNER>',
  'owner@tokosaya.com',
  'Owner Utama',
  'owner',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  true,
  now(),
  now(),
  1,
  'synced'
)
ON CONFLICT (id) DO NOTHING;

-- Admin
INSERT INTO profiles (
  id, email, full_name, role, business_id, store_id, is_active,
  created_at, updated_at, version, sync_status
) VALUES (
  '<USER_ID_ADMIN>',
  'admin@tokosaya.com',
  'Admin Toko',
  'admin',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  true,
  now(),
  now(),
  1,
  'synced'
)
ON CONFLICT (id) DO NOTHING;

-- Manager
INSERT INTO profiles (
  id, email, full_name, role, business_id, store_id, is_active,
  created_at, updated_at, version, sync_status
) VALUES (
  '<USER_ID_MANAGER>',
  'manager@tokosaya.com',
  'Manajer Operasi',
  'manager',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  true,
  now(),
  now(),
  1,
  'synced'
)
ON CONFLICT (id) DO NOTHING;

-- Kasir
INSERT INTO profiles (
  id, email, full_name, role, business_id, store_id, is_active,
  created_at, updated_at, version, sync_status
) VALUES (
  '<USER_ID_KASIR>',
  'kasir@tokosaya.com',
  'Kasir Utama',
  'kasir',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  true,
  now(),
  now(),
  1,
  'synced'
)
ON CONFLICT (id) DO NOTHING;

-- Staff Gudang
INSERT INTO profiles (
  id, email, full_name, role, business_id, store_id, is_active,
  created_at, updated_at, version, sync_status
) VALUES (
  '<USER_ID_STAFF>',
  'gudang@tokosaya.com',
  'Staff Gudang',
  'staff_gudang',
  '00000000-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000002',
  true,
  now(),
  now(),
  1,
  'synced'
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- Catatan penting:
-- - UUID <USER_ID_*> harus cocok dengan user di Supabase Auth
-- - Password diatur di Supabase Authentication > Users, tidak di sini
-- - Role di profil digunakan oleh aplikasi Flutter untuk guard navigasi
-- ============================================================
