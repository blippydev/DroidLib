function Library:Connect(event, fn)
    local ok, conn = pcall(event.Connect, event, fn)
    if ok and conn then
        table.insert(self._conns, conn)
        return conn
    end
    return nil
end

function Library:OnUnload(fn)
    if type(fn) == "function" then
        table.insert(self._unloadCbs, fn)
    end
end

function Library:Thread(fn)
    if type(fn) ~= "function" then return nil end
    local t = coroutine.create(fn)
    table.insert(self._threads, t)
    coroutine.wrap(function()
        local ok, err = coroutine.resume(t)
        if not ok then warn(err) end
    end)()
    return t
end

function Library:Create(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            pcall(function() inst[k] = v end)
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

function Library:Themed(inst, prop, key)
    table.insert(self._themeItems, { inst = inst, prop = prop, key = key })
    pcall(function() inst[prop] = self.Theme[key] end)
    return inst
end

function Library:Corner(parent, r)
    -- Linoria look: flat panels, no rounding. SquareCorners (LibraryTable)
    -- overrides whatever radius the caller asked for.
    if self.SquareCorners then r = 0 end
    return self:Create("UICorner", { CornerRadius = UDim.new(0, r or 6) }, parent)
end

function Library:Stroke(parent, thickness, key)
    local s = self:Create("UIStroke", {
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Thickness = thickness or 1,
    }, parent)
    self:Themed(s, "Color", key or "Outline")
    -- Global outline registry: SetBorder can re-tint/re-size any stroke the
    -- library created, so the "outline the UI" setting stays live.
    table.insert(self._strokeThickness, s)
    return s
end

function Library:Tween(inst, props, time)
    if self.AnimationsEnabled == false then
        pcall(function()
            for k, v in pairs(props or {}) do
                inst[k] = v
            end
        end)
        return
    end
    pcall(function()
        TweenService:Create(inst, TweenInfo.new(time or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end)
end

function Library:Drag(frame, handle)
    handle = handle or frame
    local dragging = false
    local startPos, startInput
    self:Connect(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startPos = frame.Position
            startInput = input.Position
        end
    end)
    self:Connect(UserInputService.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    self:Connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function Library:Punch(inst, from)
    local ui = self:Create("UIScale", { Scale = from or 0.94 }, inst)
    pcall(function()
        local tw = TweenService:Create(ui,
            TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 })
        tw:Play()
        task.delay(0.25, function() pcall(function() ui:Destroy() end) end)
    end)
end

function Library:NextFlag()
    self._flagN = (self._flagN or 0) + 1
    return "dw_flag_" .. tostring(self._flagN)
end

Library._widgets = {}

function Library:TrackWidget(flag, refresh)
    if type(refresh) ~= "function" then return end
    self._widgets[flag] = self._widgets[flag] or {}
    table.insert(self._widgets[flag], refresh)
end

function Library:ApplyFlags()
    for _, list in pairs(self._widgets) do
        for _, fn in ipairs(list) do
            pcall(fn)
        end
    end
    self:_pushKeybindList()
end

function Library:BringToFront(inst)
    if typeof(inst) == "Instance" and inst.Parent then
        local p = inst.Parent
        inst.Parent = nil
        inst.Parent = p
    end
end

function Library:ShowPopup(frame, anchorBtn, opts)
    opts = opts or {}
    self:ClosePopups()
    local ov = self.Overlay
    if not frame or not anchorBtn or not ov or not ov.Parent then return end
    self._openPopup = {
        frame = frame,
        parent = frame.Parent,
        pos = frame.Position,
        size = frame.Size,
    }
    frame.Parent = ov
    local bp = anchorBtn.AbsolutePosition
    local bs = anchorBtn.AbsoluteSize
    local op = ov.AbsolutePosition
    local w = opts.width or frame.Size.X.Offset
    if w <= 0 then w = bs.X end
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
    local x = bp.X - op.X + (opts.alignRight and (bs.X - w) or 0)
    x = math.clamp(x, 8, math.max(8, vp.X - w - 8))
    local y = bp.Y - op.Y + bs.Y + 4
    frame.Size = UDim2.new(0, w, frame.Size.Y.Scale, frame.Size.Y.Offset)
    frame.Position = UDim2.new(0, math.floor(x), 0, math.floor(y))
    frame.Visible = true
    self:BringToFront(ov)
    ov.Visible = true
    if opts.flip ~= false then
        self:Thread(function()
            task.wait()
            local cur = self._openPopup
            if cur and cur.frame == frame and frame.Visible and frame.Parent == ov then
                local h = frame.AbsoluteSize.Y
                if y + h > vp.Y - 8 then
                    local above = y - h - bs.Y - 8
                    frame.Position = UDim2.new(0, math.floor(x), 0, math.floor(math.max(8, above)))
                end
            end
        end)
    end
end

function Library:ClosePopups()
    local cur = self._openPopup
    self._openPopup = nil
    if cur and cur.frame then
        pcall(function()
            cur.frame.Visible = false
            cur.frame.Position = cur.pos
            cur.frame.Size = cur.size
            cur.frame.Parent = cur.parent
        end)
    end
    if self.Overlay then
        self.Overlay.Visible = false
    end
end
