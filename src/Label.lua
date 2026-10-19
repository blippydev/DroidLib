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
