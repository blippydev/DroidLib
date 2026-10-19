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
