-- ================================================================= --
-- WIA HUB v9.6 MM2 & Profile Edition :: whitewia / tordark
-- FIXED: ESP Box/Skeleton Toggle Fix, Startup Off, Profile, MM2 Hub
-- ================================================================= --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local CoreGui = game:GetService("CoreGui")

-- ========== VARIABLE DECLARATIONS ==========
local flightEnabled, noclipEnabled = false, false
local flySpeed = 50
local bodyVelocity, bodyGyro = nil, nil

local walkSpeedValue, jumpPowerValue, cframeSpeedValue = 16, 50, 2
local cframeSpeedEnabled = false
local infiniteJumpEnabled, bhopEnabled, spinbotEnabled = false, false, false
local spinbotSpeed = 20

local godmodeEnabled = false
local tpTool, tpToolActive = nil, false
local wallhackEnabled = false
local antiAFKEnabled = false
local playerListEnabled = false
local antiVoidEnabled = false
local fullBrightEnabled, noFogEnabled = false, false
local originalBrightness, originalAmbient, originalFog = nil, nil, nil

-- Custom Gravity Variables
local customGravityEnabled = false
local gravityValue = 196.2
local originalGravity = Workspace.Gravity

-- Freecam & Spectate
local freecamEnabled = false
local freecamSpeed = 50
local freecamPos = Vector3.new(0, 10, 0)

local spectateEnabled = false
local spectateTarget = nil

-- Aimbot Variables
local aimbotFOV = 90
local aimbotSmoothness = 5
local aimbotSelectedTarget = nil
local fovCircleVisible = false
local aimbotEnabled = false

-- Hitbox & Misc Utilities
local hitboxEnabled = false
local hitboxSize = 5
local originalHitboxSizes = {}
local autoClickerEnabled, autoClickerDelay = false, 100
local triggerbotEnabled = false

local chatSpamEnabled, chatSpamMessage, chatSpamDelay = false, "WIA HUB ON TOP", 5
local antiFallEnabled = false

-- ESP Extras (ALL DISABLED BY DEFAULT)
local espBoxEnabled = false
local espTracerEnabled = false
local espNamesEnabled = false
local espDistanceEnabled = false
local espHealthEnabled = false
local skeletonEspEnabled = false
local espLines, tracerLines, textDrawings, skeletonLines = {}, {}, {}, {}

-- MM2 Variables
local mm2EspEnabled = false
local mm2AutoAimMurderer = false
local mm2SilentAim = false
local killAuraEnabled = false
local killAuraRange = 15

-- Stats & Profile Variables
local fpsCount = 0
local frameCounter = 0
local lastFpsUpdate = tick()

-- Drawing API FOV Circle
local fovCircle = nil
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 60
    fovCircle.Radius = aimbotFOV
    fovCircle.Filled = false
    fovCircle.Visible = false
    fovCircle.Color = Color3.fromRGB(180, 0, 255)
end

-- ========== HELPER FUNCTIONS ==========
local function getMM2Role(plr)
    if not plr then return "Innocent" end
    local char = plr.Character
    local backpack = plr:FindFirstChild("Backpack")

    local hasKnife = (char and char:FindFirstChild("Knife")) or (backpack and backpack:FindFirstChild("Knife"))
    local hasGun = (char and (char:FindFirstChild("Gun") or char:FindFirstChild("Revolver"))) or (backpack and (backpack:FindFirstChild("Gun") or backpack:FindFirstChild("Revolver")))

    if hasKnife then return "Murderer" end
    if hasGun then return "Sheriff" end
    return "Innocent"
end

-- ========== RAYFIELD WINDOW SETUP ==========
local Window = Rayfield:CreateWindow({
    Name = "WIA HUB v9.6 MM2 Edition",
    LoadingTitle = "WIA HUB Loading...",
    LoadingSubtitle = "by whitewia / tordark",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local ProfileTab = Window:CreateTab("Profile & Info", 4483362458)
local MM2Tab = Window:CreateTab("Murder Mystery 2", 4483362458)
local CombatTab = Window:CreateTab("Combat & Aim", 4483362458)
local VisualsTab = Window:CreateTab("Visuals & ESP", 4483345998)
local MovementTab = Window:CreateTab("Movement & Cam", 4483345998)
local MiscTab = Window:CreateTab("Misc & Utilities", 4483362458)

-- ========== PROFILE TAB ==========
ProfileTab:CreateSection("Информация об Игроке")
ProfileTab:CreateLabel("Ник: " .. LocalPlayer.Name .. " (" .. LocalPlayer.DisplayName .. ")")
ProfileTab:CreateLabel("User ID: " .. LocalPlayer.UserId)

local FpsLabel = ProfileTab:CreateLabel("FPS: Вычисляется...")
local PingLabel = ProfileTab:CreateLabel("Ping: Вычисляется...")

RunService.RenderStepped:Connect(function()
    frameCounter = frameCounter + 1
    local now = tick()
    if now - lastFpsUpdate >= 1 then
        fpsCount = frameCounter
        frameCounter = 0
        lastFpsUpdate = now
        
        local ping = 0
        pcall(function()
            ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        
        FpsLabel:Set("FPS: " .. fpsCount)
        PingLabel:Set("Ping: " .. ping .. " ms")
    end
end)

-- ========== MM2 TAB ==========
MM2Tab:CreateSection("ESP & Детектор Ролей")
MM2Tab:CreateToggle({
    Name = "MM2 Role ESP (Мардер / Шериф / Инносент)",
    CurrentValue = false,
    Callback = function(v)
        mm2EspEnabled = v
        if not v then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character then
                    local hl = plr.Character:FindFirstChild("WIA_MM2_ESP")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
})

MM2Tab:CreateSection("Аимбот & Бой MM2")
MM2Tab:CreateToggle({
    Name = "Auto Aim на Мардера",
    CurrentValue = false,
    Callback = function(v) mm2AutoAimMurderer = v end
})

MM2Tab:CreateToggle({
    Name = "Silent Aim (Авто-наведение)",
    CurrentValue = false,
    Callback = function(v) mm2SilentAim = v end
})

MM2Tab:CreateToggle({
    Name = "Kill Aura (Авто-атака)",
    CurrentValue = false,
    Callback = function(v) killAuraEnabled = v end
})

MM2Tab:CreateSlider({
    Name = "Дистанция Kill Aura",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(v) killAuraRange = v end
})

MM2Tab:CreateSection("Телепортация")
MM2Tab:CreateButton({
    Name = "Телепорт к выбитому Пистолету",
    Callback = function()
        local gunDrop = Workspace:FindFirstChild("GunDrop", true) or Workspace:FindFirstChild("Gun", true)
        if gunDrop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local targetPos = gunDrop:IsA("BasePart") and gunDrop.CFrame or gunDrop:GetPivot()
            LocalPlayer.Character.HumanoidRootPart.CFrame = targetPos + Vector3.new(0, 3, 0)
            Rayfield:Notify({Title = "MM2", Content = "Успешно телепортирован к пистолету!", Duration = 3})
        else
            Rayfield:Notify({Title = "MM2", Content = "Выпавший пистолет не найден!", Duration = 3})
        end
    end
})

-- ========== PLAYER LIST & CONTROLS UI ==========
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList_v96"
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

local PlayerListMain = Instance.new("Frame")
PlayerListMain.Size = UDim2.new(0, 310, 0, 450)
PlayerListMain.Position = UDim2.new(0, 360, 0, 10)
PlayerListMain.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
PlayerListMain.BackgroundTransparency = 0.3
PlayerListMain.BorderSizePixel = 1
PlayerListMain.BorderColor3 = Color3.fromRGB(180, 0, 255)
PlayerListMain.ClipsDescendants = true
PlayerListMain.Parent = PlayerListGui

local PlayerListTitle = Instance.new("TextLabel")
PlayerListTitle.Size = UDim2.new(1, 0, 0, 30)
PlayerListTitle.Text = "PLAYER CONTROLS (TP / SPEC / AIM)"
PlayerListTitle.TextColor3 = Color3.fromRGB(180, 0, 255)
PlayerListTitle.TextScaled = true
PlayerListTitle.BackgroundTransparency = 1
PlayerListTitle.Font = Enum.Font.GothamBold
PlayerListTitle.Parent = PlayerListMain

local playerListScrollingFrame = Instance.new("ScrollingFrame")
playerListScrollingFrame.Size = UDim2.new(1, -10, 1, -85)
playerListScrollingFrame.Position = UDim2.new(0, 5, 0, 35)
playerListScrollingFrame.BackgroundTransparency = 1
playerListScrollingFrame.BorderSizePixel = 0
playerListScrollingFrame.ScrollBarThickness = 4
playerListScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 255)
playerListScrollingFrame.Parent = PlayerListMain

local PlayerListContainer = Instance.new("Frame")
PlayerListContainer.Size = UDim2.new(1, 0, 0, 0)
PlayerListContainer.BackgroundTransparency = 1
PlayerListContainer.Parent = playerListScrollingFrame

local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1, -20, 0, 45)
TargetStatus.Position = UDim2.new(0, 10, 1, -48)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = "L-Click: TP | R-Click: Aim Target | Middle/Btn: Spec\nTarget: Auto | Spec: None"
TargetStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetStatus.Font = Enum.Font.Gotham
TargetStatus.TextSize = 10
TargetStatus.TextWrapped = true
TargetStatus.Parent = PlayerListMain

local function makeDraggable(frame)
    local dragging, dragStart, startPos = false, nil, nil
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end
makeDraggable(PlayerListMain)

local function updatePlayerList()
    for _, btn in pairs(PlayerListContainer:GetChildren()) do
        btn:Destroy()
    end

    local players = Players:GetPlayers()
    local y = 0

    for _, plr in pairs(players) do
        if plr ~= LocalPlayer then
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 28)
            row.Position = UDim2.new(0, 0, 0, y)
            row.BackgroundTransparency = 1
            row.Parent = PlayerListContainer

            local nameBtn = Instance.new("TextButton")
            nameBtn.Size = UDim2.new(0.45, 0, 1, 0)
            nameBtn.Text = plr.Name
            nameBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
            nameBtn.BorderSizePixel = 0
            nameBtn.Font = Enum.Font.GothamMedium
            nameBtn.TextSize = 10
            nameBtn.Parent = row

            local tpBtn = Instance.new("TextButton")
            tpBtn.Size = UDim2.new(0.17, 0, 1, 0)
            tpBtn.Position = UDim2.new(0.46, 0, 0, 0)
            tpBtn.Text = "TP"
            tpBtn.TextColor3 = Color3.fromRGB(200, 255, 200)
            tpBtn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
            tpBtn.BorderSizePixel = 0
            tpBtn.Font = Enum.Font.GothamBold
            tpBtn.TextSize = 10
            tpBtn.Parent = row

            local aimBtn = Instance.new("TextButton")
            aimBtn.Size = UDim2.new(0.17, 0, 1, 0)
            aimBtn.Position = UDim2.new(0.64, 0, 0, 0)
            aimBtn.Text = (aimbotSelectedTarget == plr) and "AIM+" or "AIM"
            aimBtn.TextColor3 = Color3.fromRGB(220, 180, 255)
            aimBtn.BackgroundColor3 = (aimbotSelectedTarget == plr) and Color3.fromRGB(80, 20, 120) or Color3.fromRGB(60, 30, 80)
            aimBtn.BorderSizePixel = 0
            aimBtn.Font = Enum.Font.GothamBold
            aimBtn.TextSize = 10
            aimBtn.Parent = row

            local specBtn = Instance.new("TextButton")
            specBtn.Size = UDim2.new(0.17, 0, 1, 0)
            specBtn.Position = UDim2.new(0.82, 0, 0, 0)
            specBtn.Text = (spectateTarget == plr) and "SPEC+" or "SPEC"
            specBtn.TextColor3 = Color3.fromRGB(255, 220, 150)
            specBtn.BackgroundColor3 = (spectateTarget == plr) and Color3.fromRGB(120, 80, 20) or Color3.fromRGB(70, 50, 20)
            specBtn.BorderSizePixel = 0
            specBtn.Font = Enum.Font.GothamBold
            specBtn.TextSize = 10
            specBtn.Parent = row

            tpBtn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end)

            aimBtn.MouseButton1Click:Connect(function()
                if aimbotSelectedTarget == plr then
                    aimbotSelectedTarget = nil
                else
                    aimbotSelectedTarget = plr
                end
                TargetStatus.Text = "L-Click: TP | R-Click: Aim Target | Btn: Spec\nTarget: " .. (aimbotSelectedTarget and aimbotSelectedTarget.Name or "Auto") .. " | Spec: " .. (spectateTarget and spectateTarget.Name or "None")
                updatePlayerList()
            end)

            specBtn.MouseButton1Click:Connect(function()
                if spectateTarget == plr then
                    spectateTarget = nil
                else
                    spectateTarget = plr
                end
                TargetStatus.Text = "L-Click: TP | R-Click: Aim Target | Btn: Spec\nTarget: " .. (aimbotSelectedTarget and aimbotSelectedTarget.Name or "Auto") .. " | Spec: " .. (spectateTarget and spectateTarget.Name or "None")
                updatePlayerList()
            end)

            y = y + 31
        end
    end

    PlayerListContainer.Size = UDim2.new(1, 0, 0, y)
    playerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

-- ========== PERSISTENT TELEPORT TOOL ==========
local function createTPTool()
    local tool = Instance.new("Tool")
    tool.Name = "WIA_TP"
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    local tpActive = false
    tool.Equipped:Connect(function()
        tpActive = true
        Mouse.Icon = "rbxasset://SystemCursors/Crosshair"
    end)

    tool.Unequipped:Connect(function()
        tpActive = false
        Mouse.Icon = "rbxasset://SystemCursors/Arrow"
    end)

    tool.Activated:Connect(function()
        if tpActive then
            local targetPos = Mouse.Hit.Position
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                char.HumanoidRootPart.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                local part = Instance.new("Part")
                part.Size = Vector3.new(2, 0.5, 2)
                part.Position = targetPos
                part.Anchored = true
                part.CanCollide = false
                part.BrickColor = BrickColor.new("Bright violet")
                part.Material = Enum.Material.Neon
                part.Transparency = 0.5
                part.Parent = Workspace
                game:GetService("Debris"):AddItem(part, 0.5)
            end
        end
    end)

    return tool
end

local function giveTPTool()
    if not tpTool then
        tpTool = createTPTool()
    end
    tpTool.Parent = LocalPlayer.Backpack
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if tpToolActive then
        task.wait(1)
        giveTPTool()
        if char:FindFirstChild("Humanoid") then
            char.Humanoid:EquipTool(tpTool)
        end
    end
end)

-- ========== COMBAT TAB ==========
CombatTab:CreateToggle({ Name = "Aimbot", CurrentValue = false, Callback = function(v) aimbotEnabled = v end })
CombatTab:CreateToggle({ Name = "Aimbot FOV Circle", CurrentValue = false, Callback = function(v) fovCircleVisible = v end })
CombatTab:CreateSlider({ Name = "Aimbot FOV", Range = {10, 400}, Increment = 5, CurrentValue = 90, Callback = function(v) aimbotFOV = v end })
CombatTab:CreateSlider({ Name = "Aimbot Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) aimbotSmoothness = v end })
CombatTab:CreateToggle({ Name = "Triggerbot (AutoShot)", CurrentValue = false, Callback = function(v) triggerbotEnabled = v end })
CombatTab:CreateToggle({ Name = "Hitbox Expander", CurrentValue = false, Callback = function(v)
    hitboxEnabled = v
    if not v then
        for plr, size in pairs(originalHitboxSizes) do
            if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.Size = size
                plr.Character.HumanoidRootPart.Transparency = 1
            end
        end
        originalHitboxSizes = {}
    end
end })
CombatTab:CreateSlider({ Name = "Hitbox Size", Range = {2, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) hitboxSize = v end })

-- ========== VISUALS TAB (ALL DISABLED ON STARTUP) ==========
VisualsTab:CreateToggle({ Name = "ESP Boxes", CurrentValue = false, Callback = function(v) espBoxEnabled = v end })
VisualsTab:CreateToggle({ Name = "ESP Tracers", CurrentValue = false, Callback = function(v) espTracerEnabled = v end })
VisualsTab:CreateToggle({ Name = "ESP Names", CurrentValue = false, Callback = function(v) espNamesEnabled = v end })
VisualsTab:CreateToggle({ Name = "ESP Distance & HP", CurrentValue = false, Callback = function(v)
    espDistanceEnabled = v
    espHealthEnabled = v
end })
VisualsTab:CreateToggle({ Name = "Skeleton ESP", CurrentValue = false, Callback = function(v) skeletonEspEnabled = v end })
VisualsTab:CreateToggle({ Name = "Wallhack (Highlight)", CurrentValue = false, Callback = function(v)
    wallhackEnabled = v
    if not v then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character then
                local hl = plr.Character:FindFirstChild("WIA_WH")
                if hl then hl:Destroy() end
            end
        end
    end
end })
VisualsTab:CreateToggle({ Name = "FullBright", CurrentValue = false, Callback = function(v)
    fullBrightEnabled = v
    if v then
        originalBrightness, originalAmbient = Lighting.Brightness, Lighting.Ambient
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        if originalBrightness then Lighting.Brightness = originalBrightness end
        if originalAmbient then Lighting.Ambient = originalAmbient end
    end
end })
VisualsTab:CreateToggle({ Name = "No Fog", CurrentValue = false, Callback = function(v)
    noFogEnabled = v
    if v then
        originalFog = Lighting.FogEnd
        Lighting.FogEnd = 1e6
    else
        if originalFog then Lighting.FogEnd = originalFog end
    end
end })
VisualsTab:CreateSlider({ Name = "Camera FOV", Range = {50, 120}, Increment = 1, CurrentValue = 70, Callback = function(v) Camera.FieldOfView = v end })

-- ========== MOVEMENT & CAM TAB ==========
MovementTab:CreateToggle({ Name = "Flight", CurrentValue = false, Callback = function(v)
    flightEnabled = v
    if v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        bodyVelocity = Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart)
        bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bodyGyro = Instance.new("BodyGyro", LocalPlayer.Character.HumanoidRootPart)
        bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    else
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    end
end })
MovementTab:CreateSlider({ Name = "Fly Speed", Range = {10, 300}, Increment = 5, CurrentValue = 50, Callback = function(v) flySpeed = v end })

MovementTab:CreateToggle({ Name = "Enhanced Noclip", CurrentValue = false, Callback = function(v) noclipEnabled = v end })

MovementTab:CreateToggle({ Name = "Freecam", CurrentValue = false, Callback = function(v)
    freecamEnabled = v
    if v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        freecamPos = LocalPlayer.Character.HumanoidRootPart.Position
    end
end })
MovementTab:CreateSlider({ Name = "Freecam Speed", Range = {10, 200}, Increment = 5, CurrentValue = 50, Callback = function(v) freecamSpeed = v end })

MovementTab:CreateToggle({ Name = "Custom Gravity", CurrentValue = false, Callback = function(v)
    customGravityEnabled = v
    if not v then Workspace.Gravity = originalGravity end
end })
MovementTab:CreateSlider({ Name = "Gravity Value", Range = {0, 300}, Increment = 5, CurrentValue = 196.2, Callback = function(v)
    gravityValue = v
end })

MovementTab:CreateToggle({ Name = "CFrame Speed (Bypass)", CurrentValue = false, Callback = function(v) cframeSpeedEnabled = v end })
MovementTab:CreateSlider({ Name = "CFrame Speed Multiplier", Range = {1, 10}, Increment = 0.5, CurrentValue = 2, Callback = function(v) cframeSpeedValue = v end })

MovementTab:CreateSlider({ Name = "Walk Speed", Range = {16, 200}, Increment = 1, CurrentValue = 16, Callback = function(v)
    walkSpeedValue = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end })
MovementTab:CreateSlider({ Name = "Jump Power", Range = {50, 300}, Increment = 5, CurrentValue = 50, Callback = function(v)
    jumpPowerValue = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        hum.UseJumpPower = true
        hum.JumpPower = v
    end
end })

MovementTab:CreateToggle({ Name = "Infinite Jump", CurrentValue = false, Callback = function(v) infiniteJumpEnabled = v end })
MovementTab:CreateToggle({ Name = "Bhop", CurrentValue = false, Callback = function(v) bhopEnabled = v end })
MovementTab:CreateToggle({ Name = "Spinbot", CurrentValue = false, Callback = function(v) spinbotEnabled = v end })
MovementTab:CreateSlider({ Name = "Spinbot Speed", Range = {5, 50}, Increment = 1, CurrentValue = 20, Callback = function(v) spinbotSpeed = v end })

-- ========== MISC TAB ==========
MiscTab:CreateToggle({ Name = "Godmode", CurrentValue = false, Callback = function(v) godmodeEnabled = v end })
MiscTab:CreateToggle({ Name = "Anti-Void", CurrentValue = false, Callback = function(v) antiVoidEnabled = v end })
MiscTab:CreateToggle({ Name = "Anti-Fall Damage", CurrentValue = false, Callback = function(v) antiFallEnabled = v end })
MiscTab:CreateToggle({ Name = "Anti-AFK", CurrentValue = false, Callback = function(v) antiAFKEnabled = v end })

MiscTab:CreateToggle({ Name = "Player Controls GUI", CurrentValue = false, Callback = function(v)
    playerListEnabled = v
    PlayerListGui.Enabled = v
    if v then updatePlayerList() end
end })

MiscTab:CreateToggle({ Name = "Teleport Tool (Persistent)", CurrentValue = false, Callback = function(v)
    tpToolActive = v
    if v then giveTPTool() else if tpTool then tpTool:Destroy() tpTool = nil end end
end })

MiscTab:CreateToggle({ Name = "AutoClicker", CurrentValue = false, Callback = function(v) autoClickerEnabled = v end })
MiscTab:CreateSlider({ Name = "Click Delay (ms)", Range = {10, 1000}, Increment = 10, CurrentValue = 100, Callback = function(v) autoClickerDelay = v end })
MiscTab:CreateToggle({ Name = "Chat Spam", CurrentValue = false, Callback = function(v) chatSpamEnabled = v end })

MiscTab:CreateButton({ Name = "Rejoin Server", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end })
MiscTab:CreateButton({ Name = "Server Hop", Callback = function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
    for _, s in pairs(servers) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            break
        end
    end
end })

-- ========== LOOPS & SYSTEM UPDATES ==========

-- Noclip loop
RunService.Stepped:Connect(function()
    if noclipEnabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Custom Gravity Loop
RunService.Heartbeat:Connect(function()
    if customGravityEnabled then
        Workspace.Gravity = gravityValue
    end
end)

-- Freecam Loop
RunService.RenderStepped:Connect(function()
    if freecamEnabled then
        Camera.CameraType = Enum.CameraType.Scriptable
        local moveDir = Vector3.new(0, 0, 0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

        freecamPos = freecamPos + (moveDir * (freecamSpeed * 0.05))
        Camera.CFrame = CFrame.new(freecamPos)
    else
        if not spectateEnabled then
            Camera.CameraType = Enum.CameraType.Custom
        end
    end
end)

-- Spectate Loop
RunService.RenderStepped:Connect(function()
    if spectateTarget and spectateTarget.Character and spectateTarget.Character:FindFirstChild("HumanoidRootPart") then
        spectateEnabled = true
        Camera.CameraType = Enum.CameraType.Scriptable
        local targetPart = spectateTarget.Character.HumanoidRootPart
        Camera.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 4, -10), targetPart.Position)
    else
        if spectateEnabled and not freecamEnabled then
            spectateEnabled = false
            Camera.CameraType = Enum.CameraType.Custom
        end
    end
end)

-- Aimbot Target Resolver
local function getAimbotTarget()
    if aimbotSelectedTarget and aimbotSelectedTarget.Character and aimbotSelectedTarget.Character:FindFirstChild("Head") then
        return aimbotSelectedTarget
    end
    local closest, minDist = nil, aimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local pos, onScreen = Camera:WorldToScreenPoint(plr.Character.Head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

-- MM2 Auto Aim & General Aimbot Loop
RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = aimbotEnabled and fovCircleVisible
    end

    if mm2AutoAimMurderer then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getMM2Role(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("Head") then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, plr.Character.Head.Position)
                break
            end
        end
    elseif aimbotEnabled then
        local target = getAimbotTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetPos = target.Character.Head.Position
            local currentCFrame = Camera.CFrame
            local newCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(newCFrame, 1 / aimbotSmoothness)
        end
    end
end)

-- MM2 Silent Aim
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    if mm2SilentAim and tostring(method) == "FindPartOnRayWithIgnoreList" then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getMM2Role(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("Head") then
                return plr.Character.Head, plr.Character.Head.Position
            end
        end
    end
    return oldNamecall(self, ...)
end)

-- MM2 Kill Aura
RunService.Heartbeat:Connect(function()
    if killAuraEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and plr.Character:FindFirstChild("Humanoid") then
                    if plr.Character.Humanoid.Health > 0 then
                        local dist = (plr.Character.HumanoidRootPart.Position - myPos).Magnitude
                        if dist <= killAuraRange then
                            tool:Activate()
                        end
                    end
                end
            end
        end
    end
end)

-- Triggerbot
RunService.RenderStepped:Connect(function()
    if triggerbotEnabled then
        local target = Mouse.Target
        if target and target.Parent then
            local plr = Players:GetPlayerFromCharacter(target.Parent)
            if plr and plr ~= LocalPlayer then
                mouse1click()
            end
        end
    end
end)

-- MM2 Highlight Loop
RunService.Heartbeat:Connect(function()
    if mm2EspEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local role = getMM2Role(plr)
                local hl = plr.Character:FindFirstChild("WIA_MM2_ESP")
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = "WIA_MM2_ESP"
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = plr.Character
                end
                
                if role == "Murderer" then
                    hl.FillColor = Color3.fromRGB(255, 0, 0)
                elseif role == "Sheriff" then
                    hl.FillColor = Color3.fromRGB(0, 150, 255)
                else
                    hl.FillColor = Color3.fromRGB(0, 255, 100)
                end
                hl.FillTransparency = 0.4
            end
        end
    end
end)

-- Movement & Hitboxes loop
RunService.Heartbeat:Connect(function()
    if flightEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and bodyVelocity then
        local root = LocalPlayer.Character.HumanoidRootPart
        local moveDir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end

        if moveDir.Magnitude > 0 then
            bodyVelocity.Velocity = moveDir.Unit * flySpeed
            bodyGyro.CFrame = CFrame.new(root.Position, root.Position + moveDir)
        else
            bodyVelocity.Velocity = Vector3.new(0,0,0)
        end
    end

    if cframeSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        local root = LocalPlayer.Character.HumanoidRootPart
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (cframeSpeedValue / 10))
        end
    end

    if bhopEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end

    if godmodeEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
    end

    if hitboxEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = plr.Character.HumanoidRootPart
                if not originalHitboxSizes[plr] then
                    originalHitboxSizes[plr] = hrp.Size
                end
                hrp.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                hrp.Transparency = 0.7
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if spinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
    end
end)

-- Anti-Void & Anti-Fall
RunService.Heartbeat:Connect(function()
    if antiVoidEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character.HumanoidRootPart.Position.Y < -50 then
            local spawn = Workspace:FindFirstChild("SpawnLocation")
            if spawn then LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0) end
        end
    end
    if antiFallEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end)

-- Utilities Tasks
task.spawn(function()
    while true do
        task.wait(autoClickerDelay / 1000)
        if autoClickerEnabled then mouse1click() end
    end
end)

task.spawn(function()
    while true do
        task.wait(chatSpamDelay)
        if chatSpamEnabled then
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(chatSpamMessage, "All")
            end
        end
    end
end)

local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if antiAFKEnabled then
        vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Advanced ESP & Render Engine (CLEANS DYNAMICALLY)
local PURPLE = Color3.fromRGB(180, 0, 255)
RunService.RenderStepped:Connect(function()
    -- ALWAYS CLEAN DRAWINGS EVERY FRAME
    for i = #espLines, 1, -1 do espLines[i]:Remove() espLines[i] = nil end
    for i = #tracerLines, 1, -1 do tracerLines[i]:Remove() tracerLines[i] = nil end
    for i = #textDrawings, 1, -1 do textDrawings[i]:Remove() textDrawings[i] = nil end
    for i = #skeletonLines, 1, -1 do skeletonLines[i]:Remove() skeletonLines[i] = nil end

    if not (espBoxEnabled or espTracerEnabled or espNamesEnabled or skeletonEspEnabled or espDistanceEnabled or espHealthEnabled) then return end

    local camPos = Camera.CFrame.Position
    local viewport = Camera.ViewportSize

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") then
            local char = plr.Character
            local head = char.Head
            local hum = char.Humanoid
            local pos, onScreen = Camera:WorldToScreenPoint(head.Position)

            if onScreen then
                local dist = math.floor((head.Position - camPos).Magnitude)
                local size = math.clamp(100 / dist * 10, 15, 45)

                if espBoxEnabled then
                    local lines = { Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line") }
                    local x, y = pos.X - size/2, pos.Y - size/2
                    lines[1].From = Vector2.new(x, y) lines[1].To = Vector2.new(x + size, y)
                    lines[2].From = Vector2.new(x + size, y) lines[2].To = Vector2.new(x + size, y + size)
                    lines[3].From = Vector2.new(x + size, y + size) lines[3].To = Vector2.new(x, y + size)
                    lines[4].From = Vector2.new(x, y + size) lines[4].To = Vector2.new(x, y)
                    for j = 1, 4 do
                        lines[j].Color = PURPLE
                        lines[j].Thickness = 2
                        lines[j].Transparency = 1
                        lines[j].Visible = true
                        espLines[#espLines + 1] = lines[j]
                    end
                end

                if espTracerEnabled then
                    local tracer = Drawing.new("Line")
                    tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
                    tracer.To = Vector2.new(pos.X, pos.Y)
                    tracer.Color = PURPLE
                    tracer.Thickness = 1.5
                    tracer.Transparency = 0.7
                    tracer.Visible = true
                    tracerLines[#tracerLines + 1] = tracer
                end

                if skeletonEspEnabled then
                    local function drawBone(p1, p2)
                        if p1 and p2 then
                            local s1, o1 = Camera:WorldToScreenPoint(p1.Position)
                            local s2, o2 = Camera:WorldToScreenPoint(p2.Position)
                            if o1 and o2 then
                                local boneLine = Drawing.new("Line")
                                boneLine.From = Vector2.new(s1.X, s1.Y)
                                boneLine.To = Vector2.new(s2.X, s2.Y)
                                boneLine.Color = Color3.fromRGB(255, 0, 255)
                                boneLine.Thickness = 1.5
                                boneLine.Transparency = 0.8
                                boneLine.Visible = true
                                skeletonLines[#skeletonLines + 1] = boneLine
                            end
                        end
                    end
                    if char:FindFirstChild("UpperTorso") then
                        drawBone(char.Head, char.UpperTorso)
                        drawBone(char.UpperTorso, char.LowerTorso)
                        drawBone(char.UpperTorso, char.LeftUpperArm)
                        drawBone(char.LeftUpperArm, char.LeftLowerArm)
                        drawBone(char.LeftLowerArm, char.LeftHand)
                        drawBone(char.UpperTorso, char.RightUpperArm)
                        drawBone(char.RightUpperArm, char.RightLowerArm)
                        drawBone(char.RightLowerArm, char.RightHand)
                        drawBone(char.LowerTorso, char.LeftUpperLeg)
                        drawBone(char.LeftUpperLeg, char.LeftLowerLeg)
                        drawBone(char.LeftLowerLeg, char.LeftFoot)
                        drawBone(char.LowerTorso, char.RightUpperLeg)
                        drawBone(char.RightUpperLeg, char.RightLowerLeg)
                        drawBone(char.RightLowerLeg, char.RightFoot)
                    elseif char:FindFirstChild("Torso") then
                        drawBone(char.Head, char.Torso)
                        drawBone(char.Torso, char["Left Arm"])
                        drawBone(char.Torso, char["Right Arm"])
                        drawBone(char.Torso, char["Left Leg"])
                        drawBone(char.Torso, char["Right Leg"])
                    end
                end

                if espNamesEnabled or espDistanceEnabled or espHealthEnabled then
                    local text = Drawing.new("Text")
                    text.Position = Vector2.new(pos.X, pos.Y - size/2 - 18)
                    text.Size = 13
                    text.Center = true
                    text.Outline = true
                    text.Color = Color3.fromRGB(255, 255, 255)

                    local content = ""
                    if espNamesEnabled then content = content .. plr.Name .. " " end
                    if espHealthEnabled then content = content .. "[" .. math.floor(hum.Health) .. "HP] " end
                    if espDistanceEnabled then content = content .. "(" .. dist .. "m)" end

                    text.Text = content
                    text.Visible = true
                    textDrawings[#textDrawings + 1] = text
                end
            end
        end
    end
end)

-- Wallhack Highlight Loop
RunService.Heartbeat:Connect(function()
    if wallhackEnabled then
        local targetColor = Color3.fromRGB(180, 0, 255)
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("WIA_WH") then
                local hl = Instance.new("Highlight")
                hl.Name = "WIA_WH"
                hl.FillColor = targetColor
                hl.FillTransparency = 0.3
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = plr.Character
            end
        end
    end
end)

Rayfield:Notify({
    Title = "WIA HUB v9.6 Loaded",
    Content = "MM2 Hub, Profile Info (FPS/Ping), and ESP fixes active!",
    Duration = 5,
    Image = 4483362458,
})