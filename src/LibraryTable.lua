Library.Flags = {}
Library._conns = {}
Library._threads = {}
Library._unloadCbs = {}
Library._themeItems = {}
Library._windows = {}
Library.Unloading = false
Library.MenuKey = Enum.KeyCode.RightShift

-- DroidRed is the default boot theme: near-black red-tinted chrome with a
-- strong red accent (matches the DroidRed preset below).
Library.Theme = {
    Background = Color3.fromRGB(13, 13, 16),
    Panel = Color3.fromRGB(20, 20, 25),
    Element = Color3.fromRGB(24, 24, 30),
    Element2 = Color3.fromRGB(30, 30, 38),
    Surface = Color3.fromRGB(26, 26, 33),
    Inline = Color3.fromRGB(18, 18, 23),
    Accent = Color3.fromRGB(220, 30, 42),
    AccentSoft = Color3.fromRGB(120, 30, 40),
    Text = Color3.fromRGB(240, 240, 245),
    TextMuted = Color3.fromRGB(150, 150, 160),
    Outline = Color3.fromRGB(45, 45, 55),
    OutlineSoft = Color3.fromRGB(32, 32, 40),
    WindowBorder = Color3.fromRGB(50, 50, 50), -- window frame edge
}

-- Linoria ThemeManager's built-in presets, ported 1:1. AccentSoft is the
-- accent's darker variant (V / 1.5), OutlineSoft slightly darker than Outline.
Library.Presets = {
    Default = {
        Background = Color3.fromRGB(20, 20, 20), Panel = Color3.fromRGB(10, 10, 10),
        Element = Color3.fromRGB(28, 28, 28), Element2 = Color3.fromRGB(28, 28, 28),
        Surface = Color3.fromRGB(24, 24, 24), Inline = Color3.fromRGB(16, 16, 16),
        Accent = Color3.fromRGB(0, 85, 255), AccentSoft = Color3.fromRGB(0, 56, 170),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(50, 50, 50), OutlineSoft = Color3.fromRGB(38, 38, 38),
        WindowBorder = Color3.fromRGB(50, 50, 50),
    },
    BBot = {
        Background = Color3.fromRGB(35, 35, 35), Panel = Color3.fromRGB(25, 25, 25),
        Element = Color3.fromRGB(30, 30, 30), Element2 = Color3.fromRGB(30, 30, 30),
        Surface = Color3.fromRGB(27, 27, 27), Inline = Color3.fromRGB(29, 29, 29),
        Accent = Color3.fromRGB(126, 72, 163), AccentSoft = Color3.fromRGB(84, 48, 108),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(20, 20, 20), OutlineSoft = Color3.fromRGB(14, 14, 14),
        WindowBorder = Color3.fromRGB(20, 20, 20),
    },
    Fatality = {
        Background = Color3.fromRGB(25, 19, 53), Panel = Color3.fromRGB(15, 9, 43),
        Element = Color3.fromRGB(30, 24, 66), Element2 = Color3.fromRGB(30, 24, 66),
        Surface = Color3.fromRGB(26, 21, 57), Inline = Color3.fromRGB(21, 16, 44),
        Accent = Color3.fromRGB(197, 7, 84), AccentSoft = Color3.fromRGB(131, 4, 55),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(60, 53, 93), OutlineSoft = Color3.fromRGB(42, 37, 66),
        WindowBorder = Color3.fromRGB(60, 53, 93),
    },
    Jester = {
        Background = Color3.fromRGB(28, 28, 28), Panel = Color3.fromRGB(18, 18, 18),
        Element = Color3.fromRGB(36, 36, 36), Element2 = Color3.fromRGB(36, 36, 36),
        Surface = Color3.fromRGB(31, 31, 31), Inline = Color3.fromRGB(24, 24, 24),
        Accent = Color3.fromRGB(219, 68, 103), AccentSoft = Color3.fromRGB(146, 45, 68),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(55, 55, 55), OutlineSoft = Color3.fromRGB(38, 38, 38),
        WindowBorder = Color3.fromRGB(55, 55, 55),
    },
    Mint = {
        Background = Color3.fromRGB(28, 28, 28), Panel = Color3.fromRGB(18, 18, 18),
        Element = Color3.fromRGB(36, 36, 36), Element2 = Color3.fromRGB(36, 36, 36),
        Surface = Color3.fromRGB(31, 31, 31), Inline = Color3.fromRGB(24, 24, 24),
        Accent = Color3.fromRGB(61, 180, 136), AccentSoft = Color3.fromRGB(40, 120, 90),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(55, 55, 55), OutlineSoft = Color3.fromRGB(38, 38, 38),
    },
    ["Tokyo Night"] = {
        Background = Color3.fromRGB(22, 22, 31), Panel = Color3.fromRGB(12, 12, 21),
        Element = Color3.fromRGB(25, 25, 37), Element2 = Color3.fromRGB(25, 25, 37),
        Surface = Color3.fromRGB(22, 22, 32), Inline = Color3.fromRGB(19, 19, 27),
        Accent = Color3.fromRGB(103, 89, 179), AccentSoft = Color3.fromRGB(68, 59, 119),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(50, 50, 50), OutlineSoft = Color3.fromRGB(34, 34, 48),
        WindowBorder = Color3.fromRGB(50, 50, 50),
    },
    Ubuntu = {
        Background = Color3.fromRGB(50, 50, 50), Panel = Color3.fromRGB(40, 40, 40),
        Element = Color3.fromRGB(62, 62, 62), Element2 = Color3.fromRGB(62, 62, 62),
        Surface = Color3.fromRGB(54, 54, 54), Inline = Color3.fromRGB(43, 43, 43),
        Accent = Color3.fromRGB(226, 88, 30), AccentSoft = Color3.fromRGB(150, 58, 20),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(25, 25, 25), OutlineSoft = Color3.fromRGB(18, 18, 18),
        WindowBorder = Color3.fromRGB(25, 25, 25),
    },
    Quartz = {
        Background = Color3.fromRGB(29, 27, 38), Panel = Color3.fromRGB(19, 17, 28),
        Element = Color3.fromRGB(35, 35, 48), Element2 = Color3.fromRGB(35, 35, 48),
        Surface = Color3.fromRGB(30, 28, 40), Inline = Color3.fromRGB(24, 22, 32),
        Accent = Color3.fromRGB(66, 110, 135), AccentSoft = Color3.fromRGB(44, 73, 90),
        Text = Color3.fromRGB(255, 255, 255), TextMuted = Color3.fromRGB(200, 200, 200),
        Outline = Color3.fromRGB(39, 35, 47), OutlineSoft = Color3.fromRGB(27, 24, 34),
        WindowBorder = Color3.fromRGB(39, 35, 47),
    },
    -- Legacy DWLib palettes kept for back-compat with saved configs.
    DroidRed = {
        Background = Color3.fromRGB(13, 13, 16),
        Panel = Color3.fromRGB(20, 20, 25),
        Element = Color3.fromRGB(24, 24, 30),
        Element2 = Color3.fromRGB(30, 30, 38),
        Surface = Color3.fromRGB(26, 26, 33),
        Inline = Color3.fromRGB(18, 18, 23),
        Accent = Color3.fromRGB(220, 30, 42),
        AccentSoft = Color3.fromRGB(120, 30, 40),
        Text = Color3.fromRGB(240, 240, 245),
        TextMuted = Color3.fromRGB(150, 150, 160),
        Outline = Color3.fromRGB(45, 45, 55),
        OutlineSoft = Color3.fromRGB(32, 32, 40),
    },
    Midnight = {
        Background = Color3.fromRGB(10, 12, 20),
        Panel = Color3.fromRGB(16, 20, 30),
        Element = Color3.fromRGB(22, 28, 40),
        Element2 = Color3.fromRGB(28, 36, 50),
        Surface = Color3.fromRGB(24, 32, 46),
        Inline = Color3.fromRGB(14, 17, 26),
        Accent = Color3.fromRGB(70, 130, 255),
        AccentSoft = Color3.fromRGB(35, 65, 130),
        Text = Color3.fromRGB(235, 240, 255),
        TextMuted = Color3.fromRGB(140, 150, 175),
        Outline = Color3.fromRGB(40, 52, 75),
        OutlineSoft = Color3.fromRGB(30, 40, 58),
    },
    Crimson = {
        Background = Color3.fromRGB(16, 10, 12),
        Panel = Color3.fromRGB(24, 15, 19),
        Element = Color3.fromRGB(30, 20, 25),
        Element2 = Color3.fromRGB(38, 26, 32),
        Surface = Color3.fromRGB(32, 22, 28),
        Inline = Color3.fromRGB(20, 12, 16),
        Accent = Color3.fromRGB(255, 60, 90),
        AccentSoft = Color3.fromRGB(140, 35, 55),
        Text = Color3.fromRGB(245, 235, 238),
        TextMuted = Color3.fromRGB(165, 140, 148),
        Outline = Color3.fromRGB(55, 33, 40),
        OutlineSoft = Color3.fromRGB(42, 26, 32),
    },
    Ghost = {
        Background = Color3.fromRGB(235, 235, 240),
        Panel = Color3.fromRGB(250, 250, 253),
        Element = Color3.fromRGB(255, 255, 255),
        Element2 = Color3.fromRGB(228, 228, 236),
        Surface = Color3.fromRGB(240, 240, 246),
        Inline = Color3.fromRGB(225, 225, 232),
        Accent = Color3.fromRGB(200, 25, 35),
        AccentSoft = Color3.fromRGB(230, 150, 155),
        Text = Color3.fromRGB(20, 20, 25),
        TextMuted = Color3.fromRGB(110, 110, 120),
        Outline = Color3.fromRGB(200, 200, 210),
        OutlineSoft = Color3.fromRGB(215, 215, 222),
    },
}

Library.Folders = {
    Directory = "DWLIBV1",
    Configs = "DWLIBV1/Configs",
}

Library.UIScale = 1
-- Linoria-look style switches. SquareCorners flattens every UICorner (radius
-- 0); off by default so each element's own radius applies. Font routes every
-- widget's text through one face.
Library.SquareCorners = false
Library.Font = Enum.Font.Gotham
Library.FontBold = Enum.Font.GothamBold
-- Custom outline: SetBorder({ Color = Color3, Transparency = 0..1,
-- Thickness = 1..6 }) re-tints/re-sizes every chrome stroke; Color = false
-- reverts to the theme outline. Runtime setting (not config-persisted).
Library.Border = { Color = nil, Transparency = nil, Thickness = nil }
Library._strokeThickness = {}
-- Window frame border: a dedicated stroke around the window itself.
-- SetWindowBorder({ Enabled, Thickness = 1..8, Transparency = 0..1 }).
Library.WindowBorder = { Enabled = true, Thickness = 1, Transparency = 0.05 }
Library._windowBorders = {}

function Library:SetWindowBorder(opts)
    opts = opts or {}
    if self.WindowBorder == nil or type(self.WindowBorder) ~= "table" then
        self.WindowBorder = { Enabled = true, Thickness = 1, Transparency = 0.05 }
    end
    local b = self.WindowBorder
    if opts.Enabled ~= nil then b.Enabled = opts.Enabled and true or false end
    if opts.Thickness ~= nil then
        b.Thickness = math.clamp(math.floor(tonumber(opts.Thickness) or 1), 1, 8)
    end
    if opts.Transparency ~= nil then
        b.Transparency = math.clamp(tonumber(opts.Transparency) or 0, 0, 1)
    end
    self:_applyWindowBorder()
end

function Library:_applyWindowBorder()
    local b = self.WindowBorder
    if type(b) ~= "table" then return end
    local on = b.Enabled ~= false
    for _, s in ipairs(self._windowBorders or {}) do
        pcall(function()
            if s and s.Parent then
                s.Visible = on
                s.Thickness = b.Thickness
                s.Transparency = b.Transparency
            end
        end)
    end
end
-- Default window background. Paste an rbxassetid://... here after uploading
-- the PNG (Creator Dashboard > Asset Manager). Applied to every new window
-- unless overridden per-window or by a loaded config. Linoria look ships
-- clean (no art), so this is nil by default.
Library.DefaultBackgroundImage = nil
Library.DefaultBackgroundTransparency = 0.5
Library.BackgroundImage = nil
Library.BackgroundTransparency = 0.5
Library.AnimationsEnabled = true
Library.TooltipsEnabled = true
Library.NotifDuration = 4

-- Config persistence. Flags listed here are never written by GetConfig
-- and are skipped by LoadConfig. UI-internal flags (__cfg_*, __autosave_*)
-- are ignored by default so a loaded config never clobbers the config UI.
Library.ConfigIgnore = {
    __cfg_name = true,
    __cfg_list = true,
    __cfg_clipboard = true,
    __autosave_enabled = true,
    __autosave_delay = true,
}

-- Debounced auto-save state. Enable via Library:SetAutoSave(name, delay).
Library.AutoSave = {
    Enabled = false,
    Name = nil,
    Delay = 5,
    _lastJson = nil,
    _dirtySince = nil,
    _running = false,
}
