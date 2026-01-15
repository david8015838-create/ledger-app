# 🧹 清理无效 ID 数据

## 🐛 问题
如果本地数据库中已经有带小数的 ID，即使代码修复了，这些旧数据仍然会导致同步失败。

## 🔧 解决方案

### 方法 1: 清理本地数据库（推荐）

在浏览器控制台（F12）中执行以下代码来清理本地数据库中的无效 ID：

```javascript
// 清理 IndexedDB 中的无效 ID
async function cleanupInvalidIds() {
    const dbName = 'LedgerDB';
    const dbVersion = 1;
    
    return new Promise((resolve, reject) => {
        const request = indexedDB.open(dbName, dbVersion);
        
        request.onsuccess = async (event) => {
            const db = event.target.result;
            const tx = db.transaction(['transactions'], 'readwrite');
            const store = tx.objectStore('transactions');
            
            const getAllRequest = store.getAll();
            getAllRequest.onsuccess = async () => {
                const transactions = getAllRequest.result;
                let fixedCount = 0;
                
                for (const tx of transactions) {
                    const originalId = tx.id;
                    const fixedId = Math.floor(parseFloat(originalId));
                    
                    if (originalId !== fixedId) {
                        // 删除旧记录
                        await new Promise((resolve) => {
                            const deleteReq = store.delete(originalId);
                            deleteReq.onsuccess = () => resolve();
                            deleteReq.onerror = () => resolve(); // 继续处理
                        });
                        
                        // 添加修复后的记录
                        await new Promise((resolve) => {
                            const putReq = store.put({ ...tx, id: fixedId });
                            putReq.onsuccess = () => {
                                fixedCount++;
                                resolve();
                            };
                            putReq.onerror = () => resolve();
                        });
                    }
                }
                
                console.log(`✅ 修复了 ${fixedCount} 条记录的 ID`);
                resolve(fixedCount);
            };
            
            getAllRequest.onerror = () => reject(getAllRequest.error);
        };
        
        request.onerror = () => reject(request.error);
    });
}

// 执行清理
cleanupInvalidIds().then(count => {
    console.log(`✅ 清理完成，修复了 ${count} 条记录`);
    alert(`✅ 清理完成！修复了 ${count} 条记录的 ID。\n\n请刷新页面后重新同步。`);
}).catch(error => {
    console.error('❌ 清理失败:', error);
    alert('❌ 清理失败: ' + error.message);
});
```

### 方法 2: 清理 localStorage（如果使用）

```javascript
// 清理 localStorage 中的无效 ID
const txData = JSON.parse(localStorage.getItem('ledger_tx_v13') || '[]');
const fixedData = txData.map(tx => ({
    ...tx,
    id: Math.floor(parseFloat(tx.id))
}));
localStorage.setItem('ledger_tx_v13', JSON.stringify(fixedData));
console.log('✅ localStorage 中的 ID 已修复');
```

### 方法 3: 清理 Supabase 数据库（如果需要）

如果云端数据库中也有无效 ID，在 Supabase SQL Editor 中执行：

```sql
-- 查找带小数的 ID（应该不会有，因为数据库会拒绝）
SELECT id, amount 
FROM public.transactions 
WHERE id::text LIKE '%.%';

-- 如果有，需要手动删除或修复（通常不会有这种情况）
```

## 📋 执行步骤

1. **打开浏览器控制台**（按 F12）
2. **切换到 Console 标签**
3. **复制并粘贴方法 1 的代码**
4. **按 Enter 执行**
5. **等待清理完成**
6. **刷新页面**
7. **重新尝试同步**

## ✅ 验证

清理后，在控制台中检查：

```javascript
// 检查是否还有无效 ID
const dbName = 'LedgerDB';
const dbVersion = 1;
const request = indexedDB.open(dbName, dbVersion);

request.onsuccess = (event) => {
    const db = event.target.result;
    const tx = db.transaction(['transactions'], 'readonly');
    const store = tx.objectStore('transactions');
    const getAllRequest = store.getAll();
    
    getAllRequest.onsuccess = () => {
        const transactions = getAllRequest.result;
        const invalidIds = transactions.filter(tx => !Number.isInteger(tx.id));
        
        if (invalidIds.length === 0) {
            console.log('✅ 所有 ID 都是整数');
        } else {
            console.error('❌ 仍有无效 ID:', invalidIds.map(tx => tx.id));
        }
    };
};
```

## 🎯 完成

清理完成后，所有 ID 都应该是整数，同步应该可以正常工作了。
