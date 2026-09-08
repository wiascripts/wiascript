-- ================================================================= --
-- WIA HUB v11.0.1 OPTIMIZED :: MURDER MYSTERY 2 MASTER
-- XENO COMPATIBLE | FULL FUNCTIONALITY | RAYFIELD UI
-- ================================================================= --

-- ========== 1. SAFE ENVIRONMENT & EXECUTOR CHECKS ==========
local isDrawingSupported = pcall(function() return typeof(Drawing) == "table" and Drawing.new end)
local hasTouchInterest = typeof(firetouchinterest) == "function"
local hasMetaTableSupport = typeof(getrawmetatable) == "function" and typeof(setreadonly) == "function" and typeof(newcclosure) == "function"

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local function SafeGetCamera()
return Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end

local function SafeClick()
if typeof(mouse1click) == "function" then
pcall(mouse1click)
else
VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 1)
task.wait(0.02)
VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 1)
end
end

local function SafeTouch(hrp, targetPart)
if not hrp or not targetPart then return end
if hasTouchInterest then
pcall(function()
firetouchinterest(hrp, targetPart, 0)
task.wait(0.01)
firetouchinterest(hrp, targetPart, 1)
end)
else
hrp.CFrame = targetPart.CFrame
end
end

-- ========== 2. UPVALUE DECLARATIONS (FIX SCOPE & CLEANUP) ==========
local bodyVelocity = nil
local bodyGyro = nil
local ccCache = {}
local lastCCCheck = 0

-- Script & Cleanup State
local ScriptState = {
IsRunning = true,
Connections = {},
OriginalMetatable = nil,
OriginalNamecall = nil,
IsCleaningUp = false,
CleanupFlag = false,
}

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

-- Settings State
local Settings = {
Theme = "Default",
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

-- ========== 3. DRAWING POOL (SAFE FOR XENO) ==========
local DrawingPool = {
Lines = {},
Texts = {},
}

local function GetDrawingLine()
if not isDrawingSupported then return nil end
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
if not isDrawingSupported then return nil end
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
for _, d in pairs(DrawingPool.Lines) do d.Visible = false end
for _, d in pairs(DrawingPool.Texts) do d.Visible = false end
end

local function CleanupDrawings()
for _, d in pairs(DrawingPool.Lines) do pcall(function() d:Remove() end) end
for _, d in pairs(DrawingPool.Texts) do pcall(function() d:Remove() end) end
DrawingPool.Lines = {}
DrawingPool.Texts = {}
end

-- ========== 4. STATE SAVE & RESTORE ==========
local function TrackConnection(connection)
if not ScriptState.IsRunning then return nil end
table.insert(ScriptState.Connections, connection)
return connection
end

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
local hum = character:FindFirstChildOfClass("Humanoid")
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
local hum = character:FindFirstChildOfClass("Humanoid")
if hum then
if OriginalState.WalkSpeed[hum] ~= nil then
pcall(function() hum.WalkSpeed = OriginalState.WalkSpeed[hum] end)
end
if OriginalState.JumpPower[hum] ~= nil then
pcall(function() hum.JumpPower = OriginalState.JumpPower[hum] end)
end
end
end

local function SaveLightingState()
OriginalState.Brightness = Lighting.Brightness
OriginalState.Ambient = Lighting.Ambient
OriginalState.OutdoorAmbient = Lighting.OutdoorAmbient
OriginalState.FogEnd = Lighting.FogEnd
OriginalState.GlobalShadows = Lighting.GlobalShadows
OriginalState.Technology = Lighting.Technology

OriginalState.Effects = {}    
local function saveEffectContainer(container)    
    if not container then return end  
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
if LocalPlayer.Character then SaveCharacterState(LocalPlayer.Character) end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function(newChar)
OriginalState.HasSaved = {}
OriginalState.CanCollide = {}
OriginalState.Size = {}
OriginalState.Transparency = {}
OriginalState.WalkSpeed = {}
OriginalState.JumpPower = {}

task.wait(0.1)    
SaveCharacterState(newChar)    
local cam = SafeGetCamera()  
if cam then  
    OriginalState.CameraFOV = cam.FieldOfView  
end

end))

-- ========== 5. FULL CLEANUP SYSTEM ==========
local function FullCleanup()
if ScriptState.CleanupFlag then return end
ScriptState.CleanupFlag = true

ScriptState.IsRunning = false  
for _, conn in pairs(ScriptState.Connections) do  
    pcall(function() conn:Disconnect() end)  
end  
ScriptState.Connections = {}  

if ScriptState.OriginalMetatable and ScriptState.OriginalNamecall then    
    pcall(function()    
        local mt = getrawmetatable(game)    
        if mt then mt.__namecall = ScriptState.OriginalNamecall end    
    end)    
end  

CleanupDrawings()    
    
if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end    
if bodyGyro then pcall(function() bodyGyro:Destroy() end) bodyGyro = nil end    
    
RestoreLightingState()    
if LocalPlayer.Character then  
    RestoreCharacterState(LocalPlayer.Character)    
end  
    
for _, plr in pairs(Players:GetPlayers()) do    
    if plr.Character then    
        for _, v in pairs(plr.Character:GetChildren()) do    
            if v.Name:find("WIA") or v.Name:find("MM2") then    
                pcall(function() v:Destroy() end)    
            end    
        end    
    end    
end    
    
ScriptState.CleanupFlag = false

end

-- ========== 6. MM2 ROLE & WORLD HELPERS ==========
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

local function getSpawnLocation()
local spawn = Workspace:FindFirstChild("SpawnLocation")
if not spawn then
for _, obj in pairs(Workspace:GetChildren()) do
if obj:IsA("SpawnLocation") then return obj end
end
end
return spawn
end

-- ========== 7. RAYFIELD GUI SETUP ==========
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
Name = "WIA HUB v11.0.1 | MM2 Master",
LoadingTitle = "WIA HUB v11.0.1",
LoadingSubtitle = "by whitewia",
ConfigurationSaving = { Enabled = false },
Discord = { Enabled = false },
KeySystem = false,
})

local Tabs = {
Combat = Window:CreateTab("Combat", 4483362458),
Visuals = Window:CreateTab("Visuals", 4483362458),
Movement = Window:CreateTab("Movement", 4483362458),
MM2 = Window:CreateTab("MM2 Master", 4483362458),
Server = Window:CreateTab("Server", 4483362458)
}

-- Combat Tab
Tabs.Combat:CreateSection("Aimbot & Combat")

Tabs.Combat:CreateToggle({
Name = "Aimbot", CurrentValue = false, Flag = "Aimbot",
Callback = function(v) Settings.Aimbot = v end
})

Tabs.Combat:CreateSlider({
Name = "Aimbot FOV", Range = {10, 400}, Increment = 1, Suffix = "px", CurrentValue = 90, Flag = "AimbotFOV",
Callback = function(v) Settings.AimbotFOV = v end
})

Tabs.Combat:CreateSlider({
Name = "Smoothness", Range = {1, 20}, Increment = 1, Suffix = "", CurrentValue = 5, Flag = "Smoothness",
Callback = function(v) Settings.Smoothness = v end
})

Tabs.Combat:CreateToggle({
Name = "Triggerbot", CurrentValue = false, Flag = "Triggerbot",
Callback = function(v) Settings.Triggerbot = v end
})

Tabs.Combat:CreateSection("Hitbox Expander")

Tabs.Combat:CreateToggle({
Name = "Hitbox Expander", CurrentValue = false, Flag = "HitboxExpander",
Callback = function(v) Settings.HitboxExpander = v end
})

Tabs.Combat:CreateSlider({
Name = "Hitbox Size", Range = {2, 20}, Increment = 1, Suffix = " studs", CurrentValue = 5, Flag = "HitboxSize",
Callback = function(v) Settings.HitboxSize = v end
})

-- Visuals Tab
Tabs.Visuals:CreateSection("ESP Settings")

Tabs.Visuals:CreateToggle({
Name = "ESP Boxes", CurrentValue = true, Flag = "ESPBox",
Callback = function(v) Settings.ESPBox = v end
})

Tabs.Visuals:CreateToggle({
Name = "ESP Tracers", CurrentValue = true, Flag = "ESPTracer",
Callback = function(v) Settings.ESPTracer = v end
})

Tabs.Visuals:CreateToggle({
Name = "ESP Names", CurrentValue = true, Flag = "ESPName",
Callback = function(v) Settings.ESPName = v end
})

Tabs.Visuals:CreateToggle({
Name = "ESP Health", CurrentValue = true, Flag = "ESPHealth",
Callback = function(v) Settings.ESPHealth = v end
})

Tabs.Visuals:CreateToggle({
Name = "ESP Distance", CurrentValue = true, Flag = "ESPDistance",
Callback = function(v) Settings.ESPDistance = v end
})

Tabs.Visuals:CreateToggle({
Name = "Coin ESP", CurrentValue = true, Flag = "CoinESP",
Callback = function(v) Settings.CoinESP = v end
})

Tabs.Visuals:CreateToggle({
Name = "Gun Drop ESP", CurrentValue = true, Flag = "GunESP",
Callback = function(v) Settings.GunESP = v end
})

Tabs.Visuals:CreateSection("Color Customization")

Tabs.Visuals:CreateColorPicker({
Name = "Murderer Color", Color = Color3.fromRGB(255, 0, 0), Flag = "MurdererColor",
Callback = function(v) if not Settings.RainbowMode then Settings.MurdererColor = v end end
})

Tabs.Visuals:CreateColorPicker({
Name = "Sheriff Color", Color = Color3.fromRGB(0, 150, 255), Flag = "SheriffColor",
Callback = function(v) if not Settings.RainbowMode then Settings.SheriffColor = v end end
})

Tabs.Visuals:CreateColorPicker({
Name = "Innocent Color", Color = Color3.fromRGB(0, 255, 0), Flag = "InnocentColor",
Callback = function(v) if not Settings.RainbowMode then Settings.InnocentColor = v end end
})

Tabs.Visuals:CreateColorPicker({
Name = "Tracer Color", Color = Color3.fromRGB(180, 0, 255), Flag = "TracerColor",
Callback = function(v) if not Settings.RainbowMode then Settings.TracerColor = v end end
})

Tabs.Visuals:CreateToggle({
Name = "🌈 Rainbow Mode", CurrentValue = false, Flag = "RainbowMode",
Callback = function(v) Settings.RainbowMode = v end
})

Tabs.Visuals:CreateSlider({
Name = "Rainbow Speed", Range = {1, 5}, Increment = 1, Suffix = "x", CurrentValue = 1, Flag = "RainbowSpeed",
Callback = function(v) Settings.RainbowSpeed = v end
})

Tabs.Visuals:CreateSection("Visual Effects")

Tabs.Visuals:CreateToggle({
Name = "Wallhack", CurrentValue = false, Flag = "Wallhack",
Callback = function(v) Settings.Wallhack = v end
})

Tabs.Visuals:CreateToggle({
Name = "FullBright", CurrentValue = false, Flag = "FullBright",
Callback = function(v) Settings.FullBright = v end
})

Tabs.Visuals:CreateToggle({
Name = "No Fog", CurrentValue = false, Flag = "NoFog",
Callback = function(v) Settings.NoFog = v end
})

Tabs.Visuals:CreateToggle({
Name = "Remove Yellow Tint", CurrentValue = true, Flag = "DisableYellowTint",
Callback = function(v) Settings.DisableYellowTint = v end
})

Tabs.Visuals:CreateSlider({
Name = "Camera FOV", Range = {50, 120}, Increment = 1, Suffix = "°", CurrentValue = 70, Flag = "CamFOV",
Callback = function(v) Settings.CamFOV = v end
})

-- Movement Tab
Tabs.Movement:CreateSection("Flight & Physics")

Tabs.Movement:CreateToggle({
Name = "Flight", CurrentValue = false, Flag = "Flight",
Callback = function(v) Settings.Flight = v end
})

Tabs.Movement:CreateSlider({
Name = "Fly Speed", Range = {10, 300}, Increment = 5, Suffix = " studs/s", CurrentValue = 50, Flag = "FlySpeed",
Callback = function(v) Settings.FlySpeed = v end
})

Tabs.Movement:CreateToggle({
Name = "Noclip", CurrentValue = false, Flag = "Noclip",
Callback = function(v) Settings.Noclip = v end
})

Tabs.Movement:CreateSection("Movement Modifiers")

Tabs.Movement:CreateSlider({
Name = "Walk Speed", Range = {16, 200}, Increment = 1, Suffix = " studs/s", CurrentValue = 16, Flag = "Speed",
Callback = function(v) Settings.Speed = v end
})

Tabs.Movement:CreateSlider({
Name = "Jump Power", Range = {50, 200}, Increment = 1, Suffix = "", CurrentValue = 50, Flag = "JumpPower",
Callback = function(v) Settings.JumpPower = v end
})

Tabs.Movement:CreateToggle({
Name = "Infinite Jump", CurrentValue = false, Flag = "InfiniteJump",
Callback = function(v) Settings.InfiniteJump = v end
})

Tabs.Movement:CreateToggle({
Name = "Bunny Hop", CurrentValue = false, Flag = "Bhop",
Callback = function(v) Settings.Bhop = v end
})

Tabs.Movement:CreateToggle({
Name = "Spinbot", CurrentValue = false, Flag = "Spinbot",
Callback = function(v) Settings.Spinbot = v end
})

Tabs.Movement:CreateSlider({
Name = "Spin Speed", Range = {5, 50}, Increment = 1, Suffix = " deg", CurrentValue = 20, Flag = "SpinSpeed",
Callback = function(v) Settings.SpinSpeed = v end
})

-- MM2 Master Tab
Tabs.MM2:CreateSection("Auto-Farm & Collect")

Tabs.MM2:CreateToggle({
Name = "Auto-Farm Coins", CurrentValue = false, Flag = "AutoFarm",
Callback = function(v) Settings.AutoFarm = v end
})

Tabs.MM2:CreateSlider({
Name = "Farm Speed", Range = {10, 50}, Increment = 5, Suffix = " delay", CurrentValue = 25, Flag = "FarmSpeed",
Callback = function(v) Settings.FarmSpeed = v end
})

Tabs.MM2:CreateToggle({
Name = "Auto-Grab Gun", CurrentValue = false, Flag = "AutoGrabGun",
Callback = function(v) Settings.AutoGrabGun = v end
})

Tabs.MM2:CreateToggle({
Name = "Smart Gun Teleport", CurrentValue = false, Flag = "GunTeleport",
Callback = function(v) Settings.GunTeleport = v end
})

Tabs.MM2:CreateSection("Combat Systems")

Tabs.MM2:CreateToggle({
Name = "Silent Aim", CurrentValue = false, Flag = "SilentAim",
Callback = function(v) Settings.SilentAim = v end
})

Tabs.MM2:CreateToggle({
Name = "Auto-Shoot", CurrentValue = false, Flag = "AutoShoot",
Callback = function(v) Settings.AutoShoot = v end
})

Tabs.MM2:CreateToggle({
Name = "True Silent Aim", CurrentValue = false, Flag = "TrueSilentAim",
Callback = function(v) Settings.TrueSilentAim = v end
})

Tabs.MM2:CreateToggle({
Name = "Kill Aura", CurrentValue = false, Flag = "KillAura",
Callback = function(v) Settings.KillAura = v end
})

Tabs.MM2:CreateSlider({
Name = "Kill Radius", Range = {1, 50}, Increment = 1, Suffix = " studs", CurrentValue = 12, Flag = "KillRadius",
Callback = function(v) Settings.KillRadius = v end
})

Tabs.MM2:CreateSection("Protection")

Tabs.MM2:CreateToggle({
Name = "Anti-Knife", CurrentValue = false, Flag = "AntiKnife",
Callback = function(v) Settings.AntiKnife = v end
})

Tabs.MM2:CreateToggle({
Name = "Anti-Void", CurrentValue = false, Flag = "AntiVoid",
Callback = function(v) Settings.AntiVoid = v end
})

Tabs.MM2:CreateToggle({
Name = "Anti-Fall Damage", CurrentValue = false, Flag = "AntiFall",
Callback = function(v) Settings.AntiFall = v end
})

Tabs.MM2:CreateToggle({
Name = "Anti-AFK", CurrentValue = false, Flag = "AntiAFK",
Callback = function(v) Settings.AntiAFK = v end
})

Tabs.MM2:CreateSection("Actions")

Tabs.MM2:CreateButton({
Name = "Teleport to Gun",
Callback = function()
local gunDrop = getGunDrop()
local char = LocalPlayer.Character
if gunDrop and char and char:FindFirstChild("HumanoidRootPart") then
local targetPart = gunDrop:IsA("Model") and (gunDrop.PrimaryPart or gunDrop:FindFirstChildWhichIsA("BasePart")) or (gunDrop:IsA("BasePart") and gunDrop or nil)
if targetPart then
char.HumanoidRootPart.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0)
end
else
Rayfield:Notify({ Title = "Error", Content = "Gun not found!", Duration = 3, Image = 4483362458 })
end
end,
})

Tabs.MM2:CreateButton({
Name = "Kill All (Murderer)",
Callback = function()
local char = LocalPlayer.Character
if not char or not char:FindFirstChild("HumanoidRootPart") then return end

local knife = char:FindFirstChild("Knife") or (LocalPlayer:FindFirstChild("Backpack") and LocalPlayer.Backpack:FindFirstChild("Knife"))    
    if not knife then    
        Rayfield:Notify({ Title = "Error", Content = "You don't have a knife!", Duration = 3, Image = 4483362458 })  
        return    
    end    
        
    local hum = char:FindFirstChildOfClass("Humanoid")  
    if knife.Parent == LocalPlayer:FindFirstChild("Backpack") and hum then    
        hum:EquipTool(knife)    
    end    
        
    task.spawn(function()    
        for _, v in pairs(Players:GetPlayers()) do    
            if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChildOfClass("Humanoid") and v.Character:FindFirstChildOfClass("Humanoid").Health > 0 then    
                local targetHrp = v.Character.HumanoidRootPart    
                for i = 1, 3 do    
                    if char and char:FindFirstChild("HumanoidRootPart") then  
                        char.HumanoidRootPart.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 1.2)    
                    end  
                    if knife:FindFirstChild("Stab") then    
                        knife.Stab:FireServer()    
                    end    
                    SafeClick()  
                    task.wait(0.05)    
                end    
            end    
        end    
        Rayfield:Notify({ Title = "Success", Content = "Kill All executed!", Duration = 2, Image = 4483362458 })  
    end)  
end,

})

-- Server Tab
Tabs.Server:CreateSection("Server Management")

Tabs.Server:CreateButton({
Name = "Rejoin Server",
Callback = function()
TeleportService:Teleport(game.PlaceId, LocalPlayer)
end,
})

Tabs.Server:CreateButton({
Name = "Server Hop",
Callback = function()
local success, result = pcall(function()
return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
end)
if success and result then
for _, s in pairs(result) do
if s.playing < s.maxPlayers and s.id ~= game.JobId then
TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
break
end
end
end
end,
})

-- ========== 8. CORE MECHANICS & LOOPS ==========

-- Flight
TrackConnection(RunService.Heartbeat:Connect(function()
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
        
    local cam = SafeGetCamera()  
    if not cam then return end  

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
        bodyGyro.CFrame = CFrame.lookAt(root.Position, root.Position + moveDir)    
    else    
        bodyVelocity.Velocity = Vector3.new(0,0,0)    
    end    
else    
    if bodyVelocity then pcall(function() bodyVelocity:Destroy() end) bodyVelocity = nil end    
    if bodyGyro then pcall(function() bodyGyro:Destroy() end) bodyGyro = nil end    
end

end))

-- Noclip
TrackConnection(RunService.Heartbeat:Connect(function()
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

-- Speed / JumpPower
TrackConnection(RunService.Heartbeat:Connect(function()
local char = LocalPlayer.Character
if not char then return end
local hum = char:FindFirstChildOfClass("Humanoid")
if not hum then return end

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
TrackConnection(UserInputService.JumpRequest:Connect(function()
if Settings.InfiniteJump and LocalPlayer.Character then
local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end
end))

-- Bhop
TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.Bhop and LocalPlayer.Character then
local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum and hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
end
end))

-- Spinbot
TrackConnection(RunService.RenderStepped:Connect(function()
if Settings.Spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.SpinSpeed), 0)
end
end))

-- Smooth FOV
TrackConnection(RunService.RenderStepped:Connect(function()
local cam = SafeGetCamera()
if not cam then return end
if Settings.SmoothFOV then
local current = cam.FieldOfView
local target = Settings.CamFOV
cam.FieldOfView = current + (target - current) * 0.1
else
cam.FieldOfView = Settings.CamFOV
end
end))

-- FullBright & NoFog
TrackConnection(RunService.Heartbeat:Connect(function()
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

-- Remove Yellow Tint
TrackConnection(RunService.Heartbeat:Connect(function()
if not Settings.DisableYellowTint then return end

local now = tick()    
if now - lastCCCheck > 1.5 then    
    lastCCCheck = now    
    ccCache = {}    
    for _, container in ipairs({Lighting, Workspace}) do    
        if container then  
            for _, v in ipairs(container:GetDescendants()) do    
                if v:IsA("ColorCorrectionEffect") then table.insert(ccCache, v) end    
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
                    Enabled = v.Enabled, TintColor = tint, Brightness = v.Brightness,    
                    Saturation = v.Saturation, Contrast = v.Contrast, ClassName = "ColorCorrectionEffect",    
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
TrackConnection(LocalPlayer.Idled:Connect(function()
if Settings.AntiAFK then
local cam = SafeGetCamera()
if cam then
VirtualUser:Button2Down(Vector2.new(0,0), cam.CFrame)
task.wait(1)
VirtualUser:Button2Up(Vector2.new(0,0), cam.CFrame)
end
end
end))

-- Anti-Void
TrackConnection(RunService.Heartbeat:Connect(function()
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
TrackConnection(RunService.Heartbeat:Connect(function()
if Settings.AntiFall and LocalPlayer.Character then
local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
if hum and hum:GetState() == Enum.HumanoidStateType.FallingDown then
hum:ChangeState(Enum.HumanoidStateType.Landed)
end
end
end))

-- Hitbox Expander
TrackConnection(RunService.Heartbeat:Connect(function()
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
TrackConnection(RunService.Heartbeat:Connect(function()
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
pcall(function() plr.Character.WIA_WH:Destroy() end)
end
end
end
end))

-- Triggerbot
TrackConnection(RunService.RenderStepped:Connect(function()
if Settings.Triggerbot then
local target = Mouse.Target
if target and target.Parent then
local plr = Players:GetPlayerFromCharacter(target.Parent)
if plr and plr ~= LocalPlayer then
SafeClick()
end
end
end
end))

-- Aimbot
TrackConnection(RunService.RenderStepped:Connect(function()
if Settings.Aimbot then
local cam = SafeGetCamera()
if not cam then return end

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

-- ========== 9. MM2 AUTOMATION MODULES ==========

-- Smart Gun Teleport
local gunTeleportCooldown = false
local gunTeleportTimer = 0
TrackConnection(RunService.Heartbeat:Connect(function()
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
        SafeTouch(hrp, gunPart)  
        hrp.CFrame = currentPos    
        gunTeleportCooldown = false    
    end    
end

end))

-- Auto-Grab Gun
TrackConnection(RunService.Heartbeat:Connect(function()
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
            SafeTouch(hrp, gunPart)  
        end    
    end    
end

end))

-- Auto-Farm Coins
local farmCooldown = 0
TrackConnection(RunService.Heartbeat:Connect(function()
if not Settings.AutoFarm then return end

local delayTime = (Settings.FarmSpeed or 25) / 100  
local char = LocalPlayer.Character    
if char and char:FindFirstChild("HumanoidRootPart") and tick() - farmCooldown > delayTime then    
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
            SafeTouch(hrp, nearest.Part)  
            farmCooldown = tick()    
        end    
    end    
end

end))

-- Anti-Knife
TrackConnection(RunService.Heartbeat:Connect(function()
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

-- Combat Systems
TrackConnection(RunService.RenderStepped:Connect(function()
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
        local cam = SafeGetCamera()    
        if cam then cam.CFrame = CFrame.new(cam.CFrame.Position, murdererChar.Head.Position) end  
    end    
end    
    
if Settings.AutoShoot and murdererChar and murdererChar:FindFirstChild("HumanoidRootPart") then    
    local hasGun = char:FindFirstChild("Gun") or char:FindFirstChild("Revolver")    
    if hasGun then    
        local dist = (char.HumanoidRootPart.Position - murdererChar.HumanoidRootPart.Position).Magnitude    
        if dist < 60 then SafeClick() end    
    end    
end    
    
if Settings.KillAura then    
    local knife = char:FindFirstChild("Knife")    
    if knife then    
        for _, p in pairs(Players:GetPlayers()) do    
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then    
                local dist = (char.HumanoidRootPart.Position - p.Character.HumanoidRootPart.Position).Magnitude    
                if dist < Settings.KillRadius then    
                    if knife:FindFirstChild("Stab") then knife.Stab:FireServer() end    
                    SafeClick()  
                end    
            end    
        end    
    end    
end

end))

-- True Silent Aim Hook
if hasMetaTableSupport and not ScriptState.OriginalMetatable then
pcall(function()
local mt = getrawmetatable(game)
if mt then
ScriptState.OriginalMetatable = mt
ScriptState.OriginalNamecall = mt.__namecall
setreadonly(mt, false)

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
            
        setreadonly(mt, true)    
    end  
end)

end

-- ========== 10. 3D BOUNDING BOX ESP SYSTEM ==========
local espCache = {
Players = {},
Coins = {},
Gun = nil,
Timestamp = 0,
CacheTime = 0.08,
}

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
TrackConnection(RunService.RenderStepped:Connect(function()
if not isDrawingSupported then return end
local cam = SafeGetCamera()
if not cam then return end
local viewport = cam.ViewportSize
local camPos = cam.CFrame.Position

local currentTime = tick()    
if currentTime - espCache.Timestamp > espCache.CacheTime then    
    espCache.Timestamp = currentTime    
    espCache.Players = {}    
    for _, plr in pairs(Players:GetPlayers()) do    
        if plr ~= LocalPlayer and plr.Character then    
            local root = plr.Character:FindFirstChild("HumanoidRootPart")    
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")    
            if root and hum and hum.Health > 0 then    
                table.insert(espCache.Players, plr)    
            end    
        end    
    end    
    espCache.Coins = getCoins()    
    espCache.Gun = getGunDrop()    
end    
    
ClearDrawings()    
    
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
    
for _, plr in pairs(espCache.Players) do    
    if plr.Character then  
        local root = plr.Character:FindFirstChild("HumanoidRootPart")    
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")    
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
end    
    
if Settings.CoinESP then    
    for _, coin in pairs(espCache.Coins) do    
        if coin.Part and coin.Part.Parent then  
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
end    
    
if Settings.GunESP and espCache.Gun then    
    local gunPart = espCache.Gun:IsA("Model") and (espCache.Gun.PrimaryPart or espCache.Gun:FindFirstChildWhichIsA("BasePart")) or (espCache.Gun:IsA("BasePart") and espCache.Gun or nil)    
    if gunPart and gunPart.Parent then    
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

TrackConnection(LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
if not LocalPlayer.Parent then task.spawn(FullCleanup) end
end))

Rayfield:Notify({
Title = "WIA HUB v11.0.1",
Content = "Loaded Successfully for Xeno!",
Duration = 4,
Image = 4483362458,
})

print("WIA HUB v11.0.1 Full Build Executed!")