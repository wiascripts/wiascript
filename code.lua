-- [[ Rayfield UI Integration — Combined Script ]] --

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "white wia hub | MM2",
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

-- ===================== CONSTANTS & SERVICES =====================

local Services = setmetatable({}, {__index = function(Self, Index)
    local NewService = game.GetService(game, Index)
    if NewService then
        Self[Index] = NewService
    end
    return NewService
end})

local Players = Services.Players or game:GetService("Players")
local RunService = Services.RunService or game:GetService("RunService")
local UserInputService = Services.UserInputService or game:GetService("UserInputService")
local TweenService = Services.TweenService or game:GetService("TweenService")
local ReplicatedStorage = Services.ReplicatedStorage or game:GetService("ReplicatedStorage")
local Lighting = Services.Lighting or game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- [ Weapon Names & Anims ] --
local WeaponNames = {
   Knife = {
      Index = "Murderer",
      Color = Color3.fromRGB(255, 0, 0)
   },
   Gun = {
      Index = "Sheriff",
      Color = Color3.fromRGB(0, 0, 255)
   }
}

local AttackAnimations = {
   "rbxassetid://2467567750",
   "rbxassetid://1957618848",
   "rbxassetid://2470501967",
   "rbxassetid://2467577524"
}

-- ===================== CONFIG & VARIABLES =====================

local Roles = {
   Murderer = nil,
   Sheriff = nil,
   Closest = nil
}

local ESPInstances = {}

local Config = {
    ESP = {
        Enabled = true,
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
        SilentAim = true,
        KillAll = false,
        GodMode = false,
        InfiniteAmmo = false
    },
    Movement = {
        Fly = false,
        Noclip = false,
        Speed = 16.5,
        JumpPower = 50
    },
    Visuals = {
        FullBright = false,
        NoFog = false
    }
}

-- [ Character ] --
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")

LocalPlayer.CharacterAdded:Connect(function(Char)
    Character = Char
    Humanoid = Char:WaitForChild("Humanoid")
end)

-- [ Raycast Parameters ] --
local RaycastParameters = RaycastParams.new()
RaycastParameters.IgnoreWater = true
RaycastParameters.FilterType = Enum.RaycastFilterType.Blacklist
RaycastParameters.FilterDescendantsInstances = {LocalPlayer.Character}

-- ===================== CORE FUNCTIONS =====================

local Functions = {}

-- ESP --
function Functions.ESP(Part, Color)
   if Part:FindFirstChildOfClass('BoxHandleAdornment') then
       return Part:FindFirstChildOfClass('BoxHandleAdornment')
   end

   local Box = Instance.new("BoxHandleAdornment")
   Box.Size = Part.Size + Vector3.new(0.1, 0.1, 0.1)
   Box.Name = "Mesh"
   Box.Visible = Config.ESP.Enabled
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
       local Image, Ready = Players:GetUserThumbnailAsync(Roles.Murderer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
       Services.StarterGui:SetCore("SendNotification", {
           Title = 'Murderer',
           Text = Roles.Murderer.Name,
           Icon = Image,
           Duration = 5
       })
   end

   if Roles.Sheriff then
       local Image, Ready = Players:GetUserThumbnailAsync(Roles.Sheriff.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
       Services.StarterGui:SetCore("SendNotification", {
           Title = 'Sheriff',
           Text = Roles.Sheriff.Name,
           Icon = Image,
           Duration = 5
       })
   end
end

-- GetClosestPlayer --
function Functions.GetClosestPlayer(MaxDistance)
   local ClosestPlayer = nil
   local FarthestDistance = MaxDistance or math.huge

   for i, v in ipairs(Players:GetPlayers()) do
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

-- ===================== EVENT HANDLERS =====================

local EventFunctions = {}

function EventFunctions.Initialize(Player)
   local function CharacterAdded(Char)
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
                           RunService.Heartbeat:Wait(0.01)
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
   if InputState == Enum.UserInputState.End then return end
   Functions.NotifyRoles()
end

function EventFunctions.ContextActionService_V(actionName, InputState, inputObject)
   if InputState == Enum.UserInputState.End then return end

   if Humanoid.WalkSpeed == 16.5 or Humanoid.WalkSpeed == 16 then
       Humanoid.WalkSpeed = 20
   else
       Humanoid.WalkSpeed = 16.5
   end

   Services.StarterGui:SetCore("SendNotification", {
       Title = 'Speed Change',
       Text = tostring(Humanoid.WalkSpeed),
       Duration = 3
   })
end

function EventFunctions.ContextActionService_B(actionName, InputState, inputObject)
   if InputState == Enum.UserInputState.End then return end

   Config.ESP.Enabled = not Config.ESP.Enabled
   for i,v in ipairs(ESPInstances) do
       v.Visible = Config.ESP.Enabled
       if v.Parent == nil then
           table.remove(ESPInstances, i)
       end
   end
end

function EventFunctions.ContextActionService_G(actionName, InputState, inputObject)
   if InputState == Enum.UserInputState.End then return end
   Config.Combat.SilentAim = not Config.Combat.SilentAim
   Services.StarterGui:SetCore("SendNotification", {
       Title = 'Silent Aim',
       Text = "Enabled: " .. tostring(Config.Combat.SilentAim),
       Duration = 3
   })
end

-- ===================== METATABLE HOOKS =====================

local RawMetatable = getrawmetatable(game)
local OldNameCall = RawMetatable.__namecall
setreadonly(RawMetatable, false)

RawMetatable.__namecall = newcclosure(function(Object, ...)
   local NamecallMethod = getnamecallmethod()
   local Arguments = {...}

   if Config.Combat.SilentAim == true then
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

-- ===================== BACKGROUND LOOPS =====================

-- Noclip Loop
RunService.Stepped:Connect(function()
    if Config.Movement.Noclip and LocalPlayer.Character then
        for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- Initialize Listeners
for i,v in ipairs(Players:GetPlayers()) do
    EventFunctions.Initialize(v)
end
Players.PlayerAdded:Connect(EventFunctions.Initialize)
workspace.ChildAdded:Connect(EventFunctions.GunAdded)

-- Key Binds Setup
Services.ContextActionService:BindAction('SprintBind', EventFunctions.ContextActionService_V, false, Enum.KeyCode.V)
Services.ContextActionService:BindAction('NotifyBind', EventFunctions.ContextActionService_C, false, Enum.KeyCode.C)
Services.ContextActionService:BindAction('ESPBind', EventFunctions.ContextActionService_B, false, Enum.KeyCode.B)
Services.ContextActionService:BindAction('AIMBind', EventFunctions.ContextActionService_G, false, Enum.KeyCode.G)

-- ===================== RAYFIELD UI INTEGRATION =====================

-- 1. Main Tab
local MainTab = Window:CreateTab("Main / Combat", 4483362458)

MainTab:CreateToggle({
   Name = "Silent Aim (Bind: G)",
   CurrentValue = Config.Combat.SilentAim,
   Flag = "SilentAimFlag",
   Callback = function(Value)
      Config.Combat.SilentAim = Value
   end,
})

MainTab:CreateToggle({
   Name = "Kill All (Murderer)",
   CurrentValue = Config.Combat.KillAll,
   Flag = "KillAllFlag",
   Callback = function(Value)
      Config.Combat.KillAll = Value
   end,
})

MainTab:CreateToggle({
   Name = "God Mode",
   CurrentValue = Config.Combat.GodMode,
   Flag = "GodModeFlag",
   Callback = function(Value)
      Config.Combat.GodMode = Value
   end,
})

MainTab:CreateToggle({
   Name = "Infinite Ammo",
   CurrentValue = Config.Combat.InfiniteAmmo,
   Flag = "InfAmmoFlag",
   Callback = function(Value)
      Config.Combat.InfiniteAmmo = Value
   end,
})

MainTab:CreateButton({
   Name = "Notify Roles (Bind: C)",
   Callback = function()
      Functions.NotifyRoles()
   end,
})

-- 2. ESP Tab
local ESPTab = Window:CreateTab("ESP Features", 4483362458)

ESPTab:CreateToggle({
   Name = "ESP Toggle (Bind: B)",
   CurrentValue = Config.ESP.Enabled,
   Flag = "ESPToggleFlag",
   Callback = function(Value)
      Config.ESP.Enabled = Value
      for i,v in ipairs(ESPInstances) do
          v.Visible = Config.ESP.Enabled
      end
   end,
})

ESPTab:CreateToggle({
   Name = "Show Murderer",
   CurrentValue = Config.ESP.ShowMurderer,
   Flag = "ShowMurdFlag",
   Callback = function(Value)
      Config.ESP.ShowMurderer = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Show Sheriff",
   CurrentValue = Config.ESP.ShowSheriff,
   Flag = "ShowSheriffFlag",
   Callback = function(Value)
      Config.ESP.ShowSheriff = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Show Innocents",
   CurrentValue = Config.ESP.ShowInnocent,
   Flag = "ShowInnoFlag",
   Callback = function(Value)
      Config.ESP.ShowInnocent = Value
   end,
})

ESPTab:CreateToggle({
   Name = "Show Distance",
   CurrentValue = Config.ESP.ShowDistance,
   Flag = "ShowDistFlag",
   Callback = function(Value)
      Config.ESP.ShowDistance = Value
   end,
})

-- 3. Auto Farm Tab
local FarmTab = Window:CreateTab("Auto Farm", 4483362458)

FarmTab:CreateToggle({
   Name = "Enable Auto Farm",
   CurrentValue = Config.AutoFarm.Enabled,
   Flag = "AutoFarmFlag",
   Callback = function(Value)
      Config.AutoFarm.Enabled = Value
   end,
})

FarmTab:CreateToggle({
   Name = "Collect Coins",
   CurrentValue = Config.AutoFarm.CollectCoins,
   Flag = "CollectCoinsFlag",
   Callback = function(Value)
      Config.AutoFarm.CollectCoins = Value
   end,
})

FarmTab:CreateToggle({
   Name = "Auto Collect Weapons",
   CurrentValue = Config.AutoFarm.CollectWeapons,
   Flag = "CollectWeapFlag",
   Callback = function(Value)
      Config.AutoFarm.CollectWeapons = Value
   end,
})

-- 4. Movement Tab
local MoveTab = Window:CreateTab("Movement", 4483362458)

MoveTab:CreateToggle({
   Name = "Noclip",
   CurrentValue = Config.Movement.Noclip,
   Flag = "NoclipFlag",
   Callback = function(Value)
      Config.Movement.Noclip = Value
   end,
})

MoveTab:CreateToggle({
   Name = "Fly",
   CurrentValue = Config.Movement.Fly,
   Flag = "FlyFlag",
   Callback = function(Value)
      Config.Movement.Fly = Value
   end,
})

MoveTab:CreateButton({
   Name = "Toggle Speed / Sprint (Bind: V)",
   Callback = function()
      EventFunctions.ContextActionService_V("SprintBind", Enum.UserInputState.Begin, nil)
   end,
})

-- 5. Visuals & Misc Tab
local VisualsTab = Window:CreateTab("Visuals & Misc", 4483362458)

VisualsTab:CreateToggle({
   Name = "FullBright",
   CurrentValue = Config.Visuals.FullBright,
   Flag = "FullBrightFlag",
   Callback = function(v)
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
   end,
})

-- Notification on Load
pcall(function()
    Services.StarterGui:SetCore("SendNotification", {
        Title = "white wia hub",
        Text = "Successfully loaded into Rayfield UI!",
        Duration = 4
    })
end)