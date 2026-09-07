-- ================================================================= --
-- WIA HUB v8.0 Ultimate Edition :: whitewia / tordark
-- RAYFIELD UI EDITION (FULL LOGIC PRESERVED)
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
local walkSpeedEnabled, jumpPowerEnabled, cframeSpeedEnabled = false, false, false
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

local hitboxEnabled, hitboxSize = false, 5
local autoClickerEnabled, autoClickerDelay = false, 100
local triggerbotEnabled = false

local chatSpamEnabled, chatSpamMessage, chatSpamDelay = false, "WIA HUB ON TOP", 5
local antiFallEnabled = false

-- Aimbot Variables
local aimbotEnabled = false
local aimbotFOV = 90
local aimbotSmoothness = 5
local aimbotSelectedTarget = nil
local fovCircleVisible = true

-- ESP Extras
local espBoxEnabled = true
local espTracerEnabled = true
local espNamesEnabled = true
local espDistanceEnabled = true
local espHealthEnabled = true
local espLines, tracerLines, textDrawings = {}, {}, {}

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

-- ========== PLAYER LIST GUI (SEPARATE TARGET PANEL) ==========
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList_v8"
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

local PlayerListMain = Instance.new("Frame")
PlayerListMain.Size = UDim2.new(0, 260, 0, 400)
PlayerListMain.Position = UDim2.new(0, 360, 0, 10)
PlayerListMain.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
PlayerListMain.BackgroundTransparency = 0.2
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

-- Draggable Engine for Player List
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

-- TELEPORT TOOL LOGIC
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
        if tpEnabled then teleport(Mouse) end
    end)

    return tool
end

-- PLAYER LIST UPDATER
local function updatePlayerList()
    for _, btn in pairs(PlayerListContainer:GetChildren()) do btn:Destroy() end
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

-- AIMBOT ENGINE TARGET SELECTOR
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

-- ================================================================= --
-- RAYFIELD WINDOW & TABS CREATION
-- ================================================================= --

local Window = Rayfield:CreateWindow({
   Name = "WIA HUB v8.0 | Ultimate Edition",
   Icon = 0,
   LoadingTitle = "WIA HUB v8.0",
   LoadingSubtitle = "by whitewia / tordark",
   Theme = "Purple",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = false
   },
   KeySystem = false
})

-- TABS
local CombatTab = Window:CreateTab("Combat & Aim", 4483362458)
local VisualsTab = Window:CreateTab("ESP & Visuals", 4483345998)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local PlayerTab = Window:CreateTab("Player & Tools", 4483362458)
local WorldTab = Window:CreateTab("World & Auto", 4483362458)
local ServerTab = Window:CreateTab("Server", 4483362458)

-- ========== COMBAT TAB ==========
CombatTab:CreateToggle({
   Name = "Aimbot",
   CurrentValue = false,
   Flag = "AimbotToggle",
   Callback = function(Value) aimbotEnabled = Value end,
})

CombatTab:CreateToggle({
   Name = "Show FOV Circle",
   CurrentValue = true,
   Flag = "FOVCircleToggle",
   Callback = function(Value) fovCircleVisible = Value end,
})

CombatTab:CreateSlider({
   Name = "Aimbot FOV",
   Range = {10, 400},
   Increment = 1,
   Suffix = "px",
   CurrentValue = 90,
   Flag = "AimbotFOVSlider",
   Callback = function(Value) aimbotFOV = Value end,
})

CombatTab:CreateSlider({
   Name = "Aimbot Smoothness",
   Range = {1, 20},
   Increment = 1,
   Suffix = "",
   CurrentValue = 5,
   Flag = "AimbotSmoothSlider",
   Callback = function(Value) aimbotSmoothness = Value end,
})

CombatTab:CreateToggle({
   Name = "Triggerbot (AutoShot)",
   CurrentValue = false,
   Flag = "TriggerbotToggle",
   Callback = function(Value) triggerbotEnabled = Value end,
})

CombatTab:CreateToggle({
   Name = "Hitbox Expander",
   CurrentValue = false,
   Flag = "HitboxToggle",
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
   Suffix = " studs",
   CurrentValue = 5,
   Flag = "HitboxSizeSlider",
   Callback = function(Value) hitboxSize = Value end,
})

-- ========== VISUALS TAB ==========
VisualsTab:CreateToggle({
   Name = "ESP Boxes",
   CurrentValue = true,
   Flag = "ESPBoxToggle",
   Callback = function(Value) espBoxEnabled = Value end,
})

VisualsTab:CreateToggle({
   Name = "ESP Tracers",
   CurrentValue = true,
   Flag = "ESPTracerToggle",
   Callback = function(Value) espTracerEnabled = Value end,
})

VisualsTab:CreateToggle({
   Name = "ESP Names",
   CurrentValue = true,
   Flag = "ESPNameToggle",
   Callback = function(Value) espNamesEnabled = Value end,
})

VisualsTab:CreateToggle({
   Name = "ESP Distance & Health",
   CurrentValue = true,
   Flag = "ESPDistHPToggle",
   Callback = function(Value)
      espDistanceEnabled = Value
      espHealthEnabled = Value
   end,
})

VisualsTab:CreateToggle({
   Name = "Wallhack (Highlight)",
   CurrentValue = false,
   Flag = "WallhackToggle",
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

-- ========== MOVEMENT TAB ==========
MovementTab:CreateToggle({
   Name = "Flight",
   CurrentValue = false,
   Flag = "FlightToggle",
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
   Suffix = " speed",
   CurrentValue = 50,
   Flag = "FlySpeedSlider",
   Callback = function(Value) flySpeed = Value end,
})

MovementTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Flag = "NoclipToggle",
   Callback = function(Value) noclipEnabled = Value end,
})

MovementTab:CreateToggle({
   Name = "CFrame Speed (Bypass)",
   CurrentValue = false,
   Flag = "CFrameSpeedToggle",
   Callback = function(Value) cframeSpeedEnabled = Value end,
})

MovementTab:CreateSlider({
   Name = "CFrame Multiplier",
   Range = {1, 10},
   Increment = 1,
   Suffix = "x",
   CurrentValue = 2,
   Flag = "CFrameMultSlider",
   Callback = function(Value) cframeSpeedValue = Value end,
})

MovementTab:CreateSlider({
   Name = "Walk Speed",
   Range = {16, 200},
   Increment = 1,
   Suffix = "",
   CurrentValue = 16,
   Flag = "WalkSpeedSlider",
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
   Increment = 1,
   Suffix = "",
   CurrentValue = 50,
   Flag = "JumpPowerSlider",
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
   Flag = "InfJumpToggle",
   Callback = function(Value) infiniteJumpEnabled = Value end,
})

MovementTab:CreateToggle({
   Name = "Bhop (FIXED)",
   CurrentValue = false,
   Flag = "BhopToggle",
   Callback = function(Value) bhopEnabled = Value end,
})

MovementTab:CreateToggle({
   Name = "Spinbot",
   CurrentValue = false,
   Flag = "SpinbotToggle",
   Callback = function(Value) spinbotEnabled = Value end,
})

MovementTab:CreateSlider({
   Name = "Spinbot Speed",
   Range = {5, 50},
   Increment = 1,
   Suffix = " speed",
   CurrentValue = 20,
   Flag = "SpinbotSpeedSlider",
   Callback = function(Value) spinbotSpeed = Value end,
})

-- ========== PLAYER & TOOLS TAB ==========
PlayerTab:CreateToggle({
   Name = "Godmode",
   CurrentValue = false,
   Flag = "GodmodeToggle",
   Callback = function(Value)
      godmodeEnabled = Value
      if Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
         LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
      end
   end,
})

PlayerTab:CreateToggle({
   Name = "Anti-Void",
   CurrentValue = false,
   Flag = "AntiVoidToggle",
   Callback = function(Value) antiVoidEnabled = Value end,
})

PlayerTab:CreateToggle({
   Name = "Anti-Fall Damage",
   CurrentValue = false,
   Flag = "AntiFallToggle",
   Callback = function(Value) antiFallEnabled = Value end,
})

PlayerTab:CreateToggle({
   Name = "Anti-AFK",
   CurrentValue = false,
   Flag = "AntiAFKToggle",
   Callback = function(Value) antiAFKEnabled = Value end,
})

PlayerTab:CreateToggle({
   Name = "Teleport Tool",
   CurrentValue = false,
   Flag = "TPToolToggle",
   Callback = function(Value)
      if Value then
         if not tpTool then
            tpTool = createTPTool()
            tpTool.Parent = LocalPlayer.Backpack
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
               char.Humanoid:EquipTool(tpTool)
            end
         end
      else
         if tpTool then
            tpTool:Destroy()
            tpTool = nil
         end
      end
   end,
})

PlayerTab:CreateToggle({
   Name = "Player List GUI (Target Panel)",
   CurrentValue = false,
   Flag = "PlayerListGUIToggle",
   Callback = function(Value)
      playerListEnabled = Value
      PlayerListGui.Enabled = Value
      if Value then updatePlayerList() end
   end,
})

PlayerTab:CreateButton({
   Name = "Refresh Player List",
   Callback = function()
      if playerListEnabled then updatePlayerList() end
   end,
})

-- ========== WORLD & AUTO TAB ==========
WorldTab:CreateToggle({
   Name = "FullBright",
   CurrentValue = false,
   Flag = "FullBrightToggle",
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

WorldTab:CreateToggle({
   Name = "No Fog (FPS Boost)",
   CurrentValue = false,
   Flag = "NoFogToggle",
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

WorldTab:CreateSlider({
   Name = "Camera FOV",
   Range = {50, 120},
   Increment = 1,
   Suffix = " deg",
   CurrentValue = 70,
   Flag = "CamFOV",
   Callback = function(Value) Camera.FieldOfView = Value end,
})

WorldTab:CreateToggle({
   Name = "AutoClicker",
   CurrentValue = false,
   Flag = "AutoClickerToggle",
   Callback = function(Value) autoClickerEnabled = Value end,
})

WorldTab:CreateSlider({
   Name = "Click Delay (ms)",
   Range = {10, 1000},
   Increment = 10,
   Suffix = " ms",
   CurrentValue = 100,
   Flag = "ClickDelaySlider",
   Callback = function(Value) autoClickerDelay = Value end,
})

WorldTab:CreateToggle({
   Name = "Chat Spam",
   CurrentValue = false,
   Flag = "ChatSpamToggle",
   Callback = function(Value) chatSpamEnabled = Value end,
})

-- ========== SERVER TAB ==========
ServerTab:CreateButton({
   Name = "Rejoin Server",
   Callback = function()
      TeleportService:Teleport(game.PlaceId, LocalPlayer)
   end,
})

ServerTab:CreateButton({
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

-- ================================================================= --
-- GAME LOOPS & BACKGROUND PROCESSES (UNTOUCHED LOGIC)
-- ================================================================= --

-- Aimbot & FOV Circle Loop
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

-- Triggerbot Loop
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

-- BHOP
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

-- Anti-Fall
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
        if autoClickerEnabled then mouse1click() end
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

-- Anti-AFK Loop
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if antiAFKEnabled then
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ADVANCED DRAWING ESP ENGINE
local PURPLE = Color3.fromRGB(180, 0, 255)

RunService.RenderStepped:Connect(function()
    for i = #espLines, 1, -1 do espLines[i]:Remove() espLines[i] = nil end
    for i = #tracerLines, 1, -1 do tracerLines[i]:Remove() tracerLines[i] = nil end
    for i = #textDrawings, 1, -1 do textDrawings[i]:Remove() textDrawings[i] = nil end

    if not (espBoxEnabled or espTracerEnabled or espNamesEnabled or espDistanceEnabled) then return end

    local camPos = Camera.CFrame.Position
    local viewport = Camera.ViewportSize

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") then
            local head = plr.Character.Head
            local hum = plr.Character.Humanoid
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

-- Wallhack Auto-Apply Loop
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
   Title = "WIA HUB v8.0",
   Content = "Успешно загружено в стиле Rayfield!",
   Duration = 4,
   Image = 4483362458,
})

---------------------------------------------------------
-- Вкладка: Murder Mystery 2 (MM2) ULTIMATE
---------------------------------------------------------
local MM2Tab = Window:CreateTab("🔪 MM2 Pro", 4483362458)

local MM2Visuals = MM2Tab:CreateSection("ESP и Визуалы")

local RoleESPEnabled = false
MM2Tab:CreateToggle({
    Name = "Role ESP (Показывать Мардера и Шерифа)",
    CurrentValue = false,
    Flag = "MM2RoleESP",
    Callback = function(Value)
        RoleESPEnabled = Value
        if not Value then
            for _, v in pairs(Players:GetPlayers()) do
                if v.Character and v.Character:FindFirstChild("MM2RoleHighlight") then
                    v.Character.MM2RoleHighlight:Destroy()
                end
            end
        end
    end
})

local GunDropESPEnabled = false
MM2Tab:CreateToggle({
    Name = "ESP на упавший пистолет (Gun Drop)",
    CurrentValue = false,
    Flag = "MM2GunESP",
    Callback = function(Value)
        GunDropESPEnabled = Value
        if not Value and workspace:FindFirstChild("GunDrop") and workspace.GunDrop:FindFirstChild("GunHighlight") then
            workspace.GunDrop.GunHighlight:Destroy()
        end
    end
})

local MM2Combat = MM2Tab:CreateSection("Бой: Мардер (Murderer)")

local KillAuraEnabled = false
MM2Tab:CreateToggle({
    Name = "Kill Aura (Авто-удар вблизи)",
    CurrentValue = false,
    Flag = "MM2KillAura",
    Callback = function(Value) KillAuraEnabled = Value end
})

MM2Tab:CreateButton({
    Name = "Kill All (Убить всех - телепорт)",
    Callback = function()
        local char = LocalPlayer.Character
        local knife = char:FindFirstChild("Knife") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Knife"))
        
        if not knife then
            Rayfield:Notify({Title = "Ошибка", Content = "У тебя нет ножа!", Duration = 3})
            return
        end
        if knife.Parent == LocalPlayer.Backpack then char.Humanoid:EquipTool(knife) end
        
        task.spawn(function()
            for _, v in pairs(Players:GetPlayers()) do
                if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = v.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1.5)
                    task.wait(0.2)
                    if mouse1click then mouse1click() end
                    task.wait(0.3)
                end
            end
        end)
    end
})

local MM2Sheriff = MM2Tab:CreateSection("Бой: Шериф (Sheriff)")

local AutoShootEnabled = false
MM2Tab:CreateToggle({
    Name = "Авто-выстрел в Мардера (Auto Shoot)",
    CurrentValue = false,
    Flag = "MM2AutoShoot",
    Callback = function(Value) AutoShootEnabled = Value end
})

local SilentAimMM2 = false
MM2Tab:CreateToggle({
    Name = "Захват камеры на Мардера (Aim Lock)",
    CurrentValue = false,
    Flag = "MM2SilentAim",
    Callback = function(Value) SilentAimMM2 = Value end
})

local AutoGrabGun = false
MM2Tab:CreateToggle({
    Name = "Авто-подбор пистолета (Auto-Grab Gun)",
    CurrentValue = false,
    Flag = "MM2AutoGun",
    Callback = function(Value) AutoGrabGun = Value end
})

---------------------------------------------------------
-- ФОНОВЫЕ ЦИКЛЫ ДЛЯ MM2 (БЕЗ ЛАГОВ)
---------------------------------------------------------

-- 1. Роли и Подсветка (ESP)
task.spawn(function()
    while task.wait(0.5) do
        -- Role ESP
        if RoleESPEnabled then
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local char = player.Character
                    local bp = player:FindFirstChild("Backpack")
                    local hasKnife = (char and char:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife"))
                    local hasGun = (char and char:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun")) or (char and char:FindFirstChild("Revolver")) or (bp and bp:FindFirstChild("Revolver"))

                    local color = nil
                    if hasKnife then color = Color3.fromRGB(255, 0, 0)
                    elseif hasGun then color = Color3.fromRGB(0, 150, 255) end

                    if color then
                        local hl = char:FindFirstChild("MM2RoleHighlight")
                        if not hl then
                            hl = Instance.new("Highlight", char)
                            hl.Name = "MM2RoleHighlight"
                            hl.FillTransparency = 0.5
                            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        end
                        hl.FillColor = color
                        hl.OutlineColor = color
                    else
                        if char:FindFirstChild("MM2RoleHighlight") then char.MM2RoleHighlight:Destroy() end
                    end
                end
            end
        end

        -- Gun Drop ESP
        if GunDropESPEnabled then
            local gunDrop = workspace:FindFirstChild("GunDrop")
            if gunDrop and not gunDrop:FindFirstChild("GunHighlight") then
                local hl = Instance.new("Highlight", gunDrop)
                hl.Name = "GunHighlight"
                hl.FillColor = Color3.fromRGB(0, 255, 0)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end
        end
    end
end)

-- 2. Боевые функции: Kill Aura, Auto-Grab, Aim Lock, Auto Shoot
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end

    -- Поиск Мардера для Аима и Стрельбы
    local murderer = nil
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            if p.Character:FindFirstChild("Knife") or (p.Backpack and p.Backpack:FindFirstChild("Knife")) then
                murderer = p.Character
                break
            end
        end
    end

    -- Захват камеры (Aim Lock на Мардера)
    if SilentAimMM2 and murderer and murderer:FindFirstChild("Head") then
        local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")
        if gun then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, murderer.Head.Position)
        end
    end

    -- Авто-выстрел в Мардера
    if AutoShootEnabled and murderer and murderer:FindFirstChild("HumanoidRootPart") then
        local gun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")
        if gun then
            local dist = (char.HumanoidRootPart.Position - murderer.HumanoidRootPart.Position).Magnitude
            if dist < 45 then -- Стреляем, если Мардер ближе 45 стадов
                if mouse1click then mouse1click() end
            end
        end
    end

    -- Kill Aura (Автоматический удар ножом вблизи)
    if KillAuraEnabled then
        local knife = char:FindFirstChild("Knife")
        if knife then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 12 then -- Дистанция удара
                        if mouse1click then mouse1click() end
                    end
                end
            end
        end
    end
end)

-- Улучшенный Авто-подбор пистолета (Auto-Grab Gun)
task.spawn(function()
    while task.wait(0.1) do
        if AutoGrabGun then
            local gunDrop = workspace:FindFirstChild("GunDrop")
            local char = LocalPlayer.Character
            if gunDrop and char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                
                -- Метод 1: Эмуляция касания (Работает на 90% экзекьюторов)
                if firetouchinterest then
                    firetouchinterest(hrp, gunDrop, 0)
                    task.wait()
                    firetouchinterest(hrp, gunDrop, 1)
                end
                
                -- Метод 2: Притягиваем пистолет прямо к игроку
                gunDrop.CFrame = hrp.CFrame
                
                -- Метод 3: Телепорт персонажа точно на пистолет
                hrp.CFrame = gunDrop.CFrame * CFrame.new(0, 0.5, 0)
                
                task.wait(0.3) -- Небольшая пауза, чтобы сервер успел выдать пистолет
            end
        end
    end
end)