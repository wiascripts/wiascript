-- Очистка старых интерфейсов
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local Client = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Mouse = Client:GetMouse()

local guiName = "MM2FullNativeGui"
if CoreGui:FindFirstChild(guiName) then CoreGui[guiName]:Destroy() end
if Client.PlayerGui:FindFirstChild(guiName) then Client.PlayerGui[guiName]:Destroy() end

-- Создание главного контейнера
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
local success = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = Client.PlayerGui end

-- Главное окно
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 420)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 1
MainFrame.BorderColor3 = Color3.fromRGB(255, 50, 50)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Заголовок
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Text = "MM2 Full Native Script (No Loader Errors)"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Навигация по вкладкам
local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(1, 0, 0, 30)
TabHolder.Position = UDim2.new(0, 0, 0, 30)
TabHolder.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TabHolder.Parent = MainFrame

local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 1, -60)
TabContainer.Position = UDim2.new(0, 0, 0, 60)
TabContainer.BackgroundTransparency = 1
TabContainer.Parent = MainFrame

local tabs = {}
local currentTab = nil

local function CreateTab(name)
    local tabBtn = Instance.new("TextButton")
    tabBtn.Size = UDim2.new(0.333, 0, 1, 0)
    tabBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    tabBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabBtn.Text = name
    tabBtn.Font = Enum.Font.SourceSansBold
    tabBtn.TextSize = 14
    tabBtn.Parent = TabHolder
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 2, 0)
    scroll.ScrollBarThickness = 4
    scroll.Visible = false
    scroll.Parent = TabContainer

    local list = Instance.new("UIListLayout")
    list.Parent = scroll
    list.Padding = UDim.new(0, 5)
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center

    tabBtn.MouseButton1Click:Connect(function()
        for _, t in pairs(tabs) do
            t.Scroll.Visible = false
            t.Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
            t.Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        scroll.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    local tabData = {Btn = tabBtn, Scroll = scroll}
    table.insert(tabs, tabData)
    if #tabs == 1 then
        scroll.Visible = true
        tabBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    return scroll
end

local MainScroll = CreateTab("Main")
local EconomyScroll = CreateTab("Economy")
local RolesScroll = CreateTab("Roles")

-- Конструкторы UI компонентов
local function AddToggle(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.92, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.TextColor3 = Color3.fromRGB(255, 80, 80)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 15
    btn.Text = text .. " [OFF]"
    btn.Parent = parent
    
    local st = false
    btn.MouseButton1Click:Connect(function()
        st = not st
        btn.Text = text .. (st and " [ON]" or " [OFF]")
        btn.TextColor3 = st and Color3.fromRGB(80, 255, 80) or Color3.fromRGB(255, 80, 80)
        callback(st)
    end)
end

local function AddButton(parent, text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.92, 0, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansSemibold
    btn.TextSize = 15
    btn.Text = text
    btn.Parent = parent
    
    btn.MouseButton1Click:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        task.wait(0.1)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        callback()
    end)
end

-- Переменные и сервисы MM2
getgenv().Whitelisted = getgenv().Whitelisted or {}
getgenv().WS = 16
getgenv().JP = 50
getgenv().FlySpeed = 50
getgenv().KnifeRange = 25
getgenv().GunAccuracy = 25

local Character, RootPart, Humanoid
local function SetCharVars()
    Character = Client.Character or Client.CharacterAdded:Wait()
    Humanoid = Character:WaitForChild("Humanoid")
    RootPart = Character:WaitForChild("HumanoidRootPart")
end
if Client.Character then SetCharVars() end
Client.CharacterAdded:Connect(SetCharVars)

-- Подсветка выроненного гана
local GunHighlight = Instance.new("Highlight", ScreenGui)
local GunHandleAdornment = Instance.new("SphereHandleAdornment", ScreenGui)
GunHighlight.FillColor = Color3.fromRGB(248, 241, 174)
GunHighlight.OutlineTransparency = 1
GunHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
GunHandleAdornment.Color3 = Color3.fromRGB(248, 241, 174)
GunHandleAdornment.Transparency = 0.2
GunHandleAdornment.AlwaysOnTop = true

local Murderer, Sheriff = nil, nil
function GetMurderer()
    for _, v in pairs(Players:GetChildren()) do 
        if v:FindFirstChild("Backpack") and v:FindFirstChild("Character") then
            if v.Backpack:FindFirstChild("Knife") or v.Character:FindFirstChild("Knife") then return v.Name end
        end
    end
    return nil
end

function GetSheriff()
    for _, v in pairs(Players:GetChildren()) do 
        if v:FindFirstChild("Backpack") and v:FindFirstChild("Character") then
            if v.Backpack:FindFirstChild("Gun") or v.Character:FindFirstChild("Gun") then return v.Name end
        end
    end
    return nil
end

-- ==================== MAIN TAB ====================
AddToggle(MainScroll, "CTRL Click TP", function(st) getgenv().ClickTP = st end)
Mouse.Button1Down:Connect(function()
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) and getgenv().ClickTP and Mouse.Target and Character then
        Character:MoveTo(Mouse.Hit.p)
    end
end)

AddToggle(MainScroll, "Speed Hack (50)", function(st)
    getgenv().Speed = st
    if Humanoid then Humanoid.WalkSpeed = st and 50 or 16 end
end)

AddToggle(MainScroll, "Jump Hack (100)", function(st)
    getgenv().Jump = st
    if Humanoid then Humanoid.JumpPower = st and 100 or 50 end
end)

-- Полёт
local flying = false
local bv, bav, cam
local buttons = {W = false, S = false, A = false, D = false, Moving = false}

local function StartFly()
    if not Client.Character or not Client.Character:FindFirstChild("Head") or flying then return end
    local c = Client.Character
    local h = c:FindFirstChild("Humanoid")
    if not h then return end
    h.PlatformStand = true
    cam = Workspace.CurrentCamera
    bv = Instance.new("BodyVelocity", c.Head)
    bav = Instance.new("BodyAngularVelocity", c.Head)
    bv.Velocity, bv.MaxForce, bv.P = Vector3.new(0,0,0), Vector3.new(10000,10000,10000), 1000
    bav.AngularVelocity, bav.MaxTorque, bav.P = Vector3.new(0,0,0), Vector3.new(10000,10000,10000), 1000
    flying = true
end

local function EndFly()
    if not Client.Character or not flying then return end
    local h = Client.Character:FindFirstChild("Humanoid")
    if h then h.PlatformStand = false end
    if bv then bv:Destroy() end
    if bav then bav:Destroy() end
    flying = false
end

UIS.InputBegan:Connect(function(input, GPE)
    if GPE then return end
    for i in pairs(buttons) do if i ~= "Moving" and input.KeyCode == Enum.KeyCode[i] then buttons[i] = true; buttons.Moving = true end end
end)
UIS.InputEnded:Connect(function(input, GPE)
    if GPE then return end
    local a = false
    for i in pairs(buttons) do
        if i ~= "Moving" then
            if input.KeyCode == Enum.KeyCode[i] then buttons[i] = false end
            if buttons[i] then a = true end
        end
    end
    buttons.Moving = a
end)

RunService.Heartbeat:Connect(function(step)
    if flying and Client.Character and Client.Character.PrimaryPart then
        local c = Client.Character
        local cf = cam.CFrame
        local ax, ay, az = cf:ToEulerAnglesXYZ()
        c:SetPrimaryPartCFrame(CFrame.new(c.PrimaryPart.Position) * CFrame.Angles(ax, ay, az))
        if buttons.Moving then
            local t = Vector3.new()
            local speed = getgenv().FlySpeed or 50
            if buttons.W then t = t + (cf.LookVector * speed) end
            if buttons.S then t = t - (cf.LookVector * speed) end
            if buttons.A then t = t - (cf.RightVector * speed) end
            if buttons.D then t = t + (cf.RightVector * speed) end
            c:TranslateBy(t * step)
        end
    end
end)

AddToggle(MainScroll, "Fly", function(st) if st then StartFly() else EndFly() end end)

AddButton(MainScroll, "Btools", function()
    for _, t in ipairs({"Clone", "GameTool", "Hammer", "Script", "Grab"}) do
        local tool = Instance.new("HopperBin", Client.Backpack)
        tool.BinType = t
    end
end)

AddButton(MainScroll, "Godmode", function()
    if Client.Character and Client.Character:FindFirstChild("Humanoid") then
        local hum = Client.Character.Humanoid
        local accs = {}
        for _, a in pairs(hum:GetAccessories()) do table.insert(accs, a:Clone()) end
        hum.Name = "boop"
        local v = hum:Clone()
        v.Parent = Client.Character
        v.Name = "Humanoid"
        task.wait(0.1)
        hum:Destroy()
        Workspace.CurrentCamera.CameraSubject = Client.Character.Humanoid
        for _, a in pairs(accs) do Client.Character.Humanoid:AddAccessory(a) end
    end
end)

AddButton(MainScroll, "Force Respawn", function()
    if Character and Character:FindFirstChild("Head") and Humanoid then
        Character.Head:Destroy()
        Humanoid.Health = 0
    end
end)

AddButton(MainScroll, "Get All Emotes", function()
    local Modules = ReplicatedStorage:FindFirstChild("Modules")
    local EmoteModule = Modules and Modules:FindFirstChild("EmoteModule")
    local Emotes = Client.PlayerGui:WaitForChild("MainGUI"):WaitForChild("Game"):FindFirstChild("Emotes")
    if EmoteModule and Emotes then
        require(EmoteModule).GeneratePage({"headless", "zombie", "zen", "ninja", "floss", "dab"}, Emotes, 'Free Emotes')
    end
end)

-- Visuals
local espFolder = Instance.new("Folder", ScreenGui)
AddToggle(MainScroll, "Player ESP", function(st) getgenv().AllEsp = st end)
AddToggle(MainScroll, "Murderer ESP", function(st) getgenv().MurderEsp = st end)
AddToggle(MainScroll, "Sheriff ESP", function(st) getgenv().SheriffEsp = st end)
AddToggle(MainScroll, "Gun ESP", function(st) getgenv().GunESP = st end)

RunService.RenderStepped:Connect(function()
    pcall(function()
        if getgenv().GunESP then
            local gundrop = Workspace:FindFirstChild("GunDrop")
            GunHighlight.Adornee = gundrop
            GunHandleAdornment.Adornee = gundrop
            if gundrop then GunHandleAdornment.Size = gundrop.Size + Vector3.new(0.05, 0.05, 0.05) end
            GunHighlight.Enabled = true
            GunHandleAdornment.Visible = true
        else
            GunHighlight.Enabled = false
            GunHandleAdornment.Visible = false
        end
    end)
end)

local function UpdateESP()
    for _, c in pairs(espFolder:GetChildren()) do c:Destroy() end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Client and p.Character and p.Character:FindFirstChild("Head") then
            local bp, char = p:FindFirstChild("Backpack"), p.Character
            local isMrd = (char and char:FindFirstChild("Knife")) or (bp and bp:FindFirstChild("Knife"))
            local isShf = (char and char:FindFirstChild("Gun")) or (bp and bp:FindFirstChild("Gun"))
            
            local show = getgenv().AllEsp or (getgenv().MurderEsp and isMrd) or (getgenv().SheriffEsp and isShf)
            if show then
                local b = Instance.new("BillboardGui", espFolder)
                b.Adornee = p.Character.Head
                b.Size = UDim2.new(0, 100, 0, 30)
                b.AlwaysOnTop = true
                
                local t = Instance.new("TextLabel", b)
                t.Size = UDim2.new(1,0,1,0)
                t.BackgroundTransparency = 1
                t.Font = Enum.Font.SourceSansBold
                t.TextSize = 14
                t.Text = p.Name
                t.TextColor3 = isMrd and Color3.new(1,0,0) or (isShf and Color3.new(0,0,1) or Color3.new(0,1,0))
            end
        end
    end
end
RunService.RenderStepped:Connect(function() UpdateESP() end)

local function Xray(obj, trans)
    for _, v in pairs(obj:GetChildren()) do
        if v:IsA("BasePart") and not v.Parent:FindFirstChild("Humanoid") then v.LocalTransparencyModifier = trans end
        Xray(v, trans)
    end
end
AddToggle(MainScroll, "Xray", function(st) Xray(Workspace, st and 0.75 or 0) end)

AddButton(MainScroll, "Unlock Workspace", function()
    local function unlock(obj)
        for _, v in pairs(obj:GetChildren()) do
            if v:IsA("BasePart") then v.Locked = false end
            unlock(v)
        end
    end
    unlock(Workspace)
end)

AddButton(MainScroll, "TP to Lobby", function()
    if RootPart then RootPart.CFrame = CFrame.new(-121, 138, 38) end
end)

AddButton(MainScroll, "TP to Map", function()
    for _, child in pairs(Workspace:GetDescendants()) do
        if child:IsA("BasePart") and child.Name == "Coin_Server" then
            if RootPart and child.Parent and child.Parent.Parent:FindFirstChild("Map") then
                RootPart.CFrame = CFrame.new(child.Parent.Parent.Map.Part.Position)
            end
        end
    end
end)

-- ==================== ECONOMY TAB ====================
getgenv().AutofarmMethod = "Coins"
AddButton(MainScroll, "Method: Coins / XP (Click to Switch)", function()
    getgenv().AutofarmMethod = (getgenv().AutofarmMethod == "Coins") and "XP" or "Coins"
    print("Autofarm Method set to: " .. getgenv().AutofarmMethod)
end)

AddToggle(EconomyScroll, "Autofarm", function(st)
    getgenv().Autofarm = st
    task.spawn(function()
        while getgenv().Autofarm do
            task.wait()
            if getgenv().AutofarmMethod == "Coins" then
                local CoinContainer = Workspace:FindFirstChild("CoinContainer", true)
                if CoinContainer and Client.PlayerGui.MainGUI.Game.CashBag.Visible then
                    local coin = CoinContainer:FindFirstChild("Coin_Server")
                    if coin and RootPart then
                        repeat
                            RootPart.CFrame = CFrame.new(coin.Position - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(180))
                            RunService.Stepped:Wait()
                        until not coin:IsDescendantOf(Workspace) or coin.Name ~= "Coin_Server" or not getgenv().Autofarm
                        task.wait(1.8)
                    end
                else task.wait(1.5) end
            else
                if Client.PlayerGui.MainGUI.Game.CashBag.Visible and RootPart then
                    RootPart.CFrame = CFrame.new(-121, 138, 38)
                end
                task.wait(0.5)
            end
        end
    end)
end)

-- ==================== ROLES TAB ====================
AddToggle(RolesScroll, "Sheriff Silent Aim", function(st) getgenv().SheriffAim = st end)

local lastCFrame
AddButton(RolesScroll, "Get Gun (Teleport Drop)", function()
    local gundrop = Workspace:FindFirstChild("GunDrop")
    if gundrop and not lastCFrame and RootPart then
        lastCFrame = RootPart.CFrame
        pcall(function()
            repeat
                RootPart.CFrame = gundrop.CFrame
                RunService.Stepped:Wait()
            until not gundrop:IsDescendantOf(Workspace)
            RootPart.CFrame = lastCFrame
            lastCFrame = nil
        end)
    end
end)

AddToggle(RolesScroll, "Kill Aura", function(st) getgenv().KnifeAura = st end)

AddButton(RolesScroll, "Kill All", function()
    pcall(function()
        local Knife = Client.Backpack:FindFirstChild("Knife") or (Client.Character and Client.Character:FindFirstChild("Knife"))
        if Knife then
            if Knife.Parent.Name == "Backpack" and Humanoid then Humanoid:EquipTool(Knife) end
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= Client and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    if not table.find(getgenv().Whitelisted, v.Name) then
                        local EnemyRoot = v.Character.HumanoidRootPart
                        VirtualUser:ClickButton1(Vector2.new())
                        if firetouchinterest then
                            firetouchinterest(Knife.Handle, EnemyRoot, 0)
                            firetouchinterest(Knife.Handle, EnemyRoot, 1)
                        end
                    end
                end
            end
        end
    end)
end)

-- Цикл Kill Aura
local lastAttack = tick()
RunService.Heartbeat:Connect(function()
    if not getgenv().KnifeAura or (tick() - lastAttack) < 0.1 then return end
    pcall(function()
        local Knife = Client.Backpack:FindFirstChild("Knife") or (Client.Character and Client.Character:FindFirstChild("Knife"))
        if Knife and Knife:IsA("Tool") and RootPart then
            for _, v in ipairs(Players:GetPlayers()) do
                if v ~= Client and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
                    if not table.find(getgenv().Whitelisted, v.Name) then
                        local EnemyRoot = v.Character.HumanoidRootPart
                        if (EnemyRoot.Position - RootPart.Position).Magnitude <= getgenv().KnifeRange then
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
        end
    end)
end)

-- Трекинг маньяка и шерифа
task.spawn(function()
    while task.wait(1) do
        pcall(function()
            Murderer = GetMurderer()
            Sheriff = GetSheriff()
        end)
    end
end)

-- Silent Aim Hook
if hookmetamethod then
    local GunHook
    GunHook = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }
        if not checkcaller() and typeof(self) == "Instance" then
            if self.Name == "ShootGun" and method == "InvokeServer" then
                if getgenv().SheriffAim and Murderer then
                    local targetPlayer = Players:FindFirstChild(tostring(Murderer))
                    if targetPlayer and targetPlayer.Character and targetPlayer.Character.PrimaryPart then
                        local Root = targetPlayer.Character.PrimaryPart
                        local Veloc = Root.AssemblyLinearVelocity
                        args[2] = Root.Position + (Veloc * Vector3.new(0.125, 0, 0.125))
                    end
                end
            end
        end
        return GunHook(self, unpack(args))
    end)
end