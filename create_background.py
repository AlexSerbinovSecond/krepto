from PIL import Image, ImageDraw, ImageFont
import os

# Створити зображення 600x400
width, height = 600, 400
img = Image.new('RGB', (width, height), color='#f8f8f8')
draw = ImageDraw.Draw(img)

# Градієнт фон
for y in range(height):
    color_value = int(248 - (y / height) * 15)
    color = (color_value, color_value, color_value + 5)
    draw.line([(0, y), (width, y)], fill=color)

# Додати текст інструкції
try:
    # Спробувати системний шрифт
    font_large = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 22)
    font_small = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 14)
except:
    # Fallback на default шрифт
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Текст по центру
text1 = "Drag Krepto to Applications"
text2 = "to install"
text_color = '#2c2c2c'

# Розрахувати позиції тексту
bbox1 = draw.textbbox((0, 0), text1, font=font_large)
bbox2 = draw.textbbox((0, 0), text2, font=font_small)
text1_width = bbox1[2] - bbox1[0]
text2_width = bbox2[2] - bbox2[0]

x1 = (width - text1_width) // 2
x2 = (width - text2_width) // 2
y1 = height // 2 - 50
y2 = height // 2 - 25

draw.text((x1, y1), text1, fill=text_color, font=font_large)
draw.text((x2, y2), text2, fill=text_color, font=font_small)

# Намалювати красиву стрілку (як у VNC Viewer)
arrow_y = height // 2 + 20
arrow_start_x = 200  # Від Krepto app
arrow_end_x = 400    # До Applications
arrow_color = '#007AFF'
arrow_width = 4

# Основна лінія стрілки
draw.line([(arrow_start_x, arrow_y), (arrow_end_x - 15, arrow_y)], fill=arrow_color, width=arrow_width)

# Наконечник стрілки (більший та красивіший)
arrow_head = [
    (arrow_end_x, arrow_y),
    (arrow_end_x - 15, arrow_y - 8),
    (arrow_end_x - 15, arrow_y + 8)
]
draw.polygon(arrow_head, fill=arrow_color)

# Додати тінь для стрілки
shadow_offset = 2
shadow_color = '#cccccc'
draw.line([(arrow_start_x + shadow_offset, arrow_y + shadow_offset), 
          (arrow_end_x - 15 + shadow_offset, arrow_y + shadow_offset)], 
          fill=shadow_color, width=arrow_width)

shadow_head = [
    (arrow_end_x + shadow_offset, arrow_y + shadow_offset),
    (arrow_end_x - 15 + shadow_offset, arrow_y - 8 + shadow_offset),
    (arrow_end_x - 15 + shadow_offset, arrow_y + 8 + shadow_offset)
]
draw.polygon(shadow_head, fill=shadow_color)

# Зберегти зображення
img.save('dmg_background.png')
print("Background image with arrow created: dmg_background.png")
