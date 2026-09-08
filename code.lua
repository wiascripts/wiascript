-- ================================================================= --
-- WIA HUB v12.6 :: MM2 ULTIMATE & INFINITY YIELD HYBRID
-- FINAL POLISH | OPTIMIZED | CLEAN ARCHITECTURE | FLIGHT FIXED
-- ================================================================= --

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

-- ========== 1. УПРАВЛЕНИЕ СОЕДИНЕНИЯМИ ==========
local Connections = {}
local function TrackConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function CleanupConnections()
    for _, conn in pairs(Connections) do
        pcall(function() conn:Disconnect() end)
    end
    Connections = {}
end

-- ========== 2. НАСТРОЙКИ СКРИПТА ==========
local Settings = {
    -- Movement
    Speed = 16,
    JumpPower = 50,
    Fly = false,
    FlySpeed = 50,
    Noclip = false,
    InfiniteJump = false,
    
    -- Combat
    Aimbot = false,
    AimbotFOV = 120,
    Smoothness = 3,
    KillAura = false,
    KillRadius = 15,
    
    -- MM2 Master & Visuals
    PlayerESP = false,
    CoinESP = false,
    GunESP = false,
    
    MurdererColor = Color3.fromRGB(255, 0, 0),
    SheriffColor = Color3.fromRGB(0, 150, 255),
    InnocentColor = Color3.fromRGB(0, 255, 0),
    CoinColor = Color3.fromRGB(255, 215, 0),
    GunColor = Color3.fromRGB(255, 255, 0),
    
    -- Automation
    AutoFarm = false,
    FarmSpeed = 0.3,
    AutoGrabGun = false,
    AntiKnife = false,
    
    -- Utility
    AntiAFK = true,
    FullBright = false,
    NoFog = false,
    HideLocal = false,
    SpectateTarget = nil,
    IsSpectating = false,
}

-- ========== 3. СОСТОЯНИЕ И КЭШ ==========
local OriginalLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
}

-- Кэш контейнеров монет
local CoinContainerCache = {
    Containers = {},
    Timestamp = 0,
    UpdateInterval = 2,
}

-- Кэш монет
local CoinCache = {
    Coins = {},
    Timestamp = 0,
    UpdateInterval = 0.5,
}

-- Сохранение исходных CanCollide для Noclip
local OriginalCollision = {}

-- ESP кэш
local ESPCache = {
    PlayerHighlights = {},
    CoinHighlights = {},
    GunHighlight = nil,
    PlayerRoles = {},
    GunObject = nil,
    PlayerBackpackConnections = {},
}

-- Полёт
local FlyData = {
    BodyVelocity = nil,
    BodyGyro = nil,
    Active = false,
}

-- ========== НОВЫЕ СОСТОЯНИЯ ДЛЯ UTILITIES ==========
local UtilityState = {
    TeleportTool = nil,
    SelectedPlayer = nil,
    IsSpectating = false,
    SpectateTarget = nil,
    OriginalCameraCFrame = nil,
    OriginalCameraSubject = nil,
    PlayerDropdown = nil,
    PlayerListFrame = nil,
    IsFirstLoad = true,
}

local UtilityObjects = {}

-- ========== 4. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local function SafeGetCamera()
    return Workspace.CurrentCamera or Workspace:FindFirstChildOfClass("Camera")
end

-- Кэшированный поиск контейнеров монет
local function GetCoinContainers()
    local now = tick()
    if now - CoinContainerCache.Timestamp < CoinContainerCache.UpdateInterval then
        return CoinContainerCache.Containers
    end
    
    CoinContainerCache.Timestamp = now
    CoinContainerCache.Containers = {}
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "CoinContainer" then
            table.insert(CoinContainerCache.Containers, obj)
        end
    end
    
    return CoinContainerCache.Containers
end

local function InvalidateCoinContainerCache()
    CoinContainerCache.Timestamp = 0
end

local function GetCoinsCached()
    local now = tick()
    if now - CoinCache.Timestamp < CoinCache.UpdateInterval then
        return CoinCache.Coins
    end
    
    CoinCache.Timestamp = now
    CoinCache.Coins = {}
    
    local containers = GetCoinContainers()
    
    for _, container in pairs(containers) do
        for _, child in pairs(container:GetChildren()) do
            if child:IsA("BasePart") and child.Transparency and child.Transparency < 0.9 then
                table.insert(CoinCache.Coins, child)
            elseif child:IsA("Model") then
                local part = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
                if part and part.Transparency and part.Transparency < 0.9 then
                    table.insert(CoinCache.Coins, part)
                end
            end
        end
    end
    
    return CoinCache.Coins
end

local function InvalidateCoinCache()
    CoinCache.Timestamp = 0
    InvalidateCoinContainerCache()
end

local function SetupWorkspaceWatcher()
    local function onDescendantAdded(descendant)
        if descendant.Name == "CoinContainer" or 
           (descendant:IsA("BasePart") and descendant.Name == "Coin") then
            InvalidateCoinCache()
        end
    end
    
    local function onDescendantRemoved(descendant)
        if descendant.Name == "CoinContainer" or 
           (descendant:IsA("BasePart") and descendant.Name == "Coin") then
            InvalidateCoinCache()
        end
    end
    
    TrackConnection(Workspace.DescendantAdded:Connect(onDescendantAdded))
    TrackConnection(Workspace.DescendantRemoved:Connect(onDescendantRemoved))
end

SetupWorkspaceWatcher()

local function GetNearestCoin(position)
    local coins = GetCoinsCached()
    local nearest = nil
    local minDist = math.huge
    
    for _, coin in pairs(coins) do
        if coin and coin.Position then
            local dist = (position - coin.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = coin
            end
        end
    end
    
    return nearest
end

local function GetPlayerRole(player)
    if not player then return "Innocent" end
    
    if ESPCache.PlayerRoles[player] and ESPCache.PlayerRoles[player].Timestamp > tick() - 0.2 then
        return ESPCache.PlayerRoles[player].Role
    end
    
    local role = "Innocent"
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    
    if char or bp then
        local function hasItem(name)
            if char and char:FindFirstChild(name) then return true end
            if bp and bp:FindFirstChild(name) then return true end
            return false
        end
        
        if hasItem("Knife") then
            role = "Murderer"
        elseif hasItem("Gun") or hasItem("Revolver") then
            role = "Sheriff"
        end
    end
    
    ESPCache.PlayerRoles[player] = {
        Role = role,
        Timestamp = tick()
    }
    
    return role
end

local function InvalidateRoleCache(player)
    if player then
        ESPCache.PlayerRoles[player] = nil
    else
        ESPCache.PlayerRoles = {}
    end
end

local function GetGunDrop()
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj.Name == "GunDrop" and obj:IsA("BasePart") then
            return obj
        end
        
        if obj:IsA("Model") then
            local gunDrop = obj:FindFirstChild("GunDrop")
            if gunDrop and gunDrop:IsA("BasePart") then
                return obj
            end
            
            if obj.Name ~= "Character" and obj.Name ~= "Player" then
                local hasGun = false
                local isTool = false
                
                for _, child in pairs(obj:GetChildren()) do
                    if child:IsA("BasePart") and (child.Name == "Gun" or child.Name == "Revolver") then
                        hasGun = true
                    end
                    if child:IsA("Tool") then
                        isTool = true
                    end
                end
                
                if hasGun and not isTool then
                    return obj
                end
            end
        end
    end
    return nil
end

-- ========== НОВЫЕ UTILITY ФУНКЦИИ ==========

-- Получение списка игроков
local function GetPlayerList()
    local list = {}
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            table.insert(list, plr)
        end
    end
    return list
end

-- Обновление Dropdown игроков
local function UpdatePlayerDropdown(dropdown)
    if not dropdown then return end
    
    local players = GetPlayerList()
    local options = {}
    
    for _, plr in pairs(players) do
        table.insert(options, {
            Name = plr.Name,
            Value = plr.Name,
        })
    end
    
    if #options == 0 then
        table.insert(options, {
            Name = "Нет игроков",
            Value = "none",
        })
    end
    
    dropdown:SetOptions(options)
end

-- Телепорт к игроку
local function TeleportToPlayer(player)
    if not player then
        Rayfield:Notify({ Title = "Ошибка", Content = "Игрок не выбран!", Duration = 3 })
        return false
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        Rayfield:Notify({ Title = "Ошибка", Content = "Ваш персонаж не найден!", Duration = 3 })
        return false
    end
    
    local targetChar = player.Character
    if not targetChar or not targetChar:FindFirstChild("HumanoidRootPart") then
        Rayfield:Notify({ Title = "Ошибка", Content = "Персонаж игрока не найден!", Duration = 3 })
        return false
    end
    
    local hrp = char.HumanoidRootPart
    local targetHrp = targetChar.HumanoidRootPart
    
    hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 3, 0)
    Rayfield:Notify({ Title = "Успех", Content = "Телепорт к " .. player.Name .. " выполнен!", Duration = 2 })
    return true
end

-- Spectate
local function StartSpectate(player)
    if not player then
        Rayfield:Notify({ Title = "Ошибка", Content = "Игрок не выбран!", Duration = 3 })
        return false
    end
    
    local targetChar = player.Character
    if not targetChar or not targetChar:FindFirstChild("Humanoid") then
        Rayfield:Notify({ Title = "Ошибка", Content = "У игрока нет Humanoid!", Duration = 3 })
        return false
    end
    
    local cam = SafeGetCamera()
    if not cam then return false end
    
    -- Сохраняем оригинальное состояние
    UtilityState.OriginalCameraCFrame = cam.CFrame
    UtilityState.OriginalCameraSubject = cam.CameraSubject
    
    -- Переключаем на цель
    cam.CameraSubject = targetChar.Humanoid
    cam.CameraType = Enum.CameraType.Attach
    
    Settings.IsSpectating = true
    Settings.SpectateTarget = player
    UtilityState.IsSpectating = true
    UtilityState.SpectateTarget = player
    
    Rayfield:Notify({ Title = "Spectate", Content = "Вы наблюдаете за " .. player.Name, Duration = 3 })
    return true
end

local function StopSpectate()
    local cam = SafeGetCamera()
    if not cam then return end
    
    cam.CameraSubject = UtilityState.OriginalCameraSubject or LocalPlayer.Character
    cam.CameraType = Enum.CameraType.Custom
    
    Settings.IsSpectating = false
    Settings.SpectateTarget = nil
    UtilityState.IsSpectating = false
    UtilityState.SpectateTarget = nil
    
    Rayfield:Notify({ Title = "Spectate", Content = "Наблюдение остановлено", Duration = 2 })
end

-- Создание Teleport Tool
local function CreateTeleportTool()
    -- Удаляем старый инструмент если есть
    if UtilityState.TeleportTool then
        UtilityState.TeleportTool:Destroy()
        UtilityState.TeleportTool = nil
    end
    
    local tool = Instance.new("Tool")
    tool.Name = "WIA_TeleportTool"
    tool.RequiresHandle = false
    tool.CanBeDropped = false
    
    local teleportPoint = nil
    
    tool.Activated:Connect(function()
        if not teleportPoint then
            Rayfield:Notify({ Title = "Ошибка", Content = "Сначала выберите точку (клик правой кнопкой)!" , Duration = 3 })
            return
        end
        
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            char.HumanoidRootPart.CFrame = teleportPoint
            Rayfield:Notify({ Title = "Телепорт", Content = "Перемещён в выбранную точку!", Duration = 2 })
        end
    end)
    
    tool:GetPropertyChangedSignal("Parent"):Connect(function()
        if tool.Parent == nil then
            teleportPoint = nil
        end
    end)
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton2 and tool.Parent == LocalPlayer.Character then
            local target = Mouse.Hit
            if target and target.Position then
                teleportPoint = target
                Rayfield:Notify({ Title = "Точка сохранена", Content = "Позиция: " .. tostring(target.Position), Duration = 2 })
            end
        end
    end)
    
    tool.Parent = LocalPlayer.Backpack
    UtilityState.TeleportTool = tool
    table.insert(UtilityObjects, tool)
    
    Rayfield:Notify({ Title = "Успех", Content = "Teleport Tool создан! Кликните ПКМ для выбора точки, затем ЛКМ для телепорта.", Duration = 5 })
end

-- Remove Tools
local function RemoveAllTools()
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    
    local count = 0
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
            count = count + 1
        end
    end
    
    Rayfield:Notify({ Title = "Очистка", Content = "Удалено инструментов: " .. count, Duration = 2 })
end

-- Clear WIA ESP
local function ClearWIAESP()
    for _, hl in pairs(ESPCache.PlayerHighlights) do
        pcall(function() hl:Destroy() end)
    end
    ESPCache.PlayerHighlights = {}
    
    for _, hl in pairs(ESPCache.CoinHighlights) do
        pcall(function() hl:Destroy() end)
    end
    ESPCache.CoinHighlights = {}
    
    if ESPCache.GunHighlight then
        pcall(function() ESPCache.GunHighlight:Destroy() end)
        ESPCache.GunHighlight = nil
    end
    
    Rayfield:Notify({ Title = "ESP очищен", Content = "Все выделения удалены!", Duration = 2 })
end

-- Reset Character
local function ResetCharacter()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
        Rayfield:Notify({ Title = "Респавн", Content = "Персонаж пересоздаётся...", Duration = 2 })
    end
end

-- ========== 5. ПРИМЕНЕНИЕ НАСТРОЕК ДВИЖЕНИЯ ==========
local function ApplyMovementSettings()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    if hum.WalkSpeed ~= Settings.Speed then
        hum.WalkSpeed = Settings.Speed
    end
    
    if hum.JumpPower ~= Settings.JumpPower then
        hum.JumpPower = Settings.JumpPower
    end
    if not hum.UseJumpPower then
        hum.UseJumpPower = true
    end
end

-- ========== 6. СИСТЕМА ПОЛЁТА ==========
local function UpdateFlight()
    if Settings.Fly and LocalPlayer.Character then
        local char = LocalPlayer.Character
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        if not FlyData.BodyVelocity then
            FlyData.BodyVelocity = Instance.new("BodyVelocity")
            FlyData.BodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
            FlyData.BodyVelocity.Parent = root
            table.insert(UtilityObjects, FlyData.BodyVelocity)
        end
        
        if not FlyData.BodyGyro then
            FlyData.BodyGyro = Instance.new("BodyGyro")
            FlyData.BodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
            FlyData.BodyGyro.Parent = root
            FlyData.BodyGyro.P = 5000
            FlyData.BodyGyro.D = 500
            table.insert(UtilityObjects, FlyData.BodyGyro)
        end
        
        local cam = SafeGetCamera()
        if not cam then return end
        
        local moveDir = Vector3.new(0, 0, 0)
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
            FlyData.BodyVelocity.Velocity = moveDir * Settings.FlySpeed
            local targetCFrame = CFrame.lookAt(root.Position, root.Position + moveDir)
            FlyData.BodyGyro.CFrame = targetCFrame
        else
            FlyData.BodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        FlyData.Active = true
    else
        if FlyData.BodyVelocity then
            FlyData.BodyVelocity:Destroy()
            FlyData.BodyVelocity = nil
        end
        if FlyData.BodyGyro then
            FlyData.BodyGyro:Destroy()
            FlyData.BodyGyro = nil
        end
        FlyData.Active = false
    end
end

TrackConnection(RunService.Heartbeat:Connect(UpdateFlight))

-- ========== 7. УПРАВЛЕНИЕ ESP (ИНКРЕМЕНТАЛЬНОЕ) ==========

local function UpdatePlayerESP()
    if not Settings.PlayerESP then
        for player, hl in pairs(ESPCache.PlayerHighlights) do
            pcall(function() hl:Destroy() end)
        end
        ESPCache.PlayerHighlights = {}
        return
    end
    
    local playersToRemove = {}
    for player, hl in pairs(ESPCache.PlayerHighlights) do
        if not player or not player.Parent or not player.Character or not hl.Parent then
            pcall(function() hl:Destroy() end)
            playersToRemove[player] = true
        end
    end
    for player in pairs(playersToRemove) do
        ESPCache.PlayerHighlights[player] = nil
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local role = GetPlayerRole(plr)
            local color = (role == "Murderer" and Settings.MurdererColor) or 
                         (role == "Sheriff" and Settings.SheriffColor) or 
                         Settings.InnocentColor
            
            local hl = ESPCache.PlayerHighlights[plr]
            if not hl or not hl.Parent then
                hl = Instance.new("Highlight")
                hl.Name = "WIA_ESP"
                hl.FillTransparency = 0.35
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.OutlineTransparency = 0.5
                hl.Parent = plr.Character
                ESPCache.PlayerHighlights[plr] = hl
            end
            
            if hl.FillColor ~= color then
                hl.FillColor = color
            end
        end
    end
end

local function UpdateCoinESP()
    if not Settings.CoinESP then
        for _, hl in pairs(ESPCache.CoinHighlights) do
            pcall(function() hl:Destroy() end)
        end
        ESPCache.CoinHighlights = {}
        return
    end
    
    local coins = GetCoinsCached()
    local currentCoins = {}
    for _, coin in pairs(coins) do
        currentCoins[coin] = true
    end
    
    local toRemove = {}
    for coin, hl in pairs(ESPCache.CoinHighlights) do
        if not coin or not coin.Parent or not currentCoins[coin] then
            pcall(function() hl:Destroy() end)
            toRemove[coin] = true
        end
    end
    for coin in pairs(toRemove) do
        ESPCache.CoinHighlights[coin] = nil
    end
    
    for _, coin in pairs(coins) do
        if coin and coin.Parent and not ESPCache.CoinHighlights[coin] then
            local hl = Instance.new("Highlight")
            hl.Name = "Coin_ESP"
            hl.FillColor = Settings.CoinColor
            hl.FillTransparency = 0.2
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.OutlineTransparency = 0.7
            hl.Parent = coin
            ESPCache.CoinHighlights[coin] = hl
        end
    end
end

local function UpdateGunESP()
    local gun = GetGunDrop()
    
    if not Settings.GunESP or not gun then
        if ESPCache.GunHighlight then
            pcall(function() ESPCache.GunHighlight:Destroy() end)
            ESPCache.GunHighlight = nil
        end
        ESPCache.GunObject = nil
        return
    end
    
    if ESPCache.GunObject ~= gun then
        if ESPCache.GunHighlight then
            pcall(function() ESPCache.GunHighlight:Destroy() end)
            ESPCache.GunHighlight = nil
        end
        
        local hl = Instance.new("Highlight")
        hl.Name = "Gun_ESP"
        hl.FillColor = Settings.GunColor
        hl.FillTransparency = 0.15
        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
        hl.OutlineTransparency = 0.6
        hl.Parent = gun
        ESPCache.GunHighlight = hl
        ESPCache.GunObject = gun
    end
end

local function CleanupPlayer(player)
    if ESPCache.PlayerHighlights[player] then
        pcall(function() ESPCache.PlayerHighlights[player]:Destroy() end)
        ESPCache.PlayerHighlights[player] = nil
    end
    ESPCache.PlayerRoles[player] = nil
    
    if ESPCache.PlayerBackpackConnections[player] then
        for _, conn in pairs(ESPCache.PlayerBackpackConnections[player]) do
            pcall(function() conn:Disconnect() end)
        end
        ESPCache.PlayerBackpackConnections[player] = nil
    end
end

local function UpdateAllESP()
    InvalidateRoleCache()
    UpdatePlayerESP()
    UpdateCoinESP()
    UpdateGunESP()
end

-- ========== 8. НАСТРОЙКА ТРИГГЕРОВ ==========
local function SetupTriggers()
    local function SetupPlayer(plr)
        if plr == LocalPlayer then return end
        
        TrackConnection(plr.CharacterAdded:Connect(function()
            task.wait(0.2)
            InvalidateRoleCache(plr)
            UpdatePlayerESP()
        end))
        
        local backpackConnections = {}
        
        local function checkBackpackChange()
            task.wait(0.1)
            local oldRole = ESPCache.PlayerRoles[plr] and ESPCache.PlayerRoles[plr].Role
            local newRole = GetPlayerRole(plr)
            if oldRole ~= newRole then
                InvalidateRoleCache(plr)
                UpdatePlayerESP()
            end
        end
        
        local function cleanupBackpackConnections()
            if ESPCache.PlayerBackpackConnections[plr] then
                for _, conn in pairs(ESPCache.PlayerBackpackConnections[plr]) do
                    pcall(function() conn:Disconnect() end)
                end
                ESPCache.PlayerBackpackConnections[plr] = nil
            end
        end
        
        local function setupBackpackConnections()
            cleanupBackpackConnections()
            
            if plr.Backpack then
                local newConnections = {}
                table.insert(newConnections, TrackConnection(plr.Backpack.ChildAdded:Connect(checkBackpackChange)))
                table.insert(newConnections, TrackConnection(plr.Backpack.ChildRemoved:Connect(checkBackpackChange)))
                ESPCache.PlayerBackpackConnections[plr] = newConnections
            end
        end
        
        TrackConnection(plr:GetPropertyChangedSignal("Backpack"):Connect(setupBackpackConnections))
        setupBackpackConnections()
    end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            SetupPlayer(plr)
        end
    end
    
    TrackConnection(Players.PlayerAdded:Connect(SetupPlayer))
    TrackConnection(Players.PlayerRemoving:Connect(CleanupPlayer))
    
    TrackConnection(LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.1)
        ApplyMovementSettings()
        UpdateAllESP()
        
        -- Останавливаем spectate при респавне
        if UtilityState.IsSpectating then
            StopSpectate()
        end
    end))
end

SetupTriggers()

-- ========== 9. ИНТЕРФЕЙС RAYFIELD ==========
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name = "WIA HUB v12.6 | MM2 & IY Hybrid",
    LoadingTitle = "Загрузка WIA HUB...",
    LoadingSubtitle = "Финальная версия",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local Tabs = {
    MM2 = Window:CreateTab("MM2 Master", 4483362458),
    Movement = Window:CreateTab("Movement", 4483362458),
    Combat = Window:CreateTab("Combat", 4483362458),
    IYUtils = Window:CreateTab("IY Utilities", 4483362458),
}

-- ================================================================= --
-- ВКЛАДКА: MM2 MASTER
-- ================================================================= --
Tabs.MM2:CreateSection("Визуалы и Подсветка (Highlight ESP)")

Tabs.MM2:CreateToggle({
    Name = "Подсветка Игроков (Wallhack)",
    CurrentValue = false,
    Tooltip = "Закрашивает игроков сквозь стены по их ролям.",
    Callback = function(v) 
        Settings.PlayerESP = v 
        UpdatePlayerESP()
    end
})

Tabs.MM2:CreateToggle({
    Name = "Подсветка Монет (Coin ESP)",
    CurrentValue = false,
    Tooltip = "Показывает местоположение золотых монет.",
    Callback = function(v) 
        Settings.CoinESP = v 
        UpdateCoinESP()
    end
})

Tabs.MM2:CreateToggle({
    Name = "Подсветка Выпавшей Пушки",
    CurrentValue = false,
    Tooltip = "Подсвечивает выпавший пистолет Шерифа.",
    Callback = function(v) 
        Settings.GunESP = v 
        UpdateGunESP()
    end
})

Tabs.MM2:CreateSection("Автоматизация MM2")

Tabs.MM2:CreateToggle({
    Name = "Автофарм Монет",
    CurrentValue = false,
    Tooltip = "Автоматически собирает монеты на карте.",
    Callback = function(v) Settings.AutoFarm = v end
})

Tabs.MM2:CreateSlider({
    Name = "Задержка автофарма (сек)",
    Range = {0.1, 1},
    Increment = 0.05,
    Suffix = "с",
    CurrentValue = 0.3,
    Tooltip = "Задержка между телепортами.",
    Callback = function(v) Settings.FarmSpeed = v end
})

Tabs.MM2:CreateToggle({
    Name = "Авто-подбор Пушки",
    CurrentValue = false,
    Tooltip = "Автоматически забирает пистолет Шерифа.",
    Callback = function(v) Settings.AutoGrabGun = v end
})

Tabs.MM2:CreateButton({
    Name = "Телепорт к Пушке",
    Tooltip = "Телепортирует вас к выпавшему пистолету.",
    Callback = function()
        local gun = GetGunDrop()
        local char = LocalPlayer.Character
        if not gun or not char or not char:FindFirstChild("HumanoidRootPart") then
            Rayfield:Notify({ Title = "Ошибка", Content = "Пушка или персонаж не найдены!", Duration = 3 })
            return
        end
        
        local part = gun:IsA("Model") and gun.PrimaryPart or gun
        if not part then
            Rayfield:Notify({ Title = "Ошибка", Content = "Не удалось найти часть модели!", Duration = 3 })
            return
        end
        
        char.HumanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 2, 0)
        Rayfield:Notify({ Title = "Успех", Content = "Телепорт выполнен!", Duration = 2 })
    end
})

Tabs.MM2:CreateToggle({
    Name = "Anti-Knife (Защита)",
    CurrentValue = false,
    Tooltip = "Автоматически отталкивает от Мардера.",
    Callback = function(v) Settings.AntiKnife = v end
})

-- ================================================================= --
-- ВКЛАДКА: MOVEMENT
-- ================================================================= --
Tabs.Movement:CreateSection("Модификаторы движения")

Tabs.Movement:CreateSlider({
    Name = "Скорость бега (Speed)",
    Range = {16, 120},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 16,
    Tooltip = "Увеличивает скорость перемещения.",
    Callback = function(v) 
        Settings.Speed = v 
        ApplyMovementSettings()
    end
})

Tabs.Movement:CreateSlider({
    Name = "Сила прыжка (Jump Power)",
    Range = {50, 200},
    Increment = 5,
    Suffix = "",
    CurrentValue = 50,
    Tooltip = "Увеличивает высоту прыжка.",
    Callback = function(v) 
        Settings.JumpPower = v 
        ApplyMovementSettings()
    end
})

Tabs.Movement:CreateToggle({
    Name = "Бесконечный прыжок",
    CurrentValue = false,
    Tooltip = "Позволяет прыгать в воздухе.",
    Callback = function(v) Settings.InfiniteJump = v end
})

Tabs.Movement:CreateToggle({
    Name = "Полёты (Fly)",
    CurrentValue = false,
    Tooltip = "Свободный полёт (WASD, Space, Shift).",
    Callback = function(v) 
        Settings.Fly = v 
        if not v then UpdateFlight() end
    end
})

Tabs.Movement:CreateSlider({
    Name = "Скорость полёта",
    Range = {10, 300},
    Increment = 5,
    Suffix = " speed",
    CurrentValue = 50,
    Tooltip = "Скорость передвижения в режиме полёта.",
    Callback = function(v) Settings.FlySpeed = v end
})

Tabs.Movement:CreateToggle({
    Name = "Проход сквозь стены",
    CurrentValue = false,
    Tooltip = "Отключает коллизию персонажа.",
    Callback = function(v) Settings.Noclip = v end
})

-- ================================================================= --
-- ВКЛАДКА: COMBAT
-- ================================================================= --
Tabs.Combat:CreateSection("Аимбот и Киллаура")

Tabs.Combat:CreateToggle({
    Name = "Aimbot на Мардера",
    CurrentValue = false,
    Tooltip = "Наводит камеру на Мардера.",
    Callback = function(v) Settings.Aimbot = v end
})

Tabs.Combat:CreateSlider({
    Name = "Радиус Aimbot",
    Range = {30, 400},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 120,
    Tooltip = "Размер области действия.",
    Callback = function(v) Settings.AimbotFOV = v end
})

Tabs.Combat:CreateSlider({
    Name = "Плавность Aimbot",
    Range = {1, 20},
    Increment = 1,
    Suffix = "",
    CurrentValue = 3,
    Tooltip = "Плавность наведения (1 - мгновенно, 20 - очень плавно).",
    Callback = function(v) Settings.Smoothness = v end
})

Tabs.Combat:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Tooltip = "Автоматически атакует всех рядом.",
    Callback = function(v) Settings.KillAura = v end
})

Tabs.Combat:CreateSlider({
    Name = "Радиус Kill Aura",
    Range = {1, 50},
    Increment = 1,
    Suffix = " studs",
    CurrentValue = 15,
    Tooltip = "Радиус действия Kill Aura.",
    Callback = function(v) Settings.KillRadius = v end
})

-- ================================================================= --
-- ВКЛАДКА: INFINITY YIELD UTILITIES (РАСШИРЕННАЯ)
-- ================================================================= --

-- ====== PLAYER UTILITIES SECTION ======
local PlayerUtilsSection = Tabs.IYUtils:CreateSection("Player Utilities")

-- Player Dropdown
local playerDropdown = Tabs.IYUtils:CreateDropdown({
    Name = "Выбрать игрока",
    Options = {},
    CurrentOption = "none",
    Tooltip = "Выберите игрока для действий",
    Callback = function(option)
        if option == "none" then
            UtilityState.SelectedPlayer = nil
            return
        end
        
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Name == option and plr ~= LocalPlayer then
                UtilityState.SelectedPlayer = plr
                break
            end
        end
    end
})

UtilityState.PlayerDropdown = playerDropdown

-- Обновление списка игроков
local function RefreshPlayerList()
    if not playerDropdown then return end
    
    local players = GetPlayerList()
    local options = {}
    
    if #players == 0 then
        table.insert(options, {
            Name = "Нет игроков",
            Value = "none",
        })
    else
        for _, plr in pairs(players) do
            table.insert(options, {
                Name = plr.Name,
                Value = plr.Name,
            })
        end
    end
    
    playerDropdown:SetOptions(options)
    
    -- Проверяем выбранного игрока
    if UtilityState.SelectedPlayer then
        local stillExists = false
        for _, plr in pairs(players) do
            if plr == UtilityState.SelectedPlayer then
                stillExists = true
                break
            end
        end
        if not stillExists then
            UtilityState.SelectedPlayer = nil
            playerDropdown:SetCurrentOption("none")
        end
    end
end

-- Обновление при добавлении/удалении игроков
TrackConnection(Players.PlayerAdded:Connect(RefreshPlayerList))
TrackConnection(Players.PlayerRemoving:Connect(RefreshPlayerList))

-- Teleport to Player
Tabs.IYUtils:CreateButton({
    Name = "Teleport to Player",
    Tooltip = "Телепортирует вас к выбранному игроку",
    Callback = function()
        if not UtilityState.SelectedPlayer then
            Rayfield:Notify({ Title = "Ошибка", Content = "Сначала выберите игрока!", Duration = 3 })
            return
        end
        TeleportToPlayer(UtilityState.SelectedPlayer)
    end
})

-- Spectate Player
Tabs.IYUtils:CreateButton({
    Name = "Spectate Player",
    Tooltip = "Начать наблюдение за выбранным игроком",
    Callback = function()
        if not UtilityState.SelectedPlayer then
            Rayfield:Notify({ Title = "Ошибка", Content = "Сначала выберите игрока!", Duration = 3 })
            return
        end
        StartSpectate(UtilityState.SelectedPlayer)
    end
})

-- Stop Spectating
Tabs.IYUtils:CreateButton({
    Name = "Stop Spectating",
    Tooltip = "Остановить наблюдение",
    Callback = function()
        StopSpectate()
    end
})

-- Copy Player Name
Tabs.IYUtils:CreateButton({
    Name = "Copy Player Name",
    Tooltip = "Копирует имя выбранного игрока",
    Callback = function()
        if not UtilityState.SelectedPlayer then
            Rayfield:Notify({ Title = "Ошибка", Content = "Сначала выберите игрока!", Duration = 3 })
            return
        end
        setclipboard and setclipboard(UtilityState.SelectedPlayer.Name) or nil
        Rayfield:Notify({ Title = "Скопировано", Content = "Имя: " .. UtilityState.SelectedPlayer.Name, Duration = 2 })
    end
})

-- Copy UserId
Tabs.IYUtils:CreateButton({
    Name = "Copy UserId",
    Tooltip = "Копирует UserId выбранного игрока",
    Callback = function()
        if not UtilityState.SelectedPlayer then
            Rayfield:Notify({ Title = "Ошибка", Content = "Сначала выберите игрока!", Duration = 3 })
            return
        end
        setclipboard and setclipboard(tostring(UtilityState.SelectedPlayer.UserId)) or nil
        Rayfield:Notify({ Title = "Скопировано", Content = "UserId: " .. UtilityState.SelectedPlayer.UserId, Duration = 2 })
    end
})

-- Refresh Player List
Tabs.IYUtils:CreateButton({
    Name = "Refresh Player List",
    Tooltip = "Обновить список игроков",
    Callback = function()
        RefreshPlayerList()
        Rayfield:Notify({ Title = "Обновлено", Content = "Список игроков обновлён!", Duration = 2 })
    end
})

-- ====== MOVEMENT UTILITIES ======
local MovementUtilsSection = Tabs.IYUtils:CreateSection("Movement Utilities")

Tabs.IYUtils:CreateButton({
    Name = "Reset Character",
    Tooltip = "Пересоздать персонажа",
    Callback = function()
        ResetCharacter()
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Sit",
    Tooltip = "Усадить персонажа",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Sit = true
        end
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Force Jump",
    Tooltip = "Заставить персонажа прыгнуть",
    Callback = function()
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
})

-- ====== WORLD / VISUAL UTILITIES ======
local WorldUtilsSection = Tabs.IYUtils:CreateSection("World & Visual")

Tabs.IYUtils:CreateToggle({
    Name = "No Fog",
    CurrentValue = false,
    Tooltip = "Убирает туман",
    Callback = function(v)
        Settings.NoFog = v
        if v then
            Lighting.FogEnd = 100000
        else
            Lighting.FogEnd = OriginalLighting.FogEnd or 10000
        end
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Restore Lighting",
    Tooltip = "Восстанавливает оригинальное освещение",
    Callback = function()
        Lighting.Brightness = OriginalLighting.Brightness or 1
        Lighting.ClockTime = OriginalLighting.ClockTime or 14
        Lighting.FogEnd = OriginalLighting.FogEnd or 10000
        Lighting.Ambient = OriginalLighting.Ambient or Color3.fromRGB(127, 127, 127)
        Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient or Color3.fromRGB(127, 127, 127)
        Settings.FullBright = false
        Settings.NoFog = false
        Rayfield:Notify({ Title = "Восстановлено", Content = "Освещение восстановлено!", Duration = 2 })
    end
})

Tabs.IYUtils:CreateSlider({
    Name = "ClockTime",
    Range = {0, 24},
    Increment = 0.5,
    Suffix = "h",
    CurrentValue = 14,
    Tooltip = "Время суток",
    Callback = function(v)
        Lighting.ClockTime = v
    end
})

Tabs.IYUtils:CreateSlider({
    Name = "Ambient Brightness",
    Range = {0, 2},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 1,
    Tooltip = "Яркость окружения",
    Callback = function(v)
        Lighting.Ambient = Color3.fromRGB(v * 127, v * 127, v * 127)
    end
})

Tabs.IYUtils:CreateToggle({
    Name = "Hide Local Character",
    CurrentValue = false,
    Tooltip = "Скрыть своего персонажа",
    Callback = function(v)
        Settings.HideLocal = v
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = v and 1 or 0
                end
            end
        end
    end
})

-- ====== SERVER UTILITIES ======
local ServerUtilsSection = Tabs.IYUtils:CreateSection("Server Utilities")

Tabs.IYUtils:CreateButton({
    Name = "Server Info",
    Tooltip = "Показывает информацию о сервере",
    Callback = function()
        local playerCount = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        Rayfield:Notify({ 
            Title = "Server Info", 
            Content = "Игроков: " .. playerCount .. "/" .. maxPlayers .. "\nPlaceId: " .. game.PlaceId .. "\nJobId: " .. game.JobId,
            Duration = 5 
        })
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Copy JobId",
    Tooltip = "Копирует JobId сервера",
    Callback = function()
        setclipboard and setclipboard(game.JobId) or nil
        Rayfield:Notify({ Title = "Скопировано", Content = "JobId: " .. game.JobId, Duration = 2 })
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Copy PlaceId",
    Tooltip = "Копирует PlaceId сервера",
    Callback = function()
        setclipboard and setclipboard(tostring(game.PlaceId)) or nil
        Rayfield:Notify({ Title = "Скопировано", Content = "PlaceId: " .. game.PlaceId, Duration = 2 })
    end
})

-- ====== UTILITY ======
local UtilitySection = Tabs.IYUtils:CreateSection("Utility")

Tabs.IYUtils:CreateButton({
    Name = "Get Teleport Tool",
    Tooltip = "Создаёт инструмент для телепортации",
    Callback = function()
        CreateTeleportTool()
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Remove All Tools",
    Tooltip = "Удаляет все инструменты из рюкзака",
    Callback = function()
        RemoveAllTools()
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Clear WIA ESP",
    Tooltip = "Удаляет все выделения WIA",
    Callback = function()
        ClearWIAESP()
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Full Cleanup",
    Tooltip = "Полная очистка всех эффектов и соединений",
    Callback = function()
        FullCleanup()
        Rayfield:Notify({ Title = "Очистка", Content = "Все эффекты удалены!", Duration = 3 })
    end
})

Tabs.IYUtils:CreateButton({
    Name = "Destroy WIA GUI",
    Tooltip = "Закрывает интерфейс WIA HUB",
    Callback = function()
        SafeCleanup()
        if Window and Window.Close then
            Window:Close()
        end
    end
})

-- Инициализация списка игроков
task.wait(0.5)
RefreshPlayerList()

-- ================================================================= --
-- 10. ОСНОВНЫЕ ИСПОЛНИТЕЛЬНЫЕ ЦИКЛЫ
-- ================================================================= --

-- Noclip
TrackConnection(RunService.Stepped:Connect(function()
    if not LocalPlayer.Character then return end
    
    if Settings.Noclip then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                if OriginalCollision[part] == nil then
                    OriginalCollision[part] = part.CanCollide
                end
                part.CanCollide = false
            end
        end
    else
        for part, originalValue in pairs(OriginalCollision) do
            if part and part.Parent then
                pcall(function() part.CanCollide = originalValue end)
            end
        end
        OriginalCollision = {}
    end
end))

-- Infinite Jump
TrackConnection(UserInputService.JumpRequest:Connect(function()
    if Settings.InfiniteJump and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end))

-- AutoFarm
local lastFarm = 0
TrackConnection(RunService.Heartbeat:Connect(function()
    if Settings.AutoFarm then
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char.HumanoidRootPart
        local nearestCoin = GetNearestCoin(hrp.Position)
        
        if nearestCoin and tick() - lastFarm > Settings.FarmSpeed then
            hrp.CFrame = nearestCoin.CFrame * CFrame.new(0, 1, 0)
            lastFarm = tick()
        end
    end
end))

-- Anti-Knife
TrackConnection(RunService.Heartbeat:Connect(function()
    if not Settings.AntiKnife then return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and GetPlayerRole(plr) == "Murderer" then
            local mChar = plr.Character
            if mChar and mChar:FindFirstChild("HumanoidRootPart") then
                local mHrp = mChar.HumanoidRootPart
                local dist = (char.HumanoidRootPart.Position - mHrp.Position).Magnitude
                
                if dist < 12 then
                    local escapeDir = (char.HumanoidRootPart.Position - mHrp.Position).Unit
                    char.HumanoidRootPart.CFrame = CFrame.new(char.HumanoidRootPart.Position + escapeDir * 15)
                end
            end
        end
    end
end))

-- Auto-Grab Gun
TrackConnection(RunService.Heartbeat:Connect(function()
    if not Settings.AutoGrabGun then return end
    
    local gun = GetGunDrop()
    local char = LocalPlayer.Character
    if gun and char and char:FindFirstChild("HumanoidRootPart") then
        local hrp = char.HumanoidRootPart
        local gunPart = gun:IsA("Model") and gun.PrimaryPart or gun
        
        if gunPart and (hrp.Position - gunPart.Position).Magnitude < 15 then
            hrp.CFrame = gunPart.CFrame * CFrame.new(0, 1, 0)
            if firetouchinterest then
                pcall(function()
                    firetouchinterest(hrp, gunPart, 0)
                    firetouchinterest(hrp, gunPart, 1)
                end)
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

-- FullBright & NoFog
TrackConnection(RunService.Heartbeat:Connect(function()
    if Settings.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    end
    
    if Settings.NoFog then
        Lighting.FogEnd = 100000
    end
end))

-- Aimbot
TrackConnection(RunService.RenderStepped:Connect(function()
    if not Settings.Aimbot then return end
    
    local cam = SafeGetCamera()
    if not cam then return end
    
    local target = nil
    local minDist = Settings.AimbotFOV
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and GetPlayerRole(plr) == "Murderer" and plr.Character then
            local head = plr.Character:FindFirstChild("Head")
            if head then
                local pos, onScreen = cam:WorldToScreenPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if dist < minDist then
                        minDist = dist
                        target = plr
                    end
                end
            end
        end
    end
    
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local head = target.Character.Head
        local targetPos = head.Position
        local currentCFrame = cam.CFrame
        local newCFrame = CFrame.new(currentCFrame.Position, targetPos)
        
        if Settings.Smoothness > 1 then
            cam.CFrame = currentCFrame:Lerp(newCFrame, 1 / Settings.Smoothness)
        else
            cam.CFrame = newCFrame
        end
    end
end))

-- Kill Aura
TrackConnection(RunService.RenderStepped:Connect(function()
    if not Settings.KillAura then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local knife = char:FindFirstChild("Knife")
    if not knife then return end
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = plr.Character.HumanoidRootPart
            local dist = (char.HumanoidRootPart.Position - hrp.Position).Magnitude
            
            if dist < Settings.KillRadius then
                if knife:FindFirstChild("Stab") then
                    knife.Stab:FireServer()
                end
                if mouse1click then mouse1click() end
            end
        end
    end
end))

-- Периодическое обновление ESP
TrackConnection(RunService.Heartbeat:Connect(function()
    if Settings.PlayerESP then
        if tick() % 2 < 0.05 then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local currentRole = GetPlayerRole(plr)
                    local cached = ESPCache.PlayerRoles[plr]
                    if cached and cached.Role ~= currentRole then
                        InvalidateRoleCache(plr)
                        UpdatePlayerESP()
                    end
                end
            end
        end
    end
end))

-- Spectate мониторинг
TrackConnection(RunService.Heartbeat:Connect(function()
    if UtilityState.IsSpectating and UtilityState.SpectateTarget then
        local target = UtilityState.SpectateTarget
        if not target or not target.Parent then
            StopSpectate()
            return
        end
        
        local targetChar = target.Character
        if not targetChar or not targetChar:FindFirstChild("Humanoid") then
            StopSpectate()
            return
        end
        
        -- Проверяем, что камера всё ещё следит за целью
        local cam = SafeGetCamera()
        if cam and cam.CameraSubject ~= targetChar.Humanoid then
            cam.CameraSubject = targetChar.Humanoid
            cam.CameraType = Enum.CameraType.Attach
        end
    end
end))

-- ================================================================= --
-- 11. ПОЛНАЯ ОЧИСТКА
-- ================================================================= --
local function FullCleanup()
    -- Очищаем ESP
    for _, hl in pairs(ESPCache.PlayerHighlights) do
        pcall(function() hl:Destroy() end)
    end
    ESPCache.PlayerHighlights = {}
    
    for _, hl in pairs(ESPCache.CoinHighlights) do
        pcall(function() hl:Destroy() end)
    end
    ESPCache.CoinHighlights = {}
    
    if ESPCache.GunHighlight then
        pcall(function() ESPCache.GunHighlight:Destroy() end)
        ESPCache.GunHighlight = nil
    end
    
    -- Очищаем соединения Backpack
    for player, connections in pairs(ESPCache.PlayerBackpackConnections) do
        for _, conn in pairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
    end
    ESPCache.PlayerBackpackConnections = {}
    
    -- Восстанавливаем Noclip
    for part, originalValue in pairs(OriginalCollision) do
        if part and part.Parent then
            pcall(function() part.CanCollide = originalValue end)
        end
    end
    OriginalCollision = {}
    
    -- Очищаем полёт
    if FlyData.BodyVelocity then
        FlyData.BodyVelocity:Destroy()
        FlyData.BodyVelocity = nil
    end
    if FlyData.BodyGyro then
        FlyData.BodyGyro:Destroy()
        FlyData.BodyGyro = nil
    end
    FlyData.Active = false
    
    -- Удаляем Teleport Tool
    if UtilityState.TeleportTool then
        UtilityState.TeleportTool:Destroy()
        UtilityState.TeleportTool = nil
    end
    
    -- Останавливаем Spectate
    if UtilityState.IsSpectating then
        StopSpectate()
    end
    
    -- Восстанавливаем камеру
    local cam = SafeGetCamera()
    if cam then
        cam.CameraSubject = LocalPlayer.Character
        cam.CameraType = Enum.CameraType.Custom
    end
    
    -- Восстанавливаем освещение
    Lighting.Brightness = OriginalLighting.Brightness or 1
    Lighting.ClockTime = OriginalLighting.ClockTime or 14
    Lighting.FogEnd = OriginalLighting.FogEnd or 10000
    Lighting.Ambient = OriginalLighting.Ambient or Color3.fromRGB(127, 127, 127)
    Lighting.OutdoorAmbient = OriginalLighting.OutdoorAmbient or Color3.fromRGB(127, 127, 127)
    
    -- Удаляем Utility Objects
    for _, obj in pairs(UtilityObjects) do
        pcall(function() obj:Destroy() end)
    end
    UtilityObjects = {}
    
    -- Отключаем все соединения
    CleanupConnections()
end

-- Безопасная очистка
local function SafeCleanup()
    task.spawn(FullCleanup)
end

-- Подписываемся на закрытие окна
if Window and Window.Close then
    local oldClose = Window.Close
    Window.Close = function(...)
        SafeCleanup()
        if oldClose then
            return oldClose(...)
        end
    end
end

-- Очистка при выходе
TrackConnection(LocalPlayer:GetPropertyChangedSignal("Parent"):Connect(function()
    if not LocalPlayer.Parent then
        SafeCleanup()
    end
end))

-- ================================================================= --
-- 12. ЗАПУСК
-- ================================================================= --
task.wait(0.5)
ApplyMovementSettings()
UpdateAllESP()
RefreshPlayerList()

Rayfield:Notify({
    Title = "WIA HUB v12.6",
    Content = "Расширенная версия. Готов к работе!",
    Duration = 5
})

print("WIA HUB v12.6 Loaded Successfully!")
print("Extended version with Player List, Teleport Tool, and IY Utilities!")