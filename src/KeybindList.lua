function Library:KeybindList(data)
    data = data or {}
    local scale = tonumber(data.Scale) or 1
    if not (scale > 0) then scale = 1 end

    -- Base metrics at scale 1. Wide and short on purpose: a horizontal
    -- rectangle, title bar on top, bound keys in two columns below.
    local kl = { Items = {}, _scale = scale }
    local baseTitle = tostring(data.Title or "Keybinds")
    local dims = {}
    local function measure()
        local s = kl._scale
        dims.width = math.floor(340 * s + 0.5)
        dims.headH = math.max(20, math.floor(28 * s + 0.5))
        dims.headFont = math.max(10, math.floor(14 * s + 0.5))
        dims.rowH = math.max(14, math.floor(18 * s + 0.5))
        dims.rowFont = math.max(9, math.floor(12 * s + 0.5))
        dims.padX = math.max(6, math.floor(10 * s + 0.5))
        dims.gap = math.max(2, math.floor(4 * s + 0.5))
        -- Structured row cells: right block holds "MODE [KEY]" — the bind's
        -- behaviour tag plus the key, so the name gets the remaining room.
        dims.rightW = math.max(120, math.floor(160 * s + 0.5))
        dims.rowPad = math.max(4, math.floor(6 * s + 0.5))
    end
    measure()

    local frame = self:Create("Frame", {
        Name = "KeybindList",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = data.Position or UDim2.new(0, 12, 0.5, 0),
        Size = UDim2.new(0, dims.width, 0, 30),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Visible = data.Visible ~= false,
    }, self.Holder)
    self:Themed(frame, "BackgroundColor3", "Panel")
    self:Corner(frame, 8)
    self:Stroke(frame, 1, "OutlineSoft")

    -- Title header, top-left.
    local head = self:Create("TextLabel", {
        Position = UDim2.new(0, dims.padX, 0, 0),
        Size = UDim2.new(1, -dims.padX * 2, 0, dims.headH),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = dims.headFont,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Title or "Keybinds"),
    }, frame)
    self:Themed(head, "TextColor3", "Text")

    local div = self:Create("Frame", {
        Position = UDim2.new(0, 0, 0, dims.headH),
        Size = UDim2.new(1, 0, 0, 2),
        BorderSizePixel = 0,
    }, frame)
    self:Themed(div, "BackgroundColor3", "Accent")

    -- Entry area: full-width rows (one column), so each
    -- | name | STATE - [KEY] | row has room to breathe.
    local list = self:Create("Frame", {
        Position = UDim2.new(0, dims.padX, 0, dims.headH + 6),
        Size = UDim2.new(1, -dims.padX * 2, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, frame)
    local col = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, list)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Vertical,
        Padding = UDim.new(0, dims.gap),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, col)
    self:Drag(frame, head)

    kl.Items = { Frame = frame, List = list }

    local function applyMetrics()
        measure()
        frame.Size = UDim2.new(0, dims.width, 0, 30)
        head.Position = UDim2.new(0, dims.padX, 0, 0)
        head.Size = UDim2.new(1, -dims.padX * 2, 0, dims.headH)
        head.TextSize = dims.headFont
        div.Position = UDim2.new(0, 0, 0, dims.headH)
        div.Size = UDim2.new(1, 0, 0, 2)
        list.Position = UDim2.new(0, dims.padX, 0, dims.headH + 6)
        list.Size = UDim2.new(1, -dims.padX * 2, 0, 10)
        for _, kid in ipairs(col:GetChildren()) do
            if kid:IsA("UIListLayout") then
                kid.Padding = UDim.new(0, dims.gap)
            end
        end
    end

    function kl:Refresh()
        for _, c in ipairs(col:GetChildren()) do
            if c.Name == "KBRow" or c:IsA("TextLabel") then c:Destroy() end
        end
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        local rows = {}
        for _, kb in ipairs(Library._keybinds) do
            if type(kb.GetParts) == "function" then
                local ok, parts = pcall(kb.GetParts, kb)
                if ok and type(parts) == "table" then
                    rows[#rows + 1] = parts
                end
            elseif type(kb.GetText) == "function" then
                local ok, text, on = pcall(kb.GetText, kb)
                if ok and text then
                    rows[#rows + 1] = { legacy = tostring(text), on = on and true or false }
                end
            end
        end
        if #rows == 0 then
            head.Text = baseTitle .. " (0)"
            local row = Library:Create("TextLabel", {
                Size = UDim2.new(1, 0, 0, dims.rowH),
                BackgroundTransparency = 1,
                Font = Enum.Font.Code,
                TextSize = dims.rowFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = "none bound",
            }, list)
            Library:Themed(row, "TextColor3", "TextMuted")
            return
        end
        head.Text = baseTitle .. " (" .. #rows .. ")"
        -- Row anatomy: status dot | name | chip (MODE [KEY]).
        -- The chip lights up (Surface bg + Accent text) while the bind is
        -- ON and sinks to flat muted text while OFF.
        local function addRow(col, order, r)
            if r.legacy then
                local row = Library:Create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, dims.rowH),
                    BackgroundTransparency = 1,
                    Font = Enum.Font.Code,
                    TextSize = dims.rowFont,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Text = r.legacy,
                    LayoutOrder = order,
                }, col)
                Library:Themed(row, "TextColor3", r.on and "Text" or "TextMuted")
                return
            end
            local pad, rightW = dims.rowPad, dims.rightW
            local rowF = Library:Create("Frame", {
                Name = "KBRow",
                Size = UDim2.new(1, 0, 0, dims.rowH),
                BackgroundTransparency = 1,
                LayoutOrder = order,
            }, col)
            local dot = Library:Create("Frame", {
                AnchorPoint = Vector2.new(0, 0.5),
                Position = UDim2.new(0, pad, 0.5, 0),
                Size = UDim2.new(0, 6, 0, 6),
                BorderSizePixel = 0,
                BackgroundColor3 = r.on and Color3.fromRGB(90, 255, 110) or Color3.fromRGB(110, 110, 120),
            }, rowF)
            Library:Corner(dot, 3)
            local nameL = Library:Create("TextLabel", {
                Position = UDim2.new(0, pad + 12, 0, 0),
                Size = UDim2.new(1, -(rightW + pad * 2 + 14), 1, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Font = Enum.Font.Code,
                TextSize = dims.rowFont,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = tostring(r.name),
            }, rowF)
            Library:Themed(nameL, "TextColor3", r.on and "Text" or "TextMuted")
            local chip = Library:Create("Frame", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, 0, 0.5, 0),
                Size = UDim2.new(0, rightW, 0, dims.rowH),
                BorderSizePixel = 0,
                BackgroundTransparency = r.on and 0 or 0.6,
            }, rowF)
            Library:Themed(chip, "BackgroundColor3", "Surface")
            Library:Corner(chip, 0)
            Library:Stroke(chip, 1)
            local rightL = Library:Create("TextLabel", {
                Position = UDim2.new(0, 4, 0, 0),
                Size = UDim2.new(1, -8, 1, 0),
                BackgroundTransparency = 1,
                ClipsDescendants = true,
                Font = Enum.Font.Code,
                TextSize = dims.rowFont,
                TextXAlignment = Enum.TextXAlignment.Right,
                Text = tostring(r.mode) .. " [" .. tostring(r.key) .. "]",
            }, chip)
            Library:Themed(rightL, "TextColor3", r.on and "Accent" or "TextMuted")
        end
        -- Top-to-bottom, one full-width row per bind.
        for i, r in ipairs(rows) do
            addRow(col, i, r)
        end
    end

    function kl:SetVisibility(v)
        frame.Visible = v and true or false
    end

    function kl:SetPosition(pos)
        if typeof(pos) == "UDim2" then frame.Position = pos end
    end

    function kl:SetScale(s)
        s = tonumber(s)
        if not (s and s > 0) then return kl end
        kl._scale = math.clamp(s, 0.5, 3)
        applyMetrics()
        kl:Refresh()
        return kl
    end

    function kl:GetScale() return kl._scale end

    kl:Refresh()
    return kl
end

function Library:_pushKeybindList()
    for _, w in ipairs(self._windows) do
        if w.KeybindList then
            pcall(function() w.KeybindList:Refresh() end)
        end
    end
end
