# 🔐 Ledger App - Magic Link 登录使用指南

## 📋 目录
1. [系统架构](#系统架构)
2. [Supabase 设置](#supabase-设置)
3. [登录流程](#登录流程)
4. [数据同步机制](#数据同步机制)
5. [安全性说明](#安全性说明)

---

## 系统架构

### 本地优先 + 云端备份

```
┌─────────────────────────────────────────────┐
│           Ledger App (前端)                  │
│  ┌─────────────────────────────────────┐    │
│  │     IndexedDB (本地数据库)            │    │
│  │  - 所有交易记录                       │    │
│  │  - 分类设置                          │    │
│  │  - 用户偏好                          │    │
│  │  ✅ 100% 离线可用                    │    │
│  └─────────────────────────────────────┘    │
│              ↕ 双向同步                      │
│  ┌─────────────────────────────────────┐    │
│  │   Supabase Cloud (云端备份)          │    │
│  │  - transactions (最近365天)          │    │
│  │  - categories                        │    │
│  │  - user_settings                     │    │
│  │  ✅ 跨设备同步                       │    │
│  └─────────────────────────────────────┘    │
└─────────────────────────────────────────────┘
```

### 数据流转

```
用户操作 → IndexedDB (本地存储) → 后台同步 → Supabase (云端)
   ↓                                              ↓
立即生效                                     365天自动清理
```

---

## Supabase 设置

### 1. 执行数据库 Schema

在 Supabase Dashboard → SQL Editor 中执行 `supabase-schema.sql`：

```sql
-- 这将创建：
-- ✅ transactions 表（交易记录）
-- ✅ categories 表（分类）
-- ✅ user_settings 表（用户设置）
-- ✅ RLS 策略（Row Level Security）
-- ✅ 自动清理函数（365天过期策略）
-- ✅ 新用户初始化触发器
```

### 2. 启用 Magic Link 登录

1. 进入 Supabase Dashboard
2. 导航到 **Authentication** → **Providers**
3. 找到 **Email**
4. 启用 **Enable Email provider**
5. **取消勾选** "Confirm email"（可选，简化流程）
6. 保存设置

### 3. 配置 Email Templates（可选）

在 **Authentication** → **Email Templates** 中自定义登录邮件模板：

**Magic Link 模板示例：**
```html
<h2>欢迎回到 Ledger!</h2>
<p>点击下方链接完成登录：</p>
<p><a href="{{ .ConfirmationURL }}">登入我的账户</a></p>
<p>此链接将在 24 小时后过期。</p>
```

### 4. 设置 Redirect URLs（重要）

在 **Authentication** → **URL Configuration** 中添加：

```
Site URL: file:///path/to/your/ledger-app/index.html
Redirect URLs: 
  - file:///path/to/your/ledger-app/index.html
  - http://localhost:8080  (如果使用本地服务器)
```

---

## 登录流程

### 场景 1：新用户首次使用

```
1. 打开应用 → 显示登录页面
2. 用户可以选择：
   a) 输入 Email → 收到 Magic Link → 点击登录
   b) 点击"跳过，僅使用本地模式" → 直接使用（无云端同步）
```

### 场景 2：已有本地数据的用户

```
1. 打开应用 → 直接进入主页（显示本地数据）
2. 可在"设置"页面随时登录云端账户
```

### 场景 3：Magic Link 登录详细步骤

#### **步骤 1：输入 Email**

```
┌─────────────────────────────────┐
│         LEDGER™                 │
│                                 │
│  [  登入  ] [  註冊  ]          │
│                                 │
│  Email:                         │
│  ┌───────────────────────────┐ │
│  │ your@email.com            │ │
│  └───────────────────────────┘ │
│                                 │
│  [ ✨ 發送登入連結 ]             │
│                                 │
│  我們會將登入連結寄到您的信箱    │
│  點擊連結即可完成登入，無需密碼  │
│                                 │
│  [跳過，僅使用本地模式]          │
└─────────────────────────────────┘
```

#### **步驟 2：檢查信箱**

用戶將收到來自 Supabase 的登入郵件：

```
主題: Confirm your email
內容:
  歡迎回到 Ledger!
  
  點擊下方連結完成登入：
  [登入我的賬戶] ← 點此
  
  此連結將在 24 小時後過期。
```

#### **步驟 3：自動登入**

```
用戶點擊郵件中的連結 
   ↓
應用自動檢測到登入狀態
   ↓
觸發 onAuthStateChange 事件
   ↓
顯示主應用界面
   ↓
後台自動執行初次同步
```

### 設置頁面的登入狀態顯示

**未登入狀態：**
```
┌─────────────────────────────────┐
│  Account & Sync                 │
│  ○ 需要登录                      │
│                                 │
│  登录状态: 本地模式               │
│                                 │
│  [ 🔐 登入雲端账户 ]             │
│                                 │
│  (同步信息隐藏)                  │
└─────────────────────────────────┘
```

**已登入狀態：**
```
┌─────────────────────────────────┐
│  Account & Sync                 │
│  ● 需要登录                      │
│                                 │
│  登录状态: ✅ 已登录              │
│  账户: your@email.com            │
│                                 │
│  [ 🚪 登出账户 ]                 │
│                                 │
│  ─────────────────────────      │
│  本地数据: 15 笔交易              │
│  最后同步: 2 分钟前               │
│  [ 🔄 立即同步到云端 ]           │
│  💡 提示：应用会在打开时自动同步  │
└─────────────────────────────────┘
```

---

## 數據同步機制

### 自動同步觸發時機

```javascript
1. 應用啟動時 (window.onload)
   → 如果已登入且 > 1小時未同步
   
2. 新增/修改交易後 (saveTransaction)
   → 後台靜默同步
   
3. 修改設定後 (saveSettings)
   → 後台靜默同步
   
4. 用戶手動點擊"立即同步" (manualSync)
   → 前台顯示同步狀態
```

### 同步流程詳解

#### **上傳到雲端 (syncToCloud)**

```
1. 檢查登入狀態
   ├─ 未登入 → 跳過同步
   └─ 已登入 → 繼續

2. 讀取本地數據
   ├─ transactions (所有記錄)
   ├─ categories (所有分類)
   └─ settings (預算、主題、幣種)

3. 自動填入 user_id
   data.user_id = currentUser.id

4. Upsert 到 Supabase
   ON CONFLICT (id) DO UPDATE

5. 執行雲端清理 (365天策略)
   CALL sync_and_cleanup(user_id)

6. 更新最後同步時間
```

#### **從雲端拉取 (syncFromCloud)**

```
1. 查詢雲端數據 (WHERE user_id = ?)
   ├─ transactions (僅最近365天)
   ├─ categories (所有)
   └─ settings (最新設定)

2. 比較 updated_at 時間戳
   IF cloud.updated_at > local.updated_at
      → 更新本地數據
   ELSE
      → 保留本地數據

3. 本地數據永久保留
   (不會因雲端過期而刪除)
```

### 衝突處理策略

**原則：本地優先 (Local First)**

```
場景 A: 同一筆交易，雲端和本地都有修改
   → 比較 updated_at 時間戳
   → 最新的覆蓋舊的

場景 B: 雲端數據已過期（>365天）
   → 雲端自動清理
   → 本地數據完整保留

場景 C: 用戶換新設備登入
   → 只拉取雲端最近365天數據
   → 舊設備本地數據不受影響
```

---

## 安全性說明

### Row Level Security (RLS) 策略

```sql
-- 用戶只能查看自己的數據
CREATE POLICY "Users can view own transactions"
    ON transactions FOR SELECT
    USING (auth.uid() = user_id);

-- 用戶只能插入自己的數據
CREATE POLICY "Users can insert own transactions"
    ON transactions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- 用戶只能修改自己的數據
CREATE POLICY "Users can update own transactions"
    ON transactions FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 用戶只能刪除自己的數據
CREATE POLICY "Users can delete own transactions"
    ON transactions FOR DELETE
    USING (auth.uid() = user_id);
```

### 關鍵安全特性

1. **API 密鑰保護**
   - 只使用 `anon` 公鑰
   - 不暴露 `service_role` 密鑰

2. **用戶隔離**
   - 每筆數據都綁定 `user_id`
   - RLS 自動過濾非本人數據

3. **Magic Link 安全性**
   - 連結 24 小時過期
   - 一次性使用
   - HTTPS 加密傳輸

4. **本地數據保護**
   - IndexedDB 僅當前域可訪問
   - 瀏覽器沙箱隔離

---

## 錯誤處理

### 網絡離線

```javascript
// 應用行為
✅ 本地功能完全可用
✅ 所有數據保存到 IndexedDB
⚠️ 同步靜默失敗（不影響用戶）
🔄 下次上線時自動補同步
```

### 雲端空間已滿

```javascript
// UI 提示
Settings → Cloud Sync:
  "⚠️ 雲端空間已滿，目前僅儲存於本地"

// 應用行為
✅ 本地功能正常
❌ 不再嘗試上傳
```

### 登入失敗

```javascript
// 常見原因
1. Email 格式錯誤 → 提示 "請輸入有效的 Email 地址"
2. Supabase 未配置 → 提示 "Supabase 未配置，無法使用雲端功能"
3. 網絡問題 → 提示 "發送失敗：{error.message}"
```

---

## 常見問題 (FAQ)

### Q1: 如果我換手機了，舊手機的數據會消失嗎？

**A:** 不會！本地數據永久保留。只是新手機登入後，只能從雲端拉取最近 365 天的數據。

### Q2: 我可以同時在多個設備登入嗎？

**A:** 可以！每個設備都有完整的本地副本，會自動同步最新數據。

### Q3: 如果我不想登入，可以一直用本地模式嗎？

**A:** 完全可以！點擊"跳過，僅使用本地模式"，所有功能正常使用，只是無法跨設備同步。

### Q4: Magic Link 沒收到怎麼辦？

**A:**
1. 檢查垃圾郵件資料夾
2. 確認 Supabase Email Provider 已啟用
3. 檢查 Supabase Dashboard → Authentication → Users 是否有該用戶

### Q5: 雲端的 365 天清理會刪除我本地的數據嗎？

**A:** **絕對不會！** 雲端清理只影響 Supabase 數據庫，你的 IndexedDB 本地數據完整保留。

### Q6: 如何完全重置應用？

**A:** 打開瀏覽器開發者工具（F12）：
```javascript
// 清除 IndexedDB
indexedDB.deleteDatabase('ledgerDB')

// 清除 LocalStorage
localStorage.clear()

// 重新載入
location.reload()
```

---

## 開發者備註

### 關鍵代碼位置

```
index.html
├─ 登入 UI: 行 763-838 (<section id="page-auth">)
├─ 登入函數: 行 1986-2061 (handleMagicLink, showAuthMessage)
├─ 同步管理: 行 1265-1480 (class SyncManager)
├─ Auth 監聽: 行 1852-1874 (onAuthStateChange)
└─ 設置頁面: 行 2571-2632 (updateAuthUI)

supabase-schema.sql
├─ RLS 策略: 行 140-209
├─ 自動清理: 行 89-134
└─ 新用戶初始化: 行 263-295
```

### 環境變數

```javascript
const SUPABASE_CONFIG = {
    url: 'https://ndtkurowumazsgdotlxb.supabase.co',
    anonKey: 'eyJhbGc...'  // 公鑰，可安全暴露
};
```

---

## 🎉 總結

**Ledger App** 現在是一個完整的 **本地優先 + 雲端備份** 的記帳應用：

✅ **無需密碼** - Magic Link 一鍵登入  
✅ **完全離線** - IndexedDB 本地存儲  
✅ **自動同步** - Supabase 雲端備份  
✅ **安全隔離** - RLS 策略保護  
✅ **智能清理** - 365 天自動過期  
✅ **跨設備** - 多端數據同步  

**開始使用：**
1. 執行 `supabase-schema.sql`
2. 啟用 Magic Link
3. 打開應用，輸入 Email
4. 收信，點擊連結
5. 開始記帳！🚀
