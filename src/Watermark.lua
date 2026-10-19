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
