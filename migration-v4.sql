-- ═══════════════════════════════════════════
-- PoS 4 All — Migration v4
-- Run this in your Supabase SQL Editor
-- ═══════════════════════════════════════════

-- ADD amount_received and cash_change to invoices
-- Only populated when payment_method = 'cash'
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS amount_received DECIMAL(10,2);
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS cash_change DECIMAL(10,2);
