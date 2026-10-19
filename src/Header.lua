-- DWLibV1 - DroidWare UI library v1 (original code, red/black theme)
-- Boot: unload previous copy so re-execution never stacks two windows.
if getgenv and getgenv().DWLib then
    pcall(function() getgenv().DWLib:Unload() end)
end

local Library = {}

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local CoreGui = game:GetService("CoreGui")
local function getHolderParent()
    local ok, hui = pcall(gethui)
    if ok and typeof(hui) == "Instance" then
        return hui
    end
    local ok2, hg = pcall(get_hidden_gui)
    if ok2 and typeof(hg) == "Instance" then
        return hg
    end
    return CoreGui
end

local LocalPlayer = Players.LocalPlayer
