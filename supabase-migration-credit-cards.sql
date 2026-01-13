-- ============================================
-- Ledger App - Credit Card Feature Migration
-- 为现有数据库添加信用卡功能支持
-- ============================================

-- 1. 为 transactions 表添加信用卡相关字段
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash',
ADD COLUMN IF NOT EXISTS card_id TEXT,
ADD COLUMN IF NOT EXISTS installments INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS interest_rate NUMERIC(5, 2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS billing_month TEXT;

-- 2. 创建信用卡表 (credit_cards)
CREATE TABLE IF NOT EXISTS public.credit_cards (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    closing_day INTEGER NOT NULL CHECK (closing_day >= 1 AND closing_day <= 31),
    due_days_after INTEGER NOT NULL CHECK (due_days_after >= 1 AND due_days_after <= 60),
    carrying_balance NUMERIC(10, 2) DEFAULT 0,
    initial_balance NUMERIC(10, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- 3. 创建信用卡表索引
CREATE INDEX IF NOT EXISTS idx_credit_cards_user_id ON public.credit_cards(user_id);

-- 4. 为信用卡表添加 updated_at 触发器
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_credit_cards_updated_at ON public.credit_cards;
CREATE TRIGGER update_credit_cards_updated_at
    BEFORE UPDATE ON public.credit_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. 启用信用卡表的 RLS
ALTER TABLE public.credit_cards ENABLE ROW LEVEL SECURITY;

-- 6. 创建信用卡表的 RLS 策略
CREATE POLICY "Users can view own credit cards"
    ON public.credit_cards FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own credit cards"
    ON public.credit_cards FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own credit cards"
    ON public.credit_cards FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own credit cards"
    ON public.credit_cards FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 完成提示
-- ============================================
-- 执行此 SQL 文件后：
-- 1. 现有的 transactions 数据会保留
-- 2. 新添加的字段将使用默认值
-- 3. 信用卡表已创建并启用 RLS
-- 4. 应用程序现在可以同步信用卡数据到云端
