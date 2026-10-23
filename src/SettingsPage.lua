function Library:CreateSettingsPage(window)
    if window.SettingsPage then
        return window.SettingsPage
    end
    local page = self:Page(window, { Name = "Settings", Icon = "settings", IsSystem = true })
    -- System page like Home: sections live directly on the tab, no sub-tabs.
    local sec = self:Section(page, { Name = "Interface" })

    local menuRow = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
    }, sec.Items.List)
    local menuLbl = self:Create("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Menu key",
    }, menuRow)
    self:Themed(menuLbl, "TextColor3", "Text")
    local menuBtn = self:Create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.new(0, 100, 0, 22),
        AutoButtonColor = false,
        Font = Enum.Font.Code,
        TextSize = 12,
        BorderSizePixel = 0,
    }, menuRow)
    self:Themed(menuBtn, "BackgroundColor3", "Surface")
    self:Themed(menuBtn, "TextColor3", "Text")
    self:Corner(menuBtn, 0)
    self:Stroke(menuBtn, 1)
    local menuPicking = false
    local function menuPaint()
        menuBtn.Text = menuPicking and "[...]" or ("[" .. tostring(self.MenuKey):gsub("Enum.KeyCode.", "") .. "]")
    end
    menuPaint()
    self:Connect(menuBtn.MouseButton1Click, function()
        menuPicking = true
        menuPaint()
    end)
    self:Connect(UserInputService.InputBegan, function(input, gpe)
        if menuPicking and input.UserInputType == Enum.UserInputType.Keyboard then
            menuPicking = false
            self:SetMenuKeybind(input.KeyCode)
            self.Flags.__menukey = input.KeyCode.Name
            menuPaint()
        end
    end)
    self:TrackWidget("__menukey", function()
        local name = self.Flags.__menukey
        if type(name) == "string" and Enum.KeyCode[name] then
            self:SetMenuKeybind(Enum.KeyCode[name])
            menuPaint()
        end
    end)
    sec:Toggle({
        Name = "Keybind list",
        Flag = "__showkeybinds",
        Default = window.KeybindList ~= nil,
        Callback = function(v)
            if window.KeybindList then
                window.KeybindList:SetVisibility(v)
            end
        end,
    })
    if window.Watermark then
        sec:Toggle({
            Name = "Watermark",
            Flag = "__showwatermark",
            Default = true,
            Callback = function(v)
                if window.Watermark then
                    window.Watermark:SetVisibility(v)
                end
            end,
        })
        sec:Toggle({
            Name = "Watermark stats",
            Flag = "__watermarkstats",
            Default = window.Watermark.ShowStats ~= false,
            Callback = function(v)
                if window.Watermark then
                    window.Watermark:SetStatsEnabled(v)
                end
            end,
        })
    else
        sec:AddLabel("Watermark: disabled at boot")
    end
    if window.ToggleButton then
        sec:Toggle({
            Name = "Toggle button",
            Flag = "__showtogglebtn",
            Default = true,
            Callback = function(v)
                if window.ToggleButton then
                    window.ToggleButton:SetVisibility(v)
                end
            end,
        })
    end
    -- Element scales live together in their own section: window chrome,
    -- keybind list, watermark.
    local uiElements = self:Section(page, { Name = "UI Elements" })
    uiElements:Slider({
        Name = "UI Scale",
        Flag = "__uiscale",
        Min = 0.75,
        Max = 1.5,
        Default = 1,
        Decimals = 0.05,
        Suffix = "x",
        Live = false,
        Preview = function(v)
            self:PreviewUIScale(v)
        end,
        Callback = function(v)
            self:SetUIScale(v)
        end,
    })
    if window.KeybindList then
        uiElements:Slider({
            Name = "Keybind list scale",
            Flag = "__kblistscale",
            Min = 0.5,
            Max = 3,
            Default = window.KeybindList:GetScale(),
            Decimals = 0.05,
            Suffix = "x",
            Callback = function(v)
                if window.KeybindList then
                    window.KeybindList:SetScale(v)
                end
            end,
        })
        -- Config loads only repaint widgets; push the restored scale to the
        -- panel the same way LoadConfig does for the other __ flags.
        self:TrackWidget("__kblistscale", function()
            local s = tonumber(self.Flags.__kblistscale)
            if s then
                for _, w in ipairs(self._windows) do
                    if w.KeybindList then
                        pcall(function() w.KeybindList:SetScale(s) end)
                    end
                end
            end
        end)
    end
    if window.Watermark then
        uiElements:Slider({
            Name = "Watermark scale",
            Flag = "__wmscale",
            Min = 0.5,
            Max = 3,
            Default = window.Watermark:GetScale(),
            Decimals = 0.05,
            Suffix = "x",
            Callback = function(v)
                if window.Watermark then
                    window.Watermark:SetScale(v)
                end
            end,
        })
        self:TrackWidget("__wmscale", function()
            local s = tonumber(self.Flags.__wmscale)
            if s then
                for _, w in ipairs(self._windows) do
                    if w.Watermark then
                        pcall(function() w.Watermark:SetScale(s) end)
                    end
                end
            end
        end)
    end
    sec:Slider({
        Name = "Notify length",
        Flag = "__notifdur",
        Min = 1,
        Max = 10,
        Default = 4,
        Decimals = 1,
        Suffix = "s",
        Callback = function(v)
            self.NotifDuration = math.clamp(tonumber(v) or 4, 1, 30)
        end,
    })
    sec:Toggle({
        Name = "UI animations",
        Flag = "__anim",
        Default = true,
        Callback = function(v)
            self.AnimationsEnabled = v and true or false
        end,
    })
    sec:Toggle({
        Name = "Tooltips",
        Flag = "__tooltips",
        Default = true,
        Callback = function(v)
            self.TooltipsEnabled = v and true or false
            if not v and self._tooltip then
                self._tooltip.Visible = false
            end
        end,
    })
    sec:Button({
        Name = "Reset floating panels",
        Callback = function()
            if window.KeybindList then
                window.KeybindList:SetPosition(UDim2.new(1, -218, 0, 60))
            end
            if window.ToggleButton then
                window.ToggleButton:SetPosition(UDim2.new(0, 16, 0.5, -22))
            end
        end,
    })
    sec:Button({
        Name = "Unload UI",
        Callback = function() self:Unload() end,
    })

    local theme = self:Section(page, { Name = "Theming" })
    local names = {}
    for k in pairs(self.Presets) do table.insert(names, k) end
    table.sort(names)
    theme:Dropdown({
        Name = "Preset",
        Flag = "__theme",
        Items = names,
        Default = "DroidRed",
        Callback = function(v) self:ApplyThemePreset(v) end,
    })
    theme:AddButton({
        Name = "Random preset",
        Callback = function()
            local pool = {}
            for k in pairs(self.Presets) do table.insert(pool, k) end
            if #pool > 0 then
                self:ApplyThemePreset(pool[math.random(1, #pool)])
            end
        end,
    })
    theme:AddButton({
        Name = "Reset theme",
        Callback = function()
            self:ApplyThemePreset("DroidRed")
            self:SetBackgroundImage(self.DefaultBackgroundImage, self.DefaultBackgroundTransparency)
        end,
    })
    theme:AddTextbox({
        Name = "Background Image",
        Flag = "__bg_image",
        Placeholder = "Asset ID or URL",
        Callback = function(t)
            self:SetBackgroundImage(t, self.BackgroundTransparency)
        end,
    })
    theme:AddSlider({
        Name = "Background Transparency",
        Flag = "__bg_transparency",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Decimals = 0.05,
        Callback = function(v)
            self:SetBackgroundImage(self.BackgroundImage, v)
        end,
    })
    -- Window frame border controls (the box around the whole UI).
    theme:AddToggle({
        Name = "Window border",
        Flag = "__win_border",
        Default = self.WindowBorder.Enabled ~= false,
        Callback = function(v) self:SetWindowBorder({ Enabled = v }) end,
    })
    theme:AddSlider({
        Name = "Window border size",
        Flag = "__win_border_thickness",
        Min = 1,
        Max = 8,
        Default = self.WindowBorder.Thickness or 1,
        Decimals = 1,
        Callback = function(v) self:SetWindowBorder({ Thickness = v }) end,
    })
    theme:AddSlider({
        Name = "Window border alpha",
        Flag = "__win_border_alpha",
        Min = 0,
        Max = 1,
        Default = self.WindowBorder.Transparency or 0.05,
        Decimals = 0.05,
        Callback = function(v) self:SetWindowBorder({ Transparency = v }) end,
    })

    -- Custom outline controls. The colorpicker enables the tint; sliders
    -- shape it; the reset button hands control back to the theme outline.
    theme:AddColorpicker({
        Name = "Border Color",
        Flag = "__border_color",
        Default = self.Border.Color or self.Theme.Accent,
        Alpha = false,
        Callback = function(c) self:SetBorder({ Color = c }) end,
    })
    theme:AddSlider({
        Name = "Border Transparency",
        Flag = "__border_transparency",
        Min = 0,
        Max = 1,
        Default = self.Border.Transparency or 0,
        Decimals = 0.05,
        Callback = function(v) self:SetBorder({ Transparency = v }) end,
    })
    theme:AddSlider({
        Name = "Border Thickness",
        Flag = "__border_thickness",
        Min = 1,
        Max = 4,
        Default = self.Border.Thickness or 1,
        Decimals = 1,
        Callback = function(v) self:SetBorder({ Thickness = v }) end,
    })
    theme:AddButton({
        Name = "Reset border",
        Callback = function()
            self:SetBorder({ Color = false })
            self:SetBorder({ Transparency = 0, Thickness = 1 })
        end,
    })
    local keys = {}
    for k, v in pairs(self.Theme) do
        if typeof(v) == "Color3" then table.insert(keys, k) end
    end
    table.sort(keys)
    for _, k in ipairs(keys) do
        theme:AddColorpicker({
            Name = k,
            Flag = "__theme_" .. k,
            Default = self.Theme[k],
            Alpha = false, -- theme keys are Color3: no alpha channel to edit
            Callback = (function(key)
                return function(c) self:ChangeTheme(key, c) end
            end)(k),
        })
    end

    local cfg = self:Section(page, { Name = "Configs", Side = 2 })
    local status = cfg:AddLabel("Status: idle")
    local cfgName = "default"
    local clipStr = ""
    local autoDelay = 5

    local function setStatus(t)
        status:SetText("Status: " .. tostring(t))
    end

    cfg:AddTextbox({
        Name = "Config name",
        Flag = "__cfg_name",
        Placeholder = "default",
        Default = "default",
        Callback = function(t)
            if type(t) == "string" and t ~= "" then
                cfgName = t
                if Library:IsAutoSaveEnabled() then
                    Library:SetAutoSave(cfgName, Library.AutoSave.Delay or autoDelay)
                    setStatus("autosave -> " .. cfgName)
                end
            end
        end,
    })
    local list = cfg:AddDropdown({
        Name = "Saved",
        Flag = "__cfg_list",
        Items = Library:ListConfigs(),
        Callback = function(v)
            if type(v) == "string" and v ~= "" then
                cfgName = v
                if Library:IsAutoSaveEnabled() then
                    Library:SetAutoSave(cfgName, Library.AutoSave.Delay or autoDelay)
                    setStatus("autosave -> " .. cfgName)
                end
            end
        end,
    })
    local listOpen = list.SetOpen
    function list:SetOpen(o)
        if o then
            list:Refresh(Library:ListConfigs())
        end
        return listOpen(self, o)
    end
    cfg:AddButton({
        Name = "Refresh list",
        Callback = function()
            local found = Library:ListConfigs()
            list:Refresh(found)
            if #found > 0 then list:Set(found[1]) end
            setStatus(#found .. " saved")
        end,
    })
    local function doSave()
        if Library:SaveConfig(cfgName) then
            list:Refresh(Library:ListConfigs())
            setStatus("saved " .. cfgName)
        else
            setStatus("save failed")
        end
    end
    cfg:AddButton({
        Name = "Save",
        Callback = function()
            if type(cfgName) ~= "string" or cfgName == "" then
                setStatus("empty name")
                return
            end
            if Library:HasConfig(cfgName) then
                Library:Dialog({
                    Title = "Overwrite config?",
                    Text = "Config '" .. cfgName .. "' already exists. Overwrite it?",
                    Buttons = {
                        { Text = "Overwrite", Accent = true, Callback = doSave },
                        { Text = "Cancel" },
                    },
                })
            else
                doSave()
            end
        end,
    })
    cfg:AddButton({
        Name = "Load",
        Callback = function()
            if Library:LoadConfigFile(cfgName) then
                setStatus("loaded " .. cfgName)
            else
                setStatus("not found")
            end
        end,
    })
    cfg:AddButton({
        Name = "Delete",
        Callback = function()
            Library:DeleteConfig(cfgName)
            list:Refresh(Library:ListConfigs())
            setStatus("deleted " .. cfgName)
        end,
    })
    cfg:AddButton({
        Name = "Set autoload",
        Callback = function()
            Library:SetAutoloadConfig(cfgName)
            setStatus("autoload = " .. cfgName)
        end,
    })
    cfg:AddButton({
        Name = "Clear autoload",
        Callback = function()
            Library:ClearAutoloadConfig()
            setStatus("autoload cleared")
        end,
    })
    cfg:AddButton({
        Name = "Copy string",
        Callback = function()
            local s = Library:ExportConfigString()
            if Library:CopyConfigToClipboard() then
                setStatus("copied " .. tostring(#s) .. " chars")
            else
                setStatus("copy failed (no clipboard)")
            end
        end,
    })
    cfg:AddButton({
        Name = "Paste string",
        Callback = function()
            if Library:PasteConfigFromClipboard() then
                setStatus("pasted clipboard")
            else
                setStatus("clipboard empty/invalid")
            end
        end,
    })
    cfg:AddTextbox({
        Name = "Import JSON",
        Flag = "__cfg_clipboard",
        Placeholder = "paste config json...",
        Callback = function(t)
            clipStr = tostring(t or "")
        end,
    })
    cfg:AddButton({
        Name = "Import textbox",
        Callback = function()
            if clipStr == "" then
                setStatus("nothing to import")
                return
            end
            if Library:ImportConfigString(clipStr) then
                setStatus("imported string")
            else
                setStatus("import failed")
            end
        end,
    })
    cfg:Toggle({
        Name = "Auto-save",
        Flag = "__autosave_enabled",
        Default = false,
        Callback = function(v)
            if v then
                Library:SetAutoSave(cfgName, autoDelay)
                setStatus("autosave -> " .. cfgName)
            else
                Library:DisableAutoSave()
                setStatus("autosave off")
            end
        end,
    })
    cfg:Slider({
        Name = "Auto-save delay",
        Flag = "__autosave_delay",
        Min = 1,
        Max = 30,
        Default = 5,
        Decimals = 1,
        Suffix = "s",
        Callback = function(v)
            autoDelay = math.clamp(tonumber(v) or 5, 1, 60)
            if Library:IsAutoSaveEnabled() then
                Library.AutoSave.Delay = autoDelay
            end
        end,
    })
    window.SettingsPage = page
    return page
end
