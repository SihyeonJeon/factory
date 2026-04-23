# R23 Ship Assets Evidence Notes

## Asset Inputs

- Existing source icon: `workspace/ios/App/Assets.xcassets/AppIcon.appiconset/icon_1024.png`
- Existing catalog metadata: `AppIcon.appiconset/Contents.json`, `AccentColor.colorset/Contents.json`, and `Assets.xcassets/Contents.json`

## AppIcon Generation Command History

Operator reported the source icon was generated before this Codex session with a PIL-based one-liner equivalent to:

```bash
python3 - <<'PY'
from PIL import Image, ImageDraw, ImageFont
size = 1024
img = Image.new("RGB", (size, size), "#f77f7f")
draw = ImageDraw.Draw(img)
# Draw coral to lavender gradient, white heart, and "Unfading" wordmark.
img.save("workspace/ios/App/Assets.xcassets/AppIcon.appiconset/icon_1024.png")
PY
```

The exact prior shell history was not available in this fresh Codex session.

## Launch Logo Placeholder

Codex generated the temporary launch logo from the existing icon with:

```bash
sips -Z 256 App/Assets.xcassets/AppIcon.appiconset/icon_1024.png --out App/Assets.xcassets/LaunchLogo.imageset/launch_logo.png
```

Planned replacement: regenerate `launch_logo.png` at approximately 240x240 as a white wordmark on transparent background.

## Deferred Items

- Real branded app icon set beyond the single 1024px source.
- Transparent launch wordmark asset instead of full icon reuse.
- Dark-mode-specific launch screen review and asset variant if needed.
