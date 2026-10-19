function Library.Pages:AddSection(nameOrData, icon)
    local d
    if type(nameOrData) == "table" then d = nameOrData
    elseif icon ~= nil then d = { Name = nameOrData, Icon = icon }
    else d = { Name = nameOrData } end
    return self:Section(d)
end

function Library.Sections:AddToggle(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Toggle(nameOrData) end
    local d = { Name = nameOrData }
    if type(extra) == "table" then for k, v in pairs(extra) do d[k] = v end end
    return self:Toggle(d)
end

function Library.Sections:AddButton(nameOrData, cb)
    if type(nameOrData) == "table" then return self:Button(nameOrData) end
    return self:Button({ Name = nameOrData, Callback = cb })
end

function Library.Sections:AddSlider(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Slider(nameOrData) end
    return self:Slider({ Name = nameOrData })
end

function Library.Sections:AddDropdown(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Dropdown(nameOrData) end
    return self:Dropdown({ Name = nameOrData })
end

function Library.Sections:AddLabel(textOrData)
    if type(textOrData) == "table" then return self:Label(textOrData) end
    return self:Label(textOrData)
end

function Library.Sections:AddTextbox(nameOrData, extra)
    if type(nameOrData) == "table" then return self:Textbox(nameOrData) end
    return self:Textbox({ Name = nameOrData })
end

function Library.Sections:AddKeybind(data)
    return self:Keybind(data or {})
end
