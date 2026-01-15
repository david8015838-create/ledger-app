-- ============================================
-- 添加 billing_month 欄位到 transactions 表
-- ============================================
-- 如果您的數據庫缺少 billing_month 欄位，請執行此 SQL

-- 檢查並添加 billing_month 欄位
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS billing_month TEXT;

-- 驗證欄位已添加
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'transactions' 
  AND column_name = 'billing_month';

-- 如果查詢返回一行，表示欄位已成功添加
