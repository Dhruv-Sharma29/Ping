"""Builds Ping's 1024px light and dark app icons from the logo originals in this folder.

Run from the Ping folder:  python3 Design/make-icons.py   (needs Pillow)

Steps: crop inside the logo's own rounded square (its corners are black), separate the
P and sparks from their backdrop by colour difference, shrink them to 84% so the sparks
clear iOS's corner mask, and place them on a clean gradient made from the backdrop's
corner colours.
"""
from PIL import Image, ImageChops

CENTER_X, CENTER_Y, HALF = 619.5, 626, 431.5  # square inside the originals' rounded corners
SIZE, INNER = 1024, 860                       # icon size; logo size inside it (84%)
OUT = "Ping/Assets.xcassets/AppIcon.appiconset/"


def gradient(img, size, inset=50):
    """Bilinear gradient from the colours near the image's four corners."""
    n = img.size[0] - 1
    grid = Image.new("RGB", (2, 2))
    corners = {(0, 0): (inset, inset), (1, 0): (n - inset, inset),
               (0, 1): (inset, n - inset), (1, 1): (n - inset, n - inset)}
    for cell, point in corners.items():
        grid.putpixel(cell, img.getpixel(point))
    return grid.resize((size, size), Image.BILINEAR)


box = (round(CENTER_X - HALF), round(CENTER_Y - HALF), round(CENTER_X + HALF), round(CENTER_Y + HALF))
offset = (SIZE - INNER) // 2
for source, name in [("Design/logo-light.webp", "AppIcon.png"), ("Design/logo-dark.webp", "AppIcon-Dark.png")]:
    crop = Image.open(source).convert("RGB").crop(box)
    r, g, b = ImageChops.difference(crop, gradient(crop, crop.size[0])).split()
    alpha = ImageChops.lighter(ImageChops.lighter(r, g), b).point(lambda v: max(0, min(255, (v - 10) * 6)))
    icon = gradient(crop, SIZE)  # RGB, no alpha channel: the App Store rejects icons with alpha
    icon.paste(crop.resize((INNER, INNER), Image.LANCZOS), (offset, offset), alpha.resize((INNER, INNER), Image.LANCZOS))
    icon.save(OUT + name)
    print("wrote", OUT + name)
