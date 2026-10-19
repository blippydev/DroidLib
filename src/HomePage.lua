function Library:CreateHomePage(window, opts)
    if window.HomePage then
        return window.HomePage
    end
    if type(opts) ~= "table" then opts = {} end

    local page = self:Page(window, { Name = opts.tabName or "Home", Icon = opts.icon or "house", IsSystem = true }, 1, nil)
    page.Items.Left.Visible = false
    page.Items.Right.Visible = false

    local holder = page.Items.Holder
    local scroll = self:Create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        ScrollBarThickness = 2,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, holder)
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 6),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, scroll)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 2),
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 8),
    }, scroll)

    -- Card 1: welcome banner.
    local banner = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, scroll)
    self:Themed(banner, "BackgroundColor3", "Panel")
    self:Corner(banner, 0)
    self:Stroke(banner, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, banner)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
    }, banner)

    -- Welcome row with live stats on the right.
    local top = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, banner)
    local avatar = self:Create("ImageLabel", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(0, 40, 0, 40),
        BorderSizePixel = 0,
        BackgroundColor3 = Color3.fromRGB(35, 35, 42),
    }, top)
    self:Corner(avatar, 0)
    local avatarRing = self:Stroke(avatar, 1, "Outline")
    task.spawn(function()
        pcall(function()
            local me = Players.LocalPlayer
            if me then
                avatar.Image = Players:GetUserThumbnailAsync(
                    me.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
            end
        end)
    end)
    local welcome = self:Create("TextLabel", {
        Position = UDim2.new(0, 50, 0, 1),
        Size = UDim2.new(0, 300, 0, 13),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = "Welcome back,",
    }, top)
    self:Themed(welcome, "TextColor3", "TextMuted")
    local who = self:Create("TextLabel", {
        Position = UDim2.new(0, 50, 0, 14),
        Size = UDim2.new(0, 300, 0, 20),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = Players.LocalPlayer and Players.LocalPlayer.DisplayName or "Player",
    }, top)
    self:Themed(who, "TextColor3", "Text")
    local sub2 = self:Create("TextLabel", {
        Position = UDim2.new(0, 50, 0, 34),
        Size = UDim2.new(0, 300, 0, 13),
        BackgroundTransparency = 1,
        Font = Enum.Font.Code,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
        Text = tostring(opts.subtitle or "#1 Script HUB"),
    }, top)
    self:Themed(sub2, "TextColor3", "TextMuted")

    local statValues = {}
    local function statCell(parent, label, iconName, order)
        local cell = self:Create("Frame", {
            Size = UDim2.new(0.25, -6, 0, 38),
            BorderSizePixel = 0,
            LayoutOrder = order,
        }, parent)
        self:Themed(cell, "BackgroundColor3", "Panel")
        self:Corner(cell, 0)
        self:Stroke(cell, 1, "OutlineSoft")
        local iconImg = self:GetIcon(iconName)
        if iconImg then
            local ic = self:Create("ImageLabel", {
                Position = UDim2.new(0, 10, 0.5, -7),
                Size = UDim2.new(0, 14, 0, 14),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Image = iconImg,
                ScaleType = Enum.ScaleType.Fit,
            }, cell)
            self:Themed(ic, "ImageColor3", "Accent")
        end
        local l = self:Create("TextLabel", {
            Size = UDim2.new(1, -38, 0, 12),
            Position = UDim2.new(0, 30, 0, 5),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = label,
        }, cell)
        self:Themed(l, "TextColor3", "TextMuted")
        local v = self:Create("TextLabel", {
            Position = UDim2.new(0, 30, 0, 18),
            Size = UDim2.new(1, -38, 0, 16),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = "--",
        }, cell)
        self:Themed(v, "TextColor3", "Text")
        statValues[label] = v
    end
    -- Card 2: one line of stat pills (standalone, no card behind them).
    local statsStrip = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundTransparency = 1,
        LayoutOrder = 2,
    }, scroll)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, statsStrip)
    statCell(statsStrip, "Players", "users", 1)
    statCell(statsStrip, "Ping", "wifi", 2)
    statCell(statsStrip, "FPS", "gauge", 3)
    statCell(statsStrip, "Uptime", "timer", 4)

    local frames = 0
    self:Connect(RunService.RenderStepped, function()
        frames = frames + 1
    end)
    local bootTick = tick()
    self:Thread(function()
        while not self.Unloading do
            task.wait(1)
            if self.Unloading then break end
            local fps = frames
            frames = 0
            local up = math.floor(tick() - bootTick)
            local upText = (math.floor(up / 60) > 0 and (math.floor(up / 60) .. "m ") or "") .. (up % 60) .. "s"
            local ping = nil
            pcall(function()
                ping = math.floor(Players.LocalPlayer:GetNetworkPing() * 1000 + 0.5)
            end)
            local count, max = nil, nil
            pcall(function()
                count = #Players:GetPlayers()
                max = Players.MaxPlayers
            end)
            pcall(function()
                if statValues.Players.Parent then
                    statValues.Players.Text = (count and max) and (count .. "/" .. max) or "--"
                end
                if statValues.FPS.Parent then statValues.FPS.Text = tostring(fps) end
                if statValues.Ping.Parent then statValues.Ping.Text = ping and (ping .. "ms") or "--" end
                if statValues.Uptime.Parent then statValues.Uptime.Text = upText end
            end)
        end
    end)

    -- Card 3: credits + game info as two separated sub-cards.
    local infoCard = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    }, scroll)
    self:Themed(infoCard, "BackgroundColor3", "Panel")
    self:Corner(infoCard, 0)
    self:Stroke(infoCard, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, infoCard)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 8),
        PaddingBottom = UDim.new(0, 8),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, infoCard)

    local infoRow = self:Create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
    }, infoCard)
    self:Create("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, infoRow)

    local function colTitle(parent, text)
        local row = self:Create("Frame", {
            Size = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
        }, parent)
        local t = self:Create("TextLabel", {
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Text = tostring(text),
        }, row)
        self:Themed(t, "TextColor3", "Text")
        return t
    end

    local function colLine(parent, text)
        local l = self:Create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Font = Library.Font,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Text = tostring(text),
        }, parent)
        self:Themed(l, "TextColor3", "TextMuted")
        return l
    end

    local leftCol = self:Create("Frame", {
        Size = UDim2.new(0.5, -5, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    }, infoRow)
    self:Themed(leftCol, "BackgroundColor3", "Panel")
    self:Corner(leftCol, 0)
    self:Stroke(leftCol, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, leftCol)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, leftCol)
    colTitle(leftCol, "Credits")
    for _, creditLine in ipairs(opts.credits or { "Lead Dev: DROIDWARE", "UI Library: DWLib V1" }) do
        colLine(leftCol, creditLine)
    end

    local rightCol = self:Create("Frame", {
        Size = UDim2.new(0.5, -5, 0, 10),
        AutomaticSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    }, infoRow)
    self:Themed(rightCol, "BackgroundColor3", "Panel")
    self:Corner(rightCol, 0)
    self:Stroke(rightCol, 1, "OutlineSoft")
    self:Create("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, rightCol)
    self:Create("UIPadding", {
        PaddingTop = UDim.new(0, 7),
        PaddingBottom = UDim.new(0, 7),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
    }, rightCol)
    colTitle(rightCol, "Game Info")
    -- Prefer an explicit override, otherwise resolve the real game name from
    -- the marketplace and fall back to the window branding while it loads.
    if type(opts.gameName) == "string" and opts.gameName ~= "" then
        colLine(rightCol, "Game: " .. opts.gameName)
    else
        local fallback = window.SubName
        if type(fallback) ~= "string" or fallback == "" then fallback = window.Name end
        local gameLine = colLine(rightCol, "Game: " .. tostring(fallback))
        task.spawn(function()
            local ok, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
            end)
            local resolved = nil
            if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
                resolved = info.Name
            elseif type(game.Name) == "string" and game.Name ~= "" then
                resolved = game.Name
            end
            if resolved then
                pcall(function()
                    if gameLine.Parent then
                        gameLine.Text = "Game: " .. resolved
                    end
                end)
            end
        end)
    end
    colLine(rightCol, "Place ID: " .. tostring(game.PlaceId))
    colLine(rightCol, "Game ID: " .. tostring(game.GameId))
    colLine(rightCol, "Job ID: " .. tostring(game.JobId))
    local discord = tostring(opts.discordLink or "")
    local fakeSection = { Items = { List = rightCol }, Window = window, Page = page }
    self.Sections.Button(fakeSection, {
        Name = "Copy Discord",
        Callback = function()
            if discord ~= "" then
                local ok = pcall(setclipboard, discord)
                self:Notification("Discord", ok and "Link copied!" or discord, 3)
            else
                self:Notification("Discord", "No link set.", 3)
            end
        end,
    })

    window.HomePage = page
    return page, statValues
end
