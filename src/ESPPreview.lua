-- ESP preview panel: a floating window (KeybindList chrome) that mirrors the
-- live LocalPlayer character into a ViewportFrame and draws flag-driven ESP
-- overlays on top of it. The character animates like the player because every
-- limb CFrame is copied from the real rig each RenderStepped — the clone runs
-- zero scripts.
--
-- Flag contract (data.Flags):
--   Enabled  = flag (boolean or any value the user's ESP toggles)
--   Box, Skeleton, Tracer, Name, Health, Distance = toggle flags
--   Chams    = toggle flag (or a second color flag, see ChamsColor)
--   Color    = colorpicker flag (box/tracer/skeleton/name tint)
--
-- Overlays are positioned with a manual pinhole projection of the viewport
-- camera; the stub Camera's WorldToViewportPoint does not track ViewportFrame
-- sizing, so the math is done here and the viewport camera only carries CFrame
-- and FieldOfView.

function Library:ESPPreview(data)
    data = data or {}
    local scale = math.clamp(tonumber(data.Scale) or 1, 0.5, 3)
    local flags = data.Flags or {}

    local function readFlag(name, kind)
        local f = flags[name]
        if f == nil or f == "" then return nil end
        local v = self.Flags[f]
        if v == nil then return nil end
        if kind == "color" then
            return typeof(v) == "Color3" and v or nil
        elseif kind == "number" then
            return tonumber(v)
        end
        return v and true or false
    end
    local function on(name)
        return readFlag(name) and true or false
    end

    local dims = {
        width = 240, headH = 24, footH = 18, bodyH = 250, font = 12, pad = 8,
    }
    local function applyScale(s)
        dims.width = math.floor(240 * s + 0.5)
        dims.headH = math.max(20, math.floor(24 * s + 0.5))
        dims.footH = math.max(16, math.floor(18 * s + 0.5))
        dims.bodyH = math.floor(250 * s + 0.5)
        dims.font = math.max(9, math.floor(12 * s + 0.5))
        dims.pad = math.max(4, math.floor(8 * s + 0.5))
    end
    applyScale(scale)

    -- Floating panel, same chrome family as the KeybindList.
    local root = self:Create("Frame", {
        Name = "ESPPreview",
        Position = data.Position or UDim2.new(1, -(dims.width + 218), 0, 60),
        Size = UDim2.new(0, dims.width, 0, dims.headH + dims.bodyH + dims.footH + 7),
        BorderSizePixel = 0,
        Active = true,
    }, self.Holder)
    self:Themed(root, "BackgroundColor3", "Panel")
    self:Corner(root, 8)
    self:Stroke(root, 1, "OutlineSoft")

    local head = self:Create("TextLabel", {
        Position = UDim2.new(0, dims.pad, 0, 0),
        Size = UDim2.new(1, -dims.pad * 2, 0, dims.headH),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = dims.font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = tostring(data.Title or "ESP Preview"),
    }, root)
    self:Themed(head, "TextColor3", "Text")

    local div = self:Create("Frame", {
        Position = UDim2.new(0, dims.pad, 0, dims.headH),
        Size = UDim2.new(1, -dims.pad * 2, 0, 1),
        BorderSizePixel = 0,
    }, root)
    self:Themed(div, "BackgroundColor3", "OutlineSoft")

    -- Viewport body. Overlay is a child of the view, so its coordinates are
    -- the viewport's pixel space directly.
    local view = self:Create("ViewportFrame", {
        Position = UDim2.new(0, dims.pad, 0, dims.headH + 6),
        Size = UDim2.new(1, -dims.pad * 2, 0, dims.bodyH),
        BorderSizePixel = 0,
    }, root)
    self:Themed(view, "BackgroundColor3", "Background")
    local world = Instance.new("WorldModel")
    world.Parent = view

    local overlay = self:Create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, view)

    local foot = self:Create("TextLabel", {
        Position = UDim2.new(0, dims.pad, 1, -dims.footH),
        Size = UDim2.new(1, -dims.pad * 2, 0, dims.footH),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = math.max(8, dims.font - 2),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Text = "no character",
    }, root)
    self:Themed(foot, "TextColor3", "TextMuted")

    self:Drag(root, head)

    -- ------------------------------------------------------------------
    -- Overlay constructs. Created once, driven per-frame by projection.
    -- ------------------------------------------------------------------
    -- Vertical strip whose height is set per line; rotated about its center.
    -- a/b are viewport-space Vector2; thickness is 1px.
    local function makeStrip()
        local f = self:Create("Frame", {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.new(0, 1, 0, 1),
            BorderSizePixel = 0,
            Visible = false,
        }, overlay)
        return f
    end
    local function placeStrip(f, a, b, color)
        local d = b - a
        if d.Magnitude < 1.5 then
            f.Visible = false
            return
        end
        f.Visible = true
        f.Position = UDim2.new(0, (a.X + b.X) * 0.5, 0, (a.Y + b.Y) * 0.5)
        f.Size = UDim2.new(0, 1, 0, d.Magnitude)
        f.Rotation = math.deg(math.atan2(-d.X, d.Y))
        f.BackgroundColor3 = color
    end

    local boxL, boxR = makeStrip(), makeStrip()
    local boxT, boxB = makeStrip(), makeStrip()
    local tracer = makeStrip()
    local skeleton = {}
    for _ = 1, 13 do
        skeleton[#skeleton + 1] = makeStrip()
    end

    -- Vertical health bar, left of the box.
    local hpTrack = self:Create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        BorderSizePixel = 0,
        Visible = false,
    }, overlay)
    self:Themed(hpTrack, "BackgroundColor3", "Inline")
    local hpFill = self:Create("Frame", {
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        BorderSizePixel = 0,
    }, hpTrack)

    local nameL = self:Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 1),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = dims.font,
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
    }, overlay)
    local distL = self:Create("TextLabel", {
        AnchorPoint = Vector2.new(0.5, 0),
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundTransparency = 1,
        Font = Library.Font,
        TextSize = math.max(8, dims.font - 2),
        TextXAlignment = Enum.TextXAlignment.Center,
        Visible = false,
    }, overlay)
    self:Themed(distL, "TextColor3", "TextMuted")

    local green = Color3.fromRGB(90, 255, 110)
    local red = Color3.fromRGB(255, 60, 60)

    -- ------------------------------------------------------------------
    -- Character mirror.
    -- ------------------------------------------------------------------
    local Players = game:GetService("Players")
    local charRef = nil          -- live character instance
    local clone = nil            -- preview clone in the WorldModel
    local cloneParts = nil       -- [name] -> clone BasePart
    local liveParts = nil        -- [name] -> live BasePart
    local chams = nil            -- Highlight on the clone
    local charName = nil

    -- Target selection: nil defaults to LocalPlayer.Character. Also accepts
    -- a Model, a Player (follows their .Character), or a function returning
    -- either (re-resolved every poll, so "follow my aim target" modes work).
    local targetOverride = data.Target
    local function resolveTarget()
        local t = targetOverride
        if type(t) == "function" then
            local ok, v = pcall(t)
            if ok then t = v else t = nil end
        end
        if typeof(t) == "Instance" then
            if t:IsA("Player") then t = t.Character end
            if typeof(t) == "Instance" and t.Parent then return t end
            return nil
        end
        local char = Players.LocalPlayer.Character
        return (typeof(char) == "Instance" and char.Parent) and char or nil
    end

    local function clearOverlays()
        for _, f in ipairs({ boxL, boxR, boxT, boxB, tracer, hpTrack, nameL, distL }) do
            f.Visible = false
        end
        for _, l in ipairs(skeleton) do
            l.Visible = false
        end
    end

    local function buildMirror()
        local char = resolveTarget()
        if clone then
            clone:Destroy()
            clone, cloneParts, liveParts = nil, nil, nil
        end
        charRef = (typeof(char) == "Instance" and char.Parent) and char or nil
        charName = charRef and charRef.Name or nil
        clearOverlays()
        if not charRef then
            foot.Text = "no character"
            return
        end
        local ok, c = pcall(function()
            charRef.Archivable = true
            return charRef:Clone()
        end)
        if not ok or typeof(c) ~= "Instance" then
            foot.Text = "mirror failed"
            return
        end
        -- Scripts AND the Humanoid die: nothing in the clone may evaluate or
        -- simulate. All parts get anchored, so the manual CFrame mirror is
        -- the only thing that can move them (with a Humanoid present, the
        -- WorldModel physics step would fight the mirror and the puppet
        -- would sag or drift).
        for _, d in ipairs(c:GetDescendants()) do
            if d:IsA("BaseScript") or d:IsA("Script") or d:IsA("LocalScript") or d:IsA("ModuleScript") then
                d:Destroy()
            elseif d:IsA("Humanoid") then
                d:Destroy()
            end
        end
        clone = c
        cloneParts, liveParts = {}, {}
        for _, p in ipairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.Anchored = true
                cloneParts[p.Name] = p
            end
        end
        for _, p in ipairs(charRef:GetDescendants()) do
            if p:IsA("BasePart") then
                liveParts[p.Name] = p
            end
        end
        if chams then chams:Destroy() end
        chams = Instance.new("Highlight")
        chams.FillTransparency = 0.55
        chams.OutlineTransparency = 0
        chams.Enabled = false
        chams.Parent = c
        c.Parent = world
        foot.Text = "preview · " .. tostring(charName or "?")
    end

    self:Connect(Players.LocalPlayer.CharacterAdded, function()
        task.defer(buildMirror)
    end)
    self:Connect(Players.LocalPlayer.CharacterRemoving, function()
        charRef, clone, cloneParts, liveParts = nil, nil, nil, nil
        if chams then chams:Destroy() chams = nil end
        clearOverlays()
        foot.Text = "no character"
    end)
    -- Late characters + target switches: rebuild whenever the resolved
    -- target instance changes (respawn, dropdown switch, aim target swap).
    self:Thread(function()
        while not self.Unloading do
            task.wait(1.5)
            if self.Unloading then break end
            local ch = resolveTarget()
            if ch ~= charRef then
                buildMirror()
            elseif (not clone) and ch then
                buildMirror()
            end
        end
    end)

    -- ------------------------------------------------------------------
    -- Skeleton topology, resolved by part name against the mirror maps. Rig
    -- type comes from the LIVE character (the clone carries no Humanoid).
    -- ------------------------------------------------------------------
    local function rigPairs()
        local hum = charRef and charRef:FindFirstChildOfClass("Humanoid")
        if not hum then return nil end
        if hum.RigType == Enum.HumanoidRigType.R15 then
            return {
                { "Head", "UpperTorso" },
                { "UpperTorso", "LowerTorso" },
                { "UpperTorso", "LeftUpperArm" },
                { "UpperTorso", "RightUpperArm" },
                { "LeftUpperArm", "LeftLowerArm" },
                { "RightUpperArm", "RightLowerArm" },
                { "LeftLowerArm", "LeftHand" },
                { "RightLowerArm", "RightHand" },
                { "LowerTorso", "LeftUpperLeg" },
                { "LowerTorso", "RightUpperLeg" },
                { "LeftUpperLeg", "LeftLowerLeg" },
                { "RightUpperLeg", "RightLowerLeg" },
                { "LeftLowerLeg", "LeftFoot" },
                { "RightLowerLeg", "RightFoot" },
            }
        end
        return {
            { "Head", "Torso" },
            { "Torso", "Left Arm" },
            { "Torso", "Right Arm" },
            { "Torso", "Left Leg" },
            { "Torso", "Right Leg" },
        }
    end

    -- ------------------------------------------------------------------
    -- Viewport camera + projection.
    -- ------------------------------------------------------------------
    local camCF = CFrame.new(0, 5, -20)
    local cam = Instance.new("Camera")
    cam.CFrame = camCF
    cam.FieldOfView = 55
    cam.Parent = view
    view.CurrentCamera = cam

    local FOV = 55
    -- Returns nx, ny (viewport pixels) or nil when behind camera.
    local function project(worldPos)
        local lp = camCF:PointToObjectSpace(worldPos)
        if lp.Z >= -0.1 then return nil end
        local size = view.AbsoluteSize
        if size.X < 8 or size.Y < 8 then return nil end
        local f = 0.5 / math.tan(math.rad(FOV) * 0.5)
        return size.X * 0.5 + (lp.X / -lp.Z) * f * size.Y,
            size.Y * 0.5 - (lp.Y / -lp.Z) * f * size.Y
    end

    -- ------------------------------------------------------------------
    -- Per-frame pass.
    -- ------------------------------------------------------------------
    local function frameLoop()
        if not clone or not clone.Parent or not charRef then
            clearOverlays()
            return
        end
        local liveHrp = charRef:FindFirstChild("HumanoidRootPart")
        local cloneHrp = cloneParts and cloneParts.HumanoidRootPart
        if not liveHrp or not cloneHrp then
            clearOverlays()
            return
        end

        -- Mirror every limb CFrame (live pose -> preview pose).
        for name, part in pairs(cloneParts) do
            local lp2 = liveParts[name]
            if lp2 then
                pcall(function()
                    part.CFrame = lp2.CFrame
                end)
            end
        end

        -- Camera: fixed-back view, tall enough to frame the whole rig.
        local ext = clone:GetExtentsSize()
        local dist = math.max(6, ext.Y * 2.2)
        camCF = CFrame.lookAt(
            liveHrp.Position + Vector3.new(0, ext.Y * 0.05, -dist),
            liveHrp.Position
        )
        cam.CFrame = camCF

        clearOverlays() -- redraw below
        local size = view.AbsoluteSize
        if size.X < 8 or size.Y < 8 then return end

        local espOn = on("Enabled")
        local espColor = readFlag("Color", "color") or Library.Theme.Accent
        local chamColor = readFlag("ChamsColor", "color") or espColor

        -- Chams ride the highlight regardless of box geometry.
        if chams then
            chams.Enabled = espOn and on("Chams")
            chams.FillColor = chamColor
            chams.OutlineColor = espColor
        end
        if not espOn then return end

        local sx, sy = project(liveHrp.Position)
        if not sx then return end
        local halfY = ext.Y * 0.5
        local tx, ty = project(liveHrp.Position + Vector3.new(0, halfY, 0))
        local bx, by = project(liveHrp.Position - Vector3.new(0, halfY, 0))

        -- Tracer first: independent of box projection.
        if tx and on("Tracer") then
            placeStrip(tracer, Vector2.new(size.X * 0.5, size.Y - 1), Vector2.new(tx, ty), espColor)
        end

        if tx and bx then
            local cx = (tx + bx) * 0.5
            local topY = ty - 3
            local botY = by + 3
            local h = math.abs(botY - topY)
            if h > 8 then
                -- Box: four 1px edges around the player.
                if on("Box") then
                    local w = h * 0.45
                    placeStrip(boxL, Vector2.new(cx - w * 0.5, topY), Vector2.new(cx - w * 0.5, botY), espColor)
                    placeStrip(boxR, Vector2.new(cx + w * 0.5, topY), Vector2.new(cx + w * 0.5, botY), espColor)
                    placeStrip(boxT, Vector2.new(cx - w * 0.5, topY), Vector2.new(cx + w * 0.5, topY), espColor)
                    placeStrip(boxB, Vector2.new(cx - w * 0.5, botY), Vector2.new(cx + w * 0.5, botY), espColor)

                    -- Health bar left of the box, straight from live hp.
                    if on("Health") then
                        local liveHum = charRef:FindFirstChildOfClass("Humanoid")
                        local hpMax = liveHum and math.max(1, liveHum.MaxHealth) or 100
                        local hp = liveHum and math.clamp(liveHum.Health / hpMax, 0, 1) or 1
                        hpTrack.Size = UDim2.new(0, 5, 0, h)
                        hpTrack.Position = UDim2.new(0, cx - w * 0.5 - 5, 0, (topY + botY) * 0.5)
                        hpFill.Size = UDim2.new(1, 0, hp, 0)
                        hpFill.BackgroundColor3 = green:Lerp(red, 1 - hp)
                        hpTrack.Visible = true
                    end
                end

                -- Name above the box.
                if on("Name") then
                    nameL.Visible = true
                    nameL.TextSize = dims.font
                    nameL.Position = UDim2.new(0, cx, 0, topY - dims.font - 2)
                    nameL.TextColor3 = espColor
                    nameL.Text = tostring(data.NameText or charName or "Player")
                end

                -- Distance under the box, measured to the real camera.
                if on("Distance") then
                    local wcam = workspace.CurrentCamera
                    if typeof(wcam) == "Instance" then
                        local d = (wcam.CFrame.Position - liveHrp.Position).Magnitude
                        distL.Visible = true
                        distL.Position = UDim2.new(0, cx, 0, botY + 3)
                        distL.Text = math.floor(d + 0.5) .. " m"
                    end
                end
            end
        end

        -- Skeleton.
        local pairsList = rigPairs()
        if pairsList and on("Skeleton") then
            for i, l in ipairs(skeleton) do
                local pr = pairsList[i]
                if not pr then break end
                local pa = cloneParts[pr[1]]
                local pb = cloneParts[pr[2]]
                if pa and pb then
                    local sxa, sya = project(pa.Position)
                    local sxb, syb = project(pb.Position)
                    if sxa and sxb then
                        placeStrip(l, Vector2.new(sxa, sya), Vector2.new(sxb, syb), espColor)
                    end
                end
            end
        end
    end

    self:Connect(RunService.RenderStepped, frameLoop)

    -- ------------------------------------------------------------------
    -- Foot strip: character + active feature count, cheap 0.5s poll.
    -- ------------------------------------------------------------------
    self:Thread(function()
        while not self.Unloading do
            task.wait(0.5)
            if self.Unloading then break end
            pcall(function()
                local n = 0
                for k in pairs(flags) do
                    if k ~= "Color" and k ~= "ChamsColor" and k ~= "Enabled" and on(k) then
                        n = n + 1
                    end
                end
                local base = (charName and ("preview · " .. charName)) or "no character"
                foot.Text = base .. " · " .. n .. " active"
            end)
        end
    end)

    local ep = { _scale = scale }
    function ep:SetTarget(t)
        targetOverride = t
        buildMirror()
        return ep
    end
    function ep:GetTarget() return resolveTarget() end
    function ep:SetVisibility(v)
        root.Visible = v and true or false
    end
    function ep:SetPosition(pos)
        if typeof(pos) == "UDim2" then root.Position = pos end
    end
    function ep:SetFlags(map)
        if type(map) == "table" then
            for k, v in pairs(map) do flags[k] = v end
        end
        return ep
    end
    function ep:SetScale(s)
        s = tonumber(s)
        if not (s and s > 0) then return ep end
        ep._scale = math.clamp(s, 0.5, 3)
        applyScale(ep._scale)
        root.Size = UDim2.new(0, dims.width, 0, dims.headH + dims.bodyH + dims.footH + 7)
        head.Position = UDim2.new(0, dims.pad, 0, 0)
        head.Size = UDim2.new(1, -dims.pad * 2, 0, dims.headH)
        head.TextSize = dims.font
        div.Position = UDim2.new(0, dims.pad, 0, dims.headH)
        div.Size = UDim2.new(1, -dims.pad * 2, 0, 1)
        view.Position = UDim2.new(0, dims.pad, 0, dims.headH + 6)
        view.Size = UDim2.new(1, -dims.pad * 2, 0, dims.bodyH)
        foot.Position = UDim2.new(0, dims.pad, 1, -dims.footH)
        foot.Size = UDim2.new(1, -dims.pad * 2, 0, dims.footH)
        foot.TextSize = math.max(8, dims.font - 2)
        nameL.TextSize = dims.font
        distL.TextSize = math.max(8, dims.font - 2)
        return ep
    end
    function ep:GetScale() return ep._scale end
    function ep:GetInstance() return root end

    ep:SetScale(scale)
    buildMirror()
    return ep
end
