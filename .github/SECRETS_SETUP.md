# GitHub Secrets 設定指南

為了讓 GitHub Actions 能夠自動保持 Supabase 專案活躍，您需要在 GitHub 儲存庫中設定以下 Secrets。

## 📝 需要設定的 Secrets

### 1. SUPABASE_URL
- **值**: `https://ndtkurowumazsgdotlxb.supabase.co`
- **說明**: 您的 Supabase 專案 URL

### 2. SUPABASE_ANON_KEY
- **值**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5kdGt1cm93dW1henNnZG90bHhiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgyMzUwMzUsImV4cCI6MjA4MzgxMTAzNX0.tukEU-T8f8Sne7KRFOPBYgtlhalHWaPMJlZ_Qpa6J6E`
- **說明**: 您的 Supabase Anon/Public API Key

---

## 🔧 設定步驟

### 步驟 1: 前往 GitHub 儲存庫設定
1. 打開您的 GitHub 儲存庫：`https://github.com/david8015838-create/ledger-app`
2. 點擊上方的 **Settings** 標籤
3. 在左側選單找到 **Secrets and variables** → 點擊 **Actions**

### 步驟 2: 新增第一個 Secret
1. 點擊 **New repository secret** 按鈕
2. **Name**: 輸入 `SUPABASE_URL`
3. **Secret**: 貼上 `https://ndtkurowumazsgdotlxb.supabase.co`
4. 點擊 **Add secret**

### 步驟 3: 新增第二個 Secret
1. 再次點擊 **New repository secret** 按鈕
2. **Name**: 輸入 `SUPABASE_ANON_KEY`
3. **Secret**: 貼上您的 Anon Key（見上方）
4. 點擊 **Add secret**

---

## ✅ 驗證設定

設定完成後，您可以：

### 手動測試 Action
1. 前往 **Actions** 標籤
2. 在左側選擇 **Keep Supabase Active**
3. 點擊 **Run workflow** → **Run workflow**
4. 查看執行結果

### 檢查自動執行
- GitHub Action 會在每天凌晨 2:00 UTC（台灣時間 10:00）自動執行
- 您可以在 **Actions** 標籤查看歷史執行記錄

---

## 📊 工作原理

這個 GitHub Action 會：
1. 每天自動對您的 Supabase 資料庫發送一個簡單查詢
2. 查詢 `categories` 表（只取 1 筆資料）
3. 保持您的 Supabase 專案活躍，避免因長期不使用而被暫停
4. 記錄執行結果，方便您追蹤

---

## 🔒 安全說明

- ✅ 使用 GitHub Secrets 安全儲存敏感資訊
- ✅ Secrets 不會在 logs 中顯示
- ✅ 只使用 Anon Key（公開 API Key），不會洩漏敏感資料
- ✅ 只執行讀取操作，不會修改資料

---

## 💡 提示

如果您想要：
- **改變執行時間**：修改 `.github/workflows/keep-supabase-active.yml` 中的 `cron` 設定
- **停用自動執行**：刪除或註解掉 `schedule` 部分
- **手動執行**：隨時可以在 Actions 頁面手動觸發
