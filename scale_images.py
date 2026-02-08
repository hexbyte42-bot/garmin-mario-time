#!/usr/bin/env python3
"""
放大 Garmin 表盘素材图片
从 Pebble 尺寸 (144x168) 放大到 FR265 尺寸 (416x416)
"""

import os
from PIL import Image

# 配置
INPUT_DIR = "resources"
OUTPUT_DIR = "resources_scaled"

# 缩放比例
SCALE_FACTORS = {
    # 背景: 144x168 -> 416x416 (需要特殊处理，保持比例或重新设计)
    "background_day.png": (416, 416),
    "background_night.png": (416, 416),
    "background_underground.png": (416, 416),
    "background_castle.png": (416, 416),
    
    # 马里奥: 48x48 -> 120x120 (2.5x)
    "mario_normal.png": (120, 120),
    "mario_jump.png": (120, 120),
    "luigi_normal.png": (120, 120),
    "luigi_jump.png": (120, 120),
    "bowser_normal.png": (156, 132),  # Bowser 原来是 78x66
    "bowser_jump.png": (156, 132),
    
    # 方块: 50x50 -> 100x100 (2x)
    "block.png": (100, 100),
    
    # 启动图标: 60x60 -> 60x60 (保持不变)
    "launcher_icon.png": (60, 60),
}

def scale_image(input_path, output_path, size):
    """缩放图片到指定尺寸"""
    with Image.open(input_path) as img:
        # 使用最近邻插值保持像素风格
        scaled = img.resize(size, Image.NEAREST)
        scaled.save(output_path)
        print(f"Scaled: {os.path.basename(input_path)} -> {size}")

def main():
    # 创建输出目录
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    # 处理每个文件
    for filename, size in SCALE_FACTORS.items():
        input_path = os.path.join(INPUT_DIR, filename)
        output_path = os.path.join(OUTPUT_DIR, filename)
        
        if os.path.exists(input_path):
            scale_image(input_path, output_path, size)
        else:
            print(f"Warning: {filename} not found")
    
    print(f"\nDone! Scaled images saved to: {OUTPUT_DIR}")
    print("\nNext steps:")
    print("1. Review the scaled images")
    print("2. Copy them to your project resources folder")
    print("3. Update resources.xml if needed")

if __name__ == "__main__":
    main()
