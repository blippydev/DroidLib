local function ensureDir(path)
    pcall(function()
        if makefolder and not isfolder(path) then makefolder(path) end
    end)
end

-- Defaults survive re-execution (Header unloads but this table persists on Library).
Library.ConfigIgnore = Library.ConfigIgnore or {
    __cfg_name = true,
    __cfg_list = true,
    __cfg_clipboard = true,
    __autosave_enabled = true,
    __autosave_delay = true,
}
Library.AutoSave = Library.AutoSave or {
    Enabled = false,
    Name = nil,
    Delay = 5,
    _lastJson = nil,
    _dirtySince = nil,
    _running = false,
}

function Library:IsFlagIgnored(flag)
    return self.ConfigIgnore[tostring(flag)] == true
end

function Library:IgnoreFlag(flag)
    self.ConfigIgnore[tostring(flag)] = true
end

function Library:UnignoreFlag(flag)
    self.ConfigIgnore[tostring(flag)] = nil
end

function Library:SetConfigIgnored(flags)
    self.ConfigIgnore = {}
    if type(flags) == "table" then
        if #flags > 0 then
            for _, f in ipairs(flags) do
                self.ConfigIgnore[tostring(f)] = true
            end
        else
            for k, v in pairs(flags) do
                if v then
                    self.ConfigIgnore[tostring(k)] = true
                end
            end
        end
    end
end

local function buildExtraIgnore(extra)
    if extra == nil then return nil end
    if type(extra) == "string" then return { [extra] = true } end
    if type(extra) == "table" then
        local map = {}
        if #extra > 0 then
            for _, f in ipairs(extra) do map[tostring(f)] = true end
        else
            for k, v in pairs(extra) do
                if v then map[tostring(k)] = true end
            end
        end
        return map
    end
    return nil
end

function Library:GetConfig(extraIgnore)
    local extra = buildExtraIgnore(extraIgnore)
    local out = { flags = {}, theme = {} }
    for k, v in pairs(self.Flags) do
        if self.ConfigIgnore[k] or (extra and extra[k]) then
            continue
        end
        local t = typeof(v)
        if t == "Color3" then
            out.flags[k] = { __c3 = true, r = v.R, g = v.G, b = v.B }
        elseif t == "EnumItem" then
            out.flags[k] = { __enum = true, t = tostring(v.EnumType), n = v.Name }
        elseif type(v) == "table" and (v.Key ~= nil or v.Mode ~= nil) and v.Toggled ~= nil then
            out.flags[k] = {
                __key = true,
                key = (typeof(v.Key) == "EnumItem") and v.Key.Name or nil,
                mode = tostring(v.Mode or "Toggle"),
                toggled = v.Toggled and true or false,
            }
        elseif type(v) ~= "function" and type(v) ~= "userdata" then
            local ok, _ = pcall(function() return HttpService:JSONEncode(v) end)
            if ok then out.flags[k] = v end
        end
    end
    for k, v in pairs(self.Theme) do
        if typeof(v) == "Color3" then
            out.theme[k] = { r = v.R, g = v.G, b = v.B }
        end
    end
    if self.BackgroundImage then
        out.background = { image = self.BackgroundImage, transparency = self.BackgroundTransparency }
    end
    local ok, json = pcall(HttpService.JSONEncode, HttpService, out)
    return ok and json or "{}"
end

function Library:LoadConfig(json, opts)
    local extra = nil
    if type(opts) == "table" and opts.Ignore ~= nil then
        extra = buildExtraIgnore(opts.Ignore)
    end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, json)
    if not ok or type(data) ~= "table" then return false end
    if type(data.theme) == "table" then
        for k, v in pairs(data.theme) do
            if type(v) == "table" and v.r then
                self:ChangeTheme(k, Color3.new(v.r, v.g, v.b))
            end
        end
    end
    if type(data.background) == "table" and data.background.image then
        self:SetBackgroundImage(data.background.image, data.background.transparency)
    end
    if type(data.flags) == "table" then        for k, v in pairs(data.flags) do
            if self.ConfigIgnore[k] or (extra and extra[k]) then
                continue
            end
            if type(v) == "table" and v.__c3 then
                self.Flags[k] = Color3.new(v.r, v.g, v.b)
            elseif type(v) == "table" and v.__enum then
                local okEnum, ev = pcall(function()
                    return Enum[tostring(v.t)][tostring(v.n)]
                end)
                if okEnum and typeof(ev) == "EnumItem" then
                    self.Flags[k] = ev
                else
                    continue
                end
            elseif type(v) == "table" and v.__key then
                local key = nil
                pcall(function()
                    if v.key then key = Enum.KeyCode[v.key] end
                end)
                self.Flags[k] = { Key = key, Mode = tostring(v.mode or "Toggle"), Toggled = v.toggled and true or false }
            else
                self.Flags[k] = v
            end
        end
    end
    self:ApplyFlags(true)
    local sc = tonumber(self.Flags.__uiscale)
    if sc then
        self:SetUIScale(sc)
    end
    if self.Flags.__anim ~= nil then
        self.AnimationsEnabled = self.Flags.__anim and true or false
    end
    if self.Flags.__tooltips ~= nil then
        self.TooltipsEnabled = self.Flags.__tooltips and true or false
    end
    local nd = tonumber(self.Flags.__notifdur)
    if nd then
        self.NotifDuration = math.clamp(nd, 1, 30)
    end
    for _, w in ipairs(self._windows) do
        if w.Watermark and self.Flags.__showwatermark ~= nil then
            w.Watermark:SetVisibility(self.Flags.__showwatermark)
        end
        if w.Watermark and self.Flags.__watermarkstats ~= nil then
            w.Watermark:SetStatsEnabled(self.Flags.__watermarkstats)
        end
        if w.KeybindList and self.Flags.__showkeybinds ~= nil then
            w.KeybindList:SetVisibility(self.Flags.__showkeybinds)
        end
        if w.ToggleButton and self.Flags.__showtogglebtn ~= nil then
            w.ToggleButton:SetVisibility(self.Flags.__showtogglebtn)
        end
    end
    if self.BackgroundImage then
        self:SetBackgroundImage(self.BackgroundImage, self.BackgroundTransparency)
    end
    return true
end

function Library:HasConfig(name)
    name = tostring(name or "")
    if name == "" then return false end
    local path = self.Folders.Configs .. "/" .. name .. ".json"
    local ok, res = pcall(isfile, path)
    if ok then return res == true end
    for _, n in ipairs(self:ListConfigs()) do
        if n == name then return true end
    end
    return false
end

function Library:SaveConfig(name)
    ensureDir(self.Folders.Directory)
    ensureDir(self.Folders.Configs)
    local path = self.Folders.Configs .. "/" .. tostring(name) .. ".json"
    local okJson, json = pcall(function() return self:GetConfig() end)
    if not okJson then return false end
    local ok = pcall(writefile, path, json)
    if ok and self.AutoSave.Enabled and self.AutoSave.Name == tostring(name) then
        self.AutoSave._lastJson = json
        self.AutoSave._dirtySince = nil
    end
    return ok
end

function Library:LoadConfigFile(name, opts)
    local path = self.Folders.Configs .. "/" .. tostring(name) .. ".json"
    local ok, src = pcall(readfile, path)
    if not ok then return false end
    return self:LoadConfig(src, opts)
end

function Library:ListConfigs()
    ensureDir(self.Folders.Configs)
    local ok, files = pcall(listfiles, self.Folders.Configs)
    if not ok or type(files) ~= "table" then return {} end
    local out = {}
    for _, f in ipairs(files) do
        local n = tostring(f):match("([^/\\]+)%.json$")
        if n then table.insert(out, n) end
    end
    table.sort(out)
    return out
end

function Library:SetAutoloadConfig(name)
    ensureDir(self.Folders.Directory)
    pcall(writefile, self.Folders.Directory .. "/autoload.txt", tostring(name or ""))
end

function Library:GetAutoloadConfigName()
    local ok, src = pcall(readfile, self.Folders.Directory .. "/autoload.txt")
    if not ok or type(src) ~= "string" or src == "" then return nil end
    return src
end

function Library:ClearAutoloadConfig()
    pcall(writefile, self.Folders.Directory .. "/autoload.txt", "")
    pcall(delfile, self.Folders.Directory .. "/autoload.txt")
end

function Library:LoadAutoload()
    local name = self:GetAutoloadConfigName()
    if not name then return false end
    return self:LoadConfigFile(name)
end

function Library:DeleteConfig(name)
    local wasAutosave = self.AutoSave.Enabled and self.AutoSave.Name == tostring(name)
    pcall(delfile, self.Folders.Configs .. "/" .. tostring(name) .. ".json")
    if wasAutosave then
        self:DisableAutoSave()
    end
end

-- Clipboard string share. Export returns the same JSON SaveConfig writes;
-- Import loads it. Copy/Paste wrap the executor clipboard when present.
function Library:ExportConfigString(extraIgnore)
    return self:GetConfig(extraIgnore)
end

function Library:ImportConfigString(str, opts)
    if type(str) ~= "string" or str == "" then return false end
    return self:LoadConfig(str, opts)
end

function Library:CopyConfigToClipboard(extraIgnore)
    local json = self:GetConfig(extraIgnore)
    local ok = pcall(setclipboard, json)
    return ok
end

function Library:PasteConfigFromClipboard(opts)
    local ok, clip = pcall(getclipboard)
    if not ok or type(clip) ~= "string" or clip == "" then return false end
    return self:LoadConfig(clip, opts)
end

-- Debounced auto-save. Writes Name every Delay seconds after the last
-- flag change instead of on every callback (callbacks fire per drag tick).
function Library:SetAutoSave(name, delay)
    name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then
        self:DisableAutoSave()
        return false
    end
    delay = math.clamp(tonumber(delay) or self.AutoSave.Delay or 5, 1, 60)
    self.AutoSave.Enabled = true
    self.AutoSave.Name = name
    self.AutoSave.Delay = delay
    pcall(function()
        self.AutoSave._lastJson = self:GetConfig()
    end)
    self.AutoSave._dirtySince = nil
    if not self.AutoSave._running then
        self.AutoSave._running = true
        self:Thread(function()
            while not self.Unloading do
                task.wait(1)
                if self.Unloading then break end
                if not self.AutoSave.Enabled or not self.AutoSave.Name or self.AutoSave.Name == "" then
                    continue
                end
                local okCur, cur = pcall(function() return self:GetConfig() end)
                if not okCur or type(cur) ~= "string" then
                    continue
                end
                if cur == self.AutoSave._lastJson then
                    self.AutoSave._dirtySince = nil
                else
                    local now = tick()
                    if self.AutoSave._dirtySince == nil then
                        self.AutoSave._dirtySince = now
                    elseif now - self.AutoSave._dirtySince >= (tonumber(self.AutoSave.Delay) or 5) then
                        if self:SaveConfig(self.AutoSave.Name) then
                            -- SaveConfig refreshes _lastJson on success.
                        else
                            -- Retry next tick, keep dirty marker.
                        end
                        self.AutoSave._dirtySince = nil
                    end
                end
            end
            self.AutoSave._running = false
        end)
    end
    return true
end

function Library:DisableAutoSave()
    self.AutoSave.Enabled = false
    self.AutoSave._dirtySince = nil
end

function Library:IsAutoSaveEnabled()
    return self.AutoSave.Enabled == true and self.AutoSave.Name ~= nil and self.AutoSave.Name ~= ""
end

function Library:GetAutoSaveName()
    if self:IsAutoSaveEnabled() then return self.AutoSave.Name end
    return nil
end
