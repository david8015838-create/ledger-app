# 信用卡功能更新说明

## 📅 更新日期
2026-01-14

## 🎯 更新内容

### 1. 数据库 Schema 更新

#### 新增字段到 `transactions` 表
- `payment_method` (TEXT): 支付方式，'cash' 或 'credit'，默认 'cash'
- `card_id` (TEXT): 信用卡 ID
- `installments` (INTEGER): 分期期数，默认 1
- `interest_rate` (NUMERIC): 年利率（百分比），默认 0
- `billing_month` (TEXT): 首期账单月份 (YYYY-MM)

#### 新增 `credit_cards` 表
```sql
CREATE TABLE public.credit_cards (
    id TEXT PRIMARY KEY,
    user_id UUID,
    name TEXT,
    closing_day INTEGER,
    due_days_after INTEGER,
    carrying_balance NUMERIC(10, 2),
    initial_balance NUMERIC(10, 2),
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    is_deleted BOOLEAN
);
```

### 2. 应用功能更新

#### 新增功能
1. **信用卡管理**
   - 新增/编辑/删除信用卡
   - 设置结账日、缴款间隔天数
   - 设置初始未缴清余额

2. **分期付款支持**
   - 支持 1-24 期分期
   - 支持年利率设置（0-36%）
   - 自动计算每期本金和利息
   - 余数自动分配到第一期

3. **账单计算**
   - 自动计算每月应缴信用卡账单
   - 支持跨月账单
   - 处理短月份（如 2 月）
   - 包含初始欠款和结转余额

4. **预算整合**
   - 信用卡本金计入原类别
   - 利息和欠款单独统计
   - 实时显示本月应缴金额

5. **未来预览**
   - 显示未来 3 个月的分期付款
   - 帮助规划未来支出

#### 云端同步更新
- 交易数据同步包含信用卡字段
- 信用卡数据独立同步
- 支持双向合并算法
- 保持数据一致性

### 3. 数据迁移

#### 现有用户
- 旧交易数据自动兼容
- `paymentMethod` 默认为 'cash'
- `installments` 默认为 1
- 不影响现有功能

#### 新用户
- 需要执行 `supabase-migration-credit-cards.sql`
- 或使用更新后的 `supabase-schema.sql` 创建全新数据库

### 4. 文件更新清单

#### 核心文件
- ✅ `index.html` - 主应用逻辑和 UI
- ✅ `supabase-schema.sql` - 完整数据库 Schema
- ✅ `supabase-migration-credit-cards.sql` - 迁移脚本（针对现有数据库）

#### 文档文件
- ✅ `CREDIT_CARD_UPDATE.md` - 本文档
- ✅ `STRESS_TEST_RESULTS.md` - 压力测试结果

### 5. 测试状态

#### ✅ 已测试功能
1. 基础数据加载和显示
2. 信用卡管理（CRUD 操作）
3. 交易功能（现金/信用卡/分期）
4. 预算计算和统计
5. 未来预览
6. 云端同步（上传/下载/合并）
7. 删除同步
8. 代码质量检查

#### 📋 测试数据验证
- 使用"地狱级财务逻辑测试"验证
- 所有计算结果与预期一致
- 跨月、短月份、分期计算均正确

### 6. 部署步骤

#### 对于新部署
1. 在 Supabase Dashboard 执行 `supabase-schema.sql`
2. 部署 `index.html` 到服务器
3. 配置 Supabase API Keys

#### 对于现有部署
1. 在 Supabase Dashboard 执行 `supabase-migration-credit-cards.sql`
2. 更新 `index.html` 到服务器
3. 清除浏览器缓存（重要！）
4. 用户首次登录时会自动同步新字段

### 7. 注意事项

⚠️ **重要提醒**：
1. 执行迁移前请备份数据库
2. 建议在测试环境先验证
3. 用户需要清除浏览器缓存才能加载新版本
4. 初始欠款仅在当前月计入预算

### 8. 兼容性

- ✅ 向后兼容旧版本数据
- ✅ 旧交易自动识别为现金支付
- ✅ 支持跨设备同步
- ✅ 支持 PWA 离线使用

### 9. 已知限制

1. 信用卡数据仅存储在 localStorage 和云端
2. 不支持在 IndexedDB 中存储 cards（使用 localStorage）
3. 初始欠款始终计入当前月（不支持指定起始月份）

### 10. 未来改进方向

- [ ] 支持还款记录历史
- [ ] 支持多币种信用卡
- [ ] 支持自定义账单周期
- [ ] 添加信用卡账单详细报表
- [ ] 支持自动提醒缴款

---

## 🔗 相关文档
- [快速开始](./QUICK_START.md)
- [Supabase 设置](./SUPABASE_SETUP.md)
- [同步修复总结](./SYNC_FIXES_SUMMARY.md)
- [压力测试结果](./STRESS_TEST_RESULTS.md)
