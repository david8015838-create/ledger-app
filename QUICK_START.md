# 📱 Ledger App V2.0 - 快速开始指南

## 🎉 新特性：本地优先 + 云端备份

你的记账 App 现在支持：
- ✅ **完全离线工作** - 无需网络也能记账
- ✅ **跨设备同步** - 数据自动备份到云端
- ✅ **智能数据管理** - 云端仅保留 365 天数据，本地永久保留
- ✅ **安全隔离** - 每个用户的数据完全独立

---

## 🚀 快速开始（3 种模式）

### 模式 1：仅本地模式（无需配置，立即可用）

如果你只想在单一设备使用，不需要任何配置：

1. 直接打开 `index.html`
2. 开始记账！

**特点：**
- 所有数据存储在 IndexedDB 和 localStorage
- 完全离线工作
- 不需要网络
- 不需要注册账号

---

### 模式 2：云端同步模式（推荐）

如果你想跨设备同步数据：

#### 步骤 1：创建 Supabase 项目

1. 访问 [https://supabase.com](https://supabase.com) 并注册
2. 创建新项目（免费版即可）
3. 等待项目初始化（约 2 分钟）

#### 步骤 2：执行数据库脚本

1. 进入 Supabase Dashboard
2. 点击左侧 **SQL Editor**
3. 点击 **New Query**
4. 复制 `supabase-schema.sql` 的全部内容并粘贴
5. 点击 **Run** 执行

#### 步骤 3：获取 API 密钥

1. 在 Supabase Dashboard 中
2. 点击 **Settings** > **API**
3. 复制以下信息：
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGc...`

#### 步骤 4：配置应用

在 `index.html` 文件中找到（约第 977 行）：

```javascript
const SUPABASE_CONFIG = {
    url: 'YOUR_SUPABASE_URL', // 👈 替换为你的 Project URL
    anonKey: 'YOUR_SUPABASE_ANON_KEY' // 👈 替换为你的 anon key
};
```

替换为你的实际值：

```javascript
const SUPABASE_CONFIG = {
    url: 'https://abcdefg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
};
```

#### 步骤 5：启用用户认证（可选但推荐）

1. 在 Supabase Dashboard 中
2. 点击 **Authentication** > **Providers**
3. 启用 **Email** 或 **Google** 登录
4. 用户登录后，数据会自动关联到其账户

> **提示：** 如果不启用认证，应用仍可工作，但所有用户会共享数据（不推荐）。

---

### 模式 3：开发/测试模式

如果你想在本地开发：

```bash
# 启动本地服务器（避免 CORS 问题）
python3 -m http.server 8000

# 或使用 Node.js
npx http-server -p 8000

# 然后访问
open http://localhost:8000
```

---

## 📖 使用说明

### 日常记账

1. 打开应用，点击 ➕ 按钮
2. 输入金额、选择分类、币种
3. 点击「完成」

**手动同步：** 请点击「立即同步到云端」按钮来同步数据

### 手动同步

1. 进入「设置」页面
2. 找到「Cloud Sync」面板
3. 点击「🔄 立即同步到云端」

**查看同步状态：**
- 🟢 **已同步** - 数据已安全备份
- 🟡 **未同步** - 有新数据待上传
- 🔵 **同步中...** - 正在同步
- 🔴 **同步失败** - 检查网络或配置
- ⚪ **仅本地** - 未配置云端

### 跨设备使用

**场景：** 你在手机 A 上记账，想在手机 B 上查看

1. **手机 A：** 确保已同步（进入设置查看）
2. **手机 B：** 
   - 打开应用
   - 用同一账户登录（如果启用了认证）
   - 数据会自动拉取到本地

**注意：** 云端仅保留最近 365 天的数据，但手机 A 上的所有历史数据仍完整保留。

### 数据管理

#### 本地数据
- **存储位置：** IndexedDB + localStorage（双重备份）
- **容量限制：** 通常 50MB+（足够数万笔记录）
- **数据保留：** 永久保留，直到你手动清理

#### 云端数据
- **存储位置：** Supabase PostgreSQL
- **容量限制：** 免费版 500MB（约可存储 10 万笔记录）
- **数据保留：** 自动清理 365 天前的数据
- **清理时机：** 每次同步时自动执行

#### 数据导出（可选）

虽然数据已安全存储，但你仍可手动导出备份：

```javascript
// 在浏览器控制台执行
console.log(JSON.stringify(state.transactions, null, 2));
// 复制输出并保存为 backup.json
```

---

## 🔧 故障排查

### 问题 1：同步失败

**可能原因：**
- 网络连接问题
- Supabase 配置错误
- API 密钥过期

**解决方案：**
1. 检查网络连接
2. 验证 `SUPABASE_CONFIG` 配置正确
3. 打开浏览器控制台查看错误信息
4. 重新获取 API 密钥

### 问题 2：数据未显示

**可能原因：**
- IndexedDB 初始化失败
- 浏览器隐私模式
- 存储空间已满

**解决方案：**
1. 退出隐私/无痕模式
2. 清理浏览器存储空间
3. 查看控制台错误信息
4. 刷新页面重试

### 问题 3：云端空间已满

**症状：** 设置页面显示「云端空间已满」

**解决方案：**
1. 免费版限制 500MB，通常足够使用
2. 如需更多空间，升级到 Supabase Pro（$25/月）
3. 或手动删除云端旧数据（本地数据不受影响）

### 问题 4：无法登录 Supabase

**解决方案：**
1. 确保已在 Supabase Dashboard 启用邮箱认证
2. 检查邮件是否在垃圾箱
3. 使用「重置密码」功能
4. 或使用其他登录方式（Google、GitHub 等）

---

## 🔒 安全与隐私

### 数据安全
- ✅ 所有通信使用 HTTPS 加密
- ✅ Row Level Security (RLS) 确保数据隔离
- ✅ 用户只能访问自己的数据
- ✅ API 密钥仅用于客户端操作

### 隐私保护
- ✅ 本地优先，离线可用
- ✅ 不收集任何分析数据
- ✅ 不追踪用户行为
- ✅ 代码完全开源

### 数据所有权
- ✅ 你完全拥有自己的数据
- ✅ 可随时导出所有数据
- ✅ 可自托管 Supabase
- ✅ 可完全离线使用

---

## 📊 数据同步逻辑

### 同步策略

```
本地操作（新增/修改/删除）
    ↓
立即保存到 IndexedDB（主存储）
    ↓
备份到 localStorage（降级方案）
    ↓
后台异步同步到 Supabase（不阻塞用户）
    ↓
[成功] 更新同步状态
[失败] 静默处理，等待下次同步
```

### 冲突解决

**规则：本地数据优先**

- 本地修改 vs 云端旧数据 → 使用本地数据
- 基于 `updated_at` 时间戳判断
- 云端数据永远不会覆盖本地数据

### 手动同步模式

应用采用**手动同步模式**，只有在用户点击「立即同步到云端」按钮时才会同步：

- ✅ 用户手动点击「立即同步到云端」按钮
  - 先上传本地数据到云端
  - 再从云端拉取最新数据
  - 合并本地和云端数据

---

## 🎯 最佳实践

### 1. 定期同步

应用需要手动同步，建议：
- 每周手动同步一次（确保数据安全）
- 在重要操作后手动同步（如批量删除）

### 2. 多设备使用

- **主设备：** 在主要使用的设备上，保持应用打开或定期打开
- **次设备：** 使用前先打开应用，等待数据同步完成

### 3. 数据备份

虽然云端已备份，但建议：
- 每月导出一次数据（JSON 格式）
- 保存到电脑或其他云盘
- 作为额外的安全保障

### 4. 存储管理

- **本地：** 无需担心，数据量很小（即使 1 万笔记录也只有几 MB）
- **云端：** 免费版 500MB 足够使用数年
- **自动清理：** 365 天前的数据会自动从云端清理，本地仍保留

---

## 🆘 需要帮助？

### 查看日志

打开浏览器控制台（F12），查看详细日志：

```
🚀 Initializing Ledger App...
✅ IndexedDB initialized
📂 Loading data from IndexedDB...
✅ Loaded 42 transactions, 5 categories
🔄 Manual sync required - click "立即同步到云端" button
✅ Pulled 40 transactions from cloud
✅ Synced 42 transactions
✅ Cleaned up 5 old records from cloud
✅ App initialized successfully
```

### 常见错误代码

- `PGRST116` - 数据不存在（正常，首次使用）
- `23505` - 唯一性冲突（自动处理）
- `42P01` - 表不存在（检查 schema 是否执行）
- `42501` - 权限不足（检查 RLS 策略）

### 联系支持

- **GitHub Issues:** [项目链接]
- **Email:** your-email@example.com
- **文档:** 查看 `SUPABASE_SETUP.md` 获取详细设置说明

---

## 🎓 技术架构

### 前端
- **框架：** Vanilla JavaScript
- **样式：** Tailwind CSS
- **图表：** Chart.js
- **图标：** Lucide Icons

### 本地存储
- **主存储：** IndexedDB（结构化数据库）
- **备份：** localStorage（降级方案）
- **容量：** 50MB+（浏览器限制）

### 云端存储
- **数据库：** Supabase (PostgreSQL)
- **认证：** Supabase Auth
- **API：** RESTful API
- **安全：** Row Level Security (RLS)

### 同步机制
- **策略：** 本地优先（Offline First）
- **冲突解决：** 最后写入胜（Last Write Wins）
- **数据流：** 单向同步（本地 → 云端）
- **清理策略：** 自动删除 365 天前数据

---

## 📝 更新日志

### V2.0 (2026-01-13)
- ✨ 实现本地优先架构（IndexedDB）
- ✨ 添加 Supabase 云端同步
- ✨ 实现 365 天数据自动过期
- ✨ 添加同步状态 UI
- ✨ 支持完全离线工作
- ✨ 改进错误处理
- 🎨 优化同步体验
- 🔒 增强数据安全

### V1.x
- 基础记账功能
- 多币种支持
- 主题切换
- 数据可视化

---

## 🙏 致谢

感谢以下开源项目：
- [Supabase](https://supabase.com) - 云端数据库
- [Tailwind CSS](https://tailwindcss.com) - 样式框架
- [Chart.js](https://chartjs.org) - 图表库
- [Lucide Icons](https://lucide.dev) - 图标库

---

**🎉 现在开始记账吧！无论在线还是离线，你的数据永远安全可靠。**
