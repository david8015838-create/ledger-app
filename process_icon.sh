#!/bin/bash
# 處理 PWA 圖標：放大中央圖案並生成多種尺寸
# 使用 macOS 內建的 sips 工具

INPUT_FILE="IMG_7827.PNG"

if [ ! -f "$INPUT_FILE" ]; then
    echo "錯誤：找不到檔案: $INPUT_FILE"
    exit 1
fi

# 創建輸出目錄
mkdir -p icons

# 放大係數（1.3 = 放大 30%，減少周圍空白）
SCALE=1.3
CROP_RATIO=0.75  # 裁剪中央 75% 區域

# 獲取原始圖片尺寸
WIDTH=1024
HEIGHT=1024

echo "原始圖片尺寸: ${WIDTH}x${HEIGHT}"
echo "放大中央圖案 (係數: ${SCALE})..."

# 計算裁剪區域（放大中央區域）
CROP_SIZE=$(echo "$WIDTH * $CROP_RATIO" | bc | cut -d. -f1)
CROP_X=$(( ($WIDTH - $CROP_SIZE) / 2 ))
CROP_Y=$(( ($HEIGHT - $CROP_SIZE) / 2 ))

echo "裁剪中央區域: ${CROP_SIZE}x${CROP_SIZE} (從 $CROP_X, $CROP_Y)"

# 臨時文件：裁剪中央區域
TEMP_CROP="icons/temp_cropped.png"

# 使用 sips 裁剪中央區域（先裁剪成正方形，然後放大）
# 注意：sips 的 -c 參數需要高度和寬度
sips -c $CROP_SIZE $CROP_SIZE --cropOffset $CROP_Y $CROP_X "$INPUT_FILE" --out "$TEMP_CROP" > /dev/null 2>&1

# 放大到原始尺寸（這會使中央圖案更大，邊距更小）
sips -z $WIDTH $HEIGHT "$TEMP_CROP" --out "$TEMP_CROP" > /dev/null 2>&1

echo "生成圖標尺寸..."

# 192x192
sips -z 192 192 "$TEMP_CROP" --out "icons/icon-192x192.png" > /dev/null 2>&1
echo "✓ 已生成: icons/icon-192x192.png"

# 512x512
sips -z 512 512 "$TEMP_CROP" --out "icons/icon-512x512.png" > /dev/null 2>&1
echo "✓ 已生成: icons/icon-512x512.png"

# 180x180 (iOS)
sips -z 180 180 "$TEMP_CROP" --out "icons/apple-touch-icon-180x180.png" > /dev/null 2>&1
echo "✓ 已生成: icons/apple-touch-icon-180x180.png"

# 清理臨時文件
rm -f "$TEMP_CROP"

echo ""
echo "處理完成！圖標已生成到 icons/ 目錄"
