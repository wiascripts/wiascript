--<>----<>----<>----<>----<>----<>----<>--
repeat wait() until game:IsLoaded() wait()
game:GetService("Players").LocalPlayer.Idled:connect(function()
    game:GetService("VirtualUser"):ClickButton2(Vector2.new());
end);
--<>----<>----<>----<>----<>----<>----<>--

-- Обход ошибки с HTTP
pcall(function()
    for i, v in pairs(getconnections(game:GetService("ScriptContext").Error)) do
        v:Disable();
    end;
end);

--<>----<>----<>----<>----<>----<>----<>--
local Workspace = game:GetService('Workspace');
local ReplicatedStorage = game:GetService('ReplicatedStorage');
local Players = game:GetService('Players');
local Client = Players.LocalPlayer;
local RunService = game:GetService('RunService');
local UIS = game:GetService("UserInputService");
local CoreGui = game:GetService("CoreGui");
local Camera = Workspace.CurrentCamera;
local Mouse = Client:GetMouse();
local VirtualUser = game:GetService("VirtualUser");
local HttpService = game:GetService("HttpService");

--<>----<>----<>----<>----<>----<>----<>--
-- ЗАГРУЗКА БИБЛИОТЕКИ С ОБРАБОТКОЙ ОШИБОК
local Library = nil;
local success, err = pcall(function()
    Library = loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/Drifter0507/Shamrock/main/MainLibrary", true))();
end);

if not success or not Library then
    -- Если библиотека не загрузилась, создаем простую библиотеку вручную
    Library = {
        CreateWindow = function(data)
            return {
                CreateTab = function(tabData)
                    return {
                        CreateSection = function(sectionData) return {} end,
                        CreateToggle = function(toggleData) return {} end,
                        CreateSlider = function(sliderData) return {} end,
                        CreateButton = function(buttonData) return {} end,
                        CreateDropdown = function(dropdownData) return {} end,
                        CreateKeybind = function(keybindData) return {} end,
                        CreateLabel = function(labelData) return { Title = "Label" } end,
                        updateLabel = function(label, text, color) end
                    }
                end
            }
        end
    }
    warn("Библиотека не загрузилась, используются базовые функции")
end
--<>----<>----<>----<>----<>----<>----<>--

local Character = nil;
local RootPart = nil;
local Humanoid = nil;

getgenv().WS = 16
getgenv().JP = 50

function SetCharVars()
    Character = Client.Character;
    if not Character then return end
    Humanoid = Character:FindFirstChild("Humanoid") or Character:WaitForChild("Humanoid");
    RootPart = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart");
    if getgenv().WS then
        Humanoid.WalkSpeed = getgenv().WS;
    end;
    if getgenv().JP then
        Humanoid.JumpPower = getgenv().JP;
    end;
end;

-- Ожидаем появления персонажа
repeat wait() until Client.Character
SetCharVars();
Client.CharacterAdded:Connect(SetCharVars);

--<>----<>----<>----<>----<>----<>----<>--
-- СОЗДАНИЕ GUI
local Window = Library:CreateWindow({Title = "Whitewia Hub"});
local Tab1 = Window:CreateTab({Title = "Whitewia Hub - Main", ScrollBar = false});
local Tab2 = Window:CreateTab({Title = "Whitewia Hub - Economy", ScrollBar = false});
local Tab3 = Window:CreateTab({Title = "Whitewia Hub - Roles", ScrollBar = false});

--<>----<>----<>----<>----<>----<>----<>--
local ClientSection = Tab1:CreateSection({Title = "Whitewia Hub - Client"});
local WorldSection = Tab1:CreateSection({Title = "Whitewia Hub - World"});
local AutofarmSection = Tab2:CreateSection({Title = "Whitewia Hub - Autofarm"});
local MurderSection = Tab3:CreateSection({Title = "Whitewia Hub - Murderer"});
local SheriffSection = Tab3:CreateSection({Title = "Whitewia Hub - Sheriff"});

--<>----<>----<>----<>----<>----<>----<>--
-- Клик-телепорт
ClientSection:CreateToggle({
    Title = "CTRL click tp",
    Default = false,
    Callback = function(state)
        getgenv().ClickTP = state;
    end;
});

Mouse.Button1Down:connect(function()
    if not game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) then return end;
    if not Mouse.Target or not getgenv().ClickTP or not Character then return end;
    Character:MoveTo(Mouse.Hit.p);
end)

--<>----<>----<>----<>----<>----<>----<>--
-- Настройки скорости
ClientSection:CreateSlider({
    Title = "WalkSpeed",
    Min = 16,
    Max = 200,
    Default = 16,
    Callback = function(val)
        getgenv().WS = tonumber(val);
        if Humanoid then Humanoid.WalkSpeed = val end;
    end
});

ClientSection:CreateSlider({
    Title = "JumpPower",
    Min = 50,
    Max = 200,
    Default = 50,
    Callback = function(val)
        getgenv().JP = tonumber(val);
        if Humanoid then Humanoid.JumpPower = val end;
    end
});

--<>----<>----<>----<>----<>----<>----<>--
-- Система полета
local flying = false;
local c, h, bv, bav, cam;
local buttons = {W = false, S = false, A = false, D = false, Moving = false};

local StartFly = function()
    if not Client.Character or not Character.Head or flying then return end;
    c = Character;
    h = Humanoid;
    h.PlatformStand = true;
    cam = workspace.CurrentCamera;
    bv = Instance.new("BodyVelocity");
    bav = Instance.new("BodyAngularVelocity");
    bv.Velocity, bv.MaxForce, bv.P = Vector3.new(0, 0, 0), Vector3.new(10000, 10000, 10000), 1000;
    bav.AngularVelocity, bav.MaxTorque, bav.P = Vector3.new(0, 0, 0), Vector3.new(10000, 10000, 10000), 1000;
    bv.Parent = c.Head;
    bav.Parent = c.Head;
    flying = true;
end;

local EndFly = function()
    if not flying then return end
    h.PlatformStand = false;
    if bv then bv:Destroy() end;
    if bav then bav:Destroy() end;
    flying = false;
end;

UIS.InputBegan:connect(function(input, GPE)
    if GPE then return end;
    for i, e in pairs(buttons) do
        if i ~= "Moving" and input.KeyCode == Enum.KeyCode[i] then
            buttons[i] = true;
            buttons.Moving = true;
        end;
    end;
end);

UIS.InputEnded:connect(function(input, GPE)
    if GPE then return end;
    local a = false;
    for i, e in pairs(buttons) do
        if i ~= "Moving" then
            if input.KeyCode == Enum.KeyCode[i] then
                buttons[i] = false;
            end;
            if buttons[i] then a = true end;
        end;
    end;
    buttons.Moving = a;
end);

local setVec = function(vec)
    return vec * ((getgenv().FlySpeed or 50) / vec.Magnitude);
end;

RunService.Heartbeat:connect(function(step)
    if flying and c and c.PrimaryPart then
        local p = c.PrimaryPart.Position;
        local cf = cam.CFrame;
        local ax, ay, az = cf:toEulerAnglesXYZ();
        c:SetPrimaryPartCFrame(CFrame.new(p.x, p.y, p.z) * CFrame.Angles(ax, ay, az));
        if buttons.Moving then
            local t = Vector3.new();
            if buttons.W then t = t + (setVec(cf.lookVector)) end;
            if buttons.S then t = t - (setVec(cf.lookVector)) end;
            if buttons.A then t = t - (setVec(cf.rightVector)) end;
            if buttons.D then t = t + (setVec(cf.rightVector)) end;
            c:TranslateBy(t * step);
        end;
    end;
end);

ClientSection:CreateToggle({
    Title = "Fly",
    Default = false,
    Callback = function(state)
        getgenv().Flying = state;
        if getgenv().Flying then StartFly() else EndFly() end;
    end
});

ClientSection:CreateSlider({
    Title = "Fly speed",
    Min = 20,
    Max = 150,
    Default = 50,
    Callback = function(val)
        getgenv().FlySpeed = tonumber(val) or 50;
    end
});

--<>----<>----<>----<>----<>----<>----<>--
print("Whitewia Hub успешно загружен!");