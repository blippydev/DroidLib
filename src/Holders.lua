do
    local parent = getHolderParent()
    local gui = parent:FindFirstChild("DWLibV1")
    if gui then pcall(function() gui:Destroy() end) end
    gui = Instance.new("ScreenGui")
    gui.Name = "DWLibV1"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent
    Library.Holder = gui

    -- Sweep stale copies left by earlier executions. Some executors isolate
    -- getgenv per execution, so the Header unload above cannot see them, and
    -- each run would otherwise stack a fully live second window (double
    -- callbacks on every keypress). The name is unique enough to sweep by.
    pcall(function()
        for _, root in ipairs({ game:GetService("CoreGui"), LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") }) do
            if typeof(root) == "Instance" then
                for _, d in ipairs(root:GetDescendants()) do
                    if d ~= gui and d.Name == "DWLibV1" and d:IsA("ScreenGui") then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
        end
    end)

    local notifs = Instance.new("Frame")
    notifs.Name = "Notifs"
    notifs.BackgroundTransparency = 1
    notifs.AnchorPoint = Vector2.new(1, 1)
    notifs.Position = UDim2.new(1, -16, 1, -16)
    notifs.Size = UDim2.new(0, 340, 0, 480)
    notifs.Parent = gui
    local nl = Instance.new("UIListLayout")
    nl.VerticalAlignment = Enum.VerticalAlignment.Bottom
    nl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    nl.Padding = UDim.new(0, 8)
    nl.SortOrder = Enum.SortOrder.LayoutOrder
    nl.Parent = notifs
    Library.NotifHolder = notifs

    -- Top layer for dropdown / colorpicker popups. Popups live here instead
    -- of inside section rows so ClipsDescendants and sibling overlap can
    -- never cut them off or bury them.
    local overlay = Instance.new("Frame")
    overlay.Name = "DWOverlay"
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.Visible = false
    overlay.Parent = gui
    Library.Overlay = overlay

    local catcher = Instance.new("TextButton")
    catcher.Name = "Catcher"
    catcher.BackgroundTransparency = 1
    catcher.Size = UDim2.new(1, 0, 1, 0)
    catcher.AutoButtonColor = false
    catcher.Text = ""
    catcher.Parent = overlay
    Library:Connect(catcher.MouseButton1Click, function()
        Library:ClosePopups()
    end)
end

function Library:Unload()
    if self.Unloading then return end
    self.Unloading = true
    for _, fn in ipairs(self._unloadCbs) do
        pcall(fn)
    end
    self._unloadCbs = {}
    for _, c in ipairs(self._conns) do
        pcall(function() c:Disconnect() end)
    end
    self._conns = {}
    pcall(function() self.Holder:Destroy() end)
    if getgenv and getgenv().DWLib == self then
        getgenv().DWLib = nil
    end
end
