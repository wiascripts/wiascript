-- [[ Rayfield UI Integration for white wia hub ]] --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "white wia hub",
   LoadingTitle = "white wia hub",
   LoadingSubtitle = "by whitewia",
   ConfigurationSaving = {
      Enabled = false,
   },
   Discord = {
      Enabled = false,
   },
   KeySystem = false
})

-- // Constants \\ --

-- [ Services ] --
local Services = setmetatable({}, {__index = function(Self, Index)
local NewService = game.GetService(game, Index)
if NewService then
Self[Index] = NewService
end
return NewService
end})

-- [ Modules ] --
--[[
local OrnamentalMouse = loadstring(game:HttpGet("https://raw.githubusercontent.com/iHavoc101/Genesis-Studios/main/Modules/OrnamentalMouse.lua", true))().new()
OrnamentalMouse.Sensitivity = 0.9
OrnamentalMouse.AutoUpdate = false
]]

-- [ LocalPlayer ] --
local LocalPlayer = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ Weapon Names ] --
local WeaponNames = {
   Knife = {
Index = "Murderer";
Color = Color3.fromRGB(255, 0, 0)
};
Gun = {
Index = "Sheriff";
Color = Color3.fromRGB(0, 0, 255)
};
}

local AttackAnimations = {
   "rbxassetid://2467567750";
   "rbxassetid://1957618848";
   "rbxassetid://2470501967";
   "rbxassetid://2467577524";
}

-- // Variables \\ --
-- [ Roles ] --
local Roles = {
   Murderer = nil;
   Sheriff = nil;
   Closest = nil;
}

local ESPInstances = {}
local ESPToggle = true

local SilentAIMEnabled = true

-- [ Character ] --
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
LocalPlayer.CharacterAdded:Connect(function(Character)
Character = Character
Humanoid = Character:WaitForChild("Humanoid")
end)

-- [ Raycast Parameters ] --
local RaycastParameters = RaycastParams.new()
RaycastParameters.IgnoreWater = true
RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
RaycastParameters.FilterDescendantsInstances = {LocalPlayer.Character}

-- // Functions \\ --
-- [ Main ] --
local Functions = {}

-- ESP --
function Functions.ESP(Part, Color)
   if Part:FindFirstChildOfClass('BoxHandleAdornment') then
       return Part:FindFirstChildOfClass('BoxHandleAdornment')
   end

   local Box = Instance.new("BoxHandleAdornment")
   Box.Size = Part.Size + Vector3.new(0.1, 0.1, 0.1)
   Box.Name = "Mesh"
   Box.Visible = ESPToggle
   Box.Adornee = Part
   Box.Color3 = Color
   Box.AlwaysOnTop = true
   Box.ZIndex = 5
   Box.Transparency = 0.5
   Box.Parent = Part

   table.insert(ESPInstances, Box)

   return Box
end

-- Notify Roles --
function Functions.NotifyRoles()
   if Roles.Murderer then
       -- Murderer --
       local Image, Ready = Services.Players:GetUserThumbnailAsync(Roles.Murderer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
       Services.StarterGui:SetCore("SendNotification", {
           Title = 'Murderer';
           Text = Roles.Murderer.Name;
           Icon = Image;
           Duration = 5;
       })
   end

   if Roles.Sheriff then
       -- Sheriff --
       local Image, Ready = Services.Players:GetUserThumbnailAsync(Roles.Sheriff.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
       Services.StarterGui:SetCore("SendNotification", {
           Title = 'Sheriff';
           Text = Roles.Sheriff.Name;
           Icon = Image;
           Duration = 5;
       })
   end
end

-- GetClosestPlayer --
function Functions.GetClosestPlayer(MaxDistance)
   local ClosestPlayer = nil
   local FarthestDistance = MaxDistance or math.huge

   for i, v in ipairs(Services.Players.GetPlayers(Services.Players)) do
       if v ~= LocalPlayer then
           pcall(function()
               local DistanceFromPlayer = (LocalPlayer.Character.PrimaryPart.Position - v.Character.PrimaryPart.Position).Magnitude
               if DistanceFromPlayer < FarthestDistance then
                   FarthestDistance = DistanceFromPlayer
                   ClosestPlayer = v
               end
           end)
       end
   end

   return ClosestPlayer
end

-- [ Event ] --
local EventFunctions = {}

function EventFunctions.Initialize(Player)
   local function CharacterAdded(Character)
       Player:WaitForChild("Backpack").ChildAdded:Connect(function(Child)
           local Role = WeaponNames[Child.Name]
           if Role then
Roles[Role.Index] = Player

               local Cham = Functions.ESP(Player.Character.HumanoidRootPart, Role.Color)

               local Animator = Player.Character:FindFirstChildWhichIsA("Humanoid"):WaitForChild("Animator")
               Animator.AnimationPlayed:Connect(function(AnimationTrack)
                   if (AnimationTrack and AnimationTrack.Animation) == nil then
                       return
                   end

                   if table.find(AttackAnimations, AnimationTrack.Animation.AnimationId) then
                       Cham.Color3 = Color3.fromRGB(255, 0, 255)

                       while true do
                           Services.RunService.Heartbeat:Wait(0.01)
                           local PlayingAnimations = Animator:GetPlayingAnimationTracks()
                           local StillAttacking = false
                           for i,v in ipairs(PlayingAnimations) do
                               if table.find(AttackAnimations, v.Animation.AnimationId) then
                                   StillAttacking = true
                               end
                           end
                           if StillAttacking == false then
                               break
                           end
                       end

                       Cham.Color3 = Role.Color
                   end
               end)
           end
       end)
   end

   CharacterAdded(Player.Character or Player.CharacterAdded:Wait())
   Player.CharacterAdded:Connect(CharacterAdded)
end

function EventFunctions.GunAdded(Child)
   if Child.Name == "GunDrop" then
       Functions.ESP(Child, Color3.fromRGB(255, 255, 255))
   end
end

function EventFunctions.ContextActionService_C(actionName, InputState, inputObject)
if InputState == Enum.UserInputState.End then
return
   end
   
   Functions.NotifyRoles()
end

function EventFunctions.ContextActionService_V(actionName, InputState, inputObject)
if InputState == Enum.UserInputState.End then
return
   end

   if Humanoid.WalkSpeed == 16.5 or Humanoid.WalkSpeed == 16 then
Humanoid.WalkSpeed = 20
else
Humanoid.WalkSpeed = 16.5
   end

   Services.StarterGui:SetCore("SendNotification", {
Title = 'Speed Change';
Text = tostring(Humanoid.WalkSpeed);
Duration = 3;
})
end

function EventFunctions.ContextActionService_B(actionName, InputState, inputObject)
if InputState == Enum.UserInputState.End then
return
   end

   ESPToggle = not ESPToggle
   for i,v in ipairs(ESPInstances) do
       v.Visible = ESPToggle
       if v.Parent == nil then
           table.remove(ESPInstances, i)
       end
   end
end

function EventFunctions.ContextActionService_G(actionName, InputState, inputObject)
   if InputState == Enum.UserInputState.End then
return
   end
   SilentAIMEnabled = not SilentAIMEnabled
   Services.StarterGui:SetCore("SendNotification", {
Title = 'Silent Aim';
Text = "Enabled: " .. tostring(SilentAIMEnabled);
Duration = 3;
})
end

-- // Metatable \\ --
local RawMetatable = getrawmetatable(game)
local OldNameCall = RawMetatable.__namecall
setreadonly(RawMetatable, false)

RawMetatable.__namecall = newcclosure(function(Object, ...)
   local NamecallMethod = getnamecallmethod()
   local Arguments = {...}

   if SilentAIMEnabled == true then
       RaycastParameters.FilterDescendantsInstances = {LocalPlayer.Character}
       if NamecallMethod == "FireServer" and tostring(Object) == "Throw" then
           local Success, Error = pcall(function()
               local Closest = Functions.GetClosestPlayer()
               local PrimaryPart = Closest.Character.PrimaryPart
               local Velocity = PrimaryPart.AssemblyLinearVelocity * Vector3.new(1, 0, 1)
               local Magnitude = (PrimaryPart.Position - LocalPlayer.Character.PrimaryPart.Position).Magnitude
               local Prediction = Velocity * 0.5 * Magnitude / 100
               local Result = workspace.Raycast(workspace, LocalPlayer.Character.PrimaryPart.Position, (PrimaryPart.Position - (LocalPlayer.Character.PrimaryPart.Position + Prediction)).Unit * 200, RaycastParameters)
               Arguments[2] = Result.Position
           end)
           if not Success then
               warn(Error)
           end
       elseif NamecallMethod == "InvokeServer" and tostring(Object) == "ShootGun" and Roles.Murderer then
           local Success, Error = pcall(function()
               local PrimaryPart = Roles.Murderer.Character.PrimaryPart
               local Prediction = PrimaryPart.AssemblyLinearVelocity / 40
               if math.abs(PrimaryPart.AssemblyLinearVelocity.Y) < 10 then
                   Arguments[2] = PrimaryPart.Position + Prediction
               else
                   return "Nullify Remote"
               end
           end)
           if not Success then
               warn(Error)
           elseif Success == "Nullify Remote" then
               warn("Null")
               return
           end
       end
   end

   return OldNameCall(Object, unpack(Arguments))
end)

setreadonly(RawMetatable, true)

-- // Event Listeners \\ --
for i,v in ipairs(Services.Players:GetPlayers()) do
EventFunctions.Initialize(v)
end
Services.Players.PlayerAdded:Connect(EventFunctions.Initialize)

workspace.ChildAdded:Connect(EventFunctions.GunAdded)

-- [ Binds ] --
Services.ContextActionService:BindAction('SprintBind', EventFunctions.ContextActionService_V, false, Enum.KeyCode.V)
Services.ContextActionService:BindAction('NotifyBind', EventFunctions.ContextActionService_C, false, Enum.KeyCode.C)
Services.ContextActionService:BindAction('ESPBind', EventFunctions.ContextActionService_B, false, Enum.KeyCode.B)
Services.ContextActionService:BindAction('AIMBind', EventFunctions.ContextActionService_G, false, Enum.KeyCode.G)

-- // Rayfield UI Controls \\ --

local MainTab = Window:CreateTab("Main Features", 4483362458)

local ESPToggleUI = MainTab:CreateToggle({
   Name = "ESP Toggle (Bind: B)",
   CurrentValue = ESPToggle,
   Flag = "ESPToggleFlag",
   Callback = function(Value)
      ESPToggle = Value
      for i,v in ipairs(ESPInstances) do
          v.Visible = ESPToggle
      end
   end,
})

local SilentAimToggleUI = MainTab:CreateToggle({
   Name = "Silent Aim (Bind: G)",
   CurrentValue = SilentAIMEnabled,
   Flag = "SilentAimFlag",
   Callback = function(Value)
      SilentAIMEnabled = Value
   end,
})

MainTab:CreateButton({
   Name = "Toggle Speed / Sprint (Bind: V)",
   Callback = function()
      EventFunctions.ContextActionService_V("SprintBind", Enum.UserInputState.Begin, nil)
   end,
})

MainTab:CreateButton({
   Name = "Notify Roles (Bind: C)",
   Callback = function()
      Functions.NotifyRoles()
   end,
})

-- =================================================================
-- ADDITIONAL ATTACHED SCRIPT (Main.lua)
-- =================================================================

--[[
    Murder Mystery 2 Script
    Version: 3.2.1
    Keyless • Free • Auto-Update
    
    Features:
    - Role ESP
    - Auto Farm Coins
    - Silent Aim
    - Kill All (Murderer)
    - God Mode
    - Fly / Noclip
    - Speed / Jump
    - Auto Collect
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ===================== CONFIG =====================
local Config = {
    ESP = {
        Enabled = false,
        ShowMurderer = true,
        ShowSheriff = true,
        ShowInnocent = true,
        ShowDistance = true,
        TeamCheck = false
    },
    AutoFarm = {
        Enabled = false,
        CollectCoins = true,
        CollectWeapons = true
    },
    Combat = {
        SilentAim = false,
        KillAll = false,
        GodMode = false,
        InfiniteAmmo = false
    },
    Movement = {
        Fly = false,
        Noclip = false,
        Speed = 16,
        JumpPower = 50
    },
    Visuals = {
        FullBright = false,
        NoFog = false
    }
}

-- ===================== UI LIBRARY (simple) =====================
local Library = {}
Library.__index = Library

function Library.new()
    local self = setmetatable({}, Library)
    
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "MM2ScriptHub"
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.Parent = game:GetService("CoreGui")
    
    self.Main = Instance.new("Frame")
    self.Main.Name = "Main"
    self.Main.Size = UDim2.new(0, 480, 0, 360)
    self.Main.Position = UDim2.new(0.5, -240, 0.5, -180)
    self.Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    self.Main.BorderSizePixel = 0
    self.Main.Active = true
    self.Main.Draggable = true
    self.Main.Parent = self.ScreenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = self.Main
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(180, 40, 40)
    stroke.Thickness = 1.5
    stroke.Parent = self.Main
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = self.Main
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = titleBar
    
    local titleFix = Instance.new("Frame")
    titleFix.Size = UDim2.new(1, 0, 0, 15)
    titleFix.Position = UDim2.new(0, 0, 1, -15)
    titleFix.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    titleFix.BorderSizePixel = 0
    titleFix.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "🔪 MM2 Script  •  v3.2.1"
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.Parent = titleBar
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        self.ScreenGui:Destroy()
    end)
    
    -- Tabs
    self.TabContainer = Instance.new("Frame")
    self.TabContainer.Size = UDim2.new(0, 120, 1, -50)
    self.TabContainer.Position = UDim2.new(0, 10, 0, 50)
    self.TabContainer.BackgroundTransparency = 1
    self.TabContainer.Parent = self.Main
    
    self.Content = Instance.new("Frame")
    self.Content.Size = UDim2.new(1, -150, 1, -60)
    self.Content.Position = UDim2.new(0, 140, 0, 50)
    self.Content.BackgroundTransparency = 1
    self.Content.Parent = self.Main
    
    self.Tabs = {}
    self.CurrentTab = nil
    
    return self
end

function Library:CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(1, 0, 0, 36)
    tabBtn.Position = UDim2.new(0, 0, 0, (#self.Tabs) * 42)
    tabBtn.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    tabBtn.Text = name
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Font = Enum.Font.Gotham
    tabBtn.TextSize = 13
    tabBtn.Parent = self.TabContainer
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 6)
    tabCorner.Parent = tabBtn
    
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.Visible = false
    page.Parent = self.Content
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = page
    
    local tab = {
        Button = tabBtn,
        Page = page,
        Name = name
    }
    
    table.insert(self.Tabs, tab)
    
    tabBtn.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    
    if #self.Tabs == 1 then
        self:SelectTab(tab)
    end
    
    return page
end

function Library:SelectTab(tab)
    for _, t in ipairs(self.Tabs) do
        t.Page.Visible = false
        t.Button.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        t.Button.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
    tab.Page.Visible = true
    tab.Button.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    tab.Button.TextColor3 = Color3.new(1, 1, 1)
    self.CurrentTab = tab
end

function Library:CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.Font = Enum.Font.Gotham
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame
    
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 42, 0, 22)
    toggle.Position = UDim2.new(1, -50, 0.5, -11)
    toggle.BackgroundColor3 = default and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(50, 50, 60)
    toggle.Text = ""
    toggle.Parent = frame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggle
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.new(1, 1, 1)
    circle.Parent = toggle
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = circle
    
    local state = default
    
    toggle.MouseButton1Click:Connect(function()
        state = not state
        toggle.BackgroundColor3 = state and Color3.fromRGB(180, 40, 40) or Color3.fromRGB(50, 50, 60)
        circle.Position = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        if callback then
            callback(state)
        end
    end)
    
    return frame
end

function Library:CreateLabel(parent, text)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -10, 0, 24)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(160, 160, 170)
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

-- ===================== CREATE UI =====================
local UI = Library.new()

local combatTab = UI:CreateTab("Combat")
local espTab = UI:CreateTab("ESP")
local farmTab = UI:CreateTab("Farm")
local moveTab = UI:CreateTab("Movement")
local miscTab = UI:CreateTab("Misc")

-- Combat
UI:CreateLabel(combatTab, "Combat Features")
UI:CreateToggle(combatTab, "Silent Aim", false, function(v) Config.Combat.SilentAim = v end)
UI:CreateToggle(combatTab, "Kill All (Murderer)", false, function(v) Config.Combat.KillAll = v end)
UI:CreateToggle(combatTab, "God Mode", false, function(v) Config.Combat.GodMode = v end)
UI:CreateToggle(combatTab, "Infinite Ammo", false, function(v) Config.Combat.InfiniteAmmo = v end)

-- ESP
UI:CreateLabel(espTab, "Role ESP")
UI:CreateToggle(espTab, "Enable ESP", false, function(v) Config.ESP.Enabled = v end)
UI:CreateToggle(espTab, "Show Murderer", true, function(v) Config.ESP.ShowMurderer = v end)
UI:CreateToggle(espTab, "Show Sheriff", true, function(v) Config.ESP.ShowSheriff = v end)
UI:CreateToggle(espTab, "Show Innocents", true, function(v) Config.ESP.ShowInnocent = v end)
UI:CreateToggle(espTab, "Show Distance", true, function(v) Config.ESP.ShowDistance = v end)

-- Farm
UI:CreateLabel(farmTab, "Auto Farm")
UI:CreateToggle(farmTab, "Enable Auto Farm", false, function(v) Config.AutoFarm.Enabled = v end)
UI:CreateToggle(farmTab, "Collect Coins", true, function(v) Config.AutoFarm.CollectCoins = v end)
UI:CreateToggle(farmTab, "Auto Collect Weapons", true, function(v) Config.AutoFarm.CollectWeapons = v end)

-- Movement
UI:CreateLabel(moveTab, "Movement")
UI:CreateToggle(moveTab, "Fly", false, function(v) Config.Movement.Fly = v end)
UI:CreateToggle(moveTab, "Noclip", false, function(v) Config.Movement.Noclip = v end)

-- Misc
UI:CreateLabel(miscTab, "Visuals & Misc")
UI:CreateToggle(miscTab, "FullBright", false, function(v)
    Config.Visuals.FullBright = v
    if v then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1000
        Lighting.GlobalShadows = true
    end
end)

UI:CreateLabel(miscTab, " ")
UI:CreateLabel(miscTab, "Status: Loaded successfully")
UI:CreateLabel(miscTab, "Executor: " .. (identifyexecutor and identifyexecutor() or "Unknown"))

-- ===================== FEATURE LOGIC (stubs / safe examples) =====================

-- Simple FullBright already handled above

-- Noclip example
RunService.Stepped:Connect(function()
    if Config.Movement.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Notification
local function Notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 4
        })
    end)
end

Notify("MM2 Script", "Loaded successfully! Keyless • v3.2.1")

print("[MM2 Script] Successfully loaded!")
print("[MM2 Script] Open the GUI and toggle the features you need.")
print("[MM2 Script] Remember: use responsibly and on alt accounts.")

-- =================================================================
-- ADDITIONAL LOADER SCRIPT (Loader.lua)
-- =================================================================

--[[
    Murder Mystery 2 Script Loader
    Keyless • Free • PC Only
    
    Copy this into your executor while in Murder Mystery 2
]]

local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YOUR_USERNAME/mm2-script/main/scripts/main.lua"))()
end)

if not success then
    warn("[MM2 Script] Failed to load:", err)
    warn("Make sure you are in Murder Mystery 2 and your executor supports HttpGet.")
end
