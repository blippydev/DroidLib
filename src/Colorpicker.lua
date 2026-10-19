function Library:_attachColorpicker(row, data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local alphaOpt = data.Alpha
    if alphaOpt == nil then alphaOpt = data.alpha end
    local hasAlpha = alphaOpt ~= false
    local color = typeof(data.Default) == "Color3" and data.Default or Color3.fromRGB(220, 30, 42)
    local h, s, v = color:ToHSV()
    local alpha = hasAlpha and math.clamp(tonumber(alphaOpt) or 0, 0, 1) or 0
    Library.Flags[flag] = color
    if hasAlpha then Library.Flags[flag .. "_alpha"] = alpha end

    local host = row:FindFirstChild("Right") or row
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(0, 32, 0, 15),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
        BackgroundColor3 = color,
        BackgroundTransparency = hasAlpha and alpha or 0,
    }, host)
    if host == row then
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
    else
        btn.LayoutOrder = 2
    end
    Library:Corner(btn, 0)
    local swStroke = Library:Stroke(btn, 1)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(swStroke, { Color = Library.Theme.Accent }, 0.12)
    end)
    Library:Connect(btn.MouseLeave, function()
        Library:Tween(swStroke, { Color = Library.Theme.Outline }, 0.12)
    end)

    local open = false
    local pop
    local palBase, palDot, hueBar, hueDot, alphaFill, alphaDot, readout
    local POP_W = hasAlpha and 196 or 174

    local function current()
        return Color3.fromHSV(h, s, v)
    end

    local function fire()
        color = current()
        Library.Flags[flag] = color
        if hasAlpha then Library.Flags[flag .. "_alpha"] = alpha end
        pcall(function()
            btn.BackgroundColor3 = color
            btn.BackgroundTransparency = hasAlpha and alpha or 0
        end)
        if type(data.Callback) == "function" then task.spawn(data.Callback, color, alpha) end
    end

    local function paint()
        if not pop then return end
        palBase.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        palDot.Position = UDim2.new(s, -4, 1 - v, -4)
        hueDot.Position = UDim2.new(0.5, -5, h, -5)
        if hasAlpha and alphaFill then
            alphaFill.BackgroundColor3 = current()
            alphaDot.Position = UDim2.new(0.5, -5, alpha, -5)
        end
        readout.Text = hasAlpha
            and string.format("#%s  -  alpha %.2f", current():ToHex(), alpha)
            or ("#" .. current():ToHex())
    end

    local function dot(parent, size)
        local d = Library:Create("Frame", {
            Size = UDim2.new(0, size, 0, size),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        }, parent)
        Library:Corner(d, size)
        local st = Library:Create("UIStroke", { Thickness = 1.5 }, d)
        st.Color = Color3.fromRGB(20, 20, 25)
        return d
    end

    local function drag2D(hit, fn)
        local drag = false
        Library:Connect(hit.InputBegan, function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                drag = true
                fn(inp.Position.X, inp.Position.Y)
            end
        end)
        Library:Connect(UserInputService.InputChanged, function(inp)
            if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                fn(inp.Position.X, inp.Position.Y)
            end
        end)
        Library:Connect(UserInputService.InputEnded, function() drag = false end)
    end

    local function palAt(x, y)
        local p = palBase.AbsolutePosition
        local sz = palBase.AbsoluteSize
        s = math.clamp((x - p.X) / math.max(1, sz.X), 0, 1)
        v = 1 - math.clamp((y - p.Y) / math.max(1, sz.Y), 0, 1)
        paint()
        fire()
    end

    local function hueAt(_, y)
        local p = hueBar.AbsolutePosition
        h = math.clamp((y - p.Y) / math.max(1, hueBar.AbsoluteSize.Y), 0, 1)
        paint()
        fire()
    end

    local function alphaAt(_, y)
        if not hasAlpha then return end
        local p = alphaFill.AbsolutePosition
        alpha = math.clamp((y - p.Y) / math.max(1, alphaFill.AbsoluteSize.Y), 0, 1)
        paint()
        fire()
    end

    local function buildPop()
        pop = Library:Create("Frame", {
            Size = UDim2.new(0, POP_W, 0, 178),
            BorderSizePixel = 0,
            Visible = false,
        }, Library.Overlay or row)
        Library:Themed(pop, "BackgroundColor3", "Background")
        Library:Corner(pop, 8)
        Library:Stroke(pop, 1)

        palBase = Library:Create("TextButton", {
            Position = UDim2.new(0, 8, 0, 8),
            Size = UDim2.new(0, 136, 0, 136),
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        }, pop)
        Library:Corner(palBase, 6)
        local sat = Library:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        }, palBase)
        local satG = Library:Create("UIGradient", {}, sat)
        satG.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        })
        Library:Corner(sat, 6)
        local val = Library:Create("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        }, palBase)
        local valG = Library:Create("UIGradient", { Rotation = 90 }, val)
        valG.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        })
        Library:Corner(val, 6)
        palDot = dot(palBase, 8)

        hueBar = Library:Create("TextButton", {
            Position = UDim2.new(0, 150, 0, 8),
            Size = UDim2.new(0, 16, 0, 136),
            AutoButtonColor = false,
            Text = "",
            BorderSizePixel = 0,
        }, pop)
        local hueG = Library:Create("UIGradient", { Rotation = 90 }, hueBar)
        hueG.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        })
        Library:Corner(hueBar, 6)
        hueDot = dot(hueBar, 10)

        if hasAlpha then
            local aBar = Library:Create("TextButton", {
                Position = UDim2.new(0, 172, 0, 8),
                Size = UDim2.new(0, 16, 0, 136),
                AutoButtonColor = false,
                Text = "",
                BorderSizePixel = 0,
                BackgroundTransparency = 1,
            }, pop)
            local back = Library:Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = Color3.fromRGB(200, 200, 200),
            }, aBar)
            local backG = Library:Create("UIGradient", { Rotation = 45 }, back)
            backG.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(235, 235, 235)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 120, 120)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(235, 235, 235)),
            })
            Library:Corner(back, 6)
            alphaFill = Library:Create("Frame", {
                Size = UDim2.new(1, 0, 1, 0),
                BorderSizePixel = 0,
                BackgroundColor3 = current(),
            }, aBar)
            local aG = Library:Create("UIGradient", { Rotation = 90 }, alphaFill)
            aG.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            Library:Corner(alphaFill, 6)
            Library:Stroke(aBar, 1)
            alphaDot = dot(aBar, 10)
            drag2D(aBar, alphaAt)
        end

        readout = Library:Create("TextLabel", {
            Position = UDim2.new(0, 8, 0, 150),
            Size = UDim2.new(0, POP_W - 16, 0, 20),
            BackgroundTransparency = 1,
            Font = Enum.Font.Code,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "",
        }, pop)
        Library:Themed(readout, "TextColor3", "TextMuted")

        drag2D(palBase, palAt)
        drag2D(hueBar, hueAt)
        paint()
    end

    local picker = {}
    function picker:Get() return current(), alpha end
    function picker:Set(c, a)
        if typeof(c) == "Color3" then
            h, s, v = c:ToHSV()
            if hasAlpha and tonumber(a) ~= nil then
                alpha = math.clamp(tonumber(a), 0, 1)
            end
            paint()
            fire()
        end
    end
    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if typeof(saved) == "Color3" then
            h, s, v = saved:ToHSV()
            if hasAlpha then
                local sa = tonumber(Library.Flags[flag .. "_alpha"])
                if sa ~= nil then alpha = math.clamp(sa, 0, 1) end
            end
            paint()
            pcall(function()
                btn.BackgroundColor3 = current()
                btn.BackgroundTransparency = hasAlpha and alpha or 0
            end)
        end
    end)
    function picker:SetOpen(o)
        o = o and true or false
        if o then
            if not pop then buildPop() end
            open = true
            paint()
            Library:ShowPopup(pop, btn, { width = POP_W, alignRight = true })
            Library:Punch(pop)
        else
            open = false
            Library:ClosePopups()
        end
    end

    Library:Connect(btn.MouseButton1Click, function()
        local cur = Library._openPopup
        if open and cur and cur.frame == pop then
            picker:SetOpen(false)
        else
            picker:SetOpen(true)
        end
    end)
    return picker
end

function Library.Sections:Colorpicker(data)
    local host = self:Label(data and (data.Name or "Color") or "Color")
    local p = host:Colorpicker(data)
    if type(p) == "table" then p.Label = host end
    return p
end

function Library.Sections:AddColorpicker(a, b, c)
    if type(a) == "table" then return self:Colorpicker(a) end
    if type(b) == "function" then
        return self:Colorpicker({ Name = a, Callback = b })
    end
    return self:Colorpicker({ Name = a, Default = b, Callback = c })
end
