# DWLibV1 Elements Reference

Every widget, window call, and system in DWLibV1, with the exact tables each
one takes. Unless noted, every `data` table below is optional fields only —
constructors never throw on missing keys.

Conventions used here:

- `Flag` — string key in `Library.Flags`. Give one when a value must persist
  in configs; omit it and the lib mints a stable `dw_flag_N` id.
- `Callback` — always `task.spawn`ed, never blocks the UI thread.
- `Tooltip = "..."` — accepted by Toggle, Button, Slider, Dropdown, Textbox
  and Label. Hovering the row shows a floating card that follows the mouse.
- Right-clicking a Toggle or Button opens its keybind menu: pick Toggle /
  Hold / Always, or rebind the key. Press Backspace while picking to clear
  the bind. No code needed. Unbound keybinds stay off the keybind-list
  panel until a key is set.

---

## 1. Booting

```lua
local Library = loadstring(
    game:HttpGet("http://127.0.0.1:9001/DWLIBV1/DWLibV1.lua?t=" .. tick())
)()
assert(type(Library) == "table", "DWLib did not return Library")

local Window = Library:CreateWindow({
    Name = "DROIDWARE",        -- header title + window branding
    SubName = "My Script",    -- header subtitle, Home page, footer
    DevMode = true,           -- header pill: DEVMODE (red) vs PRODUCTION (quiet); omit to hide
    HomeOptions = {           -- Home tab content (see §3)
        subtitle = "#1 Script HUB",
        gameName = "My Game",   -- optional override; otherwise resolved
                                -- automatically via MarketplaceService
        tags = { "Free", "Live" },
        credits = { "Lead Dev: you", "UI Library: DWLib V1" },
        discordLink = "",
    },
    HomeTabEnabled = true,    -- default true: Home is always first tab
    SettingsTabEnabled = true,-- default true: auto Settings tab, kept last
    WatermarkEnabled = false, -- floating "Name | executor | ping | FPS"
    WatermarkText = "DROIDWARE",
    -- WatermarkStats = false, -- static text, no live stats
    -- WatermarkScale = 1.25, -- watermark scale (0.5 - 3, default 1)
    KeybindListEnabled = false,-- floating panel of bound keybinds
    -- KeybindListVisible = true,
    -- KeybindListScale = 1.25, -- panel scale (0.5 - 3, default 1)
    ToggleButtonEnabled = false, -- floating D button; auto-on for touch-only
    -- ToggleButtonPosition = UDim2.new(0, 16, 0.5, -22),
    -- ToggleButtonSize = UDim2.new(0, 44, 0, 44),
})
Window:HideLoading() -- call when done building; auto-hides after 4s anyway
```

Re-executing unloads the previous copy first (plus a boot sweep kills stale
copies even when the executor isolates environments), so reloads never stack.

`Library:SetMenuKeybind(Enum.KeyCode.RightShift)` changes the toggle key.
Settings → Interface has a click-to-pick `[key]` chip for it (any key works,
persisted as `__menukey` in configs).

## 2. Window

```lua
local Tab = Window:AddTab({ Name = "Combat", Icon = "swords" })   -- or Window:AddTab("Combat", "swords")
local Sub = Tab:AddSubTab({ Name = "Auto Farm" }) -- pill row under the tab

Window:SetOpen(bool)        -- show/hide, animated
Window:ToggleMaximize()     -- 980x600 <-> 1300x750, animated
Window:SetMaximized(bool)
Window:SetCenter()          -- recenter on screen
Window:SelectFirst()        -- select first top-level tab
Window:Search("text")       -- same filter the header search box applies
Window:SetLoadingStatus("Loading configs...")
Window:HideLoading()
Window:CreateHomePage(opts) -- manual; auto-created, returns existing after

Window.Watermark    -- SetText(t), SetStatsEnabled(b), SetVisibility(b), SetCenter(),
                    -- SetScale(s) (0.5 - 3), GetScale()
Window.KeybindList  -- Refresh(), SetVisibility(b), SetPosition(udim2),
                    -- SetScale(s) (0.5 - 3), GetScale()
Window.ToggleButton -- Press(), SetVisibility(b), SetPosition(udim2)
```

Tab order is declaration order; **Home stays first, Settings stays last**.
`Window:AddTab` past those keeps it that way automatically.

**Tabs are containers only.** Every tab must have at least one sub-tab, and
only sub-tabs can hold sections/elements. `Tab:AddSection` errors — use
`Sub:AddSection` instead. (Home and Settings are system pages and are exempt:
sections sit directly on the tab.)

`Icon` is a kebab-case lucide name (`"swords"`, `"eye"`, `"car"` — full list
in `DWLIBV1/src/Icons.lua`), a raw `rbxassetid://...`, or a numeric asset id.
Unknown names fall back to text-only. Icons tint with the theme automatically.
`Library:GetIcon(name)` resolves any of these (nil for unknown).

## 3. Home tab (mandatory)

Built first on every window unless `HomeTabEnabled = false`. Three separated
cards: a welcome banner (avatar with accent ring, name, subtitle), a one-line
strip of stat pills (accent lucide icon + Players / Ping / FPS / Uptime,
1s refresh), and an info card holding Credits + Game Info sub-cards with a
Copy Discord button.

## 4. Sections

```lua
local Sec = Sub:AddSection({ Name = "Aim Assist" })            -- left column
local R   = Sub:AddSection({ Name = "Checks", Side = 2 })      -- right column
local C   = Sub:AddSection({ Name = "Collapsed", Open = false })
```

- `Side = 1` (default) left, `Side = 2` right.
- Header arrow collapses with animation: `Sec:SetOpen(bool)`,
  `Sec:ToggleOpen()`, `Sec.IsOpen`.

## 5. Toggle

```lua
local T = Sec:AddToggle({
    Name = "Enabled", Flag = "aim_enabled", Default = false,
    Tooltip = "Master switch",
    Callback = function(on) print("aim", on) end,
})
T:Get()      -- bool
T:Set(true)  -- paints + fires Callback
T:SetVisibility(bool)
```

Sub-elements dock right of the row, DW-style:

```lua
T:Keybind({ Flag = "aim_key", Default = Enum.KeyCode.Q, Mode = "Toggle" })
T:Colorpicker({ Flag = "aim_color", Default = Color3.fromRGB(220, 30, 42) })
```

Keybind `Mode` is `"Toggle"` (default), `"Hold"`, or `"Always"`.
On a toggle the keybind is two-way bound: the chip shows the bound key and
pressing it writes straight into the toggle — the toggle stays the single
source of truth (clicks, code, and config loads all refresh the binding).
Keybind handle: `Get()` (reads the toggle), `GetMode()`, `SetMode(m)`,
`Press(v)`, `StartPicking()`, `SetVisibility(b)`, `Refresh()`.
`GetParts()` returns `{ name, key, on }` (nil when unbound) — the keybind
list renders it as `| name | STATE - [key] |`.
`Always` locks its toggle on — `Set(false)` is ignored until the mode changes.
`Hold` is key-driven only: row clicks and `Press()` can't stick it on, and
switching to Hold (or loading it) starts from off.

## 6. Button

```lua
local B = Sec:AddButton({ Name = "Reset", Tooltip = "...", Callback = fn })
B:Press()              -- programmatic click (same punch + callback)
B:SetText("New name")
B:SetVisibility(bool)
B:Keybind({ ... })     -- a bound key IS a press; callback runs exactly once
```

## 7. Slider

```lua
local S = Sec:AddSlider({
    Name = "FOV", Flag = "aim_fov",
    Min = 15, Max = 360, Default = 90,
    Decimals = 0.5,       -- snap step (also accepts Dec =)
    Suffix = " deg",      -- appended to the value readout
    Callback = function(v) print(v) end,
})
S:Get()
S:Set(120)               -- glides; dragging stays 1:1 with the cursor
S:SetVisibility(bool)
S:OnRelease(function(v) print("released", v) end) -- fires once per drag
```

Preview-then-commit (`Live = false`): `Callback` is deferred until release,
`Preview` fires on every tick while dragging. Used by Settings → UI Scale:
dragging draws an Accent outline of the target size, letting go applies it.

```lua
Sec:AddSlider({
    Name = "UI Scale", Flag = "__uiscale", Min = 0.75, Max = 1.5,
    Live = false,                       -- defer Callback to release
    Preview = function(v) Library:PreviewUIScale(v) end,
    Callback = function(v) Library:SetUIScale(v) end, -- runs on release
})
```

## 8. Dropdown

```lua
local D = Sec:AddDropdown({
    Name = "Target", Flag = "aim_part",
    Items = { "Head", "Torso" }, Default = "Head",
    Callback = function(v) print(v) end,
})
local M = Sec:AddDropdown({
    Name = "Checks", Flag = "aim_checks", Multi = true,
    Items = { "Visible", "Team" }, Default = { "Visible" },
    Callback = function(list) print(table.concat(list, ",")) end,
})
D:Get()                  -- value, or map for Multi
D:Set("Torso")           -- D:Set({"Visible", "Team"}) for Multi
D:Refresh({ "A", "B" })  -- replace items (optionally + Set default)
D:SetOpen(true)          -- opens in the top overlay layer
D:SelectAll()            -- Multi only
D:DeselectAll()          -- Multi only
D:SetVisibility(bool)
```

Lists open above everything (own overlay layer, click-outside to close,
flips upward near the screen edge). Rows show name left + current value
right; items are checkbox rows (accent box + ✓ when on). Long lists scroll,
capped at ~8 rows. The Settings → Saved-configs dropdown
re-reads the disk on every open — same pattern, free for any list.

## 9. Textbox

```lua
local T = Sec:AddTextbox({
    Name = "Note", Flag = "note",
    Placeholder = "type here", Default = "",
    Numeric = true,   -- reject non-numbers
    Finished = true,  -- fire on Enter (false = fire on every change)
    Callback = function(text) print(text) end,
})
T:Get()
T:Set("hello")
T:SetVisibility(bool)
```

## 10. Label

```lua
local L = Sec:AddLabel("Status: idle")   -- or AddLabel({ Text = "..." })
L:SetText("Status: running")
L:Get()
L:SetVisibility(bool)
L:Keybind({ ... })       -- chip docks right
L:Colorpicker({ ... })   -- swatch docks right
```

## 11. Colorpicker (HSV)

```lua
-- Standalone (builds its own host label, returns the picker):
local P = Sec:AddColorpicker({
    Name = "Accent", Flag = "accent",
    Default = Color3.fromRGB(220, 30, 42),
    Alpha = 0.4,          -- start transparency; Alpha = false drops the bar
    Callback = function(color, alpha) print(color:ToHex(), alpha) end,
})
-- Attached (same, docks right of a Toggle or Label):
local P2 = T:Colorpicker({ Flag = "esp_color", Default = Color3.fromRGB(255,255,255) })
P:Get()                  -- color, alpha
P:Set(Color3.fromRGB(255, 0, 0), 0.25)
P:SetOpen(true)          -- opens in the top overlay layer
-- picker.Label -> host label (standalone form only)
```

Alpha is **transparency** (`0` solid, `1` invisible), persisted per flag.
The row swatch renders the alpha live. Popup: saturation/value palette,
hue strip, alpha strip, hex readout. Settings → Theming pickers have no
alpha bar (theme keys are plain `Color3`).

## 12. Notification & Dialog

```lua
Library:Notification("Title", "Body", 4)   -- duration secs (omit: uses the
                                     -- Settings → Notify length default);
Library:Notification("Short note.")        -- returns handle with :Close()

Library:Dialog({
    Title = "Reset?",
    Text = "Reset farm settings?",
    Buttons = {
        { Text = "Yes", Accent = true, Callback = function() end },
        { Text = "No" },
    },
}) -- returns handle with :Close()
```

## 13. Flags & Configs

```lua
Library.Flags.my_flag      -- live values by Flag (toggles bool, sliders
                           -- number, dropdowns value/map, textboxes string,
                           -- colorpickers Color3, keybinds { Key, Mode, Toggled })
Library:ApplyFlags()       -- repaint every widget from Flags (theme preset)
Library:ApplyFlags(true)  -- repaint + fire every Callback (used by Load)

Library:GetConfig()        -- JSON string (flags + theme + background)
Library:SaveConfig("main") -- DWLIBV1/Configs/main.json (needs writefile)
Library:LoadConfigFile("main")
Library:LoadConfig(jsonString)
Library:ListConfigs()      -- {"main", ...} (needs listfiles)
Library:DeleteConfig("main")
Library:SetAutoloadConfig("main")  -- applied via Library:LoadAutoload()
Library:GetAutoloadConfigName()
Library:ClearAutoloadConfig()
Library:LoadAutoload()     -- call AFTER building UI; repaints everything
                            -- (also re-applies saved UI prefs: scale,
                            -- panel visibility, animations, tooltips,
                            -- notify length)
```

Without file functions the calls fail safe (`Save` false, `List` `{}`).

## 14. Theming

```lua
Library:ApplyThemePreset("Default")  -- Linoria pack: BBot, Fatality, Jester,
                            -- Mint, "Tokyo Night", Ubuntu, Quartz (+ legacy
                            -- DroidRed, Midnight, Crimson, Ghost)
Library:ChangeTheme("Accent", color)
Library:SetBackgroundImage("rbxassetid://123", 0.5)  -- "" restores default (nil = no art), "none"/nil clears
Library:SetUIScale(1.25)                             -- 0.5 - 2, persisted
-- Every window also picks up Library.DefaultBackgroundImage (set it in
-- src/LibraryTable.lua after uploading the PNG) unless a config overrides it.
Library:PreviewUIScale(1.25)                         -- outline only; commit with SetUIScale
Library:ClearUIScalePreview()

-- Global look switches (src/LibraryTable.lua):
--   Library.SquareCorners = true  -- Linoria look: every UICorner flattens to
--                                  -- radius 0 (Utils:Corner honors it)
--   Library.Font = Enum.Font.Code -- single mono face used by all widgets
```

Keys: `Background, Panel, Element, Element2, Surface, Inline, Accent,
AccentSoft, Text, TextMuted, Outline, OutlineSoft`. Settings → Theming edits
every key live, plus background image/transparency and UI scale (Interface).
Interface also holds: menu key, keybind list, watermark + stats, toggle
button, panel-position reset, UI animations, tooltips, notify length.
A separate UI Elements section holds the UI scale, keybind list scale,
and watermark scale sliders (all persisted through configs).
Theming adds random-preset and reset-theme buttons. All of it persists
through configs.

## 15. Lifecycle

```lua
Library:OnUnload(function() ... end)  -- runs inside Library:Unload()
Library:Unload()                      -- disconnects, stops loops, destroys UI
```

`Library.Unloading` / `Library.Unloaded` flip during unload. Long-running
game code should use the template's `alive()` pattern (gen counter + these
flags) so farm loops die with the UI — see `Scripts/_TEMPLATE.lua`.

## 16. Script patterns (see Scripts/_TEMPLATE.lua)

- `DwGuard(function() ... end)` around everything: boot errors notify
  instead of dying silent.
- Route by `game.GameId` (one GameId covers lobby + in-game places).
- One `state` table; workers read it so sliders apply mid-run (Luau caps
  200 locals per function — tables dodge it).
- Resolve character parts per use (`root()`, `hum()`), never cached.
- `fire(remote, ...)` / `invoke(remote, ...)` wrappers for all traffic.
- `track(conn)` every connection + `OnUnload` cleanup.
- `?t=" .. tick()` on every fetch URL (executor caches defeat).
- Confirm every remote + argument shape with a spy before coding it; write
  findings (and dead ends) in the header recon block.
