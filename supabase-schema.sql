-- ═══════════════════════════════════════════
-- CarePOS — Supabase Database Schema
-- Run this in your Supabase SQL Editor
-- ═══════════════════════════════════════════

-- 1. MENU ITEMS
CREATE TABLE menu_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  category VARCHAR(100),
  image_url TEXT,
  is_available_in_cashier BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_menu_items_available ON menu_items(is_available_in_cashier)
  WHERE is_available_in_cashier = true;

-- 2. INVOICES
CREATE TABLE invoices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number VARCHAR(50) UNIQUE NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  vat_amount DECIMAL(10,2) NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('cash','gcash')),
  payment_status VARCHAR(20) DEFAULT 'completed' CHECK (payment_status IN ('completed','pending','cancelled')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  synced_at TIMESTAMPTZ
);

CREATE INDEX idx_invoices_created ON invoices(created_at DESC);
CREATE INDEX idx_invoices_payment ON invoices(payment_method);

-- 3. INVOICE ITEMS
CREATE TABLE invoice_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
  menu_item_id UUID REFERENCES menu_items(id),
  item_name VARCHAR(255) NOT NULL,
  item_price DECIMAL(10,2) NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  line_total DECIMAL(10,2) NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_inv_items_invoice ON invoice_items(invoice_id);
CREATE INDEX idx_inv_items_menu ON invoice_items(menu_item_id);

-- ═══════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;

-- menu_items: public read, authenticated write
CREATE POLICY "Public can read menu items"
  ON menu_items FOR SELECT TO public USING (true);

CREATE POLICY "Authenticated can manage menu items"
  ON menu_items FOR ALL TO authenticated USING (true);

-- invoices: authenticated only
CREATE POLICY "Authenticated can manage invoices"
  ON invoices FOR ALL TO authenticated USING (true);

-- invoice_items: authenticated only
CREATE POLICY "Authenticated can manage invoice items"
  ON invoice_items FOR ALL TO authenticated USING (true);

-- ═══════════════════════════════════════════
-- SAMPLE DATA
-- ═══════════════════════════════════════════
INSERT INTO menu_items (name, price, category, is_available_in_cashier) VALUES
  ('Chicken Adobo', 85.00, 'Main Dish', true),
  ('Pork Sinigang', 95.00, 'Soup', true),
  ('Beef Caldereta', 110.00, 'Main Dish', true),
  ('Fried Tilapia', 90.00, 'Seafood', true),
  ('Menudo', 80.00, 'Main Dish', true),
  ('Pinakbet', 75.00, 'Vegetable', true),
  ('Steamed Rice', 15.00, 'Rice', true),
  ('Fried Rice', 25.00, 'Rice', true),
  ('Buko Juice', 35.00, 'Drinks', true),
  ('Softdrinks', 25.00, 'Drinks', true);
