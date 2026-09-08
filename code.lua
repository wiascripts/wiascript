-- ================================================================= --
-- WIA HUB v11.0.2 RAYFIELD EDITION :: FULLY FIXED
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
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ========== VARIABLES ==========
local Settings = {
    Flight = false,
    FlySpeed = 50,
    Noclip = false,
    Speed = 16,
    JumpPower = 50,
    InfiniteJump = false,
    Bhop = false,
    Spinbot = false,
    SpinSpeed = 20,
    CFrameSpeed = false,
    CFrameMultiplier = 2,

    Aimbot = false,
    AimbotFOV = 90,
    Smoothness = 5,
    Triggerbot = false,
    HitboxExpander = false,
    HitboxSize = 5,

    ESPBox = true,
    ESPTracer = true,
    ESPName = true,
    ESPDistance = true,
    ESPHealth = true,
    Wallhack = false,
    CoinESP = true,
    GunESP = true,

    AutoFarm = false,
    FarmSpeed = 25,
    AutoGrabGun = false,
    SilentAim = false,
    AutoShoot = false,
    KillAura = false,
    KillRadius = 12,
    AntiKnife = false,
    GunTeleport = false,

    FullBright = false,
    NoFog = false,
    CamFOV = 70,
    DisableYellowTint = true,

    AntiAFK = false,
    AntiVoid = false,
    AntiFall = false,
    Godmode = false,
    AutoClicker = false,
    ClickDelay = 100,
    ChatSpam = false,
    SpamMessage = "WIA HUB ON TOP",
    SpamDelay = 5,
}

-- ========== STATE SAVE ==========
local Original = {
    WalkSpeed = {},
    JumpPower = {},
    CanCollide = {},
    Size = {},
    Transparency = {},
    Brightness = nil,
    Ambient = nil,
    FogEnd = nil,
}

local function SaveCharacter(char)
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if not Original.CanCollide[part] then
                Original.CanCollide[part] = part.CanCollide
                Original.Size[part] = part.Size
                Original.Transparency[part] = part.Transparency
            end
        end
    end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        if not Original.WalkSpeed[hum] then Original.WalkSpeed[hum] = hum.WalkSpeed end
        if not Original.JumpPower[hum] then Original.JumpPower[hum] = hum.JumpPower end
    end
end

local function RestoreCharacter(char)
    if not char then return end
    for part, val in pairs(Original.CanCollide) do
        if part and part.Parent then
            pcall(function() part.CanCollide = val end)
        end
    end
    for part, val in pairs(Original.Size) do
        if part and part.Parent then
            pcall(function() part.Size = val end)
        end
    end
    for part, val in pairs(Original.Transparency) do
        if part and part.Parent then
            pcall(function() part.Transparency = val end)
        end
    end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        if Original.WalkSpeed[hum] then pcall(function() hum.WalkSpeed = Original.WalkSpeed[hum] end) end
        if Original.JumpPower[hum] then pcall(function() hum.JumpPower = Original.JumpPower[hum] end) end
    end
end

-- ========== UTILITY FUNCTIONS ==========
local function getPlayerRole(player)
    if not player or not player.Character then return "Innocent" end
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    if char:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")) then
        return "Murderer"
    elseif char:FindFirstChild("Gun") or (bp and bp:FindFirstChild("Gun")) or
           char:FindFirstChild("Revolver") or (bp and bp:FindFirstChild("Revolver")) then
        return "Sheriff"
    end
    return "Innocent"
end

local function getGunDrop()
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name == "GunDrop" then return obj end
        if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
            if obj:FindFirstChild("Gun") or obj:FindFirstChild("Revolver") then
                return obj
            end
        end
    end
    return nil
end

local function getCoins()
    local coins = {}
    for _, child in pairs(Workspace:GetDescendants()) do
        if child:IsA("BasePart") and child.Name:find("Coin") then
            table.insert(coins, child)
        end
    end
    return coins
end

local function getSpawn()
    return Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChildWhichIsA("SpawnLocation")
end

-- ========== RAYFIELD WINDOW ==========
local Window = Rayfield:CreateWindow({
    Name = "WIA HUB v11.0.2",
    LoadingTitle = "WIA HUB",
    LoadingSubtitle = "by whitewia / tordark",
    Theme = "Purple",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local CombatTab = Window:CreateTab("Combat", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483345998)
local MovementTab = Window:CreateTab("Movement", 4483362458)
local MM2Tab = Window:CreateTab("MM2 Pro", 4483362458)
local ServerTab = Window:CreateTab("Server", 4483362458)

-- ========== COMBAT TAB ==========
CombatTab:CreateSection("Aimbot")
CombatTab:CreateToggle({
    Name = "Aimbot",
    CurrentValue = false,
    Callback = function(v) Settings.Aimbot = v end
})
CombatTab:CreateSlider({
    Name = "Aimbot FOV",
    Range = {10, 400},
    Increment = 1,
    Suffix = "px",
    CurrentValue = 90,
    Callback = function(v) Settings.AimbotFOV = v end
})
CombatTab:CreateSlider({
    Name = "Smoothness",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v) Settings.Smoothness = v end
})
CombatTab:CreateToggle({
    Name = "Triggerbot",
    CurrentValue = false,
    Callback = function(v) Settings.Triggerbot = v end
})

CombatTab:CreateSection("Hitbox Expander")
CombatTab:CreateToggle({
    Name = "Hitbox Expander",
    CurrentValue = false,
    Callback = function(v) Settings.HitboxExpander = v end
})
CombatTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 20},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 5,
    Callback = function(v) Settings.HitboxSize = v end
})

CombatTab:CreateSection("Auto")
CombatTab:CreateToggle({
    Name = "AutoClicker",
    CurrentValue = false,
    Callback = function(v) Settings.AutoClicker = v end
})
CombatTab:CreateSlider({
    Name = "Click Delay (ms)",
    Range = {10, 1000},
    Increment = 10,
    Suffix = " ms",
    CurrentValue = 100,
    Callback = function(v) Settings.ClickDelay = v end
})

-- ========== VISUALS TAB ==========
VisualsTab:CreateSection("ESP")
VisualsTab:CreateToggle({
    Name = "ESP Boxes",
    CurrentValue = true,
    Callback = function(v) Settings.ESPBox = v end
})
VisualsTab:CreateToggle({
    Name = "ESP Tracers",
    CurrentValue = true,
    Callback = function(v) Settings.ESPTracer = v end
})
VisualsTab:CreateToggle({
    Name = "ESP Names",
    CurrentValue = true,
    Callback = function(v) Settings.ESPName = v end
})
VisualsTab:CreateToggle({
    Name = "ESP Distance",
    CurrentValue = true,
    Callback = function(v) Settings.ESPDistance = v end
})
VisualsTab:CreateToggle({
    Name = "ESP Health",
    CurrentValue = true,
    Callback = function(v) Settings.ESPHealth = v end
})
VisualsTab:CreateToggle({
    Name = "Coin ESP",
    CurrentValue = true,
    Callback = function(v) Settings.CoinESP = v end
})
VisualsTab:CreateToggle({
    Name = "Gun Drop ESP",
    CurrentValue = true,
    Callback = function(v) Settings.GunESP = v end
})
VisualsTab:CreateToggle({
    Name = "Wallhack",
    CurrentValue = false,
    Callback = function(v) Settings.Wallhack = v end
})

VisualsTab:CreateSection("World")
VisualsTab:CreateToggle({
    Name = "FullBright",
    CurrentValue = false,
    Callback = function(v) Settings.FullBright = v end
})
VisualsTab:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Callback = function(v) Settings.NoFog = v end
})
VisualsTab:CreateSlider({
    Name = "Camera FOV",
    Range = {50, 120},
    Increment = 1,
    Suffix = "°",
    CurrentValue = 70,
    Callback = function(v) Settings.CamFOV = v end
})
VisualsTab:CreateToggle({
    Name = "Remove Yellow Tint",
    CurrentValue = true,
    Callback = function(v) Settings.DisableYellowTint = v end
})

-- ========== MOVEMENT TAB ==========
MovementTab:CreateSection("Flight & Noclip")
MovementTab:CreateToggle({
    Name = "Flight",
    CurrentValue = false,
    Callback = function(v) Settings.Flight = v end
})
MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    Suffix = " speed",
    CurrentValue = 50,
    Callback = function(v) Settings.FlySpeed = v end
})
MovementTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(v) Settings.Noclip = v end
})

MovementTab:CreateSection("Speed & Jump")
MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(v)
        Settings.Speed = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end
})
MovementTab:CreateSlider({
    Name = "Jump Power",
    Range = {50, 200},
    Increment = 1,
    CurrentValue = 50,
    Callback = function(v)
        Settings.JumpPower = v
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.JumpPower = v
        end
    end
})
MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(v) Settings.InfiniteJump = v end
})
MovementTab:CreateToggle({
    Name = "Bhop",
    CurrentValue = false,
    Callback = function(v) Settings.Bhop = v end
})
MovementTab:CreateToggle({
    Name = "Spinbot",
    CurrentValue = false,
    Callback = function(v) Settings.Spinbot = v end
})
MovementTab:CreateSlider({
    Name = "Spin Speed",
    Range = {5, 50},
    Increment = 1,
    CurrentValue = 20,
    Callback = function(v) Settings.SpinSpeed = v end
})
MovementTab:CreateToggle({
    Name = "CFrame Speed (Bypass)",
    CurrentValue = false,
    Callback = function(v) Settings.CFrameSpeed = v end
})
MovementTab:CreateSlider({
    Name = "CFrame Multiplier",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = 2,
    Callback = function(v) Settings.CFrameMultiplier = v end
})

-- ========== MM2 TAB ==========
MM2Tab:CreateSection("Auto Farm")
MM2Tab:CreateToggle({
    Name = "Auto-Farm Coins",
    CurrentValue = false,
    Callback = function(v) Settings.AutoFarm = v end
})
MM2Tab:CreateSlider({
    Name = "Farm Speed",
    Range = {10, 50},
    Increment = 5,
    CurrentValue = 25,
    Callback = function(v) Settings.FarmSpeed = v end
})
MM2Tab:CreateToggle({
    Name = "Auto-Grab Gun",
    CurrentValue = false,
    Callback = function(v) Settings.AutoGrabGun = v end
})
MM2Tab:CreateToggle({
    Name = "Smart Gun Teleport",
    CurrentValue = false,
    Callback = function(v) Settings.GunTeleport = v end
})

MM2Tab:CreateSection("Combat")
MM2Tab:CreateToggle({
    Name = "Silent Aim (Aim Lock)",
    CurrentValue = false,
    Callback = function(v) Settings.SilentAim = v end
})
MM2Tab:CreateToggle({
    Name = "Auto-Shoot (Sheriff)",
    CurrentValue = false,
    Callback = function(v) Settings.AutoShoot = v end
})
MM2Tab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Callback = function(v) Settings.KillAura = v end
})
MM2Tab:CreateSlider({
    Name = "Kill Radius",
    Range = {1, 30},
    Increment = 1,
    CurrentValue = 12,
    Callback = function(v) Settings.KillRadius = v end
})

MM2Tab:CreateSection("Protection")
MM2Tab:CreateToggle({
    Name = "Anti-Knife (Run from Murderer)",
    CurrentValue = false,
    Callback = function(v) Settings.AntiKnife = v end
})
MM2Tab:CreateToggle({
    Name = "Anti-Void",
    CurrentValue = false,
    Callback = function(v) Settings.AntiVoid = v end
})
MM2Tab:CreateToggle({
    Name = "Anti-Fall Damage",
    CurrentValue = false,
    Callback = function(v) Settings.AntiFall = v end
})
MM2Tab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(v) Settings.AntiAFK = v end
})
MM2Tab:CreateToggle({
    Name = "Godmode (Health Lock)",
    CurrentValue = false,
    Callback = function(v) Settings.Godmode = v end
})

MM2Tab:CreateSection("Chat & Spam")
MM2Tab:CreateToggle({
    Name = "Chat Spam",
    CurrentValue = false,
    Callback = function(v) Settings.ChatSpam = v end
})
MM2Tab:CreateSlider({
    Name = "Spam Delay (s)",
    Range = {1, 60},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(v) Settings.SpamDelay = v end
})

-- ========== SERVER TAB ==========
ServerTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end
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
    end
})

-- ========== BACKGROUND LOOPS (FIXED) ==========

-- 1. Flight
local bv, bg = nil, nil
RunService.Heartbeat:Connect(function()
    if Settings.Flight and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        if not bv then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            bv.Parent = root
        end
        if not bg then
            bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            bg.Parent = root
        end
        local moveDir = Vector3.new(0,0,0)
        local cam = Camera
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end
        if moveDir.Magnitude > 0 then
            bv.Velocity = moveDir.Unit * Settings.FlySpeed
            bg.CFrame = CFrame.new(root.Position, root.Position + moveDir)
        else
            bv.Velocity = Vector3.new(0,0,0)
        end
    else
        if bv then bv:Destroy() bv = nil end
        if bg then bg:Destroy() bg = nil end
    end
end)

-- 2. Noclip
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if Settings.Noclip then
                if not Original.CanCollide[part] then Original.CanCollide[part] = part.CanCollide end
                part.CanCollide = false
            else
                if Original.CanCollide[part] then
                    part.CanCollide = Original.CanCollide[part]
                    Original.CanCollide[part] = nil
                end
            end
        end
    end
end)

-- 3. Walk Speed / Jump Power
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChild("Humanoid")
    if hum then
        if hum.WalkSpeed ~= Settings.Speed then hum.WalkSpeed = Settings.Speed end
        if hum.JumpPower ~= Settings.JumpPower then hum.JumpPower = Settings.JumpPower end
    end
end)

-- 4. Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- 5. Bhop
RunService.Heartbeat:Connect(function()
    if Settings.Bhop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- 6. Spinbot
RunService.RenderStepped:Connect(function()
    if Settings.Spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0)
    end
end)

-- 7. CFrame Speed
RunService.Heartbeat:Connect(function()
    if Settings.CFrameSpeed and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (Settings.CFrameMultiplier / 10))
        end
    end
end)

-- 8. Godmode
RunService.Heartbeat:Connect(function()
    if Settings.Godmode and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
    end
end)

-- 9. Anti-Void
RunService.Heartbeat:Connect(function()
    if Settings.AntiVoid and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character.HumanoidRootPart.Position.Y < -50 then
            local spawn = getSpawn()
            if spawn then
                LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- 10. Anti-Fall
RunService.Heartbeat:Connect(function()
    if Settings.AntiFall and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end)

-- 11. Anti-AFK
local afkConnection
LocalPlayer.Idled:Connect(function()
    if Settings.AntiAFK then
        VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
    end
end)

-- 12. Aimbot
RunService.RenderStepped:Connect(function()
    if Settings.Aimbot then
        local closest = nil
        local minDist = Settings.AimbotFOV
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
        if closest and closest.Character and closest.Character:FindFirstChild("Head") then
            local head = closest.Character.Head
            local targetPos = head.Position
            local current = Camera.CFrame
            local new = CFrame.new(current.Position, targetPos)
            if Settings.Smoothness > 1 then
                Camera.CFrame = current:Lerp(new, 1 / Settings.Smoothness)
            else
                Camera.CFrame = new
            end
        end
    end
end)

-- 13. Triggerbot
RunService.RenderStepped:Connect(function()
    if Settings.Triggerbot then
        local target = Mouse.Target
        if target and target.Parent then
            local plr = Players:GetPlayerFromCharacter(target.Parent)
            if plr and plr ~= LocalPlayer then
                mouse1click()
            end
        end
    end
end)

-- 14. Hitbox Expander
RunService.Heartbeat:Connect(function()
    if Settings.HitboxExpander then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                if not Original.Size[root] then
                    Original.Size[root] = root.Size
                    Original.Transparency[root] = root.Transparency
                end
                root.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
                root.Transparency = 0.7
            end
        end
    else
        for part, val in pairs(Original.Size) do
            if part and part.Parent then
                pcall(function() part.Size = val end)
            end
        end
        for part, val in pairs(Original.Transparency) do
            if part and part.Parent then
                pcall(function() part.Transparency = val end)
            end
        end
        Original.Size = {}
        Original.Transparency = {}
    end
end)

-- 15. AutoClicker
task.spawn(function()
    while true do
        task.wait(Settings.ClickDelay / 1000)
        if Settings.AutoClicker then
            mouse1click()
        end
    end
end)

-- 16. Chat Spam
task.spawn(function()
    while true do
        task.wait(Settings.SpamDelay)
        if Settings.ChatSpam then
            local chat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chat and chat:FindFirstChild("SayMessageRequest") then
                chat.SayMessageRequest:FireServer("WIA HUB ON TOP", "All")
            end
        end
    end
end)

-- 17. MM2: Auto Farm Coins
local farmCooldown = 0
RunService.Heartbeat:Connect(function()
    if Settings.AutoFarm and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local coins = getCoins()
        if #coins > 0 and tick() - farmCooldown > 0.15 then
            local hrp = LocalPlayer.Character.HumanoidRootPart
            local nearest = nil
            local minDist = math.huge
            for _, coin in pairs(coins) do
                local dist = (hrp.Position - coin.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = coin
                end
            end
            if nearest then
                hrp.CFrame = nearest.CFrame * CFrame.new(0, 1, 0)
                farmCooldown = tick()
            end
        end
    end
end)

-- 18. MM2: Auto-Grab Gun
RunService.Heartbeat:Connect(function()
    if Settings.AutoGrabGun then
        local gun = getGunDrop()
        local char = LocalPlayer.Character
        if gun and char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local gunPart = gun:IsA("Model") and (gun.PrimaryPart or gun:FindFirstChildWhichIsA("BasePart")) or gun
            if gunPart then
                hrp.CFrame = gunPart.CFrame * CFrame.new(0, 1, 0)
                if firetouchinterest then
                    pcall(function()
                        firetouchinterest(hrp, gunPart, 0)
                        firetouchinterest(hrp, gunPart, 1)
                    end)
                end
            end
        end
    end
end)

-- 19. MM2: Smart Gun Teleport
local gunTeleportCooldown = false
RunService.Heartbeat:Connect(function()
    if Settings.GunTeleport and not gunTeleportCooldown then
        local gun = getGunDrop()
        local char = LocalPlayer.Character
        if gun and char and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            local currentPos = hrp.CFrame
            local gunPart = gun:IsA("Model") and (gun.PrimaryPart or gun:FindFirstChildWhichIsA("BasePart")) or gun
            if gunPart then
                gunTeleportCooldown = true
                hrp.CFrame = gunPart.CFrame * CFrame.new(0, 1, 0)
                if firetouchinterest then
                    pcall(function()
                        firetouchinterest(hrp, gunPart, 0)
                        firetouchinterest(hrp, gunPart, 1)
                    end)
                end
                hrp.CFrame = currentPos
                task.wait(1.5)
                gunTeleportCooldown = false
            end
        end
    end
end)

-- 20. MM2: Silent Aim (Aim Lock on Murderer)
RunService.RenderStepped:Connect(function()
    if Settings.SilentAim then
        local murderer = nil
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getPlayerRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("Head") then
                murderer = plr.Character
                break
            end
        end
        if murderer then
            local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Revolver")
            if gun then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, murderer.Head.Position)
            end
        end
    end
end)

-- 21. MM2: Auto-Shoot
RunService.RenderStepped:Connect(function()
    if Settings.AutoShoot then
        local murderer = nil
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and getPlayerRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                murderer = plr.Character
                break
            end
        end
        if murderer then
            local gun = LocalPlayer.Character:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Revolver")
            if gun and mouse1click then
                mouse1click()
            end
        end
    end
end)

-- 22. MM2: Kill Aura
RunService.RenderStepped:Connect(function()
    if Settings.KillAura then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Knife") then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (char.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                    if dist < Settings.KillRadius then
                        if mouse1click then mouse1click() end
                        if char.Knife:FindFirstChild("Stab") then
                            char.Knife.Stab:FireServer()
                        end
                    end
                end
            end
        end
    end
end)

-- 23. MM2: Anti-Knife
RunService.Heartbeat:Connect(function()
    if Settings.AntiKnife then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and getPlayerRole(plr) == "Murderer" and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (char.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                    if dist < 12 then
                        local dir = (char.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Unit
                        char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position + dir * 15)
                    end
                end
            end
        end
    end
end)

-- 24. Wallhack
RunService.Heartbeat:Connect(function()
    if Settings.Wallhack then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("WIA_WH") then
                local hl = Instance.new("Highlight")
                hl.Name = "WIA_WH"
                hl.FillColor = Color3.fromRGB(180, 0, 255)
                hl.FillTransparency = 0.3
                hl.OutlineColor = Color3.fromRGB(255,255,255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = plr.Character
            end
        end
    else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("WIA_WH") then
                plr.Character.WIA_WH:Destroy()
            end
        end
    end
end)

-- 25. FullBright & NoFog
RunService.Heartbeat:Connect(function()
    if Settings.FullBright then
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255,255,255)
    else
        Lighting.Brightness = 1
        Lighting.Ambient = Color3.fromRGB(127,127,127)
    end
    if Settings.NoFog then
        Lighting.FogEnd = 1e6
    else
        Lighting.FogEnd = 10000
    end
end)

-- 26. Remove Yellow Tint
task.spawn(function()
    while true do
        task.wait(2)
        if Settings.DisableYellowTint then
            for _, v in pairs(Lighting:GetDescendants()) do
                if v:IsA("ColorCorrectionEffect") and v.TintColor.R > 0.8 and v.TintColor.G > 0.7 then
                    v.TintColor = Color3.new(1,1,1)
                end
            end
        end
    end
end)

-- 27. Camera FOV
RunService.RenderStepped:Connect(function()
    local current = Camera.FieldOfView
    local target = Settings.CamFOV
    if math.abs(current - target) > 0.5 then
        Camera.FieldOfView = current + (target - current) * 0.1
    end
end)

-- ========== ESP DRAWING (SIMPLE) ==========
local espLines = {}
local espTexts = {}

RunService.RenderStepped:Connect(function()
    for _, d in pairs(espLines) do d:Remove() end
    for _, d in pairs(espTexts) do d:Remove() end
    espLines = {}
    espTexts = {}

    if not (Settings.ESPBox or Settings.ESPTracer or Settings.ESPName or Settings.ESPDistance or Settings.ESPHealth) then return end

    local cam = Camera
    local viewport = cam.ViewportSize
    local camPos = cam.CFrame.Position

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local hum = plr.Character:FindFirstChild("Humanoid")
            if not hum or hum.Health <= 0 then continue end

            local pos, onScreen = cam:WorldToScreenPoint(head.Position)
            if not onScreen then continue end

            local dist = (head.Position - camPos).Magnitude
            local size = math.clamp(100 / dist * 10, 15, 45)

            local x, y = pos.X - size/2, pos.Y - size/2
            local color = Color3.fromRGB(180, 0, 255)

            if Settings.ESPBox then
                for i = 1, 4 do
                    local line = Drawing.new("Line")
                    if i == 1 then line.From = Vector2.new(x, y) line.To = Vector2.new(x + size, y)
                    elseif i == 2 then line.From = Vector2.new(x + size, y) line.To = Vector2.new(x + size, y + size)
                    elseif i == 3 then line.From = Vector2.new(x + size, y + size) line.To = Vector2.new(x, y + size)
                    else line.From = Vector2.new(x, y + size) line.To = Vector2.new(x, y) end
                    line.Color = color
                    line.Thickness = 2
                    line.Transparency = 1
                    table.insert(espLines, line)
                end
            end

            if Settings.ESPTracer then
                local tracer = Drawing.new("Line")
                tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
                tracer.To = Vector2.new(pos.X, pos.Y)
                tracer.Color = Color3.fromRGB(180, 0, 255)
                tracer.Thickness = 1.5
                tracer.Transparency = 0.7
                table.insert(espLines, tracer)
            end

            if Settings.ESPName or Settings.ESPHealth or Settings.ESPDistance then
                local text = Drawing.new("Text")
                text.Position = Vector2.new(pos.X, y - 15)
                text.Size = 13
                text.Center = true
                text.Outline = true
                text.Color = Color3.fromRGB(255,255,255)
                local str = ""
                if Settings.ESPName then str = str .. plr.Name .. " " end
                if Settings.ESPHealth and hum then str = str .. "[" .. math.floor(hum.Health) .. "HP] " end
                if Settings.ESPDistance then str = str .. "(" .. math.floor(dist) .. "m)" end
                text.Text = str
                table.insert(espTexts, text)
            end
        end
    end

    -- Coins ESP
    if Settings.CoinESP then
        for _, coin in pairs(getCoins()) do
            local pos, onScreen = cam:WorldToScreenPoint(coin.Position)
            if onScreen then
                local text = Drawing.new("Text")
                text.Position = Vector2.new(pos.X, pos.Y)
                text.Text = "$"
                text.Size = 20
                text.Center = true
                text.Outline = true
                text.Color = Color3.fromRGB(255, 215, 0)
                table.insert(espTexts, text)
            end
        end
    end

    -- Gun Drop ESP
    if Settings.GunESP then
        local gun = getGunDrop()
        if gun then
            local gunPart = gun:IsA("Model") and (gun.PrimaryPart or gun:FindFirstChildWhichIsA("BasePart")) or gun
            if gunPart then
                local pos, onScreen = cam:WorldToScreenPoint(gunPart.Position)
                if onScreen then
                    local text = Drawing.new("Text")
                    text.Position = Vector2.new(pos.X, pos.Y - 20)
                    text.Text = "GUN"
                    text.Size = 14
                    text.Center = true
                    text.Outline = true
                    text.Color = Color3.fromRGB(255, 255, 0)
                    table.insert(espTexts, text)
                end
            end
        end
    end
end)

-- ========== PLAYER LIST (FIXED) ==========
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList"
PlayerListGui.Parent = game:CoreGui
PlayerListGui.Enabled = false

local PlayerListFrame = Instance.new("Frame")
PlayerListFrame.Size = UDim2.new(0, 260, 0, 400)
PlayerListFrame.Position = UDim2.new(0, 360, 0, 10)
PlayerListFrame.BackgroundColor3 = Color3.fromRGB(10,10,25)
PlayerListFrame.BackgroundTransparency = 0.2
PlayerListFrame.BorderSizePixel = 1
PlayerListFrame.BorderColor3 = Color3.fromRGB(180,0,255)
PlayerListFrame.Parent = PlayerListGui

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1,0,0,30)
TitleLabel.Text = "PLAYER LIST"
TitleLabel.TextColor3 = Color3.fromRGB(180,0,255)
TitleLabel.TextScaled = true
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Parent = PlayerListFrame

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,-10,1,-40)
Scroll.Position = UDim2.new(0,5,0,35)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.Parent = PlayerListFrame

local Container = Instance.new("Frame")
Container.Size = UDim2.new(1,0,0,0)
Container.BackgroundTransparency = 1
Container.Parent = Scroll

local function UpdatePlayerList()
    for _, child in pairs(Container:GetChildren()) do child:Destroy() end
    local y = 0
    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,0,0,25)
        btn.Position = UDim2.new(0,0,0,y)
        btn.Text = plr.Name .. " [TP]"
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.BackgroundColor3 = Color3.fromRGB(40,40,55)
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.Gotham
        btn.TextSize = 12
        btn.Parent = Container
        btn.MouseButton1Click:Connect(function()
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = plr.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,2)
            end
        end)
        y = y + 27
    end
    Container.Size = UDim2.new(1,0,0,y)
    Scroll.CanvasSize = UDim2.new(0,0,0,y)
end

-- Слушаем изменения игроков
Players.PlayerAdded:Connect(UpdatePlayerList)
Players.PlayerRemoving:Connect(UpdatePlayerList)

-- Добавляем тумблер для Player List
VisualsTab:CreateToggle({
    Name = "Player List GUI",
    CurrentValue = false,
    Callback = function(v)
        PlayerListGui.Enabled = v
        if v then UpdatePlayerList() end
    end
})

-- ========== NOTIFICATION ==========
Rayfield:Notify({
    Title = "WIA HUB v11.0.2",
    Content = "Все ошибки исправлены!",
    Duration = 4,
})

print("WIA HUB v11.0.2 RAYFIELD EDITION LOADED SUCCESSFULLY")