import os
import shutil
import json
from PIL import Image, ImageDraw, ImageFont

SRC_DIR = "/Users/huyphan/Downloads/web-app/lingua-tube"
DST_DIR = "/Users/huyphan/Downloads/web-app/voca_flutter"

icon_svg_src = os.path.join(SRC_DIR, "src", "assets", "icon.svg")
icon_512_src = os.path.join(SRC_DIR, "public", "icons", "icon-512x512.png")
apple_180_src = os.path.join(SRC_DIR, "public", "icons", "apple-icon-180.png")
maskable_512_src = os.path.join(SRC_DIR, "public", "icons", "manifest-icon-512.maskable.png")

# 1. Ensure asset directories exist in voca_flutter
assets_images = os.path.join(DST_DIR, "assets", "images")
assets_icons = os.path.join(DST_DIR, "assets", "icons")
os.makedirs(assets_images, exist_ok=True)
os.makedirs(assets_icons, exist_ok=True)

# Copy SVG and master icon
shutil.copy(icon_svg_src, os.path.join(assets_icons, "icon.svg"))
shutil.copy(icon_512_src, os.path.join(assets_images, "app_logo.png"))
print("Copied icon.svg and app_logo.png to assets/")

# Load base images
icon_512 = Image.open(icon_512_src).convert("RGBA")
apple_180 = Image.open(apple_180_src).convert("RGBA")
maskable_512 = Image.open(maskable_512_src).convert("RGBA")

# 2. Function to create branded splash logo (Badge + "Voca" text)
def create_splash_logo(width, height, icon_size, font_size, text_offset):
    canvas = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    resized_icon = icon_512.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    ix = (width - icon_size) // 2
    iy = (height - icon_size - text_offset) // 2
    canvas.paste(resized_icon, (ix, iy), resized_icon)
    
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Avenir Next.ttc", font_size, index=0) # Bold
    except Exception:
        font = ImageFont.load_default()
        
    ty = iy + icon_size + (text_offset // 2)
    draw.text((width // 2, ty), "Voca", fill=(248, 250, 252, 255), font=font, anchor="mm")
    return canvas

# Save high-res in-app splash logo asset
splash_logo_master = create_splash_logo(480, 560, 320, 84, 110)
splash_logo_master.save(os.path.join(assets_images, "splash_logo.png"), "PNG")
print("Generated assets/images/splash_logo.png")

# 3. iOS Launch Images (LaunchImage.imageset)
ios_launch_dir = os.path.join(DST_DIR, "ios", "Runner", "Assets.xcassets", "LaunchImage.imageset")
os.makedirs(ios_launch_dir, exist_ok=True)

launch_1x = create_splash_logo(180, 220, 120, 32, 42)
launch_2x = create_splash_logo(360, 440, 240, 64, 84)
launch_3x = create_splash_logo(540, 660, 360, 96, 126)

launch_1x.save(os.path.join(ios_launch_dir, "LaunchImage.png"), "PNG")
launch_2x.save(os.path.join(ios_launch_dir, "LaunchImage@2x.png"), "PNG")
launch_3x.save(os.path.join(ios_launch_dir, "LaunchImage@3x.png"), "PNG")
print("Generated iOS LaunchImage @1x, @2x, @3x")

# 4. Android Launch Images (drawables)
android_res = os.path.join(DST_DIR, "android", "app", "src", "main", "res")

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

# Android 12+ (API 31+) splash icon with circular safe zone
v31_canvas = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
v31_icon = icon_512.resize((360, 360), Image.Resampling.LANCZOS)
v31_canvas.paste(v31_icon, (76, 76), v31_icon)
v31_canvas.save(os.path.join(android_res, "drawable", "splash_icon_v31.png"), "PNG")
print("Generated Android launch_image drawables and splash_icon_v31.png")

# 5. Android Launcher Icons (mipmap)
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
    ic = icon_512.resize((sz, sz), Image.Resampling.LANCZOS)
    ic.save(os.path.join(folder_path, "ic_launcher.png"), "PNG")
print("Generated Android ic_launcher.png mipmaps")

# 6. iOS App Icons (AppIcon.appiconset)
ios_appicon_dir = os.path.join(DST_DIR, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
contents_path = os.path.join(ios_appicon_dir, "Contents.json")
if os.path.exists(contents_path):
    with open(contents_path, "r") as f:
        data = json.load(f)
    for entry in data.get("images", []):
        fn = entry.get("filename")
        if not fn:
            continue
        # Calculate pixel dimensions: size (e.g. "60x60") * scale (e.g. "2x" or "1x")
        sz_str = entry["size"].split("x")[0]
        sz_val = float(sz_str)
        scale_val = float(entry["scale"].replace("x", ""))
        px = int(round(sz_val * scale_val))
        
        # Use full-bleed maskable/apple icon without transparent corners as required by iOS
        ios_ic = maskable_512.resize((px, px), Image.Resampling.LANCZOS).convert("RGB")
        ios_ic.save(os.path.join(ios_appicon_dir, fn), "PNG")
print("Generated iOS AppIcons from official full-bleed asset")

# 7. macOS App Icons
macos_appicon_dir = os.path.join(DST_DIR, "macos", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.exists(macos_appicon_dir):
    macos_sizes = [16, 32, 64, 128, 256, 512, 1024]
    for s in macos_sizes:
        fn = f"app_icon_{s}.png"
        mac_ic = icon_512.resize((s, s), Image.Resampling.LANCZOS)
        mac_ic.save(os.path.join(macos_appicon_dir, fn), "PNG")
print("Generated macOS AppIcons")

# 8. Web icons
web_icons_dir = os.path.join(DST_DIR, "web", "icons")
os.makedirs(web_icons_dir, exist_ok=True)

icon_512.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-192.png"), "PNG")
icon_512.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-512.png"), "PNG")
maskable_512.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-maskable-192.png"), "PNG")
maskable_512.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(web_icons_dir, "Icon-maskable-512.png"), "PNG")
icon_512.resize((32, 32), Image.Resampling.LANCZOS).save(os.path.join(DST_DIR, "web", "favicon.png"), "PNG")
print("Generated Web icons")
