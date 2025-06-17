-- Blade Ball Ultimate Script (Optimized FPS + GUI Fix)
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

-- Ожидаем полной загрузки игры
repeat task.wait() until game:IsLoaded()

-- Оптимизированные сервисы
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Настройки с защитой
local Settings = {
    AutoParry = true,
    AutoHit = true,
    SpamDetect = false, -- Отключено для оптимизации
    Prediction = 0.15,  -- Уменьшено для плавности
    Keybind = Enum.KeyCode.RightControl, -- Изменено для удобства
    Notifications = true,
    SwordSkin = "Default",
    KillEffect = "Default",
    MaxFPS = 60 -- Лимит FPS
}

-- Упрощенные скины (только основные)
local SwordSkins = {
    Default = {Texture = "", Color = Color3.new(1,1,1)},
    Gold = {Texture = "rbxassetid://1313131313", Color = Color3.fromRGB(255,215,0)},
    Ice = {Texture = "rbxassetid://1313131314", Color = Color3.fromRGB(0,191,255)}
}

-- Упрощенные эффекты
local KillEffects = {
    Default = {Sound = nil, Particle = nil},
    Blood = {Sound = "rbxassetid://444444444", Particle = "rbxassetid://444444445"}
}

-- Оптимизированная загрузка библиотеки
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/shlexware/Rayfield/main/source'))()
if not Rayfield then 
    warn("Rayfield не загружен!")
    return 
end

-- Создаем окно с проверкой
local Window = Rayfield:CreateWindow({
    Name = "Blade Ball [Ultimate]",
    LoadingTitle = "Загрузка интерфейса...",
    LoadingSubtitle = "Версия 2.1 (Оптимизированная)",
    ConfigurationSaving = {
        Enabled = false, -- Отключено для оптимизации
    },
    Discord = {
        Enabled = false,
        Invite = ""
    }
})

-- Основные функции с защитой
local function SafeApplySword()
    if not LocalPlayer.Character then return end
    
    local sword = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
    if sword and sword:FindFirstChild("Handle") then
        local skin = SwordSkins[Settings.SwordSkin] or SwordSkins.Default
        sword.Handle.Color = skin.Color
        if skin.Texture ~= "" then
            sword.Handle.Mesh.TextureId = skin.Texture
        end
    end
end

local function OptimizedFindBall()
    return workspace:FindFirstChild("Ball") or workspace:FindFirstChildWhichIsA("BasePart", true)
end

-- Главный цикл с контролем FPS
local lastTick = tick()
local function MainLoop()
    local ball = OptimizedFindBall()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    -- Авто-парирование
    if Settings.AutoParry and ball and rootPart then
        local distance = (rootPart.Position - ball.Position).Magnitude
        if distance < 20 then
            ReplicatedStorage.Events.Parry:FireServer()
        end
    end
    
    -- Контроль FPS
    local now = tick()
    local frameTime = 1/Settings.MaxFPS
    if (now - lastTick) < frameTime then
        task.wait(frameTime - (now - lastTick))
    end
    lastTick = tick()
end

-- Создаем интерфейс
local MainTab = Window:CreateTab("Главная", 4483362458)
MainTab:CreateToggle({
    Name = "Авто-парирование",
    CurrentValue = Settings.AutoParry,
    Callback = function(value)
        Settings.AutoParry = value
    end
})

MainTab:CreateToggle({
    Name = "Авто-удар",
    CurrentValue = Settings.AutoHit,
    Callback = function(value)
        Settings.AutoHit = value
    end
})

local VisualTab = Window:CreateTab("Внешность", 4483362458)
VisualTab:CreateDropdown({
    Name = "Скин меча",
    Options = {"Default", "Gold", "Ice"},
    CurrentOption = Settings.SwordSkin,
    Callback = function(value)
        Settings.SwordSkin = value
        SafeApplySword()
    end
})

-- Инициализация
LocalPlayer.CharacterAdded:Connect(SafeApplySword)
if LocalPlayer.Character then
    task.spawn(SafeApplySword)
end

-- Запуск оптимизированного цикла
RunService.Heartbeat:Connect(MainLoop)

-- Уведомление об успешной загрузке
Rayfield:Notify({
    Title = "Скрипт активирован",
    Content = "Нажмите RightControl для закрытия меню",
    Duration = 6.5,
    Image = 4483362458,
    Actions = {}
})

-- Закрытие по RightControl
UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.Keybind then
        Rayfield:Destroy()
    end
end)
