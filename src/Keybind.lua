Library._keybinds = {}

function Library:_attachKeybind(row, data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local key = data.Default
    if typeof(key) ~= "EnumItem" then key = nil end
    local mode = tostring(data.Mode or "Toggle")
    local toggled = false
    local picking = false
    Library.Flags[flag] = { Key = key, Mode = mode, Toggled = toggled }

    local host = row:FindFirstChild("Right") or row
    local btn = Library:Create("TextButton", {
        Size = UDim2.new(0, 48, 0, 16),
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        TextSize = 11,
        Text = "[NONE]",
        BorderSizePixel = 0,
    }, host)
    if host ~= row then
        btn.LayoutOrder = 1
    else
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, 0, 0.5, 0)
    end
    Library:Themed(btn, "BackgroundColor3", "Surface")
    Library:Themed(btn, "TextColor3", "TextMuted")
    Library:Corner(btn, 2)
    local kbStroke = Library:Stroke(btn, 1)
    Library:Connect(btn.MouseEnter, function()
        Library:Tween(kbStroke, { Color = Library.Theme.Accent }, 0.12)
    end)
    Library:Connect(btn.MouseLeave, function()
        Library:Tween(kbStroke, { Color = Library.Theme.Outline }, 0.12)
    end)

    local kb = { Flag = flag, _name = tostring(data.Name or flag) }
    -- Two-way link (toggle:Keybind): the chip mirrors the toggle's live
    -- value (read) and a key press writes straight into the toggle, so the
    -- toggle stays the single source of truth. Unlinked keybinds (buttons,
    -- standalone) keep the old key-name chip.
    local link = data._link
    if type(link) ~= "table" or type(link.Get) ~= "function" or type(link.Set) ~= "function" then
        link = nil
    end
    -- Button-linked keybinds are press-only: mode can never leave "Press",
    -- and the right-click menu hides the Toggle/Hold/Always rows entirely.
    local pressOnly = data._pressOnly == true
    if pressOnly then
        mode = "Press"
    end
    -- Keybind-list tag row: "BUTTON" for press-only binds, else the live
    -- mode in caps (SetMode changes show up on the next Refresh).
    local function modeTag()
        if pressOnly then return "BUTTON" end
        return string.upper(mode)
    end
    local function linkOn()
        if not link then return toggled end
        local ok, v = pcall(link.Get, link)
        return ok and v and true or false
    end
    local function paint()
        if picking then
            btn.Text = "[...]"
        else
            btn.Text = key and ("[" .. key.Name .. "]") or "[NONE]"
        end
    end
    paint()
    local function fire()
        Library.Flags[flag] = { Key = key, Mode = mode, Toggled = toggled }
        if type(data.Callback) == "function" then task.spawn(data.Callback, toggled) end
        Library:_pushKeybindList()
    end
    function kb:Get() return linkOn() end
    function kb:GetText()
        -- Unbound keybinds ([NONE]) are unregistered from the keybind list:
        -- no text means no row, and the list falls back to "none bound".
        if typeof(key) ~= "EnumItem" then return nil end
        -- State words ("ON"/"OFF") dropped by request; mode tag appended so
        -- the list still shows how the bind behaves.
        local tag = modeTag()
        if link then
            return kb._name .. " [" .. key.Name .. "] " .. tag, linkOn()
        end
        return kb._name .. " " .. btn.Text .. " " .. tag, linkOn()
    end
    -- Structured row data for the keybind list: name, key, on/off, mode.
    -- Nil when unbound (same contract as GetText) so the list skips it.
    function kb:GetParts()
        if typeof(key) ~= "EnumItem" then return nil end
        return { name = kb._name, key = key.Name, on = linkOn(), mode = modeTag() }
    end
    function kb:GetMode() return mode end
    function kb:SetMode(m)
        if pressOnly and tostring(m) ~= "Press" then return kb end
        mode = tostring(m)
        if mode == "Always" then
            -- Forced on: apply immediately, linked toggle included.
            toggled = true
            if link then link:Set(true) end
        elseif mode == "Hold" and link then
            -- Momentary only: never stick on from an earlier mode.
            kb._holdKey = true
            link:Set(false)
            kb._holdKey = false
            toggled = false
        end
        fire()
    end
    function kb:Press(v)
        if link then
            if mode == "Hold" and not kb._holdKey then return end
            local nv = (v == nil) and (not linkOn()) or (v and true or false)
            toggled = nv
            link:Set(nv)
            fire()
            return
        end
        toggled = (v == nil) and (not toggled) or (v and true or false)
        fire()
    end
    function kb:StartPicking()
        picking = true
        paint()
        Library:Punch(btn, 0.9)
    end
    -- Right-click menu: pick Toggle / Hold / Always, or rebind the key.
    local menu, menuMarks, menuKeyLbl = nil, {}, nil
    function kb:ShowModeMenu(anchor)
        if not menu or not menu.Parent then
            menuMarks = {}
            menu = Library:Create("Frame", {
                Size = UDim2.new(0, 190, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                BorderSizePixel = 0,
                Visible = false,
            }, Library.Overlay or btn.Parent)
            Library:Themed(menu, "BackgroundColor3", "Background")
            Library:Corner(menu, 8)
            Library:Stroke(menu, 1)
            Library:Create("UIPadding", {
                PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4),
                PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4),
            }, menu)
            Library:Create("UIListLayout", {
                Padding = UDim.new(0, 2),
                SortOrder = Enum.SortOrder.LayoutOrder,
            }, menu)
            local modes = {
                { "Toggle", "flips on each press" },
                { "Hold", "on while held" },
                { "Always", "forced on" },
            }
            for _, m in ipairs(modes) do
                if pressOnly then break end
                local b = Library:Create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 38),
                    AutoButtonColor = false,
                    Text = "",
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }, menu)
                Library:Corner(b, 6)
                local t = Library:Create("TextLabel", {
                    Position = UDim2.new(0, 10, 0, 3),
                    Size = UDim2.new(1, -36, 0, 16),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 13,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = m[1],
                }, b)
                Library:Themed(t, "TextColor3", "Text")
                local d = Library:Create("TextLabel", {
                    Position = UDim2.new(0, 10, 0, 19),
                    Size = UDim2.new(1, -36, 0, 14),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Code,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Text = m[2],
                }, b)
                Library:Themed(d, "TextColor3", "TextMuted")
                local mark = Library:Create("TextLabel", {
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.new(0, 18, 0, 18),
                    BackgroundTransparency = 1,
                    Font = Library.Font,
                    TextSize = 13,
                    Text = "",
                }, b)
                Library:Themed(mark, "TextColor3", "Accent")
                menuMarks[m[1]] = mark
                Library:Connect(b.MouseEnter, function()
                    Library:Tween(b, { BackgroundColor3 = Library.Theme.Element2, BackgroundTransparency = 0 }, 0.1)
                end)
                Library:Connect(b.MouseLeave, function()
                    Library:Tween(b, { BackgroundTransparency = 1 }, 0.1)
                end)
                Library:Connect(b.MouseButton1Click, function()
                    kb:SetMode(m[1])
                    Library:ClosePopups()
                end)
            end
            local kb2 = Library:Create("TextButton", {
                Size = UDim2.new(1, 0, 0, 30),
                AutoButtonColor = false,
                Text = "",
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, menu)
            Library:Corner(kb2, 6)
            menuKeyLbl = Library:Create("TextLabel", {
                Position = UDim2.new(0, 10, 0, 0),
                Size = UDim2.new(1, -20, 1, 0),
                BackgroundTransparency = 1,
                Font = Enum.Font.Code,
                TextSize = 12,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "Key: [NONE]",
            }, kb2)
            Library:Themed(menuKeyLbl, "TextColor3", "TextMuted")
            Library:Connect(kb2.MouseEnter, function()
                Library:Tween(kb2, { BackgroundColor3 = Library.Theme.Element2, BackgroundTransparency = 0 }, 0.1)
            end)
            Library:Connect(kb2.MouseLeave, function()
                Library:Tween(kb2, { BackgroundTransparency = 1 }, 0.1)
            end)
            Library:Connect(kb2.MouseButton1Click, function()
                Library:ClosePopups()
                kb:StartPicking()
            end)
        end
        for name, mark in pairs(menuMarks) do
            pcall(function() mark.Text = (mode == name) and "✓" or "" end)
        end
        pcall(function()
            menuKeyLbl.Text = "Key: " .. ((typeof(key) == "EnumItem") and ("[" .. key.Name .. "]") or "[NONE]")
        end)
        Library:ShowPopup(menu, anchor or btn, { width = 190 })
        Library:Punch(menu, 0.98)
    end
    function kb:SetVisibility(v) btn.Visible = v and true or false end
    function kb:Refresh()
        paint()
        Library:_pushKeybindList()
        return kb
    end

    Library:Connect(btn.MouseButton1Click, function() kb:StartPicking() end)
    Library:Connect(UserInputService.InputBegan, function(input, gpe)
        if picking and input.UserInputType == Enum.UserInputType.Keyboard then
            picking = false
            -- Backspace clears the bind instead of binding Backspace.
            if input.KeyCode == Enum.KeyCode.Backspace then
                key = nil
            else
                key = input.KeyCode
            end
            paint()
            fire()
            return
        end
        if gpe or key == nil then return end
        if input.KeyCode == key then
            if link then
                local newVal
                if mode == "Hold" then
                    newVal = true
                elseif mode == "Always" then
                    newVal = true
                else
                    newVal = not linkOn()
                end
                toggled = newVal
                kb._holdKey = (mode == "Hold")
                link:Set(newVal)
                kb._holdKey = false
                fire()
            elseif mode == "Always" then
                toggled = true
                fire()
            elseif mode == "Hold" then
                toggled = true
                fire()
            elseif mode == "Press" then
                -- One-shot: toggled state never flips or sticks, only fire.
                toggled = false
                fire()
            else
                toggled = not toggled
                fire()
            end
        end
    end)
    Library:Connect(UserInputService.InputEnded, function(input)
        if key ~= nil and input.KeyCode == key and mode == "Hold" then
            if link then
                toggled = false
                kb._holdKey = true
                link:Set(false)
                kb._holdKey = false
            else
                toggled = false
            end
            fire()
        end
    end)
    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if type(saved) == "table" then
            if typeof(saved.Key) == "EnumItem" or saved.Key == nil then
                key = saved.Key
            end
            if type(saved.Mode) == "string" then mode = saved.Mode end
            -- Press-only keybinds keep their mode even when a saved config
            -- (or stale flag) claims Toggle/Hold/Always.
            if pressOnly then mode = "Press" end
            toggled = saved.Toggled and true or false
            paint()
            if link then
                if mode == "Always" then
                    toggled = true
                    link:Set(true)
                elseif mode == "Hold" then
                    toggled = false
                    kb._holdKey = true
                    link:Set(false)
                    kb._holdKey = false
                end
            end
        end
    end, function()
        if link then
            toggled = linkOn()
        end
        fire()
    end)
    table.insert(Library._keybinds, kb)
    Library:_pushKeybindList()
    return kb
end

function Library.Sections:Keybind(data)
    local host = self:Label(data and (data.Name or "Keybind") or "Keybind")
    return host:Keybind(data)
end
