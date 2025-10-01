#!/usr/bin/env python3

from PIL import Image, ImageDraw
import os

def create_icon(size, filename):
    try:
        # Create a gradient-like background (blue theme for trustworthy family app)
        img = Image.new('RGB', (size, size), '#007AFF')
        draw = ImageDraw.Draw(img)

        # Add a simple clock-like circle for "time" theme
        margin = size // 6
        circle_coords = [margin, margin, size - margin, size - margin]
        draw.ellipse(circle_coords, fill='white', outline='#333333', width=max(1, size//40))

        # Add clock hands
        center = size // 2
        hand_length = size // 4
        line_width = max(1, size//25)

        # Hour hand (pointing to 12)
        draw.line([center, center, center, center - hand_length//2], fill='#333333', width=line_width)
        # Minute hand (pointing to 3)
        draw.line([center, center, center + hand_length//2, center], fill='#333333', width=line_width)

        # Add a small star for "rewards" theme
        if size >= 40:  # Only add star for larger icons
            star_size = size // 8
            star_x = size - star_size - margin//2
            star_y = margin//2

            # Simple diamond/star shape
            star_coords = [
                (star_x + star_size//2, star_y),
                (star_x + star_size, star_y + star_size//2),
                (star_x + star_size//2, star_y + star_size),
                (star_x, star_y + star_size//2)
            ]
            draw.polygon(star_coords, fill='#FFD700', outline='#FFA500')

        # Save the image
        icon_dir = '/Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/ScreenTimeApp/Assets.xcassets/AppIcon.appiconset'
        os.makedirs(icon_dir, exist_ok=True)
        icon_path = os.path.join(icon_dir, filename)
        img.save(icon_path, 'PNG', quality=95)
        print(f"   ✅ Created {filename}")
        return True

    except Exception as e:
        print(f"❌ Error creating {filename}: {e}")
        return False

def main():
    print("🎨 Creating Screen Time Rewards app icons...")

    # Create all required icon sizes
    icons = [
        # iPhone icons
        (40, "app-icon-20x20@2x.png"),
        (60, "app-icon-20x20@3x.png"),
        (58, "app-icon-29x29@2x.png"),
        (87, "app-icon-29x29@3x.png"),
        (80, "app-icon-40x40@2x.png"),
        (120, "app-icon-40x40@3x.png"),
        (120, "app-icon-60x60@2x.png"),
        (180, "app-icon-60x60@3x.png"),

        # iPad icons
        (20, "app-icon-20x20@1x.png"),
        (29, "app-icon-29x29@1x.png"),
        (40, "app-icon-40x40@1x.png"),
        (76, "app-icon-76x76@1x.png"),
        (152, "app-icon-76x76@2x.png"),
        (167, "app-icon-83.5x83.5@2x.png"),

        # App Store icon
        (1024, "app-icon-1024x1024@1x.png")
    ]

    success_count = 0
    for size, filename in icons:
        if create_icon(size, filename):
            success_count += 1

    print(f"\n✅ Successfully created {success_count}/{len(icons)} icons")
    if success_count == len(icons):
        print("🎉 All app icons created successfully!")
        print("\n🎨 Icon Design Features:")
        print("   • Blue background (trustworthy, family-friendly)")
        print("   • White clock face (time management theme)")
        print("   • Clock hands showing 3:00 (structured time)")
        print("   • Gold star (rewards/achievements)")
        print("   • Clean, recognizable design")
    else:
        print("⚠️  Some icons may need manual creation")

    print(f"\n📁 Icons saved to:")
    print("   /Users/ameen/Documents/ScreenTimeRewards-Workspace/Apps/ScreenTimeApp/ScreenTimeApp/Assets.xcassets/AppIcon.appiconset/")

if __name__ == "__main__":
    main()