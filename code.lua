-- ================================================================= --
-- WIA HUB v8.0 Ultimate Edition :: whitewia / tordark
-- FULL GUI + AIMBOT (WITH VISUAL FOV) + PLAYER LIST + EXTENDED ESP + CFRAME SPEED
-- ================================================================= --

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

-- Safe CoreGui Parent
local CoreGui = game:GetService("CoreGui")

-- ========== VARIABLE DECLARATIONS ==========
local flightEnabled, noclipEnabled, noclipForceMode = false, false, false
local flySpeed = 50
local bodyVelocity, bodyGyro, noclipConnection, noclipForceConnection = nil, nil, nil, nil
local originalCollisions = {}

local walkSpeedEnabled, jumpPowerEnabled, cframeSpeedEnabled = false, false, false
local walkSpeedValue, jumpPowerValue, cframeSpeedValue = 16, 50, 2
local infiniteJumpEnabled, bhopEnabled, spinbotEnabled = false, false, false
local spinbotSpeed = 20

local godmodeEnabled, godmodeConnection, godmodeHealthConnection = false, false, false
local tpTool, tpEnabled = nil, false

local wallhackEnabled, highlightConnections, whHighlights = false, {}, {}
local antiAFKEnabled, antiAFKConnection = false, nil
local playerListEnabled = false
local antiVoidEnabled, antiVoidConnection = false, nil
local fullBrightEnabled, noFogEnabled = false, false
local originalBrightness, originalAmbient, originalFog = nil, nil, nil

local fovEnabled, fovValue, originalFOV = false, 90, 70
local hitboxEnabled, hitboxConnection, hitboxSize = false, nil, 5
local autoClickerEnabled, autoClickerDelay, autoClickerConnection = false, 100, nil
local triggerbotEnabled, triggerbotConnection = false, nil

local chatSpamEnabled, chatSpamMessage, chatSpamDelay, chatSpamConnection = false, "WIA HUB ON TOP", 5, nil
local antiFallEnabled, antiFallConnection = false, nil

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

-- ========== GUI CREATION ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WiaHubGUI_v8"
ScreenGui.Parent = CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 340, 0, 680)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
MainFrame.BackgroundTransparency = 0.25
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.Text = "WIA HUB v8.0"
Title.TextColor3 = Color3.fromRGB(180, 0, 255)
Title.TextScaled = true
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local Underline = Instance.new("Frame")
Underline.Size = UDim2.new(1, -20, 0, 1)
Underline.Position = UDim2.new(0, 10, 0, 30)
Underline.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
Underline.BackgroundTransparency = 0.3
Underline.Parent = MainFrame

local ScrollingFrame = Instance.new("ScrollingFrame")
ScrollingFrame.Size = UDim2.new(1, 0, 1, -35)
ScrollingFrame.Position = UDim2.new(0, 0, 0, 35)
ScrollingFrame.BackgroundTransparency = 1
ScrollingFrame.BorderSizePixel = 0
ScrollingFrame.ScrollBarThickness = 6
ScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 255)
ScrollingFrame.Parent = MainFrame

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1, 0, 0, 0)
Container.BackgroundTransparency = 1
Container.Parent = ScrollingFrame

-- DYNAMIC LAYOUT ENGINE
local currentYOffset = 5
local function getNextY(height)
    local y = currentYOffset
    currentYOffset = currentYOffset + height + 5
    return y
end

local function refreshCanvas()
    Container.Size = UDim2.new(1, 0, 0, currentYOffset + 20)
    ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, currentYOffset + 20)
end

-- STATUS BAR
local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(1, -20, 0, 25)
StatusBar.Text = "Ready"
StatusBar.TextColor3 = Color3.fromRGB(150, 150, 180)
StatusBar.TextScaled = true
StatusBar.BackgroundTransparency = 1
StatusBar.Font = Enum.Font.Gotham

local function setStatus(text, color)
    StatusBar.Text = text
    StatusBar.TextColor3 = color or Color3.fromRGB(150, 150, 180)
end

-- PLAYER LIST GUI
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

-- DRAGGABLE ENGINE
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
makeDraggable(MainFrame)
makeDraggable(PlayerListMain)

-- HIDE UI ON LCTRL
local guiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
        guiVisible = not guiVisible
        ScreenGui.Enabled = guiVisible
        if playerListEnabled then PlayerListGui.Enabled = guiVisible end
    end
end)

-- UI FACTORY FUNCTIONS
local function createTumbler(labelText, defaultState)
    local y = getNextY(30)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 300, 0, 30)
    container.Position = UDim2.new(0, 10, 0, y)
    container.BackgroundTransparency = 1
    container.Parent = Container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 30)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 50, 0, 22)
    bg.Position = UDim2.new(0, 230, 0, 4)
    bg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    bg.BorderSizePixel = 0
    bg.Parent = container

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 2, 0, 2)
    knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    knob.BorderSizePixel = 0
    knob.Parent = bg

    local state = defaultState or false

    local function updateTumbler()
        if state then
            bg.BackgroundColor3 = Color3.fromRGB(180, 0, 255)
            knob.Position = UDim2.new(0, 30, 0, 2)
            knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
        else
            bg.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            knob.Position = UDim2.new(0, 2, 0, 2)
            knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        end
    end
    updateTumbler()

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = container

    local toggleEvent = Instance.new("BindableEvent")
    btn.MouseButton1Click:Connect(function()
        state = not state
        updateTumbler()
        toggleEvent:Fire(state)
    end)

    return {
        getState = function() return state end,
        setState = function(newState)
            state = newState
            updateTumbler()
            toggleEvent:Fire(state)
        end,
        onToggle = function(callback) toggleEvent.Event:Connect(callback) end
    }
end

local function createSlider(labelText, minVal, maxVal, defaultVal, callback)
    local y = getNextY(30)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 300, 0, 30)
    container.Position = UDim2.new(0, 10, 0, y)
    container.BackgroundTransparency = 1
    container.Parent = Container

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 200, 0, 30)
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255,255,255)
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 50, 0, 22)
    textBox.Position = UDim2.new(0, 230, 0, 4)
    textBox.Text = tostring(defaultVal)
    textBox.TextColor3 = Color3.fromRGB(255,255,255)
    textBox.BackgroundColor3 = Color3.fromRGB(40,40,55)
    textBox.BorderSizePixel = 0
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.Parent = container

    textBox.FocusLost:Connect(function()
        local num = tonumber(textBox.Text)
        if num and num >= minVal and num <= maxVal then
            callback(num)
            textBox.Text = tostring(num)
        else
            textBox.Text = tostring(defaultVal)
            callback(defaultVal)
        end
    end)

    return { setValue = function(val) textBox.Text = tostring(val) end }
end

local function createButton(labelText, callback)
    local y = getNextY(30)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 280, 0, 26)
    btn.Position = UDim2.new(0, 10, 0, y)
    btn.Text = labelText
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.BackgroundColor3 = Color3.fromRGB(50, 30, 80)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 12
    btn.Parent = Container

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ========== PLAYER LIST FUNCTIONS ==========
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

            -- TP (Left Click)
            btn.MouseButton1Click:Connect(function()
                if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                    setStatus("Teleported to " .. plr.Name, Color3.fromRGB(0,255,150))
                end
            end)

            -- AIM TARGET (Right Click)
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
    -- FOV Circle Position Update
    if fovCircle then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = aimbotEnabled and fovCircleVisible
    end

    -- Aimbot Loop
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

-- ========== CREATING ALL TOGGLES & SLIDERS ==========

-- COMBAT & AIM
createTumbler("Aimbot", false).onToggle(function(st) aimbotEnabled = st setStatus(st and "Aimbot ON" or "Aimbot OFF") end)
createTumbler("Aimbot FOV Circle", true).onToggle(function(st) fovCircleVisible = st end)
createSlider("Aimbot FOV", 10, 400, 90, function(val) aimbotFOV = val end)
createSlider("Aimbot Smooth", 1, 20, 5, function(val) aimbotSmoothness = val end)
createTumbler("Triggerbot (AutoShot)", false).onToggle(function(st) triggerbotEnabled = st end)
createTumbler("Hitbox Expander", false).onToggle(function(st)
    hitboxEnabled = st
    if not st then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
            end
        end
    end
end)
createSlider("Hitbox Size", 2, 20, 5, function(val) hitboxSize = val end)

-- ESP & VISUALS
createTumbler("ESP Boxes", true).onToggle(function(st) espBoxEnabled = st end)
createTumbler("ESP Tracers", true).onToggle(function(st) espTracerEnabled = st end)
createTumbler("ESP Names", true).onToggle(function(st) espNamesEnabled = st end)
createTumbler("ESP Distance & HP", true).onToggle(function(st) espDistanceEnabled = st espHealthEnabled = st end)
createTumbler("Wallhack (Highlight)", false).onToggle(function(st)
    wallhackEnabled = st
    if not st then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("WIA_WH") then
                plr.Character.WIA_WH:Destroy()
            end
        end
    end
end)

-- MOVEMENT & FLIGHT
createTumbler("Flight", false).onToggle(function(st)
    flightEnabled = st
    if st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        bodyVelocity = Instance.new("BodyVelocity", LocalPlayer.Character.HumanoidRootPart)
        bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        bodyGyro = Instance.new("BodyGyro", LocalPlayer.Character.HumanoidRootPart)
        bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    else
        if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
        if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    end
end)
createSlider("Fly Speed", 10, 300, 50, function(val) flySpeed = val end)

createTumbler("Noclip", false).onToggle(function(st) noclipEnabled = st end)
createTumbler("CFrame Speed (Bypass)", false).onToggle(function(st) cframeSpeedEnabled = st end)
createSlider("CFrame Speed Multiplier", 1, 10, 2, function(val) cframeSpeedValue = val end)

createSlider("Walk Speed", 16, 200, 16, function(val)
    walkSpeedValue = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end)

createSlider("Jump Power", 50, 200, 50, function(val)
    jumpPowerValue = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = val
    end
end)

createTumbler("Infinite Jump", false).onToggle(function(st) infiniteJumpEnabled = st end)
createTumbler("Bhop", false).onToggle(function(st) bhopEnabled = st end)
createTumbler("Spinbot", false).onToggle(function(st) spinbotEnabled = st end)
createSlider("Spinbot Speed", 5, 50, 20, function(val) spinbotSpeed = val end)

-- PLAYER UTILITIES
createTumbler("Godmode", false).onToggle(function(st)
    godmodeEnabled = st
    if st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
    end
end)
createTumbler("Anti-Void", false).onToggle(function(st) antiVoidEnabled = st end)
createTumbler("Anti-Fall Damage", false).onToggle(function(st) antiFallEnabled = st end)
createTumbler("Anti-AFK", false).onToggle(function(st) antiAFKEnabled = st end)
createTumbler("Player List GUI", false).onToggle(function(st)
    playerListEnabled = st
    PlayerListGui.Enabled = st
    if st then updatePlayerList() end
end)

-- WORLD & RENDER
createTumbler("FullBright", false).onToggle(function(st)
    fullBrightEnabled = st
    if st then
        originalBrightness = Lighting.Brightness
        originalAmbient = Lighting.Ambient
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        if originalBrightness then Lighting.Brightness = originalBrightness end
        if originalAmbient then Lighting.Ambient = originalAmbient end
    end
end)

createTumbler("No Fog (FPS Boost)", false).onToggle(function(st)
    noFogEnabled = st
    if st then
        originalFog = Lighting.FogEnd
        Lighting.FogEnd = 1e6
    else
        if originalFog then Lighting.FogEnd = originalFog end
    end
end)

createSlider("Camera FOV", 50, 120, 70, function(val) Camera.FieldOfView = val end)

-- AUTOMATION
createTumbler("AutoClicker", false).onToggle(function(st) autoClickerEnabled = st end)
createSlider("Click Delay (ms)", 10, 1000, 100, function(val) autoClickerDelay = val end)
createTumbler("Chat Spam", false).onToggle(function(st) chatSpamEnabled = st end)

-- REJOIN & SERVER HOP BUTTONS
createButton("Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

createButton("Server Hop", function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
    for _, s in pairs(servers) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            break
        end
    end
end)

-- Attach status bar at bottom
local sY = getNextY(25)
StatusBar.Position = UDim2.new(0, 10, 0, sY)
StatusBar.Parent = Container

refreshCanvas()

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

-- Spinbot Loop
RunService.RenderStepped:Connect(function()
    if spinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
    end
end)

-- Noclip & Hitbox Expander & Godmode Loop
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

-- ========== ADVANCED DRAWING ESP ENGINE ==========
local PURPLE = Color3.fromRGB(180, 0, 255)

RunService.RenderStepped:Connect(function()
    -- Clear drawings
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

                -- ESP Text Info (Names, HP, Distance)
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
                    textTextDrawings = textDrawings
                    textDrawings[#textDrawings + 1] = text
                end
            end
        end
    end
end)

-- Wallhack Auto-Apply
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

setStatus("WIA HUB v8 Loaded!", Color3.fromRGB(0, 255, 150))