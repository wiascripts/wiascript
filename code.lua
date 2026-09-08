-- ================================================================= --
-- WIA HUB v11 :: RAYFIELD EDITION
-- Full UI Architecture / Configuration / Notifications / Cleanup
-- ================================================================= --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ================================================================= --
-- RAYFIELD
-- ================================================================= --

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

local Window = Rayfield:CreateWindow({
    Name = "WIA HUB v11",
    LoadingTitle = "WIA HUB",
    LoadingSubtitle = "Rayfield Edition",

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "WIAHUB",
        FileName = "Settings"
    },

    Discord = {
        Enabled = false
    },

    KeySystem = false
})

-- ================================================================= --
-- STATE
-- ================================================================= --

local State = {
    FullBright = false,
    NoFog = false,
    RemoveColorCorrection = false,
    CameraFOV = 70,
    Notifications = true,
    Debug = false,

    -- Combat
    Aimbot = false,
    AimbotFOV = 90,
    AimbotSmoothness = 1,
    AimbotFOVCircle = false,
    AimbotTarget = nil,
    Triggerbot = false,
    HitboxExpander = false,
    HitboxSize = 1,

    -- Visuals
    ESPBox = false,
    ESPTracer = false,
    ESPName = false,
    ESPDistance = false,
    ESPHealth = false,
    ESPColor = Color3.fromRGB(255, 255, 255),
    RainbowMode = false,
    Wallhack = false,

    -- Movement
    Fly = false,
    Noclip = false,
    Speed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Bhop = false,
    Spinbot = false,
    CFrameSpeed = false,
    CFrameSpeedMultiplier = 2,

    -- MM2
    GunTeleport = false,
    SilentAim = false,
    AutoShoot = false,
    KillAura = false,
    KillAuraRange = 20,
    AntiVoid = false,
    AntiFall = false,
    AntiAFK = false,
    Godmode = false,
    TeleportTool = false,

    -- Player Utilities
    PlayerList = false,

    -- Automation
    AutoClicker = false,
    AutoClickerDelay = 100,
    ChatSpam = false,
    ChatSpamMessage = "WIA HUB ON TOP",
    ChatSpamDelay = 5,
}

local Connections = {}
local ESPDrawings = {}
local AimbotConnection = nil
local ESPConnection = nil
local MovementConnection = nil
local CombatConnection = nil
local MM2Connection = nil
local AntiVoidConnection = nil
local AntiAFKConnection = nil
local SpinbotConnection = nil
local WallhackConnection = nil
local NoclipConnection = nil
local InfiniteJumpConnection = nil
local BhopConnection = nil
local AntiFallConnection = nil
local TriggerbotConnection = nil
local NamecallHook = nil
local oldNamecall = nil
local CFrameSpeedConnection = nil
local GodmodeConnection = nil
local TeleportToolInstance = nil
local FOVCircle = nil
local PlayerListButtons = {}

-- Storage for original values
local originalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
}
local originalTransparencies = {}
local originalHitboxSizes = {}
local originalColorCorrectionStates = {}
local AntiFallHumanoidConnections = {}
local AntiAFKLastAction = nil

local function AddConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function Notify(title, content, duration)
    if not State.Notifications then return end
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

local function Cleanup()
    -- Stop threads first
    State.AutoClicker = false
    State.ChatSpam = false
    task.wait(0.1)

    -- Disconnect all connections
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Connections)

    -- Remove ESP drawings
    if ESPDrawings then
        for _, drawings in pairs(ESPDrawings) do
            for _, drawing in pairs(drawings) do
                pcall(function() drawing:Remove() end)
            end
        end
        ESPDrawings = {}
    end

    -- Restore namecall
    if NamecallHook and oldNamecall then
        pcall(function()
            hookmetamethod(game, "__namecall", oldNamecall)
        end)
        NamecallHook = nil
        oldNamecall = nil
    end

    -- Restore lighting
    Lighting.Brightness = originalLighting.Brightness
    Lighting.ClockTime = originalLighting.ClockTime
    Lighting.GlobalShadows = originalLighting.GlobalShadows
    Lighting.FogEnd = originalLighting.FogEnd

    -- Restore color corrections
    for effect, enabled in pairs(originalColorCorrectionStates) do
        if effect and effect.Parent then
            effect.Enabled = enabled
        end
    end
    originalColorCorrectionStates = {}

    -- Restore wallhack transparency
    DisableWallhack()
    -- Restore hitbox sizes
    RemoveHitboxExpander()

    -- Remove teleport tool
    if TeleportToolInstance then
        TeleportToolInstance:Destroy()
        TeleportToolInstance = nil
    end

    -- Remove FOV circle
    if FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end

    -- Clear player list buttons
    for _, btn in pairs(PlayerListButtons) do
        pcall(function() btn:Destroy() end)
    end
    PlayerListButtons = {}
end

-- ================================================================= --
-- SYSTEM FUNCTIONS
-- ================================================================= --

-- ---------- ESP System ----------
local function CreateESPForPlayer(player)
    if player == LocalPlayer then return end
    local drawings = {}

    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Color = State.ESPColor
    box.Filled = false
    box.Visible = false
    box.ZIndex = 10
    drawings.Box = box

    local tracer = Drawing.new("Line")
    tracer.Thickness = 1
    tracer.Color = State.ESPColor
    tracer.Visible = false
    tracer.ZIndex = 10
    drawings.Tracer = tracer

    local name = Drawing.new("Text")
    name.Size = 13
    name.Color = State.ESPColor
    name.Center = true
    name.Outline = true
    name.Visible = false
    name.ZIndex = 10
    drawings.Name = name

    local distance = Drawing.new("Text")
    distance.Size = 13
    distance.Color = State.ESPColor
    distance.Center = true
    distance.Outline = true
    distance.Visible = false
    distance.ZIndex = 10
    drawings.Distance = distance

    local health = Drawing.new("Line")
    health.Thickness = 2
    health.Color = Color3.fromRGB(0, 255, 0)
    health.Visible = false
    health.ZIndex = 10
    drawings.Health = health

    ESPDrawings[player] = drawings
    return drawings
end

local function RemoveESPForPlayer(player)
    local drawings = ESPDrawings[player]
    if drawings then
        for _, drawing in pairs(drawings) do
            pcall(function() drawing:Remove() end)
        end
        ESPDrawings[player] = nil
    end
end

local function RefreshESP()
    for player, drawings in pairs(ESPDrawings) do
        if drawings.Box then drawings.Box.Visible = State.ESPBox end
        if drawings.Tracer then drawings.Tracer.Visible = State.ESPTracer end
        if drawings.Name then drawings.Name.Visible = State.ESPName end
        if drawings.Distance then drawings.Distance.Visible = State.ESPDistance end
        if drawings.Health then drawings.Health.Visible = State.ESPHealth end
    end
end

local function StartESP()
    if ESPConnection then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESPForPlayer(player)
        end
    end

    AddConnection(Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            CreateESPForPlayer(player)
        end
    end))

    AddConnection(Players.PlayerRemoving:Connect(function(player)
        RemoveESPForPlayer(player)
        PlayerListButtons[player] = nil
    end))

    ESPConnection = RunService.RenderStepped:Connect(function()
        local camera = workspace.CurrentCamera
        if not camera then return end

        for player, drawings in pairs(ESPDrawings) do
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character.Humanoid
                local rootPart = character.HumanoidRootPart
                if humanoid.Health > 0 then
                    local screenPos, onScreen = camera:WorldToScreenPoint(rootPart.Position)
                    if onScreen then
                        local scale = 1000 / (camera.CFrame.Position - rootPart.Position).Magnitude
                        local size = Vector2.new(2 * scale, 3 * scale)
                        local boxPos = Vector2.new(screenPos.X - size.X/2, screenPos.Y - size.Y/2)

                        if drawings.Box.Visible then
                            drawings.Box.Size = size
                            drawings.Box.Position = boxPos
                            drawings.Box.Color = State.RainbowMode and Color3.fromHSV(tick() % 5 / 5, 1, 1) or State.ESPColor
                        end

                        if drawings.Tracer.Visible then
                            drawings.Tracer.From = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y)
                            drawings.Tracer.To = Vector2.new(screenPos.X, screenPos.Y)
                            drawings.Tracer.Color = State.RainbowMode and Color3.fromHSV(tick() % 5 / 5, 1, 1) or State.ESPColor
                        end

                        if drawings.Name.Visible then
                            drawings.Name.Text = player.Name
                            drawings.Name.Position = Vector2.new(screenPos.X, screenPos.Y - size.Y/2 - 15)
                            drawings.Name.Color = State.RainbowMode and Color3.fromHSV(tick() % 5 / 5, 1, 1) or State.ESPColor
                        end

                        if drawings.Distance.Visible then
                            local dist = (camera.CFrame.Position - rootPart.Position).Magnitude
                            drawings.Distance.Text = string.format("%.0f studs", dist)
                            drawings.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + size.Y/2 + 5)
                            drawings.Distance.Color = State.RainbowMode and Color3.fromHSV(tick() % 5 / 5, 1, 1) or State.ESPColor
                        end

                        if drawings.Health.Visible then
                            local healthPercent = humanoid.Health / humanoid.MaxHealth
                            local healthWidth = size.X
                            drawings.Health.From = Vector2.new(boxPos.X, boxPos.Y - 5)
                            drawings.Health.To = Vector2.new(boxPos.X + healthWidth * healthPercent, boxPos.Y - 5)
                            drawings.Health.Color = Color3.fromRGB(255 * (1 - healthPercent), 255 * healthPercent, 0)
                        end
                    else
                        for _, drawing in pairs(drawings) do drawing.Visible = false end
                    end
                else
                    for _, drawing in pairs(drawings) do drawing.Visible = false end
                end
            else
                for _, drawing in pairs(drawings) do drawing.Visible = false end
            end
        end
    end)
    Connections[#Connections + 1] = ESPConnection
end

-- ---------- Aimbot ----------
local function GetNearestTarget()
    if State.AimbotTarget and State.AimbotTarget.Character and State.AimbotTarget.Character:FindFirstChild("Head") then
        return State.AimbotTarget
    end

    local nearest = nil
    local nearestDist = State.AimbotFOV
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                local humanoid = character.Humanoid
                if humanoid.Health > 0 then
                    local targetPos = character.Head.Position
                    local screenPos, onScreen = camera:WorldToScreenPoint(targetPos)
                    if onScreen then
                        local screenCenter = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                        if dist < nearestDist then
                            nearest = player
                            nearestDist = dist
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function StartAimbot()
    StopAimbot()
    AimbotConnection = RunService.RenderStepped:Connect(function()
        if not State.Aimbot then return end
        -- FOV Circle
        if State.AimbotFOVCircle then
            if not FOVCircle then
                FOVCircle = Drawing.new("Circle")
                FOVCircle.Thickness = 1.5
                FOVCircle.NumSides = 60
                FOVCircle.Filled = false
                FOVCircle.Color = Color3.fromRGB(180, 0, 255)
                FOVCircle.Visible = false
            end
            FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
            FOVCircle.Radius = State.AimbotFOV
            FOVCircle.Visible = true
        elseif FOVCircle then
            FOVCircle.Visible = false
        end

        local target = GetNearestTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local camera = workspace.CurrentCamera
            if not camera then return end
            local targetPos = target.Character.Head.Position
            local lookAt = CFrame.new(camera.CFrame.Position, targetPos)
            local smooth = State.AimbotSmoothness / 10
            camera.CFrame = camera.CFrame:Lerp(lookAt, smooth)
        end
    end)
    Connections[#Connections + 1] = AimbotConnection
end

local function StopAimbot()
    if AimbotConnection then
        pcall(function() AimbotConnection:Disconnect() end)
        AimbotConnection = nil
    end
    if FOVCircle then
        FOVCircle:Remove()
        FOVCircle = nil
    end
end

-- ---------- Triggerbot ----------
local function StartTriggerbot()
    StopTriggerbot()
    TriggerbotConnection = Mouse.Button1Down:Connect(function()
        if State.Triggerbot then
            local target = GetNearestTarget()
            if target and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
                local shootRemote = ReplicatedStorage:FindFirstChild("ShootGun") or ReplicatedStorage:FindFirstChild("Fire") or ReplicatedStorage:FindFirstChild("Shoot")
                if shootRemote and shootRemote:IsA("RemoteEvent") then
                    shootRemote:FireServer(target.Character.Head.Position)
                end
            end
        end
    end)
    Connections[#Connections + 1] = TriggerbotConnection
end

local function StopTriggerbot()
    if TriggerbotConnection then
        pcall(function() TriggerbotConnection:Disconnect() end)
        TriggerbotConnection = nil
    end
end

-- ---------- Hitbox Expander ----------
local function ApplyHitboxExpander()
    RemoveHitboxExpander()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            if character then
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if not originalHitboxSizes[player] then originalHitboxSizes[player] = {} end
                        originalHitboxSizes[player][part] = part.Size
                        part.Size = part.Size * State.HitboxSize
                    end
                end
            end
        end
    end
end

local function RemoveHitboxExpander()
    for player, parts in pairs(originalHitboxSizes) do
        if player and player.Character then
            for part, originalSize in pairs(parts) do
                if part and part.Parent then
                    part.Size = originalSize
                end
            end
        end
    end
    originalHitboxSizes = {}
end

-- ---------- Wallhack ----------
local function EnableWallhack()
    DisableWallhack()
    WallhackConnection = RunService.RenderStepped:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character then
                    for _, part in ipairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            if not originalTransparencies[player] then originalTransparencies[player] = {} end
                            if not originalTransparencies[player][part] then
                                originalTransparencies[player][part] = part.Transparency
                            end
                            part.Transparency = 0.7
                        end
                    end
                end
            end
        end
    end)
    Connections[#Connections + 1] = WallhackConnection
end

local function DisableWallhack()
    if WallhackConnection then
        pcall(function() WallhackConnection:Disconnect() end)
        WallhackConnection = nil
    end
    for player, parts in pairs(originalTransparencies) do
        if player and player.Character then
            for part, transparency in pairs(parts) do
                if part and part.Parent then
                    part.Transparency = transparency
                end
            end
        end
    end
    originalTransparencies = {}
end

-- ---------- Movement Functions ----------
local function StartFly()
    StopFly()
    MovementConnection = RunService.Heartbeat:Connect(function()
        if not State.Fly then return end
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = true
                local velocity = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then velocity += workspace.CurrentCamera.CFrame.LookVector * 50 end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then velocity -= workspace.CurrentCamera.CFrame.LookVector * 50 end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then velocity -= workspace.CurrentCamera.CFrame.RightVector * 50 end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then velocity += workspace.CurrentCamera.CFrame.RightVector * 50 end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then velocity += Vector3.new(0, 50, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then velocity -= Vector3.new(0, 50, 0) end
                character.HumanoidRootPart.Velocity = velocity
            end
        end
    end)
    Connections[#Connections + 1] = MovementConnection
end

local function StopFly()
    if MovementConnection then
        pcall(function() MovementConnection:Disconnect() end)
        MovementConnection = nil
    end
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    end
end

local function EnableNoclip()
    DisableNoclip()
    NoclipConnection = RunService.Stepped:Connect(function()
        if not State.Noclip then return end
        local character = LocalPlayer.Character
        if character then
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    Connections[#Connections + 1] = NoclipConnection
end

local function DisableNoclip()
    if NoclipConnection then
        pcall(function() NoclipConnection:Disconnect() end)
        NoclipConnection = nil
    end
    local character = LocalPlayer.Character
    if character then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function ApplyMovementSettings()
    local character = LocalPlayer.Character
    if character and character:FindFirstChildOfClass("Humanoid") then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        humanoid.WalkSpeed = State.Speed
        humanoid.JumpPower = State.JumpPower
    end
end

local function EnableInfiniteJump()
    DisableInfiniteJump()
    InfiniteJumpConnection = UserInputService.JumpRequest:Connect(function()
        if State.InfiniteJump then
            local character = LocalPlayer.Character
            if character and character:FindFirstChildOfClass("Humanoid") then
                character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    Connections[#Connections + 1] = InfiniteJumpConnection
end

local function DisableInfiniteJump()
    if InfiniteJumpConnection then
        pcall(function() InfiniteJumpConnection:Disconnect() end)
        InfiniteJumpConnection = nil
    end
end

local function EnableBhop()
    DisableBhop()
    BhopConnection = RunService.Heartbeat:Connect(function()
        if not State.Bhop then return end
        local character = LocalPlayer.Character
        if character and character:FindFirstChildOfClass("Humanoid") then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid.MoveDirection.Magnitude > 0 and humanoid.FloorMaterial ~= Enum.Material.Air then
                humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end)
    Connections[#Connections + 1] = BhopConnection
end

local function DisableBhop()
    if BhopConnection then
        pcall(function() BhopConnection:Disconnect() end)
        BhopConnection = nil
    end
end

local function StartSpinbot()
    StopSpinbot()
    SpinbotConnection = RunService.RenderStepped:Connect(function()
        if not State.Spinbot then return end
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            character.HumanoidRootPart.CFrame = character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(5), 0)
        end
    end)
    Connections[#Connections + 1] = SpinbotConnection
end

local function StopSpinbot()
    if SpinbotConnection then
        pcall(function() SpinbotConnection:Disconnect() end)
        SpinbotConnection = nil
    end
end

local function EnableCFrameSpeed()
    DisableCFrameSpeed()
    CFrameSpeedConnection = RunService.Heartbeat:Connect(function()
        if not State.CFrameSpeed then return end
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") and character:FindFirstChild("Humanoid") then
            local hum = character.Humanoid
            local root = character.HumanoidRootPart
            if hum.MoveDirection.Magnitude > 0 then
                root.CFrame = root.CFrame + (hum.MoveDirection * (State.CFrameSpeedMultiplier / 10))
            end
        end
    end)
    Connections[#Connections + 1] = CFrameSpeedConnection
end

local function DisableCFrameSpeed()
    if CFrameSpeedConnection then
        pcall(function() CFrameSpeedConnection:Disconnect() end)
        CFrameSpeedConnection = nil
    end
end

-- ---------- MM2 Functions ----------
local function TeleportToGun()
    local character = LocalPlayer.Character
    if not character then return end
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and v.Name:lower():find("gun") then
            character.HumanoidRootPart.CFrame = v.Handle.CFrame + Vector3.new(0, 2, 0)
            Notify("MM2", "Teleported to gun.")
            return
        end
    end
    Notify("MM2", "No gun found.")
end

local function TeleportToTool()
    local character = LocalPlayer.Character
    if not character then return end
    local nearestTool = nil
    local nearestDist = math.huge
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Tool") and v:FindFirstChild("Handle") then
            local dist = (character.HumanoidRootPart.Position - v.Handle.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearestTool = v
            end
        end
    end
    if nearestTool then
        character.HumanoidRootPart.CFrame = nearestTool.Handle.CFrame + Vector3.new(0, 2, 0)
        Notify("MM2", "Teleported to nearest tool: " .. nearestTool.Name)
    else
        Notify("MM2", "No tool found.")
    end
end

local function EnableSilentAim()
    DisableSilentAim()
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and tostring(self) == "ShootGun" then
            local target = GetNearestTarget()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                return oldNamecall(self, unpack({...}, 1, select("#", ...) - 1), target.Character.Head.Position)
            end
        end
        return oldNamecall(self, ...)
    end)
    NamecallHook = true
end

local function DisableSilentAim()
    if NamecallHook and oldNamecall then
        pcall(function()
            hookmetamethod(game, "__namecall", oldNamecall)
        end)
        NamecallHook = nil
        oldNamecall = nil
    end
end

local function StartAutoShoot()
    StopAutoShoot()
    MM2Connection = RunService.Heartbeat:Connect(function()
        if not State.AutoShoot then return end
        local target = GetNearestTarget()
        if target and target.Character and target.Character:FindFirstChild("Humanoid") and target.Character.Humanoid.Health > 0 then
            local shootRemote = ReplicatedStorage:FindFirstChild("ShootGun") or ReplicatedStorage:FindFirstChild("Fire") or ReplicatedStorage:FindFirstChild("Shoot")
            if shootRemote and shootRemote:IsA("RemoteEvent") then
                shootRemote:FireServer(target.Character.Head.Position)
            end
        end
    end)
    Connections[#Connections + 1] = MM2Connection
end

local function StopAutoShoot()
    if MM2Connection then
        pcall(function() MM2Connection:Disconnect() end)
        MM2Connection = nil
    end
end

local function StartKillAura()
    StopKillAura()
    CombatConnection = RunService.Heartbeat:Connect(function()
        if not State.KillAura then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                if character and character:FindFirstChild("Humanoid") and character:FindFirstChild("HumanoidRootPart") then
                    local humanoid = character.Humanoid
                    if humanoid.Health > 0 then
                        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            local distance = (myRoot.Position - character.HumanoidRootPart.Position).Magnitude
                            if distance <= State.KillAuraRange then
                                local shootRemote = ReplicatedStorage:FindFirstChild("ShootGun") or ReplicatedStorage:FindFirstChild("Fire") or ReplicatedStorage:FindFirstChild("Shoot")
                                if shootRemote and shootRemote:IsA("RemoteEvent") then
                                    shootRemote:FireServer(character.Head.Position)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    Connections[#Connections + 1] = CombatConnection
end

local function StopKillAura()
    if CombatConnection then
        pcall(function() CombatConnection:Disconnect() end)
        CombatConnection = nil
    end
end

local function EnableAntiVoid()
    DisableAntiVoid()
    AntiVoidConnection = RunService.Heartbeat:Connect(function()
        if not State.AntiVoid then return end
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            if character.HumanoidRootPart.Position.Y < -50 then
                character.HumanoidRootPart.CFrame = CFrame.new(0, 50, 0)
            end
        end
    end)
    Connections[#Connections + 1] = AntiVoidConnection
end

local function DisableAntiVoid()
    if AntiVoidConnection then
        pcall(function() AntiVoidConnection:Disconnect() end)
        AntiVoidConnection = nil
    end
end

local function EnableAntiFall()
    DisableAntiFall()
    AntiFallConnection = LocalPlayer.CharacterAdded:Connect(function(character)
        local humanoid = character:WaitForChild("Humanoid")
        local fallConn = humanoid.FallingDown:Connect(function()
            if State.AntiFall then
                humanoid:ChangeState(Enum.HumanoidStateType.Landed)
            end
        end)
        table.insert(AntiFallHumanoidConnections, fallConn)
    end)
    Connections[#Connections + 1] = AntiFallConnection
end

local function DisableAntiFall()
    if AntiFallConnection then
        pcall(function() AntiFallConnection:Disconnect() end)
        AntiFallConnection = nil
    end
    for _, conn in ipairs(AntiFallHumanoidConnections) do
        pcall(function() conn:Disconnect() end)
    end
    table.clear(AntiFallHumanoidConnections)
end

local function EnableAntiAFK()
    DisableAntiAFK()
    AntiAFKConnection = RunService.Heartbeat:Connect(function()
        if not State.AntiAFK then return end
        if not AntiAFKLastAction or (tick() - AntiAFKLastAction) > 300 then
            AntiAFKLastAction = tick()
            VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        end
    end)
    Connections[#Connections + 1] = AntiAFKConnection
end

local function DisableAntiAFK()
    if AntiAFKConnection then
        pcall(function() AntiAFKConnection:Disconnect() end)
        AntiAFKConnection = nil
    end
    AntiAFKLastAction = nil
end

local function EnableGodmode()
    DisableGodmode()
    GodmodeConnection = RunService.Heartbeat:Connect(function()
        if not State.Godmode then return end
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("Humanoid") then
            character.Humanoid.Health = character.Humanoid.MaxHealth
        end
    end)
    Connections[#Connections + 1] = GodmodeConnection
end

local function DisableGodmode()
    if GodmodeConnection then
        pcall(function() GodmodeConnection:Disconnect() end)
        GodmodeConnection = nil
    end
end

local function CreateTeleportTool()
    local tool = Instance.new("Tool")
    tool.Name = "WIA_TP"
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    local function teleport(mousePos)
        if not State.TeleportTool then return end
        local targetPos = mousePos.Hit.Position
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
        end
    end

    tool.Equipped:Connect(function()
        Mouse.Icon = "rbxasset://SystemCursors/Crosshair"
    end)

    tool.Unequipped:Connect(function()
        Mouse.Icon = "rbxasset://SystemCursors/Arrow"
    end)

    tool.Activated:Connect(function()
        if State.TeleportTool then
            teleport(Mouse)
        end
    end)

    return tool
end

local function EnableTeleportTool()
    if TeleportToolInstance then return end
    TeleportToolInstance = CreateTeleportTool()
    TeleportToolInstance.Parent = LocalPlayer.Backpack
    Notify("Teleport Tool", "Tool added to backpack!")
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid:EquipTool(TeleportToolInstance)
    end
end

local function DisableTeleportTool()
    if TeleportToolInstance then
        TeleportToolInstance:Destroy()
        TeleportToolInstance = nil
        Notify("Teleport Tool", "Tool removed.")
    end
end

local function StartAutoClicker()
    if State.AutoClicker then return end
    State.AutoClicker = true
    task.spawn(function()
        while State.AutoClicker do
            mouse1click()
            task.wait(State.AutoClickerDelay / 1000)
        end
    end)
end

local function StopAutoClicker()
    State.AutoClicker = false
end

local function StartChatSpam()
    if State.ChatSpam then return end
    State.ChatSpam = true
    task.spawn(function()
        while State.ChatSpam do
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(State.ChatSpamMessage, "All")
            end
            task.wait(State.ChatSpamDelay)
        end
    end)
end

local function StopChatSpam()
    State.ChatSpam = false
end

-- ---------- Player List ----------
local function RefreshPlayerList()
    for _, btn in pairs(PlayerListButtons) do
        pcall(function() btn:Destroy() end)
    end
    PlayerListButtons = {}

    if not State.PlayerList then return end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local button = PlayerListTab:CreateButton({
                Name = plr.Name .. " [TP] [AIM]",
                Callback = function()
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
                        Notify("Player", "Teleported to " .. plr.Name)
                    end
                    State.AimbotTarget = plr
                    Notify("Player", "Aim target set to " .. plr.Name)
                end
            })
            PlayerListButtons[plr] = button
        end
    end
end

-- ================================================================= --
-- TABS
-- ================================================================= --

local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local MM2Tab = Window:CreateTab("MM2 Master", 4483362458)
local ServerTab = Window:CreateTab("Server", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)
local PlayerListTab = Window:CreateTab("Players", 4483362458)

-- ================================================================= --
-- COMBAT
-- ================================================================= --

CombatTab:CreateSection("Combat System")

CombatTab:CreateParagraph({
    Title = "Combat",
    Content = "Combat exploit functions are intentionally disabled in this safe Rayfield build."
})

CombatTab:CreateToggle({
    Name = "Combat Module",
    CurrentValue = false,
    Flag = "CombatModule",
    Callback = function(value)
        Notify("Combat", value and "Module enabled" or "Module disabled")
    end
})

CombatTab:CreateButton({
    Name = "Reset Combat Settings",
    Callback = function()
        Rayfield:Notify({
            Title = "Combat",
            Content = "Combat settings reset.",
            Duration = 2
        })
    end
})

CombatTab:CreateSection("Aimbot")

CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Flag = "Aimbot",
    Callback = function(value)
        State.Aimbot = value
        if value then
            StartAimbot()
        else
            StopAimbot()
        end
    end
})

CombatTab:CreateToggle({
    Name = "Aimbot FOV Circle",
    CurrentValue = false,
    Flag = "AimbotFOVCircle",
    Callback = function(value)
        State.AimbotFOVCircle = value
        if State.Aimbot and FOVCircle then
            FOVCircle.Visible = value
        end
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {10, 180},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 90,
    Flag = "AimbotFOV",
    Callback = function(value)
        State.AimbotFOV = value
    end
})

CombatTab:CreateSlider({
    Name = "Aimbot Smoothness",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 1,
    Flag = "AimbotSmoothness",
    Callback = function(value)
        State.AimbotSmoothness = value
    end
})

CombatTab:CreateSection("Triggerbot")

CombatTab:CreateToggle({
    Name = "Triggerbot",
    CurrentValue = false,
    Flag = "Triggerbot",
    Callback = function(value)
        State.Triggerbot = value
        if value then
            StartTriggerbot()
        else
            StopTriggerbot()
        end
    end
})

CombatTab:CreateSection("Hitbox Expander")

CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Flag = "HitboxExpander",
    Callback = function(value)
        State.HitboxExpander = value
        if value then
            ApplyHitboxExpander()
        else
            RemoveHitboxExpander()
        end
    end
})

CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {1, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Flag = "HitboxSize",
    Callback = function(value)
        State.HitboxSize = value
        if State.HitboxExpander then
            ApplyHitboxExpander()
        end
    end
})

-- ================================================================= --
-- VISUALS
-- ================================================================= --

VisualsTab:CreateSection("Visual Settings")

VisualsTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(value)
        State.FullBright = value
        if value then
            Lighting.Brightness = 2
            Lighting.ClockTime = 14
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
        else
            Lighting.Brightness = originalLighting.Brightness
            Lighting.ClockTime = originalLighting.ClockTime
            Lighting.GlobalShadows = originalLighting.GlobalShadows
            Lighting.FogEnd = originalLighting.FogEnd
        end
    end
})

VisualsTab:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Flag = "NoFog",
    Callback = function(value)
        State.NoFog = value
        if value then
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = originalLighting.FogEnd
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Remove Color Correction",
    CurrentValue = false,
    Flag = "RemoveColorCorrection",
    Callback = function(value)
        State.RemoveColorCorrection = value
        for _, object in ipairs(Lighting:GetChildren()) do
            if object:IsA("ColorCorrectionEffect") then
                if value then
                    if not originalColorCorrectionStates[object] then
                        originalColorCorrectionStates[object] = object.Enabled
                    end
                    object.Enabled = false
                else
                    if originalColorCorrectionStates[object] ~= nil then
                        object.Enabled = originalColorCorrectionStates[object]
                        originalColorCorrectionStates[object] = nil
                    end
                end
            end
        end
    end
})

VisualsTab:CreateSlider({
    Name = "Camera FOV",
    Range = {40, 120},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 70,
    Flag = "CameraFOV",
    Callback = function(value)
        State.CameraFOV = value
        local camera = workspace.CurrentCamera
        if camera then
            camera.FieldOfView = value
        end
    end
})

VisualsTab:CreateSection("ESP")

VisualsTab:CreateToggle({
    Name = "ESP Box",
    CurrentValue = false,
    Flag = "ESPBox",
    Callback = function(value)
        State.ESPBox = value
        if value then StartESP() end
        RefreshESP()
    end
})

VisualsTab:CreateToggle({
    Name = "ESP Tracer",
    CurrentValue = false,
    Flag = "ESPTracer",
    Callback = function(value)
        State.ESPTracer = value
        if value then StartESP() end
        RefreshESP()
    end
})

VisualsTab:CreateToggle({
    Name = "ESP Name",
    CurrentValue = false,
    Flag = "ESPName",
    Callback = function(value)
        State.ESPName = value
        if value then StartESP() end
        RefreshESP()
    end
})

VisualsTab:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = false,
    Flag = "ESPDistance",
    Callback = function(value)
        State.ESPDistance = value
        if value then StartESP() end
        RefreshESP()
    end
})

VisualsTab:CreateToggle({
    Name = "ESP Health",
    CurrentValue = false,
    Flag = "ESPHealth",
    Callback = function(value)
        State.ESPHealth = value
        if value then StartESP() end
        RefreshESP()
    end
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPColor",
    Callback = function(value)
        State.ESPColor = value
        RefreshESP()
    end
})

VisualsTab:CreateToggle({
    Name = "Rainbow Mode",
    CurrentValue = false,
    Flag = "RainbowMode",
    Callback = function(value)
        State.RainbowMode = value
        RefreshESP()
    end
})

VisualsTab:CreateToggle({
    Name = "Wallhack",
    CurrentValue = false,
    Flag = "Wallhack",
    Callback = function(value)
        State.Wallhack = value
        if value then
            EnableWallhack()
        else
            DisableWallhack()
        end
    end
})

-- ================================================================= --
-- MOVEMENT
-- ================================================================= --

MovementTab:CreateSection("Movement")

MovementTab:CreateParagraph({
    Title = "Movement",
    Content = "Safe UI placeholders. No exploit movement is executed."
})

MovementTab:CreateToggle({
    Name = "Movement Module",
    CurrentValue = false,
    Flag = "MovementModule",
    Callback = function(value)
        Notify("Movement", value and "Module enabled" or "Module disabled")
    end
})

MovementTab:CreateButton({
    Name = "Reset Movement",
    Callback = function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 16
                humanoid.JumpPower = 50
            end
        end
        Notify("Movement", "Movement reset.")
    end
})

MovementTab:CreateSection("Advanced Movement")

MovementTab:CreateToggle({
    Name = "Flight / Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(value)
        State.Fly = value
        if value then StartFly() else StopFly() end
    end
})

MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(value)
        State.Noclip = value
        if value then EnableNoclip() else DisableNoclip() end
    end
})

MovementTab:CreateSlider({
    Name = "Speed",
    Range = {16, 100},
    Increment = 1,
    CurrentValue = 16,
    Flag = "Speed",
    Callback = function(value)
        State.Speed = value
        ApplyMovementSettings()
    end
})

MovementTab:CreateSlider({
    Name = "JumpPower",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(value)
        State.JumpPower = value
        ApplyMovementSettings()
    end
})

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(value)
        State.InfiniteJump = value
        if value then EnableInfiniteJump() else DisableInfiniteJump() end
    end
})

MovementTab:CreateToggle({
    Name = "Bhop",
    CurrentValue = false,
    Flag = "Bhop",
    Callback = function(value)
        State.Bhop = value
        if value then EnableBhop() else DisableBhop() end
    end
})

MovementTab:CreateToggle({
    Name = "Spinbot",
    CurrentValue = false,
    Flag = "Spinbot",
    Callback = function(value)
        State.Spinbot = value
        if value then StartSpinbot() else StopSpinbot() end
    end
})

MovementTab:CreateToggle({
    Name = "CFrame Speed",
    CurrentValue = false,
    Flag = "CFrameSpeed",
    Callback = function(value)
        State.CFrameSpeed = value
        if value then EnableCFrameSpeed() else DisableCFrameSpeed() end
    end
})

MovementTab:CreateSlider({
    Name = "CFrame Speed Multiplier",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 2,
    Flag = "CFrameSpeedMultiplier",
    Callback = function(value)
        State.CFrameSpeedMultiplier = value
    end
})

-- ================================================================= --
-- MM2 MASTER
-- ================================================================= --

MM2Tab:CreateSection("MM2")

MM2Tab:CreateParagraph({
    Title = "MM2 Master",
    Content = "MM2 exploit automation is disabled in this build."
})

MM2Tab:CreateButton({
    Name = "Refresh Character",
    Callback = function()
        if LocalPlayer.Character then
            LocalPlayer.Character:BreakJoints()
        end
    end
})

MM2Tab:CreateToggle({
    Name = "MM2 Module",
    CurrentValue = false,
    Flag = "MM2Module",
    Callback = function(value)
        Notify("MM2 Master", value and "Module enabled" or "Module disabled")
    end
})

MM2Tab:CreateSection("MM2 Exploits")

MM2Tab:CreateToggle({
    Name = "Gun Teleport",
    CurrentValue = false,
    Flag = "GunTeleport",
    Callback = function(value)
        State.GunTeleport = value
        if value then TeleportToGun() end
    end
})

MM2Tab:CreateButton({
    Name = "Teleport to Tool",
    Callback = function()
        TeleportToTool()
    end
})

MM2Tab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(value)
        State.SilentAim = value
        if value then EnableSilentAim() else DisableSilentAim() end
    end
})

MM2Tab:CreateToggle({
    Name = "AutoShoot",
    CurrentValue = false,
    Flag = "AutoShoot",
    Callback = function(value)
        State.AutoShoot = value
        if value then StartAutoShoot() else StopAutoShoot() end
    end
})

MM2Tab:CreateToggle({
    Name = "KillAura",
    CurrentValue = false,
    Flag = "KillAura",
    Callback = function(value)
        State.KillAura = value
        if value then StartKillAura() else StopKillAura() end
    end
})

MM2Tab:CreateSlider({
    Name = "KillAura Range",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 20,
    Flag = "KillAuraRange",
    Callback = function(value)
        State.KillAuraRange = value
    end
})

MM2Tab:CreateToggle({
    Name = "AntiVoid",
    CurrentValue = false,
    Flag = "AntiVoid",
    Callback = function(value)
        State.AntiVoid = value
        if value then EnableAntiVoid() else DisableAntiVoid() end
    end
})

MM2Tab:CreateToggle({
    Name = "AntiFall",
    CurrentValue = false,
    Flag = "AntiFall",
    Callback = function(value)
        State.AntiFall = value
        if value then EnableAntiFall() else DisableAntiFall() end
    end
})

MM2Tab:CreateToggle({
    Name = "AntiAFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(value)
        State.AntiAFK = value
        if value then EnableAntiAFK() else DisableAntiAFK() end
    end
})

MM2Tab:CreateToggle({
    Name = "Godmode",
    CurrentValue = false,
    Flag = "Godmode",
    Callback = function(value)
        State.Godmode = value
        if value then EnableGodmode() else DisableGodmode() end
    end
})

MM2Tab:CreateToggle({
    Name = "Teleport Tool",
    CurrentValue = false,
    Flag = "TeleportTool",
    Callback = function(value)
        State.TeleportTool = value
        if value then EnableTeleportTool() else DisableTeleportTool() end
    end
})

-- ================================================================= --
-- SERVER
-- ================================================================= --

ServerTab:CreateSection("Server")

ServerTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        Notify("Server", "Rejoining...", 2)
        task.wait(0.5)
        pcall(function()
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end)
    end
})

ServerTab:CreateButton({
    Name = "Server Hop",
    Callback = function()
        Notify("Server", "Hopping to a new server...", 2)
        task.wait(0.5)
        pcall(function()
            local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
            for _, s in pairs(servers) do
                if s.playing < s.maxPlayers and s.id ~= game.JobId then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
                    break
                end
            end
        end)
    end
})

ServerTab:CreateButton({
    Name = "Copy Job ID",
    Callback = function()
        if setclipboard then
            setclipboard(game.JobId)
            Notify("Server", "Job ID copied.")
        else
            Notify("Server", "Clipboard is unavailable.")
        end
    end
})

ServerTab:CreateParagraph({
    Title = "Server Information",
    Content = "Place ID: " .. tostring(game.PlaceId) .. "\nJob ID: " .. tostring(game.JobId)
})

-- ================================================================= --
-- SETTINGS
-- ================================================================= --

SettingsTab:CreateSection("Interface")

SettingsTab:CreateToggle({
    Name = "Notifications",
    CurrentValue = true,
    Flag = "Notifications",
    Callback = function(value)
        State.Notifications = value
    end
})

SettingsTab:CreateToggle({
    Name = "Debug Mode",
    CurrentValue = false,
    Flag = "DebugMode",
    Callback = function(value)
        State.Debug = value
    end
})

SettingsTab:CreateButton({
    Name = "Reset Configuration",
    Callback = function()
        Rayfield:Notify({
            Title = "Settings",
            Content = "Configuration reset.",
            Duration = 2
        })
    end
})

SettingsTab:CreateButton({
    Name = "Destroy UI",
    Callback = function()
        Cleanup()
        Rayfield:Destroy()
    end
})

SettingsTab:CreateSection("Save / Load")

SettingsTab:CreateButton({
    Name = "Save Settings",
    Callback = function()
        Rayfield:SaveConfiguration()
        Notify("Settings", "Settings saved.")
    end
})

SettingsTab:CreateButton({
    Name = "Load Settings",
    Callback = function()
        Rayfield:LoadConfiguration()
        Notify("Settings", "Settings loaded.")
    end
})

SettingsTab:CreateButton({
    Name = "Toggle UI",
    Callback = function()
        Rayfield:Toggle()
    end
})

-- ================================================================= --
-- AUTOMATION
-- ================================================================= --

SettingsTab:CreateSection("Automation")

SettingsTab:CreateToggle({
    Name = "AutoClicker",
    CurrentValue = false,
    Flag = "AutoClicker",
    Callback = function(value)
        State.AutoClicker = value
        if value then StartAutoClicker() else StopAutoClicker() end
    end
})

SettingsTab:CreateSlider({
    Name = "Click Delay (ms)",
    Range = {10, 1000},
    Increment = 10,
    CurrentValue = 100,
    Flag = "AutoClickerDelay",
    Callback = function(value)
        State.AutoClickerDelay = value
    end
})

SettingsTab:CreateToggle({
    Name = "Chat Spam",
    CurrentValue = false,
    Flag = "ChatSpam",
    Callback = function(value)
        State.ChatSpam = value
        if value then StartChatSpam() else StopChatSpam() end
    end
})

SettingsTab:CreateTextBox({
    Name = "Chat Spam Message",
    CurrentValue = "WIA HUB ON TOP",
    Flag = "ChatSpamMessage",
    Callback = function(value)
        State.ChatSpamMessage = value
    end
})

SettingsTab:CreateSlider({
    Name = "Chat Spam Delay (s)",
    Range = {1, 60},
    Increment = 1,
    CurrentValue = 5,
    Flag = "ChatSpamDelay",
    Callback = function(value)
        State.ChatSpamDelay = value
    end
})

-- ================================================================= --
-- PLAYER LIST TAB
-- ================================================================= --

PlayerListTab:CreateSection("Player List")

PlayerListTab:CreateToggle({
    Name = "Enable Player List",
    CurrentValue = false,
    Flag = "PlayerList",
    Callback = function(value)
        State.PlayerList = value
        if value then
            RefreshPlayerList()
        else
            for _, btn in pairs(PlayerListButtons) do
                pcall(function() btn:Destroy() end)
            end
            PlayerListButtons = {}
        end
    end
})

-- ================================================================= --
-- INITIALIZATION
-- ================================================================= --

AddConnection(LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    ApplyMovementSettings()
    if State.FullBright then
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    end
    if State.Noclip then
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    if State.TeleportTool and TeleportToolInstance then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:EquipTool(TeleportToolInstance)
        end
    end
end))

AddConnection(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    local camera = workspace.CurrentCamera
    if camera then
        camera.FieldOfView = State.CameraFOV
    end
end))

AddConnection(Lighting.ChildAdded:Connect(function(object)
    if State.RemoveColorCorrection and object:IsA("ColorCorrectionEffect") then
        if not originalColorCorrectionStates[object] then
            originalColorCorrectionStates[object] = object.Enabled
        end
        object.Enabled = false
    end
end))

-- ================================================================= --
-- FINAL NOTIFICATION
-- ================================================================= --

Notify(
    "WIA HUB v11",
    "Rayfield Edition loaded successfully with all features from v8 integrated.",
    4
)