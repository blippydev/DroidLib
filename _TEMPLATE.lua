--[[
    ═══════════════════════════════════════════════════════════════════════
    DROIDWARE game script TEMPLATE (DWLibV1)
    ═══════════════════════════════════════════════════════════════════════

    WHAT THIS IS
    ------------
    A starting point for a game script with a full UI. Copy it, rename it,
    fill in the GAME parts, and you have a hub. It runs as-is (demo values
    that only print), so you can boot it first and add real features after.

    HOW TO USE IT
    -------------
    1. Copy this file to Scripts/Developed/<GameName>.lua
       (files starting with "_" are never served — this one stays a template).
    2. Register it in Scripts/loader.lua ROUTES:
           [12345678] = "Developed/<GameName>.lua",   -- game.GameId, NOT PlaceId.
       One GameId covers a game's lobby + in-game places.
    3. Do RECON first (spy remotes, find state, note dead ends in §0 below),
       THEN write features. Recon-first is what stops you redoing work later.
    4. Run it through the dev server (docs/devmode.md):
           python server.py 9001
           _G.DWDevMode = true
           loadstring(game:HttpGet("http://127.0.0.1:9001/Scripts/loader.lua?t="..tick()))()

    Full widget reference: docs/elements.md (read it alongside this file).

    ── §0. GAME MAP (fill this in BEFORE writing features) ────────────────
    Game name / GameId:
    PlaceIds (lobby + in-game):

    Remotes (where they live, exact names):
      -

    Remote arguments (confirmed with a spy, not guessed):
      -

    Player state (attributes / values / leaderstats / folders):
      -

    Data/balance modules (only require() ones the GAME already loaded):
      -

    Dead ends (what you tried that does NOT work, and why):
      -
]]

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §1. ERROR GUARD                                                      ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Everything runs inside DwGuard. Without it a boot error kills the script
-- silently: no UI, no message, nothing to report. xpcall (not pcall) so the
-- traceback is captured while the error's stack still stands.
local function DwGuard(fn)
    local ok, err = xpcall(fn, function(e)
        return tostring(e) .. "\n" .. debug.traceback(nil, 2)
    end)
    if ok then return end
    local full = tostring(err or "unknown error")
    warn("[DROIDWARE] " .. full)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DROIDWARE - script error",
            Text = full:match("^[^\n]*") or full,
            Duration = 10,
        })
    end)
end

DwGuard(function()

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §2. EXECUTION LIFETIME (gen counter + alive)                         ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Re-executing (or unloading the UI) must kill the OLD execution's loops.
-- Every loop and connection in this file checks alive(), which dies when a
-- newer execution takes over (gen counter) or the UI unloads. Without this,
-- toggling a farm on and closing the UI leaves the worker running forever
-- with no way to stop it. MyLib pins the check to OUR lib instance: checking
-- _dwEnv.DWLib directly is wrong, because boot unloads the PREVIOUS lib
-- before the new one exists, and alive() would suicide the new execution.
local _dwEnv = (getgenv and getgenv()) or _G
_dwEnv.DwTemplate_Gen = (_dwEnv.DwTemplate_Gen or 0) + 1
local MY_GEN = _dwEnv.DwTemplate_Gen
local MyLib
local function alive()
    if _dwEnv.DwTemplate_Gen ~= MY_GEN then return false end
    if MyLib and (MyLib.Unloading or MyLib.Unloaded) then return false end
    return true
end

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §3. SERVICES                                                         ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Grab services once at the top. Nothing game-specific here.
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local TeleportService   = game:GetService("TeleportService")

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §4. PLAYER (resolve per use, never cache)                            ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- The character respawns (new objects) and lobby games spawn it late, so a
-- cached HumanoidRootPart goes stale or is nil forever. These helpers fetch
-- fresh instances on every call — slightly more verbose, never stale.
--
-- Connection registry lives HERE (not §6) because the first connections
-- happen below: track() every connection so §15's OnUnload disconnects
-- them all and re-execution leaves no orphan listeners behind.
local conns = {}
local function track(conn)
    conns[#conns + 1] = conn
    return conn
end

local LocalPlayer = Players.LocalPlayer
local function root()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function hum()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChildOfClass("Humanoid")
end
track(LocalPlayer.CharacterAdded:Connect(function()
    -- Placeholder: re-apply anything character-bound here (speed, ESP...).
    -- CharacterAdded fires on every respawn; the old character is gone.
end))

-- Anti-idle: Roblox disconnects idle clients after ~20 minutes.
track(LocalPlayer.Idled:Connect(function()
    if not alive() then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end))

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §5. NETWORK (one door for all remote traffic)                        ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Route every FireServer/InvokeServer through these. Today they are thin
-- wrappers; later, if the game spies on __namecall, you add ONE safe channel
-- here (set _dwEnv.DwSafe with Fire/Invoke) instead of editing 50 calls.
local function fire(remote, ...)
    if not remote then return end
    local safe = _dwEnv.DwSafe
    if safe and type(safe.Fire) == "function" then
        return safe.Fire(remote, ...)
    end
    return remote:FireServer(...)
end
local function invoke(remote, ...)
    if not remote then return end
    local safe = _dwEnv.DwSafe
    if safe and type(safe.Invoke) == "function" then
        return safe.Invoke(remote, ...)
    end
    return remote:InvokeServer(...)
end

-- Resolve YOUR remotes here (from §0). FindFirstChild + nil check, never a
-- bare WaitForChild: if an update moves a folder, you lose one feature
-- instead of hanging the whole boot with no UI at all.
local Net = {
    -- Action = ReplicatedStorage:FindFirstChild("Remotes")
    --     and ReplicatedStorage.Remotes:FindFirstChild("Action"),
}

-- Only require() a ModuleScript the GAME already loaded (then require just
-- returns the cached table). Requiring an unloaded one RUNS it outside the
-- game's flow, which can hang the client.
local function requireLoaded(module)
    if typeof(module) ~= "Instance" or not module:IsA("ModuleScript") then return nil end
    if type(getloadedmodules) ~= "function" then return nil end
    for _, m in ipairs(getloadedmodules()) do
        if m == module then
            local ok, result = pcall(require, module)
            return ok and result or nil
        end
    end
    return nil
end

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §6. HELPERS (notify; track() lives in §4)                             ║
-- ╚══════════════════════════════════════════════════════════════════════╝
local Library -- filled in at §8; notify() works before and after that.

-- notify() before the UI exists falls back to a native Roblox toast, so boot
-- messages never depend on the library being up yet.
local function notify(title, desc)
    if Library and type(Library.Notification) == "function" then
        Library:Notification(title, desc, 6)
        return
    end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "DROIDWARE — " .. tostring(title), Text = tostring(desc), Duration = 6,
        })
    end)
end

-- track() every connection you make (§4). OnUnload (§15) disconnects them
-- all, so re-execution leaves no orphan listeners behind.

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §7. STATE (one table, read by workers)                               ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- TWO reasons for one shared table instead of scattered locals:
--  1. Luau caps a function at 200 locals — a big script blows that fast;
--     one table holds unlimited config.
--  2. Workers read state live, so moving a slider mid-run takes effect
--     immediately, no off/on toggle dance required.
local state = {
    autofarm = false,
    cfg = { delay = 0.5, mode = "Legit" },
}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §8. UI BOOTSTRAP                                                     ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- This script boots its OWN library + window. Run it through loader.lua,
-- which sets Dw_DevMode + DwLibUrl on the shared env — so this file needs
-- no per-game URL edits, in dev or live.
--
-- Split loadstring from the call ON PURPOSE: if the fetch 404s, loadstring
-- gets a non-Lua body and returns nil, and the assert below names the exact
-- URL. Fused as loadstring(...)(), you'd only get "attempt to call a nil
-- value" with no idea which fetch failed.
local DEV_MODE = _dwEnv.Dw_DevMode
if DEV_MODE == nil then DEV_MODE = true end
local isMobile = _dwEnv.Dw_IsMobile
if isMobile == nil then
    isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

if _dwEnv.DWLib then pcall(function() _dwEnv.DWLib:Unload() end) end
local libUrl = _dwEnv.DwLibUrl
    or (DEV_MODE and ("http://127.0.0.1:9001/DWLIBV1/DWLibV1.lua?t=" .. tick()))
    or error("[DROIDWARE] no lib URL: set DwLibUrl or enable Dw_DevMode")
local libSource = game:HttpGet(libUrl)
local libChunk = type(libSource) == "string" and loadstring(libSource) or nil
assert(libChunk, "[DROIDWARE] DWLib did not compile, fetched from " .. tostring(libUrl))
Library = libChunk()
assert(type(Library) == "table", "[DROIDWARE] DWLib failed to load.")
_dwEnv.DWLib = Library
MyLib = Library -- arm alive() now that OUR lib exists (see §2).
if type(Library.SetMenuKeybind) == "function" then
    Library:SetMenuKeybind(Enum.KeyCode.RightShift)
end

local Window = Library:CreateWindow({
    Name = "DROIDWARE",
    SubName = "<Game Name>", -- header subtitle + Home game line fallback.
    DevMode = DEV_MODE, -- header pill: DEVMODE vs PRODUCTION.
    HomeOptions = {
        subtitle = "#1 Script HUB",
        -- gameName = "<Game Name>", -- omit: Home resolves it via Marketplace.
        credits = { "Lead Dev: <you>", "UI Library: DWLib V1" },
        discordLink = "",
    },
    -- Floating helpers. The D button is the ONLY way back in on touch
    -- devices (no keyboard for the menu key), hence ToggleButtonEnabled.
    ToggleButtonEnabled = isMobile,
    KeybindListEnabled = true,
    -- ESP preview: floating character mirror (like the keybind list, a
    -- separate window) that redraws itself from these flags live. Hook each
    -- key to the toggle/colorpicker flags you build in §11.
    ESPPreviewEnabled = true,
    ESPPreviewFlags = {
        Enabled = "esp",
        Box = "esp_box",
        Skeleton = "esp_skeleton",
        Tracer = "esp_tracer",
        Name = "esp_name",
        Health = "esp_health",
        Distance = "esp_distance",
        Chams = "esp_chams",
        Color = "esp_color",
    },
    SettingsTabEnabled = true, -- auto Settings tab, kept last, free theming.
})
_dwEnv.DwWindow = Window

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §9. TABS (containers only — sections live on SUB-tabs)              ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- RULE: a Tab holds nothing but sub-tabs. Tab:AddSection ERRORS. Every
-- content tab needs at least one Tab:AddSubTab. (Home + Settings are the
-- only exempt system pages.) Declaration order IS the tab order, and Home
-- stays first / Settings stays last no matter when you add yours.
-- Icon = any kebab-case lucide name ("swords", "eye", "move"...).
local FarmTab = Window:AddTab({ Name = "Farm", Icon = "swords" })
local UtilTab = Window:AddTab({ Name = "Utility", Icon = "wrench" })
local VisualsTab = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local DemoTab = Window:AddTab({ Name = "Demo", Icon = "sparkles" })

-- One local per sub-tab blows the 200-local cap once features land, so keep
-- them in a single table.
local Sub = {
    FarmMain = FarmTab:AddSubTab({ Name = "Auto Farm" }),
    UtilMove = UtilTab:AddSubTab({ Name = "Movement" }),
    VisMain = VisualsTab:AddSubTab({ Name = "ESP" }),
    DemoControls = DemoTab:AddSubTab({ Name = "Controls" }),
    DemoSystem = DemoTab:AddSubTab({ Name = "System" }),
}

-- Handles live here too (same 200-local reason). UI.T, UI.status, ...
local UI = {}

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §10. SECTIONS (two columns, collapsible cards)                      ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Side = 1 (default) puts the card left, Side = 2 right. The header arrow
-- collapses it (Sec:SetOpen(bool) / Sec:ToggleOpen(), Sec.IsOpen).
-- Sections are per-sub-tab: this is what fills the two columns you see.

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §11. WIDGETS (one of each — copy/paste starter set)                 ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Every widget takes an optional Flag (persisted in Library.Flags + configs;
-- omit it and the lib mints one) and a Callback (always task.spawned, never
-- blocks the UI thread). Tooltip = "..." works on all of them.
do
    local sec = Sub.FarmMain:AddSection({ Name = "Auto Farm" })

    -- TOGGLE: the on/off workhorse. Get() reads, Set() paints + fires.
    -- The handle drives everything below (keybind, colorpicker, code reads).
    UI.farmToggle = sec:AddToggle({
        Name = "Auto Farm", Flag = "autofarm", Default = false,
        Tooltip = "Master switch for the §12 worker",
        Callback = function(on)
            state.autofarm = on
            if UI.status then UI.status:SetText("Status: farm " .. (on and "ON" or "OFF")) end
            if not on then return end
            -- Workers live in task.spawn + check alive() every round (see
            -- §12). Never block the callback itself with a loop.
            task.spawn(function()
                while alive() and state.autofarm do
                    -- ... the farm action (uses state.cfg, Net, root()) ...
                    task.wait(state.cfg.delay)
                end
            end)
        end,
    })
    -- T:Get() -> bool; T:Set(true) flips it from code (fires Callback).
    -- T:SetVisibility(bool) hides the row (still in configs).

    -- KEYBIND docked on a toggle: a key press flips that toggle. Mode is
    -- "Toggle" (default), "Hold" (on while held), or "Always" (locked on).
    -- Right-click any toggle in-game to rebind / switch mode, no code.
    -- Handle: Get() GetMode() SetMode(m) Press(v) StartPicking() Refresh()
    -- GetParts() GetText() SetVisibility(b) ShowModeMenu(anchor).
    UI.farmKey = UI.farmToggle:Keybind({ Flag = "autofarm_key", Default = Enum.KeyCode.Q, Mode = "Toggle" })

    -- COLORPICKER docked on a toggle (e.g. ESP color). Alpha = transparency
    -- (0 solid, 1 invisible); Alpha = false drops the alpha bar entirely.
    -- Handle: Get() -> color, alpha; Set(color, alpha); SetOpen(b).
    UI.farmColor = UI.farmToggle:Colorpicker({ Flag = "farm_color", Default = Color3.fromRGB(220, 30, 42) })

    -- SLIDER: Decimals = snap step, Suffix = readout unit.
    -- Handle: Get() Set(v) SetVisibility(b) OnRelease(fn).
    UI.delay = sec:AddSlider({
        Name = "Delay", Flag = "farm_delay",
        Min = 0, Max = 5, Default = 0.5, Decimals = 0.05, Suffix = "s",
        Tooltip = "Worker wait between rounds",
        Callback = function(v) state.cfg.delay = v end, -- live, mid-run. §7.
    })
    UI.delay:OnRelease(function(v) print("[farm] delay released:", v) end)

    -- DROPDOWN, single-select. Get() returns the value.
    -- Handle: Get Set Refresh SetOpen SelectAll/DeselectAll(multi) SetVisibility.
    UI.mode = sec:AddDropdown({
        Name = "Mode", Flag = "farm_mode",
        Items = { "Legit", "Fast", "Blink" }, Default = "Legit",
        Tooltip = "Farm style",
        Callback = function(v) state.cfg.mode = v end,
    })

    -- DROPDOWN, multi-select. Get() returns a lookup map; the callback gets
    -- an array. SelectAll()/DeselectAll() exist; Refresh(list) swaps items.
    UI.checks = sec:AddDropdown({
        Name = "Checks", Flag = "farm_checks", Multi = true,
        Items = { "Visible", "Team", "Alive" }, Default = { "Visible" },
        Tooltip = "Multi-select demo",
        Callback = function(list) print("checks:", table.concat(list, ",")) end,
    })

    -- TEXTBOX. Finished = true fires on Enter; false fires on every change.
    -- Numeric = true rejects non-numbers (good for amounts/IDs).
    UI.target = sec:AddTextbox({
        Name = "Target", Flag = "farm_target",
        Placeholder = "player name...", Default = "",
        Tooltip = "Fires on Enter",
        Callback = function(t) print("target:", t) end,
    })
    -- T:Get() T:Set("x") T:SetVisibility(b).

    -- BUTTON. Press() clicks it from code (same punch + callback).
    -- Handle: Press SetText SetVisibility + Keybind(...) (a bound key IS a press).
    UI.go = sec:AddButton({
        Name = "Teleport to target",
        Tooltip = "Demo button",
        Callback = function() print("go to", Library.Flags.farm_target) end,
    })
    UI.go:Keybind({ Flag = "farm_go_key", Default = Enum.KeyCode.G })

    -- LABEL. SetText() rewrites it — point it at worker status.
    -- Handle: SetText Get SetVisibility + Keybind/Colorpicker docks.
    UI.status = sec:AddLabel("Status: idle")
    UI.status:SetText("Status: built — flip Auto Farm")
    UI.statusLblKey = UI.status:Keybind({ Flag = "status_key" })
    UI.statusLblColor = UI.status:Colorpicker({ Flag = "status_color", Default = Color3.fromRGB(220, 30, 42) })

    -- STANDALONE COLORPICKER (builds its own row). Get() returns color +
    -- alpha; Set(color, alpha) drives it from code; SetOpen(b) pops it.
    UI.accent = sec:AddColorpicker({
        Name = "Accent", Flag = "farm_accent",
        Default = Color3.fromRGB(220, 30, 42), Alpha = 0,
        Tooltip = "Standalone picker (has alpha bar)",
        Callback = function(c, a) print("accent:", tostring(c), a) end,
    })
end

do
    -- Second column example (Side = 2) on the OTHER sub-tab.
    -- Side = 1 left (default), Side = 2 right. Open = false starts collapsed.
    -- Sec:SetOpen(b) Sec:ToggleOpen() Sec.IsOpen.
    local sec = Sub.UtilMove:AddSection({ Name = "Movement", Side = 2 })

    sec:AddSlider({
        Name = "WalkSpeed", Flag = "walkspeed",
        Min = 16, Max = 300, Default = 16,
        Tooltip = "Applied live to the humanoid",
        Callback = function(v)
            local h = hum() -- resolved fresh (§4); nil-safe, no caching.
            if h then h.WalkSpeed = v end
        end,
    })
    -- Preview-then-commit slider: Preview ticks while dragging, Callback only
    -- on release. Same pattern Settings uses for UI Scale.
    sec:AddSlider({
        Name = "UI Scale (preview)", Flag = "__demo_uiscale",
        Min = 0.75, Max = 1.5, Default = 1, Decimals = 0.05, Suffix = "x",
        Live = false,
        Tooltip = "Drag draws outline, release applies",
        Preview = function(v) Library:PreviewUIScale(v) end,
        Callback = function(v) Library:SetUIScale(v) end,
    })
    sec:AddTextbox({
        Name = "Amount (numeric)", Flag = "demo_amount",
        Placeholder = "0", Default = "1", Numeric = true,
        Tooltip = "Numeric rejects non-numbers",
        Callback = function(t) print("amount:", t) end,
    })
    sec:AddTextbox({
        Name = "Live note", Flag = "demo_note",
        Placeholder = "fires every keystroke", Finished = false,
        Tooltip = "Finished=false fires on change",
        Callback = function(t) print("note:", t) end,
    })
    -- STANDALONE KEYBIND row (own label + chip). Same handle as docked ones.
    UI.demoKey = sec:AddKeybind({ Name = "Panic", Flag = "demo_panic", Default = Enum.KeyCode.P, Mode = "Hold" })
end

do
    -- VISUALS: these toggles feed BOTH a real ESP impl and the preview window.
    -- Flag keys MUST match the ESPPreviewFlags map in §8 — the preview reads
    -- Library.Flags directly (no callbacks needed), diffing every frame.
    local sec = Sub.VisMain:AddSection({ Name = "ESP" })

    -- Master toggle + color dock. Color = box/tracer/skeleton/name tint in
    -- both the real ESP drawing code AND the preview window.
    UI.esp = sec:AddToggle({
        Name = "Enable ESP", Flag = "esp", Default = false,
        Tooltip = "Preview window (top-right) mirrors this live",
    })
    UI.esp:Colorpicker({ Flag = "esp_color", Default = Color3.fromRGB(220, 30, 42) })

    -- Options: flip these and watch the preview update in real time.
    sec:AddToggle({ Name = "Box", Flag = "esp_box", Default = true })
    sec:AddToggle({ Name = "Skeleton", Flag = "esp_skeleton", Default = false })
    sec:AddToggle({ Name = "Tracer", Flag = "esp_tracer", Default = false })
    sec:AddToggle({ Name = "Name tag", Flag = "esp_name", Default = true })
    sec:AddToggle({ Name = "Health bar", Flag = "esp_health", Default = true })
    sec:AddToggle({ Name = "Distance", Flag = "esp_distance", Default = false })
    sec:AddToggle({ Name = "Chams", Flag = "esp_chams", Default = false })

    -- Wire REAL ESP rendering here: Players:GetPlayers() -> playernames/AI,
    -- project to screen, draw with the same feature gates as above. The
    -- preview window is your reference implementation for geometry.
end

do
    -- DEMO tab: every remaining call in one place. Copy from here, delete tab.
    local sec = Sub.DemoControls:AddSection({ Name = "Dropdown lab" })
    UI.single = sec:AddDropdown({
        Name = "Single", Flag = "demo_single",
        Items = { "A", "B", "C" }, Default = "A",
        Callback = function(v) print("single:", v) end,
    })
    UI.multi = sec:AddDropdown({
        Name = "Multi", Flag = "demo_multi", Multi = true,
        Items = { "One", "Two", "Three" }, Default = { "One" },
        Callback = function(list) print("multi:", table.concat(list, ",")) end,
    })
    sec:AddButton({ Name = "Select all", Callback = function() UI.multi:SelectAll() end })
    sec:AddButton({ Name = "Deselect all", Callback = function() UI.multi:DeselectAll() end })
    sec:AddButton({ Name = "Refresh items", Callback = function()
        UI.single:Refresh({ "X", "Y", "Z" })
        UI.multi:Refresh({ "Red", "Green", "Blue" })
    end })
    sec:AddButton({ Name = "Open single", Callback = function() UI.single:SetOpen(true) end })

    local sec2 = Sub.DemoControls:AddSection({ Name = "Handles", Side = 2 })
    sec2:AddButton({ Name = "Toggle farm from code", Callback = function()
        UI.farmToggle:Set(not UI.farmToggle:Get())
    end })
    sec2:AddButton({ Name = "Press Go button", Callback = function() UI.go:Press() end })
    sec2:AddButton({ Name = "Rename Go button", Callback = function() UI.go:SetText("Go! (" .. os.clock() .. ")") end })
    sec2:AddButton({ Name = "Set slider 2.5", Callback = function() UI.delay:Set(2.5) end })
    sec2:AddButton({ Name = "Set accent red", Callback = function()
        UI.accent:Set(Color3.fromRGB(255, 0, 0), 0)
    end })
    sec2:AddButton({ Name = "Cycle keybind mode", Callback = function()
        local m = UI.farmKey:GetMode()
        UI.farmKey:SetMode(m == "Toggle" and "Hold" or (m == "Hold" and "Always" or "Toggle"))
        print("key mode:", UI.farmKey:GetMode())
    end })

    local sys = Sub.DemoSystem:AddSection({ Name = "Notify + Dialog" })
    sys:AddButton({ Name = "Notify default", Callback = function()
        notify("Hello", "default length")
    end })
    sys:AddButton({ Name = "Notify 8s", Callback = function()
        local n = Library:Notification("Long", "8 second card", 8)
        task.delay(2, function() pcall(function() n:Close() end) end)
    end })
    sys:AddButton({ Name = "Dialog confirm", Callback = function()
        Library:Dialog({
            Title = "Reset?", Text = "Reset demo flags?",
            Buttons = {
                { Text = "Yes", Accent = true, Callback = function() print("reset yes") end },
                { Text = "No" },
            },
        })
    end })

    local win = Sub.DemoSystem:AddSection({ Name = "Window + Search", Side = 2 })
    win:AddButton({ Name = "Toggle window", Callback = function() Window:SetOpen(not Window.IsOpen) end })
    win:AddButton({ Name = "Maximize toggle", Callback = function() Window:ToggleMaximize() end })
    win:AddButton({ Name = "Maximize on", Callback = function() Window:SetMaximized(true) end })
    win:AddButton({ Name = "Recenter", Callback = function() Window:SetCenter() end })
    win:AddButton({ Name = "Select first tab", Callback = function() Window:SelectFirst() end })
    win:AddButton({ Name = "Search 'farm'", Callback = function() Window:Search("farm") end })
    win:AddButton({ Name = "Clear search", Callback = function() Window:Search("") end })
    win:AddTextbox({ Name = "Search live", Flag = "demo_search", Placeholder = "type to filter...",
        Finished = false, Callback = function(t) Window:Search(t) end })

    local cfg = Sub.DemoSystem:AddSection({ Name = "Configs live" })
    cfg:AddButton({ Name = "Print flags", Callback = function()
        print("autofarm:", Library.Flags.autofarm, "mode:", Library.Flags.farm_mode)
    end })
    cfg:AddButton({ Name = "ApplyFlags repaint", Callback = function() Library:ApplyFlags() end })
    cfg:AddButton({ Name = "Save demo", Callback = function()
        print("save:", Library:SaveConfig("demo"))
    end })
    cfg:AddButton({ Name = "Has demo?", Callback = function()
        print("has demo:", Library:HasConfig("demo"))
    end })
    cfg:AddButton({ Name = "Load demo", Callback = function()
        print("load:", Library:LoadConfigFile("demo"))
    end })
    cfg:AddButton({ Name = "List configs", Callback = function()
        print("configs:", table.concat(Library:ListConfigs(), ", "))
    end })
    cfg:AddButton({ Name = "Export string", Callback = function()
        local s = Library:ExportConfigString()
        print("export chars:", #s)
        pcall(setclipboard, s)
    end })
    cfg:AddButton({ Name = "Import clipboard", Callback = function()
        print("import:", Library:PasteConfigFromClipboard())
    end })
    cfg:AddButton({ Name = "Autosave demo/5s", Callback = function()
        print("autosave:", Library:SetAutoSave("demo", 5))
    end })
    cfg:AddButton({ Name = "Autosave off", Callback = function()
        Library:DisableAutoSave()
        print("autosave enabled:", Library:IsAutoSaveEnabled())
    end })

    local theme = Sub.DemoSystem:AddSection({ Name = "Theme live", Side = 2 })
    theme:AddButton({ Name = "Preset Midnight", Callback = function()
        Library:ApplyThemePreset("Midnight")
    end })
    theme:AddButton({ Name = "Preset DroidRed", Callback = function()
        Library:ApplyThemePreset("DroidRed")
    end })
    theme:AddButton({ Name = "Random accent", Callback = function()
        Library:ChangeTheme("Accent", Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)))
    end })
    theme:AddButton({ Name = "Clear background", Callback = function()
        Library:SetBackgroundImage("none")
    end })
    theme:AddButton({ Name = "Restore background", Callback = function()
        Library:SetBackgroundImage("", 0.5)
    end })
    theme:AddButton({ Name = "UIScale 1.25", Callback = function() Library:SetUIScale(1.25) end })
    theme:AddButton({ Name = "UIScale 1.0", Callback = function() Library:SetUIScale(1) end })
    theme:AddButton({ Name = "Preview 1.4", Callback = function()
        Library:PreviewUIScale(1.4)
        task.delay(1, function() Library:ClearUIScalePreview() end)
    end })
end

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §12. FEATURE WORKERS (the alive() pattern)                           ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Shown inline in the §11 toggle above; the rules, repeated because they
-- are the #1 source of "my script never stops" bugs:
--   * task.spawn the loop, never run it in the Callback itself.
--   * Check alive() (and your state flag) at the TOP of every round.
--   * Read state.* fresh each round so sliders apply mid-run.
--   * task.wait() every round — a hot loop (no yield) hangs the client.
-- Connections are different (no loop to check): track() them (§6) and they
-- die in §15's OnUnload.

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §13. FLOATING UI (watermark / keybind list / ESP preview)             ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Created from the CreateWindow opts in §8; handles for code control:
--   Window.Watermark:SetText(t), :SetStatsEnabled(b), :SetVisibility(b),
--     :SetCenter(), :SetScale(s 0.5-3), :GetScale()
--   Window.KeybindList:Refresh(), :SetVisibility(b), :SetPosition(udim2),
--     :SetScale(s 0.5-3), :GetScale()
--   Window.ESPPreview:SetVisibility(b), :SetPosition(udim2), :SetFlags(t),
--     :SetScale(s 0.5-3), :GetScale()   -- mirrors your character live and
--                                       -- redraws ESP overlays from flags.
--   Window.ToggleButton:Press(), :SetVisibility(b), :SetPosition(udim2)
-- All are also toggled in Settings → Interface (persisted).
-- Icons: Library:GetIcon("swords") resolves lucide / rbxassetid / numeric.
if Window.Watermark then Window.Watermark:SetText("DROIDWARE | template") end

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §14. CONFIGS (save / load / autoload)                                ║
-- ╚══════════════════════════════════════════════════════════════════════╝
-- Flags + theme + background serialize via Library:GetConfig(). The Settings
-- tab ships a full manager (named configs, autoload, clipboard strings,
-- auto-save with delay, overwrite confirm). From code:
--   Library:SaveConfig("main") / Library:LoadConfigFile("main")
--   Library:HasConfig("main") -> bool (used for overwrite confirms)
--   Library:LoadAutoload()  -- call AFTER building the UI (below), so every
--   widget exists to repaint. Needs executor file functions; without them
--   the calls fail safe (Save false, List {}).
--   Library:ExportConfigString() -> json; ImportConfigString(json) -> bool
--   Library:CopyConfigToClipboard() / PasteConfigFromClipboard()
--   Library:SetAutoSave("main", 5) / DisableAutoSave() / IsAutoSaveEnabled()
--   Library:IgnoreFlag("transient") / UnignoreFlag(f) / IsFlagIgnored(f)
--   Library:SetConfigIgnored({"a", "b"}) -- transient flags never save/load.
-- THEMING from code: ApplyThemePreset("DroidRed"|"Midnight"|"Crimson"|"Ghost"),
-- ChangeTheme("Accent", color), SetBackgroundImage(asset, transparency),
-- SetUIScale(1.0) + PreviewUIScale(v) / ClearUIScalePreview().
-- Settings → Theming/Interface edits all of it live.
-- Menu key: Library:SetMenuKeybind(Enum.KeyCode.RightShift) (persisted).
-- Misc: Library:ApplyFlags() repaints all, Library:ShowPopup/ClosePopups,
-- Library:BringToFront(inst), Library:AttachTooltip(inst, text),
-- Library:Punch(inst), Library:Tween(inst, props, time), Library:Drag(frame).
Library:IgnoreFlag("transient_demo") -- example: never persisted.

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §15. UNLOAD (connections die here; loops die via alive)              ║
-- ╚══════════════════════════════════════════════════════════════════════╝
Library:OnUnload(function()
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    conns = {}
end)
-- Library:Unload() (Settings → Unload UI, or the X button) then runs these
-- callbacks, disconnects library listeners, and destroys the UI. Loops check
-- alive() (§2/§12) and exit on their own — no loop registry needed.

-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║ §16. READY                                                           ║
-- ╚══════════════════════════════════════════════════════════════════════╝
Window:HideLoading() -- dismiss the boot card (auto-hides after 4s anyway).
Library:LoadAutoload() -- AFTER the UI exists. Repaints + applies UI prefs.
notify("DROIDWARE", "Template loaded — make it yours.")
print("[Template] ready —", game.GameId)

end)
