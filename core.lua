-- core.lua — базовые сервисы, настройки и общие функции Mortis Hack

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Глобальный контейнер
local Mortis = getgenv().Mortis or {}
getgenv().Mortis = Mortis

Mortis.Players = Players
Mortis.Workspace = Workspace
Mortis.RunService = RunService
Mortis.UserInputService = UserInputService
Mortis.Lighting = Lighting
Mortis.LocalPlayer = LocalPlayer
Mortis.Camera = Camera
Mortis.Mouse = Mouse

-- ============================================
-- SETTINGS
-- ============================================

local Settings = {
    ESP_Enabled = true, ESP_Color = Color3.fromRGB(255, 50, 50), ESP_Transparency = 0.6,

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
    Aimbot_VisCheck = false,
    Aimbot_KeyMode = "RMB",
    Aimbot_AlwaysOn = false,

    MagicBullet_Enabled = false, MagicBullet_FOVCheck = true, MagicBullet_TargetPart = "Head",
    AntiRecoil_Enabled = false, AntiRecoil_Strength = 100,
    NoHandShake_Enabled = false, NoHandShake_Strength = 100,
    Fullbright_Enabled = false, AlwaysDay_Enabled = false, RemoveFog_Enabled = false, OriginalLightingSettings = nil,
    Fly_Enabled = false, Fly_Speed = 50, Noclip_Enabled = false,
    Speed_Enabled = false, Speed_Value = 50,
    JumpPower_Enabled = false, JumpPower_Value = 100,
    InfiniteJump_Enabled = false, Invisibility_Enabled = false, GodMode_Enabled = false,
    FreeCam_Enabled = false, FreeCam_Speed = 1,
    ClickTP_Enabled = false, Spin_Enabled = false, Spin_Speed = 10,
    BigHead_Enabled = false, HitboxSize = 10,
    FOVCircle = nil, OriginalTransparency = {}, Flying = false, FlyBV = nil, FlyBG = nil,
    WatchedModels = {}, OriginalHeadSizes = {},
    CurrentTarget = nil, AimbotActive = false,
}

Mortis.Settings = Settings

-- ============================================
-- ПОИСК СВОЕГО МОДЕЛЯ / HUMANOID / HRP
-- ============================================

local MyModel = nil
Mortis._MyModel = MyModel

function Mortis.getMyModel()
    return MyModel
end

function Mortis.setMyModel(m)
    MyModel = m
    Mortis._MyModel = m
end

function Mortis.findMyModel()
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
    Mortis._MyModel = closest
    return closest
end

function Mortis.getHumanoid()
    local char = LocalPlayer.Character
    if char then
        for _, d in pairs(char:GetDescendants()) do
            if d:IsA("Humanoid") then
                return d
            end
        end
    end
    if MyModel then
        for _, d in pairs(MyModel:GetDescendants()) do
            if d:IsA("Humanoid") then
                return d
            end
        end
    end
    return nil
end

function Mortis.getHRP()
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            return hrp
        end
    end
    if MyModel then
        local charC = MyModel:FindFirstChild("Character_C")
        if charC then
            local human = charC:FindFirstChild("Human")
            if human then
                local head = human:FindFirstChild("Head")
                if head and head:IsA("BasePart") then
                    return head
                end
            end
        end
    end
    return nil
end

-- ============================================
-- ПОИСК ГОЛОВЫ / ЛУЧШЕЙ ЦЕЛИ
-- ============================================

function Mortis.findCorrectHead(model)
    if not model then return nil end
    local charC = model:FindFirstChild("Character_C")
    if charC then
        local human = charC:FindFirstChild("Human")
        if human then
            local head = human:FindFirstChild("Head")
            if head and head:IsA("BasePart") then
                return head
            end
        end
    end
    return nil
end

function Mortis.findBestTargetPart(model, pref)
    if not model then return nil end
    pref = pref or "Head"

    local correctHead = Mortis.findCorrectHead(model)

    if pref == "Head" or pref == "Auto" then
        if correctHead then
            return correctHead
        end
    end

    if pref == "Torso" then
        local charC = model:FindFirstChild("Character_C")
        if charC then
            local human = charC:FindFirstChild("Human")
            if human then
                local ub = human:FindFirstChild("UpperBody")
                if ub then
                    for _, p in pairs(ub:GetChildren()) do
                        if p:IsA("BasePart") then
                            return p
                        end
                    end
                end
            end
        end
    end

    if correctHead then
        return correctHead
    end

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

-- ============================================
-- ЖИВОСТЬ МОДЕЛЕЙ / КОМАНДЫ
-- ============================================

local aliveCache = {}
local teamCache = {}
local teamCacheTick = {}

Mortis.aliveCache = aliveCache
Mortis.teamCache = teamCache
Mortis.teamCacheTick = teamCacheTick

function Mortis.isModelAlive(model)
    if not model or not model.Parent then
        return false
    end
    local cached = aliveCache[model]
    if cached and cached.Parent then
        return cached.Health > 0
    end
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("Humanoid") then
            aliveCache[model] = d
            return d.Health > 0
        end
    end
    for _, d in pairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            return true
        end
    end
    return false
end

function Mortis.getTeamType(model)
    if not model then
        return "neutral"
    end
    local now = tick()
    if teamCacheTick[model] and (now - teamCacheTick[model]) < 2 then
        return teamCache[model] or "neutral"
    end
    local result = "neutral"
    for _, d in pairs(model:GetDescendants()) do
        local n = d.Name:lower()
        if n == "headcloth" then
            result = "headcloth"
            break
        elseif n == "band" then
            result = "band"
        end
    end
    teamCache[model] = result
    teamCacheTick[model] = now
    return result
end

-- ============================================
-- ANTI-AFK
-- ============================================

pcall(function()
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        vu:CaptureController()
        vu:ClickButton2(Vector2.new())
    end)
end)

return Mortis

