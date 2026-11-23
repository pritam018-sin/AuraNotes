import os
from PIL import Image

src_img = r"C:\Users\DELL\.gemini\antigravity-ide\brain\a70626c3-b25e-4600-a9a5-a58e6975c440\auranotes_logo_1792727121860.jpg"
project_root = r"c:\Users\DELL\WebDevPractice\chrome\AuraNotes"

img = Image.open(src_img).convert("RGBA")

# Ensure assets dir exists
assets_dir = os.path.join(project_root, "assets")
os.makedirs(assets_dir, exist_ok=True)

# 1. Save PNG
png_path = os.path.join(assets_dir, "app_icon.png")
img_resized = img.resize((512, 512), Image.Resampling.LANCZOS)
img_resized.save(png_path, format="PNG")
print(f"Saved PNG: {png_path}")

# 2. Save ICO to runner resources
ico_dest_runner = os.path.join(project_root, "windows", "runner", "resources", "app_icon.ico")
ico_sizes = [(256, 256), (128, 128), (64, 64), (48, 48), (32, 32), (16, 16)]
img.save(ico_dest_runner, format="ICO", sizes=ico_sizes)
print(f"Saved runner ICO: {ico_dest_runner}")

# 3. Save ICO to project root and assets
ico_dest_root = os.path.join(project_root, "app_icon.ico")
img.save(ico_dest_root, format="ICO", sizes=ico_sizes)
ico_dest_assets = os.path.join(assets_dir, "app_icon.ico")
img.save(ico_dest_assets, format="ICO", sizes=ico_sizes)
print("Icons successfully generated!")
