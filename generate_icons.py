from PIL import Image
import os

# Source image
SRC_IMAGE = "knights3.png"

# Output directories and sizes for each platform
ICON_SIZES = {
    "android": [
        ("mipmap-mdpi", 48),
        ("mipmap-hdpi", 72),
        ("mipmap-xhdpi", 96),
        ("mipmap-xxhdpi", 144),
        ("mipmap-xxxhdpi", 192),
    ],
    "ios": [
        ("Icon-App-20x20@1x", 20),
        ("Icon-App-20x20@2x", 40),
        ("Icon-App-20x20@3x", 60),
        ("Icon-App-29x29@1x", 29),
        ("Icon-App-29x29@2x", 58),
        ("Icon-App-29x29@3x", 87),
        ("Icon-App-40x40@1x", 40),
        ("Icon-App-40x40@2x", 80),
        ("Icon-App-40x40@3x", 120),
        ("Icon-App-60x60@2x", 120),
        ("Icon-App-60x60@3x", 180),
        ("Icon-App-76x76@1x", 76),
        ("Icon-App-76x76@2x", 152),
        ("Icon-App-83.5x83.5@2x", 167),
        ("Icon-App-1024x1024@1x", 1024),
    ],
    "web": [
        ("Icon-192", 192),
        ("Icon-512", 512),
        ("favicon", 16),
    ],
    "windows": [
        ("app_icon_16", 16),
        ("app_icon_32", 32),
        ("app_icon_48", 48),
        ("app_icon_256", 256),
    ],
    "macos": [
        ("app_icon_16", 16),
        ("app_icon_32", 32),
        ("app_icon_128", 128),
        ("app_icon_256", 256),
        ("app_icon_512", 512),
        ("app_icon_1024", 1024),
    ]
}

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def save_icon(img, out_path, size):
    icon = img.resize((size, size), Image.LANCZOS)
    icon.save(out_path, format="PNG")

def main():
    img = Image.open(SRC_IMAGE).convert("RGBA")
    for platform, icons in ICON_SIZES.items():
        out_dir = f"generated_icons/{platform}"
        ensure_dir(out_dir)
        for name, size in icons:
            out_path = os.path.join(out_dir, f"{name}.png")
            save_icon(img, out_path, size)
            print(f"Saved {out_path}")

if __name__ == "__main__":
    main()