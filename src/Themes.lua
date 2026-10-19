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
