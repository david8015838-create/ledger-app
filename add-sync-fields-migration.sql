-- ============================================
-- 同步功能增强迁移
-- 添加 custom_theme 字段和 recurring_transactions 表
-- ============================================

-- 1. 添加 custom_theme 字段到 user_settings 表
ALTER TABLE public.user_settings 
ADD COLUMN IF NOT EXISTS custom_theme JSONB;

-- 2. 创建每月固定消费表 (recurring_transactions)
CREATE TABLE IF NOT EXISTS public.recurring_transactions (
    id TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    note TEXT,
    amount NUMERIC(10, 2) NOT NULL,
    category TEXT NOT NULL,
    frequency TEXT NOT NULL CHECK (frequency IN ('daily', 'weekly', 'monthly', 'yearly')),
    start_date DATE NOT NULL,
    end_date DATE,
    payment_method TEXT DEFAULT 'cash',
    card_id TEXT,
    last_created DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- 3. 创建索引
CREATE INDEX IF NOT EXISTS idx_recurring_transactions_user_id ON public.recurring_transactions(user_id);

-- 4. 创建触发器：自动更新 updated_at
DROP TRIGGER IF EXISTS update_recurring_transactions_updated_at ON public.recurring_transactions;
CREATE TRIGGER update_recurring_transactions_updated_at
    BEFORE UPDATE ON public.recurring_transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. 启用 RLS
ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;

-- 6. 创建 RLS 策略：Recurring Transactions 表
DROP POLICY IF EXISTS "Users can view own recurring transactions" ON public.recurring_transactions;
DROP POLICY IF EXISTS "Users can insert own recurring transactions" ON public.recurring_transactions;
DROP POLICY IF EXISTS "Users can update own recurring transactions" ON public.recurring_transactions;
DROP POLICY IF EXISTS "Users can delete own recurring transactions" ON public.recurring_transactions;

CREATE POLICY "Users can view own recurring transactions"
    ON public.recurring_transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own recurring transactions"
    ON public.recurring_transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own recurring transactions"
    ON public.recurring_transactions FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own recurring transactions"
    ON public.recurring_transactions FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 完成提示
-- ============================================
-- 执行此 SQL 文件后，请在 Supabase Dashboard 中：
-- 1. 验证 user_settings 表已添加 custom_theme 字段
-- 2. 验证 recurring_transactions 表已创建
-- 3. 检查 RLS 策略已启用
-- 4. 测试同步功能
