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
