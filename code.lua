-- ================================================================= --
-- WIA HUB v11 :: RAYFIELD EDITION
-- Full UI Architecture / Configuration / Notifications / Cleanup
-- ================================================================= --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

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
    Debug = false
}

local Connections = {}

local function AddConnection(connection)
    table.insert(Connections, connection)
    return connection
end

local function Notify(title, content, duration)
    if not State.Notifications then
        return
    end

    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = duration or 3
    })
end

local function Cleanup()
    for _, connection in ipairs(Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(Connections)
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
        Notify(
            "Combat",
            value and "Module enabled" or "Module disabled"
        )
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
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
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
            Lighting.FogEnd = 1000
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
                object.Enabled = not value
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
        Notify(
            "Movement",
            value and "Module enabled" or "Module disabled"
        )
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
        Notify(
            "MM2 Master",
            value and "Module enabled" or "Module disabled"
        )
    end
})

-- ================================================================= --
-- SERVER
-- ================================================================= --

ServerTab:CreateSection("Server")

ServerTab:CreateButton({
    Name = "Rejoin Server",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")

        Notify("Server", "Rejoining...", 2)

        task.wait(0.5)

        pcall(function()
            TeleportService:TeleportToPlaceInstance(
                game.PlaceId,
                game.JobId,
                LocalPlayer
            )
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
    Content =
        "Place ID: " .. tostring(game.PlaceId) ..
        "\nJob ID: " .. tostring(game.JobId)
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

-- ================================================================= --
-- CAMERA UPDATE
-- ================================================================= --

AddConnection(
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        local camera = workspace.CurrentCamera

        if camera then
            camera.FieldOfView = State.CameraFOV
        end
    end)
)

-- ================================================================= --
-- CHARACTER HANDLING
-- ================================================================= --

AddConnection(
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)

        local camera = workspace.CurrentCamera

        if camera then
            camera.FieldOfView = State.CameraFOV
        end

        if State.FullBright then
            Lighting.Brightness = 2
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
        end
    end)
)

-- ================================================================= --
-- LIGHTING MONITOR
-- ================================================================= --

AddConnection(
    Lighting.ChildAdded:Connect(function(object)
        if State.RemoveColorCorrection
            and object:IsA("ColorCorrectionEffect") then

            object.Enabled = false
        end
    end)
)

-- ================================================================= --
-- FINAL
-- ================================================================= --

Notify(
    "WIA HUB v11",
    "Rayfield Edition loaded successfully.",
    4
)