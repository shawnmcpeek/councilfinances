from PIL import Image
import os
import shutil

def ensure_dir(directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

def resize_image(input_path, output_path, size):
    with Image.open(input_path) as img:
        # Convert to RGBA if not already
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        # Resize image
        resized_img = img.resize(size, Image.Resampling.LANCZOS)
        # Save with transparency
        resized_img.save(output_path, 'PNG')

def generate_android_icons(input_path):
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
        'mipmap-anydpi-v26': 192,  # Adaptive icon
    }
    
    base_dir = 'android/app/src/main/res'
    
    # Generate regular icons
    for folder, size in android_sizes.items():
        if folder != 'mipmap-anydpi-v26':  # Skip adaptive icon folder for now
            output_dir = os.path.join(base_dir, folder)
            ensure_dir(output_dir)
            output_path = os.path.join(output_dir, 'ic_launcher.png')
            resize_image(input_path, output_path, (size, size))
    
    # Generate adaptive icon
    adaptive_dir = os.path.join(base_dir, 'mipmap-anydpi-v26')
    ensure_dir(adaptive_dir)
    
    # Create foreground and background layers for adaptive icon
    with Image.open(input_path) as img:
        if img.mode != 'RGBA':
            img = img.convert('RGBA')
        
        # Create foreground - just the icon centered at 80% size
        icon_size = int(192 * 0.8)
        icon = img.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
        foreground = Image.new('RGBA', (192, 192), (0, 0, 0, 0))  # Transparent background
        position = ((192 - icon_size) // 2, (192 - icon_size) // 2)
        foreground.paste(icon, position, icon)
        foreground.save(os.path.join(adaptive_dir, 'ic_launcher_foreground.png'), 'PNG')
    
    # Create a solid color background
    background = Image.new('RGBA', (192, 192), (13, 71, 161, 255))  # Using primaryColor from AppTheme
    background.save(os.path.join(adaptive_dir, 'ic_launcher_background.png'), 'PNG')

def generate_ios_icons(input_path):
    ios_sizes = {
        '20x20': 20,
        '20x20@2x': 40,
        '20x20@3x': 60,
        '29x29': 29,
        '29x29@2x': 58,
        '29x29@3x': 87,
        '40x40': 40,
        '40x40@2x': 80,
        '40x40@3x': 120,
        '60x60@2x': 120,
        '60x60@3x': 180,
        '76x76': 76,
        '76x76@2x': 152,
        '83.5x83.5@2x': 167,
        '1024x1024': 1024,  # App Store
    }
    
    base_dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    ensure_dir(base_dir)
    
    # Generate Contents.json for iOS
    contents = {
        "images": [],
        "info": {
            "author": "xcode",
            "version": 1
        }
    }
    
    for name, size in ios_sizes.items():
        output_path = os.path.join(base_dir, f'Icon-{name}.png')
        resize_image(input_path, output_path, (size, size))
        
        # Add to Contents.json
        image_info = {
            "size": f"{size}x{size}",
            "idiom": "universal",
            "filename": f"Icon-{name}.png",
            "scale": "1x" if "@" not in name else name.split("@")[1]
        }
        contents["images"].append(image_info)
    
    # Write Contents.json
    import json
    with open(os.path.join(base_dir, 'Contents.json'), 'w') as f:
        json.dump(contents, f, indent=2)

def main():
    input_path = 'knights1.png'
    
    # Verify input image exists
    if not os.path.exists(input_path):
        print(f"Error: {input_path} not found!")
        return
    
    print("Generating Android icons...")
    generate_android_icons(input_path)
    
    print("Generating iOS icons...")
    generate_ios_icons(input_path)
    
    print("Icon generation complete!")

if __name__ == "__main__":
    main() 