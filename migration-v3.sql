-- ═══════════════════════════════════════════
-- PoS 4 All — Migration v3
-- Run this in your Supabase SQL Editor
-- ═══════════════════════════════════════════

-- 1. ADD ref_id column to invoices (GCash / Bank Transfer reference number)
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS ref_id VARCHAR(100);

-- 2. ADD status_reason column to invoices (reason for Refund / Void)
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS status_reason TEXT;

-- 3. UPDATE payment_method constraint to include bank_transfer
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_payment_method_check;
ALTER TABLE invoices ADD CONSTRAINT invoices_payment_method_check
  CHECK (payment_method IN ('cash','gcash','bank_transfer'));

-- 4. CREATE expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category VARCHAR(100) NOT NULL,
  description TEXT,
  amount DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  expense_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category);

-- 5. ROW LEVEL SECURITY for expenses
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can read expenses"
  ON expenses FOR SELECT TO public USING (true);

CREATE POLICY "Public can insert expenses"
  ON expenses FOR INSERT TO public WITH CHECK (true);

CREATE POLICY "Public can delete expenses"
  ON expenses FOR DELETE TO public USING (true);
