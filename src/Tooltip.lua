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
