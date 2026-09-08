-- ================================================================= --
-- WIA HUB v9.0 Ultimate Edition :: whitewia / tordark (Rayfield GUI)
-- FULL FEATURES + FIXED SKELETON + ENHANCED NOCLIP + GRAVITY & CAM
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

-- New Features & Adjustments Variables
local customGravityEnabled = false
local gravityValue = 196.2
local originalGravity = Workspace.Gravity

local freecamEnabled = false
local freecamSpeed = 50
local freecamPos = Vector3.new(0, 10, 0)

local spectateEnabled = false
local spectateTarget = nil

local aimbotFOV = 90
local aimbotSmoothness = 5
local aimbotSelectedTarget = nil
local fovCircleVisible = true
local aimbotEnabled = false

local hitboxEnabled = false
local hitboxSize = 5
local autoClickerEnabled, autoClickerDelay = false, 100
local triggerbotEnabled = false

local chatSpamEnabled, chatSpamMessage, chatSpamDelay = false, "WIA HUB ON TOP", 5
local antiFallEnabled = false

-- ESP Extras
local espBoxEnabled = true
local espTracerEnabled = true
local espNamesEnabled = true
local espDistanceEnabled = true
local espHealthEnabled = true
local skeletonEspEnabled = true
local espLines, tracerLines, textDrawings, skeletonLines = {}, {}, {}, {}

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

-- ========== RAYFIELD WINDOW SETUP ==========
local Window = Rayfield:CreateWindow({
    Name = "WIA HUB v9.0 Ultimate Edition",
    LoadingTitle = "WIA HUB v9.0 Loading...",
    LoadingSubtitle = "by whitewia / tordark",
    ConfigurationSaving = { Enabled = false },
    Discord = { Enabled = false },
    KeySystem = false
})

local CombatTab = Window:CreateTab("Combat & Aim", 4483362458)
local VisualsTab = Window:CreateTab("Visuals & ESP", 4483345998)
local MovementTab = Window:CreateTab("Movement & Cam", 4483345998)
local MiscTab = Window:CreateTab("Misc & Utilities", 4483362458)

-- ========== PLAYER LIST & SPECTATE UI ==========
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList_v90"
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

local PlayerListMain = Instance.new("Frame")
PlayerListMain.Size = UDim2.new(0, 280, 0, 420)
PlayerListMain.Position = UDim2.new(0, 360, 0, 10)
PlayerListMain.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
PlayerListMain.BackgroundTransparency = 0.3
PlayerListMain.BorderSizePixel = 1
PlayerListMain.BorderColor3 = Color3.fromRGB(180, 0, 255)
PlayerListMain.ClipsDescendants = true
PlayerListMain.Parent = PlayerListGui

local PlayerListTitle = Instance.new("TextLabel")
PlayerListTitle.Size = UDim2.new(1, 0, 0, 30)
PlayerListTitle.Text = "PLAYER LIST / SPECTATE / AIM"
PlayerListTitle.TextColor3 = Color3.fromRGB(180, 0, 255)
PlayerListTitle.TextScaled = true
PlayerListTitle.BackgroundTransparency = 1
PlayerListTitle.Font = Enum.Font.GothamBold
PlayerListTitle.Parent = PlayerListMain

local playerListScrollingFrame = Instance.new("ScrollingFrame")
playerListScrollingFrame.Size = UDim2.new(1, -10, 1, -65)
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
TargetStatus.Size = UDim2.new(1, -20, 0, 25)
TargetStatus.Position = UDim2.new(0, 10, 1, -28)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = "Target: Auto | Spec: None"
TargetStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetStatus.Font = Enum.Font.Gotham
TargetStatus.TextSize = 11
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
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 25)
            btn.Position = UDim2.new(0, 0, 0, y)
            btn.Text = plr.Name .. " [TP] [SPEC] [AIM]"
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.BackgroundColor3 = (aimbotSelectedTarget == plr) and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40,40,55)
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 10
            btn.Parent = PlayerListContainer

            -- Left Click: Teleport
            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end)

            -- Right Click: Set Aimbot Target & Spectate Toggle Cycle
            btn.MouseButton2Click:Connect(function()
                if spectateTarget == plr then
                    spectateTarget = nil
                else
                    spectateTarget = plr
                end
                TargetStatus.Text = "Target: " .. (aimbotSelectedTarget and aimbotSelectedTarget.Name or "Auto") .. " | Spec: " .. (spectateTarget and spectateTarget.Name or "None")
                updatePlayerList()
            end)

            y = y + 27
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
CombatTab:CreateToggle({ Name = "Aimbot FOV Circle", CurrentValue = true, Callback = function(v) fovCircleVisible = v end })
CombatTab:CreateSlider({ Name = "Aimbot FOV", Range = {10, 400}, Increment = 5, CurrentValue = 90, Callback = function(v) aimbotFOV = v end })
CombatTab:CreateSlider({ Name = "Aimbot Smoothness", Range = {1, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) aimbotSmoothness = v end })
CombatTab:CreateToggle({ Name = "Triggerbot (AutoShot)", CurrentValue = false, Callback = function(v) triggerbotEnabled = v end })
CombatTab:CreateToggle({ Name = "Hitbox Expander", CurrentValue = false, Callback = function(v) hitboxEnabled = v end })
CombatTab:CreateSlider({ Name = "Hitbox Size", Range = {2, 20}, Increment = 1, CurrentValue = 5, Callback = function(v) hitboxSize = v end })

-- ========== VISUALS TAB ==========
VisualsTab:CreateToggle({ Name = "ESP Boxes", CurrentValue = true, Callback = function(v) espBoxEnabled = v end })
VisualsTab:CreateToggle({ Name = "ESP Tracers", CurrentValue = true, Callback = function(v) espTracerEnabled = v end })
VisualsTab:CreateToggle({ Name = "ESP Names", CurrentValue = true, Callback = function(v) espNamesEnabled = v end })
VisualsTab:CreateToggle({ Name = "ESP Distance & HP", CurrentValue = true, Callback = function(v) espDistanceEnabled = v espHealthEnabled = v end })
VisualsTab:CreateToggle({ Name = "Skeleton ESP (Fixed)", CurrentValue = true, Callback = function(v) skeletonEspEnabled = v end })
VisualsTab:CreateToggle({ Name = "Wallhack (Highlight)", CurrentValue = false, Callback = function(v) wallhackEnabled = v end })
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
MovementTab:CreateSlider({ Name = "Jump Power", Range = {50, 200}, Increment = 5, CurrentValue = 50, Callback = function(v)
    jumpPowerValue = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
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

MiscTab:CreateToggle({ Name = "Player List / Spectate GUI", CurrentValue = false, Callback = function(v)
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

-- ========== ENHANCED SYSTEMS & LOOPS ==========

-- Bulletproof Optimized Noclip (Forces collision disabled across Character descendants seamlessly)
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

-- Spectate System Loop
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

-- Aimbot Engine
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

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = aimbotEnabled and fovCircleVisible
    end

    if aimbotEnabled then
        local target = getAimbotTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local targetPos = target.Character.Head.Position
            local currentCFrame = Camera.CFrame
            local newCFrame = CFrame.new(currentCFrame.Position, targetPos)
            Camera.CFrame = currentCFrame:Lerp(newCFrame, 1 / aimbotSmoothness)
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

-- Flight, CFrame Speed, Bhop, Spinbot, Godmode, Hitboxes
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
                plr.Character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                plr.Character.HumanoidRootPart.Transparency = 0.7
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

-- Advanced ESP & Fixed Scale Skeleton Engine (Accurate R15 / R6 mapping)
local PURPLE = Color3.fromRGB(180, 0, 255)
RunService.RenderStepped:Connect(function()
    for i = #espLines, 1, -1 do espLines[i]:Remove() espLines[i] = nil end
    for i = #tracerLines, 1, -1 do tracerLines[i]:Remove() tracerLines[i] = nil end
    for i = #textDrawings, 1, -1 do textDrawings[i]:Remove() textDrawings[i] = nil end
    for i = #skeletonLines, 1, -1 do skeletonLines[i]:Remove() skeletonLines[i] = nil end

    if not (espBoxEnabled or espTracerEnabled or espNamesEnabled or skeletonEspEnabled) then return end

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
                    -- Rig mapping verification (Supports R15 and R6 properly)
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

                if espNamesEnabled or espDistanceEnabled then
                    local text = Drawing.new("Text")
                    text.Position = Vector2.new(pos.X, pos.Y - size/2 - 15)
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

-- Wallhack Highlight
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
    Title = "WIA HUB v9.0 Ultimate",
    Content = "Skeleton ESP fixed, Noclip improved, Freecam & Spectate active!",
    Duration = 5,
    Image = 4483362458,
})