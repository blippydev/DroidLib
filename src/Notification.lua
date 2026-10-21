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
