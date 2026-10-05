import os
import subprocess
import json
from PIL import Image, ImageDraw, ImageFont

VOCA_DIR = "/Users/huyphan/Downloads/web-app/voca_flutter"
LINGUA_DIR = "/Users/huyphan/Downloads/web-app/lingua-tube"
SCRATCH_DIR = "/Users/huyphan/.gemini/antigravity/brain/88bdc9c4-d73b-45bb-ace2-2dab454a4b1d/scratch"

# Concept A: Modern Refined Kikyou (Japanese Bellflower)
# - Authentic Kikyou 5-petal geometry with smooth seamless convergence
# - Single clean circular negative-space pistil cutout (r=38 in 512, scaled 0.66)
# - Borderless modern squircle gradient

SRC_PETAL = "M 0,-300 C 5.0,-295.1 18.55,-287.5 34.34,-280.8 C 69.0,-266.3 117.0,-227.9 108.65,-173.7 C 106.5,-166.2 105.2,-161.9 101.75,-155.7 L 0,0 L -101.75,-155.7 C -105.2,-161.9 -106.5,-166.2 -108.65,-173.7 C -117.0,-227.9 -69.0,-266.3 -34.34,-280.8 C -18.55,-287.5 -5.0,-295.1 0,-300 Z"

# 1. Standard Squircle SVG (for app_logo, web, Android launcher, macOS)
squircle_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="voca-grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF7E93"/>
      <stop offset="50%" stop-color="#F45B74"/>
      <stop offset="100%" stop-color="#DF4360"/>
    </linearGradient>
    <path id="kikyou-petal" d="{SRC_PETAL}" fill="#FFFDFB"/>
  </defs>
  <rect width="512" height="512" rx="118" fill="url(#voca-grad)"/>
  <g transform="translate(256, 256) scale(0.66)">
    <use href="#kikyou-petal" transform="rotate(0)"/>
    <use href="#kikyou-petal" transform="rotate(72)"/>
    <use href="#kikyou-petal" transform="rotate(144)"/>
    <use href="#kikyou-petal" transform="rotate(216)"/>
    <use href="#kikyou-petal" transform="rotate(288)"/>
    <circle cx="0" cy="0" r="38" fill="#F45B74"/>
  </g>
</svg>'''

# 2. Full-bleed SVG (for iOS AppIcon where Apple rounds the corners automatically)
fullbleed_svg = f'''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <defs>
    <linearGradient id="voca-grad-fb" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FF7E93"/>
      <stop offset="50%" stop-color="#F45B74"/>
      <stop offset="100%" stop-color="#DF4360"/>
    </linearGradient>
    <path id="kikyou-petal-fb" d="{SRC_PETAL}" fill="#FFFDFB"/>
  </defs>
  <rect width="512" height="512" fill="url(#voca-grad-fb)"/>
  <g transform="translate(256, 256) scale(0.66)">
    <use href="#kikyou-petal-fb" transform="rotate(0)"/>
    <use href="#kikyou-petal-fb" transform="rotate(72)"/>
    <use href="#kikyou-petal-fb" transform="rotate(144)"/>
    <use href="#kikyou-petal-fb" transform="rotate(216)"/>
    <use href="#kikyou-petal-fb" transform="rotate(288)"/>
    <circle cx="0" cy="0" r="38" fill="#F45B74"/>
  </g>
</svg>'''

# Write SVGs to scratch
squircle_svg_path = os.path.join(SCRATCH_DIR, "icon_squircle.svg")
fullbleed_svg_path = os.path.join(SCRATCH_DIR, "icon_fullbleed.svg")
with open(squircle_svg_path, "w") as f:
    f.write(squircle_svg)
with open(fullbleed_svg_path, "w") as f:
    f.write(fullbleed_svg)

# Render 1024x1024 master PNGs via qlmanage
subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", SCRATCH_DIR, squircle_svg_path], check=True)
subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", SCRATCH_DIR, fullbleed_svg_path], check=True)

squircle_master = Image.open(os.path.join(SCRATCH_DIR, "icon_squircle.svg.png")).convert("RGBA")
fullbleed_master = Image.open(os.path.join(SCRATCH_DIR, "icon_fullbleed.svg.png")).convert("RGBA")

print("Rendered 1024x1024 master PNGs")

# Copy simplified SVG to assets
assets_icons = os.path.join(VOCA_DIR, "assets", "icons")
os.makedirs(assets_icons, exist_ok=True)
with open(os.path.join(assets_icons, "icon.svg"), "w") as f:
    f.write(squircle_svg)
print("Updated voca_flutter/assets/icons/icon.svg")

# Also update lingua-tube SVGs if available
for lt_sub in [os.path.join(LINGUA_DIR, "src", "assets", "icon.svg"), os.path.join(LINGUA_DIR, "src", "favicon.svg")]:
    if os.path.exists(os.path.dirname(lt_sub)):
        with open(lt_sub, "w") as f:
            f.write(squircle_svg)
        print(f"Updated {lt_sub}")

# Update app_logo.png (512x512)
assets_images = os.path.join(VOCA_DIR, "assets", "images")
os.makedirs(assets_images, exist_ok=True)
app_logo_512 = squircle_master.resize((512, 512), Image.Resampling.LANCZOS)
app_logo_512.save(os.path.join(assets_images, "app_logo.png"), "PNG")
print("Saved assets/images/app_logo.png")

# Branded splash logo function (Icon + "Voca" text)
def create_splash_logo(width, height, icon_size, font_size, text_offset):
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    resized_icon = squircle_master.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    ix = (width - icon_size) // 2
    iy = (height - icon_size - text_offset) // 2
    canvas.paste(resized_icon, (ix, iy), resized_icon)
    
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", font_size, index=0)
    except Exception:
        font = ImageFont.load_default()
        
    ty = iy + icon_size + (text_offset // 2)
    draw.text((width // 2, ty), "Voca", fill=(248, 250, 252, 255), font=font, anchor="mm")
    return canvas

# Save in-app splash_logo.png
splash_logo = create_splash_logo(480, 560, 320, 84, 110)
splash_logo.save(os.path.join(assets_images, "splash_logo.png"), "PNG")
print("Saved assets/images/splash_logo.png")

# iOS LaunchImage
ios_launch_dir = os.path.join(VOCA_DIR, "ios", "Runner", "Assets.xcassets", "LaunchImage.imageset")
os.makedirs(ios_launch_dir, exist_ok=True)
create_splash_logo(180, 220, 120, 32, 42).save(os.path.join(ios_launch_dir, "LaunchImage.png"), "PNG")
create_splash_logo(360, 440, 240, 64, 84).save(os.path.join(ios_launch_dir, "LaunchImage@2x.png"), "PNG")
create_splash_logo(540, 660, 360, 96, 126).save(os.path.join(ios_launch_dir, "LaunchImage@3x.png"), "PNG")
print("Saved iOS LaunchImages")

# Android LaunchImage & Splash
android_res = os.path.join(VOCA_DIR, "android", "app", "src", "main", "res")
android_densities = {
    "drawable": (360, 440, 240, 64, 84),
    "drawable-mdpi": (180, 220, 120, 32, 42),
    "drawable-hdpi": (270, 330, 180, 48, 63),
    "drawable-xhdpi": (360, 440, 240, 64, 84),
    "drawable-xxhdpi": (540, 660, 360, 96, 126),
    "drawable-xxxhdpi": (720, 880, 480, 128, 168),
}
for folder, (w, h, sz, fs, to) in android_densities.items():
    folder_path = os.path.join(android_res, folder)
    os.makedirs(folder_path, exist_ok=True)
    img = create_splash_logo(w, h, sz, fs, to)
    img.save(os.path.join(folder_path, "launch_image.png"), "PNG")

# Android 12+ API 31+ splash icon
v31_canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
v31_icon = squircle_master.resize((360, 360), Image.Resampling.LANCZOS)
v31_canvas.paste(v31_icon, (76, 76), v31_icon)
v31_canvas.save(os.path.join(android_res, "drawable", "splash_icon_v31.png"), "PNG")
print("Saved Android launch drawables and splash_icon_v31.png")

# Android Launcher Mipmaps
android_mipmaps = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
for folder, sz in android_mipmaps.items():
    folder_path = os.path.join(android_res, folder)
    os.makedirs(folder_path, exist_ok=True)
    ic = squircle_master.resize((sz, sz), Image.Resampling.LANCZOS)
    ic.save(os.path.join(folder_path, "ic_launcher.png"), "PNG")
print("Saved Android ic_launcher mipmaps")

# iOS App Icons (AppIcon.appiconset)
ios_appicon_dir = os.path.join(VOCA_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
contents_path = os.path.join(ios_appicon_dir, "Contents.json")
if os.path.exists(contents_path):
    with open(contents_path, "r") as f:
        data = json.load(f)
    for entry in data.get("images", []):
        fn = entry.get("filename")
        if not fn:
            continue
        sz_str = entry["size"].split("x")[0]
        sz_val = float(sz_str)
        scale_val = float(entry["scale"].replace("x", ""))
        px = int(round(sz_val * scale_val))
        
        # Use full-bleed without transparent corners as required by iOS
        ios_ic = fullbleed_master.resize((px, px), Image.Resampling.LANCZOS).convert("RGB")
        ios_ic.save(os.path.join(ios_appicon_dir, fn), "PNG")
print("Saved iOS AppIcons")

# macOS App Icons
macos_appicon_dir = os.path.join(VOCA_DIR, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.exists(macos_appicon_dir):
    macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
    for s in macos_sizes:
        fn = f"app_icon_{s}.png"
        mac_ic = squircle_master.resize((s, s), Image.Resampling.LANCZOS)
        mac_ic.save(os.path.join(macos_appicon_dir, fn), "PNG")
print("Saved macOS AppIcons")

# Web Icons
web_icons_dir = os.path.join(VOCA_DIR, "web", "icons")
os.makedirs(web_icons_dir, exist_ok=True)
squircle_master.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-192.png"), "PNG")
squircle_master.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-512.png"), "PNG")
fullbleed_master.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-maskable-192.png"), "PNG")
fullbleed_master.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-maskable-512.png"), "PNG")
squircle_master.resize((32, 32), Image.Resampling.LANCZOS).save(os.path.join(VOCA_DIR, "web", "favicon.png"), "PNG")
print("Saved Web icons")
print("All assets successfully regenerated!")
