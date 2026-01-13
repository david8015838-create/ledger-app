# Supabase 设置指南

## 📋 前置准备

1. 注册 Supabase 账户：https://supabase.com
2. 创建新项目（选择离你最近的区域）

## 🗄️ 数据库设置

### 步骤 1：执行 Schema SQL

1. 登录 Supabase Dashboard
2. 进入你的项目
3. 点击左侧菜单 **SQL Editor**
4. 点击 **New Query**
5. 复制粘贴 `supabase-schema.sql` 的全部内容
6. 点击 **Run** 执行

### 步骤 2：验证表创建成功

在 SQL Editor 中执行以下查询验证：

```sql
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

你应该看到以下表：
- `transactions`
- `categories`
- `user_settings`

### 步骤 3：验证 RLS 策略

```sql
SELECT tablename, policyname 
FROM pg_policies 
WHERE schemaname = 'public';
```

## 🔑 获取 API 密钥

1. 在 Supabase Dashboard 中
2. 点击左侧 **Settings** > **API**
3. 找到以下信息：
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...`

4. 将这些信息保存到应用的配置中

## 🔒 安全配置

### 启用邮箱认证（推荐）

1. 进入 **Authentication** > **Providers**
2. 启用 **Email**
3. 配置邮件模板（可选）

### 配置 RLS（已在 SQL 中完成）

Row Level Security 已自动配置，确保：
- ✅ 用户只能访问自己的数据
- ✅ 自动关联 `auth.uid()` 到 `user_id`
- ✅ 防止未授权访问

## 📝 配置前端应用

在 `index.html` 中替换以下配置：

```javascript
const SUPABASE_CONFIG = {
    url: 'https://YOUR-PROJECT-ID.supabase.co',
    anonKey: 'YOUR-ANON-KEY'
};
```

## ⚙️ 可选：设置定期清理任务

如果想要自动定期清理过期数据，可以使用 Supabase Edge Functions 或设置 pg_cron：

```sql
-- 安装 pg_cron 扩展（需要在 Database > Extensions 中启用）
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 每天凌晨 2 点清理所有用户的过期数据
SELECT cron.schedule(
    'cleanup-old-transactions',
    '0 2 * * *',
    $$
    SELECT cleanup_old_transactions(user_id) 
    FROM auth.users;
    $$
);
```

## 🧪 测试数据库连接

在浏览器控制台中测试：

```javascript
// 测试连接
const { data, error } = await supabase
    .from('user_settings')
    .select('*')
    .limit(1);

console.log('Connection test:', error ? 'Failed' : 'Success');
```

## 📊 监控使用情况

1. 进入 **Settings** > **Usage**
2. 查看：
   - Database size（数据库大小）
   - Monthly Active Users（月活跃用户）
   - Bandwidth（带宽使用）

免费版限制：
- 500 MB 数据库空间
- 50,000 月活跃用户
- 2 GB 带宽/月

## 🔧 故障排查

### 问题：无法插入数据
- 检查 RLS 是否正确配置
- 确认用户已登录（`auth.uid()` 不为空）
- 查看浏览器控制台错误

### 问题：同步失败
- 检查网络连接
- 验证 API 密钥是否正确
- 查看 Supabase Dashboard > Logs

### 问题：数据未自动清理
- 确认 `sync_and_cleanup` 函数已创建
- 检查同步逻辑是否调用该函数
- 手动测试：`SELECT sync_and_cleanup('user-uuid-here');`

## 📱 跨设备同步测试

1. 在设备 A 登录并添加数据
2. 点击同步按钮
3. 在设备 B 用同一账户登录
4. 数据应自动拉取到本地

## 🎯 最佳实践

1. **定期同步**：建议定期点击「立即同步到云端」按钮来同步数据
2. **错误处理**：网络错误时静默失败，不影响用户体验
3. **本地优先**：所有操作优先写入本地，后台同步
4. **冲突解决**：本地数据优先于云端
5. **数据备份**：重要数据定期导出（JSON/CSV）

## 🚀 完成！

设置完成后，你的应用将支持：
- ✅ 完全离线工作
- ✅ 跨设备同步
- ✅ 自动数据过期（365天）
- ✅ 用户数据隔离
- ✅ 安全的云端备份
