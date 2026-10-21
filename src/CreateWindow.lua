function Library:CreateWindow(data)
    data = data or {}
    local window = self:Window(data)

    function window:AddTab(nameOrData, icon)
        local d
        if type(nameOrData) == "table" then
            d = nameOrData
        else
            d = { Name = nameOrData, Icon = icon }
        end
        local page = Library:Page(window, d, 1, nil)
        if window.SettingsPage and window.Pages[#window.Pages] ~= window.SettingsPage then
            for i, p in ipairs(window.Pages) do
                if p == window.SettingsPage then
                    table.remove(window.Pages, i)
                    break
                end
            end
            table.insert(window.Pages, window.SettingsPage)
            for i, p in ipairs(window.Pages) do
                if p.Items and p.Items.Button then
                    p.Items.Button.LayoutOrder = i
                end
            end
        end
        return page
    end

    function window:CreateHomePage(opts)
        return Library:CreateHomePage(window, opts)
    end

    Library:Connect(UserInputService.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == Library.MenuKey then
            window:SetOpen(not window.IsOpen)
        end
    end)

    -- Header search filters controls by name across every tab.
    if window.Items.Search then
        Library:Connect(window.Items.Search:GetPropertyChangedSignal("Text"), function()
            window:Search(window.Items.Search.Text)
        end)
    end

    if data.HomeTabEnabled ~= false then
        Library:CreateHomePage(window, data.HomeOptions)
    end

    if data.WatermarkEnabled then
        window.Watermark = Library:Watermark({
            Text = data.WatermarkText or data.Name or "DWLib",
            Stats = data.WatermarkStats ~= false,
            Scale = data.WatermarkScale,
        })
    end

    if data.KeybindListEnabled then
        window.KeybindList = Library:KeybindList({
            Visible = data.KeybindListVisible ~= false,
            Scale = data.KeybindListScale,
            Position = data.KeybindListPosition,
        })
    end

    if data.ESPPreviewEnabled then
        window.ESPPreview = Library:ESPPreview({
            Position = data.ESPPreviewPosition,
            Scale = data.ESPPreviewScale,
            Title = data.ESPPreviewTitle,
            Flags = data.ESPPreviewFlags or {},
            Target = data.ESPPreviewTarget,
        })
    end

    local showToggle = data.ToggleButtonEnabled
    if showToggle == nil then
        showToggle = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    end
    if showToggle then
        window.ToggleButton = Library:ToggleButton(window, {
            Position = data.ToggleButtonPosition,
            Size = data.ToggleButtonSize,
        })
    end

    if data.SettingsTabEnabled ~= false then
        Library:CreateSettingsPage(window)
    end

    window:SelectFirst()
    if data.DevMode ~= nil then
        window:SetEnvPill(data.DevMode and true or false)
    end
    return window
end

function Library:SetMenuKeybind(key)
    if typeof(key) == "EnumItem" then
        self.MenuKey = key
        local name = tostring(key):gsub("Enum.KeyCode.", "")
        for _, w in ipairs(self._windows) do
            if w.Items and w.Items.FootKey then
                pcall(function()
                    w.Items.FootKey.Text = "[" .. name .. "] - menu"
                end)
            end
        end
    end
end
