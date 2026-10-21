function Library.Sections:Textbox(data)
    data = data or {}
    local flag = data.Flag or Library:NextFlag()
    local val = tostring(data.Default or "")
    Library.Flags[flag] = val

    local row = Library:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
    }, self.Items.List)
    local lbl = Library:Create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(data.Name or flag),
    }, row)
    Library:Themed(lbl, "TextColor3", "Text")
    local box = Library:Create("TextBox", {
        Position = UDim2.new(0, 0, 0, 17),
        Size = UDim2.new(1, 0, 0, 18),
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = val,
        PlaceholderText = tostring(data.Placeholder or ""),
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
    }, row)
    Library:Themed(box, "BackgroundColor3", "Inline")
    Library:Themed(box, "TextColor3", "Text")
    Library:Corner(box, 6)
    local boxStroke = Library:Stroke(box, 1)
    Library:Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, box)
    Library:Connect(box.Focused, function()
        Library:Tween(boxStroke, { Color = Library.Theme.Accent }, 0.15)
    end)

    local tb = {}
    function tb:Get() return val end
    function tb:Set(v)
        val = tostring(v)
        box.Text = val
        Library.Flags[flag] = val
        if type(data.Callback) == "function" then task.spawn(data.Callback, val) end
    end
    function tb:SetVisibility(v) row.Visible = v and true or false end

    Library:TrackWidget(flag, function()
        local saved = Library.Flags[flag]
        if type(saved) == "string" then
            val = saved
            box.Text = val
        end
    end, function()
        local saved = Library.Flags[flag]
        if type(saved) == "string" then
            val = saved
            box.Text = val
        end
        if type(data.Callback) == "function" then task.spawn(data.Callback, val) end
    end)
    if type(data.Tooltip) == "string" and data.Tooltip ~= "" then
        Library:AttachTooltip(row, data.Tooltip)
    end

    Library:Connect(box.FocusLost, function(enter)
        Library:Tween(boxStroke, { Color = Library.Theme.Outline }, 0.15)
        local t = box.Text
        if data.Numeric then
            if t ~= "" and tonumber(t) == nil then
                box.Text = val
                return
            end
        end
        if data.Finished ~= false and not enter then return end
        tb:Set(t)
    end)
    return tb
end
