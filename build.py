import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(HERE, "src")
DEFAULT_OUT = os.path.join(HERE, "DWLibV1.lua")

SEPARATOR = "-- " + "=" * 60

MODULE_ORDER = [
    "Header.lua",
    "LibraryTable.lua",
    "Utils.lua",
    "Themes.lua",
    "Icons.lua",
    "Holders.lua",
    "Watermark.lua",
    "Tooltip.lua",
    "Window.lua",
    "Page.lua",
    "Section.lua",
    "Toggle.lua",
    "Button.lua",
    "Slider.lua",
    "Dropdown.lua",
    "Label.lua",
    "Textbox.lua",
    "Keybind.lua",
    "Colorpicker.lua",
    "Notification.lua",
    "Dialog.lua",
    "Config.lua",
    "KeybindList.lua",
    "ESPPreview.lua",
    "ToggleButton.lua",
    "HomePage.lua",
    "SettingsPage.lua",
    "CreateWindow.lua",
    "Aliases.lua",
    "Footer.lua",
]

def build(pure=False):
    parts = []
    for name in MODULE_ORDER:
        path = os.path.join(SRC_DIR, name)
        with open(path, "r", encoding="utf-8", newline="") as f:
            chunk = f.read()
        chunk = chunk.replace("\r\n", "\n")
        if pure:
            parts.append(chunk)
        else:
            parts.append(f"{SEPARATOR}\n-- [ module: {name} ]\n{SEPARATOR}\n\n{chunk}")
    return "".join(parts)

def main():
    pure = "--pure" in sys.argv
    out = DEFAULT_OUT
    if "--out" in sys.argv:
        out = sys.argv[sys.argv.index("--out") + 1]
    content = build(pure=pure)
    with open(out, "w", encoding="utf-8", newline="") as f:
        f.write(content)
    print(f"OK - wrote {out} ({len(content.splitlines())} lines)")

if __name__ == "__main__":
    main()
