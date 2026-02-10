-- esp.lua — ESP / Wallhack (подсветка игроков)

local Mortis = getgenv().Mortis or require("core")
getgenv().Mortis = Mortis

local Workspace = Mortis.Workspace
local Settings = Mortis.Settings

local teamCache = Mortis.teamCache
local teamCacheTick = Mortis.teamCacheTick
local aliveCache = Mortis.aliveCache

local M = {}

local function getOrCreateHighlight(model)
    local h = model:FindFirstChild("Chms")
    if h then
        return h
    end
    h = Instance.new("Highlight")
    h.Name = "Chms"
    h.FillTransparency = Settings.ESP_Transparency
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled = true
    h.Parent = model
    return h
end

local function refreshHighlight(model)
    if not model or not model.Parent then return end

    if model == Mortis.getMyModel() then
        local h = model:FindFirstChild("Chms")
        if h then
            h.Enabled = false
        end
        return
    end

    if not Settings.ESP_Enabled then
        local h = model:FindFirstChild("Chms")
        if h then
            h.Enabled = false
        end
        return
    end

    local h = getOrCreateHighlight(model)
    teamCacheTick[model] = 0
    local team = Mortis.getTeamType(model)

    if team == "headcloth" then
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.fromRGB(255, 0, 0)
    elseif team == "band" then
        h.FillColor = Color3.fromRGB(0, 255, 0)
        h.OutlineColor = Color3.fromRGB(0, 255, 0)
    else
        h.FillColor = Settings.ESP_Color
        h.OutlineColor = Settings.ESP_Color
    end

    h.FillTransparency = Settings.ESP_Transparency
    h.Enabled = true
end

function M.watchModel(model)
    if not model then return end
    if Settings.WatchedModels[model] then
        refreshHighlight(model)
        return
    end

    Settings.WatchedModels[model] = true
    refreshHighlight(model)

    local c1 = model.DescendantAdded:Connect(function(d)
        local n = d.Name:lower()
        if n == "headcloth" or n == "band" then
            teamCacheTick[model] = 0
            task.defer(function()
                task.wait(0.1)
                refreshHighlight(model)
            end)
        end
    end)

    local c2 = model.DescendantRemoving:Connect(function(d)
        local n = d.Name:lower()
        if n == "headcloth" or n == "band" then
            teamCacheTick[model] = 0
            task.defer(function()
                task.wait(0.1)
                refreshHighlight(model)
            end)
        end
    end)

    local c3
    c3 = model.AncestryChanged:Connect(function(_, p)
        if not p then
            Settings.WatchedModels[model] = nil
            teamCache[model] = nil
            teamCacheTick[model] = nil
            aliveCache[model] = nil
            pcall(function() c1:Disconnect() end)
            pcall(function() c2:Disconnect() end)
            pcall(function() c3:Disconnect() end)
        end
    end)
end

function M.updateESP()
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return 0 end

    local count = 0
    for _, m in pairs(chars:GetChildren()) do
        if m ~= Mortis.getMyModel() then
            M.watchModel(m)
            count = count + 1
        end
    end
    return count
end

Mortis.ESP = M
Mortis.refreshHighlight = refreshHighlight
Mortis.watchModel = M.watchModel
Mortis.updateESP = M.updateESP

return M

