-- ============================================
-- Ledger App - Supabase Database Schema
-- 本地优先 + 云端备份架构
-- ============================================

-- 1. 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. 创建用户表（可选，如果使用 Supabase Auth 则不需要）
-- Supabase Auth 会自动管理 auth.users 表

-- 3. 创建交易记录表 (transactions)
CREATE TABLE IF NOT EXISTS public.transactions (
    id BIGINT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    amount NUMERIC(10, 2) NOT NULL,
    date DATE NOT NULL,
    note TEXT,
    category TEXT NOT NULL,
    icon TEXT NOT NULL,
    currency TEXT DEFAULT 'TWD',
    payment_method TEXT DEFAULT 'cash',
    card_id TEXT,
    installments INTEGER DEFAULT 1,
    interest_rate NUMERIC(5, 2) DEFAULT 0,
    billing_month TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- 3.5 创建信用卡表 (credit_cards)
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

-- 4. 创建分类表 (categories)
CREATE TABLE IF NOT EXISTS public.categories (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    icon TEXT NOT NULL,
    color TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    is_deleted BOOLEAN DEFAULT FALSE
);

-- 5. 创建用户设置表 (user_settings)
CREATE TABLE IF NOT EXISTS public.user_settings (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    budget NUMERIC(10, 2) DEFAULT 30000,
    theme_id TEXT DEFAULT 'minimal',
    currency TEXT DEFAULT 'TWD',
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.5 创建登入代码表 (login_codes)
CREATE TABLE IF NOT EXISTS public.login_codes (
    code TEXT PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    email TEXT NOT NULL,
    access_token TEXT NOT NULL,
    refresh_token TEXT NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    used_at TIMESTAMPTZ
);

-- 6. 创建索引以提升查询性能
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON public.transactions(date DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_updated_at ON public.transactions(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_categories_user_id ON public.categories(user_id);
CREATE INDEX IF NOT EXISTS idx_credit_cards_user_id ON public.credit_cards(user_id);

-- 7. 创建触发器函数：自动更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 8. 为所有表添加 updated_at 触发器
DROP TRIGGER IF EXISTS update_transactions_updated_at ON public.transactions;
CREATE TRIGGER update_transactions_updated_at
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_categories_updated_at ON public.categories;
CREATE TRIGGER update_categories_updated_at
    BEFORE UPDATE ON public.categories
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_settings_updated_at ON public.user_settings;
CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_credit_cards_updated_at ON public.credit_cards;
CREATE TRIGGER update_credit_cards_updated_at
    BEFORE UPDATE ON public.credit_cards
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 数据过期策略：自动删除 365 天前的数据
-- ============================================

-- 9. 创建自动清理过期数据的函数
CREATE OR REPLACE FUNCTION cleanup_old_transactions(target_user_id UUID)
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    -- 删除该用户 365 天前的交易记录
    DELETE FROM public.transactions
    WHERE user_id = target_user_id
      AND date < (CURRENT_DATE - INTERVAL '365 days');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. 创建同步后自动清理的函数（供应用调用）
CREATE OR REPLACE FUNCTION sync_and_cleanup(target_user_id UUID)
RETURNS JSON AS $$
DECLARE
    deleted_count INTEGER;
    result JSON;
BEGIN
    -- 执行清理
    deleted_count := cleanup_old_transactions(target_user_id);
    
    -- 更新最后同步时间
    UPDATE public.user_settings
    SET last_sync_at = NOW()
    WHERE user_id = target_user_id;
    
    -- 如果用户设置不存在，则创建
    IF NOT FOUND THEN
        INSERT INTO public.user_settings (user_id, last_sync_at)
        VALUES (target_user_id, NOW());
    END IF;
    
    -- 返回结果
    result := json_build_object(
        'success', true,
        'deleted_count', deleted_count,
        'sync_time', NOW()
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- Row Level Security (RLS) 设置
-- ============================================

-- 11. 启用 RLS
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.credit_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.login_codes ENABLE ROW LEVEL SECURITY;

-- 12. 删除旧的策略（如果存在）
DROP POLICY IF EXISTS "Users can view own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can insert own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can update own transactions" ON public.transactions;
DROP POLICY IF EXISTS "Users can delete own transactions" ON public.transactions;

DROP POLICY IF EXISTS "Users can view own categories" ON public.categories;
DROP POLICY IF EXISTS "Users can insert own categories" ON public.categories;
DROP POLICY IF EXISTS "Users can update own categories" ON public.categories;
DROP POLICY IF EXISTS "Users can delete own categories" ON public.categories;

DROP POLICY IF EXISTS "Users can view own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can insert own settings" ON public.user_settings;
DROP POLICY IF EXISTS "Users can update own settings" ON public.user_settings;

-- 13. 创建 RLS 策略：Transactions 表
CREATE POLICY "Users can view own transactions"
    ON public.transactions FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
    ON public.transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own transactions"
    ON public.transactions FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own transactions"
    ON public.transactions FOR DELETE
    USING (auth.uid() = user_id);

-- 14. 创建 RLS 策略：Categories 表
CREATE POLICY "Users can view own categories"
    ON public.categories FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own categories"
    ON public.categories FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories"
    ON public.categories FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories"
    ON public.categories FOR DELETE
    USING (auth.uid() = user_id);

-- 15. 创建 RLS 策略：User Settings 表
CREATE POLICY "Users can view own settings"
    ON public.user_settings FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own settings"
    ON public.user_settings FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own settings"
    ON public.user_settings FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 15.3 创建 RLS 策略：Credit Cards 表
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

-- 15.5 创建 RLS 策略：Login Codes 表
-- 注意：login_codes 表需要特殊的策略，因为验证时用户可能未登录
DROP POLICY IF EXISTS "Users can insert own login codes" ON public.login_codes;
DROP POLICY IF EXISTS "Anyone can read valid login codes" ON public.login_codes;

-- 已登录用户可以创建自己的登入代码
CREATE POLICY "Users can insert own login codes"
    ON public.login_codes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 任何人都可以读取未过期且未使用的登入代码（用于验证）
CREATE POLICY "Anyone can read valid login codes"
    ON public.login_codes FOR SELECT
    USING (expires_at > NOW() AND used_at IS NULL);

-- ============================================
-- 数据库函数：批量 Upsert（用于同步）
-- ============================================

-- 16. 批量 Upsert 交易记录
CREATE OR REPLACE FUNCTION upsert_transactions(
    target_user_id UUID,
    transactions_data JSONB
)
RETURNS JSON AS $$
DECLARE
    result JSON;
    upserted_count INTEGER := 0;
    tx JSONB;
BEGIN
    -- 遍历每一笔交易
    FOR tx IN SELECT * FROM jsonb_array_elements(transactions_data)
    LOOP
        INSERT INTO public.transactions (
            id, user_id, amount, date, note, category, icon, currency, updated_at
        ) VALUES (
            (tx->>'id')::BIGINT,
            target_user_id,
            (tx->>'amount')::NUMERIC,
            (tx->>'date')::DATE,
            tx->>'note',
            tx->>'category',
            tx->>'icon',
            COALESCE(tx->>'currency', 'TWD'),
            COALESCE((tx->>'updated_at')::TIMESTAMPTZ, NOW())
        )
        ON CONFLICT (id) DO UPDATE SET
            amount = EXCLUDED.amount,
            date = EXCLUDED.date,
            note = EXCLUDED.note,
            category = EXCLUDED.category,
            icon = EXCLUDED.icon,
            currency = EXCLUDED.currency,
            updated_at = EXCLUDED.updated_at
        WHERE public.transactions.updated_at < EXCLUDED.updated_at;
        
        upserted_count := upserted_count + 1;
    END LOOP;
    
    result := json_build_object(
        'success', true,
        'upserted_count', upserted_count
    );
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- 新用户自动初始化
-- ============================================

-- 17. 创建新用户自动初始化函数
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- 为新用户创建默认设置
    INSERT INTO public.user_settings (user_id, budget, theme_id, currency)
    VALUES (NEW.id, 30000, 'minimal', 'TWD')
    ON CONFLICT (user_id) DO NOTHING;
    
    -- 为新用户创建默认分类
    INSERT INTO public.categories (user_id, name, icon, color) VALUES
        (NEW.id, '美食餐飲', '🍚', '#6366f1'),
        (NEW.id, '交通運輸', '🚗', '#10b981'),
        (NEW.id, '購物消費', '🛒', '#f59e0b'),
        (NEW.id, '帳單雜項', '🧾', '#8b5cf6'),
        (NEW.id, '休閒娛樂', '🎮', '#ec4899')
    ON CONFLICT DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 18. 创建触发器：当新用户注册时自动执行
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================
-- 完成提示
-- ============================================
-- 执行此 SQL 文件后，请在 Supabase Dashboard 中：
-- 1. 验证表已创建
-- 2. 检查 RLS 策略已启用
-- 3. 在 Authentication > Providers 中启用 Email (Magic Link)
-- 4. 在项目设置中获取 API URL 和 anon key
-- 5. 配置到前端应用中
