-- ================================================================= --
-- WIA HUB v11.0.1 OPTIMIZED :: MURDER MYSTERY 2 MASTER
-- PERFORMANCE OPTIMIZED | TRUE 3D BOUNDING BOX | FULL STATE MANAGEMENT
-- ================================================================= --

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Init.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========== SCRIPT STATE ==========
local ScriptState = {
IsRunning = true,
Connections = {},
OriginalMetatable = nil,
OriginalNamecall = nil,
IsCleaningUp = false,
CleanupFlag = false,
}

-- ========== CONNECTION MANAGEMENT ==========
local function TrackConnection(connection)
if not ScriptState.IsRunning then return nil end
table.insert(ScriptState.Connections, connection)
return connection
end

local function CleanupConnections()
ScriptState.IsRunning = false
for _, conn in pairs(ScriptState.Connections) do
pcall(function() conn:Disconnect() end)
end
ScriptState.Connections = {}

if ScriptState.OriginalMetatable and ScriptState.OriginalNamecall then  
    pcall(function()  
        local mt = getrawmetatable(game)  
        if mt then  
            mt.__namecall = ScriptState.OriginalNamecall  
        end  
    end)  
end

end

-- ========== DRAWING POOL ==========
local DrawingPool = {
Lines = {},
Texts = {},
}

local function GetDrawingLine()
for _, d in pairs(DrawingPool.Lines) do
if not d.Visible then
d.Visible = true
return d
end
end
local d = Drawing.new("Line")
d.Visible = true
table.insert(DrawingPool.Lines, d)
return d
end

local function GetDrawingText()
for _, d in pairs(DrawingPool.Texts) do
if not d.Visible then
d.Visible = true
return d
end
end
local d = Drawing.new("Text")
d.Visible = true
table.insert(DrawingPool.Texts, d)
return d
end

local function ClearDrawings()
for _, d in pairs(DrawingPool.Lines) do
d.Visible = false
end
for _, d in pairs(DrawingPool.Texts) do
d.Visible = false
end
end

local function CleanupDrawings()
for _, d in pairs(DrawingPool.Lines) do
pcall(function() d:Remove() end)
end
for _, d in pairs(DrawingPool.Texts) do
pcall(function() d:Remove() end)
end
DrawingPool.Lines = {}
DrawingPool.Texts = {}
end

-- ========== STATE MANAGEMENT ==========
local OriginalState = {
WalkSpeed = {},
JumpPower = {},
CanCollide = {},
Size = {},
Transparency = {},
Brightness = nil,
Ambient = nil,
OutdoorAmbient = nil,
FogEnd = nil,
CameraFOV = nil,
GlobalShadows = nil,
Technology = nil,
Effects = {},
HasSaved = {},
}

-- Save state of a character
local function SaveCharacterState(character)
if not character then return end
for _, part in pairs(character:GetDescendants()) do
if part:IsA("BasePart") then
if not OriginalState.HasSaved[part] then
OriginalState.CanCollide[part] = part.CanCollide
OriginalState.Size[part] = part.Size
OriginalState.Transparency[part] = part.Transparency
OriginalState.HasSaved[part] = true
end
end
end
local hum = character:FindFirstChild("Humanoid")
if hum and not OriginalState.HasSaved[hum] then
OriginalState.WalkSpeed[hum] = hum.WalkSpeed
OriginalState.JumpPower[hum] = hum.JumpPower
OriginalState.HasSaved[hum] = true
end
end

local function RestoreCharacterState(character)
if not character then return end
for _, part in pairs(character:GetDescendants()) do
if part:IsA("BasePart") then
if OriginalState.CanCollide[part] ~= nil then
pcall(function() part.CanCollide = OriginalState.CanCollide[part] end)
end
if OriginalState.Size[part] ~= nil then
pcall(function() part.Size = OriginalState.Size[part] end)
end
if OriginalState.Transparency[part] ~= nil then
pcall(function() part.Transparency = OriginalState.Transparency[part] end)
end
end
end
local hum = character:FindFirstChild("Humanoid")
if hum then
if OriginalState.WalkSpeed[hum] ~= nil then
pcall(function() hum.WalkSpeed = OriginalState.WalkSpeed[hum] end)
end
if OriginalState.JumpPower[hum] ~= nil then
pcall(function() hum.JumpPower = OriginalState.JumpPower[hum] end)
end
end
end

-- Save lighting and post-processing effects in unified state
local function SaveLightingState()
OriginalState.Brightness = Lighting.Brightness
OriginalState.Ambient = Lighting.Ambient
OriginalState.OutdoorAmbient = Lighting.OutdoorAmbient
OriginalState.FogEnd = Lighting.FogEnd
OriginalState.GlobalShadows = Lighting.GlobalShadows
OriginalState.Technology = Lighting.Technology

OriginalState.Effects = {}  
local function saveEffectContainer(container)  
    for _, obj in pairs(container:GetDescendants()) do  
        if obj:IsA("PostEffect") or obj:IsA("ColorCorrectionEffect") or obj:IsA("BloomEffect") or obj:IsA("SunRaysEffect") or obj:IsA("BlurEffect") then  
            local data = { Enabled = obj.Enabled, ClassName = obj.ClassName }  
            if obj:IsA("ColorCorrectionEffect") then  
                data.TintColor = obj.TintColor  
                data.Brightness = obj.Brightness  
                data.Saturation = obj.Saturation  
                data.Contrast = obj.Contrast  
            elseif obj:IsA("BloomEffect") then  
                data.Intensity = obj.Intensity  
                data.Size = obj.Size  
                data.Threshold = obj.Threshold  
            elseif obj:IsA("SunRaysEffect") then  
                data.Intensity = obj.Intensity  
                data.Spread = obj.Spread  
            end  
            OriginalState.Effects[obj] = data  
        end  
    end  
end  
  
saveEffectContainer(Lighting)  
saveEffectContainer(Workspace)

end

local function RestoreLightingState()
if OriginalState.Brightness then Lighting.Brightness = OriginalState.Brightness end
if OriginalState.Ambient then Lighting.Ambient = OriginalState.Ambient end
if OriginalState.OutdoorAmbient then Lighting.OutdoorAmbient = OriginalState.OutdoorAmbient end
if OriginalState.FogEnd then Lighting.FogEnd = OriginalState.FogEnd end
if OriginalState.GlobalShadows ~= nil then Lighting.GlobalShadows = OriginalState.GlobalShadows end
if OriginalState.Technology then Lighting.Technology = OriginalState.Technology end

for effect, data in pairs(OriginalState.Effects) do  
    pcall(function()  
        if effect and effect.Parent then  
            effect.Enabled = data.Enabled  
            if data.ClassName == "ColorCorrectionEffect" then  
                effect.TintColor = data.TintColor  
                effect.Brightness = data.Brightness  
                effect.Saturation = data.Saturation  
                effect.Contrast = data.Contrast  
            elseif data.ClassName == "BloomEffect" then  
                effect.Intensity = data.Intensity  
                effect.Size = data.Size  
                effect.Threshold = data.Threshold  
            elseif data.ClassName == "SunRaysEffect" then  
                effect.Intensity = data.Intensity  
                effect.Spread = data.Spread  
            end  
        end  
    end)  
end

end

-- Initial state save
SaveLightingState()
local character = LocalPlayer.Character
if character then SaveCharacterState(character) end

-- Track character respawn
TrackConnection(LocalPlayer.CharacterAdded:Connect(function(newChar)
OriginalState.HasSaved = {}
OriginalState.CanCollide = {}
OriginalState.Size = {}
OriginalState.Transparency = {}
OriginalState.WalkSpeed = {}
OriginalState.JumpPower = {}

task.wait(0.1)  
SaveCharacterState(newChar)  
OriginalState.CameraFOV = workspace.CurrentCamera.FieldOfView

end))

-- ========== VARIABLES ==========
local Settings = {
Theme = "Dark",
Keybind = Enum.KeyCode.RightControl,

-- Movement  
Flight = false,  
FlySpeed = 50,  
Noclip = false,  
Speed = 16,  
JumpPower = 50,  
InfiniteJump = false,  
Bhop = false,  
Spinbot = false,  
SpinSpeed = 20,  
  
-- Combat  
Aimbot = false,  
AimbotFOV = 90,  
Smoothness = 5,  
Triggerbot = false,  
HitboxExpander = false,  
HitboxSize = 5,  
  
-- ESP  
ESPBox = true,  
ESPTracer = true,  
ESPName = true,  
ESPDistance = true,  
ESPHealth = true,  
Wallhack = false,  
MurdererColor = Color3.fromRGB(255, 0, 0),  
SheriffColor = Color3.fromRGB(0, 150, 255),  
InnocentColor = Color3.fromRGB(0, 255, 0),  
TracerColor = Color3.fromRGB(180, 0, 255),  
RainbowMode = false,  
RainbowSpeed = 1,  
CoinESP = true,  
GunESP = true,  
  
-- MM2 Features  
AutoFarm = false,  
FarmSpeed = 25,  
AutoGrabGun = false,  
AntiKnife = false,  
SilentAim = false,  
AutoShoot = false,  
KillAura = false,  
KillRadius = 12,  
TrueSilentAim = false,  
GunTeleport = false,  
  
-- Visuals  
FullBright = false,  
NoFog = false,  
CamFOV = 70,  
SmoothFOV = true,  
DisableYellowTint = true,  
  
-- Other  
AntiAFK = false,  
AntiVoid = false,  
AntiFall = false,

}

-- ========== MM2 ROLE DETECTION ==========
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

-- Strictly validated gun drop identification
local function getGunDrop()
for _, obj in pairs(Workspace:GetChildren()) do
if obj.Name == "GunDrop" then
return obj
end
if obj:IsA("Model") and obj.Name ~= "Character" and not Players:GetPlayerFromCharacter(obj) then
if obj:FindFirstChild("Gun") or obj:FindFirstChild("Revolver") or obj:FindFirstChild("GunDrop") then
return obj
end
local handle = obj:FindFirstChild("Handle")
if handle and (obj:FindFirstChildWhichIsA("TouchTransmitter", true) or obj:FindFirstChild("PointLight")) then
return obj
end
end
end
return nil
end

local function getCoins()
local coins = {}
local containers = {}

for _, child in pairs(Workspace:GetChildren()) do  
    if child:IsA("Model") then  
        local coinContainer = child:FindFirstChild("CoinContainer")  
        if coinContainer then table.insert(containers, coinContainer) end  
    end  
    if child:IsA("Folder") and child.Name == "CoinContainer" then  
        table.insert(containers, child)  
    end  
end  
  
for _, container in pairs(containers) do  
    for _, child in pairs(container:GetChildren()) do  
        if child:IsA("BasePart") or child:IsA("Model") then  
            local part = child:IsA("Model") and child.PrimaryPart or child  
            if part and part:IsA("BasePart") then  
                local isVisible = true  
                if child:IsA("BasePart") and child.Transparency > 0.8 then  
                    isVisible = false  
                end  
                if isVisible and part.Parent and part.Parent ~= LocalPlayer.Character then  
                    table.insert(coins, {Object = child, Part = part})  
                end  
            end  
        end  
    end  
end  
return coins

end

-- Find spawn location
local function getSpawnLocation()
local spawn = Workspace:FindFirstChild("SpawnLocation")
if not spawn then
for _, obj in pairs(Workspace:GetChildren()) do
if obj:IsA("SpawnLocation") then
return obj
end
end
end
return spawn
end

-- ========== UI SETUP ==========
local Window = Library:CreateWindow({
Title = "WIA HUB v11.0.1 | MM2 Master",
SubTitle = "Performance Optimized | True 3D ESP",
TabWidth = 160,
Size = UDim2.fromOffset(580, 460),
Acrylic = true,
Theme = "Dark",
MinimizeKey = Settings.Keybind
})

-- Tabs
local Tabs = {
Combat = Window:AddTab("Combat"),
Visuals = Window:AddTab("Visuals"),
Movement = Window:AddTab("Movement"),
MM2 = Window:AddTab("MM2 Master"),
Server = Window:AddTab("Server")
}

-- ========== COMBAT TAB ==========
local CombatSection = Tabs.Combat:AddSection("Aimbot & Combat")
CombatSection:AddToggle("Aimbot", {
Title = "Aimbot",
Description = "Lock onto enemies",
Default = false,
Callback = function(v) Settings.Aimbot = v end
})

CombatSection:AddSlider("AimbotFOV", {
Title = "Aimbot FOV",
Description = "Field of view for aimbot",
Default = 90,
Min = 10,
Max = 400,
Rounding = 1,
Callback = function(v) Settings.AimbotFOV = v end
})

CombatSection:AddSlider("Smoothness", {
Title = "Smoothness",
Description = "Aimbot smoothness",
Default = 5,
Min = 1,
Max = 20,
Rounding = 1,
Callback = function(v) Settings.Smoothness = v end
})

CombatSection:AddToggle("Triggerbot", {
Title = "Triggerbot",
Description = "Auto-shoot when crosshair is on enemy",
Default = false,
Callback = function(v) Settings.Triggerbot = v end
})

local HitboxSection = Tabs.Combat:AddSection("Hitbox Expander")
HitboxSection:AddToggle("HitboxExpander", {
Title = "Hitbox Expander",
Description = "Expand hitboxes of enemies",
Default = false,
Callback = function(v) Settings.HitboxExpander = v end
})

HitboxSection:AddSlider("HitboxSize", {
Title = "Hitbox Size",
Description = "Size of expanded hitboxes",
Default = 5,
Min = 2,
Max = 20,
Rounding = 1,
Callback = function(v) Settings.HitboxSize = v end
})

-- ========== VISUALS TAB ==========
local VisualSection = Tabs.Visuals:AddSection("ESP Settings")
VisualSection:AddToggle("ESPBox", {
Title = "ESP Boxes",
Description = "Draw 2D boxes around players",
Default = true,
Callback = function(v) Settings.ESPBox = v end
})

VisualSection:AddToggle("ESPTracer", {
Title = "ESP Tracers",
Description = "Draw lines to players",
Default = true,
Callback = function(v) Settings.ESPTracer = v end
})

VisualSection:AddToggle("ESPName", {
Title = "ESP Names",
Description = "Show player names",
Default = true,
Callback = function(v) Settings.ESPName = v end
})

VisualSection:AddToggle("ESPHealth", {
Title = "ESP Health",
Description = "Show health bars",
Default = true,
Callback = function(v) Settings.ESPHealth = v end
})

VisualSection:AddToggle("ESPDistance", {
Title = "ESP Distance",
Description = "Show distance to players",
Default = true,
Callback = function(v) Settings.ESPDistance = v end
})

VisualSection:AddToggle("CoinESP", {
Title = "Coin ESP",
Description = "Highlight coins",
Default = true,
Callback = function(v) Settings.CoinESP = v end
})

VisualSection:AddToggle("GunESP", {
Title = "Gun Drop ESP",
Description = "Highlight gun drops",
Default = true,
Callback = function(v) Settings.GunESP = v end
})

local ColorSection = Tabs.Visuals:AddSection("Color Customization")
ColorSection:AddColorPicker("MurdererColor", {
Title = "Murderer Color",
Default = Color3.fromRGB(255, 0, 0),
Callback = function(v)
if not Settings.RainbowMode then Settings.MurdererColor = v end
end
})

ColorSection:AddColorPicker("SheriffColor", {
Title = "Sheriff Color",
Default = Color3.fromRGB(0, 150, 255),
Callback = function(v)
if not Settings.RainbowMode then Settings.SheriffColor = v end
end
})

ColorSection:AddColorPicker("InnocentColor", {
Title = "Innocent Color",
Default = Color3.fromRGB(0, 255, 0),
Callback = function(v)
if not Settings.RainbowMode then Settings.InnocentColor = v end
end
})

ColorSection:AddColorPicker("TracerColor", {
Title = "Tracer Color",
Default = Color3.fromRGB(180, 0, 255),
Callback = function(v)
if not Settings.RainbowMode then Settings.TracerColor = v end
end
})

ColorSection:AddToggle("RainbowMode", {
Title = "🌈 Rainbow Mode",
Description = "Dynamic rainbow colors",
Default = false,
Callback = function(v) Settings.RainbowMode = v end
})

ColorSection:AddSlider("RainbowSpeed", {
Title = "Rainbow Speed",
Description = "Speed of color cycling",
Default = 1,
Min = 1,
Max = 5,
Rounding = 1,
Callback = function(v) Settings.RainbowSpeed = v end
})

local VisualEffects = Tabs.Visuals:AddSection("Visual Effects")
VisualEffects:AddToggle("Wallhack", {
Title = "Wallhack",
Description = "See players through walls",
Default = false,
Callback = function(v) Settings.Wallhack = v end
})

VisualEffects:AddToggle("FullBright", {
Title = "FullBright",
Description = "Brighten the world",
Default = false,
Callback = function(v) Settings.FullBright = v end
})

VisualEffects:AddToggle("NoFog", {
Title = "No Fog",
Description = "Remove fog for better visibility",
Default = false,
Callback = function(v) Settings.NoFog = v end
})

VisualEffects:AddToggle("DisableYellowTint", {
Title = "Remove Yellow Tint",
Description = "Fix yellow screen effect",
Default = true,
Callback = function(v) Settings.DisableYellowTint = v end
})

VisualEffects:AddSlider("CamFOV", {
Title = "Camera FOV",
Description = "Field of view",
Default = 70,
Min = 50,
Max = 120,
Rounding = 1,
Callback = function(v) Settings.CamFOV = v end
})

-- ========== MOVEMENT TAB ==========
local MovementSection = Tabs.Movement:AddSection("Flight & Physics")
MovementSection:AddToggle("Flight", {
Title = "Flight",
Description = "Enable flight mode",
Default = false,
Callback = function(v) Settings.Flight = v end
})

MovementSection:AddSlider("FlySpeed", {
Title = "Fly Speed",
Description = "Speed while flying",
Default = 50,
Min = 10,
Max = 300,
Rounding = 5,
Callback = function(v) Settings.FlySpeed = v end
})

MovementSection:AddToggle("Noclip", {
Title = "Noclip",
Description = "Walk through walls",
Default = false,
Callback = function(v) Settings.Noclip = v end
})

local SpeedSection = Tabs.Movement:AddSection("Movement Modifiers")
SpeedSection:AddSlider("Speed", {
Title = "Walk Speed",
Description = "Player walk speed",
Default = 16,
Min = 16,
Max = 200,
Rounding = 1,
Callback = function(v) Settings.Speed = v end
})

SpeedSection:AddSlider("JumpPower", {
Title = "Jump Power",
Description = "Jump height",
Default = 50,
Min = 50,
Max = 200,
Rounding = 1,
Callback = function(v) Settings.JumpPower = v end
})

SpeedSection:AddToggle("InfiniteJump", {
Title = "Infinite Jump",
Description = "Jump infinitely",
Default = false,
Callback = function(v) Settings.InfiniteJump = v end
})

SpeedSection:AddToggle("Bhop", {
Title = "Bunny Hop",
Description = "Auto-jump while moving",
Default = false,
Callback = function(v) Settings.Bhop = v end
})

SpeedSection:AddToggle("Spinbot", {
Title = "Spinbot",
Description = "Spin automatically",
Default = false,
Callback = function(v) Settings.Spinbot = v end
})

SpeedSection:AddSlider("SpinSpeed", {
Title = "Spin Speed",
Description = "Speed of spinning",
Default = 20,
Min = 5,
Max = 50,
Rounding = 1,
Callback = function(v) Settings.SpinSpeed = v end
})

-- ========== MM2 MASTER TAB ==========
local FarmSection = Tabs.MM2:AddSection("Auto-Farm & Collect")
FarmSection:AddToggle("AutoFarm", {
Title = "Auto-Farm Coins",
Description = "Automatically collect coins",
Default = false,
Callback = function(v) Settings.AutoFarm = v end
})

FarmSection:AddSlider("FarmSpeed", {
Title = "Farm Speed",
Description = "Speed of coin collection",
Default = 25,
Min = 10,
Max = 50,
Rounding = 5,
Callback = function(v) Settings.FarmSpeed = v end
})

FarmSection:AddToggle("AutoGrabGun", {
Title = "Auto-Grab Gun",
Description = "Automatically pick up gun drops",
Default = false,
Callback = function(v) Settings.AutoGrabGun = v end
})

FarmSection:AddToggle("GunTeleport", {
Title = "Smart Gun Teleport",
Description = "TP to gun & return safely",
Default = false,
Callback = function(v) Settings.GunTeleport = v end
})

local CombatSectionMM2 = Tabs.MM2:AddSection("Combat Systems")
CombatSectionMM2:AddToggle("SilentAim", {
Title = "Silent Aim",
Description = "Lock camera to murderer",
Default = false,
Callback = function(v) Settings.SilentAim = v end
})

CombatSectionMM2:AddToggle("AutoShoot", {
Title = "Auto-Shoot",
Description = "Auto-shoot at murderer",
Default = false,
Callback = function(v) Settings.AutoShoot = v end
})

CombatSectionMM2:AddToggle("TrueSilentAim", {
Title = "True Silent Aim",
Description = "Shoot through walls at murderer",
Default = false,
Callback = function(v) Settings.TrueSilentAim = v end
})

CombatSectionMM2:AddToggle("KillAura", {
Title = "Kill Aura",
Description = "Auto-stab nearby players",
Default = false,
Callback = function(v) Settings.KillAura = v end
})

CombatSectionMM2:AddSlider("KillRadius", {
Title = "Kill Radius",
Description = "Radius for Kill Aura",
Default = 12,
Min = 1,
Max = 50,
Rounding = 1,
Callback = function(v) Settings.KillRadius = v end
})

local ProtectionSection = Tabs.MM2:AddSection("Protection")
ProtectionSection:AddToggle("AntiKnife", {
Title = "Anti-Knife",
Description = "Auto-avoid murderer",
Default = false,
Callback = function(v) Settings.AntiKnife = v end
})

ProtectionSection:AddToggle("AntiVoid", {
Title = "Anti-Void",
Description = "Prevent falling into void",
Default = false,
Callback = function(v) Settings.AntiVoid = v end
})

ProtectionSection:AddToggle("AntiFall", {
Title = "Anti-Fall Damage",
Description = "Prevent fall damage",
Default = false,
Callback = function(v) Settings.AntiFall = v end
})

ProtectionSection:AddToggle("AntiAFK", {
Title = "Anti-AFK",
Description = "Prevent AFK kick",
Default = false,
Callback = function(v) Settings.AntiAFK = v end
})

local ButtonsSection = Tabs.MM2:AddSection("Actions")
ButtonsSection:AddButton("Teleport to Gun", function()
local gunDrop = getGunDrop()
local char = LocalPlayer.Character
if gunDrop and char and char:FindFirstChild("HumanoidRootPart") then
local targetPart = gunDrop:IsA("Model") and (gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")) or (gunDrop:IsA("BasePart") and gunDrop or nil)
if targetPart then
char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
end
else
Library:Notify("Gun not found!", 3)
end
end)

ButtonsSection:AddButton("Kill All (Murderer)", function()
local char = LocalPlayer.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then return end

local knife = char:FindFirstChild("Knife") or (LocalPlayer.Backpack and LocalPlayer.Backpack:FindFirstChild("Knife"))  
if not knife then  
    Library:Notify("You don't have a knife!", 3)  
    return  
end  
  
if knife.Parent == LocalPlayer.Backpack then  
    char.Humanoid:EquipTool(knife)  
end  
  
task.spawn(function()  
    for _, v in pairs(Players:GetPlayers()) do  
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then  
            local targetHrp = v.Character.HumanoidRootPart  
            for i = 1, 3 do  
                char.HumanoidRootPart.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1.2)  
                if knife:FindFirstChild("Stab") then  
                    knife.Stab:FireServer()  
                end  
                if mouse1click then mouse1click() end  
                task.wait(0.05)  
            end  
        end  
    end  
    Library:Notify("Kill All executed!", 2)  
end)

end)

-- ========== SERVER TAB ==========
local ServerSection = Tabs.Server:AddSection("Server Management")
ServerSection:AddButton("Rejoin Server", function()
TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

ServerSection:AddButton("Server Hop", function()
local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
for _, s in pairs(servers) do
if s.playing < s.maxPlayers and s.id ~= game.JobId then
TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
break
end
end
end)

-- ========== CORE FUNCTIONALITY ==========

-- Flight System
local bodyVelocity, bodyGyro = nil, nil
local flightConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.Flight and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
local char = LocalPlayer.Character
local root = char.HumanoidRootPart

if not bodyVelocity then  
        bodyVelocity = Instance.new("BodyVelocity")  
        bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)  
        bodyVelocity.Parent = root  
    end  
    if not bodyGyro then  
        bodyGyro = Instance.new("BodyGyro")  
        bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)  
        bodyGyro.Parent = root  
        bodyGyro.P = 5000  
        bodyGyro.D = 500  
    end  
      
    local cam = workspace.CurrentCamera  
    local moveDir = Vector3.new(0,0,0)  
      
    local forward = cam.CFrame.LookVector  
    local right = cam.CFrame.RightVector  
    local up = cam.CFrame.UpVector  
      
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + forward end  
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - forward end  
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - right end  
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + right end  
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + up end  
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - up end  
      
    if moveDir.Magnitude > 0 then  
        moveDir = moveDir.Unit  
        bodyVelocity.Velocity = moveDir * Settings.FlySpeed  
        local targetCFrame = CFrame.lookAt(root.Position, root.Position + moveDir)  
        bodyGyro.CFrame = targetCFrame  
    else  
        bodyVelocity.Velocity = Vector3.new(0,0,0)  
    end  
else  
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end  
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end  
end

end))

-- Noclip
local noclipConnection = TrackConnection(RunService.Heartbeat:Connect(function()
local char = LocalPlayer.Character
if not char then return end

for _, part in pairs(char:GetDescendants()) do  
    if part:IsA("BasePart") then  
        if Settings.Noclip then  
            if OriginalState.HasSaved[part] == nil then  
                OriginalState.CanCollide[part] = part.CanCollide  
                OriginalState.HasSaved[part] = true  
            end  
            part.CanCollide = false  
        else  
            if OriginalState.HasSaved[part] then  
                part.CanCollide = OriginalState.CanCollide[part]  
                OriginalState.HasSaved[part] = nil  
            end  
        end  
    end  
end

end))

-- Movement Settings
local movementConnection = TrackConnection(RunService.Heartbeat:Connect(function()
local char = LocalPlayer.Character
if not char or not char:FindFirstChild("Humanoid") then return end
local hum = char.Humanoid

if Settings.Speed ~= 16 and hum.WalkSpeed ~= Settings.Speed then  
    hum.WalkSpeed = Settings.Speed  
elseif Settings.Speed == 16 and hum.WalkSpeed ~= 16 then  
    hum.WalkSpeed = 16  
end  
  
if Settings.JumpPower ~= 50 and hum.JumpPower ~= Settings.JumpPower then  
    hum.JumpPower = Settings.JumpPower  
elseif Settings.JumpPower == 50 and hum.JumpPower ~= 50 then  
    hum.JumpPower = 50  
end

end))

-- Infinite Jump
local jumpConnection = TrackConnection(UserInputService.JumpRequest:Connect(function()
if Settings.InfiniteJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
end
end))

-- Bhop
local bhopConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.Bhop and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
local hum = LocalPlayer.Character.Humanoid
if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
end
end))

-- Spinbot
local spinbotConnection = TrackConnection(RunService.RenderStepped:Connect(function()
if Settings.Spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0)
end
end))

-- Smooth FOV (Decoupled from Aimbot)
local fovConnection = TrackConnection(RunService.RenderStepped:Connect(function()
local cam = workspace.CurrentCamera
if Settings.SmoothFOV then
local current = cam.FieldOfView
local target = Settings.CamFOV
cam.FieldOfView = current + (target - current) * 0.1
else
cam.FieldOfView = Settings.CamFOV
end
end))

-- FullBright & NoFog
local lightingConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.FullBright then
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(255, 255, 255)
Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
else
Lighting.Brightness = OriginalState.Brightness or 1
Lighting.Ambient = OriginalState.Ambient or Color3.fromRGB(127, 127, 127)
Lighting.OutdoorAmbient = OriginalState.OutdoorAmbient or Color3.fromRGB(127, 127, 127)
end

if Settings.NoFog then  
    Lighting.FogEnd = 1e6  
else  
    Lighting.FogEnd = OriginalState.FogEnd or 10000  
end

end))

-- Yellow Tint Removal (Optimized throttling)
local ccCache = {}
local lastCCCheck = 0

local yellowTintConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if not Settings.DisableYellowTint then return end

local now = tick()  
if now - lastCCCheck > 1.5 then  
    lastCCCheck = now  
    ccCache = {}  
    for _, container in ipairs({Lighting, Workspace}) do  
        for _, v in ipairs(container:GetDescendants()) do  
            if v:IsA("ColorCorrectionEffect") then  
                table.insert(ccCache, v)  
            end  
        end  
    end  
end  
  
for _, v in ipairs(ccCache) do  
    if v and v.Parent then  
        local tint = v.TintColor  
        if tint and tint.R > 0.8 and tint.G > 0.7 and tint.B < 0.5 then  
            if not OriginalState.Effects[v] then  
                OriginalState.Effects[v] = {  
                    Enabled = v.Enabled,  
                    TintColor = tint,  
                    Brightness = v.Brightness,  
                    Saturation = v.Saturation,  
                    Contrast = v.Contrast,  
                    ClassName = "ColorCorrectionEffect",  
                }  
            end  
            v.TintColor = Color3.new(1, 1, 1)  
            v.Brightness = 0  
            v.Saturation = 0  
            v.Contrast = 0  
        end  
    end  
end

end))

-- Anti-AFK
local afkConnection = TrackConnection(LocalPlayer.Idled:Connect(function()
if Settings.AntiAFK then
local cam = workspace.CurrentCamera
VirtualUser:Button2Down(Vector2.new(0,0), cam.CFrame)
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0,0), cam.CFrame)
end
end))

-- Anti-Void
local voidConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.AntiVoid and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
if LocalPlayer.Character.HumanoidRootPart.Position.Y < -50 then
local spawn = getSpawnLocation()
if spawn then
LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
else
LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0)
end
end
end
end))

-- Anti-Fall
local fallConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.AntiFall and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
local hum = LocalPlayer.Character.Humanoid
if hum:GetState() == Enum.HumanoidStateType.FallingDown then
hum:ChangeState(Enum.HumanoidStateType.Landed)
end
end
end))

-- Hitbox Expander
local hitboxConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.HitboxExpander then
for _, plr in pairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and plr.Character then
local root = plr.Character:FindFirstChild("HumanoidRootPart")
if root then
if not OriginalState.HasSaved[root] then
OriginalState.Size[root] = root.Size
OriginalState.Transparency[root] = root.Transparency
OriginalState.HasSaved[root] = true
end
root.Size = Vector3.new(Settings.HitboxSize, Settings.HitboxSize, Settings.HitboxSize)
root.Transparency = 0.7
end
end
end
else
for part, val in pairs(OriginalState.Size) do
if part and part.Parent then
pcall(function() part.Size = val end)
OriginalState.HasSaved[part] = nil
end
end
for part, val in pairs(OriginalState.Transparency) do
if part and part.Parent then
pcall(function() part.Transparency = val end)
end
end
end
end))

-- Wallhack
local wallhackConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.Wallhack then
for _, plr in pairs(Players:GetPlayers()) do
if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("WIA_WH") then
local hl = Instance.new("Highlight")
hl.Name = "WIA_WH"
local color = Settings.InnocentColor
if getPlayerRole(plr) == "Murderer" then color = Settings.MurdererColor
elseif getPlayerRole(plr) == "Sheriff" then color = Settings.SheriffColor end
hl.FillColor = color
hl.FillTransparency = 0.3
hl.OutlineColor = Color3.fromRGB(255, 255, 255)
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
end))

-- Triggerbot
local triggerConnection = TrackConnection(RunService.RenderStepped:Connect(function()
if Settings.Triggerbot then
local target = Mouse.Target
if target and target.Parent then
local plr = Players:GetPlayerFromCharacter(target.Parent)
if plr and plr ~= LocalPlayer and mouse1click then
mouse1click()
end
end
end
end))

-- Aimbot
local aimbotConnection = TrackConnection(RunService.RenderStepped:Connect(function()
if Settings.Aimbot then
local cam = workspace.CurrentCamera
local closest = nil
local minDist = Settings.AimbotFOV

for _, plr in pairs(Players:GetPlayers()) do  
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then  
            local head = plr.Character.Head  
            local pos, onScreen = cam:WorldToScreenPoint(head.Position)  
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
        local currentCFrame = cam.CFrame  
        local newCFrame = CFrame.new(currentCFrame.Position, targetPos)  
          
        if Settings.Smoothness > 1 then  
            cam.CFrame = currentCFrame:Lerp(newCFrame, 1 / Settings.Smoothness)  
        else  
            cam.CFrame = newCFrame  
        end  
    end  
end

end))

-- ========== MM2 CORE SYSTEMS ==========

-- Smart Gun Teleport
local gunTeleportCooldown = false
local gunTeleportTimer = 0
local gunTeleportConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if not Settings.GunTeleport or gunTeleportCooldown then return end
if tick() - gunTeleportTimer < 1.5 then return end

local gunDrop = getGunDrop()  
local char = LocalPlayer.Character  
if gunDrop and char and char:FindFirstChild("HumanoidRootPart") then  
    local hrp = char.HumanoidRootPart  
    local currentPos = hrp.CFrame  
    local gunPart = gunDrop:IsA("Model") and (gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")) or (gunDrop:IsA("BasePart") and gunDrop or nil)  
      
    if gunPart then  
        gunTeleportCooldown = true  
        gunTeleportTimer = tick()  
          
        hrp.CFrame = gunPart.CFrame * CFrame.new(0, 1, 0)  
          
        if firetouchinterest then  
            pcall(function()  
                firetouchinterest(hrp, gunPart, 0)  
                firetouchinterest(hrp, gunPart, 1)  
            end)  
        end  
          
        hrp.CFrame = currentPos  
        gunTeleportCooldown = false  
    end  
end

end))

-- Auto-Grab Gun
local grabConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if not Settings.AutoGrabGun then return end

local gunDrop = getGunDrop()  
local char = LocalPlayer.Character  
if gunDrop and char and char:FindFirstChild("HumanoidRootPart") then  
    local hrp = char.HumanoidRootPart  
    local gunPart = gunDrop:IsA("Model") and (gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")) or (gunDrop:IsA("BasePart") and gunDrop or nil)  
      
    if gunPart then  
        local dist = (hrp.Position - gunPart.Position).Magnitude  
        if dist < 15 and dist > 3 then  
            hrp.CFrame = gunPart.CFrame + Vector3.new(0, 1, 0)  
            if firetouchinterest then  
                pcall(function()  
                    firetouchinterest(hrp, gunPart, 0)  
                    firetouchinterest(hrp, gunPart, 1)  
                end)  
            end  
        end  
    end  
end

end))

-- Auto-Farm Coins
local farmCooldown = 0
local farmConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if not Settings.AutoFarm then return end

local char = LocalPlayer.Character  
if char and char:FindFirstChild("HumanoidRootPart") and tick() - farmCooldown > 0.15 then  
    local coins = getCoins()  
    if #coins > 0 then  
        local nearest = nil  
        local minDist = math.huge  
        local hrp = char.HumanoidRootPart  
          
        for _, coin in pairs(coins) do  
            local dist = (hrp.Position - coin.Part.Position).Magnitude  
            if dist < minDist then  
                minDist = dist  
                nearest = coin  
            end  
        end  
          
        if nearest then  
            hrp.CFrame = nearest.Part.CFrame * CFrame.new(0, 1, 0)  
            farmCooldown = tick()  
        end  
    end  
end

end))

-- Anti-Knife
local antiknifeConnection = TrackConnection(RunService.Heartbeat:Connect(function()
if not Settings.AntiKnife then return end

local char = LocalPlayer.Character  
if char and char:FindFirstChild("HumanoidRootPart") then  
    for _, p in pairs(Players:GetPlayers()) do  
        if p ~= LocalPlayer and getPlayerRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then  
            local mHrp = p.Character.HumanoidRootPart  
            local dist = (char.HumanoidRootPart.Position - mHrp.Position).Magnitude  
              
            if dist < 12 then  
                local escapeDir = (char.HumanoidRootPart.Position - mHrp.Position).Unit  
                char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position + escapeDir * 15)  
            end  
        end  
    end  
end

end))

-- MM2 Combat Systems
local combatConnection = TrackConnection(RunService.RenderStepped:Connect(function()
local char = LocalPlayer.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then return end

local murdererChar = nil  
for _, p in pairs(Players:GetPlayers()) do  
    if p ~= LocalPlayer and getPlayerRole(p) == "Murderer" and p.Character then  
        murdererChar = p.Character  
        break  
    end  
end  
  
if Settings.SilentAim and murdererChar and murdererChar:FindFirstChild("Head") then  
    local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")  
    if hasGun then  
        local cam = workspace.CurrentCamera  
        cam.CFrame = CFrame.new(cam.CFrame.Position, murdererChar.Head.Position)  
    end  
end  
  
if Settings.AutoShoot and murdererChar and murdererChar:FindFirstChild("HumanoidRootPart") then  
    local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")  
    if hasGun then  
        local dist = (char.HumanoidRootPart.Position - murdererChar.HumanoidRootPart.Position).Magnitude  
        if dist < 60 and mouse1click then  
            mouse1click()  
        end  
    end  
end  
  
if Settings.KillAura then  
    local knife = char:FindFirstChild("Knife")  
    if knife then  
        for _, p in pairs(Players:GetPlayers()) do  
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then  
                local dist = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude  
                if dist < Settings.KillRadius then  
                    if knife:FindFirstChild("Stab") then   
                        knife.Stab:FireServer()   
                    end  
                    if mouse1click then mouse1click() end  
                end  
            end  
        end  
    end  
end

end))

-- True Silent Aim
if not ScriptState.OriginalMetatable then
local mt = getrawmetatable(game)
if mt then
ScriptState.OriginalMetatable = mt
ScriptState.OriginalNamecall = mt.__namecall
if setreadonly then setreadonly(mt, false) end

mt.__namecall = newcclosure(function(self, ...)  
        local method = getnamecallmethod and getnamecallmethod()  
        local args = {...}  
          
        if Settings.TrueSilentAim and tostring(self) == "ShootGun" and method == "InvokeServer" then  
            local murdererChar = nil  
            for _, p in pairs(Players:GetPlayers()) do  
                if p ~= LocalPlayer and getPlayerRole(p) == "Murderer" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then  
                    murdererChar = p.Character  
                    break  
                end  
            end  
              
            if murdererChar and murdererChar:FindFirstChild("HumanoidRootPart") then  
                args[1] = murdererChar.HumanoidRootPart.Position + (murdererChar.HumanoidRootPart.Velocity * 0.05)  
                return ScriptState.OriginalNamecall(self, unpack(args))  
            end  
        end  
          
        return ScriptState.OriginalNamecall(self, ...)  
    end)  
      
    if setreadonly then setreadonly(mt, true) end  
end

end

-- ========== TRUE 3D BOUNDING BOX ESP (OPTIMIZED) ==========
local espCache = {
Players = {},
Coins = {},
Gun = nil,
Timestamp = 0,
CacheTime = 0.08,
}

-- Single pass 3D Bounding Box Calculation
local function GetTrueBoundingBox(character, cam)
local minX, maxX = math.huge, -math.huge
local minY, maxY = math.huge, -math.huge
local hasValidPoints = false

for _, part in ipairs(character:GetDescendants()) do  
    if part:IsA("BasePart") then  
        local size = part.Size  
        local cframe = part.CFrame  
        local right = cframe.RightVector * (size.X / 2)  
        local up = cframe.UpVector * (size.Y / 2)  
        local look = cframe.LookVector * (size.Z / 2)  
          
        local corners = {  
            cframe.Position - right - up - look,  
            cframe.Position + right - up - look,  
            cframe.Position - right + up - look,  
            cframe.Position + right + up - look,  
            cframe.Position - right - up + look,  
            cframe.Position + right - up + look,  
            cframe.Position - right + up + look,  
            cframe.Position + right + up + look,  
        }  
          
        for i = 1, 8 do  
            local pos, onScreen = cam:WorldToViewportPoint(corners[i])  
            if onScreen then  
                hasValidPoints = true  
                local x, y = pos.X, pos.Y  
                if x < minX then minX = x end  
                if x > maxX then maxX = x end  
                if y < minY then minY = y end  
                if y > maxY then maxY = y end  
            end  
        end  
    end  
end  
  
if not hasValidPoints then return nil end  
  
local padding = 2  
return {minX - padding, minY - padding, maxX + padding, maxY + padding}

end

local hue = 0
local espConnection = TrackConnection(RunService.RenderStepped:Connect(function()
local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize
local camPos = cam.CFrame.Position

-- Update cache  
local currentTime = tick()  
if currentTime - espCache.Timestamp > espCache.CacheTime then  
    espCache.Timestamp = currentTime  
    espCache.Players = {}  
    for _, plr in pairs(Players:GetPlayers()) do  
        if plr ~= LocalPlayer and plr.Character then  
            local root = plr.Character:FindFirstChild("HumanoidRootPart")  
            local hum = plr.Character:FindFirstChild("Humanoid")  
            if root and hum and hum.Health > 0 then  
                table.insert(espCache.Players, plr)  
            end  
        end  
    end  
    espCache.Coins = getCoins()  
    espCache.Gun = getGunDrop()  
end  
  
ClearDrawings()  
  
-- Rainbow colors  
local rMurderer = Settings.MurdererColor  
local rSheriff = Settings.SheriffColor  
local rInnocent = Settings.InnocentColor  
local rTracer = Settings.TracerColor  
  
if Settings.RainbowMode then  
    hue = (hue + 0.01 * Settings.RainbowSpeed) % 1  
    rMurderer = Color3.fromHSV(hue, 1, 1)  
    rSheriff = Color3.fromHSV((hue + 0.33) % 1, 1, 1)  
    rInnocent = Color3.fromHSV((hue + 0.66) % 1, 1, 1)  
    rTracer = Color3.fromHSV((hue + 0.5) % 1, 1, 1)  
end  
  
-- ESP for players  
for _, plr in pairs(espCache.Players) do  
    local root = plr.Character.HumanoidRootPart  
    local hum = plr.Character:FindFirstChild("Humanoid")  
    if root and hum then  
        local bbox = GetTrueBoundingBox(plr.Character, cam)  
        if bbox then  
            local role = getPlayerRole(plr)  
            local color = rInnocent  
            if role == "Murderer" then color = rMurderer  
            elseif role == "Sheriff" then color = rSheriff end  
              
            local dist = (root.Position - camPos).Magnitude  
            local x1, y1, x2, y2 = bbox[1], bbox[2], bbox[3], bbox[4]  
            local centerX, centerY = (x1 + x2) / 2, (y1 + y2) / 2  
              
            -- ESP Box  
            if Settings.ESPBox then  
                local l1 = GetDrawingLine()  
                if l1 then l1.From = Vector2.new(x1, y1) l1.To = Vector2.new(x2, y1) l1.Color = color l1.Thickness = 2 l1.Transparency = 1 end  
                local l2 = GetDrawingLine()  
                if l2 then l2.From = Vector2.new(x2, y1) l2.To = Vector2.new(x2, y2) l2.Color = color l2.Thickness = 2 l2.Transparency = 1 end  
                local l3 = GetDrawingLine()  
                if l3 then l3.From = Vector2.new(x2, y2) l3.To = Vector2.new(x1, y2) l3.Color = color l3.Thickness = 2 l3.Transparency = 1 end  
                local l4 = GetDrawingLine()  
                if l4 then l4.From = Vector2.new(x1, y2) l4.To = Vector2.new(x1, y1) l4.Color = color l4.Thickness = 2 l4.Transparency = 1 end  
            end  
              
            -- ESP Tracer  
            if Settings.ESPTracer then  
                local tracer = GetDrawingLine()  
                if tracer then  
                    tracer.From = Vector2.new(viewport.X / 2, viewport.Y)  
                    tracer.To = Vector2.new(centerX, centerY)  
                    tracer.Color = rTracer  
                    tracer.Thickness = 1.5  
                    tracer.Transparency = 0.7  
                end  
            end  
              
            -- Text Info  
            if Settings.ESPName or Settings.ESPHealth or Settings.ESPDistance then  
                local textObj = GetDrawingText()  
                if textObj then  
                    local txt = ""  
                    if Settings.ESPName then txt = txt .. plr.Name .. " " end  
                    if Settings.ESPHealth and hum then   
                        local maxHp = math.max(hum.MaxHealth, 1)  
                        local hp = math.clamp(math.floor(hum.Health), 0, maxHp)  
                        txt = txt .. "[" .. hp .. "HP] "   
                    end  
                    if Settings.ESPDistance then txt = txt .. "(" .. math.floor(dist) .. "m)" end  
                      
                    textObj.Position = Vector2.new(centerX, y1 - 15)  
                    textObj.Text = txt  
                    textObj.Size = 13  
                    textObj.Center = true  
                    textObj.Outline = true  
                    textObj.Color = Color3.fromRGB(255, 255, 255)  
                end  
            end  
              
            -- Health Bar (Zero-Division Safe)  
            if Settings.ESPHealth and hum then  
                local maxHp = math.max(hum.MaxHealth, 1)  
                local healthPercent = math.clamp(hum.Health / maxHp, 0, 1)  
                local barX, barY = x1, y2 + 2  
                local barWidth = math.max(x2 - x1, 20)  
                  
                local bg = GetDrawingLine()  
                if bg then  
                    bg.From = Vector2.new(barX, barY)  
                    bg.To = Vector2.new(barX + barWidth, barY)  
                    bg.Color = Color3.fromRGB(30, 30, 30)  
                    bg.Thickness = 4  
                    bg.Transparency = 0.8  
                end  
                  
                local hp = GetDrawingLine()  
                if hp then  
                    hp.From = Vector2.new(barX, barY)  
                    hp.To = Vector2.new(barX + (barWidth * healthPercent), barY)  
                    hp.Color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthPercent)  
                    hp.Thickness = 4  
                    hp.Transparency = 1  
                end  
            end  
        end  
    end  
end  
  
-- Coin ESP  
if Settings.CoinESP then  
    for _, coin in pairs(espCache.Coins) do  
        local pos, onScreen = cam:WorldToViewportPoint(coin.Part.Position)  
        if onScreen then  
            local textObj = GetDrawingText()  
            if textObj then  
                textObj.Position = Vector2.new(pos.X, pos.Y)  
                textObj.Text = "$"  
                textObj.Size = 20  
                textObj.Center = true  
                textObj.Outline = true  
                textObj.Color = Color3.fromRGB(255, 215, 0)  
            end  
        end  
    end  
end  
  
-- Gun Drop ESP  
if Settings.GunESP and espCache.Gun then  
    local gunPart = espCache.Gun:IsA("Model") and (espCache.Gun.PrimaryPart or espCache.Gun:FindFirstChildWhichIsA("BasePart")) or (espCache.Gun:IsA("BasePart") and espCache.Gun or nil)  
    if gunPart then  
        local pos, onScreen = cam:WorldToViewportPoint(gunPart.Position)  
        if onScreen then  
            local textObj = GetDrawingText()  
            if textObj then  
                textObj.Position = Vector2.new(pos.X, pos.Y - 20)  
                textObj.Text = "GUN"  
                textObj.Size = 14  
                textObj.Center = true  
                textObj.Outline = true  
                textObj.Color = Color3.fromRGB(255, 255, 0)  
            end  
        end  
    end  
end

end))

-- ========== SAVE MANAGER ==========
SaveManager:SetLibrary(Library)
InterfaceManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})
InterfaceManager:SetFolder("WIAHub")
SaveManager:SetFolder("WIAHub/saves")

SaveManager:BuildConfigSection(Tabs.Server)
InterfaceManager:BuildInterfaceSection(Tabs.Server)

SaveManager:LoadAutoloadConfig()

-- ========== FULL CLEANUP SYSTEM ==========
local function FullCleanup()
if ScriptState.CleanupFlag then return end
ScriptState.CleanupFlag = true

CleanupConnections()  
CleanupDrawings()  
  
if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end  
if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end  
  
RestoreLightingState()  
RestoreCharacterState(LocalPlayer.Character)  
  
for _, plr in pairs(Players:GetPlayers()) do  
    if plr.Character then  
        for _, v in pairs(plr.Character:GetChildren()) do  
            if v.Name:find("WIA") or v.Name:find("MM2") then  
                v:Destroy()  
            end  
        end  
    end  
end  
  
ScriptState.CleanupFlag = false

end

-- Auto-cleanup triggers
TrackConnection(LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
if not LocalPlayer.Parent then
task.spawn(FullCleanup)
end
end))

-- Override the library close function
if Window.Close then
local oldClose = Window.Close
Window.Close = function(...)
FullCleanup()
return oldClose(...)
end
end

-- ========== INITIALIZATION COMPLETE ==========
Library:Notify({
Title = "WIA HUB v11.0.1",
Content = "Fully Patched & Optimized",
Duration = 4
})

print("WIA HUB v11.0.1 Loaded Successfully! All identified edge-cases resolved.")

