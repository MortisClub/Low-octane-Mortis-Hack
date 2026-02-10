-- movement.lua — полёт, скорость, прыжки, спин, инвиз, бигхед, фрикам

-- Берём глобальный Mortis, созданный core.lua, без require("core")
local Mortis = getgenv().Mortis or {}
getgenv().Mortis = Mortis

local Settings = Mortis.Settings
local UserInputService = Mortis.UserInputService
local Camera = Mortis.Camera

local M = {}

-- ============================================
-- FLY
-- ============================================

local function cleanupFly()
    Settings.Flying = false
    if Settings.FlyBV then
        pcall(function() Settings.FlyBV:Destroy() end)
        Settings.FlyBV = nil
    end
    if Settings.FlyBG then
        pcall(function() Settings.FlyBG:Destroy() end)
        Settings.FlyBG = nil
    end
end

function M.startFly()
    local hrp = Mortis.getHRP()
    if not hrp then return end
    cleanupFly()
    Settings.Flying = true

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(9e9,9e9,9e9)
    bv.Velocity = Vector3.zero
    bv.Parent = hrp
    Settings.FlyBV = bv

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
    bg.P = 9e4
    bg.CFrame = hrp.CFrame
    bg.Parent = hrp
    Settings.FlyBG = bg
end

function M.stopFly()
    cleanupFly()
end

function M.updateFly()
    if not Settings.Fly_Enabled or not Settings.Flying then return end
    local hrp = Mortis.getHRP()
    if not hrp then return end
    if not Settings.FlyBV or not Settings.FlyBV.Parent then
        M.startFly()
        return
    end

    local dir = Vector3.zero
    local cf = Camera.CFrame

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        dir = dir - Vector3.new(0,1,0)
    end

    Settings.FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * Settings.Fly_Speed or Vector3.zero
    Settings.FlyBG.CFrame = CFrame.new(hrp.Position, hrp.Position + cf.LookVector)
end

-- ============================================
-- MOVEMENT / PLAYER
-- ============================================

function M.applyNoclip()
    if not Settings.Noclip_Enabled then return end

    local myModel = Mortis.getMyModel()
    if myModel then
        for _, p in pairs(myModel:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end

    local c = Mortis.LocalPlayer.Character
    if c then
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") then
                p.CanCollide = false
            end
        end
    end
end

function M.applySpeed()
    if not Settings.Speed_Enabled then return end
    local h = Mortis.getHumanoid()
    if h then
        h.WalkSpeed = Settings.Speed_Value
    end
end

function M.resetSpeed()
    local h = Mortis.getHumanoid()
    if h then
        h.WalkSpeed = 16
    end
end

function M.applyJumpPower()
    if not Settings.JumpPower_Enabled then return end
    local h = Mortis.getHumanoid()
    if h then
        h.JumpPower = Settings.JumpPower_Value
        h.JumpHeight = Settings.JumpPower_Value / 2
    end
end

function M.resetJumpPower()
    local h = Mortis.getHumanoid()
    if h then
        h.JumpPower = 50
        h.JumpHeight = 7.2
    end
end

function M.applySpin()
    if not Settings.Spin_Enabled then return end
    local h = Mortis.getHRP()
    if h then
        h.CFrame = h.CFrame * CFrame.Angles(0, math.rad(Settings.Spin_Speed), 0)
    end
end

function M.applyGodMode()
    if not Settings.GodMode_Enabled then return end
    local h = Mortis.getHumanoid()
    if h then
        h.Health = h.MaxHealth
    end
end

function M.teleportToMouse()
    local h = Mortis.getHRP()
    local mouse = Mortis.Mouse
    if h and mouse and mouse.Hit then
        h.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0))
    end
end

function M.teleportToPlayer(name)
    local h = Mortis.getHRP()
    if not h then return nil end

    for _, p in pairs(Mortis.Players:GetPlayers()) do
        if p ~= Mortis.LocalPlayer and p.Name:lower():find(name:lower()) then
            local tc = p.Character
            if tc then
                local tp
                for _, d in pairs(tc:GetDescendants()) do
                    if d:IsA("BasePart") and d.Name == "Head" then
                        tp = d
                        break
                    end
                end
                if tp then
                    h.CFrame = tp.CFrame * CFrame.new(0,0,3)
                    return p.Name
                end
            end
        end
    end
    return nil
end

function M.applyInvisibility()
    local target = Mortis.getMyModel() or Mortis.LocalPlayer.Character
    if not target then return end

    if Settings.Invisibility_Enabled then
        for _, p in pairs(target:GetDescendants()) do
            if (p:IsA("BasePart") or p:IsA("Decal") or p:IsA("Texture")) and not Settings.OriginalTransparency[p] then
                Settings.OriginalTransparency[p] = p.Transparency
                p.Transparency = 1
            end
        end
    else
        for p, t in pairs(Settings.OriginalTransparency) do
            pcall(function()
                if p and p.Parent then
                    p.Transparency = t
                end
            end)
        end
        Settings.OriginalTransparency = {}
    end
end

local lastBigHeadUpdate = 0

function M.applyBigHead()
    local now = tick()
    if now - lastBigHeadUpdate < 0.5 then return end
    lastBigHeadUpdate = now

    local chars = Mortis.Workspace:FindFirstChild("Characters")
    if not chars then return end

    for _, m in pairs(chars:GetChildren()) do
        if m ~= Mortis.getMyModel() then
            local head = Mortis.findCorrectHead(m)
            if head then
                if Settings.BigHead_Enabled then
                    if not Settings.OriginalHeadSizes[head] then
                        Settings.OriginalHeadSizes[head] = head.Size
                    end
                    head.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                    head.Transparency = 0.5
                    head.CanCollide = false
                else
                    local o = Settings.OriginalHeadSizes[head]
                    if o then
                        head.Size = o
                        Settings.OriginalHeadSizes[head] = nil
                    end
                    head.Transparency = 0
                end
            end
        end
    end
end

-- ============================================
-- FREE CAM
-- ============================================

function M.startFreeCam()
    Mortis.Camera.CameraType = Enum.CameraType.Scriptable
end

function M.stopFreeCam()
    local cam = Mortis.Camera
    cam.CameraType = Enum.CameraType.Custom
    local h = Mortis.getHumanoid()
    if h then
        cam.CameraSubject = h
    end
end

function M.updateFreeCam()
    if not Settings.FreeCam_Enabled then return end
    local dir = Vector3.zero
    local cam = Mortis.Camera

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end

    if dir.Magnitude > 0 then
        cam.CFrame = cam.CFrame + dir.Unit * Settings.FreeCam_Speed
    end
end

Mortis.Movement = M

return M

