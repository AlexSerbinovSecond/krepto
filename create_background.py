from PIL import Image, ImageDraw, ImageFont
import os

# Створити зображення 600x400
width, height = 600, 400
img = Image.new('RGB', (width, height), color='#f0f0f0')
draw = ImageDraw.Draw(img)

# Градієнт фон
for y in range(height):
    color_value = int(240 - (y / height) * 20)
    color = (color_value, color_value, color_value + 10)
    draw.line([(0, y), (width, y)], fill=color)

# Додати текст інструкції
try:
    # Спробувати системний шрифт
    font_large = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 24)
    font_small = ImageFont.truetype('/System/Library/Fonts/Helvetica.ttc', 16)
except:
    # Fallback на default шрифт
    font_large = ImageFont.load_default()
    font_small = ImageFont.load_default()

# Текст по центру
text1 = "Drag Krepto to Applications"
text2 = "to install"
text_color = '#333333'

# Розрахувати позиції тексту
bbox1 = draw.textbbox((0, 0), text1, font=font_large)
bbox2 = draw.textbbox((0, 0), text2, font=font_small)
text1_width = bbox1[2] - bbox1[0]
text2_width = bbox2[2] - bbox2[0]

x1 = (width - text1_width) // 2
x2 = (width - text2_width) // 2
y1 = height // 2 - 40
y2 = height // 2 - 10

draw.text((x1, y1), text1, fill=text_color, font=font_large)
draw.text((x2, y2), text2, fill=text_color, font=font_small)

# Намалювати стрілку
arrow_y = height // 2 + 30
arrow_start_x = width // 2 - 50
arrow_end_x = width // 2 + 50
arrow_color = '#007AFF'

# Лінія стрілки
draw.line([(arrow_start_x, arrow_y), (arrow_end_x, arrow_y)], fill=arrow_color, width=3)

# Наконечник стрілки
draw.polygon([
    (arrow_end_x, arrow_y),
    (arrow_end_x - 10, arrow_y - 5),
    (arrow_end_x - 10, arrow_y + 5)
], fill=arrow_color)

# Зберегти зображення
img.save('dmg_background.png')
print("Background image created: dmg_background.png")
