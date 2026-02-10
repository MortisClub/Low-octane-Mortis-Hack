-- runtime.lua — хуки, инпут, циклы RunService и общий init

local Mortis = getgenv().Mortis or require("core")
getgenv().Mortis = Mortis

local Settings = Mortis.Settings
local RunService = Mortis.RunService
local UserInputService = Mortis.UserInputService
local Lighting = Mortis.Lighting
local Workspace = Mortis.Workspace
local Camera = Mortis.Camera

local lighting = require("lighting")
local movement = require("movement")
local aim = require("aim")
local esp = require("esp")
local ui = require("ui")

local M = {}

-- ============================================
-- HOOKS (Magic Bullet)
-- ============================================

local function setupMagicBulletHook()
    pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local args = {...}
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "InvokeServer") and Settings.MagicBullet_Enabled then
                local ok, rn = pcall(function() return self.Name:lower() end)
                if ok and rn and (rn:find("shoot") or rn:find("fire") or rn:find("gun") or rn:find("damage") or rn:find("hit") or rn:find("bullet")) then
                    local t = aim.getMagicBulletTarget()
                    if t then
                        for i=1,#args do
                            if typeof(args[i]) == "Vector3" then
                                args[i] = t.Position
                            elseif typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(t.Position)
                            end
                        end
                    end
                end
            end
            return old(self, unpack(args))
        end)
    end)
end

-- ============================================
-- INPUT
-- ============================================

local function bindInput()
    UserInputService.JumpRequest:Connect(function()
        if Settings.InfiniteJump_Enabled then
            local h = Mortis.getHumanoid()
            if h then
                h:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.E and Settings.ClickTP_Enabled then
            movement.teleportToMouse()
        end
    end)
end

-- ============================================
-- MAIN LOOPS
-- ============================================

local function bindLoops()
    RunService.Stepped:Connect(function()
        if Settings.Noclip_Enabled then
            movement.applyNoclip()
        end
    end)

    local lastMyModelUpdate = 0
    local lastSpeedUpdate = 0
    local lastSH = 0

    RunService.RenderStepped:Connect(function()
        local now = tick()

        if now - lastMyModelUpdate > 2 then
            lastMyModelUpdate = now
            Mortis.findMyModel()
        end

        lighting.maintainLighting()

        if Settings.Fly_Enabled then movement.updateFly() end
        if Settings.FreeCam_Enabled then movement.updateFreeCam() end
        if Settings.Spin_Enabled then movement.applySpin() end

        if now - lastSpeedUpdate > 0.2 then
            lastSpeedUpdate = now
            if Settings.Speed_Enabled then movement.applySpeed() end
            if Settings.JumpPower_Enabled then movement.applyJumpPower() end
            if Settings.GodMode_Enabled then movement.applyGodMode() end
        end

        pcall(function()
            if Settings.FOVCircle then
                local s = Camera.ViewportSize
                Settings.FOVCircle.Position = Vector2.new(s.X/2, s.Y/2)
                Settings.FOVCircle.Visible = Settings.Aimbot_Enabled or Settings.MagicBullet_Enabled
            end
        end)

        Settings.AimbotActive = Settings.Aimbot_Enabled and aim.isAimKeyPressed()

        if Settings.AimbotActive then
            local part = aim.getBestTarget()
            if part then
                aim.aimAt(part)
                Settings.CurrentTarget = part
            else
                Settings.CurrentTarget = nil
            end
        else
            Settings.CurrentTarget = nil
        end

        if not Settings.AimbotActive then aim.applyAntiRecoil() end
        if not Settings.AimbotActive then aim.applyNoHandShake() end
    end)

    RunService.Heartbeat:Connect(function()
        if Settings.BigHead_Enabled then movement.applyBigHead() end
        if Settings.NoHandShake_Enabled and tick()-lastSH >= 5 then
            lastSH = tick()
            task.defer(aim.setupNoHandShakeHook)
        end
    end)
end

-- ============================================
-- INIT
-- ============================================

function Mortis.init()
    lighting.saveOriginalLighting()
    lighting.bindGuards()

    local window = ui.initUI()
    Mortis.Window = window

    setupMagicBulletHook()
    bindInput()
    bindLoops()

    task.defer(function()
        local chars = Workspace:WaitForChild("Characters", 30)
        if not chars then
            warn("[Mortis] No Characters!")
            return
        end

        chars.ChildAdded:Connect(function(m)
            task.defer(function()
                task.wait(0.2)
                Mortis.findMyModel()
                esp.watchModel(m)
            end)
        end)

        chars.ChildRemoved:Connect(function(m)
            Settings.WatchedModels[m] = nil
            Mortis.teamCache[m] = nil
            Mortis.teamCacheTick[m] = nil
            Mortis.aliveCache[m] = nil
            if m == Mortis.getMyModel() then
                Mortis.findMyModel()
            end
        end)

        aim.createFOVCircle()
        task.wait(1)
        Mortis.findMyModel()
        local count = esp.updateESP()

        if Mortis.Fluent then
            Mortis.Fluent:Notify({
                Title = "Mortis HACK v10.1",
                Content = "✅ Загружено! " .. count .. " игроков\n🔴 Red = Headcloth | 🟢 Green = Band",
                Duration = 7
            })
        end

        print("[Mortis v10.1] " .. count .. " players | MyModel: " .. (Mortis.getMyModel() and Mortis.getMyModel().Name or "nil"))
    end)
end

return M

