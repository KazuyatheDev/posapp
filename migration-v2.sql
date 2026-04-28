-- ═══════════════════════════════════════════
-- PoS 4 All — Migration v2
-- Run this in your Supabase SQL Editor
-- ═══════════════════════════════════════════

-- 1. FIX payment_status constraint
--    Allow refunded & void in addition to completed/pending/cancelled
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_payment_status_check;
ALTER TABLE invoices ADD CONSTRAINT invoices_payment_status_check
  CHECK (payment_status IN ('completed','pending','cancelled','refunded','void'));

-- 2. ADD inventory quantity column to menu_items
--    NULL = N/A (untracked), 0 = sold out, >0 = in stock
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS inv_qty INTEGER;

-- 3. ADD product types/sizes column to menu_items
--    NULL = N/A (single price), JSON array = variants with name + price
--    Example: [{"name":"Small","price":50.00},{"name":"Large","price":80.00}]
ALTER TABLE menu_items ADD COLUMN IF NOT EXISTS product_types JSONB;

-- 4. CREATE Supabase Storage bucket for product images
--    Do this in the Supabase Dashboard:
--      Storage > New Bucket > Name: "product-images" > Public: ON
--    Then add this policy in the SQL editor:

-- Allow anyone (anon) to upload images to the product-images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

CREATE POLICY "Public can upload product images"
  ON storage.objects FOR INSERT TO public
  WITH CHECK (bucket_id = 'product-images');

CREATE POLICY "Public can read product images"
  ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'product-images');
