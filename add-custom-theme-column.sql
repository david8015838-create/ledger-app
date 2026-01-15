-- ============================================
-- 添加 custom_theme 字段到 user_settings 表
-- ============================================

-- 添加 custom_theme 字段（JSONB类型，用于存储自定义主题色配置）
ALTER TABLE public.user_settings 
ADD COLUMN IF NOT EXISTS custom_theme JSONB;

-- 添加注释说明
COMMENT ON COLUMN public.user_settings.custom_theme IS '自定义主题色配置：{ color, rgb, opacity, bg }';
