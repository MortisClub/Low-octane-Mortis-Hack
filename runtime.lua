local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================
-- ЖДЁМ ЗАГРУЗКУ ИГРЫ
-- ============================================
task.wait(5)

-- ============================================
-- НАЙТИ СЕБЯ
-- ============================================
local MyModel = nil

local function findMyModel()
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return nil end
    local closest, closestDist = nil, math.huge
    for _, m in pairs(chars:GetChildren()) do
        local charC = m:FindFirstChild("Character_C")
        if charC then
            local human = charC:FindFirstChild("Human")
            if human then
                local head = human:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    local d = (head.Position - Camera.CFrame.Position).Magnitude
                    if d < closestDist then
                        closestDist = d
                        closest = m
                    end
                end
            end
        end
    end
    MyModel = closest
    return closest
end

-- ============================================
-- SETTINGS (ТОЛЬКО НУЖНОЕ)
-- ============================================
local Settings = {
    ESP_Enabled = false,
    ESP_Color = Color3.fromRGB(255, 50, 50),
    ESP_Transparency = 0.6,

    Aimbot_Enabled = false,
    Aimbot_Smoothing = 4,
    Aimbot_FOV = 120,
    Aimbot_DeadZone = 1,
    Aimbot_Prediction = 0.08,
    Aimbot_ResponseCurve = 1.2,
    Aimbot_MaxSpeed = 40,
    Aimbot_MinSpeed = 0.5,
    Aimbot_NearSlowdown = 15,
    Aimbot_StickyTarget = true,
    Aimbot_TargetPart = "Head",
    Aimbot_KeyMode = "RMB",
    Aimbot_AlwaysOn = false,

    Fullbright_Enabled = false,

    FOVCircle = nil,
    WatchedModels = {},
    CurrentTarget = nil,
    AimbotActive = false,
}

-- ============================================
-- ПОИСК ГОЛОВЫ / ЦЕЛИ
-- ============================================
local function findCorrectHead(model)
    local charC = model:FindFirstChild("Character_C")
    if charC then
        local human = charC:FindFirstChild("Human")
        if human then
            local head = human:FindFirstChild("Head")
            if head and head:IsA("BasePart") then return head end
        end
    end
    return nil
end

local function findBestTargetPart(model, pref)
    if not model then return nil end
    pref = pref or "Head"
    local correctHead = findCorrectHead(model)

    if pref == "Head" or pref == "Auto" then
        if correctHead then return correctHead end
    end

    if pref == "Torso" then
        local charC = model:FindFirstChild("Character_C")
        if charC then
            local human = charC:FindFirstChild("Human")
            if human then
                local ub = human:FindFirstChild("UpperBody")
                if ub then
                    for _, p in pairs(ub:GetChildren()) do
                        if p:IsA("BasePart") then return p end
                    end
                end
            end
        end
    end

    if correctHead then return correctHead end

    local highest, highY = nil, -math.huge
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("BasePart") and d.Size.Magnitude > 0.3 and d.Position.Y > highY then
            if d.Parent.Name ~= "RagdollCollision" and d.Parent.Name ~= "Accessories" then
                highY = d.Position.Y
                highest = d
            end
        end
    end
    return highest
end

local aliveCache = {}

local function isModelAlive(model)
    if not model or not model.Parent then return false end
    local cached = aliveCache[model]
    if cached and cached.Parent then return cached.Health > 0 end
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("Humanoid") then
            aliveCache[model] = d
            return d.Health > 0
        end
    end
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("BasePart") then return true end
    end
    return false
end

-- ============================================
-- TEAM COLORS
-- ============================================
local teamCache = {}
local teamCacheTick = {}

local function getTeamType(model)
    if not model then return "neutral" end
    local now = tick()
    if teamCacheTick[model] and (now - teamCacheTick[model]) < 2 then
        return teamCache[model] or "neutral"
    end
    local result = "neutral"
    for _, d in pairs(model:GetDescendants()) do
        local n = d.Name:lower()
        if n == "headcloth" then result = "headcloth" break
        elseif n == "band" then result = "band" end
    end
    teamCache[model] = result
    teamCacheTick[model] = now
    return result
end

-- ============================================
-- FULLBRIGHT
-- ============================================
local OriginalLighting = {
    Ambient = Lighting.Ambient,
    Brightness = Lighting.Brightness,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation,
}

local function applyFullbright()
    if Settings.Fullbright_Enabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ExposureCompensation = 0.5
    else
        Lighting.Ambient = OriginalLighting.Ambient
        Lighting.Brightness = OriginalLighting.Brightness
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient
        Lighting.ExposureCompensation = OriginalLighting.ExposureCompensation
    end
end

Lighting:GetPropertyChangedSignal("Ambient"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.Ambient = Color3.fromRGB(255, 255, 255) end
end)
Lighting:GetPropertyChangedSignal("OutdoorAmbient"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255) end
end)
Lighting:GetPropertyChangedSignal("Brightness"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.Brightness = 2 end
end)
Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(function()
    if Settings.Fullbright_Enabled then Lighting.ExposureCompensation = 0.5 end
end)

-- ============================================
-- ESP
-- ============================================
local function getOrCreateHighlight(model)
    local h = model:FindFirstChild("Chms")
    if h then return h end
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
    if model == MyModel then
        local h = model:FindFirstChild("Chms")
        if h then h.Enabled = false end
        return
    end
    if not Settings.ESP_Enabled then
        local h = model:FindFirstChild("Chms")
        if h then h.Enabled = false end
        return
    end
    local h = getOrCreateHighlight(model)
    teamCacheTick[model] = 0
    local team = getTeamType(model)
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

local function watchModel(model)
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
            task.defer(function() task.wait(0.1) refreshHighlight(model) end)
        end
    end)
    local c2 = model.DescendantRemoving:Connect(function(d)
        local n = d.Name:lower()
        if n == "headcloth" or n == "band" then
            teamCacheTick[model] = 0
            task.defer(function() task.wait(0.1) refreshHighlight(model) end)
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

local function updateESP()
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return 0 end
    local count = 0
    for _, m in pairs(chars:GetChildren()) do
        if m ~= MyModel then
            watchModel(m)
            count = count + 1
        end
    end
    return count
end

-- ============================================
-- AIM KEY
-- ============================================
local function isAimKeyPressed()
    if Settings.Aimbot_AlwaysOn then return true end
    local m = Settings.Aimbot_KeyMode
    if m == "RMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif m == "LMB" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    elseif m == "Shift" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
    elseif m == "Alt" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt)
    elseif m == "Ctrl" then return UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)
    elseif m == "Q" then return UserInputService:IsKeyDown(Enum.KeyCode.Q)
    elseif m == "X" then return UserInputService:IsKeyDown(Enum.KeyCode.X)
    elseif m == "C" then return UserInputService:IsKeyDown(Enum.KeyCode.C)
    elseif m == "CapsLock" then return UserInputService:IsKeyDown(Enum.KeyCode.CapsLock)
    elseif m == "Always On" then return true
    end
    return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

-- ============================================
-- AIMBOT
-- ============================================
local stickyTargetModel = nil

local function createFOVCircle()
    pcall(function()
        if Settings.FOVCircle then
            pcall(function() Settings.FOVCircle:Remove() end)
        end
        local c = Drawing.new("Circle")
        c.Thickness = 2
        c.NumSides = 64
        c.Radius = Settings.Aimbot_FOV
        c.Color = Color3.fromRGB(255, 255, 255)
        c.Transparency = 0.7
        c.Visible = false
        c.Filled = false
        Settings.FOVCircle = c
    end)
end

local function isInFOV(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    if not onScreen then return false, math.huge end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
    return dist <= Settings.Aimbot_FOV, dist
end

local function getBestTarget()
    local bestPart, bestDist, bestModel = nil, math.huge, nil
    local chars = Workspace:FindFirstChild("Characters")
    if not chars then return nil end

    if Settings.Aimbot_StickyTarget and stickyTargetModel
        and stickyTargetModel.Parent and stickyTargetModel ~= MyModel
        and isModelAlive(stickyTargetModel) then
        local part = findBestTargetPart(stickyTargetModel, Settings.Aimbot_TargetPart)
        if part then
            local inFov = isInFOV(part.Position)
            if inFov then return part end
        end
    end

    for _, model in pairs(chars:GetChildren()) do
        if model ~= MyModel and isModelAlive(model) then
            local part = findBestTargetPart(model, Settings.Aimbot_TargetPart)
            if part then
                local inFov, dist = isInFOV(part.Position)
                if inFov and dist < bestDist then
                    bestDist = dist
                    bestPart = part
                    bestModel = model
                end
            end
        end
    end
    if bestModel then stickyTargetModel = bestModel end
    return bestPart
end

local function aimAt(targetPart)
    if not targetPart or not targetPart.Parent then return end
    local vel = Vector3.zero
    pcall(function() vel = targetPart.AssemblyLinearVelocity or Vector3.zero end)
    local predicted = targetPart.Position + vel * Settings.Aimbot_Prediction
    if predicted ~= predicted then predicted = targetPart.Position end

    local sp, onScreen = Camera:WorldToViewportPoint(predicted)
    if not onScreen then return end

    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local offX = sp.X - center.X
    local offY = sp.Y - center.Y
    local dist = math.sqrt(offX * offX + offY * offY)
    if dist < Settings.Aimbot_DeadZone then return end

    local dirX = offX / dist
    local dirY = offY / dist
    local baseFactor = math.clamp(1 / Settings.Aimbot_Smoothing, 0.05, 1.0)
    local normalizedDist = math.clamp(dist / Settings.Aimbot_FOV, 0.001, 1)
    local curvedFactor = math.pow(normalizedDist, Settings.Aimbot_ResponseCurve)

    local nearFactor = 1
    if dist < Settings.Aimbot_NearSlowdown then
        nearFactor = math.clamp(dist / Settings.Aimbot_NearSlowdown, 0.08, 1)
    end

    local speed = Settings.Aimbot_MaxSpeed * baseFactor * curvedFactor * nearFactor
    speed = math.clamp(speed, Settings.Aimbot_MinSpeed, Settings.Aimbot_MaxSpeed)
    speed = math.min(speed, dist * 0.9)
    if speed < Settings.Aimbot_MinSpeed and dist > Settings.Aimbot_DeadZone then
        speed = Settings.Aimbot_MinSpeed
    end

    mousemoverel(dirX * speed, dirY * speed)
end

-- ============================================
-- GUI — RAYFIELD
-- ============================================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Mortis v10.2 — Xeno Fix",
    LoadingTitle = "Mortis HACK",
    LoadingSubtitle = "Loading...",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

-- ═══ ESP ═══
local ESPTab = Window:CreateTab("ESP", 4483362458)
ESPTab:CreateSection("ESP Settings")

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Callback = function(v)
        Settings.ESP_Enabled = v
        updateESP()
    end
})

ESPTab:CreateColorPicker({
    Name = "Neutral Color",
    Color = Settings.ESP_Color,
    Callback = function(v)
        Settings.ESP_Color = v
        updateESP()
    end
})

ESPTab:CreateSlider({
    Name = "Fill Transparency",
    Range = {0, 1},
    Increment = 0.1,
    CurrentValue = Settings.ESP_Transparency,
    Callback = function(v)
        Settings.ESP_Transparency = v
        updateESP()
    end
})

ESPTab:CreateButton({
    Name = "Rescan Players",
    Callback = function()
        Settings.WatchedModels = {}
        teamCache = {}
        teamCacheTick = {}
        aliveCache = {}
        findMyModel()
        local c = updateESP()
        Rayfield:Notify({
            Title = "ESP",
            Content = c .. " players found",
            Duration = 3
        })
    end
})

ESPTab:CreateLabel("🔴 Red = Headcloth | 🟢 Green = Band")

-- ═══ AIMBOT ═══
local AimTab = Window:CreateTab("Aimbot", 4483362458)
AimTab:CreateSection("Activation")

AimTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(v)
        Settings.Aimbot_Enabled = v
        pcall(function()
            if Settings.FOVCircle then
                Settings.FOVCircle.Visible = v
            end
        end)
    end
})

AimTab:CreateDropdown({
    Name = "Aim Key",
    Options = {"RMB", "LMB", "Shift", "Alt", "Ctrl", "Q", "X", "C", "CapsLock", "Always On"},
    CurrentOption = {"RMB"},
    Callback = function(o)
        Settings.Aimbot_KeyMode = o[1]
        Settings.Aimbot_AlwaysOn = (o[1] == "Always On")
    end
})

AimTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "Auto", "Torso"},
    CurrentOption = {"Head"},
    Callback = function(o)
        Settings.Aimbot_TargetPart = o[1]
    end
})

AimTab:CreateToggle({
    Name = "Sticky Target",
    CurrentValue = true,
    Callback = function(v)
        Settings.Aimbot_StickyTarget = v
    end
})

AimTab:CreateSection("Main Settings")

AimTab:CreateSlider({
    Name = "Smoothing (1=instant 15=smooth)",
    Range = {1, 15},
    Increment = 0.5,
    CurrentValue = 4,
    Callback = function(v)
        Settings.Aimbot_Smoothing = v
    end
})

AimTab:CreateSlider({
    Name = "FOV Radius",
    Range = {30, 500},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 120,
    Callback = function(v)
        Settings.Aimbot_FOV = v
        pcall(function()
            if Settings.FOVCircle then
                Settings.FOVCircle.Radius = v
            end
        end)
    end
})

AimTab:CreateSlider({
    Name = "Dead Zone",
    Range = {0.5, 15},
    Increment = 0.5,
    Suffix = "px",
    CurrentValue = 1,
    Callback = function(v)
        Settings.Aimbot_DeadZone = v
    end
})

AimTab:CreateSlider({
    Name = "Prediction",
    Range = {0, 50},
    Increment = 1,
    Suffix = "%",
    CurrentValue = 8,
    Callback = function(v)
        Settings.Aimbot_Prediction = v / 100
    end
})

AimTab:CreateSection("Fine Tuning")

AimTab:CreateSlider({
    Name = "Response Curve",
    Range = {0.3, 3},
    Increment = 0.1,
    CurrentValue = 1.2,
    Callback = function(v)
        Settings.Aimbot_ResponseCurve = v
    end
})

AimTab:CreateSlider({
    Name = "Max Speed",
    Range = {5, 100},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 40,
    Callback = function(v)
        Settings.Aimbot_MaxSpeed = v
    end
})

AimTab:CreateSlider({
    Name = "Min Speed",
    Range = {0.1, 3},
    Increment = 0.1,
    Suffix = "px",
    CurrentValue = 0.5,
    Callback = function(v)
        Settings.Aimbot_MinSpeed = v
    end
})

AimTab:CreateSlider({
    Name = "Near Slowdown",
    Range = {5, 80},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 15,
    Callback = function(v)
        Settings.Aimbot_NearSlowdown = v
    end
})

AimTab:CreateSection("Presets")

AimTab:CreateButton({
    Name = "🎯 Ideal",
    Callback = function()
        Settings.Aimbot_Smoothing = 4
        Settings.Aimbot_FOV = 120
        Settings.Aimbot_DeadZone = 1
        Settings.Aimbot_Prediction = 0.08
        Settings.Aimbot_ResponseCurve = 1.2
        Settings.Aimbot_MaxSpeed = 40
        Settings.Aimbot_MinSpeed = 0.5
        Settings.Aimbot_NearSlowdown = 15
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius = 120 end end)
        Rayfield:Notify({ Title = "Preset", Content = "Ideal settings applied", Duration = 2 })
    end
})

AimTab:CreateButton({
    Name = "⚡ Aggressive",
    Callback = function()
        Settings.Aimbot_Smoothing = 2
        Settings.Aimbot_FOV = 150
        Settings.Aimbot_DeadZone = 0.5
        Settings.Aimbot_Prediction = 0.05
        Settings.Aimbot_ResponseCurve = 0.7
        Settings.Aimbot_MaxSpeed = 70
        Settings.Aimbot_MinSpeed = 1
        Settings.Aimbot_NearSlowdown = 8
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius = 150 end end)
        Rayfield:Notify({ Title = "Preset", Content = "Aggressive settings applied", Duration = 2 })
    end
})

AimTab:CreateButton({
    Name = "🫥 Legit",
    Callback = function()
        Settings.Aimbot_Smoothing = 8
        Settings.Aimbot_FOV = 80
        Settings.Aimbot_DeadZone = 2
        Settings.Aimbot_Prediction = 0.1
        Settings.Aimbot_ResponseCurve = 1.8
        Settings.Aimbot_MaxSpeed = 25
        Settings.Aimbot_MinSpeed = 0.3
        Settings.Aimbot_NearSlowdown = 30
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius = 80 end end)
        Rayfield:Notify({ Title = "Preset", Content = "Legit settings applied", Duration = 2 })
    end
})

AimTab:CreateButton({
    Name = "🔒 Lock-On",
    Callback = function()
        Settings.Aimbot_Smoothing = 1
        Settings.Aimbot_FOV = 200
        Settings.Aimbot_DeadZone = 0.5
        Settings.Aimbot_Prediction = 0.12
        Settings.Aimbot_ResponseCurve = 0.5
        Settings.Aimbot_MaxSpeed = 100
        Settings.Aimbot_MinSpeed = 2
        Settings.Aimbot_NearSlowdown = 5
        pcall(function() if Settings.FOVCircle then Settings.FOVCircle.Radius = 200 end end)
        Rayfield:Notify({ Title = "Preset", Content = "Lock-On settings applied", Duration = 2 })
    end
})

-- ═══ VISUALS ═══
local VisTab = Window:CreateTab("Visuals", 4483362458)
VisTab:CreateSection("Lighting")

VisTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(v)
        Settings.Fullbright_Enabled = v
        applyFullbright()
    end
})

-- ============================================
-- НИКАКИХ HOOKS
-- ============================================

-- ============================================
-- MAIN LOOP (МИНИМАЛЬНЫЙ)
-- ============================================
local lastMyModelUpdate = 0

RunService.RenderStepped:Connect(function()
    local now = tick()

    if now - lastMyModelUpdate > 2 then
        lastMyModelUpdate = now
        findMyModel()
    end

    if Settings.Fullbright_Enabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end

    pcall(function()
        if Settings.FOVCircle then
            local s = Camera.ViewportSize
            Settings.FOVCircle.Position = Vector2.new(s.X / 2, s.Y / 2)
            Settings.FOVCircle.Visible = Settings.Aimbot_Enabled
        end
    end)

    Settings.AimbotActive = Settings.Aimbot_Enabled and isAimKeyPressed()

    if Settings.AimbotActive then
        local part = getBestTarget()
        if part then
            aimAt(part)
            Settings.CurrentTarget = part
        else
            Settings.CurrentTarget = nil
        end
    else
        Settings.CurrentTarget = nil
        stickyTargetModel = nil
    end
end)

-- ============================================
-- INIT
-- ============================================
task.defer(function()
    local chars = Workspace:WaitForChild("Characters", 30)
    if not chars then
        warn("[Mortis] No Characters folder!")
        return
    end

    chars.ChildAdded:Connect(function(m)
        task.defer(function()
            task.wait(0.5)
            findMyModel()
            watchModel(m)
        end)
    end)

    chars.ChildRemoved:Connect(function(m)
        Settings.WatchedModels[m] = nil
        teamCache[m] = nil
        teamCacheTick[m] = nil
        aliveCache[m] = nil
        if m == MyModel then findMyModel() end
        if m == stickyTargetModel then stickyTargetModel = nil end
    end)

    createFOVCircle()
    findMyModel()
    local count = updateESP()

    Rayfield:Notify({
        Title = "Mortis v10.2",
        Content = count .. " players | ESP + Aimbot + Fullbright\nNo hooks = weapon works!",
        Duration = 7
    })

    print("[Mortis v10.2] " .. count .. " players | MyModel: " .. (MyModel and MyModel.Name or "nil"))
end)

