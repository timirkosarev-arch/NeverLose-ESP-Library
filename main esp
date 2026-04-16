local ESPLibrary = {}
ESPLibrary.__index = ESPLibrary

-- Службы
local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local Workspace = cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

-- Кэш и Конфиги
local CameraCache = { position = Vector3.new(), cframe = CFrame.new(), lastUpdate = 0 }
local JOINT_CONFIGS = {
    R15 = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"},
        {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}
    },
    R6 = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }
}

-- Настройки по умолчанию (Полная кастомизация)
local DEFAULT_SETTINGS = {
    Enabled = true,
    TeamCheck = true,
    UseLOD = true,
    RenderDistance = 1000,
    
    -- Визуальные элементы
    Boxes = true,
    HealthBar = true,
    Names = true,
    Distances = true,
    Skeletons = false,
    Tracers = false,
    Chams = false,
    LookLines = false, -- Линия взгляда
    
    -- Цвета
    EnemyColor = Color3.fromRGB(255, 50, 50),
    TeamColor = Color3.fromRGB(50, 255, 50),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 255, 255),
    
    -- Параметры
    TracerOrigin = "Bottom", -- "Top", "Center", "Bottom"
    BoxThickness = 1.5,
    TextSize = 16,
    TracerThickness = 1,
}

-- [ Вспомогательные функции остались прежними, добавим новые ] --

function ESPLibrary:GetTeamColor(player)
    if self.Settings.TeamCheck and player.Team == LocalPlayer.Team then
        return self.Settings.TeamColor
    end
    return self.Settings.EnemyColor
end

-- Основной объект ESP
function ESPLibrary:CreateESPObject(player)
    local obj = {
        Player = player,
        Box = Drawing.new("Square"),
        BoxOutline = Drawing.new("Square"),
        HealthBar = Drawing.new("Square"),
        HealthBarOutline = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Skeleton = {},
        LookLine = Drawing.new("Line")
    }
    
    -- Инициализация базовых свойств
    obj.Box.Filled = false
    obj.BoxOutline.Filled = false
    obj.BoxOutline.Thickness = 3
    obj.BoxOutline.Transparency = 0.5
    obj.Name.Center = true
    obj.Name.Outline = true
    obj.Distance.Center = true
    obj.Distance.Outline = true
    obj.Tracer.Thickness = self.Settings.TracerThickness
    
    return obj
end

function ESPLibrary:UpdatePlayerESP(player)
    local character = player.Character
    if not character then return self:HideESP(player) end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return self:HideESP(player) end

    local pos, onScreen = CurrentCamera:WorldToViewportPoint(root.Position)
    local dist = (CurrentCamera.CFrame.Position - root.Position).Magnitude
    
    if not onScreen or dist > self.Settings.RenderDistance then 
        return self:HideESP(player) 
    end

    local esp = self.ESPObjects[player] or self:CreateESPObject(player)
    self.ESPObjects[player] = esp
    
    local color = self:GetTeamColor(player)
    
    -- Расчет размеров бокса
    local head = character:FindFirstChild("Head")
    if not head then return end
    
    local headPos = CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    local legPos = CurrentCamera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
    local height = math.abs(headPos.Y - legPos.Y)
    local width = height / 1.5
    local xPos = pos.X - width / 2
    
    -- 1. Box
    if self.Settings.Boxes then
        esp.Box.Size = Vector2.new(width, height)
        esp.Box.Position = Vector2.new(xPos, headPos.Y)
        esp.Box.Color = color
        esp.Box.Visible = true
        
        esp.BoxOutline.Size = esp.Box.Size
        esp.BoxOutline.Position = esp.Box.Position
        esp.BoxOutline.Visible = true
    else
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
    end

    -- 2. Health Bar
    if self.Settings.HealthBar then
        local healthPC = hum.Health / hum.MaxHealth
        esp.HealthBarOutline.Size = Vector2.new(4, height)
        esp.HealthBarOutline.Position = Vector2.new(xPos - 6, headPos.Y)
        esp.HealthBarOutline.Visible = true
        
        esp.HealthBar.Size = Vector2.new(2, height * healthPC)
        esp.HealthBar.Position = Vector2.new(xPos - 5, headPos.Y + (height * (1 - healthPC)))
        esp.HealthBar.Color = Color3.fromHSV(healthPC * 0.33, 1, 1)
        esp.HealthBar.Visible = true
    else
        esp.HealthBar.Visible = false
        esp.HealthBarOutline.Visible = false
    end

    -- 3. Names & Distance
    if self.Settings.Names then
        esp.Name.Text = player.Name
        esp.Name.Position = Vector2.new(pos.X, headPos.Y - 20)
        esp.Name.Color = color
        esp.Name.Visible = true
    else esp.Name.Visible = false end

    if self.Settings.Distances then
        esp.Distance.Text = math.floor(dist) .. " studs"
        esp.Distance.Position = Vector2.new(pos.X, legPos.Y + 5)
        esp.Distance.Visible = true
    else esp.Distance.Visible = false end

    -- 4. Tracers
    if self.Settings.Tracers then
        local origin = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y)
        if self.Settings.TracerOrigin == "Center" then
            origin = Vector2.new(CurrentCamera.ViewportSize.X / 2, CurrentCamera.ViewportSize.Y / 2)
        end
        esp.Tracer.From = origin
        esp.Tracer.To = Vector2.new(pos.X, legPos.Y)
        esp.Tracer.Color = color
        esp.Tracer.Visible = true
    else esp.Tracer.Visible = false end
    
    -- 5. Look Lines (Взгляд)
    if self.Settings.LookLines then
        local lookAt = root.Position + (root.CFrame.LookVector * 5)
        local lookPos, lookOn = CurrentCamera:WorldToViewportPoint(lookAt)
        if lookOn then
            esp.LookLine.From = Vector2.new(pos.X, pos.Y)
            esp.LookLine.To = Vector2.new(lookPos.X, lookPos.Y)
            esp.LookLine.Color = Color3.new(1, 1, 0)
            esp.LookLine.Visible = true
        else esp.LookLine.Visible = false end
    else esp.LookLine.Visible = false end
end

function ESPLibrary:HideESP(player)
    local esp = self.ESPObjects[player]
    if esp then
        esp.Box.Visible = false
        esp.BoxOutline.Visible = false
        esp.HealthBar.Visible = false
        esp.HealthBarOutline.Visible = false
        esp.Name.Visible = false
        esp.Distance.Visible = false
        esp.Tracer.Visible = false
        esp.LookLine.Visible = false
        -- Скелет очищается отдельно
    end
end

-- [ Остальные методы Start/Stop аналогичны твоему скрипту ] --

function ESPLibrary.Init()
    local lib = ESPLibrary.new()
    lib:Start()
    return lib
end

return ESPLibrary
