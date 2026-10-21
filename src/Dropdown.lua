function Library.Sections:Dropdown(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local multi = data.Multi == true
    local items = {}
    for _, v in ipairs(data.Items or {}) do table.insert(items, tostring(v)) end

    local current
    if multi then
        current = {}
        for _, v in ipairs(data.Default or {}) do current[tostring(v)] = true end
    else
        current = tostring(data.Default or items[1] or "")
    end
    Library.Flags[flag] = current

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
    }, self.Items.List)
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(1, 0, 1, 0),
        AutoButtonColor = false,
        Text = "",
        BorderSizePixel = 0,
    }, row)
    Library:Themed(btn, "BackgroundColor3", "Element2")
    local dd = { Flag = flag, _open = false }
    Library:Corner(btn, 6)
    local ddStroke = Library:Stroke(btn, 1)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(ddStroke, { Color = Library.Theme.Accent }, 0.15)
    end)
    Library:Connect(btn.MouseLeave, function()
        if not dd._open then
            Library:Tween(ddStroke, { Color = Library.Theme.Outline }, 0.15)
        end
    end)

    local nameLbl = Library:Create("TextLabel", {
        Position = UDim2.new(0, 8, 0, 0),
        Size = UDim2.new(0.42, -8, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Name or "Select"),
    }, btn)
    Library:Themed(nameLbl, "TextColor3", "TextMuted")
    local valueLbl = Library:Create("TextLabel", {
        Position = UDim2.new(0.42, 0, 0, 0),
        Size = UDim2.new(0.58, -22, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "",
    }, btn)
    Library:Themed(valueLbl, "TextColor3", "Text")
    -- Linoria-look arrow: accent gradient segment on the right edge of the
    -- closed box, glyph flips to "^" when the list is open.
    local arrowBox = Library:Create("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -3, 0.5, 0),
        Size = UDim2.new(0, 18, 1, -6),
        BorderSizePixel = 0,
    }, btn)
    Library:Themed(arrowBox, "BackgroundColor3", "Accent")
    Library:Corner(arrowBox, 2)
    Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 160, 160)),
        }),
        Rotation = 90,
    }, arrowBox)
    local arrow = Library:Create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        Text = "v",
    }, arrowBox)
    Library:Themed(arrow, "TextColor3", "Text")

    local list = Library:Create("ScrollingFrame", {
        Position = UDim2.new(0, 0, 1, 4),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2,
        BorderSizePixel = 0,
        Visible = false,
    }, row)
    Library:Themed(list, "BackgroundColor3", "Background")
    Library:Themed(list, "ScrollBarImageColor3", "Outline")
    Library:Corner(list, 8)
    Library:Stroke(list, 1)
    local ll = Library:Create("UIListLayout", { Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }, list)
    local MAX_H = 276 -- ~14 rows, then scroll
    local function contentHeight()
        local n = #items
        if n <= 0 then return 28 end
        return math.min(8 + n * 18 + (n - 1) * 1, MAX_H)
    end
    local function syncHeight()
        list.Size = UDim2.new(list.Size.X.Scale, list.Size.X.Offset, 0, contentHeight())
    end
    Library:Create("UIPadding", {
        PaddingTop = UDim.new(0, 3), PaddingBottom = UDim.new(0, 3),
        PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 3),
    }, list)

    local function valueText()
        if multi then
            local t = {}
            for k in pairs(current) do table.insert(t, k) end
            if #t == 0 then return "none" end
            table.sort(t)
            return table.concat(t, ", ")
        end
        return tostring(current)
    end
    local function paint() valueLbl.Text = valueText() end
    local function fire()
        Library.Flags[flag] = current
        if type(data.Callback) == "function" then
            if multi then
                local out = {}
                for k in pairs(current) do table.insert(out, k) end
                task.spawn(data.Callback, out)
            else
                task.spawn(data.Callback, current)
            end
        end
    end
    local function rebuild()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for _, name in ipairs(items) do
            local on = multi and current[name] or (current == name)
            local b = Library:Create("TextButton", {
                Size = UDim2.new(1, -4, 0, 18),
                AutoButtonColor = false,
                Text = "",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, list)
            Library:Corner(b, 0)
            local box = Library:Create("Frame", {
                Position = UDim2.new(0, 6, 0.5, -6),
                Size = UDim2.new(0, 12, 0, 12),
                BorderSizePixel = 0,
            }, b)
            if on then
                Library:Themed(box, "BackgroundColor3", "Accent")
            else
                Library:Themed(box, "BackgroundColor3", "Element2")
            end
            Library:Corner(box, 0)
            local boxStroke = Library:Stroke(box, 1)
            local mark = Library:Create("TextLabel", {
                Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Font = Library.Font,
                TextSize = 10,
                Text = on and "✓" or "",
                Visible = on and true or false,
            }, box)
            Library:Themed(mark, "TextColor3", "Text")
            local lbl = Library:Create("TextLabel", {
                Position = UDim2.new(0, 24, 0, 0),
                Size = UDim2.new(1, -30, 1, 0),
                BackgroundTransparency = 1,
                Font = Library.Font,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Text = name,
            }, b)
            if on then
                Library:Themed(lbl, "TextColor3", "Text")
            else
                Library:Themed(lbl, "TextColor3", "TextMuted")
            end
            Library:Connect(b.MouseEnter, function()
                Library:Tween(b, { BackgroundColor3 = Library.Theme.Element2, BackgroundTransparency = 0 }, 0.1)
                Library:Tween(boxStroke, { Color = Library.Theme.Accent }, 0.1)
            end)
            Library:Connect(b.MouseLeave, function()
                Library:Tween(b, { BackgroundTransparency = 1 }, 0.1)
                Library:Tween(boxStroke, { Color = Library.Theme.Outline }, 0.1)
            end)
            Library:Connect(b.MouseButton1Click, function()
                Library:Punch(b, 0.97)
                if multi then
                    current[name] = not current[name] or nil
                else
                    current = name
                    dd:SetOpen(false)
                end
                paint(); rebuild(); fire()
            end)
        end
        if dd._open then syncHeight() end
    end
    paint(); rebuild()

    function dd:Get() return current end
    function dd:Set(v)
        if multi then
            current = {}
            for _, x in ipairs(v or {}) do current[tostring(x)] = true end
        else
            current = tostring(v)
        end
        paint(); rebuild(); fire()
    end
    function dd:Refresh(newItems)
        items = {}
        for _, v in ipairs(newItems or {}) do table.insert(items, tostring(v)) end
        rebuild(); paint()
        syncHeight()
    end
    function dd:SetOpen(o)
        o = o and true or false
        if o then
            dd._open = true
            Library:Tween(ddStroke, { Color = Library.Theme.Accent }, 0.12)
            -- Explicit height: full content up to 8 rows, then scroll.
            syncHeight()
            pcall(function() list.CanvasPosition = Vector2.new(0, 0) end)
            Library:ShowPopup(list, btn, { width = math.max(140, btn.AbsoluteSize.X) })
            Library:Punch(list)
        else
            dd._open = false
            Library:Tween(ddStroke, { Color = Library.Theme.Outline }, 0.12)
            Library:ClosePopups()
        end
        arrow.Text = dd._open and "^" or "v"
    end
    function dd:SetVisibility(v) row.Visible = v and true or false end
    function dd:SelectAll()
        if not multi then return end
        for _, n in ipairs(items) do current[n] = true end
        paint(); rebuild(); fire()
    end
    function dd:DeselectAll()
        if not multi then return end
        current = {}
        paint(); rebuild(); fire()
    end
    Library:Connect(btn.MouseButton1Click, function()
        Library:Punch(btn, 0.98)
        local cur = Library._openPopup
        if dd._open and cur and cur.frame == list then
            dd:SetOpen(false)
        else
            dd:SetOpen(true)
        end
    end)
    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if multi then
            if type(saved) == "table" then
                current = {}
                local isArray = saved[1] ~= nil
                if isArray then
                    for _, x in ipairs(saved) do current[tostring(x)] = true end
                else
                    for k in pairs(saved) do current[tostring(k)] = true end
                end
                paint(); rebuild()
            end
        elseif type(saved) == "string" then
            current = saved
            paint(); rebuild()
        end
    end, function()
        local saved = Library.Flags[flag]
        if multi then
            if type(saved) == "table" then
                current = {}
                local isArray = saved[1] ~= nil
                if isArray then
                    for _, x in ipairs(saved) do current[tostring(x)] = true end
                else
                    for k in pairs(saved) do current[tostring(k)] = true end
                end
                paint(); rebuild()
            end
        elseif type(saved) == "string" then
            current = saved
            paint(); rebuild()
        end
        fire()
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(btn, data.Tooltip)
    end
    return dd
end
