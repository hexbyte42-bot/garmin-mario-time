#!/usr/bin/env python3
"""
简化版 Garmin 字体生成器
从 TTF 生成 FNT + PNG（仅支持数字 0-9）
"""

import os
import sys
from PIL import Image, ImageDraw, ImageFont

def create_garmin_font(ttf_path, output_name, size=48):
    """生成 Garmin 格式的位图字体"""
    
    chars = "0123456789"
    char_list = list(chars)
    
    # 加载字体
    try:
        font = ImageFont.truetype(ttf_path, size)
    except Exception as e:
        print(f"Error loading font: {e}")
        return False
    
    # 计算每个字符的尺寸
    char_data = []
    max_width = 0
    max_height = 0
    
    for char in char_list:
        bbox = font.getbbox(char)
        width = bbox[2] - bbox[0]
        height = bbox[3] - bbox[1]
        char_data.append({
            'char': char,
            'width': width,
            'height': height,
            'bbox': bbox
        })
        max_width = max(max_width, width)
        max_height = max(max_height, height)
    
    # 添加一些间距
    padding = 4
    max_width += padding * 2
    max_height += padding * 2
    
    # 创建图集（横向排列）
    atlas_width = max_width * len(char_list)
    atlas_height = max_height
    
    # 使用白色背景（Garmin 需要）
    atlas = Image.new('RGBA', (atlas_width, atlas_height), (255, 255, 255, 0))
    draw = ImageDraw.Draw(atlas)
    
    # 渲染每个字符
    fnt_entries = []
    x_offset = 0
    
    for i, data in enumerate(char_data):
        char = data['char']
        width = data['width']
        height = data['height']
        bbox = data['bbox']
        
        # 计算绘制位置（居中）
        char_x = x_offset + padding
        char_y = padding + (max_height - height) // 2 - bbox[1]
        
        # 绘制字符（黑色）
        draw.text((char_x, char_y), char, font=font, fill=(0, 0, 0, 255))
        
        # FNT 文件条目
        # id, x, y, width, height, xoffset, yoffset, xadvance
        fnt_entries.append({
            'id': ord(char),
            'x': x_offset,
            'y': 0,
            'width': max_width,
            'height': max_height,
            'xoffset': 0,
            'yoffset': 0,
            'xadvance': max_width
        })
        
        x_offset += max_width
    
    # 保存 PNG
    png_path = f"{output_name}.png"
    atlas.save(png_path)
    print(f"Created: {png_path}")
    
    # 生成 FNT 文件（Garmin 格式）
    fnt_path = f"{output_name}.fnt"
    with open(fnt_path, 'w') as f:
        f.write("info face=\"PixelFont\" size={} bold=0 italic=0 charset=\"\" unicode=0 stretchH=100 smooth=1 aa=1 padding=0,0,0,0 spacing=2,2\n".format(size))
        f.write("common lineHeight={} base={} scaleW={} scaleH={} pages=1 packed=0\n".format(max_height, max_height, atlas_width, atlas_height))
        f.write("page id=0 file=\"{}\"\n".format(os.path.basename(png_path)))
        f.write("chars count={}\n".format(len(char_list)))
        
        for entry in fnt_entries:
            f.write("char id={} x={} y={} width={} height={} xoffset={} yoffset={} xadvance={} page=0 chnl=0\n".format(
                entry['id'], entry['x'], entry['y'], entry['width'], entry['height'],
                entry['xoffset'], entry['yoffset'], entry['xadvance']
            ))
    
    print(f"Created: {fnt_path}")
    return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 font_generator.py <ttf_file> [output_name] [size]")
        print("Example: python3 font_generator.py Gamegirl.ttf pixel_font 48")
        sys.exit(1)
    
    ttf_file = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else "custom_font"
    size = int(sys.argv[3]) if len(sys.argv) > 3 else 48
    
    if create_garmin_font(ttf_file, output, size):
        print("\nSuccess! Add this to resources.xml:")
        print(f'  <font id="{output}" filename="{output}.fnt" antialias="true" />')
    else:
        print("Failed to create font")
