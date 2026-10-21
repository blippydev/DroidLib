-- ============================================================
-- [ module: Header.lua ]
-- ============================================================

-- DWLibV1 - DroidWare UI library v1 (original code, red/black theme)
-- Boot: unload previous copy so re-execution never stacks two windows.
if getgenv and getgenv().DWLib then
    pcall(function() getgenv().DWLib:Unload() end)
end

local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CoreGui = game:GetService("CoreGui")
local function getHolderParent()
    local ok, hui = pcall(gethui)
    if ok and typeof(hui) == "Instance" then
        return hui
    end
    local ok2, hg = pcall(get_hidden_gui)
    if ok2 and typeof(hg) == "Instance" then
        return hg
    end
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer
-- ============================================================
-- [ module: LibraryTable.lua ]
-- ============================================================

Library.Flags = {}
Library._conns = {}
Library._threads = {}
Library._unloadCbs = {}
Library._themeItems = {}
Library._windows = {}
Library.Unloading = false
Library.MenuKey = Enum.KeyCode.RightShift

-- Linoria-look palette: flat dark, thin outlines, blue accent, mono text.
-- Keys mirror Linoria's 5-color scheme (BackgroundColor/MainColor/
-- AccentColor/OutlineColor/FontColor) mapped onto DWLib's 12 keys.
-- Type is Gotham everywhere (mono Code survives only on chips/readouts);
-- corners are real (SquareCorners=false) with per-element radii.
Library.Theme = {
    Background = Color3.fromRGB(20, 20, 20),   -- 0x141414 window bg
    Panel = Color3.fromRGB(10, 10, 10),        -- darker section cards
    Element = Color3.fromRGB(28, 28, 28),      -- 0x1c1c1c MainColor (rows)
    Element2 = Color3.fromRGB(28, 28, 28),     -- 0x1c1c1c controls
    Surface = Color3.fromRGB(24, 24, 24),      -- 0x181818 chips
    Inline = Color3.fromRGB(16, 16, 16),       -- 0x101010 inputs
    Accent = Color3.fromRGB(0, 85, 255),       -- 0x0055ff AccentColor
    AccentSoft = Color3.fromRGB(0, 56, 170),   -- darker accent (v / 1.5)
    Text = Color3.fromRGB(255, 255, 255),      -- FontColor
    TextMuted = Color3.fromRGB(200, 200, 200),
    Outline = Color3.fromRGB(50, 50, 50),      -- 0x323232 OutlineColor
    OutlineSoft = Color3.fromRGB(38, 38, 38),  -- 0x262626
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
-- ============================================================
-- [ module: Utils.lua ]
-- ============================================================

function Library:Connect(event, fn)
    local ok, conn = pcall(event.Connect, event, fn)
    if ok and conn then
        table.insert(self._conns, conn)
        return conn
    end
    return nil
end

function Library:OnUnload(fn)
    if type(fn) == "function" then
        table.insert(self._unloadCbs, fn)
    end
end

function Library:Thread(fn)
    if type(fn) ~= "function" then return nil end
    local t = coroutine.create(fn)
    table.insert(self._threads, t)
    coroutine.wrap(function()
        local ok, err = coroutine.resume(t)
        if not ok then warn(err) end
    end)()
    return t
end

function Library:Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

function Library:Themed(inst, prop, key)
    table.insert(self._themeItems, { inst = inst, prop = prop, key = key })
    pcall(function() inst[prop] = self.Theme[key] end)
    return inst
end

function Library:Corner(parent, r)
    -- Linoria look: flat panels, no rounding. SquareCorners (LibraryTable)
    -- overrides whatever radius the caller asked for.
    if self.SquareCorners then r = 0 end
    return self:Create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, parent)
end

function Library:Stroke(parent, thickness, key)
    local s = self:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = thickness or 1,
    }, parent)
    self:Themed(s, "Color", key or "Outline")
    -- Global outline registry: SetBorder can re-tint/re-size any stroke the
    -- library created, so the "outline the UI" setting stays live.
    table.insert(self._strokeThickness, s)
    return s
end

function Library:Tween(inst, props, time)
    if self.AnimationsEnabled == false then
        pcall(function()
            for k, v in pairs(props or {}) do
                inst[k] = v
            end
        end)
        return
    end
    pcall(function()
        TweenService:Create(inst, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end)
end

function Library:Drag(frame, handle)
    handle = handle or frame
    local dragging = false
    local startPos, startInput
    self:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = frame.Position
            startInput = input.Position
        end
    end)
    self:Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    self:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function Library:Punch(inst, from)
    local ui = self:Create("UIScale", { Scale = from or 0.94 }, inst)
    pcall(function()
        local tw = TweenService:Create(ui,
            TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 })
        tw:Play()
        task.delay(0.25, function() pcall(function() ui:Destroy() end) end)
    end)
end

function Library:NextFlag()
    self._flagN = (self._flagN or 0) + 1
    return "dw_flag_" .. tostring(self._flagN)
end

Library._widgets = {}
Library._appliers = Library._appliers or {}

function Library:TrackWidget(flag, refresh, fire)
    if type(refresh) == "function" then
        self._widgets[flag] = self._widgets[flag] or {}
        table.insert(self._widgets[flag], refresh)
    end
    if type(fire) == "function" then
        self._appliers[flag] = self._appliers[flag] or {}
        table.insert(self._appliers[flag], fire)
    end
end

function Library:ApplyFlags(fireCallbacks)
    for _, list in pairs(self._widgets) do
        for _, fn in ipairs(list) do
            pcall(fn)
        end
    end
    if fireCallbacks then
        for _, list in pairs(self._appliers) do
            for _, fn in ipairs(list) do
                pcall(fn)
            end
        end
    end
    self:_pushKeybindList()
end

function Library:BringToFront(inst)
    if typeof(inst) == "Instance" and inst.Parent then
        local p = inst.Parent
        inst.Parent = nil
        inst.Parent = p
    end
end

function Library:ShowPopup(frame, anchorBtn, opts)
    opts = opts or {}
    self:ClosePopups()
    local ov = self.Overlay
    if not frame or not anchorBtn or not ov or not ov.Parent then return end
    self._openPopup = {
        frame = frame,
        parent = frame.Parent,
        pos = frame.Position,
        size = frame.Size,
    }
    frame.Parent = ov
    local bp = anchorBtn.AbsolutePosition
    local bs = anchorBtn.AbsoluteSize
    local op = ov.AbsolutePosition
    local w = opts.width or frame.Size.X.Offset
    if w <= 0 then w = bs.X end
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local x = bp.X - op.X + (opts.alignRight and (bs.X - w) or 0)
    x = math.clamp(x, 8, math.max(8, vp.X - w - 8))
    local y = bp.Y - op.Y + bs.Y + 4
    frame.Size = UDim2.new(0, w, frame.Size.Y.Scale, frame.Size.Y.Offset)
    frame.Position = UDim2.new(0, math.floor(x), 0, math.floor(y))
    frame.Visible = true
    self:BringToFront(ov)
    ov.Visible = true
    if opts.flip ~= false then
        self:Thread(function()
            task.wait()
            local cur = self._openPopup
            if cur and cur.frame == frame and frame.Visible and frame.Parent == ov then
                local h = frame.AbsoluteSize.Y
                if y + h > vp.Y - 8 then
                    local above = y - h - bs.Y - 8
                    frame.Position = UDim2.new(0, math.floor(x), 0, math.floor(math.max(8, above)))
                end
            end
        end)
    end
end

function Library:ClosePopups()
    local cur = self._openPopup
    self._openPopup = nil
    if cur and cur.frame then
        pcall(function()
            cur.frame.Visible = false
            cur.frame.Position = cur.pos
            cur.frame.Size = cur.size
            cur.frame.Parent = cur.parent
        end)
    end
    if self.Overlay then
        self.Overlay.Visible = false
    end
end
-- ============================================================
-- [ module: Themes.lua ]
-- ============================================================

function Library:ApplyThemePreset(name)
    local p = self.Presets[name]
    if not p then return false end
    for k, v in pairs(p) do
        self.Theme[k] = v
    end
    for _, e in ipairs(self._themeItems) do
        pcall(function()
            if e.inst and e.inst.Parent ~= nil then
                e.inst[e.prop] = self.Theme[e.key]
            end
        end)
    end
    self.Flags.__theme = name
    for k, v in pairs(p) do
        self.Flags["__theme_" .. k] = v
    end
    self:ApplyFlags()
    pcall(function() self:_applyBorder() end)
    pcall(function() self:_applyWindowBorder() end)
    return true
end

function Library:ChangeTheme(key, color)
    if typeof(color) ~= "Color3" then return false end
    self.Theme[key] = color
    for _, e in ipairs(self._themeItems) do
        if e.key == key then
            pcall(function() e.inst[e.prop] = color end)
        end
    end
    -- The outline override outranks the theme tint it tracked from.
    pcall(function() self:_applyBorder() end)
    return true
end

-- Customizable outline. Global override for the chrome strokes (window,
-- groupboxes, chips, inputs). Color=false disables the tint; nil fields are
-- no-ops so partial updates work: SetBorder({ Transparency = 0.4 }).
function Library:SetBorder(cfg)
    cfg = cfg or {}
    self.Border = self.Border or { Color = nil, Transparency = nil, Thickness = nil }
    if cfg.Color ~= nil then
        -- Any Color3 enables the tint; `false` reverts to the theme outline.
        self.Border.Color = typeof(cfg.Color) == "Color3" and cfg.Color or nil
    end
    if cfg.Transparency ~= nil then
        self.Border.Transparency = math.clamp(tonumber(cfg.Transparency) or 0, 0, 1)
    end
    if cfg.Thickness ~= nil then
        self.Border.Thickness = math.clamp(math.floor(tonumber(cfg.Thickness) or 1), 1, 6)
    end
    self:_applyBorder()
end

function Library:_applyBorder()
    local b = self.Border
    if type(b) ~= "table" then return end
    local tint = b.Color
    for _, e in ipairs(self._themeItems or {}) do
        if e.key == "Outline" or e.key == "OutlineSoft" then
            pcall(function()
                if e.inst and e.inst.Parent ~= nil and e.prop == "Color" then
                    e.inst[e.prop] = tint or self.Theme[e.key]
                    if tint and b.Transparency then
                        e.inst.Transparency = b.Transparency
                    elseif not tint then
                        e.inst.Transparency = 0
                    end
                end
            end)
        end
    end
    if b.Thickness then
        for _, s in ipairs(self._strokeThickness or {}) do
            pcall(function()
                if s and s.Parent then s.Thickness = b.Thickness end
            end)
        end
    end
end

local function resolveAsset(input)
    local s = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if s == "" then return nil end
    if s:match("^%d+$") then
        return "rbxassetid://" .. s
    end
    return s
end

function Library:SetBackgroundImage(asset, transparency)
    local tr = math.clamp(tonumber(transparency) or tonumber(self.BackgroundTransparency) or 0.5, 0, 1)
    local img = nil
    if asset ~= nil then
        local s = tostring(asset):gsub("^%s+", ""):gsub("%s+$", "")
        if s == "" then
            img = self.DefaultBackgroundImage
        elseif s:lower() == "none" then
            img = nil
        else
            img = resolveAsset(asset)
        end
    end
    self.BackgroundImage = img
    self.BackgroundTransparency = tr
    local custom = img ~= nil and img ~= self.DefaultBackgroundImage
    for _, w in ipairs(self._windows) do
        local bi = w.Items and w.Items.BgImage
        if bi then
            pcall(function()
                if img then
                    bi.Image = img
                    bi.ImageTransparency = tr
                    bi.Visible = true
                else
                    bi.Visible = false
                    bi.Image = ""
                end
            end)
        end
        local logo, title = w.Items and w.Items.Logo, w.Items and w.Items.Title
        if logo and title then
            pcall(function()
                logo.Visible = custom and true or false
                logo.Image = custom and img or ""
                title.Position = custom and UDim2.new(0, 46, 0, 0) or UDim2.new(0, 14, 0, 0)
                title.Size = custom and UDim2.new(1, -372, 0, 44) or UDim2.new(1, -340, 0, 44)
            end)
        end
    end
end

function Library:SetUIScale(s)
    s = math.clamp(tonumber(s) or 1, 0.5, 2)
    self:ClearUIScalePreview()
    self.UIScale = s
    self.Flags.__uiscale = s
    for _, w in ipairs(self._windows) do
        local root = w.Items and w.Items.Root
        if root then
            local sc = root:FindFirstChild("DWUIScale")
            if not sc then
                sc = Instance.new("UIScale")
                sc.Name = "DWUIScale"
                sc.Parent = root
            end
            sc.Scale = s
        end
    end
end

function Library:ClearUIScalePreview()
    if self._scalePreviews then
        for _, fr in pairs(self._scalePreviews) do
            pcall(function() fr:Destroy() end)
        end
    end
    self._scalePreviews = {}
end

-- Outline-only preview of a scale value. Never touches the real UIScale;
-- commit with SetUIScale on slider release.
function Library:PreviewUIScale(s)
    s = math.clamp(tonumber(s) or 1, 0.5, 2)
    if not self.Holder or not self.Holder.Parent then return end
    self._scalePreviews = self._scalePreviews or {}
    local vp = Vector2.new(1280, 720)
    pcall(function()
        if workspace.CurrentCamera then
            vp = workspace.CurrentCamera.ViewportSize
        end
    end)
    for _, w in ipairs(self._windows) do
        local root = w.Items and w.Items.Root
        if root then
            local fr = self._scalePreviews[w]
            if not fr or not fr.Parent then
                fr = self:Create("Frame", {
                    Name = "DWScalePreview",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 1000,
                }, self.Holder)
                self:Corner(fr, 8)
                local stroke = self:Stroke(fr, 2, "Accent")
                stroke.Transparency = 0
                local tag = self:Create("TextLabel", {
                    Name = "ScaleTag",
                    AnchorPoint = Vector2.new(0.5, 1),
                    Position = UDim2.new(0.5, 0, 0, -26),
                    Size = UDim2.new(0, 76, 0, 20),
                    BackgroundTransparency = 0,
                    Font = Library.Font,
                    TextSize = 12,
                    Text = "",
                }, fr)
                self:Themed(tag, "BackgroundColor3", "Element2")
                self:Themed(tag, "TextColor3", "Text")
                self:Corner(tag, 10)
                self:Stroke(tag, 1, "Outline")
                self._scalePreviews[w] = fr
            end
            local baseW = 980
            local baseH = 600
            pcall(function()
                baseW = root.Size.X.Offset
                baseH = root.Size.Y.Offset
                if baseW <= 0 then baseW = 980 end
                if baseH <= 0 then baseH = 600 end
            end)
            local tw = math.floor(baseW * s + 0.5)
            local th = math.floor(baseH * s + 0.5)
            -- UIScale grows Size from a fixed top-left: AbsolutePosition does
            -- not move when the scale changes, so anchor the outline there.
            -- (Centering on the current middle drifts whenever the window was
            -- dragged, and it is wrong even for a centered window.)
            -- NOTE: Holder-space offsets != screen pixels. The ScreenGui sits
            -- at a negative Y (topbar inset), so convert via Holder's own
            -- AbsolutePosition instead of copying AbsolutePosition raw.
            local px, py = nil, nil
            pcall(function()
                if root.Visible and root.AbsoluteSize.X > 0 then
                    local hx, hy = 0, 0
                    if self.Holder then
                        hx = self.Holder.AbsolutePosition.X
                        hy = self.Holder.AbsolutePosition.Y
                    end
                    px = math.floor(root.AbsolutePosition.X - hx + 0.5)
                    py = math.floor(root.AbsolutePosition.Y - hy + 0.5)
                end
            end)
            if px == nil then
                px = math.floor((vp.X - tw) / 2 + 0.5)
                py = math.floor((vp.Y - th) / 2 + 0.5)
            end
            pcall(function()
                fr.Size = UDim2.new(0, tw, 0, th)
                fr.Position = UDim2.new(0, px, 0, py)
                local tag = fr:FindFirstChild("ScaleTag")
                if tag then tag.Text = string.format("%.2fx", s) end
                fr.Visible = true
                self:BringToFront(fr)
            end)
        end
    end
end
-- ============================================================
-- [ module: Icons.lua ]
-- ============================================================

-- DWLibV1 vendored lucide tab icons (subset).
-- Source icons: Footagesus/Icons lucide pack (Lucide is MIT).
-- Full upstream set has 1500+ names; add more lines here as needed.
-- Thesetint white at runtime via ImageColor3, so they follow the theme.

Library.IconMap = Library.IconMap or {}
do
	Library.IconMap["activity"] = "rbxassetid://94212016861936"
	Library.IconMap["anchor"] = "rbxassetid://92181172123618"
	Library.IconMap["axe"] = "rbxassetid://132405197863294"
	Library.IconMap["backpack"] = "rbxassetid://140420225386018"
	Library.IconMap["bell"] = "rbxassetid://97392696311902"
	Library.IconMap["bike"] = "rbxassetid://102930322246035"
	Library.IconMap["bomb"] = "rbxassetid://139223800924636"
	Library.IconMap["box"] = "rbxassetid://101768155599700"
	Library.IconMap["bug"] = "rbxassetid://83626408925438"
	Library.IconMap["camera"] = "rbxassetid://79950339943067"
	Library.IconMap["car"] = "rbxassetid://121065933462582"
	Library.IconMap["check"] = "rbxassetid://93898873302694"
	Library.IconMap["chevron-down"] = "rbxassetid://134243273101015"
	Library.IconMap["chevron-right"] = "rbxassetid://92473583511724"
	Library.IconMap["coffee"] = "rbxassetid://106864403231093"
	Library.IconMap["compass"] = "rbxassetid://115123411028382"
	Library.IconMap["crosshair"] = "rbxassetid://134242818164054"
	Library.IconMap["crown"] = "rbxassetid://127843403295538"
	Library.IconMap["dices"] = "rbxassetid://81268120302865"
	Library.IconMap["door-open"] = "rbxassetid://91306356501736"
	Library.IconMap["drone"] = "rbxassetid://117299095794783"
	Library.IconMap["eye"] = "rbxassetid://100033680381365"
	Library.IconMap["film"] = "rbxassetid://120978945609706"
	Library.IconMap["fish"] = "rbxassetid://124360663785796"
	Library.IconMap["flag"] = "rbxassetid://78183383236196"
	Library.IconMap["flame"] = "rbxassetid://98218034436456"
	Library.IconMap["fuel"] = "rbxassetid://106447647274511"
	Library.IconMap["gamepad-2"] = "rbxassetid://92483947987410"
	Library.IconMap["gauge"] = "rbxassetid://110273524101447"
	Library.IconMap["gem"] = "rbxassetid://112904952151156"
	Library.IconMap["ghost"] = "rbxassetid://113822048130017"
	Library.IconMap["gift"] = "rbxassetid://109855212076373"
	Library.IconMap["globe"] = "rbxassetid://114238209622913"
	Library.IconMap["hammer"] = "rbxassetid://83545120140895"
	Library.IconMap["headphones"] = "rbxassetid://118833729589183"
	Library.IconMap["hourglass"] = "rbxassetid://86160434939203"
	Library.IconMap["house"] = "rbxassetid://98755624629571"
	Library.IconMap["info"] = "rbxassetid://124560466474914"
	Library.IconMap["key"] = "rbxassetid://96510194465420"
	Library.IconMap["keyboard"] = "rbxassetid://121474456068237"
	Library.IconMap["layers"] = "rbxassetid://81973586053257"
	Library.IconMap["lightbulb"] = "rbxassetid://103871245626488"
	Library.IconMap["lock"] = "rbxassetid://134724289526879"
	Library.IconMap["map"] = "rbxassetid://95107167260947"
	Library.IconMap["menu"] = "rbxassetid://77021539815611"
	Library.IconMap["monitor"] = "rbxassetid://72664649203050"
	Library.IconMap["mountain"] = "rbxassetid://73269957566415"
	Library.IconMap["move"] = "rbxassetid://116138709011735"
	Library.IconMap["music"] = "rbxassetid://113343203848535"
	Library.IconMap["package"] = "rbxassetid://97261141732706"
	Library.IconMap["palette"] = "rbxassetid://86350350950064"
	Library.IconMap["pickaxe"] = "rbxassetid://105888023317688"
	Library.IconMap["plane"] = "rbxassetid://126985561580989"
	Library.IconMap["play"] = "rbxassetid://135609604299893"
	Library.IconMap["plus"] = "rbxassetid://111774323017047"
	Library.IconMap["printer"] = "rbxassetid://76080649734247"
	Library.IconMap["puzzle"] = "rbxassetid://136837798892463"
	Library.IconMap["radar"] = "rbxassetid://138528222906635"
	Library.IconMap["radio"] = "rbxassetid://85611589536956"
	Library.IconMap["refresh-ccw"] = "rbxassetid://117913330389477"
	Library.IconMap["rocket"] = "rbxassetid://87412317685854"
	Library.IconMap["sailboat"] = "rbxassetid://87110567187540"
	Library.IconMap["satellite"] = "rbxassetid://134967053164645"
	Library.IconMap["save"] = "rbxassetid://126116963775616"
	Library.IconMap["search"] = "rbxassetid://121018724060431"
	Library.IconMap["server"] = "rbxassetid://92188766517878"
	Library.IconMap["settings"] = "rbxassetid://80758916183665"
	Library.IconMap["shield"] = "rbxassetid://110987169760162"
	Library.IconMap["ship"] = "rbxassetid://83995100553930"
	Library.IconMap["shovel"] = "rbxassetid://102465000512056"
	Library.IconMap["siren"] = "rbxassetid://134210267818039"
	Library.IconMap["skull"] = "rbxassetid://137726256442333"
	Library.IconMap["sliders-horizontal"] = "rbxassetid://85538382643347"
	Library.IconMap["smartphone"] = "rbxassetid://96623008834511"
	Library.IconMap["sparkles"] = "rbxassetid://138635884129147"
	Library.IconMap["sword"] = "rbxassetid://124448418211665"
	Library.IconMap["swords"] = "rbxassetid://81872698913435"
	Library.IconMap["target"] = "rbxassetid://87563802520297"
	Library.IconMap["tent"] = "rbxassetid://109779587826330"
	Library.IconMap["tent-tree"] = "rbxassetid://76698322463977"
	Library.IconMap["timer"] = "rbxassetid://85473888890506"
	Library.IconMap["traffic-cone"] = "rbxassetid://74110220470369"
	Library.IconMap["trash-2"] = "rbxassetid://109843431391323"
	Library.IconMap["trophy"] = "rbxassetid://131545003268773"
	Library.IconMap["tv"] = "rbxassetid://135687724791776"
	Library.IconMap["user"] = "rbxassetid://81589895647169"
	Library.IconMap["users"] = "rbxassetid://115398113982385"
	Library.IconMap["wallet"] = "rbxassetid://132331555762628"
	Library.IconMap["waves"] = "rbxassetid://96340135183647"
	Library.IconMap["wifi"] = "rbxassetid://104669375183960"
	Library.IconMap["wrench"] = "rbxassetid://112148279212860"
	Library.IconMap["x"] = "rbxassetid://110786993356448"
	Library.IconMap["zap"] = "rbxassetid://130551565616516"
end

function Library:GetIcon(name)
	if name == nil then return nil end
	local s = tostring(name):gsub("^%s+", ""):gsub("%s+$", ""):lower()
	if s == "" then return nil end
	if s:match("^rbxassetid://%d+$") then return s end
	if s:match("^%d+$") then return "rbxassetid://" .. s end
	return self.IconMap[s]
end
-- ============================================================
-- [ module: Holders.lua ]
-- ============================================================

do
    local parent = getHolderParent()
    local gui = parent:FindFirstChild("DWLibV1")
    if gui then pcall(function() gui:Destroy() end) end
    gui = Instance.new("ScreenGui")
    gui.Name = "DWLibV1"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent
    Library.Holder = gui

    -- Sweep stale copies left by earlier executions. Some executors isolate
    -- getgenv per execution, so the Header unload above cannot see them, and
    -- each run would otherwise stack a fully live second window (double
    -- callbacks on every keypress). The name is unique enough to sweep by.
    pcall(function()
        for _, root in ipairs({ game:GetService("CoreGui"), LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") }) do
            if typeof(root) == "Instance" then
                for _, d in ipairs(root:GetDescendants()) do
                    if d ~= gui and d.Name == "DWLibV1" and d:IsA("ScreenGui") then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
        end
    end)

    local notifs = Instance.new("Frame")
    notifs.Name = "Notifs"
    notifs.BackgroundTransparency = 1
    notifs.AnchorPoint = Vector2.new(1, 1)
    notifs.Position = UDim2.new(1, -16, 1, -16)
    notifs.Size = UDim2.new(0, 340, 0, 480)
    notifs.Parent = gui
    local nl = Instance.new("UIListLayout")
    nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    nl.Padding = UDim.new(0, 8)
    nl.SortOrder = Enum.SortOrder.LayoutOrder
    nl.Parent = notifs
    Library.NotifHolder = notifs

    -- Top layer for dropdown / colorpicker popups. Popups live here instead
    -- of inside section rows so ClipsDescendants and sibling overlap can
    -- never cut them off or bury them.
    local overlay = Instance.new("Frame")
    overlay.Name = "DWOverlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Visible = false
    overlay.Parent = gui
    Library.Overlay = overlay

    local catcher = Instance.new("TextButton")
    catcher.Name = "Catcher"
    catcher.BackgroundTransparency = 1
    catcher.Size = UDim2.new(1, 0, 1, 0)
    catcher.AutoButtonColor = false
    catcher.Text = ""
    catcher.Parent = overlay
    Library:Connect(catcher.MouseButton1Click, function()
        Library:ClosePopups()
    end)
end

function Library:Unload()
    if self.Unloading then return end
    self.Unloading = true
    for _, fn in ipairs(self._unloadCbs) do
        pcall(fn)
    end
    self._unloadCbs = {}
    for _, c in ipairs(self._conns) do
        pcall(function() c:Disconnect() end)
    end
    self._conns = {}
    pcall(function() self.Holder:Destroy() end)
    if getgenv and getgenv().DWLib == self then
        getgenv().DWLib = nil
    end
end
-- ============================================================
-- [ module: Watermark.lua ]
-- ============================================================

function Library:Watermark(data)
    data = data or {}
    local base = tostring(data.Text or data.Name or "DWLib")
    local showStats = data.Stats ~= false
    local rate = math.clamp(tonumber(data.RefreshRate) or 1, 0.5, 10)

    local executor = "Unknown"
    pcall(function()
        if identifyexecutor then executor = tostring(identifyexecutor())
        elseif getexecutorname then executor = tostring(getexecutorname()) end
    end)

    local frame = self:Create("Frame", {
        Name = "Watermark",
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(0, 0, 0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.35,
    }, self.Holder)
    self:Corner(frame, 6)
    local label = self:Create("TextLabel", {
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = base,
    }, frame)
    self:Themed(label, "TextColor3", "Text")
    local pad = self:Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, frame)
    self:Drag(frame)

    local wm = { BaseText = base, ShowStats = showStats, _scale = 1 }
    local frames, lastFps, lastPing, lastTick = 0, 0, nil, tick()

    local function render()
        local text = wm.BaseText
        if wm.ShowStats then
            text = text .. "  |  " .. executor
                .. "  |  " .. (lastPing and (tostring(lastPing) .. " ms") or "--")
                .. "  |  " .. tostring(lastFps) .. " FPS"
        end
        if label.Parent then label.Text = text end
    end

    function wm:SetText(t)
        wm.BaseText = tostring(t or "")
        render()
    end
    function wm:SetStatsEnabled(v)
        wm.ShowStats = v and true or false
        render()
    end
    function wm:SetVisibility(v)
        frame.Visible = v and true or false
    end
    function wm:SetCenter()
        frame.Position = UDim2.new(0, 12, 0, 8)
    end
    function wm:SetScale(s)
        s = tonumber(s)
        if not (s and s > 0) then return wm end
        wm._scale = math.clamp(s, 0.5, 3)
        frame.Size = UDim2.new(0, 0, 0, math.max(18, math.floor(26 * wm._scale + 0.5)))
        label.TextSize = math.max(9, math.floor(12 * wm._scale + 0.5))
        local px = math.max(6, math.floor(10 * wm._scale + 0.5))
        pad.PaddingLeft = UDim.new(0, px)
        pad.PaddingRight = UDim.new(0, px)
        return wm
    end
    function wm:GetScale() return wm._scale end

    self:Connect(RunService.RenderStepped, function()
        frames = frames + 1
    end)
    self:Thread(function()
        while not self.Unloading do
            task.wait(rate)
            if self.Unloading then break end
            local now = tick()
            lastFps = math.floor(frames / math.max(0.01, now - lastTick) + 0.5)
            frames, lastTick = 0, now
            pcall(function()
                lastPing = math.floor(LocalPlayer:GetNetworkPing() * 1000 + 0.5)
            end)
            render()
        end
    end)
    wm:SetScale(data.Scale)
    render()
    return wm
end
-- ============================================================
-- [ module: Tooltip.lua ]
-- ============================================================

Library.TooltipMaxWidth = 260

function Library:EnsureTooltip()
    if self._tooltip and self._tooltip.Parent then
        return self._tooltip
    end
    local card = self:Create("TextButton", {
        Name = "DWTooltip",
        Size = UDim2.new(0, 100, 0, 26),
        AutoButtonColor = false,
        Active = false,
        Visible = false,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 500,
    }, self.Holder)
    self:Themed(card, "BackgroundColor3", "Element2")
    self:Corner(card, 8)
    self:Stroke(card, 1)
    local label = self:Create("TextLabel", {
        Size = UDim2.new(1, -16, 1, -10),
        Position = UDim2.new(0, 8, 0, 5),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        Text = "",
    }, card)
    self:Themed(label, "TextColor3", "Text")
    self._tooltip = card
    self._tooltipLabel = label
    return card
end

function Library:AttachTooltip(inst, text)
    if self.TooltipsEnabled == false then return end
    if typeof(inst) ~= "Instance" then return end
    text = tostring(text or "")
    if text == "" then return end
    self:EnsureTooltip()
    self:Connect(inst.MouseEnter, function()
        local card, label = self._tooltip, self._tooltipLabel
        if not card or not card.Parent then return end
        self:BringToFront(card)
        label.Text = text
        local bounds = label.TextBounds
        local w = math.clamp(bounds.X + 20, 40, self.TooltipMaxWidth)
        local h = math.max(26, bounds.Y + 14)
        card.Size = UDim2.new(0, w, 0, h)
        card.Visible = true
    end)
    self:Connect(inst.MouseLeave, function()
        if self._tooltip then self._tooltip.Visible = false end
    end)
    self:Connect(UserInputService.InputChanged, function(input)
        local card = self._tooltip
        if card and card.Visible and input.UserInputType == Enum.UserInputType.MouseMovement then
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            local x = math.clamp(input.Position.X + 14, 0, math.max(0, vp.X - card.AbsoluteSize.X))
            local y = math.clamp(input.Position.Y + 16, 0, math.max(0, vp.Y - card.AbsoluteSize.Y))
            card.Position = UDim2.new(0, x, 0, y)
        end
    end)
end
-- ============================================================
-- [ module: Window.lua ]
-- ============================================================

Library.Pages = {}
Library.Pages.__index = Library.Pages
Library.Sections = {}
Library.Sections.__index = Library.Sections

local WIN_W, WIN_H = 560, 620

function Library:Window(data)
    data = data or {}
    local window = {
        Name = data.Name or "DWLib",
        SubName = data.SubName or "",
        IsOpen = true,
        Pages = {},
        _maxed = false,
    }

    local root = self:Create("Frame", {
        Name = "Main",
        Size = UDim2.new(0, WIN_W, 0, WIN_H),
        Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
        BorderSizePixel = 0,
    }, self.Holder)
    self:Themed(root, "BackgroundColor3", "Background")
    self:Corner(root, 8)

    -- Dedicated window border: its own frame + stroke so it can grow to any
    -- thickness (the UIStroke sits outside the content and follows resize /
    -- maximize for free). Driven by the WindowBorder theme key + settings
    -- (Library.WindowBorder / :SetWindowBorder). Deliberately NOT in the
    -- _strokeThickness registry, so the chrome-outline setting can't touch it.
    local border = self:Create("Frame", {
        Name = "WindowBorder",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }, root)
    self:Corner(border, 8)
    local borderStroke = self:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = (self.WindowBorder and self.WindowBorder.Thickness) or 1,
        Transparency = (self.WindowBorder and self.WindowBorder.Transparency) or 0.05,
    }, border)
    self:Themed(borderStroke, "Color", "WindowBorder")
    table.insert(self._windowBorders, borderStroke)

    -- Background image sits behind everything (first child) and never
    -- intercepts clicks.
    local bgImage = self:Create("ImageLabel", {
        Name = "BgImage",
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Active = false,
        Visible = false,
        ScaleType = Enum.ScaleType.Crop,
        Image = "",
        ImageTransparency = 0.5,
    }, root)
    self:Corner(bgImage, 8)

    -- Slim top bar: title left, search + window buttons right.
    local top = self:Create("Frame", {
        Name = "Top",
        Size = UDim2.new(1, 0, 0, 30),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
    }, root)
    -- Custom-background thumbnail: only visible while the active background
    -- is not the default (cleared counts as default-hidden: nothing to show).
    local logo = self:Create("ImageLabel", {
        Name = "BgLogo",
        Position = UDim2.new(0, 8, 0, 4),
        Size = UDim2.new(0, 22, 0, 22),
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Visible = false,
        ScaleType = Enum.ScaleType.Crop,
        Image = "",
    }, top)
    self:Corner(logo, 5)
    self:Stroke(logo, 1, "OutlineSoft")
    local title = self:Create("TextLabel", {
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -260, 0, 30),
        Font = Library.FontBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(window.Name),
    }, top)
    self:Themed(title, "TextColor3", "Text")

    local search = self:Create("TextBox", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -108, 0, 4),
        Size = UDim2.new(0, 140, 0, 22),
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        PlaceholderText = "Search...",
        Text = "",
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
    }, top)
    self:Themed(search, "BackgroundColor3", "Inline")
    self:Themed(search, "TextColor3", "Text")
    self:Corner(search, 6)
    local searchStroke = self:Stroke(search, 1)
    self:Connect(search.Focused, function()
        Library:Tween(searchStroke, { Color = Library.Theme.Accent }, 0.15)
    end)
    self:Connect(search.FocusLost, function()
        Library:Tween(searchStroke, { Color = Library.Theme.Outline }, 0.15)
    end)
    self:Create("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }, search)

    -- Window control squares: boxed like the tabs, state-colored borders.
    -- Minimize stays neutral, maximize glows accent, close flips to the
    -- risk red on hover (destructive affordance).
    local function winBtn(text, xOff, danger)
        local dangerColor = Library.Theme.RiskColor or Color3.fromRGB(255, 50, 50)
        local b = self:Create("TextButton", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, xOff, 0, 4),
            Size = UDim2.new(0, 22, 0, 22),
            AutoButtonColor = false,
            BackgroundTransparency = 0,
            Font = Library.Font,
            TextSize = 12,
            Text = text,
            BorderSizePixel = 0,
        }, top)
        self:Themed(b, "BackgroundColor3", "Panel")
        self:Themed(b, "TextColor3", "TextMuted")
        self:Corner(b, 4)
        local stroke = self:Stroke(b, 1, "OutlineSoft")
        Library:Connect(b.MouseEnter, function()
            Library:Tween(b, { BackgroundColor3 = Library.Theme.Element2 }, 0.12)
            Library:Tween(stroke, { Color = danger and dangerColor or Library.Theme.Accent }, 0.12)
            Library:Tween(b, { TextColor3 = danger and dangerColor or Library.Theme.Text }, 0.12)
        end)
        Library:Connect(b.MouseLeave, function()
            Library:Tween(b, { BackgroundColor3 = Library.Theme.Panel }, 0.12)
            Library:Tween(stroke, { Color = Library.Theme.OutlineSoft }, 0.12)
            Library:Tween(b, { TextColor3 = Library.Theme.TextMuted }, 0.12)
        end)
        return b
    end
    local btnMin = winBtn("-", -76)
    local btnMax = winBtn("+", -44)
    local btnX = winBtn("X", -12, true)

    -- Environment pill: boxed chip with a state dot. DEVMODE glows accent
    -- (dot + text), PRODUCTION stays muted, hidden unless the script passes
    -- DevMode = true/false to CreateWindow.
    local envPill = self:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -296, 0, 5),
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        BorderSizePixel = 0,
        Visible = false,
    }, top)
    self:Themed(envPill, "BackgroundColor3", "Panel")
    self:Stroke(envPill, 1, "OutlineSoft")
    do
        self:Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Center,
        }, envPill)
        self:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
        }, envPill)
    end
    local envDot = self:Create("Frame", {
        Size = UDim2.new(0, 6, 0, 6),
        LayoutOrder = 1,
        BorderSizePixel = 0,
    }, envPill)
    self:Themed(envDot, "BackgroundColor3", "TextMuted")
    local envLbl = self:Create("TextLabel", {
        Size = UDim2.new(0, 0, 0, 12),
        AutomaticSize = Enum.AutomaticSize.X,
        LayoutOrder = 2,
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 11,
        Text = "",
    }, envPill)
    self:Themed(envLbl, "TextColor3", "TextMuted")
    self:Connect(btnMin.MouseButton1Click, function()
        Library:Punch(btnMin, 0.88)
        window:SetOpen(false)
    end)
    self:Connect(btnX.MouseButton1Click, function()
        Library:Punch(btnX, 0.88)
        Library:Dialog({
            Title = "Unload interface?",
            Text = "This closes the window and unloads DWLib.",
            Buttons = {
                { Text = "Unload", Accent = true, Callback = function() Library:Unload() end },
                { Text = "Cancel" },
            },
        })
    end)
    self:Connect(btnMax.MouseButton1Click, function()
        Library:Punch(btnMax, 0.88)
        -- Glyph mirrors state: square = restore, diamonds = maximize.
        btnMax.Text = window._maxed and "s" or "+"
        window:ToggleMaximize()
    end)

    local accentBar = self:Create("Frame", {
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 0, 30),
        BorderSizePixel = 0,
    }, root)
    self:Themed(accentBar, "BackgroundColor3", "Outline")

    -- Sub-tab pill bar: flat strip under the tab strip, visible only when
    -- the active tab has subs (Linoria-look: same chrome, one row lower).
    local substrip = self:Create("Frame", {
        Name = "SubTabs",
        Position = UDim2.new(0, 8, 0, 64),
        Size = UDim2.new(1, -16, 0, 24),
        BorderSizePixel = 0,
        Visible = false,
    }, root)
    self:Themed(substrip, "BackgroundColor3", "Panel")
    self:Corner(substrip, 0)
    self:Stroke(substrip, 1, "OutlineSoft")
    self:Create("UIPadding", {
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
    }, substrip)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, substrip)

    -- Thin divider separating the sub-tab bar from the content below.
    local subdiv = self:Create("Frame", {
        Name = "SubDiv",
        Size = UDim2.new(1, -24, 0, 1),
        Position = UDim2.new(0, 12, 0, 92),
        BorderSizePixel = 0,
        Visible = false,
    }, root)
    self:Themed(subdiv, "BackgroundColor3", "OutlineSoft")

    -- Linoria-look navigation: horizontal top tab strip under the title bar
    -- instead of a left sidebar. Tabs auto-width to their label.
    local side = self:Create("ScrollingFrame", {
        Name = "Side",
        Position = UDim2.new(0, 8, 0, 34),
        Size = UDim2.new(1, -16, 0, 26),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageTransparency = 0.4,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        ScrollingDirection = Enum.ScrollingDirection.X,
    }, root)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    }, side)
    self:Create("UIPadding", { PaddingRight = UDim.new(0, 6) }, side)

    local body = self:Create("Frame", {
        Name = "Body",
        Position = UDim2.new(0, 8, 0, 66),
        Size = UDim2.new(1, -16, 1, -74),
        BackgroundTransparency = 1,
    }, root)

    window.Items = { Root = root, Strip = side, SubStrip = substrip, SubDiv = subdiv, Body = body, Search = search, BgImage = bgImage, Logo = logo, Title = title, EnvPill = envPill, EnvDot = envDot, EnvLabel = envLbl }
    self:Drag(root, top)

    -- Moves the body below the sub-tab bar when subs are shown, pulls it
    -- back up when hidden. Keeps a clear gap either way.
    function window:_layoutSubs(hasSubs)
        if hasSubs then
            substrip.Visible = true
            subdiv.Visible = true
            body.Position = UDim2.new(0, 8, 0, 96)
            body.Size = UDim2.new(1, -16, 1, -104)
        else
            substrip.Visible = false
            subdiv.Visible = false
            body.Position = UDim2.new(0, 8, 0, 66)
            body.Size = UDim2.new(1, -16, 1, -74)
        end
    end

    function window:SetOpen(open)
        open = open and true or false
        if open == window.IsOpen and root.Visible == open then return end
        window.IsOpen = open
        if open then
            root.Visible = true
            Library:Punch(root, 0.96)
        else
            local ui = Library:Create("UIScale", { Scale = 1 }, root)
            pcall(function()
                local tw = TweenService:Create(ui,
                    TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                    { Scale = 0.96 })
                tw:Play()
                tw.Completed:Wait()
            end)
            pcall(function() ui:Destroy() end)
            if not window.IsOpen then
                root.Visible = false
            end
        end
    end

    function window:SetCenter()
        root.Position = UDim2.new(0.5, -root.AbsoluteSize.X / 2, 0.5, -root.AbsoluteSize.Y / 2)
    end

    -- Environment badge. true -> accent DEVMODE chip, false -> quiet muted
    -- PRODUCTION chip, nil -> hidden (title takes the full width back).
    function window:SetEnvPill(dev)
        local title = window.Items and window.Items.Title
        local pill = window.Items and window.Items.EnvPill
        local dot = window.Items and window.Items.EnvDot
        local lbl = window.Items and window.Items.EnvLabel
        if not pill or not dot or not lbl then return end
        if dev == nil then
            pill.Visible = false
            if title then title.Size = UDim2.new(1, -260, 0, 30) end
            return
        end
        if dev then
            lbl.Text = "DEVMODE"
            Library:Themed(lbl, "TextColor3", "Accent")
            Library:Themed(dot, "BackgroundColor3", "Accent")
        else
            lbl.Text = "PRODUCTION"
            Library:Themed(lbl, "TextColor3", "TextMuted")
            Library:Themed(dot, "BackgroundColor3", "TextMuted")
        end
        pill.Visible = true
        if title then title.Size = UDim2.new(1, -320, 0, 30) end
    end

    function window:ToggleMaximize()
        window._maxed = not window._maxed
        if window._maxed then
            window._prevSize = root.Size
            window._prevPos = root.Position
            Library:Tween(root, {
                Size = UDim2.new(0, 700, 0, 820),
                Position = UDim2.new(0.5, -350, 0.5, -410),
            }, 0.25)
        elseif window._prevSize then
            Library:Tween(root, { Size = window._prevSize, Position = window._prevPos }, 0.25)
        end
    end

    function window:SetMaximized(v)
        if (v and true or false) ~= window._maxed then
            window:ToggleMaximize()
        end
    end

    function window:SelectFirst()
        for _, p in ipairs(window.Pages) do
            if p.Level == 1 then
                p:Select()
                return
            end
        end
        if window.Pages[1] then window.Pages[1]:Select() end
    end

    function window:Search(text)
        text = string.lower(tostring(text or ""))
        for _, page in ipairs(window.Pages) do
            for _, sec in ipairs(page.Sections) do
                local anyVisible = false
                for _, row in ipairs(sec.Items.List:GetChildren()) do
                    if row:IsA("GuiObject") then
                        local show = true
                        if text ~= "" then
                            show = false
                            for _, d in ipairs(row:GetDescendants()) do
                                if (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox"))
                                    and string.find(string.lower(d.Text or ""), text, 1, true) then
                                    show = true
                                    break
                                end
                            end
                        end
                        row.Visible = show
                        if show then anyVisible = true end
                    end
                end
                sec.Items.Box.Visible = anyVisible or (text == "")
            end
        end
    end

    -- Soft drop shadow: a dark plate riding behind the window, synced to
    -- every move/resize so the window floats above the game.
    local shadow = self:Create("Frame", {
        Name = "WindowShadow",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
        ZIndex = 0,
        Active = false,
    }, self.Holder)
    self:Corner(shadow, 14)
    local function syncShadow()
        pcall(function()
            shadow.Position = UDim2.new(root.Position.X.Scale, root.Position.X.Offset - 7, root.Position.Y.Scale, root.Position.Y.Offset + 5)
            shadow.Size = UDim2.new(root.Size.X.Scale, root.Size.X.Offset + 14, root.Size.Y.Scale, root.Size.Y.Offset + 14)
        end)
    end
    syncShadow()
    self:Connect(root:GetPropertyChangedSignal("Position"), syncShadow)
    self:Connect(root:GetPropertyChangedSignal("Size"), syncShadow)

    -- Loading card.
    local overlay = self:Create("Frame", {
        Name = "Loading",
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.35,
        BackgroundColor3 = Color3.new(0, 0, 0),
        ZIndex = 200,
    }, root)
    local lcard = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 240, 0, 140),
        BorderSizePixel = 0,
    }, overlay)
    self:Themed(lcard, "BackgroundColor3", "Background")
    self:Corner(lcard, 10)
    self:Stroke(lcard, 1)

    local llogo = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 14),
        Size = UDim2.new(0, 32, 0, 32),
        BorderSizePixel = 0,
    }, lcard)
    self:Themed(llogo, "BackgroundColor3", "Element2")
    self:Corner(llogo, 16)
    local llogoT = self:Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 18,
        Text = string.sub(tostring(window.Name), 1, 1):upper(),
    }, llogo)
    self:Themed(llogoT, "TextColor3", "Accent")

    local ltitle = self:Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 52),
        Size = UDim2.new(0, 200, 0, 20),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 13,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(window.Name),
    }, lcard)
    self:Themed(ltitle, "TextColor3", "Text")

    local track = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 78),
        Size = UDim2.new(0, 180, 0, 4),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    }, lcard)
    self:Corner(track, 2)
    local fill = self:Create("Frame", {
        Size = UDim2.new(0, 50, 1, 0),
        BorderSizePixel = 0,
    }, track)
    self:Themed(fill, "BackgroundColor3", "Accent")
    self:Corner(fill, 2)

    local lstatus = self:Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 90),
        Size = UDim2.new(0, 210, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 10,
        Text = "preparing the interface.",
    }, lcard)
    self:Themed(lstatus, "TextColor3", "TextMuted")

    window.IsLoading = true
    window.Items.Loading = overlay

    Library:Thread(function()
        while window.IsLoading and overlay.Parent do
            local tw = TweenService:Create(fill,
                TweenInfo.new(0.9, Enum.EasingStyle.Linear),
                { Position = UDim2.new(1, -50, 0, 0) })
            tw:Play()
            tw.Completed:Wait()
            if not window.IsLoading or not overlay.Parent then break end
            fill.Position = UDim2.new(0, 0, 0, 0)
        end
    end)

    function window:SetLoadingStatus(text)
        if lstatus.Parent then
            lstatus.Text = tostring(text or "")
        end
    end

    function window:HideLoading()
        if not window.IsLoading then return end
        window.IsLoading = false
        local ov = window.Items.Loading
        if not ov or not ov.Parent then return end
        pcall(function()
            local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
            TweenService:Create(ov, info, { BackgroundTransparency = 1 }):Play()
            for _, d in ipairs(ov:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    TweenService:Create(d, info, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
                elseif d:IsA("GuiObject") then
                    TweenService:Create(d, info, { BackgroundTransparency = 1 }):Play()
                elseif d:IsA("UIStroke") then
                    TweenService:Create(d, info, { Transparency = 1 }):Play()
                end
            end
        end)
        task.delay(0.35, function() pcall(function() ov:Destroy() end) end)
    end

    task.delay(4, function()
        if window.IsLoading then window:HideLoading() end
    end)

    -- Apply the library background state to new windows too (previously only
    -- LoadConfig did this, so windows built after a load lost the image).
    -- Per-window opt wins, then current state, then the shipped default.
    table.insert(self._windows, window)
    if data.BackgroundImage ~= nil then
        self:SetBackgroundImage(data.BackgroundImage, data.BackgroundTransparency)
    elseif self.BackgroundImage then
        self:SetBackgroundImage(self.BackgroundImage, self.BackgroundTransparency)
    elseif self.DefaultBackgroundImage then
        self:SetBackgroundImage(self.DefaultBackgroundImage, self.DefaultBackgroundTransparency)
    end
    return setmetatable(window, self)
end
-- ============================================================
-- [ module: Page.lua ]
-- ============================================================

function Library:Page(window, data, level, parentTab)
    data = data or {}
    local page = {
        Window = window,
        Name = data.Name or "Tab",
        Sections = {},
        SubTabs = {},
        Level = level == 2 and 2 or 1,
        ParentTab = parentTab,
        -- System pages (Home / Settings) are exempt from the sub-tab-only rule.
        IsSystem = data.IsSystem == true,
        _allowSections = data.AllowSections == true or data.IsSystem == true,
    }
    local strip = (page.Level == 2) and window.Items.SubStrip or window.Items.Strip
    local idx = #window.Pages + 1
    local isSub = page.Level == 2

    -- Measured in the live tab font (GothamBold): measuring in mono Code
    -- undershoots bold advances and truncates names ("Ho...").
    local function labelTextWidth(text)
        local ok, size = pcall(function()
            local ts = game:GetService("TextService")
            return ts:GetTextSize(tostring(text), 13, Library.FontBold, Vector2.new(10000, 100)).X
        end)
        if ok and type(size) == "number" and size > 0 then return size end
        return #tostring(text) * 9
    end

    local btn = self:Create("TextButton", {
        Size = isSub and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 90, 0, 22),
        AutomaticSize = Enum.AutomaticSize.X,
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        BackgroundTransparency = isSub and 0 or 1,
        LayoutOrder = idx,
    }, strip)
    self:Corner(btn, 4)
    local nameLbl
    local subStroke = nil
    local subEdge = nil
    local tabIcon = nil
    local tabStroke = nil
    if isSub then
        self:Themed(btn, "BackgroundColor3", "Surface")
        btn.Font = Library.Font
        btn.TextSize = 12
        btn.Text = tostring(page.Name)
        self:Themed(btn, "TextColor3", "TextMuted")
        self:Create("UIPadding", {
            PaddingLeft = UDim.new(0, 12),
            PaddingRight = UDim.new(0, 12),
        }, btn)
        subStroke = self:Stroke(btn, 1, "Outline")
        -- Active-state accent underline: same language as the top tabs, so
        -- sub-tab boxes read as a smaller tier of the same control.
        subEdge = self:Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -1),
            Size = UDim2.new(1, -8, 0, 2),
            BorderSizePixel = 0,
            Visible = false,
        }, btn)
        self:Themed(subEdge, "BackgroundColor3", "Accent")
        nameLbl = btn
    else
        -- Boxed tab: dark Panel fill with a soft border while inactive, so
        -- every tab reads as a discrete square rather than floating text.
        self:Themed(btn, "BackgroundColor3", "Panel")
        tabStroke = self:Stroke(btn, 1, "OutlineSoft")
        local iconImg = self:GetIcon(data.Icon)
        local textX = iconImg and 24 or 10
        local btnWidth = textX + labelTextWidth(page.Name) + 18
        btn.Size = UDim2.new(0, btnWidth, 0, 22)
        if iconImg then
            tabIcon = self:Create("ImageLabel", {
                Position = UDim2.new(0, 9, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = iconImg,
                ScaleType = Enum.ScaleType.Fit,
            }, btn)
            self:Themed(tabIcon, "ImageColor3", "TextMuted")
        end
        nameLbl = self:Create("TextLabel", {
            Position = UDim2.new(0, textX, 0, 0),
            Size = UDim2.new(1, -(textX + 10), 1, 0),
            BackgroundTransparency = 1,
            Font = Library.FontBold,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(page.Name),
        }, btn)
        self:Themed(nameLbl, "TextColor3", "TextMuted")
    end
    local edge = nil
    if not isSub then
        -- Linoria-style active-tab indicator: 2px accent bar across the
        -- bottom of the tab button instead of a left edge sliver.
        edge = self:Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, 0, 1, -1),
            Size = UDim2.new(1, -8, 0, 2),
            BorderSizePixel = 0,
            Visible = false,
        }, btn)
        self:Themed(edge, "BackgroundColor3", "Accent")
    end

    local holder = self:Create("Frame", {
        Size = UDim2.new(1, -12, 1, -6),
        Position = UDim2.new(0, 6, 0, 3),
        BackgroundTransparency = 1,
        Visible = false,
    }, window.Items.Body)

    local left = self:Create("ScrollingFrame", {
        Name = "Left",
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, holder)
    self:Themed(left, "ScrollBarImageColor3", "Outline")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, left)

    local right = self:Create("ScrollingFrame", {
        Name = "Right",
        Position = UDim2.new(0.5, 5, 0, 0),
        Size = UDim2.new(0.5, -5, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, holder)
    self:Themed(right, "ScrollBarImageColor3", "Outline")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, right)

    page.Items = { Button = btn, Edge = edge, SubStroke = subStroke, TabStroke = tabStroke, TabIcon = tabIcon, Holder = holder, Left = left, Right = right }
    page._active = false

    local function paintIcon(colorKey)
        if tabIcon then
            self:Themed(tabIcon, "ImageColor3", colorKey)
            pcall(function() tabIcon.ImageColor3 = Library.Theme[colorKey] end)
        end
    end

    local function paint(active)
        page._active = active
        if isSub then
            if active then
                self:Themed(btn, "BackgroundColor3", "Element2")
                Library:Tween(btn, { BackgroundTransparency = 0 }, 0.15)
                pcall(function() nameLbl.TextColor3 = Library.Theme.Text end)
                if subStroke then
                    self:Themed(subStroke, "Color", "Accent")
                    Library:Tween(subStroke, { Color = Library.Theme.Accent }, 0.15)
                end
                if subEdge then subEdge.Visible = true end
            else
                self:Themed(btn, "BackgroundColor3", "Surface")
                Library:Tween(btn, { BackgroundTransparency = 0 }, 0.15)
                pcall(function() nameLbl.TextColor3 = Library.Theme.TextMuted end)
                if subStroke then
                    self:Themed(subStroke, "Color", "Outline")
                    Library:Tween(subStroke, { Color = Library.Theme.Outline }, 0.15)
                end
                if subEdge then subEdge.Visible = false end
            end
            return
        end
        if active then
            self:Themed(btn, "BackgroundColor3", "Element2")
            Library:Tween(btn, { BackgroundTransparency = 0 }, 0.15)
            pcall(function() nameLbl.TextColor3 = Library.Theme.Text end)
            paintIcon("Text")
            if tabStroke then
                Library:Tween(tabStroke, { Color = Library.Theme.Accent }, 0.15)
            end
            if edge then
                edge.Visible = true
                edge.Size = UDim2.new(0, 0, 0, 2)
                Library:Tween(edge, { Size = UDim2.new(1, -8, 0, 2) }, 0.18)
            end
        else
            self:Themed(btn, "BackgroundColor3", "Panel")
            Library:Tween(btn, { BackgroundTransparency = 0 }, 0.15)
            if edge then edge.Visible = false end
            if tabStroke then
                Library:Tween(tabStroke, { Color = Library.Theme.OutlineSoft }, 0.15)
            end
            pcall(function() nameLbl.TextColor3 = Library.Theme.TextMuted end)
            paintIcon("TextMuted")
        end
    end

    function page:Select()
        if page.Level == 2 then
            for _, p in ipairs(window.Pages) do
                p.Items.Holder.Visible = (p == page)
                if p ~= page and p ~= page.ParentTab then p:_paintSelf(false) end
            end
            Library:Punch(page.Items.Holder, 0.985)
            page:_paintSelf(true)
            if page.ParentTab then page.ParentTab:_paintSelf(true) end
            return
        end
        for _, p in ipairs(window.Pages) do
            p.Items.Holder.Visible = false
            p:_paintSelf(false)
        end
        local hasSubs = #page.SubTabs > 0
        if not hasSubs and page.Level == 1 and not page.IsSystem then
            warn("[DWLib] Tab '" .. tostring(page.Name) .. "' has no SubTabs. "
                .. "Add one with Tab:AddSubTab({ Name = \"...\" }) - Tabs cannot hold elements directly.")
        end
        if window._layoutSubs then
            window:_layoutSubs(hasSubs)
        else
            window.Items.SubStrip.Visible = hasSubs
        end
        if window.Items.SubDiv then
            window.Items.SubDiv.Visible = hasSubs
        end
        for _, p in ipairs(window.Pages) do
            if p.Level == 2 then
                p.Items.Button.Visible = (p.ParentTab == page)
            end
        end
        if hasSubs then
            page:_paintSelf(true)
            page.SubTabs[1]:Select()
        else
            page.Items.Holder.Visible = true
            Library:Punch(page.Items.Holder, 0.985)
            page:_paintSelf(true)
        end
    end

    function page:_paintSelf(active)
        paint(active)
    end

    self:Connect(btn.MouseButton1Click, function()
        Library:Punch(btn, 0.97)
        page:Select()
    end)
    Library:Connect(btn.MouseEnter, function()
        if not page._active then
            if isSub then
                Library:Tween(btn, { BackgroundColor3 = Library.Theme.Element2, BackgroundTransparency = 0 }, 0.12)
                Library:Tween(nameLbl, { TextColor3 = Library.Theme.Text }, 0.12)
                if subStroke then
                    Library:Tween(subStroke, { Color = Library.Theme.AccentSoft }, 0.12)
                end
            else
                Library:Themed(btn, "BackgroundColor3", "Element")
                Library:Tween(btn, { BackgroundTransparency = 0, }, 0.12)
                if tabStroke then
                    Library:Tween(tabStroke, { Color = Library.Theme.AccentSoft }, 0.12)
                end
                Library:Tween(nameLbl, { TextColor3 = Library.Theme.Text }, 0.12)
                if tabIcon then
                    Library:Tween(tabIcon, { ImageColor3 = Library.Theme.Text }, 0.12)
                end
            end
        end
    end)
    Library:Connect(btn.MouseLeave, function()
        if not page._active then
            if isSub then
                Library:Tween(btn, { BackgroundColor3 = Library.Theme.Surface, BackgroundTransparency = 0 }, 0.12)
                Library:Tween(nameLbl, { TextColor3 = Library.Theme.TextMuted }, 0.12)
                if subStroke then
                    Library:Tween(subStroke, { Color = Library.Theme.Outline }, 0.12)
                end
            else
                Library:Themed(btn, "BackgroundColor3", "Panel")
                Library:Tween(btn, { BackgroundTransparency = 0 }, 0.12)
                if tabStroke then
                    Library:Tween(tabStroke, { Color = Library.Theme.OutlineSoft }, 0.12)
                end
                Library:Tween(nameLbl, { TextColor3 = Library.Theme.TextMuted }, 0.12)
                if tabIcon then
                    Library:Tween(tabIcon, { ImageColor3 = Library.Theme.TextMuted }, 0.12)
                end
            end
        end
    end)

    table.insert(window.Pages, page)
    if parentTab then
        table.insert(parentTab.SubTabs, page)
        btn.Visible = false
    end
    if #window.Pages == 1 then page:Select() end
    return setmetatable(page, self.Pages)
end

function Library.Pages:AddSubTab(data)
    if self.Level ~= 1 then
        error("[DWLib] AddSubTab can only be called on a Tab (Level 1), not on a SubTab (" .. tostring(self.Name) .. ")", 2)
    end
    data = data or {}
    if type(data) ~= "table" then data = { Name = data } end
    return Library:Page(self.Window, data, 2, self)
end

function Library.Pages:Section(data)
    if self.Level == 1 and not self._allowSections then
        error("[DWLib] Tab '" .. tostring(self.Name) .. "' cannot hold Sections directly. "
            .. "Create a SubTab first: local Sub = Tab:AddSubTab({ Name = \"...\" }); Sub:AddSection(...)", 2)
    end
    data = data or {}
    return Library:Section(self, data)
end
-- ============================================================
-- [ module: Section.lua ]
-- ============================================================

function Library:Section(page, data)
    if page and page.Level == 1 and not page._allowSections then
        error("[DWLib] Tab '" .. tostring(page.Name) .. "' cannot hold Sections directly. "
            .. "Create a SubTab first: local Sub = Tab:AddSubTab({ Name = \"...\" }); Sub:AddSection(...)", 2)
    end
    data = data or {}
    local section = {
        Page = page,
        Window = page.Window,
        Name = data.Name or "Section",
        IsOpen = true,
    }
    local column = (tonumber(data.Side) == 2) and page.Items.Right or page.Items.Left
    local order = #page.Sections + 1
    local HEADER_H = 28

    local box = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = order,
        ClipsDescendants = true,
    }, column)
    self:Themed(box, "BackgroundColor3", "Panel")
    self:Corner(box, 6)
    self:Stroke(box, 1, "OutlineSoft")

    local head = self:Create("TextLabel", {
        Size = UDim2.new(1, -56, 0, 18),
        Position = UDim2.new(0, 8, 0, 2),
        BackgroundTransparency = 1,
        Font = Library.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = string.upper(tostring(section.Name)),
    }, box)
    self:Themed(head, "TextColor3", "Text")

    -- Linoria groupbox header: 2px accent underline under the title row
    -- (the old vertical side-tag read as a different library).
    local underline = self:Create("Frame", {
        Position = UDim2.new(0, 6, 0, 22),
        Size = UDim2.new(1, -12, 0, 2),
        BorderSizePixel = 0,
    }, box)
    self:Themed(underline, "BackgroundColor3", "Accent")

    local arrow = self:Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -6, 0, 2),
        Size = UDim2.new(0, 18, 0, 18),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        TextSize = 12,
        Text = "v",
    }, box)
    self:Themed(arrow, "TextColor3", "TextMuted")

    local list = self:Create("Frame", {
        Name = "List",
        Position = UDim2.new(0, 8, 0, 28),
        Size = UDim2.new(1, -16, 0, 8),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, box)
    local layout = self:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)
    self:Create("UIPadding", { PaddingBottom = UDim.new(0, 4) }, list)

    section.Items = { Box = box, List = list }
    section._fullH = 0
    section._busy = false

    function section:SetOpen(v)
        v = v and true or false
        if v == section.IsOpen or section._busy then return end
        section.IsOpen = v
        section._busy = true
        arrow.Text = v and "v" or ">"
        if not v then
            section._fullH = box.AbsoluteSize.Y
            box.AutomaticSize = Enum.AutomaticSize.None
            box.Size = UDim2.new(1, 0, 0, section._fullH)
            local tw = TweenService:Create(box,
                TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Size = UDim2.new(1, 0, 0, HEADER_H) })
            tw:Play()
            tw.Completed:Wait()
            if not section.IsOpen then
                list.Visible = false
            end
        else
            list.Visible = true
            box.AutomaticSize = Enum.AutomaticSize.None
            box.Size = UDim2.new(1, 0, 0, HEADER_H)
            local target = (section._fullH > HEADER_H) and section._fullH or 200
            local tw = TweenService:Create(box,
                TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                { Size = UDim2.new(1, -4, 0, target) })
            tw:Play()
            tw.Completed:Wait()
            if section.IsOpen then
                box.AutomaticSize = Enum.AutomaticSize.Y
            end
        end
        section._busy = false
    end

    function section:ToggleOpen()
        section:SetOpen(not section.IsOpen)
    end

    if data.Open == false then
        task.defer(function()
            list.Visible = false
            box.AutomaticSize = Enum.AutomaticSize.None
            box.Size = UDim2.new(1, 0, 0, HEADER_H)
            section.IsOpen = false
            arrow.Text = ">"
        end)
    end

    Library:Connect(arrow.MouseButton1Click, function()
        Library:Punch(arrow, 0.85)
        task.spawn(function() section:SetOpen(not section.IsOpen) end)
    end)

    table.insert(page.Sections, section)
    return setmetatable(section, self.Sections)
end
-- ============================================================
-- [ module: Toggle.lua ]
-- ============================================================

function Library.Sections:Toggle(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local state = data.Default == true
    Library.Flags[flag] = state

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 21),
        BackgroundTransparency = 1,
    }, self.Items.List)

    local box = Library:Create("TextButton", {
        Position = UDim2.new(0, 0, 0.5, -8),
        Size = UDim2.new(0, 30, 0, 16),
        AutoButtonColor = false,
        Font = Library.Font,
        TextSize = 10,
        Text = "",
        BorderSizePixel = 0,
    }, row)
    Library:Themed(box, "BackgroundColor3", "Element2")
    Library:Corner(box, 8)
    local boxStroke = Library:Stroke(box, 1)
    -- Active glow: a soft accent halo that fades in with the ON state.
    local glowStroke = Library:Stroke(box, 2)
    Library:Themed(glowStroke, "Color", "Accent")
    glowStroke.Transparency = 1
    local knob = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.new(0, 10, 0, 10),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
    }, box)
    Library:Corner(knob, 5)

    local lbl = Library:Create("TextButton", {
        Position = UDim2.new(0, 37, 0, 0),
        Size = UDim2.new(1, -88, 1, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Library.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Name or flag),
    }, row)
    Library:Themed(lbl, "TextColor3", "Text")

    local right = Library:Create("Frame", {
        Name = "Right",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
    }, row)
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, right)

    local toggle = { Flag = flag, _row = row }
    local kbRef = nil
    local function paint(instant)
        local t = instant and 0 or 0.15
        if state then
            Library:Tween(box, { BackgroundColor3 = Library.Theme.Accent }, t)
            Library:Tween(knob, { Position = UDim2.new(0, 17, 0.5, 0) }, t)
            Library:Tween(glowStroke, { Transparency = 0.55 }, t)
        else
            Library:Tween(box, { BackgroundColor3 = Library.Theme.Element2 }, t)
            Library:Tween(knob, { Position = UDim2.new(0, 3, 0.5, 0) }, t)
            Library:Tween(glowStroke, { Transparency = 1 }, t)
        end
    end
    paint(true)

    function toggle:Get() return state end
    function toggle:Set(v)
        v = v and true or false
        if kbRef and kbRef.GetMode then
            local m = kbRef:GetMode()
            -- Locked on while Always; key-driven only while Hold.
            if (not v and m == "Always")
                or (m == "Hold" and not kbRef._holdKey) then
                return
            end
        end
        state = v
        Library.Flags[flag] = state
        paint(false)
        if kbRef then kbRef:Refresh() end
        if type(data.Callback) == "function" then
            task.spawn(data.Callback, state)
        end
    end
    function toggle:SetVisibility(v) row.Visible = v and true or false end

    function toggle:Keybind(kdata)
        if kbRef then return kbRef end
        kdata = kdata or {}
        if kdata.Name == nil then kdata.Name = data.Name end
        -- Two-way link: the chip shows this toggle's value (ON/OFF) and a
        -- key press writes into the toggle. The toggle stays authoritative.
        kdata._link = toggle
        kbRef = Library:_attachKeybind(row, kdata)
        kbRef:Refresh()
        return kbRef
    end
    function toggle:Colorpicker(cdata)
        return Library:_attachColorpicker(row, cdata)
    end

    -- Right-click opens the keybind menu (mode + rebind).
    local function bindKey()
        if kbRef then
            kbRef:ShowModeMenu(row)
        else
            kbRef = toggle:Keybind({ Name = data.Name, Mode = "Toggle" })
            kbRef:ShowModeMenu(row)
        end
    end
    local function onRight(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            bindKey()
        end
    end
    Library:Connect(row.InputBegan, onRight)
    Library:Connect(box.MouseButton2Click, bindKey)
    Library:Connect(lbl.MouseButton2Click, bindKey)

    local function flip()
        Library:Punch(box, 0.8)
        toggle:Set(not state)
    end
    Library:Connect(box.MouseButton1Click, flip)
    Library:Connect(lbl.MouseButton1Click, flip)
    Library:Connect(row.MouseEnter, function()
        Library:Tween(boxStroke, { Color = Library.Theme.Accent }, 0.15)
    end)
    Library:Connect(row.MouseLeave, function()
        Library:Tween(boxStroke, { Color = Library.Theme.Outline }, 0.15)
    end)

    Library:TrackWidget(flag, function()
        state = Library.Flags[flag] and true or false
        -- Mode invariants win over the saved value regardless of restore order
        -- (the keybind side enforces the same pair, so both orders converge).
        if kbRef and kbRef.GetMode then
            local m = kbRef:GetMode()
            if m == "Always" then
                state = true
            elseif m == "Hold" then
                state = false
            end
        end
        paint(true)
        if kbRef then kbRef:Refresh() end
    end, function()
        state = Library.Flags[flag] and true or false
        if kbRef and kbRef.GetMode then
            local m = kbRef:GetMode()
            if m == "Always" then
                state = true
            elseif m == "Hold" then
                state = false
            end
        end
        Library.Flags[flag] = state
        paint(true)
        if kbRef then kbRef:Refresh() end
        if type(data.Callback) == "function" then
            task.spawn(data.Callback, state)
        end
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(row, data.Tooltip)
    end
    return toggle
end
-- ============================================================
-- [ module: Button.lua ]
-- ============================================================

function Library.Sections:Button(data)
    data = data or {}
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 20),
        AutoButtonColor = false,
        Font = Library.Font,
        TextSize = 13,
        Text = tostring(data.Name or "Button"),
        BorderSizePixel = 0,
    }, self.Items.List)
    Library:Themed(btn, "BackgroundColor3", "Element2")
    Library:Themed(btn, "TextColor3", "Text")
    Library:Corner(btn, 6)
    local btnStroke = Library:Stroke(btn, 1)
    -- Linoria-look sheen: white->gray vertical gradient over the fill. The
    -- gradient multiplies whatever themed background is underneath.
    Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
        }),
        Rotation = 90,
    }, btn)

    local handle = {}
    local kbRef = nil
    function handle:Press()
        Library:Punch(btn)
        if type(data.Callback) == "function" then
            task.spawn(data.Callback)
        end
    end
    function handle:Keybind(kdata)
        if kbRef then return kbRef end
        kdata = kdata or {}
        if kdata.Name == nil then kdata.Name = data.Name end
        -- Button keybinds are press-only: mode locked to "Press" no matter
        -- what the caller asked for (Toggle/Hold/Always never apply).
        -- InputEnded handlers are not wired for this mode, so hold-release
        -- and stuck-on states are structurally impossible.
        kdata.Mode = "Press"
        kdata._pressOnly = true
        -- A bound key IS a press: the button callback runs exactly once.
        kdata.Callback = function() handle:Press() end
        kbRef = Library:_attachKeybind(btn, kdata)
        return kbRef
    end
    local function bindKey()
        if kbRef then
            kbRef:ShowModeMenu(btn)
        else
            kbRef = handle:Keybind({})
            kbRef:ShowModeMenu(btn)
        end
    end
    Library:Connect(btn.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            bindKey()
        end
    end)
    Library:Connect(btn.MouseButton2Click, bindKey)
    function handle:SetVisibility(v) btn.Visible = v and true or false end
    function handle:SetText(t) btn.Text = tostring(t) end
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(btn, data.Tooltip)
    end
    Library:Connect(btn.MouseButton1Click, function() handle:Press() end)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(btn, { BackgroundColor3 = Library.Theme.Element }, 0.12)
        -- Linoria highlight: border flips to the accent, fill stays put.
        Library:Tween(btnStroke, { Color = Library.Theme.Accent }, 0.12)
    end)
    Library:Connect(btn.MouseLeave, function()
        Library:Tween(btn, { BackgroundColor3 = Library.Theme.Element2 }, 0.12)
        Library:Tween(btnStroke, { Color = Library.Theme.Outline }, 0.12)
    end)
    return handle
end
-- ============================================================
-- [ module: Slider.lua ]
-- ============================================================

function Library.Sections:Slider(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local min = tonumber(data.Min) or 0
    local max = tonumber(data.Max) or 100
    if max < min then min, max = max, min end
    local dec = tonumber(data.Decimals) or tonumber(data.Dec) or 1
    local val = tonumber(data.Default) or min
    val = math.clamp(val, min, max)
    Library.Flags[flag] = val

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
    }, self.Items.List)
    local name = Library:Create("TextLabel", {
        Size = UDim2.new(1, -66, 0, 14),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Name or flag),
    }, row)
    Library:Themed(name, "TextColor3", "Text")
    local value = Library:Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 62, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)
    Library:Themed(value, "TextColor3", "TextMuted")

    local bar = Library:Create("TextButton", {
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 9),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
    }, row)
    Library:Themed(bar, "BackgroundColor3", "Element2")
    Library:Corner(bar, 4)
    Library:Stroke(bar, 1)
    local fill = Library:Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
    }, bar)
    Library:Themed(fill, "BackgroundColor3", "Accent")
    Library:Corner(fill, 4)
    -- Depth on the fill: accent fades into its darker twin toward the tip.
    Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 170, 170)),
        }),
        Rotation = 0,
    }, fill)
    local sheen = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
    }, fill)
    Library:Corner(sheen, 4)
    -- Drag knob: white dot riding the fill head.
    local knob = Library:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 10, 0, 10),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        ZIndex = 2,
    }, bar)
    Library:Corner(knob, 5)
    Library:Stroke(knob, 1, "Outline")

    local slider = {}
    local dragging = false
    -- Live=false: Callback is deferred until release (for preview-then-commit
    -- sliders like UI Scale). Preview fires on every tick while dragging.
    local live = data.Live ~= false
    local previewFn = (type(data.Preview) == "function") and data.Preview or nil
    local releaseCbs = {}
    do
        local rf = data.OnRelease
        if type(rf) ~= "function" then rf = data.Release end
        if type(rf) ~= "function" then rf = data.Commit end
        if type(rf) == "function" then table.insert(releaseCbs, rf) end
    end
    local function firePreview(v)
        if previewFn then task.spawn(previewFn, v) end
    end
    local function fireCallback(v)
        if type(data.Callback) == "function" then
            task.spawn(data.Callback, v)
        end
    end
    local function fireRelease(v)
        for _, fn in ipairs(releaseCbs) do
            task.spawn(fn, v)
        end
    end
    local function round(v)
        if dec and dec > 0 then
            local m = 1 / dec
            return math.floor(v * m + 0.5) / m
        end
        return math.floor(v + 0.5)
    end
    local function paint()
        local t = (max == min) and 0 or ((val - min) / (max - min))
        local sfx = data.Suffix and tostring(data.Suffix) or ""
        value.Text = tostring(val) .. sfx
        if dragging then
            fill.Size = UDim2.new(t, 0, 1, 0)
            knob.Position = UDim2.new(t, 0, 0.5, 0)
        else
            Library:Tween(fill, { Size = UDim2.new(t, 0, 1, 0) }, 0.1)
            Library:Tween(knob, { Position = UDim2.new(t, 0, 0.5, 0) }, 0.1)
        end
    end
    paint()

    function slider:Get() return val end
    function slider:Set(v)
        v = tonumber(v) or val
        val = round(math.clamp(v, min, max))
        paint()
        if dragging and not live then
            -- Preview-only tick: do not touch Flags/Callback yet.
            firePreview(val)
            return
        end
        Library.Flags[flag] = val
        fireCallback(val)
    end
    function slider:SetVisibility(v) row.Visible = v and true or false end
    function slider:OnRelease(fn)
        if type(fn) == "function" then table.insert(releaseCbs, fn) end
        return slider
    end

    local function apply(x)
        local abs = bar.AbsolutePosition.X
        local w = math.max(1, bar.AbsoluteSize.X)
        local t = math.clamp((x - abs) / w, 0, 1)
        slider:Set(min + (max - min) * t)
    end
    Library:Connect(bar.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Library:Tween(bar, { Size = UDim2.new(1, 0, 0, 12) }, 0.1)
            apply(i.Position.X)
        end
    end)
    Library:Connect(UserInputService.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            apply(i.Position.X)
        end
    end)
    Library:Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                Library:Tween(bar, { Size = UDim2.new(1, 0, 0, 9) }, 0.12)
            end
            local wasDragging = dragging
            dragging = false
            if wasDragging then
                if not live then
                    Library.Flags[flag] = val
                    paint()
                    fireCallback(val)
                end
                fireRelease(val)
            end
        end
    end)

    Library:TrackWidget(flag, function()
        local saved = tonumber(Library.Flags[flag])
        if saved ~= nil then
            val = round(math.clamp(saved, min, max))
            paint()
        end
    end, function()
        local saved = tonumber(Library.Flags[flag])
        if saved ~= nil then
            val = round(math.clamp(saved, min, max))
            Library.Flags[flag] = val
            paint()
        end
        fireCallback(val)
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(row, data.Tooltip)
    end
    return slider
end
-- ============================================================
-- [ module: Dropdown.lua ]
-- ============================================================

function Library.Sections:Dropdown(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local multi = data.Multi == true
    local items = {}
    for _, v in ipairs(data.Items or {}) do table.insert(items, tostring(v)) end

    local current
    if multi then
        current = {}
        for _, v in ipairs(data.Default or {}) do current[tostring(v)] = true end
    else
        current = tostring(data.Default or items[1] or "")
    end
    Library.Flags[flag] = current

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
    }, self.Items.List)
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
    }, row)
    Library:Themed(btn, "BackgroundColor3", "Element2")
    local dd = { Flag = flag, _open = false }
    Library:Corner(btn, 6)
    local ddStroke = Library:Stroke(btn, 1)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(ddStroke, { Color = Library.Theme.Accent }, 0.15)
    end)
    Library:Connect(btn.MouseLeave, function()
        if not dd._open then
            Library:Tween(ddStroke, { Color = Library.Theme.Outline }, 0.15)
        end
    end)

    local nameLbl = Library:Create("TextLabel", {
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.42, -8, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Name or "Select"),
    }, btn)
    Library:Themed(nameLbl, "TextColor3", "TextMuted")
    local valueLbl = Library:Create("TextLabel", {
        Position = UDim2.new(0.42, 0, 0, 0),
        Size = UDim2.new(0.58, -22, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "",
    }, btn)
    Library:Themed(valueLbl, "TextColor3", "Text")
    -- Linoria-look arrow: accent gradient segment on the right edge of the
    -- closed box, glyph flips to "^" when the list is open.
    local arrowBox = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -3, 0.5, 0),
        Size = UDim2.new(0, 18, 1, -6),
        BorderSizePixel = 0,
    }, btn)
    Library:Themed(arrowBox, "BackgroundColor3", "Accent")
    Library:Corner(arrowBox, 2)
    Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160)),
        }),
        Rotation = 90,
    }, arrowBox)
    local arrow = Library:Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        Text = "v",
    }, arrowBox)
    Library:Themed(arrow, "TextColor3", "Text")

    local list = Library:Create("ScrollingFrame", {
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        BorderSizePixel = 0,
        Visible = false,
    }, row)
    Library:Themed(list, "BackgroundColor3", "Background")
    Library:Themed(list, "ScrollBarImageColor3", "Outline")
    Library:Corner(list, 8)
    Library:Stroke(list, 1)
    local ll = Library:Create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, list)
    local MAX_H = 276 -- ~14 rows, then scroll
    local function contentHeight()
        local n = #items
        if n <= 0 then return 28 end
        return math.min(8 + n * 18 + (n - 1) * 1, MAX_H)
    end
    local function syncHeight()
        list.Size = UDim2.new(list.Size.X.Scale, list.Size.X.Offset, 0, contentHeight())
    end
    Library:Create("UIPadding", {
        PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3),
    }, list)

    local function valueText()
        if multi then
            local t = {}
            for k in pairs(current) do table.insert(t, k) end
            if #t == 0 then return "none" end
            table.sort(t)
            return table.concat(t, ", ")
        end
        return tostring(current)
    end
    local function paint() valueLbl.Text = valueText() end
    local function fire()
        Library.Flags[flag] = current
        if type(data.Callback) == "function" then
            if multi then
                local out = {}
                for k in pairs(current) do table.insert(out, k) end
                task.spawn(data.Callback, out)
            else
                task.spawn(data.Callback, current)
            end
        end
    end
    local function rebuild()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, name in ipairs(items) do
            local on = multi and current[name] or (current == name)
            local b = Library:Create("TextButton", {
                Size = UDim2.new(1, -4, 0, 18),
                AutoButtonColor = false,
                Text = "",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, list)
            Library:Corner(b, 0)
            local box = Library:Create("Frame", {
                Position = UDim2.new(0, 6, 0.5, -6),
                Size = UDim2.new(0, 12, 0, 12),
                BorderSizePixel = 0,
            }, b)
            if on then
                Library:Themed(box, "BackgroundColor3", "Accent")
            else
                Library:Themed(box, "BackgroundColor3", "Element2")
            end
            Library:Corner(box, 0)
            local boxStroke = Library:Stroke(box, 1)
            local mark = Library:Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Library.Font,
                TextSize = 10,
                Text = on and "✓" or "",
                Visible = on and true or false,
            }, box)
            Library:Themed(mark, "TextColor3", "Text")
            local lbl = Library:Create("TextLabel", {
                Position = UDim2.new(0, 24, 0, 0),
                Size = UDim2.new(1, -30, 1, 0),
                BackgroundTransparency = 1,
                Font = Library.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = name,
            }, b)
            if on then
                Library:Themed(lbl, "TextColor3", "Text")
            else
                Library:Themed(lbl, "TextColor3", "TextMuted")
            end
            Library:Connect(b.MouseEnter, function()
                Library:Tween(b, { BackgroundColor3 = Library.Theme.Element2, BackgroundTransparency = 0 }, 0.1)
                Library:Tween(boxStroke, { Color = Library.Theme.Accent }, 0.1)
            end)
            Library:Connect(b.MouseLeave, function()
                Library:Tween(b, { BackgroundTransparency = 1 }, 0.1)
                Library:Tween(boxStroke, { Color = Library.Theme.Outline }, 0.1)
            end)
            Library:Connect(b.MouseButton1Click, function()
                Library:Punch(b, 0.97)
                if multi then
                    current[name] = not current[name] or nil
                else
                    current = name
                    dd:SetOpen(false)
                end
                paint(); rebuild(); fire()
            end)
        end
        if dd._open then syncHeight() end
    end
    paint(); rebuild()

    function dd:Get() return current end
    function dd:Set(v)
        if multi then
            current = {}
            for _, x in ipairs(v or {}) do current[tostring(x)] = true end
        else
            current = tostring(v)
        end
        paint(); rebuild(); fire()
    end
    function dd:Refresh(newItems)
        items = {}
        for _, v in ipairs(newItems or {}) do table.insert(items, tostring(v)) end
        rebuild(); paint()
        syncHeight()
    end
    function dd:SetOpen(o)
        o = o and true or false
        if o then
            dd._open = true
            Library:Tween(ddStroke, { Color = Library.Theme.Accent }, 0.12)
            -- Explicit height: full content up to 8 rows, then scroll.
            syncHeight()
            pcall(function() list.CanvasPosition = Vector2.new(0, 0) end)
            Library:ShowPopup(list, btn, { width = math.max(140, btn.AbsoluteSize.X) })
            Library:Punch(list)
        else
            dd._open = false
            Library:Tween(ddStroke, { Color = Library.Theme.Outline }, 0.12)
            Library:ClosePopups()
        end
        arrow.Text = dd._open and "^" or "v"
    end
    function dd:SetVisibility(v) row.Visible = v and true or false end
    function dd:SelectAll()
        if not multi then return end
        for _, n in ipairs(items) do current[n] = true end
        paint(); rebuild(); fire()
    end
    function dd:DeselectAll()
        if not multi then return end
        current = {}
        paint(); rebuild(); fire()
    end
    Library:Connect(btn.MouseButton1Click, function()
        Library:Punch(btn, 0.98)
        local cur = Library._openPopup
        if dd._open and cur and cur.frame == list then
            dd:SetOpen(false)
        else
            dd:SetOpen(true)
        end
    end)
    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if multi then
            if type(saved) == "table" then
                current = {}
                local isArray = saved[1] ~= nil
                if isArray then
                    for _, x in ipairs(saved) do current[tostring(x)] = true end
                else
                    for k in pairs(saved) do current[tostring(k)] = true end
                end
                paint(); rebuild()
            end
        elseif type(saved) == "string" then
            current = saved
            paint(); rebuild()
        end
    end, function()
        local saved = Library.Flags[flag]
        if multi then
            if type(saved) == "table" then
                current = {}
                local isArray = saved[1] ~= nil
                if isArray then
                    for _, x in ipairs(saved) do current[tostring(x)] = true end
                else
                    for k in pairs(saved) do current[tostring(k)] = true end
                end
                paint(); rebuild()
            end
        elseif type(saved) == "string" then
            current = saved
            paint(); rebuild()
        end
        fire()
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(btn, data.Tooltip)
    end
    return dd
end
-- ============================================================
-- [ module: Label.lua ]
-- ============================================================

function Library.Sections:Label(data)
    local text = ""
    if type(data) == "table" then
        text = tostring(data.Text or data.Name or "")
    else
        text = tostring(data or "")
    end
    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
    }, self.Items.List)
    local lbl = Library:Create("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = text,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)
    Library:Themed(lbl, "TextColor3", "TextMuted")

    local right = Library:Create("Frame", {
        Name = "Right",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 16),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
    }, row)
    Library:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, right)

    local handle = {}
    function handle:SetText(t) lbl.Text = tostring(t) end
    function handle:Get() return lbl.Text end
    function handle:SetVisibility(v) row.Visible = v and true or false end
    function handle:Keybind(kdata)
        kdata = kdata or {}
        if kdata.Name == nil then kdata.Name = text end
        return Library:_attachKeybind(row, kdata)
    end
    function handle:Colorpicker(cdata) return Library:_attachColorpicker(row, cdata) end
    if type(data) == "table" and type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(row, data.Tooltip)
    end
    return handle
end
-- ============================================================
-- [ module: Textbox.lua ]
-- ============================================================

function Library.Sections:Textbox(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local val = tostring(data.Default or "")
    Library.Flags[flag] = val

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
    }, self.Items.List)
    local lbl = Library:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(data.Name or flag),
    }, row)
    Library:Themed(lbl, "TextColor3", "Text")
    local box = Library:Create("TextBox", {
        Position = UDim2.new(0, 0, 0, 17),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = val,
        PlaceholderText = tostring(data.Placeholder or ""),
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
    }, row)
    Library:Themed(box, "BackgroundColor3", "Inline")
    Library:Themed(box, "TextColor3", "Text")
    Library:Corner(box, 6)
    local boxStroke = Library:Stroke(box, 1)
    Library:Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
    Library:Connect(box.Focused, function()
        Library:Tween(boxStroke, { Color = Library.Theme.Accent }, 0.15)
    end)

    local tb = {}
    function tb:Get() return val end
    function tb:Set(v)
        val = tostring(v)
        box.Text = val
        Library.Flags[flag] = val
        if type(data.Callback) == "function" then task.spawn(data.Callback, val) end
    end
    function tb:SetVisibility(v) row.Visible = v and true or false end

    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if type(saved) == "string" then
            val = saved
            box.Text = val
        end
    end, function()
        local saved = Library.Flags[flag]
        if type(saved) == "string" then
            val = saved
            box.Text = val
        end
        if type(data.Callback) == "function" then task.spawn(data.Callback, val) end
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(row, data.Tooltip)
    end

    Library:Connect(box.FocusLost, function(enter)
        Library:Tween(boxStroke, { Color = Library.Theme.Outline }, 0.15)
        local t = box.Text
        if data.Numeric then
            if t ~= "" and tonumber(t) == nil then
                box.Text = val
                return
            end
        end
        if data.Finished ~= false and not enter then return end
        tb:Set(t)
    end)
    return tb
end
-- ============================================================
-- [ module: Keybind.lua ]
-- ============================================================

Library._keybinds = {}

function Library:_attachKeybind(row, data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local key = data.Default
    if typeof(key) ~= "EnumItem" then key = nil end
    local mode = tostring(data.Mode or "Toggle")
    local toggled = false
    local picking = false
    Library.Flags[flag] = { Key = key, Mode = mode, Toggled = toggled }

    local host = row:FindFirstChild("Right") or row
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(0, 48, 0, 16),
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        TextSize = 11,
        Text = "[NONE]",
        BorderSizePixel = 0,
    }, host)
    if host ~= row then
        btn.LayoutOrder = 1
    else
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
    end
    Library:Themed(btn, "BackgroundColor3", "Surface")
    Library:Themed(btn, "TextColor3", "TextMuted")
    Library:Corner(btn, 2)
    local kbStroke = Library:Stroke(btn, 1)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(kbStroke, { Color = Library.Theme.Accent }, 0.12)
    end)
    Library:Connect(btn.MouseLeave, function()
        Library:Tween(kbStroke, { Color = Library.Theme.Outline }, 0.12)
    end)

    local kb = { Flag = flag, _name = tostring(data.Name or flag) }
    -- Two-way link (toggle:Keybind): the chip mirrors the toggle's live
    -- value (read) and a key press writes straight into the toggle, so the
    -- toggle stays the single source of truth. Unlinked keybinds (buttons,
    -- standalone) keep the old key-name chip.
    local link = data._link
    if type(link) ~= "table" or type(link.Get) ~= "function" or type(link.Set) ~= "function" then
        link = nil
    end
    -- Button-linked keybinds are press-only: mode can never leave "Press",
    -- and the right-click menu hides the Toggle/Hold/Always rows entirely.
    local pressOnly = data._pressOnly == true
    if pressOnly then
        mode = "Press"
    end
    -- Keybind-list tag row: "BUTTON" for press-only binds, else the live
    -- mode in caps (SetMode changes show up on the next Refresh).
    local function modeTag()
        if pressOnly then return "BUTTON" end
        return string.upper(mode)
    end
    local function linkOn()
        if not link then return toggled end
        local ok, v = pcall(link.Get, link)
        return ok and v and true or false
    end
    local function paint()
        if picking then
            btn.Text = "[...]"
        else
            btn.Text = key and ("[" .. key.Name .. "]") or "[NONE]"
        end
    end
    paint()
    local function fire()
        Library.Flags[flag] = { Key = key, Mode = mode, Toggled = toggled }
        if type(data.Callback) == "function" then task.spawn(data.Callback, toggled) end
        Library:_pushKeybindList()
    end
    function kb:Get() return linkOn() end
    function kb:GetText()
        -- Unbound keybinds ([NONE]) are unregistered from the keybind list:
        -- no text means no row, and the list falls back to "none bound".
        if typeof(key) ~= "EnumItem" then return nil end
        -- State words ("ON"/"OFF") dropped by request; mode tag appended so
        -- the list still shows how the bind behaves.
        local tag = modeTag()
        if link then
            return kb._name .. " [" .. key.Name .. "] " .. tag, linkOn()
        end
        return kb._name .. " " .. btn.Text .. " " .. tag, linkOn()
    end
    -- Structured row data for the keybind list: name, key, on/off, mode.
    -- Nil when unbound (same contract as GetText) so the list skips it.
    function kb:GetParts()
        if typeof(key) ~= "EnumItem" then return nil end
        return { name = kb._name, key = key.Name, on = linkOn(), mode = modeTag() }
    end
    function kb:GetMode() return mode end
    function kb:SetMode(m)
        if pressOnly and tostring(m) ~= "Press" then return kb end
        mode = tostring(m)
        if mode == "Always" then
            -- Forced on: apply immediately, linked toggle included.
            toggled = true
            if link then link:Set(true) end
        elseif mode == "Hold" and link then
            -- Momentary only: never stick on from an earlier mode.
            kb._holdKey = true
            link:Set(false)
            kb._holdKey = false
            toggled = false
        end
        fire()
    end
    function kb:Press(v)
        if link then
            if mode == "Hold" and not kb._holdKey then return end
            local nv = (v == nil) and (not linkOn()) or (v and true or false)
            toggled = nv
            link:Set(nv)
            fire()
            return
        end
        toggled = (v == nil) and (not toggled) or (v and true or false)
        fire()
    end
    function kb:StartPicking()
        picking = true
        paint()
        Library:Punch(btn, 0.9)
    end
    -- Right-click menu: pick Toggle / Hold / Always, or rebind the key.
    local menu, menuMarks, menuKeyLbl = nil, {}, nil
    function kb:ShowModeMenu(anchor)
        if not menu or not menu.Parent then
            menuMarks = {}
            menu = Library:Create("Frame", {
                Size = UDim2.new(0, 190, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Visible = false,
            }, Library.Overlay or btn.Parent)
            Library:Themed(menu, "BackgroundColor3", "Background")
            Library:Corner(menu, 8)
            Library:Stroke(menu, 1)
            Library:Create("UIPadding", {
                PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
            }, menu)
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, menu)
            local modes = {
                { "Toggle", "flips on each press" },
                { "Hold", "on while held" },
                { "Always", "forced on" },
            }
            for _, m in ipairs(modes) do
                if pressOnly then break end
                local b = Library:Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 38),
                    AutoButtonColor = false,
                    Text = "",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, menu)
                Library:Corner(b, 6)
                local t = Library:Create("TextLabel", {
                    Position = UDim2.new(0, 10, 0, 3),
                    Size = UDim2.new(1, -36, 0, 16),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = m[1],
                }, b)
                Library:Themed(t, "TextColor3", "Text")
                local d = Library:Create("TextLabel", {
                    Position = UDim2.new(0, 10, 0, 19),
                    Size = UDim2.new(1, -36, 0, 14),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = m[2],
                }, b)
                Library:Themed(d, "TextColor3", "TextMuted")
                local mark = Library:Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 18, 0, 18),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 13,
                    Text = "",
                }, b)
                Library:Themed(mark, "TextColor3", "Accent")
                menuMarks[m[1]] = mark
                Library:Connect(b.MouseEnter, function()
                    Library:Tween(b, { BackgroundColor3 = Library.Theme.Element2, BackgroundTransparency = 0 }, 0.1)
                end)
                Library:Connect(b.MouseLeave, function()
                    Library:Tween(b, { BackgroundTransparency = 1 }, 0.1)
                end)
                Library:Connect(b.MouseButton1Click, function()
                    kb:SetMode(m[1])
                    Library:ClosePopups()
                end)
            end
            local kb2 = Library:Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                AutoButtonColor = false,
                Text = "",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, menu)
            Library:Corner(kb2, 6)
            menuKeyLbl = Library:Create("TextLabel", {
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Code,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Key: [NONE]",
            }, kb2)
            Library:Themed(menuKeyLbl, "TextColor3", "TextMuted")
            Library:Connect(kb2.MouseEnter, function()
                Library:Tween(kb2, { BackgroundColor3 = Library.Theme.Element2, BackgroundTransparency = 0 }, 0.1)
            end)
            Library:Connect(kb2.MouseLeave, function()
                Library:Tween(kb2, { BackgroundTransparency = 1 }, 0.1)
            end)
            Library:Connect(kb2.MouseButton1Click, function()
                Library:ClosePopups()
                kb:StartPicking()
            end)
        end
        for name, mark in pairs(menuMarks) do
            pcall(function() mark.Text = (mode == name) and "✓" or "" end)
        end
        pcall(function()
            menuKeyLbl.Text = "Key: " .. ((typeof(key) == "EnumItem") and ("[" .. key.Name .. "]") or "[NONE]")
        end)
        Library:ShowPopup(menu, anchor or btn, { width = 190 })
        Library:Punch(menu, 0.98)
    end
    function kb:SetVisibility(v) btn.Visible = v and true or false end
    function kb:Refresh()
        paint()
        Library:_pushKeybindList()
        return kb
    end

    Library:Connect(btn.MouseButton1Click, function() kb:StartPicking() end)
    Library:Connect(UserInputService.InputBegan, function(input, gpe)
        if picking and input.UserInputType == Enum.UserInputType.Keyboard then
            picking = false
            -- Backspace clears the bind instead of binding Backspace.
            if input.KeyCode == Enum.KeyCode.Backspace then
                key = nil
            else
                key = input.KeyCode
            end
            paint()
            fire()
            return
        end
        if gpe or key == nil then return end
        if input.KeyCode == key then
            if link then
                local newVal
                if mode == "Hold" then
                    newVal = true
                elseif mode == "Always" then
                    newVal = true
                else
                    newVal = not linkOn()
                end
                toggled = newVal
                kb._holdKey = (mode == "Hold")
                link:Set(newVal)
                kb._holdKey = false
                fire()
            elseif mode == "Always" then
                toggled = true
                fire()
            elseif mode == "Hold" then
                toggled = true
                fire()
            elseif mode == "Press" then
                -- One-shot: toggled state never flips or sticks, only fire.
                toggled = false
                fire()
            else
                toggled = not toggled
                fire()
            end
        end
    end)
    Library:Connect(UserInputService.InputEnded, function(input)
        if key ~= nil and input.KeyCode == key and mode == "Hold" then
            if link then
                toggled = false
                kb._holdKey = true
                link:Set(false)
                kb._holdKey = false
            else
                toggled = false
            end
            fire()
        end
    end)
    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if type(saved) == "table" then
            if typeof(saved.Key) == "EnumItem" or saved.Key == nil then
                key = saved.Key
            end
            if type(saved.Mode) == "string" then mode = saved.Mode end
            -- Press-only keybinds keep their mode even when a saved config
            -- (or stale flag) claims Toggle/Hold/Always.
            if pressOnly then mode = "Press" end
            toggled = saved.Toggled and true or false
            paint()
            if link then
                if mode == "Always" then
                    toggled = true
                    link:Set(true)
                elseif mode == "Hold" then
                    toggled = false
                    kb._holdKey = true
                    link:Set(false)
                    kb._holdKey = false
                end
            end
        end
    end, function()
        if link then
            toggled = linkOn()
        end
        fire()
    end)
    table.insert(Library._keybinds, kb)
    Library:_pushKeybindList()
    return kb
end

function Library.Sections:Keybind(data)
    local host = self:Label(data and (data.Name or "Keybind") or "Keybind")
    return host:Keybind(data)
end
-- ============================================================
-- [ module: Colorpicker.lua ]
-- ============================================================

function Library:_attachColorpicker(row, data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local alphaOpt = data.Alpha
    if alphaOpt == nil then alphaOpt = data.alpha end
    local hasAlpha = alphaOpt ~= false
    local color = typeof(data.Default) == "Color3" and data.Default or Color3.fromRGB(220, 30, 42)
    local h, s, v = color:ToHSV()
    local alpha = hasAlpha and math.clamp(tonumber(alphaOpt) or 0, 0, 1) or 0
    Library.Flags[flag] = color
    if hasAlpha then Library.Flags[flag .. "_alpha"] = alpha end

    local host = row:FindFirstChild("Right") or row
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 15),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        BackgroundColor3 = color,
        BackgroundTransparency = hasAlpha and alpha or 0,
    }, host)
    if host == row then
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
    else
        btn.LayoutOrder = 2
    end
    Library:Corner(btn, 0)
    local swStroke = Library:Stroke(btn, 1)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(swStroke, { Color = Library.Theme.Accent }, 0.12)
    end)
    Library:Connect(btn.MouseLeave, function()
        Library:Tween(swStroke, { Color = Library.Theme.Outline }, 0.12)
    end)

    local open = false
    local pop
    local palBase, palDot, hueBar, hueDot, alphaFill, alphaDot, readout
    local POP_W = hasAlpha and 196 or 174

    local function current()
        return Color3.fromHSV(h, s, v)
    end

    local function fire()
        color = current()
        Library.Flags[flag] = color
        if hasAlpha then Library.Flags[flag .. "_alpha"] = alpha end
        pcall(function()
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = hasAlpha and alpha or 0
        end)
        if type(data.Callback) == "function" then task.spawn(data.Callback, color, alpha) end
    end

    local function paint()
        if not pop then return end
        palBase.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        palDot.Position = UDim2.new(s, -4, 1 - v, -4)
        hueDot.Position = UDim2.new(0.5, -5, h, -5)
        if hasAlpha and alphaFill then
            alphaFill.BackgroundColor3 = current()
            alphaDot.Position = UDim2.new(0.5, -5, alpha, -5)
        end
        readout.Text = hasAlpha
            and string.format("#%s  -  alpha %.2f", current():ToHex(), alpha)
            or ("#" .. current():ToHex())
    end

    local function dot(parent, size)
        local d = Library:Create("Frame", {
            Size = UDim2.new(0, size, 0, size),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        }, parent)
        Library:Corner(d, size)
        local st = Library:Create("UIStroke", { Thickness = 1.5 }, d)
        st.Color = Color3.fromRGB(20, 20, 25)
        return d
    end

    local function drag2D(hit, fn)
        local drag = false
        Library:Connect(hit.InputBegan, function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                drag = true
                fn(inp.Position.X, inp.Position.Y)
            end
        end)
        Library:Connect(UserInputService.InputChanged, function(inp)
            if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                fn(inp.Position.X, inp.Position.Y)
            end
        end)
        Library:Connect(UserInputService.InputEnded, function() drag = false end)
    end

    local function palAt(x, y)
        local p = palBase.AbsolutePosition
        local sz = palBase.AbsoluteSize
        s = math.clamp((x - p.X) / math.max(1, sz.X), 0, 1)
        v = 1 - math.clamp((y - p.Y) / math.max(1, sz.Y), 0, 1)
        paint()
        fire()
    end

    local function hueAt(_, y)
        local p = hueBar.AbsolutePosition
        h = math.clamp((y - p.Y) / math.max(1, hueBar.AbsoluteSize.Y), 0, 1)
        paint()
        fire()
    end

    local function alphaAt(_, y)
        if not hasAlpha then return end
        local p = alphaFill.AbsolutePosition
        alpha = math.clamp((y - p.Y) / math.max(1, alphaFill.AbsoluteSize.Y), 0, 1)
        paint()
        fire()
    end

    local function buildPop()
        pop = Library:Create("Frame", {
            Size = UDim2.new(0, POP_W, 0, 178),
            BorderSizePixel = 0,
            Visible = false,
        }, Library.Overlay or row)
        Library:Themed(pop, "BackgroundColor3", "Background")
        Library:Corner(pop, 8)
        Library:Stroke(pop, 1)

        palBase = Library:Create("TextButton", {
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(0, 136, 0, 136),
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        }, pop)
        Library:Corner(palBase, 6)
        local sat = Library:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        }, palBase)
        local satG = Library:Create("UIGradient", {}, sat)
        satG.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        Library:Corner(sat, 6)
        local val = Library:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        }, palBase)
        local valG = Library:Create("UIGradient", { Rotation = 90 }, val)
        valG.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        Library:Corner(val, 6)
        palDot = dot(palBase, 8)

        hueBar = Library:Create("TextButton", {
            Position = UDim2.new(0, 150, 0, 8),
            Size = UDim2.new(0, 16, 0, 136),
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
        }, pop)
        local hueG = Library:Create("UIGradient", { Rotation = 90 }, hueBar)
        hueG.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        Library:Corner(hueBar, 6)
        hueDot = dot(hueBar, 10)

        if hasAlpha then
            local aBar = Library:Create("TextButton", {
                Position = UDim2.new(0, 172, 0, 8),
                Size = UDim2.new(0, 16, 0, 136),
                AutoButtonColor = false,
                Text = "",
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
            }, pop)
            local back = Library:Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(200, 200, 200),
            }, aBar)
            local backG = Library:Create("UIGradient", { Rotation = 45 }, back)
            backG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 235, 235)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 120)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 235, 235)),
            })
            Library:Corner(back, 6)
            alphaFill = Library:Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = current(),
            }, aBar)
            local aG = Library:Create("UIGradient", { Rotation = 90 }, alphaFill)
            aG.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            Library:Corner(alphaFill, 6)
            Library:Stroke(aBar, 1)
            alphaDot = dot(aBar, 10)
            drag2D(aBar, alphaAt)
        end

        readout = Library:Create("TextLabel", {
            Position = UDim2.new(0, 8, 0, 150),
            Size = UDim2.new(0, POP_W - 16, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "",
        }, pop)
        Library:Themed(readout, "TextColor3", "TextMuted")

        drag2D(palBase, palAt)
        drag2D(hueBar, hueAt)
        paint()
    end

    local picker = {}
    function picker:Get() return current(), alpha end
    function picker:Set(c, a)
        if typeof(c) == "Color3" then
            h, s, v = c:ToHSV()
            if hasAlpha and tonumber(a) ~= nil then
                alpha = math.clamp(tonumber(a), 0, 1)
            end
            paint()
            fire()
        end
    end
    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if typeof(saved) == "Color3" then
            h, s, v = saved:ToHSV()
            if hasAlpha then
                local sa = tonumber(Library.Flags[flag .. "_alpha"])
                if sa ~= nil then alpha = math.clamp(sa, 0, 1) end
            end
            paint()
            pcall(function()
                btn.BackgroundColor3 = current()
                btn.BackgroundTransparency = hasAlpha and alpha or 0
            end)
        end
    end, function()
        local saved = Library.Flags[flag]
        if typeof(saved) == "Color3" then
            h, s, v = saved:ToHSV()
            if hasAlpha then
                local sa = tonumber(Library.Flags[flag .. "_alpha"])
                if sa ~= nil then alpha = math.clamp(sa, 0, 1) end
            end
            paint()
            pcall(function()
                btn.BackgroundColor3 = current()
                btn.BackgroundTransparency = hasAlpha and alpha or 0
            end)
        end
        fire()
    end)
    function picker:SetOpen(o)
        o = o and true or false
        if o then
            if not pop then buildPop() end
            open = true
            paint()
            Library:ShowPopup(pop, btn, { width = POP_W, alignRight = true })
            Library:Punch(pop)
        else
            open = false
            Library:ClosePopups()
        end
    end

    Library:Connect(btn.MouseButton1Click, function()
        local cur = Library._openPopup
        if open and cur and cur.frame == pop then
            picker:SetOpen(false)
        else
            picker:SetOpen(true)
        end
    end)
    return picker
end

function Library.Sections:Colorpicker(data)
    local host = self:Label(data and (data.Name or "Color") or "Color")
    local p = host:Colorpicker(data)
    if type(p) == "table" then p.Label = host end
    return p
end

function Library.Sections:AddColorpicker(a, b, c)
    if type(a) == "table" then return self:Colorpicker(a) end
    if type(b) == "function" then
        return self:Colorpicker({ Name = a, Callback = b })
    end
    return self:Colorpicker({ Name = a, Default = b, Callback = c })
end
-- ============================================================
-- [ module: Notification.lua ]
-- ============================================================

function Library:Notification(title, body, duration)
    if type(title) ~= "string" then body = title title = "DWLib" end
    body = tostring(body or "")
    duration = math.max(1, tonumber(duration) or tonumber(self.NotifDuration) or 4)
    local TweenService = game:GetService("TweenService")
    local RiskColor = self.Theme.RiskColor or self.Theme.Accent

    local W, H = 300, 64
    local card = self:Create("Frame", {
        Size = UDim2.new(0, W, 0, H),
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, self.NotifHolder)
    self:Themed(card, "BackgroundColor3", "Background")
    self:Corner(card, 8)
    self:Stroke(card, 1, "Outline")

    -- 2px accent rail down the left edge.
    local rail = self:Create("Frame", {
        Size = UDim2.new(0, 2, 1, 0),
        BorderSizePixel = 0,
    }, card)
    self:Themed(rail, "BackgroundColor3", "Accent")

    local titleLbl = self:Create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 7),
        Size = UDim2.new(1, -66, 0, 14),
        BackgroundTransparency = 1,
        Font = Library.FontBold,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(title),
    }, card)
    self:Themed(titleLbl, "TextColor3", "Text")

    -- Countdown chip, top-right: remaining seconds as "3s".
    local timer = self:Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 7),
        Size = UDim2.new(0, 40, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = tostring(duration) .. "s",
    }, card)
    self:Themed(timer, "TextColor3", "TextMuted")

    local bodyLbl = self:Create("TextLabel", {
        Position = UDim2.new(0, 12, 0, 24),
        Size = UDim2.new(1, -24, 0, 28),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = body,
    }, card)
    self:Themed(bodyLbl, "TextColor3", "TextMuted")

    -- Drain bar: 1px track with an accent fill that shrinks with the clock,
    -- so the disappearance is visible even at a glance.
    local track = self:Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.5,
        BackgroundColor3 = Color3.new(0, 0, 0),
        ZIndex = 2,
    }, card)
    local drain = self:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BorderSizePixel = 0,
        ZIndex = 3,
    }, track)
    self:Themed(drain, "BackgroundColor3", "Accent")

    local n = { Instance = card }
    local closing = false
    local paused = false
    function n:Close()
        closing = true
        pcall(function()
            local info = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local tw = TweenService:Create(card, info, { BackgroundTransparency = 1 })
            tw:Play()
            for _, d in ipairs(card:GetDescendants()) do
                if d:IsA("TextLabel") then
                    TweenService:Create(d, info, { TextTransparency = 1 }):Play()
                elseif d:IsA("Frame") and d ~= card then
                    TweenService:Create(d, info, { BackgroundTransparency = 1 }):Play()
                elseif d:IsA("UIStroke") then
                    TweenService:Create(d, info, { Transparency = 1 }):Play()
                end
            end
        end)
        task.delay(0.2, function() pcall(function() card:Destroy() end) end)
    end
    Library:BringToFront(Library.NotifHolder)
    Library:Punch(card)
    -- Hover pauses the clock, click dismisses instantly with the fade.
    Library:Connect(card.MouseEnter, function() paused = true end)
    Library:Connect(card.MouseLeave, function() paused = false end)
    Library:Connect(card.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then n:Close() end
    end)

    Library:Thread(function()
        local left = duration
        local t0 = tick()
        while left > 0 and card.Parent and not closing do
            task.wait(0.05)
            if paused then
                t0 = tick() - (duration - left) -- freeze the clock while hovered
                continue
            end
            left = duration - (tick() - t0)
            if left <= 0 then break end
            local frac = left / duration
            local urgent = left <= 1
            local disp = math.max(1, math.floor(left + 0.95))
            pcall(function()
                timer.Text = tostring(disp) .. "s"
                timer.TextColor3 = urgent and Library.Theme.Text or Library.Theme.TextMuted
                drain.Size = UDim2.new(frac, 0, 1, 0)
                drain.BackgroundColor3 = urgent and RiskColor
                    or Library.Theme.Accent
                drain.BackgroundTransparency = paused and 0.55 or 0
            end)
        end
    end)
    task.delay(duration + 0.5, function()
        if not closing and card.Parent then n:Close() end
    end)
    return n
end
-- ============================================================
-- [ module: Dialog.lua ]
-- ============================================================

function Library:Dialog(data)
    data = data or {}
    local overlay = self:Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        Text = "",
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.5,
        ZIndex = 100,
    }, self.Holder)
    local card = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 440, 0, 220),
        BorderSizePixel = 0,
        ZIndex = 101,
    }, overlay)
    self:Themed(card, "BackgroundColor3", "Panel")
    self:Corner(card, 8)
    self:Stroke(card, 1, "OutlineSoft")
    local t = self:Create("TextLabel", {
        Position = UDim2.new(0, 16, 0, 12),
        Size = UDim2.new(1, -32, 0, 26),
        BackgroundTransparency = 1,
        Font = Library.FontBold,
        TextSize = 17,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(data.Title or "Confirm"),
        ZIndex = 102,
    }, card)
    self:Themed(t, "TextColor3", "Text")
    local b = self:Create("TextLabel", {
        Position = UDim2.new(0, 16, 0, 44),
        Size = UDim2.new(1, -32, 0, 96),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Text = tostring(data.Text or ""),
        ZIndex = 102,
    }, card)
    self:Themed(b, "TextColor3", "TextMuted")

    local dlg = {}
    function dlg:Close() pcall(function() overlay:Destroy() end) end
    Library:Punch(card)
    local btns = data.Buttons or { { Text = "OK" } }
    for i, bd in ipairs(btns) do
        local bb = self:Create("TextButton", {
            Position = UDim2.new(0, 16 + (i - 1) * 208, 1, -52),
            Size = UDim2.new(0, 196, 0, 36),
            AutoButtonColor = false,
            Font = Library.Font,
            TextSize = 15,
            Text = tostring(bd.Text or "OK"),
            BorderSizePixel = 0,
            ZIndex = 102,
        }, card)
        if bd.Accent then
            self:Themed(bb, "BackgroundColor3", "Accent")
            bb.TextColor3 = Color3.fromRGB(255, 255, 255)
        else
            self:Themed(bb, "BackgroundColor3", "Element2")
            self:Themed(bb, "TextColor3", "Text")
        end
        self:Corner(bb, 6)
        self:Connect(bb.MouseButton1Click, function()
            if type(bd.Callback) == "function" then task.spawn(bd.Callback) end
            dlg:Close()
        end)
        if i >= 2 then break end
    end
    return dlg
end
-- ============================================================
-- [ module: Config.lua ]
-- ============================================================

local function ensureDir(path)
    pcall(function()
        if makefolder and not isfolder(path) then makefolder(path) end
    end)
end

-- Defaults survive re-execution (Header unloads but this table persists on Library).
Library.ConfigIgnore = Library.ConfigIgnore or {
    __cfg_name = true,
    __cfg_list = true,
    __cfg_clipboard = true,
    __autosave_enabled = true,
    __autosave_delay = true,
}
Library.AutoSave = Library.AutoSave or {
    Enabled = false,
    Name = nil,
    Delay = 5,
    _lastJson = nil,
    _dirtySince = nil,
    _running = false,
}

function Library:IsFlagIgnored(flag)
    return self.ConfigIgnore[tostring(flag)] == true
end

function Library:IgnoreFlag(flag)
    self.ConfigIgnore[tostring(flag)] = true
end

function Library:UnignoreFlag(flag)
    self.ConfigIgnore[tostring(flag)] = nil
end

function Library:SetConfigIgnored(flags)
    self.ConfigIgnore = {}
    if type(flags) == "table" then
        if #flags > 0 then
            for _, f in ipairs(flags) do
                self.ConfigIgnore[tostring(f)] = true
            end
        else
            for k, v in pairs(flags) do
                if v then
                    self.ConfigIgnore[tostring(k)] = true
                end
            end
        end
    end
end

local function buildExtraIgnore(extra)
    if extra == nil then return nil end
    if type(extra) == "string" then return { [extra] = true } end
    if type(extra) == "table" then
        local map = {}
        if #extra > 0 then
            for _, f in ipairs(extra) do map[tostring(f)] = true end
        else
            for k, v in pairs(extra) do
                if v then map[tostring(k)] = true end
            end
        end
        return map
    end
    return nil
end

function Library:GetConfig(extraIgnore)
    local extra = buildExtraIgnore(extraIgnore)
    local out = { flags = {}, theme = {} }
    for k, v in pairs(self.Flags) do
        if self.ConfigIgnore[k] or (extra and extra[k]) then
            continue
        end
        local t = typeof(v)
        if t == "Color3" then
            out.flags[k] = { __c3 = true, r = v.R, g = v.G, b = v.B }
        elseif t == "EnumItem" then
            out.flags[k] = { __enum = true, t = tostring(v.EnumType), n = v.Name }
        elseif type(v) == "table" and (v.Key ~= nil or v.Mode ~= nil) and v.Toggled ~= nil then
            out.flags[k] = {
                __key = true,
                key = (typeof(v.Key) == "EnumItem") and v.Key.Name or nil,
                mode = tostring(v.Mode or "Toggle"),
                toggled = v.Toggled and true or false,
            }
        elseif type(v) ~= "function" and type(v) ~= "userdata" then
            local ok, _ = pcall(function() return HttpService:JSONEncode(v) end)
            if ok then out.flags[k] = v end
        end
    end
    for k, v in pairs(self.Theme) do
        if typeof(v) == "Color3" then
            out.theme[k] = { r = v.R, g = v.G, b = v.B }
        end
    end
    if self.BackgroundImage then
        out.background = { image = self.BackgroundImage, transparency = self.BackgroundTransparency }
    end
    local ok, json = pcall(HttpService.JSONEncode, HttpService, out)
    return ok and json or "{}"
end

function Library:LoadConfig(json, opts)
    local extra = nil
    if type(opts) == "table" and opts.Ignore ~= nil then
        extra = buildExtraIgnore(opts.Ignore)
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or type(data) ~= "table" then return false end
    if type(data.theme) == "table" then
        for k, v in pairs(data.theme) do
            if type(v) == "table" and v.r then
                self:ChangeTheme(k, Color3.new(v.r, v.g, v.b))
            end
        end
    end
    if type(data.background) == "table" and data.background.image then
        self:SetBackgroundImage(data.background.image, data.background.transparency)
    end
    if type(data.flags) == "table" then        for k, v in pairs(data.flags) do
            if self.ConfigIgnore[k] or (extra and extra[k]) then
                continue
            end
            if type(v) == "table" and v.__c3 then
                self.Flags[k] = Color3.new(v.r, v.g, v.b)
            elseif type(v) == "table" and v.__enum then
                local okEnum, ev = pcall(function()
                    return Enum[tostring(v.t)][tostring(v.n)]
                end)
                if okEnum and typeof(ev) == "EnumItem" then
                    self.Flags[k] = ev
                else
                    continue
                end
            elseif type(v) == "table" and v.__key then
                local key = nil
                pcall(function()
                    if v.key then key = Enum.KeyCode[v.key] end
                end)
                self.Flags[k] = { Key = key, Mode = tostring(v.mode or "Toggle"), Toggled = v.toggled and true or false }
            else
                self.Flags[k] = v
            end
        end
    end
    self:ApplyFlags(true)
    local sc = tonumber(self.Flags.__uiscale)
    if sc then
        self:SetUIScale(sc)
    end
    if self.Flags.__anim ~= nil then
        self.AnimationsEnabled = self.Flags.__anim and true or false
    end
    if self.Flags.__tooltips ~= nil then
        self.TooltipsEnabled = self.Flags.__tooltips and true or false
    end
    local nd = tonumber(self.Flags.__notifdur)
    if nd then
        self.NotifDuration = math.clamp(nd, 1, 30)
    end
    for _, w in ipairs(self._windows) do
        if w.Watermark and self.Flags.__showwatermark ~= nil then
            w.Watermark:SetVisibility(self.Flags.__showwatermark)
        end
        if w.Watermark and self.Flags.__watermarkstats ~= nil then
            w.Watermark:SetStatsEnabled(self.Flags.__watermarkstats)
        end
        if w.KeybindList and self.Flags.__showkeybinds ~= nil then
            w.KeybindList:SetVisibility(self.Flags.__showkeybinds)
        end
        if w.ToggleButton and self.Flags.__showtogglebtn ~= nil then
            w.ToggleButton:SetVisibility(self.Flags.__showtogglebtn)
        end
    end
    if self.BackgroundImage then
        self:SetBackgroundImage(self.BackgroundImage, self.BackgroundTransparency)
    end
    return true
end

function Library:HasConfig(name)
    name = tostring(name or "")
    if name == "" then return false end
    local path = self.Folders.Configs .. "/" .. name .. ".json"
    local ok, res = pcall(isfile, path)
    if ok then return res == true end
    for _, n in ipairs(self:ListConfigs()) do
        if n == name then return true end
    end
    return false
end

function Library:SaveConfig(name)
    ensureDir(self.Folders.Directory)
    ensureDir(self.Folders.Configs)
    local path = self.Folders.Configs .. "/" .. tostring(name) .. ".json"
    local okJson, json = pcall(function() return self:GetConfig() end)
    if not okJson then return false end
    local ok = pcall(writefile, path, json)
    if ok and self.AutoSave.Enabled and self.AutoSave.Name == tostring(name) then
        self.AutoSave._lastJson = json
        self.AutoSave._dirtySince = nil
    end
    return ok
end

function Library:LoadConfigFile(name, opts)
    local path = self.Folders.Configs .. "/" .. tostring(name) .. ".json"
    local ok, src = pcall(readfile, path)
    if not ok then return false end
    return self:LoadConfig(src, opts)
end

function Library:ListConfigs()
    ensureDir(self.Folders.Configs)
    local ok, files = pcall(listfiles, self.Folders.Configs)
    if not ok or type(files) ~= "table" then return {} end
    local out = {}
    for _, f in ipairs(files) do
        local n = tostring(f):match("([^/\\]+)%.json$")
        if n then table.insert(out, n) end
    end
    table.sort(out)
    return out
end

function Library:SetAutoloadConfig(name)
    ensureDir(self.Folders.Directory)
    pcall(writefile, self.Folders.Directory .. "/autoload.txt", tostring(name or ""))
end

function Library:GetAutoloadConfigName()
    local ok, src = pcall(readfile, self.Folders.Directory .. "/autoload.txt")
    if not ok or type(src) ~= "string" or src == "" then return nil end
    return src
end

function Library:ClearAutoloadConfig()
    pcall(writefile, self.Folders.Directory .. "/autoload.txt", "")
    pcall(delfile, self.Folders.Directory .. "/autoload.txt")
end

function Library:LoadAutoload()
    local name = self:GetAutoloadConfigName()
    if not name then return false end
    return self:LoadConfigFile(name)
end

function Library:DeleteConfig(name)
    local wasAutosave = self.AutoSave.Enabled and self.AutoSave.Name == tostring(name)
    pcall(delfile, self.Folders.Configs .. "/" .. tostring(name) .. ".json")
    if wasAutosave then
        self:DisableAutoSave()
    end
end

-- Clipboard string share. Export returns the same JSON SaveConfig writes;
-- Import loads it. Copy/Paste wrap the executor clipboard when present.
function Library:ExportConfigString(extraIgnore)
    return self:GetConfig(extraIgnore)
end

function Library:ImportConfigString(str, opts)
    if type(str) ~= "string" or str == "" then return false end
    return self:LoadConfig(str, opts)
end

function Library:CopyConfigToClipboard(extraIgnore)
    local json = self:GetConfig(extraIgnore)
    local ok = pcall(setclipboard, json)
    return ok
end

function Library:PasteConfigFromClipboard(opts)
    local ok, clip = pcall(getclipboard)
    if not ok or type(clip) ~= "string" or clip == "" then return false end
    return self:LoadConfig(clip, opts)
end

-- Debounced auto-save. Writes Name every Delay seconds after the last
-- flag change instead of on every callback (callbacks fire per drag tick).
function Library:SetAutoSave(name, delay)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        self:DisableAutoSave()
        return false
    end
    delay = math.clamp(tonumber(delay) or self.AutoSave.Delay or 5, 1, 60)
    self.AutoSave.Enabled = true
    self.AutoSave.Name = name
    self.AutoSave.Delay = delay
    pcall(function()
        self.AutoSave._lastJson = self:GetConfig()
    end)
    self.AutoSave._dirtySince = nil
    if not self.AutoSave._running then
        self.AutoSave._running = true
        self:Thread(function()
            while not self.Unloading do
                task.wait(1)
                if self.Unloading then break end
                if not self.AutoSave.Enabled or not self.AutoSave.Name or self.AutoSave.Name == "" then
                    continue
                end
                local okCur, cur = pcall(function() return self:GetConfig() end)
                if not okCur or type(cur) ~= "string" then
                    continue
                end
                if cur == self.AutoSave._lastJson then
                    self.AutoSave._dirtySince = nil
                else
                    local now = tick()
                    if self.AutoSave._dirtySince == nil then
                        self.AutoSave._dirtySince = now
                    elseif now - self.AutoSave._dirtySince >= (tonumber(self.AutoSave.Delay) or 5) then
                        if self:SaveConfig(self.AutoSave.Name) then
                            -- SaveConfig refreshes _lastJson on success.
                        else
                            -- Retry next tick, keep dirty marker.
                        end
                        self.AutoSave._dirtySince = nil
                    end
                end
            end
            self.AutoSave._running = false
        end)
    end
    return true
end

function Library:DisableAutoSave()
    self.AutoSave.Enabled = false
    self.AutoSave._dirtySince = nil
end

function Library:IsAutoSaveEnabled()
    return self.AutoSave.Enabled == true and self.AutoSave.Name ~= nil and self.AutoSave.Name ~= ""
end

function Library:GetAutoSaveName()
    if self:IsAutoSaveEnabled() then return self.AutoSave.Name end
    return nil
end
-- ============================================================
-- [ module: KeybindList.lua ]
-- ============================================================

function Library:KeybindList(data)
    data = data or {}
    local scale = tonumber(data.Scale) or 1
    if not (scale > 0) then scale = 1 end

    -- Base metrics at scale 1. Wide and short on purpose: a horizontal
    -- rectangle, title bar on top, bound keys in two columns below.
    local kl = { Items = {}, _scale = scale }
    local baseTitle = tostring(data.Title or "Keybinds")
    local dims = {}
    local function measure()
        local s = kl._scale
        dims.width = math.floor(340 * s + 0.5)
        dims.headH = math.max(20, math.floor(28 * s + 0.5))
        dims.headFont = math.max(10, math.floor(14 * s + 0.5))
        dims.rowH = math.max(14, math.floor(18 * s + 0.5))
        dims.rowFont = math.max(9, math.floor(12 * s + 0.5))
        dims.padX = math.max(6, math.floor(10 * s + 0.5))
        dims.gap = math.max(2, math.floor(4 * s + 0.5))
        -- Structured row cells: right block holds "MODE [KEY]" — the bind's
        -- behaviour tag plus the key, so the name gets the remaining room.
        dims.rightW = math.max(120, math.floor(160 * s + 0.5))
        dims.rowPad = math.max(4, math.floor(6 * s + 0.5))
    end
    measure()

    local frame = self:Create("Frame", {
        Name = "KeybindList",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = data.Position or UDim2.new(0, 12, 0.5, 0),
        Size = UDim2.new(0, dims.width, 0, 30),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Visible = data.Visible ~= false,
    }, self.Holder)
    self:Themed(frame, "BackgroundColor3", "Panel")
    self:Corner(frame, 8)
    self:Stroke(frame, 1, "OutlineSoft")

    -- Title header, top-left.
    local head = self:Create("TextLabel", {
        Position = UDim2.new(0, dims.padX, 0, 0),
        Size = UDim2.new(1, -dims.padX * 2, 0, dims.headH),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = dims.headFont,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Title or "Keybinds"),
    }, frame)
    self:Themed(head, "TextColor3", "Text")

    local div = self:Create("Frame", {
        Position = UDim2.new(0, 0, 0, dims.headH),
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
    }, frame)
    self:Themed(div, "BackgroundColor3", "Accent")

    -- Entry area: full-width rows (one column), so each
    -- | name | STATE - [KEY] | row has room to breathe.
    local list = self:Create("Frame", {
        Position = UDim2.new(0, dims.padX, 0, dims.headH + 6),
        Size = UDim2.new(1, -dims.padX * 2, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, frame)
    local col = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, list)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, dims.gap),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, col)
    self:Drag(frame, head)

    kl.Items = { Frame = frame, List = list }

    local function applyMetrics()
        measure()
        frame.Size = UDim2.new(0, dims.width, 0, 30)
        head.Position = UDim2.new(0, dims.padX, 0, 0)
        head.Size = UDim2.new(1, -dims.padX * 2, 0, dims.headH)
        head.TextSize = dims.headFont
        div.Position = UDim2.new(0, 0, 0, dims.headH)
        div.Size = UDim2.new(1, 0, 0, 2)
        list.Position = UDim2.new(0, dims.padX, 0, dims.headH + 6)
        list.Size = UDim2.new(1, -dims.padX * 2, 0, 10)
        for _, kid in ipairs(col:GetChildren()) do
            if kid:IsA("UIListLayout") then
                kid.Padding = UDim.new(0, dims.gap)
            end
        end
    end

    function kl:Refresh()
        for _, c in ipairs(col:GetChildren()) do
            if c.Name == "KBRow" or c:IsA("TextLabel") then c:Destroy() end
        end
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        local rows = {}
        for _, kb in ipairs(Library._keybinds) do
            if type(kb.GetParts) == "function" then
                local ok, parts = pcall(kb.GetParts, kb)
                if ok and type(parts) == "table" then
                    rows[#rows + 1] = parts
                end
            elseif type(kb.GetText) == "function" then
                local ok, text, on = pcall(kb.GetText, kb)
                if ok and text then
                    rows[#rows + 1] = { legacy = tostring(text), on = on and true or false }
                end
            end
        end
        if #rows == 0 then
            head.Text = baseTitle .. " (0)"
            local row = Library:Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, dims.rowH),
                BackgroundTransparency = 1,
                Font = Enum.Font.Code,
                TextSize = dims.rowFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "none bound",
            }, list)
            Library:Themed(row, "TextColor3", "TextMuted")
            return
        end
        head.Text = baseTitle .. " (" .. #rows .. ")"
        -- Row anatomy: status dot | name | chip (MODE [KEY]).
        -- The chip lights up (Surface bg + Accent text) while the bind is
        -- ON and sinks to flat muted text while OFF.
        local function addRow(col, order, r)
            if r.legacy then
                local row = Library:Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, dims.rowH),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Code,
                    TextSize = dims.rowFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = r.legacy,
                    LayoutOrder = order,
                }, col)
                Library:Themed(row, "TextColor3", r.on and "Text" or "TextMuted")
                return
            end
            local pad, rightW = dims.rowPad, dims.rightW
            local rowF = Library:Create("Frame", {
                Name = "KBRow",
                Size = UDim2.new(1, 0, 0, dims.rowH),
                BackgroundTransparency = 1,
                LayoutOrder = order,
            }, col)
            local dot = Library:Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, pad, 0.5, 0),
                Size = UDim2.new(0, 6, 0, 6),
                BorderSizePixel = 0,
                BackgroundColor3 = r.on and Color3.fromRGB(90, 255, 110) or Color3.fromRGB(110, 110, 120),
            }, rowF)
            Library:Corner(dot, 3)
            local nameL = Library:Create("TextLabel", {
                Position = UDim2.new(0, pad + 12, 0, 0),
                Size = UDim2.new(1, -(rightW + pad * 2 + 14), 1, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Font = Enum.Font.Code,
                TextSize = dims.rowFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(r.name),
            }, rowF)
            Library:Themed(nameL, "TextColor3", r.on and "Text" or "TextMuted")
            local chip = Library:Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, rightW, 0, dims.rowH),
                BorderSizePixel = 0,
                BackgroundTransparency = r.on and 0 or 0.6,
            }, rowF)
            Library:Themed(chip, "BackgroundColor3", "Surface")
            Library:Corner(chip, 0)
            Library:Stroke(chip, 1)
            local rightL = Library:Create("TextLabel", {
                Position = UDim2.new(0, 4, 0, 0),
                Size = UDim2.new(1, -8, 1, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Font = Enum.Font.Code,
                TextSize = dims.rowFont,
                TextXAlignment = Enum.TextXAlignment.Right,
                Text = tostring(r.mode) .. " [" .. tostring(r.key) .. "]",
            }, chip)
            Library:Themed(rightL, "TextColor3", r.on and "Accent" or "TextMuted")
        end
        -- Top-to-bottom, one full-width row per bind.
        for i, r in ipairs(rows) do
            addRow(col, i, r)
        end
    end

    function kl:SetVisibility(v)
        frame.Visible = v and true or false
    end

    function kl:SetPosition(pos)
        if typeof(pos) == "UDim2" then frame.Position = pos end
    end

    function kl:SetScale(s)
        s = tonumber(s)
        if not (s and s > 0) then return kl end
        kl._scale = math.clamp(s, 0.5, 3)
        applyMetrics()
        kl:Refresh()
        return kl
    end

    function kl:GetScale() return kl._scale end

    kl:Refresh()
    return kl
end

function Library:_pushKeybindList()
    for _, w in ipairs(self._windows) do
        if w.KeybindList then
            pcall(function() w.KeybindList:Refresh() end)
        end
    end
end
-- ============================================================
-- [ module: ESPPreview.lua ]
-- ============================================================

-- ESP preview panel: a floating window (KeybindList chrome) that mirrors the
-- live LocalPlayer character into a ViewportFrame and draws flag-driven ESP
-- overlays on top of it. The character animates like the player because every
-- limb CFrame is copied from the real rig each RenderStepped — the clone runs
-- zero scripts.
--
-- Flag contract (data.Flags):
--   Enabled  = flag (boolean or any value the user's ESP toggles)
--   Box, Skeleton, Tracer, Name, Health, Distance = toggle flags
--   Chams    = toggle flag (or a second color flag, see ChamsColor)
--   Color    = colorpicker flag (box/tracer/skeleton/name tint)
--
-- Overlays are positioned with a manual pinhole projection of the viewport
-- camera; the stub Camera's WorldToViewportPoint does not track ViewportFrame
-- sizing, so the math is done here and the viewport camera only carries CFrame
-- and FieldOfView.

function Library:ESPPreview(data)
    data = data or {}
    local scale = math.clamp(tonumber(data.Scale) or 1, 0.5, 3)
    local flags = data.Flags or {}

    local function readFlag(name, kind)
        local f = flags[name]
        if f == nil or f == "" then return nil end
        local v = self.Flags[f]
        if v == nil then return nil end
        if kind == "color" then
            return typeof(v) == "Color3" and v or nil
        elseif kind == "number" then
            return tonumber(v)
        end
        return v and true or false
    end
    local function on(name)
        return readFlag(name) and true or false
    end

    local dims = {
        width = 240, headH = 24, footH = 18, bodyH = 250, font = 12, pad = 8,
    }
    local function applyScale(s)
        dims.width = math.floor(240 * s + 0.5)
        dims.headH = math.max(20, math.floor(24 * s + 0.5))
        dims.footH = math.max(16, math.floor(18 * s + 0.5))
        dims.bodyH = math.floor(250 * s + 0.5)
        dims.font = math.max(9, math.floor(12 * s + 0.5))
        dims.pad = math.max(4, math.floor(8 * s + 0.5))
    end
    applyScale(scale)

    -- Floating panel, same chrome family as the KeybindList.
    local root = self:Create("Frame", {
        Name = "ESPPreview",
        Position = data.Position or UDim2.new(1, -(dims.width + 218), 0, 60),
        Size = UDim2.new(0, dims.width, 0, dims.headH + dims.bodyH + dims.footH + 7),
        BorderSizePixel = 0,
        Active = true,
    }, self.Holder)
    self:Themed(root, "BackgroundColor3", "Panel")
    self:Corner(root, 8)
    self:Stroke(root, 1, "OutlineSoft")

    local head = self:Create("TextLabel", {
        Position = UDim2.new(0, dims.pad, 0, 0),
        Size = UDim2.new(1, -dims.pad * 2, 0, dims.headH),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = dims.font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Title or "ESP Preview"),
    }, root)
    self:Themed(head, "TextColor3", "Text")

    local div = self:Create("Frame", {
        Position = UDim2.new(0, dims.pad, 0, dims.headH),
        Size = UDim2.new(1, -dims.pad * 2, 0, 1),
        BorderSizePixel = 0,
    }, root)
    self:Themed(div, "BackgroundColor3", "OutlineSoft")

    -- Viewport body. Overlay is a child of the view, so its coordinates are
    -- the viewport's pixel space directly.
    local view = self:Create("ViewportFrame", {
        Position = UDim2.new(0, dims.pad, 0, dims.headH + 6),
        Size = UDim2.new(1, -dims.pad * 2, 0, dims.bodyH),
        BorderSizePixel = 0,
    }, root)
    self:Themed(view, "BackgroundColor3", "Background")
    local world = Instance.new("WorldModel")
    world.Parent = view

    local overlay = self:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, view)

    local foot = self:Create("TextLabel", {
        Position = UDim2.new(0, dims.pad, 1, -dims.footH),
        Size = UDim2.new(1, -dims.pad * 2, 0, dims.footH),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = math.max(8, dims.font - 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "no character",
    }, root)
    self:Themed(foot, "TextColor3", "TextMuted")

    self:Drag(root, head)

    -- ------------------------------------------------------------------
    -- Overlay constructs. Created once, driven per-frame by projection.
    -- ------------------------------------------------------------------
    -- Vertical strip whose height is set per line; rotated about its center.
    -- a/b are viewport-space Vector2; thickness is 1px.
    local function makeStrip()
        local f = self:Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 1, 0, 1),
            BorderSizePixel = 0,
            Visible = false,
        }, overlay)
        return f
    end
    local function placeStrip(f, a, b, color)
        local d = b - a
        if d.Magnitude < 1.5 then
            f.Visible = false
            return
        end
        f.Visible = true
        f.Position = UDim2.new(0, (a.X + b.X) * 0.5, 0, (a.Y + b.Y) * 0.5)
        f.Size = UDim2.new(0, 1, 0, d.Magnitude)
        f.Rotation = math.deg(math.atan2(-d.X, d.Y))
        f.BackgroundColor3 = color
    end

    local boxL, boxR = makeStrip(), makeStrip()
    local boxT, boxB = makeStrip(), makeStrip()
    local tracer = makeStrip()
    local skeleton = {}
    for _ = 1, 14 do
        skeleton[#skeleton + 1] = makeStrip()
    end

    -- Vertical health bar, left of the box.
    local hpTrack = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Visible = false,
    }, overlay)
    self:Themed(hpTrack, "BackgroundColor3", "Inline")
    local hpFill = self:Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
    }, hpTrack)

    local nameL = self:Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = dims.font,
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
    }, overlay)
    local distL = self:Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = math.max(8, dims.font - 2),
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
    }, overlay)
    self:Themed(distL, "TextColor3", "TextMuted")

    local green = Color3.fromRGB(90, 255, 110)
    local red = Color3.fromRGB(255, 60, 60)

    -- ------------------------------------------------------------------
    -- Character mirror.
    -- ------------------------------------------------------------------
    local Players = game:GetService("Players")
    local charRef = nil          -- live character instance
    local clone = nil            -- preview clone in the WorldModel
    local cloneParts = nil       -- [name] -> clone BasePart
    local liveParts = nil        -- [name] -> live BasePart
    local chams = nil            -- Highlight on the clone
    local charName = nil

    -- Target selection: nil defaults to LocalPlayer.Character. Also accepts
    -- a Model, a Player (follows their .Character), or a function returning
    -- either (re-resolved every poll, so "follow my aim target" modes work).
    local targetOverride = data.Target
    local function resolveTarget()
        local t = targetOverride
        if type(t) == "function" then
            local ok, v = pcall(t)
            if ok then t = v else t = nil end
        end
        if typeof(t) == "Instance" then
            if t:IsA("Player") then t = t.Character end
            if typeof(t) == "Instance" and t.Parent then return t end
            return nil
        end
        local char = Players.LocalPlayer.Character
        return (typeof(char) == "Instance" and char.Parent) and char or nil
    end

    local function clearOverlays()
        for _, f in ipairs({ boxL, boxR, boxT, boxB, tracer, hpTrack, nameL, distL }) do
            f.Visible = false
        end
        for _, l in ipairs(skeleton) do
            l.Visible = false
        end
    end

    local function buildMirror()
        local char = resolveTarget()
        if clone then
            clone:Destroy()
            clone, cloneParts, liveParts = nil, nil, nil
        end
        charRef = (typeof(char) == "Instance" and char.Parent) and char or nil
        charName = charRef and charRef.Name or nil
        clearOverlays()
        if not charRef then
            foot.Text = "no character"
            return
        end
        local ok, c = pcall(function()
            charRef.Archivable = true
            return charRef:Clone()
        end)
        if not ok or typeof(c) ~= "Instance" then
            foot.Text = "mirror failed"
            return
        end
        -- Scripts AND the Humanoid die: nothing in the clone may evaluate or
        -- simulate. All parts get anchored, so the manual CFrame mirror is
        -- the only thing that can move them (with a Humanoid present, the
        -- WorldModel physics step would fight the mirror and the puppet
        -- would sag or drift).
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BaseScript") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                d:Destroy()
            elseif d:IsA("Humanoid") then
                d:Destroy()
            end
        end
        clone = c
        cloneParts, liveParts = {}, {}
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Anchored = true
                cloneParts[p.Name] = p
            end
        end
        for _, p in ipairs(charRef:GetDescendants()) do
            if p:IsA("BasePart") then
                liveParts[p.Name] = p
            end
        end
        if chams then chams:Destroy() end
        chams = Instance.new("Highlight")
        chams.FillTransparency = 0.55
        chams.OutlineTransparency = 0
        chams.Enabled = false
        chams.Parent = c
        c.Parent = world
        foot.Text = "preview · " .. tostring(charName or "?")
    end

    self:Connect(Players.LocalPlayer.CharacterAdded, function()
        task.defer(buildMirror)
    end)
    self:Connect(Players.LocalPlayer.CharacterRemoving, function()
        charRef, clone, cloneParts, liveParts = nil, nil, nil, nil
        if chams then chams:Destroy() chams = nil end
        clearOverlays()
        foot.Text = "no character"
    end)
    -- Late characters + target switches: rebuild whenever the resolved
    -- target instance changes (respawn, dropdown switch, aim target swap).
    self:Thread(function()
        while not self.Unloading do
            task.wait(1.5)
            if self.Unloading then break end
            local ch = resolveTarget()
            if ch ~= charRef then
                buildMirror()
            elseif (not clone) and ch then
                buildMirror()
            end
        end
    end)

    -- ------------------------------------------------------------------
    -- Skeleton topology, resolved by part name against the mirror maps. Rig
    -- type comes from the LIVE character (the clone carries no Humanoid).
    -- ------------------------------------------------------------------
    local function rigPairs()
        local hum = charRef and charRef:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        if hum.RigType == Enum.HumanoidRigType.R15 then
            return {
                { "Head", "UpperTorso" },
                { "UpperTorso", "LowerTorso" },
                { "UpperTorso", "LeftUpperArm" },
                { "UpperTorso", "RightUpperArm" },
                { "LeftUpperArm", "LeftLowerArm" },
                { "RightUpperArm", "RightLowerArm" },
                { "LeftLowerArm", "LeftHand" },
                { "RightLowerArm", "RightHand" },
                { "LowerTorso", "LeftUpperLeg" },
                { "LowerTorso", "RightUpperLeg" },
                { "LeftUpperLeg", "LeftLowerLeg" },
                { "RightUpperLeg", "RightLowerLeg" },
                { "LeftLowerLeg", "LeftFoot" },
                { "RightLowerLeg", "RightFoot" },
            }
        end
        return {
            { "Head", "Torso" },
            { "Torso", "Left Arm" },
            { "Torso", "Right Arm" },
            { "Torso", "Left Leg" },
            { "Torso", "Right Leg" },
        }
    end

    -- ------------------------------------------------------------------
    -- Viewport camera + projection.
    -- ------------------------------------------------------------------
    local camCF = CFrame.new(0, 5, -20)
    local cam = Instance.new("Camera")
    cam.CFrame = camCF
    cam.FieldOfView = 55
    cam.Parent = view
    view.CurrentCamera = cam

    local FOV = 55
    -- Returns nx, ny (viewport pixels) or nil when behind camera.
    local function project(worldPos)
        local lp = camCF:PointToObjectSpace(worldPos)
        if lp.Z >= -0.1 then return nil end
        local size = view.AbsoluteSize
        if size.X < 8 or size.Y < 8 then return nil end
        local f = 0.5 / math.tan(math.rad(FOV) * 0.5)
        return size.X * 0.5 + (lp.X / -lp.Z) * f * size.Y,
            size.Y * 0.5 - (lp.Y / -lp.Z) * f * size.Y
    end

    -- ------------------------------------------------------------------
    -- Per-frame pass.
    -- ------------------------------------------------------------------
    local function frameLoop()
        if not clone or not clone.Parent or not charRef then
            clearOverlays()
            return
        end
        local liveHrp = charRef:FindFirstChild("HumanoidRootPart")
        local cloneHrp = cloneParts and cloneParts.HumanoidRootPart
        if not liveHrp or not cloneHrp then
            clearOverlays()
            return
        end

        -- Mirror every limb CFrame (live pose -> preview pose).
        for name, part in pairs(cloneParts) do
            local lp2 = liveParts[name]
            if lp2 then
                pcall(function()
                    part.CFrame = lp2.CFrame
                end)
            end
        end

        -- Camera: fixed-back view, tall enough to frame the whole rig.
        local ext = clone:GetExtentsSize()
        local dist = math.max(6, ext.Y * 2.2)
        camCF = CFrame.lookAt(
            liveHrp.Position + Vector3.new(0, ext.Y * 0.05, -dist),
            liveHrp.Position
        )
        cam.CFrame = camCF

        clearOverlays() -- redraw below
        local size = view.AbsoluteSize
        if size.X < 8 or size.Y < 8 then return end

        local espOn = on("Enabled")
        local espColor = readFlag("Color", "color") or Library.Theme.Accent
        local chamColor = readFlag("ChamsColor", "color") or espColor

        -- Chams ride the highlight regardless of box geometry.
        if chams then
            chams.Enabled = espOn and on("Chams")
            chams.FillColor = chamColor
            chams.OutlineColor = espColor
        end
        if not espOn then return end

        local sx, sy = project(liveHrp.Position)
        if not sx then return end
        local halfY = ext.Y * 0.5
        local tx, ty = project(liveHrp.Position + Vector3.new(0, halfY, 0))
        local bx, by = project(liveHrp.Position - Vector3.new(0, halfY, 0))

        -- Tracer first: bottom-center of the panel to the feet (not the head).
        if on("Tracer") then
            local fx, fy = (bx and bx or sx), (by and by or sy)
            if fx then
                placeStrip(tracer, Vector2.new(size.X * 0.5, size.Y - 1), Vector2.new(fx, fy), espColor)
            end
        end

        if tx and bx then
            local cx = (tx + bx) * 0.5
            local topY = ty - 3
            local botY = by + 3
            local h = math.abs(botY - topY)
            if h > 8 then
                -- Box: four 1px edges around the player.
                if on("Box") then
                    local w = h * 0.45
                    placeStrip(boxL, Vector2.new(cx - w * 0.5, topY), Vector2.new(cx - w * 0.5, botY), espColor)
                    placeStrip(boxR, Vector2.new(cx + w * 0.5, topY), Vector2.new(cx + w * 0.5, botY), espColor)
                    placeStrip(boxT, Vector2.new(cx - w * 0.5, topY), Vector2.new(cx + w * 0.5, topY), espColor)
                    placeStrip(boxB, Vector2.new(cx - w * 0.5, botY), Vector2.new(cx + w * 0.5, botY), espColor)
                end

                -- Health bar left of the box, straight from live hp.
                -- Standalone: needs the box geometry, not the Box toggle.
                if on("Health") then
                    local liveHum = charRef:FindFirstChildOfClass("Humanoid")
                    local hpMax = liveHum and math.max(1, liveHum.MaxHealth) or 100
                    local hp = liveHum and math.clamp(liveHum.Health / hpMax, 0, 1) or 1
                    local w = h * 0.45
                    hpTrack.Size = UDim2.new(0, 5, 0, h)
                    hpTrack.Position = UDim2.new(0, cx - w * 0.5 - 5, 0, (topY + botY) * 0.5)
                    hpFill.Size = UDim2.new(1, 0, hp, 0)
                    hpFill.BackgroundColor3 = green:Lerp(red, 1 - hp)
                    hpTrack.Visible = true
                end

                -- Name above the box.
                if on("Name") then
                    nameL.Visible = true
                    nameL.TextSize = dims.font
                    nameL.Position = UDim2.new(0, cx, 0, topY - dims.font - 2)
                    nameL.TextColor3 = espColor
                    nameL.Text = tostring(data.NameText or charName or "Player")
                end

                -- Distance under the box, measured to the real camera.
                if on("Distance") then
                    local wcam = workspace.CurrentCamera
                    if typeof(wcam) == "Instance" then
                        local d = (wcam.CFrame.Position - liveHrp.Position).Magnitude
                        distL.Visible = true
                        distL.Position = UDim2.new(0, cx, 0, botY + 3)
                        distL.Text = math.floor(d + 0.5) .. " m"
                    end
                end
            end
        end

        -- Skeleton.
        local pairsList = rigPairs()
        if pairsList and on("Skeleton") then
            for i, l in ipairs(skeleton) do
                local pr = pairsList[i]
                if not pr then break end
                local pa = cloneParts[pr[1]]
                local pb = cloneParts[pr[2]]
                if pa and pb then
                    local sxa, sya = project(pa.Position)
                    local sxb, syb = project(pb.Position)
                    if sxa and sxb then
                        placeStrip(l, Vector2.new(sxa, sya), Vector2.new(sxb, syb), espColor)
                    end
                end
            end
        end
    end

    self:Connect(RunService.RenderStepped, frameLoop)

    -- ------------------------------------------------------------------
    -- Foot strip: character + active feature count, cheap 0.5s poll.
    -- ------------------------------------------------------------------
    self:Thread(function()
        while not self.Unloading do
            task.wait(0.5)
            if self.Unloading then break end
            pcall(function()
                local n = 0
                for k in pairs(flags) do
                    if k ~= "Color" and k ~= "ChamsColor" and k ~= "Enabled" and on(k) then
                        n = n + 1
                    end
                end
                local base = (charName and ("preview · " .. charName)) or "no character"
                foot.Text = base .. " · " .. n .. " active"
            end)
        end
    end)

    local ep = { _scale = scale }
    function ep:SetTarget(t)
        targetOverride = t
        buildMirror()
        return ep
    end
    function ep:GetTarget() return resolveTarget() end
    function ep:SetVisibility(v)
        root.Visible = v and true or false
    end
    function ep:SetPosition(pos)
        if typeof(pos) == "UDim2" then root.Position = pos end
    end
    function ep:SetFlags(map)
        if type(map) == "table" then
            for k, v in pairs(map) do flags[k] = v end
        end
        return ep
    end
    function ep:SetScale(s)
        s = tonumber(s)
        if not (s and s > 0) then return ep end
        ep._scale = math.clamp(s, 0.5, 3)
        applyScale(ep._scale)
        root.Size = UDim2.new(0, dims.width, 0, dims.headH + dims.bodyH + dims.footH + 7)
        head.Position = UDim2.new(0, dims.pad, 0, 0)
        head.Size = UDim2.new(1, -dims.pad * 2, 0, dims.headH)
        head.TextSize = dims.font
        div.Position = UDim2.new(0, dims.pad, 0, dims.headH)
        div.Size = UDim2.new(1, -dims.pad * 2, 0, 1)
        view.Position = UDim2.new(0, dims.pad, 0, dims.headH + 6)
        view.Size = UDim2.new(1, -dims.pad * 2, 0, dims.bodyH)
        foot.Position = UDim2.new(0, dims.pad, 1, -dims.footH)
        foot.Size = UDim2.new(1, -dims.pad * 2, 0, dims.footH)
        foot.TextSize = math.max(8, dims.font - 2)
        nameL.TextSize = dims.font
        distL.TextSize = math.max(8, dims.font - 2)
        return ep
    end
    function ep:GetScale() return ep._scale end
    function ep:GetInstance() return root end

    ep:SetScale(scale)
    buildMirror()
    return ep
end
-- ============================================================
-- [ module: ToggleButton.lua ]
-- ============================================================

function Library:ToggleButton(window, data)
    data = data or {}
    local btn = self:Create("TextButton", {
        Name = "DWToggle",
        Position = data.Position or UDim2.new(0, 16, 0.5, -18),
        Size = data.Size or UDim2.new(0, 36, 0, 36),
        AutoButtonColor = false,
        Font = Library.Font,
        TextSize = 16,
        Text = "D",
        BorderSizePixel = 0,
    }, self.Holder)
    self:Themed(btn, "BackgroundColor3", "Element")
    self:Themed(btn, "TextColor3", "Accent")
    self:Corner(btn, 0)
    self:Stroke(btn, 1)
    self:Drag(btn)

    local tb = {}
    function tb:Press()
        window:SetOpen(not window.IsOpen)
    end
    function tb:SetVisibility(v)
        btn.Visible = v and true or false
    end
    function tb:SetPosition(pos)
        if typeof(pos) == "UDim2" then btn.Position = pos end
    end
    self:Connect(btn.MouseButton1Click, function() tb:Press() end)
    return tb
end
-- ============================================================
-- [ module: HomePage.lua ]
-- ============================================================

function Library:CreateHomePage(window, opts)
    if window.HomePage then
        return window.HomePage
    end
    if type(opts) ~= "table" then opts = {} end

    local page = self:Page(window, { Name = opts.tabName or "Home", Icon = opts.icon or "house", IsSystem = true }, 1, nil)
    page.Items.Left.Visible = false
    page.Items.Right.Visible = false

    local holder = page.Items.Holder
    local scroll = self:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, holder)
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 8),
    }, scroll)

    -- Card 1: welcome banner.
    local banner = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, scroll)
    self:Themed(banner, "BackgroundColor3", "Panel")
    self:Corner(banner, 0)
    self:Stroke(banner, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, banner)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, banner)

    -- Welcome row with live stats on the right.
    local top = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, banner)
    local avatar = self:Create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 40),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    }, top)
    self:Corner(avatar, 0)
    local avatarRing = self:Stroke(avatar, 1, "Outline")
    task.spawn(function()
        pcall(function()
            local me = Players.LocalPlayer
            if me then
                avatar.Image = Players:GetUserThumbnailAsync(
                    me.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end
        end)
    end)
    local welcome = self:Create("TextLabel", {
        Position = UDim2.new(0, 50, 0, 1),
        Size = UDim2.new(0, 300, 0, 13),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Welcome back,",
    }, top)
    self:Themed(welcome, "TextColor3", "TextMuted")
    local who = self:Create("TextLabel", {
        Position = UDim2.new(0, 50, 0, 14),
        Size = UDim2.new(0, 300, 0, 20),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Player",
    }, top)
    self:Themed(who, "TextColor3", "Text")
    local sub2 = self:Create("TextLabel", {
        Position = UDim2.new(0, 50, 0, 34),
        Size = UDim2.new(0, 300, 0, 13),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(opts.subtitle or "#1 Script HUB"),
    }, top)
    self:Themed(sub2, "TextColor3", "TextMuted")

    local statValues = {}
    local function statCell(parent, label, iconName, order)
        local cell = self:Create("Frame", {
            Size = UDim2.new(0.25, -6, 0, 38),
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, parent)
        self:Themed(cell, "BackgroundColor3", "Panel")
        self:Corner(cell, 0)
        self:Stroke(cell, 1, "OutlineSoft")
        local iconImg = self:GetIcon(iconName)
        if iconImg then
            local ic = self:Create("ImageLabel", {
                Position = UDim2.new(0, 10, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = iconImg,
                ScaleType = Enum.ScaleType.Fit,
            }, cell)
            self:Themed(ic, "ImageColor3", "Accent")
        end
        local l = self:Create("TextLabel", {
            Size = UDim2.new(1, -38, 0, 12),
            Position = UDim2.new(0, 30, 0, 5),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = label,
        }, cell)
        self:Themed(l, "TextColor3", "TextMuted")
        local v = self:Create("TextLabel", {
            Position = UDim2.new(0, 30, 0, 18),
            Size = UDim2.new(1, -38, 0, 16),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "--",
        }, cell)
        self:Themed(v, "TextColor3", "Text")
        statValues[label] = v
    end
    -- Card 2: one line of stat pills (standalone, no card behind them).
    local statsStrip = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    }, scroll)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, statsStrip)
    statCell(statsStrip, "Players", "users", 1)
    statCell(statsStrip, "Ping", "wifi", 2)
    statCell(statsStrip, "FPS", "gauge", 3)
    statCell(statsStrip, "Uptime", "timer", 4)

    local frames = 0
    self:Connect(RunService.RenderStepped, function()
        frames = frames + 1
    end)
    local bootTick = tick()
    self:Thread(function()
        while not self.Unloading do
            task.wait(1)
            if self.Unloading then break end
            local fps = frames
            frames = 0
            local up = math.floor(tick() - bootTick)
            local upText = (math.floor(up / 60) > 0 and (math.floor(up / 60) .. "m ") or "") .. (up % 60) .. "s"
            local ping = nil
            pcall(function()
                ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000 + 0.5)
            end)
            local count, max = nil, nil
            pcall(function()
                count = #Players:GetPlayers()
                max = Players.MaxPlayers
            end)
            pcall(function()
                if statValues.Players.Parent then
                    statValues.Players.Text = (count and max) and (count .. "/" .. max) or "--"
                end
                if statValues.FPS.Parent then statValues.FPS.Text = tostring(fps) end
                if statValues.Ping.Parent then statValues.Ping.Text = ping and (ping .. "ms") or "--" end
                if statValues.Uptime.Parent then statValues.Uptime.Text = upText end
            end)
        end
    end)

    -- Card 3: credits + game info as two separated sub-cards.
    local infoCard = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    }, scroll)
    self:Themed(infoCard, "BackgroundColor3", "Panel")
    self:Corner(infoCard, 0)
    self:Stroke(infoCard, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, infoCard)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, infoCard)

    local infoRow = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, infoCard)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, infoRow)

    local function colTitle(parent, text)
        local row = self:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
        }, parent)
        local t = self:Create("TextLabel", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(text),
        }, row)
        self:Themed(t, "TextColor3", "Text")
        return t
    end

    local function colLine(parent, text)
        local l = self:Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(text),
        }, parent)
        self:Themed(l, "TextColor3", "TextMuted")
        return l
    end

    local leftCol = self:Create("Frame", {
        Size = UDim2.new(0.5, -5, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, infoRow)
    self:Themed(leftCol, "BackgroundColor3", "Panel")
    self:Corner(leftCol, 0)
    self:Stroke(leftCol, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, leftCol)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, leftCol)
    colTitle(leftCol, "Credits")
    for _, creditLine in ipairs(opts.credits or { "Lead Dev: DROIDWARE", "UI Library: DWLib V1" }) do
        colLine(leftCol, creditLine)
    end

    local rightCol = self:Create("Frame", {
        Size = UDim2.new(0.5, -5, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, infoRow)
    self:Themed(rightCol, "BackgroundColor3", "Panel")
    self:Corner(rightCol, 0)
    self:Stroke(rightCol, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, rightCol)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, rightCol)
    colTitle(rightCol, "Game Info")
    -- Prefer an explicit override, otherwise resolve the real game name from
    -- the marketplace and fall back to the window branding while it loads.
    if type(opts.gameName) == "string" and opts.gameName ~= "" then
        colLine(rightCol, "Game: " .. opts.gameName)
    else
        local fallback = window.SubName
        if type(fallback) ~= "string" or fallback == "" then fallback = window.Name end
        local gameLine = colLine(rightCol, "Game: " .. tostring(fallback))
        task.spawn(function()
            local ok, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            end)
            local resolved = nil
            if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
                resolved = info.Name
            elseif type(game.Name) == "string" and game.Name ~= "" then
                resolved = game.Name
            end
            if resolved then
                pcall(function()
                    if gameLine.Parent then
                        gameLine.Text = "Game: " .. resolved
                    end
                end)
            end
        end)
    end
    colLine(rightCol, "Place ID: " .. tostring(game.PlaceId))
    colLine(rightCol, "Game ID: " .. tostring(game.GameId))
    colLine(rightCol, "Job ID: " .. tostring(game.JobId))
    local discord = tostring(opts.discordLink or "")
    local fakeSection = { Items = { List = rightCol }, Window = window, Page = page }
    self.Sections.Button(fakeSection, {
        Name = "Copy Discord",
        Callback = function()
            if discord ~= "" then
                local ok = pcall(setclipboard, discord)
                self:Notification("Discord", ok and "Link copied!" or discord, 3)
            else
                self:Notification("Discord", "No link set.", 3)
            end
        end,
    })

    window.HomePage = page
    return page, statValues
end
-- ============================================================
-- [ module: SettingsPage.lua ]
-- ============================================================

function Library:CreateSettingsPage(window)
    if window.SettingsPage then
        return window.SettingsPage
    end
    local page = self:Page(window, { Name = "Settings", Icon = "settings", IsSystem = true })
    -- System page like Home: sections live directly on the tab, no sub-tabs.
    local sec = self:Section(page, { Name = "Interface" })

    local menuRow = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
    }, sec.Items.List)
    local menuLbl = self:Create("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Menu key",
    }, menuRow)
    self:Themed(menuLbl, "TextColor3", "Text")
    local menuBtn = self:Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 100, 0, 22),
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        TextSize = 12,
        BorderSizePixel = 0,
    }, menuRow)
    self:Themed(menuBtn, "BackgroundColor3", "Surface")
    self:Themed(menuBtn, "TextColor3", "Text")
    self:Corner(menuBtn, 0)
    self:Stroke(menuBtn, 1)
    local menuPicking = false
    local function menuPaint()
        menuBtn.Text = menuPicking and "[...]" or ("[" .. tostring(self.MenuKey):gsub("Enum.KeyCode.", "") .. "]")
    end
    menuPaint()
    self:Connect(menuBtn.MouseButton1Click, function()
        menuPicking = true
        menuPaint()
    end)
    self:Connect(UserInputService.InputBegan, function(input, gpe)
        if menuPicking and input.UserInputType == Enum.UserInputType.Keyboard then
            menuPicking = false
            self:SetMenuKeybind(input.KeyCode)
            self.Flags.__menukey = input.KeyCode.Name
            menuPaint()
        end
    end)
    self:TrackWidget("__menukey", function()
        local name = self.Flags.__menukey
        if type(name) == "string" and Enum.KeyCode[name] then
            self:SetMenuKeybind(Enum.KeyCode[name])
            menuPaint()
        end
    end)
    sec:Toggle({
        Name = "Keybind list",
        Flag = "__showkeybinds",
        Default = window.KeybindList ~= nil,
        Callback = function(v)
            if window.KeybindList then
                window.KeybindList:SetVisibility(v)
            end
        end,
    })
    if window.Watermark then
        sec:Toggle({
            Name = "Watermark",
            Flag = "__showwatermark",
            Default = true,
            Callback = function(v)
                if window.Watermark then
                    window.Watermark:SetVisibility(v)
                end
            end,
        })
        sec:Toggle({
            Name = "Watermark stats",
            Flag = "__watermarkstats",
            Default = window.Watermark.ShowStats ~= false,
            Callback = function(v)
                if window.Watermark then
                    window.Watermark:SetStatsEnabled(v)
                end
            end,
        })
    else
        sec:AddLabel("Watermark: disabled at boot")
    end
    if window.ToggleButton then
        sec:Toggle({
            Name = "Toggle button",
            Flag = "__showtogglebtn",
            Default = true,
            Callback = function(v)
                if window.ToggleButton then
                    window.ToggleButton:SetVisibility(v)
                end
            end,
        })
    end
    -- Element scales live together in their own section: window chrome,
    -- keybind list, watermark.
    local uiElements = self:Section(page, { Name = "UI Elements" })
    uiElements:Slider({
        Name = "UI Scale",
        Flag = "__uiscale",
        Min = 0.75,
        Max = 1.5,
        Default = 1,
        Decimals = 0.05,
        Suffix = "x",
        Live = false,
        Preview = function(v)
            self:PreviewUIScale(v)
        end,
        Callback = function(v)
            self:SetUIScale(v)
        end,
    })
    if window.KeybindList then
        uiElements:Slider({
            Name = "Keybind list scale",
            Flag = "__kblistscale",
            Min = 0.5,
            Max = 3,
            Default = window.KeybindList:GetScale(),
            Decimals = 0.05,
            Suffix = "x",
            Callback = function(v)
                if window.KeybindList then
                    window.KeybindList:SetScale(v)
                end
            end,
        })
        -- Config loads only repaint widgets; push the restored scale to the
        -- panel the same way LoadConfig does for the other __ flags.
        self:TrackWidget("__kblistscale", function()
            local s = tonumber(self.Flags.__kblistscale)
            if s then
                for _, w in ipairs(self._windows) do
                    if w.KeybindList then
                        pcall(function() w.KeybindList:SetScale(s) end)
                    end
                end
            end
        end)
    end
    if window.Watermark then
        uiElements:Slider({
            Name = "Watermark scale",
            Flag = "__wmscale",
            Min = 0.5,
            Max = 3,
            Default = window.Watermark:GetScale(),
            Decimals = 0.05,
            Suffix = "x",
            Callback = function(v)
                if window.Watermark then
                    window.Watermark:SetScale(v)
                end
            end,
        })
        self:TrackWidget("__wmscale", function()
            local s = tonumber(self.Flags.__wmscale)
            if s then
                for _, w in ipairs(self._windows) do
                    if w.Watermark then
                        pcall(function() w.Watermark:SetScale(s) end)
                    end
                end
            end
        end)
    end
    sec:Slider({
        Name = "Notify length",
        Flag = "__notifdur",
        Min = 1,
        Max = 10,
        Default = 4,
        Decimals = 1,
        Suffix = "s",
        Callback = function(v)
            self.NotifDuration = math.clamp(tonumber(v) or 4, 1, 30)
        end,
    })
    sec:Toggle({
        Name = "UI animations",
        Flag = "__anim",
        Default = true,
        Callback = function(v)
            self.AnimationsEnabled = v and true or false
        end,
    })
    sec:Toggle({
        Name = "Tooltips",
        Flag = "__tooltips",
        Default = true,
        Callback = function(v)
            self.TooltipsEnabled = v and true or false
        end,
    })
    sec:Button({
        Name = "Reset floating panels",
        Callback = function()
            if window.KeybindList then
                window.KeybindList:SetPosition(UDim2.new(1, -218, 0, 60))
            end
            if window.ToggleButton then
                window.ToggleButton:SetPosition(UDim2.new(0, 16, 0.5, -22))
            end
        end,
    })
    sec:Button({
        Name = "Unload UI",
        Callback = function() self:Unload() end,
    })

    local theme = self:Section(page, { Name = "Theming" })
    local names = {}
    for k in pairs(self.Presets) do table.insert(names, k) end
    table.sort(names)
    theme:Dropdown({
        Name = "Preset",
        Flag = "__theme",
        Items = names,
        Default = "Default",
        Callback = function(v) self:ApplyThemePreset(v) end,
    })
    theme:AddButton({
        Name = "Random preset",
        Callback = function()
            local pool = {}
            for k in pairs(self.Presets) do table.insert(pool, k) end
            if #pool > 0 then
                self:ApplyThemePreset(pool[math.random(1, #pool)])
            end
        end,
    })
    theme:AddButton({
        Name = "Reset theme",
        Callback = function()
            self:ApplyThemePreset("Default")
            self:SetBackgroundImage(self.DefaultBackgroundImage, self.DefaultBackgroundTransparency)
        end,
    })
    theme:AddTextbox({
        Name = "Background Image",
        Flag = "__bg_image",
        Placeholder = "Asset ID or URL",
        Callback = function(t)
            self:SetBackgroundImage(t, self.BackgroundTransparency)
        end,
    })
    theme:AddSlider({
        Name = "Background Transparency",
        Flag = "__bg_transparency",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Decimals = 0.05,
        Callback = function(v)
            self:SetBackgroundImage(self.BackgroundImage, v)
        end,
    })
    -- Window frame border controls (the box around the whole UI).
    theme:AddToggle({
        Name = "Window border",
        Flag = "__win_border",
        Default = self.WindowBorder.Enabled ~= false,
        Callback = function(v) self:SetWindowBorder({ Enabled = v }) end,
    })
    theme:AddSlider({
        Name = "Window border size",
        Flag = "__win_border_thickness",
        Min = 1,
        Max = 8,
        Default = self.WindowBorder.Thickness or 1,
        Decimals = 1,
        Callback = function(v) self:SetWindowBorder({ Thickness = v }) end,
    })
    theme:AddSlider({
        Name = "Window border alpha",
        Flag = "__win_border_alpha",
        Min = 0,
        Max = 1,
        Default = self.WindowBorder.Transparency or 0.05,
        Decimals = 0.05,
        Callback = function(v) self:SetWindowBorder({ Transparency = v }) end,
    })

    -- Custom outline controls. The colorpicker enables the tint; sliders
    -- shape it; the reset button hands control back to the theme outline.
    theme:AddColorpicker({
        Name = "Border Color",
        Flag = "__border_color",
        Default = self.Border.Color or self.Theme.Accent,
        Alpha = false,
        Callback = function(c) self:SetBorder({ Color = c }) end,
    })
    theme:AddSlider({
        Name = "Border Transparency",
        Flag = "__border_transparency",
        Min = 0,
        Max = 1,
        Default = self.Border.Transparency or 0,
        Decimals = 0.05,
        Callback = function(v) self:SetBorder({ Transparency = v }) end,
    })
    theme:AddSlider({
        Name = "Border Thickness",
        Flag = "__border_thickness",
        Min = 1,
        Max = 4,
        Default = self.Border.Thickness or 1,
        Decimals = 1,
        Callback = function(v) self:SetBorder({ Thickness = v }) end,
    })
    theme:AddButton({
        Name = "Reset border",
        Callback = function()
            self:SetBorder({ Color = false })
            self:SetBorder({ Transparency = 0, Thickness = 1 })
        end,
    })
    local keys = {}
    for k, v in pairs(self.Theme) do
        if typeof(v) == "Color3" then table.insert(keys, k) end
    end
    table.sort(keys)
    for _, k in ipairs(keys) do
        theme:AddColorpicker({
            Name = k,
            Flag = "__theme_" .. k,
            Default = self.Theme[k],
            Alpha = false, -- theme keys are Color3: no alpha channel to edit
            Callback = (function(key)
                return function(c) self:ChangeTheme(key, c) end
            end)(k),
        })
    end

    local cfg = self:Section(page, { Name = "Configs", Side = 2 })
    local status = cfg:AddLabel("Status: idle")
    local cfgName = "default"
    local clipStr = ""
    local autoDelay = 5

    local function setStatus(t)
        status:SetText("Status: " .. tostring(t))
    end

    cfg:AddTextbox({
        Name = "Config name",
        Flag = "__cfg_name",
        Placeholder = "default",
        Default = "default",
        Callback = function(t)
            if type(t) == "string" and t ~= "" then
                cfgName = t
                if Library:IsAutoSaveEnabled() then
                    Library:SetAutoSave(cfgName, Library.AutoSave.Delay or autoDelay)
                    setStatus("autosave -> " .. cfgName)
                end
            end
        end,
    })
    local list = cfg:AddDropdown({
        Name = "Saved",
        Flag = "__cfg_list",
        Items = Library:ListConfigs(),
        Callback = function(v)
            if type(v) == "string" and v ~= "" then
                cfgName = v
                if Library:IsAutoSaveEnabled() then
                    Library:SetAutoSave(cfgName, Library.AutoSave.Delay or autoDelay)
                    setStatus("autosave -> " .. cfgName)
                end
            end
        end,
    })
    local listOpen = list.SetOpen
    function list:SetOpen(o)
        if o then
            list:Refresh(Library:ListConfigs())
        end
        return listOpen(self, o)
    end
    cfg:AddButton({
        Name = "Refresh list",
        Callback = function()
            local found = Library:ListConfigs()
            list:Refresh(found)
            if #found > 0 then list:Set(found[1]) end
            setStatus(#found .. " saved")
        end,
    })
    local function doSave()
        if Library:SaveConfig(cfgName) then
            list:Refresh(Library:ListConfigs())
            setStatus("saved " .. cfgName)
        else
            setStatus("save failed")
        end
    end
    cfg:AddButton({
        Name = "Save",
        Callback = function()
            if type(cfgName) ~= "string" or cfgName == "" then
                setStatus("empty name")
                return
            end
            if Library:HasConfig(cfgName) then
                Library:Dialog({
                    Title = "Overwrite config?",
                    Text = "Config '" .. cfgName .. "' already exists. Overwrite it?",
                    Buttons = {
                        { Text = "Overwrite", Accent = true, Callback = doSave },
                        { Text = "Cancel" },
                    },
                })
            else
                doSave()
            end
        end,
    })
    cfg:AddButton({
        Name = "Load",
        Callback = function()
            if Library:LoadConfigFile(cfgName) then
                setStatus("loaded " .. cfgName)
            else
                setStatus("not found")
            end
        end,
    })
    cfg:AddButton({
        Name = "Delete",
        Callback = function()
            Library:DeleteConfig(cfgName)
            list:Refresh(Library:ListConfigs())
            setStatus("deleted " .. cfgName)
        end,
    })
    cfg:AddButton({
        Name = "Set autoload",
        Callback = function()
            Library:SetAutoloadConfig(cfgName)
            setStatus("autoload = " .. cfgName)
        end,
    })
    cfg:AddButton({
        Name = "Clear autoload",
        Callback = function()
            Library:ClearAutoloadConfig()
            setStatus("autoload cleared")
        end,
    })
    cfg:AddButton({
        Name = "Copy string",
        Callback = function()
            local s = Library:ExportConfigString()
            if Library:CopyConfigToClipboard() then
                setStatus("copied " .. tostring(#s) .. " chars")
            else
                setStatus("copy failed (no clipboard)")
            end
        end,
    })
    cfg:AddButton({
        Name = "Paste string",
        Callback = function()
            if Library:PasteConfigFromClipboard() then
                setStatus("pasted clipboard")
            else
                setStatus("clipboard empty/invalid")
            end
        end,
    })
    cfg:AddTextbox({
        Name = "Import JSON",
        Flag = "__cfg_clipboard",
        Placeholder = "paste config json...",
        Callback = function(t)
            clipStr = tostring(t or "")
        end,
    })
    cfg:AddButton({
        Name = "Import textbox",
        Callback = function()
            if clipStr == "" then
                setStatus("nothing to import")
                return
            end
            if Library:ImportConfigString(clipStr) then
                setStatus("imported string")
            else
                setStatus("import failed")
            end
        end,
    })
    cfg:Toggle({
        Name = "Auto-save",
        Flag = "__autosave_enabled",
        Default = false,
        Callback = function(v)
            if v then
                Library:SetAutoSave(cfgName, autoDelay)
                setStatus("autosave -> " .. cfgName)
            else
                Library:DisableAutoSave()
                setStatus("autosave off")
            end
        end,
    })
    cfg:Slider({
        Name = "Auto-save delay",
        Flag = "__autosave_delay",
        Min = 1,
        Max = 30,
        Default = 5,
        Decimals = 1,
        Suffix = "s",
        Callback = function(v)
            autoDelay = math.clamp(tonumber(v) or 5, 1, 60)
            if Library:IsAutoSaveEnabled() then
                Library.AutoSave.Delay = autoDelay
            end
        end,
    })
    window.SettingsPage = page
    return page
end
-- ============================================================
-- [ module: CreateWindow.lua ]
-- ============================================================

function Library:CreateWindow(data)
    data = data or {}
    local window = self:Window(data)

    function window:AddTab(nameOrData, icon)
        local d
        if type(nameOrData) == "table" then
            d = nameOrData
        else
            d = { Name = nameOrData, Icon = icon }
        end
        local page = Library:Page(window, d, 1, nil)
        if window.SettingsPage and window.Pages[#window.Pages] ~= window.SettingsPage then
            for i, p in ipairs(window.Pages) do
                if p == window.SettingsPage then
                    table.remove(window.Pages, i)
                    break
                end
            end
            table.insert(window.Pages, window.SettingsPage)
            for i, p in ipairs(window.Pages) do
                if p.Items and p.Items.Button then
                    p.Items.Button.LayoutOrder = i
                end
            end
        end
        return page
    end

    function window:CreateHomePage(opts)
        return Library:CreateHomePage(window, opts)
    end

    Library:Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.MenuKey then
            window:SetOpen(not window.IsOpen)
        end
    end)

    -- Header search filters controls by name across every tab.
    if window.Items.Search then
        Library:Connect(window.Items.Search:GetPropertyChangedSignal("Text"), function()
            window:Search(window.Items.Search.Text)
        end)
    end

    if data.HomeTabEnabled ~= false then
        Library:CreateHomePage(window, data.HomeOptions)
    end

    if data.WatermarkEnabled then
        window.Watermark = Library:Watermark({
            Text = data.WatermarkText or data.Name or "DWLib",
            Stats = data.WatermarkStats ~= false,
            Scale = data.WatermarkScale,
        })
    end

    if data.KeybindListEnabled then
        window.KeybindList = Library:KeybindList({
            Visible = data.KeybindListVisible ~= false,
            Scale = data.KeybindListScale,
            Position = data.KeybindListPosition,
        })
    end

    if data.ESPPreviewEnabled then
        window.ESPPreview = Library:ESPPreview({
            Position = data.ESPPreviewPosition,
            Scale = data.ESPPreviewScale,
            Title = data.ESPPreviewTitle,
            Flags = data.ESPPreviewFlags or {},
            Target = data.ESPPreviewTarget,
        })
    end

    local showToggle = data.ToggleButtonEnabled
    if showToggle == nil then
        showToggle = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    end
    if showToggle then
        window.ToggleButton = Library:ToggleButton(window, {
            Position = data.ToggleButtonPosition,
            Size = data.ToggleButtonSize,
        })
    end

    if data.SettingsTabEnabled ~= false then
        Library:CreateSettingsPage(window)
    end

    window:SelectFirst()
    if data.DevMode ~= nil then
        window:SetEnvPill(data.DevMode and true or false)
    end
    return window
end

function Library:SetMenuKeybind(key)
    if typeof(key) == "EnumItem" then
        self.MenuKey = key
        local name = tostring(key):gsub("Enum.KeyCode.", "")
        for _, w in ipairs(self._windows) do
            if w.Items and w.Items.FootKey then
                pcall(function()
                    w.Items.FootKey.Text = "[" .. name .. "] - menu"
                end)
            end
        end
    end
end
-- ============================================================
-- [ module: Aliases.lua ]
-- ============================================================

function Library.Pages:AddSection(nameOrData, icon)
    local d
    if type(nameOrData) == "table" then d = nameOrData
    elseif icon ~= nil then d = { Name = nameOrData, Icon = icon }
    else d = { Name = nameOrData } end
    return self:Section(d)
end

function Library.Sections:AddToggle(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Toggle(nameOrData) end
    local d = { Name = nameOrData }
    if type(extra) == "table" then for k, v in pairs(extra) do d[k] = v end end
    return self:Toggle(d)
end

function Library.Sections:AddButton(nameOrData, cb)
    if type(nameOrData) == "table" then return self:Button(nameOrData) end
    return self:Button({ Name = nameOrData, Callback = cb })
end

function Library.Sections:AddSlider(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Slider(nameOrData) end
    return self:Slider({ Name = nameOrData })
end

function Library.Sections:AddDropdown(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Dropdown(nameOrData) end
    return self:Dropdown({ Name = nameOrData })
end

function Library.Sections:AddLabel(textOrData)
    if type(textOrData) == "table" then return self:Label(textOrData) end
    return self:Label(textOrData)
end

function Library.Sections:AddTextbox(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Textbox(nameOrData) end
    return self:Textbox({ Name = nameOrData })
end

function Library.Sections:AddKeybind(data)
    return self:Keybind(data or {})
end
-- ============================================================
-- [ module: _BuildInfo (generated) ]
-- ============================================================

Library.BuildId = "6870dea 2026-10-21 03:49 UTC"
-- ============================================================
-- [ module: Footer.lua ]
-- ============================================================

if getgenv then
    getgenv().DWLib = Library
end
return Library
