-- Убираем старые версии GUI
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")

local guiName = "SimpleMM2Gui"
if CoreGui:FindFirstChild(guiName) then CoreGui[guiName]:Destroy() end
if Client.PlayerGui:FindFirstChild(guiName) then Client.PlayerGui[guiName]:Destroy() end

-- Создаем экран
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
-- Пытаемся поместить в CoreGui, если экзекутор не дает - в PlayerGui
local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = Client.PlayerGui end

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 350)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -175)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
MainFrame.BorderSizePixel = 2
MainFrame.BorderColor3 = Color3.fromRGB(200, 0, 0)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "MM2 Native GUI (No Errors)"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Скролл для кнопок
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, 0, 1, -30)
Scroll.Position = UDim2.new(0, 0, 0, 30)
Scroll.BackgroundTransparency = 1
Scroll.CanvasSize = UDim2.new(0, 0, 1.5, 0)
Scroll.ScrollBarThickness = 5
Scroll.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Parent = Scroll
UIListLayout.Padding = UDim.new(0, 5)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Функция создания переключателя (Toggle)
local function CreateToggle(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 16
    btn.Text = text .. " [OFF]"
    btn.Parent = Scroll
    
    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.Text = text .. (state and " [ON]" or " [OFF]")
        btn.TextColor3 = state and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
        callback(state)
    end)
end

-- Функция создания кнопки (Button)
local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 16
    btn.Text = text
    btn.Parent = Scroll
    
    btn.MouseButton1Click:Connect(function()
        local oldColor = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        task.wait(0.1)
        btn.BackgroundColor3 = oldColor
        callback()
    end)
end

-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
getgenv().KnifeRange = 25
getgenv().KnifeAura = false
getgenv().AllEsp = false
local espFolder = Instance.new("Folder", ScreenGui)
espFolder.Name = "ESP_Folder"

-- == ЛОГИКА ESP ==
local function UpdateESP()
    for _, child in pairs(espFolder:GetChildren()) do child:Destroy() end
    if not getgenv().AllEsp then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Client and player.Character and player.Character:FindFirstChild("Head") then
            local bp = player:FindFirstChild("Backpack")
            local char = player.Character
            
            local color = Color3.new(0, 1, 0) -- Зеленый (мирный)
            local role = "Innocent"
            
            if (char and char:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife")) then
                color = Color3.new(1, 0, 0) -- Красный (Маньяк)
                role = "Murderer"
            elseif (char and char:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun")) then
                color = Color3.new(0, 0, 1) -- Синий (Шериф)
                role = "Sheriff"
            end

            local billboard = Instance.new("BillboardGui", espFolder)
            billboard.Adornee = player.Character.Head
            billboard.Size = UDim2.new(0, 100, 0, 40)
            billboard.AlwaysOnTop = true

            local txt = Instance.new("TextLabel", billboard)
            txt.Size = UDim2.new(1, 0, 1, 0)
            txt.BackgroundTransparency = 1
            txt.Text = player.Name .. "\n[" .. role .. "]"
            txt.TextColor3 = color
            txt.TextStrokeTransparency = 0
            txt.Font = Enum.Font.SourceSansBold
            txt.TextSize = 14
        end
    end
end

RunService.RenderStepped:Connect(function()
    if getgenv().AllEsp and task.wait(1) then
        UpdateESP()
    end
end)

-- == СОЗДАНИЕ КНОПОК В GUI ==

CreateToggle("Speed & Jump Hack", function(state)
    local char = Client.Character
    if char and char:FindFirstChild("Humanoid") then
        if state then
            char.Humanoid.WalkSpeed = 50
            char.Humanoid.JumpPower = 100
        else
            char.Humanoid.WalkSpeed = 16
            char.Humanoid.JumpPower = 50
        end
    end
end)

CreateToggle("ESP (Show All Roles)", function(state)
    getgenv().AllEsp = state
    if not state then
        for _, child in pairs(espFolder:GetChildren()) do child:Destroy() end
    end
end)

CreateToggle("Kill Aura (Murderer)", function(state)
    getgenv().KnifeAura = state
end)

CreateButton("Kill All (Need Knife)", function()
    local char = Client.Character
    local Knife = Client.Backpack:FindFirstChild("Knife") or (char and char:FindFirstChild("Knife"))
    
    if Knife and char and char:FindFirstChild("HumanoidRootPart") then
        if Knife.Parent.Name == "Backpack" then char.Humanoid:EquipTool(Knife) end
        
        for _, v in pairs(Players:GetPlayers()) do
            if v ~= Client and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local EnemyRoot = v.Character.HumanoidRootPart
                VirtualUser:ClickButton1(Vector2.new())
                if firetouchinterest then
                    firetouchinterest(Knife.Handle, EnemyRoot, 0)
                    firetouchinterest(Knife.Handle, EnemyRoot, 1)
                end
            end
        end
    end
end)

CreateButton("GodMode", function()
    if Client.Character and Client.Character:FindFirstChild("Humanoid") then
        local hum = Client.Character.Humanoid
        local accessories = {}
        for _, acc in pairs(hum:GetAccessories()) do table.insert(accessories, acc:Clone()) end
        
        hum.Name = "boop"
        local newHum = hum:Clone()
        newHum.Parent = Client.Character
        newHum.Name = "Humanoid"
        task.wait(0.1)
        hum:Destroy()
        Workspace.CurrentCamera.CameraSubject = Client.Character.Humanoid
        for _, acc in pairs(accessories) do Client.Character.Humanoid:AddAccessory(acc) end
    end
end)

CreateButton("Hide GUI (F9 to check errors)", function()
    ScreenGui:Destroy()
end)

-- Цикл Kill Aura
local lastAttack = tick()
RunService.Heartbeat:Connect(function()
    if not getgenv().KnifeAura then return end
    if (tick() - lastAttack) < 0.1 then return end
    
    local char = Client.Character
    local Knife = Client.Backpack:FindFirstChild("Knife") or (char and char:FindFirstChild("Knife"))
    
    if Knife and Knife:IsA("Tool") and char and char:FindFirstChild("HumanoidRootPart") then
        local RootPart = char.HumanoidRootPart
        for _, v in ipairs(Players:GetPlayers()) do
            if v ~= Client and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                local EnemyRoot = v.Character.HumanoidRootPart
                local Distance = (EnemyRoot.Position - RootPart.Position).Magnitude
                if Distance <= getgenv().KnifeRange then
                    VirtualUser:ClickButton1(Vector2.new())
                    if firetouchinterest then
                        firetouchinterest(Knife.Handle, EnemyRoot, 0)
                        firetouchinterest(Knife.Handle, EnemyRoot, 1)
                    end
                    lastAttack = tick()
                end
            end
        end
    end
end)