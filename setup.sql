-- ============================================================
-- SCC Order System - Database Setup
-- Run this in Supabase Dashboard > SQL Editor
-- ============================================================

-- Step 1: Create shipments table
CREATE TABLE IF NOT EXISTS shipments (
  id BIGSERIAL PRIMARY KEY,
  order_id BIGINT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  shipping_notice_no TEXT,
  eta DATE,
  actual_qty INTEGER,
  actual_amount_usd NUMERIC(12,2),
  customs_fee INTEGER DEFAULT 0,
  trade_promotion_fee INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Step 2: Grant anon role access
GRANT SELECT, INSERT, UPDATE, DELETE ON shipments TO anon;
GRANT USAGE, SELECT ON SEQUENCE shipments_id_seq TO anon;

-- Step 3: Migrate existing orders data to shipments
-- (Only inserts rows where eta IS NOT NULL and no shipment exists yet)
INSERT INTO shipments (order_id, shipping_notice_no, eta, actual_qty, actual_amount_usd, customs_fee, trade_promotion_fee, created_at)
SELECT
  id AS order_id,
  shipping_notice_no,
  eta,
  actual_qty::INTEGER,
  actual_amount_usd,
  COALESCE(customs_fee, 0)::INTEGER,
  COALESCE(trade_promotion_fee, 0)::INTEGER,
  COALESCE(updated_at, created_at)
FROM orders
WHERE eta IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM shipments WHERE order_id = orders.id);
