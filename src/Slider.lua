function Library.Sections:Slider(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local min = tonumber(data.Min) or 0
    local max = tonumber(data.Max) or 100
    if max < min then min, max = max, min end
    local dec = tonumber(data.Decimals) or tonumber(data.Dec) or 1
    local val = tonumber(data.Default) or min
    val = math.clamp(val, min, max)
    Library.Flags[flag] = val

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
    }, self.Items.List)
    local name = Library:Create("TextLabel", {
        Size = UDim2.new(1, -66, 0, 14),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Name or flag),
    }, row)
    Library:Themed(name, "TextColor3", "Text")
    local value = Library:Create("TextLabel", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0),
        Size = UDim2.new(0, 62, 0, 14),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Text = "",
    }, row)
    Library:Themed(value, "TextColor3", "TextMuted")

    local bar = Library:Create("TextButton", {
        Position = UDim2.new(0, 0, 0, 18),
        Size = UDim2.new(1, 0, 0, 9),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
    }, row)
    Library:Themed(bar, "BackgroundColor3", "Element2")
    Library:Corner(bar, 4)
    Library:Stroke(bar, 1)
    local fill = Library:Create("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
    }, bar)
    Library:Themed(fill, "BackgroundColor3", "Accent")
    Library:Corner(fill, 4)
    local sheen = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0.5, 0),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.85,
    }, fill)
    Library:Corner(sheen, 4)

    local slider = {}
    local dragging = false
    -- Live=false: Callback is deferred until release (for preview-then-commit
    -- sliders like UI Scale). Preview fires on every tick while dragging.
    local live = data.Live ~= false
    local previewFn = (type(data.Preview) == "function") and data.Preview or nil
    local releaseCbs = {}
    do
        local rf = data.OnRelease
        if type(rf) ~= "function" then rf = data.Release end
        if type(rf) ~= "function" then rf = data.Commit end
        if type(rf) == "function" then table.insert(releaseCbs, rf) end
    end
    local function firePreview(v)
        if previewFn then task.spawn(previewFn, v) end
    end
    local function fireCallback(v)
        if type(data.Callback) == "function" then
            task.spawn(data.Callback, v)
        end
    end
    local function fireRelease(v)
        for _, fn in ipairs(releaseCbs) do
            task.spawn(fn, v)
        end
    end
    local function round(v)
        if dec and dec > 0 then
            local m = 1 / dec
            return math.floor(v * m + 0.5) / m
        end
        return math.floor(v + 0.5)
    end
    local function paint()
        local t = (max == min) and 0 or ((val - min) / (max - min))
        local sfx = data.Suffix and tostring(data.Suffix) or ""
        value.Text = tostring(val) .. sfx
        if dragging then
            fill.Size = UDim2.new(t, 0, 1, 0)
        else
            Library:Tween(fill, { Size = UDim2.new(t, 0, 1, 0) }, 0.1)
        end
    end
    paint()

    function slider:Get() return val end
    function slider:Set(v)
        v = tonumber(v) or val
        val = round(math.clamp(v, min, max))
        paint()
        if dragging and not live then
            -- Preview-only tick: do not touch Flags/Callback yet.
            firePreview(val)
            return
        end
        Library.Flags[flag] = val
        fireCallback(val)
    end
    function slider:SetVisibility(v) row.Visible = v and true or false end
    function slider:OnRelease(fn)
        if type(fn) == "function" then table.insert(releaseCbs, fn) end
        return slider
    end

    local function apply(x)
        local abs = bar.AbsolutePosition.X
        local w = math.max(1, bar.AbsoluteSize.X)
        local t = math.clamp((x - abs) / w, 0, 1)
        slider:Set(min + (max - min) * t)
    end
    Library:Connect(bar.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            Library:Tween(bar, { Size = UDim2.new(1, 0, 0, 12) }, 0.1)
            apply(i.Position.X)
        end
    end)
    Library:Connect(UserInputService.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            apply(i.Position.X)
        end
    end)
    Library:Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                Library:Tween(bar, { Size = UDim2.new(1, 0, 0, 9) }, 0.12)
            end
            local wasDragging = dragging
            dragging = false
            if wasDragging then
                if not live then
                    Library.Flags[flag] = val
                    paint()
                    fireCallback(val)
                end
                fireRelease(val)
            end
        end
    end)

    Library:TrackWidget(flag, function()
        local saved = tonumber(Library.Flags[flag])
        if saved ~= nil then
            val = round(math.clamp(saved, min, max))
            paint()
        end
    end, function()
        local saved = tonumber(Library.Flags[flag])
        if saved ~= nil then
            val = round(math.clamp(saved, min, max))
            Library.Flags[flag] = val
            paint()
        end
        fireCallback(val)
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(row, data.Tooltip)
    end
    return slider
end
