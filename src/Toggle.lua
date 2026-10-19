function Library.Sections:Toggle(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local state = data.Default == true
    Library.Flags[flag] = state

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 21),
        BackgroundTransparency = 1,
    }, self.Items.List)

    local box = Library:Create("TextButton", {
        Position = UDim2.new(0, 0, 0.5, -7),
        Size = UDim2.new(0, 14, 0, 14),
        AutoButtonColor = false,
        Font = Library.Font,
        TextSize = 10,
        Text = "",
        BorderSizePixel = 0,
    }, row)
    Library:Themed(box, "BackgroundColor3", "Element2")
    Library:Themed(box, "TextColor3", "Text")
    Library:Corner(box, 0)
    local boxStroke = Library:Stroke(box, 1)

    local lbl = Library:Create("TextButton", {
        Position = UDim2.new(0, 19, 0, 0),
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Font = Library.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Name or flag),
    }, row)
    Library:Themed(lbl, "TextColor3", "Text")

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

    local toggle = { Flag = flag, _row = row }
    local kbRef = nil
    local function paint(instant)
        local t = instant and 0 or 0.15
        if state then
            Library:Tween(box, { BackgroundColor3 = Library.Theme.Accent }, t)
            task.delay(t, function()
                if state and box.Parent then box.Text = "✓" end
            end)
        else
            box.Text = ""
            Library:Tween(box, { BackgroundColor3 = Library.Theme.Element2 }, t)
        end
    end
    paint(true)

    function toggle:Get() return state end
    function toggle:Set(v)
        v = v and true or false
        if kbRef and kbRef.GetMode then
            local m = kbRef:GetMode()
            -- Locked on while Always; key-driven only while Hold.
            if (not v and m == "Always")
                or (m == "Hold" and not kbRef._holdKey) then
                return
            end
        end
        state = v
        Library.Flags[flag] = state
        paint(false)
        if kbRef then kbRef:Refresh() end
        if type(data.Callback) == "function" then
            task.spawn(data.Callback, state)
        end
    end
    function toggle:SetVisibility(v) row.Visible = v and true or false end

    function toggle:Keybind(kdata)
        if kbRef then return kbRef end
        kdata = kdata or {}
        if kdata.Name == nil then kdata.Name = data.Name end
        -- Two-way link: the chip shows this toggle's value (ON/OFF) and a
        -- key press writes into the toggle. The toggle stays authoritative.
        kdata._link = toggle
        kbRef = Library:_attachKeybind(row, kdata)
        kbRef:Refresh()
        return kbRef
    end
    function toggle:Colorpicker(cdata)
        return Library:_attachColorpicker(row, cdata)
    end

    -- Right-click opens the keybind menu (mode + rebind).
    local function bindKey()
        if kbRef then
            kbRef:ShowModeMenu(row)
        else
            kbRef = toggle:Keybind({ Name = data.Name, Mode = "Toggle" })
            kbRef:ShowModeMenu(row)
        end
    end
    local function onRight(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            bindKey()
        end
    end
    Library:Connect(row.InputBegan, onRight)
    Library:Connect(box.MouseButton2Click, bindKey)
    Library:Connect(lbl.MouseButton2Click, bindKey)

    local function flip()
        Library:Punch(box, 0.8)
        toggle:Set(not state)
    end
    Library:Connect(box.MouseButton1Click, flip)
    Library:Connect(lbl.MouseButton1Click, flip)
    Library:Connect(row.MouseEnter, function()
        Library:Tween(boxStroke, { Color = Library.Theme.Accent }, 0.15)
    end)
    Library:Connect(row.MouseLeave, function()
        Library:Tween(boxStroke, { Color = Library.Theme.Outline }, 0.15)
    end)

    Library:TrackWidget(flag, function()
        state = Library.Flags[flag] and true or false
        -- Mode invariants win over the saved value regardless of restore order
        -- (the keybind side enforces the same pair, so both orders converge).
        if kbRef and kbRef.GetMode then
            local m = kbRef:GetMode()
            if m == "Always" then
                state = true
            elseif m == "Hold" then
                state = false
            end
        end
        paint(true)
        if kbRef then kbRef:Refresh() end
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(row, data.Tooltip)
    end
    return toggle
end
