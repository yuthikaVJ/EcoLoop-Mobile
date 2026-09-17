import os
from PIL import Image, ImageDraw

def crop_to_circle(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    
    # Create a mask
    mask = Image.new('L', img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse((0, 0, img.size[0], img.size[1]), fill=255)
    
    # Apply the mask
    result = Image.new('RGBA', img.size)
    result.paste(img, (0, 0), mask=mask)
    
    result.save(output_path, "PNG")
    print(f"Successfully cropped and saved to {output_path}")

input_path = "C:/Users/User/Desktop/ECOLOOP/mobile/assets/images/logo.jpeg"
output_path = "C:/Users/User/Desktop/ECOLOOP/mobile/assets/images/logo_rounded.png"

try:
    crop_to_circle(input_path, output_path)
except Exception as e:
    print(f"Error: {e}")
