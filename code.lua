-- ================================================================= --
-- WIA HUB v8.0 Ultimate Edition :: whitewia / tordark (Rayfield GUI)
-- RAYFIELD UI + AIMBOT + SKELETON ESP + PLAYER LIST + EXTENDED ESP + PERSISTENT TP TOOL
-- ================================================================= --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
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
local tpTool = nil
local tpEnabled = false

local wallhackEnabled = false
local antiAFKEnabled = false
local playerListEnabled = false
local antiVoidEnabled = false
local fullBrightEnabled, noFogEnabled = false, false
local originalBrightness, originalAmbient, originalFog = nil, nil, nil

local aimbotFOV = 90
local aimbotSmoothness = 5
local aimbotSelectedTarget = nil
local fovCircleVisible = true

local hitboxEnabled = false
local hitboxSize = 5
local autoClickerEnabled, autoClickerDelay = false, 100
local triggerbotEnabled = false

local chatSpamEnabled, chatSpamMessage, chatSpamDelay = false, "WIA HUB ON TOP", 5
local antiFallEnabled = false

local aimbotEnabled = false

-- ESP Extras
local espBoxEnabled = true
local espTracerEnabled = true
local espNamesEnabled = true
local espDistanceEnabled = true
local espHealthEnabled = true
local skeletonEspEnabled = true -- Added Skeleton ESP toggle default
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
    Name = "WIA HUB v8.0 Ultimate Edition",
    LoadingTitle = "WIA HUB Loading...",
    LoadingSubtitle = "by whitewia / tordark",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = "WiaHubConfig",
        FileName = "WiaHub"
    },
    Discord = { Enabled = false },
    KeySystem = false
})

local CombatTab = Window:CreateTab("Combat & Aim", 4483362458)
local VisualsTab = Window:CreateTab("Visuals & ESP", 4483345998)
local MovementTab = Window:CreateTab("Movement", 4483345998)
local MiscTab = Window:CreateTab("Misc & Utilities", 4483362458)

-- ========== PLAYER LIST GUI (NATIVE OVERLAY) ==========
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList_v8"
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

local PlayerListMain = Instance.new("Frame")
PlayerListMain.Size = UDim2.new(0, 260, 0, 400)
PlayerListMain.Position = UDim2.new(0, 360, 0, 10)
PlayerListMain.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
PlayerListMain.BackgroundTransparency = 0.3
PlayerListMain.BorderSizePixel = 1
PlayerListMain.BorderColor3 = Color3.fromRGB(180, 0, 255)
PlayerListMain.ClipsDescendants = true
PlayerListMain.Parent = PlayerListGui

local PlayerListTitle = Instance.new("TextLabel")
PlayerListTitle.Size = UDim2.new(1, 0, 0, 30)
PlayerListTitle.Text = "PLAYER LIST / AIM TARGET"
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
TargetStatus.Text = "Target: Auto (Closest)"
TargetStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetStatus.Font = Enum.Font.Gotham
TargetStatus.TextSize = 12
TargetStatus.Parent = PlayerListMain

-- Draggable Function for Player List
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
            btn.Text = plr.Name .. "  [TP]  [AIM]"
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.BackgroundColor3 = (aimbotSelectedTarget == plr) and Color3.fromRGB(0, 120, 60) or Color3.fromRGB(40,40,55)
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 11
            btn.Parent = PlayerListContainer

            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                end
            end)

            btn.MouseButton2Click:Connect(function()
                if aimbotSelectedTarget == plr then
                    aimbotSelectedTarget = nil
                    TargetStatus.Text = "Target: Auto (Closest)"
                    TargetStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
                else
                    aimbotSelectedTarget = plr
                    TargetStatus.Text = "Target: " .. plr.Name
                    TargetStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
                end
                updatePlayerList()
            end)

            y = y + 27
        end
    end

    PlayerListContainer.Size = UDim2.new(1, 0, 0, y)
    playerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, y + 10)
end

-- ========== TELEPORT TOOL FUNCTIONS (PERSISTENT AFTER DEATH) ==========
local function createTPTool()
    local tool = Instance.new("Tool")
    tool.Name = "WIA_TP"
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    local function teleport(mousePos)
        if not tpEnabled then return end
        local targetPos = mousePos.Hit.Position
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))

            local part = Instance.new("Part")
            part.Size = Vector3.new(2, 0.5, 2)
            part.Position = targetPos
            part.Anchored = true
            part.CanCollide = false
            part.BrickColor = BrickColor.new("Bright violet")
            part.Material = Enum.Material.Neon
            part.Transparency = 0.5
            part.Parent = workspace
            game:GetService("Debris"):AddItem(part, 0.5)
        end
    end

    tool.Equipped:Connect(function()
        tpEnabled = true
        Mouse.Icon = "rbxasset://SystemCursors/Crosshair"
    end)

    tool.Unequipped:Connect(function()
        tpEnabled = false
        Mouse.Icon = "rbxasset://SystemCursors/Arrow"
    end)

    tool.Activated:Connect(function()
        if tpEnabled then
            teleport(Mouse)
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

-- ========== COMBAT TAB CONTROLS ==========
CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(Value)
        aimbotEnabled = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Aimbot FOV Circle",
    CurrentValue = true,
    Callback = function(Value)
        fovCircleVisible = Value
    end,
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {10, 400},
    Increment = 5,
    CurrentValue = 90,
    Callback = function(Value)
        aimbotFOV = Value
    end,
})

CombatTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value)
        aimbotSmoothness = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Triggerbot (AutoShot)",
    CurrentValue = false,
    Callback = function(Value)
        triggerbotEnabled = Value
    end,
})

CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Callback = function(Value)
        hitboxEnabled = Value
        if not Value then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    plr.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                end
            end
        end
    end,
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value)
        hitboxSize = Value
    end,
})

-- ========== VISUALS TAB CONTROLS ==========
VisualsTab:CreateToggle({
    Name = "ESP Boxes",
    CurrentValue = true,
    Callback = function(Value)
        espBoxEnabled = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "ESP Tracers",
    CurrentValue = true,
    Callback = function(Value)
        espTracerEnabled = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "ESP Names",
    CurrentValue = true,
    Callback = function(Value)
        espNamesEnabled = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "ESP Distance & Health",
    CurrentValue = true,
    Callback = function(Value)
        espDistanceEnabled = Value
        espHealthEnabled = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "Skeleton ESP",
    CurrentValue = true,
    Callback = function(Value)
        skeletonEspEnabled = Value
    end,
})

VisualsTab:CreateToggle({
    Name = "Wallhack (Highlight)",
    CurrentValue = false,
    Callback = function(Value)
        wallhackEnabled = Value
        if not Value then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr.Character and plr.Character:FindFirstChild("WIA_WH") then
                    plr.Character.WIA_WH:Destroy()
                end
            end
        end
    end,
})

VisualsTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Callback = function(Value)
        fullBrightEnabled = Value
        if Value then
            originalBrightness = Lighting.Brightness
            originalAmbient = Lighting.Ambient
            Lighting.Brightness = 2
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        else
            if originalBrightness then Lighting.Brightness = originalBrightness end
            if originalAmbient then Lighting.Ambient = originalAmbient end
        end
    end,
})

VisualsTab:CreateToggle({
    Name = "No Fog (FPS Boost)",
    CurrentValue = false,
    Callback = function(Value)
        noFogEnabled = Value
        if Value then
            originalFog = Lighting.FogEnd
            Lighting.FogEnd = 1e6
        else
            if originalFog then Lighting.FogEnd = originalFog end
        end
    end,
})

VisualsTab:CreateSlider({
    Name = "Camera FOV",
    Range = {50, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(Value)
        Camera.FieldOfView = Value
    end,
})

-- ========== MOVEMENT TAB CONTROLS ==========
MovementTab:CreateToggle({
    Name = "Flight",
    CurrentValue = false,
    Callback = function(Value)
        flightEnabled = Value
        if Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            bodyVelocity = Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart)
            bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bodyGyro = Instance.new("BodyGyro", LocalPlayer.Character.HumanoidRootPart)
            bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
        else
            if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
            if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        flySpeed = Value
    end,
})

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(Value)
        noclipEnabled = Value
    end,
})

MovementTab:CreateToggle({
    Name = "CFrame Speed (Bypass)",
    CurrentValue = false,
    Callback = function(Value)
        cframeSpeedEnabled = Value
    end,
})

MovementTab:CreateSlider({
    Name = "CFrame Speed Multiplier",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(Value)
        cframeSpeedValue = Value
    end,
})

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        walkSpeedValue = Value
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        jumpPowerValue = Value
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = Value
        end
    end,
})

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        infiniteJumpEnabled = Value
    end,
})

MovementTab:CreateToggle({
    Name = "Bhop (FIXED)",
    CurrentValue = false,
    Callback = function(Value)
        bhopEnabled = Value
    end,
})

MovementTab:CreateToggle({
    Name = "Spinbot",
    CurrentValue = false,
    Callback = function(Value)
        spinbotEnabled = Value
    end,
})

MovementTab:CreateSlider({
    Name = "Spinbot Speed",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 20,
    Callback = function(Value)
        spinbotSpeed = Value
    end,
})

-- ========== MISC & UTILITIES TAB CONTROLS ==========
MiscTab:CreateToggle({
    Name = "Godmode",
    CurrentValue = false,
    Callback = function(Value)
        godmodeEnabled = Value
        if Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
        end
    end,
})

MiscTab:CreateToggle({
    Name = "Anti-Void",
    CurrentValue = false,
    Callback = function(Value)
        antiVoidEnabled = Value
    end,
})

MiscTab:CreateToggle({
    Name = "Anti-Fall Damage",
    CurrentValue = false,
    Callback = function(Value)
        antiFallEnabled = Value
    end,
})

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(Value)
        antiAFKEnabled = Value
    end,
})

MiscTab:CreateToggle({
    Name = "Player List GUI",
    CurrentValue = false,
    Callback = function(Value)
        playerListEnabled = Value
        PlayerListGui.Enabled = Value
        if Value then updatePlayerList() end
    end,
})

MiscTab:CreateToggle({
    Name = "Teleport Tool (Persistent)",
    CurrentValue = false,
    Callback = function(Value)
        tpToolActive = Value
        if Value then
            giveTPTool()
        else
            if tpTool then
                tpTool:Destroy()
                tpTool = nil
            end
        end
    end,
})

MiscTab:CreateToggle({
    Name = "AutoClicker",
    CurrentValue = false,
    Callback = function(Value)
        autoClickerEnabled = Value
    end,
})

MiscTab:CreateSlider({
    Name = "Click Delay (ms)",
    Range = {10, 1000},
    Increment = 10,
    CurrentValue = 100,
    Callback = function(Value)
        autoClickerDelay = Value
    end,
})

MiscTab:CreateToggle({
    Name = "Chat Spam",
    CurrentValue = false,
    Callback = function(Value)
        chatSpamEnabled = Value
    end,
})

MiscTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

MiscTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
        for _, s in pairs(servers) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                break
            end
        end
    end,
})

-- ========== AIMBOT ENGINE ==========
local function getAimbotTarget()
    if aimbotSelectedTarget and aimbotSelectedTarget.Character and aimbotSelectedTarget.Character:FindFirstChild("Head") then
        return aimbotSelectedTarget
    end

    local closest = nil
    local minDist = aimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local pos, onScreen = Camera:WorldToScreenPoint(head.Position)
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
            local head = target.Character.Head
            local targetPos = head.Position
            local currentCFrame = Camera.CFrame
            local newCFrame = CFrame.new(currentCFrame.Position, targetPos)

            if aimbotSmoothness > 1 then
                Camera.CFrame = currentCFrame:Lerp(newCFrame, 1 / aimbotSmoothness)
            else
                Camera.CFrame = newCFrame
            end
        end
    end
end)

-- ========== TRIGGERBOT ENGINE ==========
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

-- ========== GAME LOOPS & HEARTBEAT ==========

-- Flight Loop
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
end)

-- CFrame Speed Loop
RunService.Heartbeat:Connect(function()
    if cframeSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        local root = LocalPlayer.Character.HumanoidRootPart
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (cframeSpeedValue / 10))
        end
    end
end)

-- BHOP Loop
RunService.Heartbeat:Connect(function()
    if bhopEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Spinbot Loop
RunService.RenderStepped:Connect(function()
    if spinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
    end
end)

-- Noclip & Hitbox & Godmode Loop
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        if noclipEnabled then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        if godmodeEnabled and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = char.Humanoid.MaxHealth
        end
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

-- Anti-Void Loop
RunService.Heartbeat:Connect(function()
    if antiVoidEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character.HumanoidRootPart.Position.Y < -50 then
            local spawn = workspace:FindFirstChild("SpawnLocation")
            if spawn then
                LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- Anti-Fall Loop
RunService.Heartbeat:Connect(function()
    if antiFallEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end)

-- AutoClicker Loop
task.spawn(function()
    while true do
        task.wait(autoClickerDelay / 1000)
        if autoClickerEnabled then
            mouse1click()
        end
    end
end)

-- Chat Spam Loop
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

-- Anti-AFK Connection
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if antiAFKEnabled then
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- Infinite Jump Request
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ========== ADVANCED DRAWING ESP & SKELETON ENGINE ==========
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

                -- ESP Box
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

                -- ESP Tracers
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

                -- Skeleton ESP (R15 / R6 Support)
                if skeletonEspEnabled then
                    local function drawBone(part1, part2)
                        if part1 and part2 then
                            local p1, on1 = Camera:WorldToScreenPoint(part1.Position)
                            local p2, on2 = Camera:WorldToScreenPoint(part2.Position)
                            if on1 and on2 then
                                local boneLine = Drawing.new("Line")
                                boneLine.From = Vector2.new(p1.X, p1.Y)
                                boneLine.To = Vector2.new(p2.X, p2.Y)
                                boneLine.Color = Color3.fromRGB(255, 0, 255)
                                boneLine.Thickness = 1.5
                                boneLine.Transparency = 0.8
                                boneLine.Visible = true
                                skeletonLines[#skeletonLines + 1] = boneLine
                            end
                        end
                    end

                    -- Check R15 or R6
                    if char:FindFirstChild("UpperTorso") then
                        -- R15 Skeleton
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
                        -- R6 Skeleton
                        drawBone(char.Head, char.Torso)
                        drawBone(char.Torso, char["Left Arm"])
                        drawBone(char.Torso, char["Right Arm"])
                        drawBone(char.Torso, char["Left Leg"])
                        drawBone(char.Torso, char["Right Leg"])
                    end
                end

                -- Names & Stats Text
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

-- Wallhack Highlight Loop
RunService.Heartbeat:Connect(function()
    if wallhackEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("WIA_WH") then
                local hl = Instance.new("Highlight")
                hl.Name = "WIA_WH"
                hl.FillColor = Color3.fromRGB(180, 0, 255)
                hl.FillTransparency = 0.3
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = plr.Character
            end
        end
    end
end)

Rayfield:Notify({
    Title = "WIA HUB v8.0 Loaded",
    Content = "Rayfield UI + Skeleton ESP + Persistent TP Tool active!",
    Duration = 5,
    Image = 4483362458,
})