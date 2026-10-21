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
