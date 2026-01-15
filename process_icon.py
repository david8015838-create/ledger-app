#!/usr/bin/env python3
"""
處理 PWA 圖標：放大中央圖案並生成多種尺寸
需要安裝 Pillow: pip3 install Pillow
"""

import sys
import os
from pathlib import Path

try:
    from PIL import Image, ImageEnhance, ImageFilter
    HAS_PIL = True
except ImportError:
    HAS_PIL = False
    print("錯誤：需要安裝 Pillow。執行: pip3 install Pillow")
    sys.exit(1)

def process_icon(input_path, output_dir="icons", scale_factor=1.4):
    """
    處理圖標：
    1. 讀取原始圖片
    2. 放大中央區域（減少周圍空白）
    3. 生成 192x192 和 512x512 尺寸
    """
    # 讀取原始圖片
    img = Image.open(input_path).convert("RGBA")
    original_size = img.size
    
    print(f"原始圖片尺寸: {original_size}")
    
    # 計算新的尺寸（放大中央區域）
    # 假設原始圖片中央 70% 是主要內容，我們將其放大到 100%
    crop_ratio = 0.7
    new_width = int(original_size[0] * crop_ratio * scale_factor)
    new_height = int(original_size[1] * crop_ratio * scale_factor)
    
    # 確保不超過原始尺寸
    new_width = min(new_width, original_size[0])
    new_height = min(new_height, original_size[1])
    
    # 計算裁剪區域（保持居中）
    left = (original_size[0] - new_width) // 2
    top = (original_size[1] - new_height) // 2
    right = left + new_width
    bottom = top + new_height
    
    # 裁剪中央區域
    cropped = img.crop((left, top, right, bottom))
    
    # 放大到原始尺寸（這會使中央圖案更大，減少邊距）
    processed = cropped.resize(original_size, Image.Resampling.LANCZOS)
    
    # 創建輸出目錄
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    # 生成不同尺寸
    sizes = [
        (192, 192, "icon-192x192.png"),
        (512, 512, "icon-512x512.png"),
        (180, 180, "apple-touch-icon-180x180.png"),  # iOS 專用
    ]
    
    for width, height, filename in sizes:
        resized = processed.resize((width, height), Image.Resampling.LANCZOS)
        output_file = output_path / filename
        resized.save(output_file, "PNG", optimize=True)
        print(f"已生成: {output_file} ({width}x{height})")
    
    return processed

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: python3 process_icon.py <圖片路徑> [縮放係數]")
        print("範例: python3 process_icon.py icon.png 1.4")
        sys.exit(1)
    
    input_file = sys.argv[1]
    scale = float(sys.argv[2]) if len(sys.argv) > 2 else 1.4
    
    if not os.path.exists(input_file):
        print(f"錯誤：找不到檔案: {input_file}")
        sys.exit(1)
    
    process_icon(input_file, scale_factor=scale)
    print("\n處理完成！")
