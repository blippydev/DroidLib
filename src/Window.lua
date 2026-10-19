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
    self:Corner(root, 0)

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
        Font = Library.Font,
        TextSize = 13,
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
    self:Corner(search, 0)
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
    self:Corner(lcard, 0)
    self:Stroke(lcard, 1)

    local llogo = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 14),
        Size = UDim2.new(0, 32, 0, 32),
        BorderSizePixel = 0,
    }, lcard)
    self:Themed(llogo, "BackgroundColor3", "Element2")
    self:Corner(llogo, 0)
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
    self:Corner(track, 0)
    local fill = self:Create("Frame", {
        Size = UDim2.new(0, 50, 1, 0),
        BorderSizePixel = 0,
    }, track)
    self:Themed(fill, "BackgroundColor3", "Accent")
    self:Corner(fill, 0)

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
