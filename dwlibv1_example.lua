local Library = loadstring(game:HttpGet("http://127.0.0.1:9001/DWLIBV1/DWLibV1.lua?t=" .. tick()))()
assert(type(Library) == "table", "DWLib did not return Library")

local Window = Library:CreateWindow({
    Name = "DROIDWARE",
    SubName = "DWLibV1 demo",
    WatermarkEnabled = true,
    WatermarkText = "DROIDWARE | demo",
    KeybindListEnabled = true,
    ESPPreviewEnabled = true,
    ESPPreviewFlags = {
        Enabled = "demo_esp",
        Box = "demo_esp_box",
        Skeleton = "demo_esp_skeleton",
        Tracer = "demo_esp_tracer",
        Name = "demo_esp_name",
        Health = "demo_esp_health",
        Distance = "demo_esp_distance",
        Chams = "demo_esp_chams",
        Color = "demo_esp_color",
    },
    ToggleButtonEnabled = true,
})

local Main = Window:AddTab({ Name = "Main", Icon = "house" })
local MainSub = Main:AddSubTab({ Name = "General" })
local Sec = MainSub:AddSection({ Name = "Demo" })

local Status = Sec:AddLabel("Status: idle")
Sec:AddToggle({ Name = "Enable feature", Flag = "demo_enabled", Default = false, Callback = function(v)
    Status:SetText("Status: enabled = " .. tostring(v))
end })
Sec:AddSlider({ Name = "Speed", Flag = "demo_speed", Min = 16, Max = 120, Default = 32, Suffix = " st", Callback = function(v)
    Status:SetText("Status: speed = " .. tostring(v))
end })
Sec:AddDropdown({ Name = "Mode", Flag = "demo_mode", Items = { "Legit", "Fast", "Blink" }, Default = "Legit", Callback = function(v)
    Status:SetText("Status: mode = " .. tostring(v))
end })
Sec:AddTextbox({ Name = "Note", Flag = "demo_note", Placeholder = "type here", Callback = function(v)
    Status:SetText("Status: note = " .. tostring(v))
end })
Sec:AddButton({ Name = "Notify", Callback = function()
    Library:Notification("DROIDWARE", "DWLibV1 works.", 3)
end })
Sec:AddButton({ Name = "Dialog", Callback = function()
    Library:Dialog({ Title = "Reset?", Text = "Reset demo settings?", Buttons = {
        { Text = "Yes", Accent = true, Callback = function() Status:SetText("Status: reset") end },
        { Text = "No" },
    } })
end })

local Visuals = Window:AddTab({ Name = "Visuals", Icon = "eye" })
local VisSub = Visuals:AddSubTab({ Name = "General" })
local VSec = VisSub:AddSection({ Name = "Colors" })
VSec:AddColorpicker({ Name = "Accent", Callback = function(c)
    Library:ChangeTheme("Accent", c)
end })
local Tgl = VSec:AddToggle({ Name = "ESP", Flag = "demo_esp", Default = false })
Tgl:Keybind({ Flag = "demo_esp_key", Default = Enum.KeyCode.T, Mode = "Toggle" })
Tgl:Colorpicker({ Flag = "demo_esp_color", Default = Color3.fromRGB(220, 30, 42) })

local EspSec = VSec:AddSection({ Name = "ESP Options" })
EspSec:AddToggle({ Name = "Box", Flag = "demo_esp_box", Default = true })
EspSec:AddToggle({ Name = "Skeleton", Flag = "demo_esp_skeleton", Default = false })
EspSec:AddToggle({ Name = "Tracer", Flag = "demo_esp_tracer", Default = false })
EspSec:AddToggle({ Name = "Name", Flag = "demo_esp_name", Default = true })
EspSec:AddToggle({ Name = "Health", Flag = "demo_esp_health", Default = true })
EspSec:AddToggle({ Name = "Distance", Flag = "demo_esp_distance", Default = false })
EspSec:AddToggle({ Name = "Chams", Flag = "demo_esp_chams", Default = false })

Window:HideLoading()
Library:LoadAutoload()
Library:Notification("DROIDWARE", "DWLibV1 loaded.", 3)
