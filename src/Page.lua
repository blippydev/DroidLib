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

    -- Mono Code font: fixed advance per char. Measure with TextService when
    -- games allow it; fall back to the documented 8px advance at size 13.
    local function labelTextWidth(text)
        local ok, size = pcall(function()
            local ts = game:GetService("TextService")
            return ts:GetTextSize(tostring(text), 13, Enum.Font.Code, Vector2.new(10000, 100)).X
        end)
        if ok and type(size) == "number" and size > 0 then return size end
        return #tostring(text) * 8
    end

    local btn = self:Create("TextButton", {
        Size = isSub and UDim2.new(0, 0, 0, 20) or UDim2.new(0, 90, 0, 22),
        AutomaticSize = isSub and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
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
        local btnWidth = textX + labelTextWidth(page.Name) + 10
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
            Size = UDim2.new(0, btnWidth - textX - 4, 1, 0),
            BackgroundTransparency = 1,
            Font = Library.Font,
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
