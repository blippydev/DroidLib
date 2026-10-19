function Library.Sections:Button(data)
    data = data or {}
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 20),
        AutoButtonColor = false,
        Font = Library.Font,
        TextSize = 13,
        Text = tostring(data.Name or "Button"),
        BorderSizePixel = 0,
    }, self.Items.List)
    Library:Themed(btn, "BackgroundColor3", "Element2")
    Library:Themed(btn, "TextColor3", "Text")
    Library:Corner(btn, 6)
    local btnStroke = Library:Stroke(btn, 1)
    -- Linoria-look sheen: white->gray vertical gradient over the fill. The
    -- gradient multiplies whatever themed background is underneath.
    Library:Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(212, 212, 212)),
        }),
        Rotation = 90,
    }, btn)

    local handle = {}
    local kbRef = nil
    function handle:Press()
        Library:Punch(btn)
        if type(data.Callback) == "function" then
            task.spawn(data.Callback)
        end
    end
    function handle:Keybind(kdata)
        if kbRef then return kbRef end
        kdata = kdata or {}
        if kdata.Name == nil then kdata.Name = data.Name end
        -- Button keybinds are press-only: mode locked to "Press" no matter
        -- what the caller asked for (Toggle/Hold/Always never apply).
        -- InputEnded handlers are not wired for this mode, so hold-release
        -- and stuck-on states are structurally impossible.
        kdata.Mode = "Press"
        kdata._pressOnly = true
        -- A bound key IS a press: the button callback runs exactly once.
        kdata.Callback = function() handle:Press() end
        kbRef = Library:_attachKeybind(btn, kdata)
        return kbRef
    end
    local function bindKey()
        if kbRef then
            kbRef:ShowModeMenu(btn)
        else
            kbRef = handle:Keybind({})
            kbRef:ShowModeMenu(btn)
        end
    end
    Library:Connect(btn.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton2 then
            bindKey()
        end
    end)
    Library:Connect(btn.MouseButton2Click, bindKey)
    function handle:SetVisibility(v) btn.Visible = v and true or false end
    function handle:SetText(t) btn.Text = tostring(t) end
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(btn, data.Tooltip)
    end
    Library:Connect(btn.MouseButton1Click, function() handle:Press() end)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(btn, { BackgroundColor3 = Library.Theme.Element }, 0.12)
        -- Linoria highlight: border flips to the accent, fill stays put.
        Library:Tween(btnStroke, { Color = Library.Theme.Accent }, 0.12)
    end)
    Library:Connect(btn.MouseLeave, function()
        Library:Tween(btn, { BackgroundColor3 = Library.Theme.Element2 }, 0.12)
        Library:Tween(btnStroke, { Color = Library.Theme.Outline }, 0.12)
    end)
    return handle
end
