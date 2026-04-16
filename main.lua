--// Фикс для экзекуторов без cloneref
local function safe_cloneref(service)
    return (cloneref and cloneref(service)) or service
end

local ESPLibrary = {}
ESPLibrary.__index = ESPLibrary

-- Используем безопасный вызов сервисов
local Players = safe_cloneref(game:GetService("Players"))
local RunService = safe_cloneref(game:GetService("RunService"))
local Workspace = safe_cloneref(game:GetService("Workspace"))

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

local JOINT_CONFIGS = {
    R15 = {
        {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
        {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
        {"RightUpperArm", "RightLowerArm"}, {"RightUpperArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
        {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
        {"RightUpperLeg", "RightLowerLeg"}, {"RightUpperLeg", "RightFoot"}
    },
    R6 = {
        {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}
    }
}

local DEFAULT_SETTINGS = {
    Enabled = false,
    BoxEnable = true,
    HealthBar = true,
    Nickname = true,
    Skeleton = false,
    ChamsEnable = false,
    BoxColor = Color3.new(1, 1, 1),
    NicknameColor = Color3.new(1, 1, 1),
    RenderDistance = 650,
    UseLOD = true
}

-- [ Внутренние функции ]
local function WorldToViewportPoint(position)
    local screenPosition, onScreen = CurrentCamera:WorldToViewportPoint(position)
    return Vector2.new(screenPosition.X, screenPosition.Y), onScreen
end

function ESPLibrary.new(settings)
    local self = setmetatable({}, ESPLibrary)
    self.Settings = {}
    for key, value in pairs(DEFAULT_SETTINGS) do
        self.Settings[key] = (settings and settings[key] ~= nil) and settings[key] or value
    end
    self.ESPObjects = {}
    self.IsRunning = false
    return self
end

function ESPLibrary:CreateESPObject(player)
    if player == LocalPlayer then return end
    local esp = {
        Box = Drawing.new("Square"),
        Nickname = Drawing.new("Text")
    }
    esp.Box.Thickness = 2
    esp.Box.Filled = false
    esp.Nickname.Size = 16
    esp.Nickname.Center = true
    esp.Nickname.Outline = true
    return esp
end

function ESPLibrary:UpdatePlayerESP(player)
    local character = player.Character
    if not character or not self.Settings.Enabled then return self:RemoveESP(player) end
    
    local root = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")
    if not root or not head then return end

    local pos, onScreen = WorldToViewportPoint(root.Position)
    local dist = (CurrentCamera.CFrame.Position - root.Position).Magnitude

    if onScreen and dist <= self.Settings.RenderDistance then
        local esp = self.ESPObjects[player] or self:CreateESPObject(player)
        self.ESPObjects[player] = esp

        local headPos = WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        local height = math.abs(headPos.Y - legPos.Y)
        local width = height / 1.5

        if self.Settings.BoxEnable then
            esp.Box.Visible = true
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(pos.X - width / 2, headPos.Y)
            esp.Box.Color = self.Settings.BoxColor
        else
            esp.Box.Visible = false
        end

        if self.Settings.Nickname then
            esp.Nickname.Visible = true
            esp.Nickname.Text = player.Name
            esp.Nickname.Position = Vector2.new(pos.X, headPos.Y - 20)
            esp.Nickname.Color = self.Settings.NicknameColor
        else
            esp.Nickname.Visible = false
        end
    else
        self:RemoveESP(player)
    end
end

function ESPLibrary:RemoveESP(player)
    local esp = self.ESPObjects[player]
    if esp then
        esp.Box.Visible = false
        esp.Nickname.Visible = false
        -- Для полной очистки нужно удалять Drawing объекты, но для теста скроем
    end
end

function ESPLibrary:Start()
    if self.IsRunning then return end
    self.IsRunning = true
    self.Connection = RunService.RenderStepped:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                self:UpdatePlayerESP(player)
            end
        end
    end)
end

function ESPLibrary:Stop()
    self.IsRunning = false
    if self.Connection then self.Connection:Disconnect() end
    for player, _ in pairs(self.ESPObjects) do self:RemoveESP(player) end
end

return ESPLibrary
