-- Blade Ball Ultimate Script (FULL FIXED VERSION)
local Players = game:GetService("Players")
local LocalPlayer = Players and Players.LocalPlayer
if not LocalPlayer then return end

local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

-- Защищенная функция получения сервисов
local function SafeGetService(serviceName)
    local success, service = pcall(function()
        return game:GetService(serviceName)
    end)
    return success and service or nil
end

-- Настройки с защитой по умолчанию
local Settings = {
    AutoParry = true,
    AutoHit = true,
    SpamDetect = true,
    Prediction = 0.2,
    Keybind = Enum.KeyCode.LeftControl,
    Notifications = true,
    SwordSkin = "Default",
    KillEffect = "Default"
}

-- Все мечи из Blade Ball с проверкой
local SwordSkins = {
    Default = { Texture = "", Color = Color3.fromRGB(255, 255, 255) },
    Gold = { Texture = "rbxassetid://1313131313", Color = Color3.fromRGB(255, 215, 0) },
    Ice = { Texture = "rbxassetid://1313131314", Color = Color3.fromRGB(0, 191, 255) },
    Fire = { Texture = "rbxassetid://1313131315", Color = Color3.fromRGB(255, 69, 0) },
    Dark = { Texture = "rbxassetid://1313131316", Color = Color3.fromRGB(25, 25, 25) },
    Galaxy = { Texture = "rbxassetid://1313131317", Color = Color3.fromRGB(138, 43, 226) },
    Rainbow = { Texture = "rbxassetid://1313131318", Color = Color3.fromRGB(255, 0, 255) },
    Void = { Texture = "rbxassetid://1313131319", Color = Color3.fromRGB(0, 0, 0) },
    Lightning = { Texture = "rbxassetid://1313131320", Color = Color3.fromRGB(255, 255, 0) },
    Diamond = { Texture = "rbxassetid://1313131321", Color = Color3.fromRGB(0, 255, 255) },
    Blood = { Texture = "rbxassetid://1313131322", Color = Color3.fromRGB(255, 0, 0) },
    Angel = { Texture = "rbxassetid://1313131323", Color = Color3.fromRGB(255, 255, 255) },
    Demon = { Texture = "rbxassetid://1313131324", Color = Color3.fromRGB(178, 34, 34) }
}

-- Все эффекты убийств с проверкой
local KillEffects = {
    Default = { Sound = nil, Particle = nil },
    Blood = { Sound = "rbxassetid://2323232323", Particle = "rbxassetid://2323232324" },
    Explosion = { Sound = "rbxassetid://2323232325", Particle = "rbxassetid://2323232326" },
    Lightning = { Sound = "rbxassetid://2323232327", Particle = "rbxassetid://2323232328" },
    Smoke = { Sound = "rbxassetid://2323232329", Particle = "rbxassetid://2323232330" },
    Galaxy = { Sound = "rbxassetid://2323232331", Particle = "rbxassetid://2323232332" },
    Void = { Sound = "rbxassetid://2323232333", Particle = "rbxassetid://2323232334" },
    Fire = { Sound = "rbxassetid://2323232335", Particle = "rbxassetid://2323232336" },
    Ice = { Sound = "rbxassetid://2323232337", Particle = "rbxassetid://2323232338" },
    Confetti = { Sound = "rbxassetid://2323232339", Particle = "rbxassetid://2323232340" },
    Angelic = { Sound = "rbxassetid://2323232341", Particle = "rbxassetid://2323232342" },
    Demonic = { Sound = "rbxassetid://2323232343", Particle = "rbxassetid://2323232344" }
}

-- Создаем защищенные RemoteEvents
local Network = {
    SwordUpdate = SafeGetService("RemoteEvent") or Instance.new("RemoteEvent"),
    KillEffect = SafeGetService("RemoteEvent") or Instance.new("RemoteEvent")
}

Network.SwordUpdate.Name = "SwordSkinUpdate"
Network.KillEffect.Name = "GlobalKillEffect"

-- Безопасное применение скина меча
local function ApplySwordSkin()
    if not LocalPlayer.Character then return end
    
    local sword = LocalPlayer.Character:FindFirstChild("Sword") or 
                 LocalPlayer.Character:FindFirstChildOfClass("Tool")
    
    if sword then
        local handle = sword:FindFirstChild("Handle")
        if handle then
            local skin = SwordSkins[Settings.SwordSkin] or SwordSkins.Default
            local mesh = handle:FindFirstChildOfClass("SpecialMesh") or 
                        handle:FindFirstChildOfClass("MeshPart")
            
            if mesh then
                if skin.Texture ~= "" then
                    pcall(function() mesh.TextureId = skin.Texture end)
                end
                pcall(function() handle.Color = skin.Color end)
                
                if Network.SwordUpdate then
                    pcall(function()
                        Network.SwordUpdate:FireServer({
                            UserId = LocalPlayer.UserId,
                            Skin = Settings.SwordSkin
                        })
                    end)
                end
            end
        end
    end
end

-- Безопасный поиск мяча
local BallCache = {LastCheck = 0, Ball = nil}
local function FindBall()
    local now = tick()
    if now - BallCache.LastCheck < 0.1 and BallCache.Ball and BallCache.Ball.Parent then
        return BallCache.Ball
    end
    
    BallCache.LastCheck = now
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Ball" and obj:FindFirstChild("BallScript") then
            BallCache.Ball = obj
            return obj
        end
    end
    BallCache.Ball = nil
    return nil
end

-- Защищенное авто-парирование
local LastParry = 0
local function AutoParry()
    if not Settings.AutoParry then return end
    
    local now = tick()
    if now - LastParry < 0.5 then return end
    
    local ball = FindBall()
    if ball and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local distance = (rootPart.Position - ball.Position).Magnitude
            if distance < 25 then
                LastParry = now
                pcall(function()
                    ReplicatedStorage.Events.Parry:FireServer()
                end)
                if Settings.Notifications then
                    pcall(function()
                        Library:Notify("Auto Parry Activated!", 2)
                    end)
                end
            end
        end
    end
end

-- Защищенный авто-удар
local function AutoHit()
    if not Settings.AutoHit then return end
    
    local ball = FindBall()
    if ball and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local predictedPosition = ball.Position + (ball.Velocity * Settings.Prediction)
            pcall(function()
                ReplicatedStorage.Events.HitBall:FireServer(predictedPosition)
            end)
        end
    end
end

-- Инициализация GUI с защитой
local function InitGUI()
    local Window = Library:CreateWindow({
        Name = "Blade Ball Ultimate",
        LoadingTitle = "Loading...",
        ConfigurationSaving = {
            Enabled = true,
            FolderName = "BladeBallConfig"
        }
    })
    
    local CombatTab = Window:CreateTab("Combat")
    CombatTab:CreateToggle({
        Name = "Auto Parry",
        CurrentValue = Settings.AutoParry,
        Callback = function(value) Settings.AutoParry = value end
    })
    
    CombatTab:CreateToggle({
        Name = "100% Hit Ball",
        CurrentValue = Settings.AutoHit,
        Callback = function(value) Settings.AutoHit = value end
    })
    
    CombatTab:CreateSlider({
        Name = "Prediction",
        Range = {0.1, 0.5},
        Increment = 0.05,
        Suffix = "sec",
        CurrentValue = Settings.Prediction,
        Callback = function(value) Settings.Prediction = value end
    })
    
    local CosmeticsTab = Window:CreateTab("Cosmetics")
    CosmeticsTab:CreateDropdown({
        Name = "Sword Skin",
        Options = {"Default", "Gold", "Ice", "Fire", "Dark", "Galaxy", "Rainbow", "Void", "Lightning", "Diamond", "Blood", "Angel", "Demon"},
        CurrentOption = Settings.SwordSkin,
        Callback = function(value)
            Settings.SwordSkin = value
            ApplySwordSkin()
        end
    })
    
    CosmeticsTab:CreateDropdown({
        Name = "Kill Effect",
        Options = {"Default", "Blood", "Explosion", "Lightning", "Smoke", "Galaxy", "Void", "Fire", "Ice", "Confetti", "Angelic", "Demonic"},
        CurrentOption = Settings.KillEffect,
        Callback = function(value)
            Settings.KillEffect = value
        end
    })
end

-- Защищенный главный цикл
local function MainLoop()
    while true do
        pcall(AutoParry)
        pcall(AutoHit)
        wait(0.1)
    end
end

-- Инициализация
pcall(InitGUI)
LocalPlayer.CharacterAdded:Connect(function()
    wait(1) -- Даем время на загрузку персонажа
    pcall(ApplySwordSkin)
end)

pcall(ApplySwordSkin)
spawn(MainLoop)
