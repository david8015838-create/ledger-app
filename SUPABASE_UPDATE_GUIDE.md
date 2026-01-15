# 📘 Supabase 数据库更新指南

## 🎯 目标
在 Supabase 数据库中添加两个新功能：
1. 自定义主题字段 (`custom_theme`)
2. 每月固定消费表 (`recurring_transactions`)

## 📝 步骤说明

### 步骤 1: 登录 Supabase Dashboard

1. 打开浏览器，访问：https://supabase.com/dashboard
2. 使用您的账号登录
3. 选择您的项目（如果看到项目列表）

### 步骤 2: 打开 SQL Editor

1. 在左侧菜单栏中，找到并点击 **"SQL Editor"**（SQL 编辑器）
   - 图标通常是一个代码符号 `</>`
   - 或者点击 **"Database"** → **"SQL Editor"**

### 步骤 3: 创建新的 SQL 查询

1. 在 SQL Editor 页面，点击 **"+ New query"**（新建查询）按钮
2. 会打开一个新的 SQL 查询编辑器

### 步骤 4: 复制并粘贴 SQL 代码

1. 打开项目中的文件：`add-sync-fields-migration.sql`
2. **全选**文件中的所有内容（Ctrl+A 或 Cmd+A）
3. **复制**（Ctrl+C 或 Cmd+C）
4. 回到 Supabase SQL Editor
5. **粘贴**到查询编辑器中（Ctrl+V 或 Cmd+V）

### 步骤 5: 执行 SQL 脚本

1. 确认 SQL 代码已粘贴到编辑器中
2. 点击编辑器右下角的 **"Run"**（运行）按钮
   - 或者按快捷键：`Ctrl+Enter`（Windows/Linux）或 `Cmd+Enter`（Mac）

### 步骤 6: 查看执行结果

1. 执行后，页面下方会显示执行结果
2. 如果成功，会看到类似这样的消息：
   ```
   Success. No rows returned
   ```
   或
   ```
   Success. X rows affected
   ```
3. 如果有错误，会显示红色错误信息（请告诉我错误内容）

### 步骤 7: 验证更新是否成功

#### 方法 A: 在 Table Editor 中查看

1. 在左侧菜单栏，点击 **"Table Editor"**（表编辑器）
2. 查看表列表，应该能看到：
   - ✅ `user_settings` 表 - 点击查看，确认有 `custom_theme` 列
   - ✅ `recurring_transactions` 表 - 应该出现在列表中

#### 方法 B: 使用 SQL 查询验证

在 SQL Editor 中执行以下查询来验证：

```sql
-- 检查 user_settings 表是否有 custom_theme 字段
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'user_settings' 
AND column_name = 'custom_theme';

-- 检查 recurring_transactions 表是否存在
SELECT table_name 
FROM information_schema.tables 
WHERE table_name = 'recurring_transactions';
```

如果两个查询都有结果，说明更新成功！

## 🖼️ 图示说明

### SQL Editor 位置
```
Supabase Dashboard
├── Project Settings
├── Database
│   ├── Tables (表编辑器)
│   ├── SQL Editor ← 点击这里
│   └── ...
└── ...
```

### SQL Editor 界面
```
┌─────────────────────────────────────┐
│  SQL Editor                         │
├─────────────────────────────────────┤
│                                     │
│  [SQL 代码粘贴在这里]                │
│                                     │
│                                     │
├─────────────────────────────────────┤
│                    [Run] ← 点击执行 │
└─────────────────────────────────────┘
```

## ⚠️ 常见问题

### Q1: 找不到 SQL Editor？
**A**: 确保您有项目的管理员权限。如果没有，请联系项目所有者。

### Q2: 执行后出现错误？
**A**: 可能的原因：
- 表已经存在（这是正常的，SQL 使用了 `IF NOT EXISTS`）
- 权限问题（需要管理员权限）
- 网络问题

如果看到错误，请：
1. 复制错误信息
2. 告诉我具体的错误内容
3. 我会帮您解决

### Q3: 如何确认更新成功？
**A**: 最简单的方法：
1. 打开 Table Editor
2. 点击 `user_settings` 表
3. 查看列列表，应该能看到 `custom_theme` 列
4. 查看表列表，应该能看到 `recurring_transactions` 表

### Q4: 更新会影响现有数据吗？
**A**: 不会！这个迁移脚本是安全的：
- 使用 `IF NOT EXISTS` 和 `ADD COLUMN IF NOT EXISTS`
- 不会删除或修改现有数据
- 只是添加新字段和新表

## 📋 快速检查清单

执行更新前：
- [ ] 已登录 Supabase Dashboard
- [ ] 已选择正确的项目
- [ ] 已打开 SQL Editor

执行更新时：
- [ ] 已复制完整的 SQL 代码
- [ ] 已粘贴到 SQL Editor
- [ ] 已点击 Run 执行

执行更新后：
- [ ] 看到成功消息
- [ ] 在 Table Editor 中验证了 `custom_theme` 字段
- [ ] 在 Table Editor 中验证了 `recurring_transactions` 表

## 🆘 需要帮助？

如果遇到任何问题：
1. 截图错误信息
2. 告诉我您在哪一步卡住了
3. 我会提供更详细的指导

## ✅ 完成后

更新完成后：
1. 刷新您的应用页面
2. 重新登录
3. 测试同步功能
4. 添加一些数据并点击"立即同步到云端"
5. 在另一个设备/浏览器中验证数据是否同步

---

**提示**: 如果您使用的是中文界面，菜单名称可能是：
- SQL Editor = SQL 编辑器
- Table Editor = 表编辑器
- Run = 运行
