local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Settings = {
    AutoParry = true,
    AutoHit = true,
    SpamDetect = true,
    Prediction = 0.2,
    Keybind = Enum.KeyCode.LeftControl,
    Notifications = true,
    SwordSkin = "Default"
    KillEffect = "Default"
}

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

local Network = {
    SwordUpdate = Instance.new("RemoteEvent")
    KillEffect = Instance.new("RemoteEvent")
}

Network.SwordUpdate.Name = "SwordSkinUpdate"
Network.KillEffect.Name = "GlobalKillEffect"
Network.SwordUpdate.Parent = ReplicatedStorage
Network.KillEffect.Parent = ReplicatedStorage

local BallCache = {}
local LastBallCheck = 0

local function FindBall()
    local now = tick()
    if now - LastBallCheck < 0.1 and BallCache.Ball and BallCache.Ball.Parent then
        return BallCache.Ball
    end

    LastBallCheck = now
    for _, obj in ipair(workspace:GetDescendants()) do
        if obj.Name == "Ball" and obj:FindFirstChild("BallScript") then
           BallCache.Ball = obj
           return obj
        end
    end
    BallCache.Ball = nil
    return nil
end

local CurrentSword = nil
local function ApplySwordSkin()
    if not LocalPlayer.Character then return end

    local sword = LocalPlayer.Character:FindFirstChild("Sword") or
                  LocalPlayer.Character:FindFirstChildOfClass("Tool")

    if sword and sword ~= CurrentSword then
        CurrentSword = sword
        local handle = sword:FindFirstChild("Handle")
        if handle then
            local mesh = handle:FindFirstChildOfClass("SpecialMesh") or
                        handle:FindFirstChildOfClass("MeshPart")
            if mesh then
                local skin = SwordSkins[Settings.SwordSkin]
                if skin.Texture ~= "" then
                    mesh.TextureId = skin.Texture
                end
                handle.Color = skin.Color

                Network.SwordUpdate:FireServer({
                    UserId = LocalPlayer.UserId,
                    Skin = Settings.SwordSkin
                })
            end
        end
    end
end

local function ApplyKillEffect(target)
    if Settings.KillEffect == "Default" then return end

    local character = target and target.Character
    if not character then return end

    local humanoidBootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidBootPart then return end

    local effect = KillEffects[Settings.KillEffect]
    if not effect then return end

    Netwirk.KillEffect:FireServer({
        Effect = Settings.KillEffect,
        Position = humanoidBootPart.Position,
        UserId = LocalPlayer.UserId,
        TargetUserId = target.UserId
    })
end

Network.SwordUpdate.OnClientEvent:Connect(function(data)
    local player = Players:GetPlayerByUserId(data.UserId)
    if player and player ~= LocalPlayer then
        local sword = player.Character and (player.Character:FindFirstChild("Sword") or
                      player.Character:FindFirstChildOfClass("Tool"))
        if sword then
            local handle = sword:FindFirstChild("Handle")
            if handle then
                local mesh = handle:FindFirstChildOfClass("SpecialMesh") or
                            handle:FindFirstChildOfClass("MeshPart")
                if mesh then
                    local skin = SwordSkins[data.Skim]
                    if skin then
                        if skin.Texture ~= "" then
                            mesh.TextureId = skin.Texture
                        end
                        handle.Color = skin.Color
                    end
                end
            end
        end
    end
end)

Network.KillEffect.OnClientEvent:Connect(function(data)
    local effect = KillEffects[data.Effect]
    in not effect then return end
    
    local sound = Instance.new("Sound")
    sound.SoundId = effect.Sound
    sound.Volume = 1
    sound.Parent = workspace
    sound:Play()

    local particle = Instance.new("ParticleEmitter")
    particle.Texture = effect.Particle
    particle.LightEmission = 1
    particle.Size = NumberSequence.new(1)
    particle.Parent = workspace
    particle:Emit(50)

    game:GetService("Debris"):AddItem(sound, 3)
    game:GetService("Debris"):AddItem(particle, 3)
end)

local LastParry = 0
local function AutoParry()
    if not Settings.AutoParry then return end

    local new = tick()
    if not - LastParry < 0.5 then return end

    local ball = FindBall()
    if ball and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local distance = (rootPart.Position - ball.Position).Magnitude
            if distance < 25 then
                LastParry = now
                ReplicatedStorage.Events.Parry:FireServer()
                if Settings.Notifications then
                    Library:Notify("Auto Parry Activated!", 2)
                end
            end
        end
    end
end

local function AutoHit()
    if not Settings.AutoHit then return end

    local ball = FindBall()
    if ball and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local predictedPosition = ball.Position + (ball.Velocity * Settings.Prediction)
            ReplicatedStorage.Events.HitBall:FireServer(predictedPosition)
        end
    end
end

local lastHitTimes = {}
local function SpamDetect()
    if not Settings.SpamDetect then return end

    local ball = FindBall()
    if ball then
        table.insert(lastHitTime, tick())

        while #lastHitTimes > 0 and (tick() - lastHitTimes[1]) > 3 do
            table.remove(lastHitTimes, 1)
        end

        if #lastHitTimes > 5 and Settings.Notifications then
            Library:Notify("Spam Detected!", 2)
        end
    end
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/sourse"))()
local Window = Library:CreateWindow({
    Name = "Blade Ball Ultimate",
    LoadingTitle = "Loading Ultimate Blade Ball Script...",
    LoadingSubtitle = "by Arise"
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BladeBallConfig",
        FileName = "Config.json"
    }
})

local CombatTab = Window:CreateTab("Combat")
CombatTab:CreateToggle({
    Name = 'Auto Parry',
    CurrentValue = Settings.AutoParry,
    Flag = 'AutoParryToggle',
    Callback = function(value)
        Settings.AutoParry = value
    end
})

CombatTab:CreateToggle({
    Name = '100% Hit Ball',
    CurrentValue = Settings.AutoHit,
    Flag = 'AutoHitToggle',
    Callback = function(value)
        Settings.AutoHit = value
    end
})

CombatTab:CreateSlider({
    Name = 'Prediction',
    Range = {0.1, 0.5},
    Increment = 0.05,
    Suffix = "sec",
    CurrentValue = Settings.Prediction,
    Flag = "PredictionSlider",
    Callback = function(value)
        Settings.Prediction = value
    end
})

local CosmeticsTab = Window:CreateTab("Cosmetics")
CosmeticsTab:CreateDropdown({
    Name = "Sword Skin",
    Options = {"Default", "Gold", "Ice", "Fire", "Dark", "Galaxy", "Rainbow", "Void", "Lightning", "Diamond", "Blood", "Angel", "Demon"},
    CurrentOption = Settings.SwordSkin,
    Flag = 'SwordSkinDropdown',
    Callback = function(value)
        Settings.SwordSkin = value
        ApplySwordSkin()
    end
})

CosmeticsTab:CreateDropdown({
    Name = "Kill Effect",
    Options = {"Default", "Blood", "Explosion", "Lightning", "Smoke", "Galaxy", "Void", "Fire", "Ice", "Confetti", "Angelic", "Demonic"},
    CurrentOption = Settings.KillEffect,
    Flag = "KillEffectDropdown",
    Callback = function(value)
        Settings.KillEffect = value
    end
})

UIS.InputBegan:Connect(function(input)
    if input.KeyCode == Settings.Leybind then
        Library:Destroy()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    ApplySwordSkin()
end)

ApplySwordSkin()
Library:Notify("Script loadedZ! Press LeftControl to close GUI.")
