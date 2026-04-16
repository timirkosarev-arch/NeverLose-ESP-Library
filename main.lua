--// NEVERLOSE ESP LIBRARY (STABLE VERSION)
local ESPLibrary = {}
ESPLibrary.__index = ESPLibrary

-- Используем стандартные вызовы, чтобы не было ошибок 'nil value'
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera

local DEFAULT_SETTINGS = {
    Enabled = false,
    BoxEnable = true,
    HealthBar = true,
    Nickname = true,
    Skeleton = false,
    ChamsEnable = false,
    BoxColor = Color3.new(1, 1, 1),
    NicknameColor = Color3.new(1, 1, 1),
    RenderDistance = 1000,
}

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
    local esp = {}
    
    -- Создаем бокс
    esp.Box = Drawing.new("Square")
    esp.Box.Thickness = 1.5
    esp.Box.Filled = false
    esp.Box.Transparency = 1
    
    -- Создаем ник
    esp.Nickname = Drawing.new("Text")
    esp.Nickname.Size = 16
    esp.Nickname.Center = true
    esp.Nickname.Outline = true
    esp.Nickname.Transparency = 1
    
    return esp
end

function ESPLibrary:UpdatePlayerESP(player)
    local char = player.Character
    if not char or not self.Settings.Enabled then return self:RemoveESP(player) end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local pos, onScreen = CurrentCamera:WorldToViewportPoint(hrp.Position)
    local dist = (CurrentCamera.CFrame.Position - hrp.Position).Magnitude

    if onScreen and dist <= self.Settings.RenderDistance then
        local esp = self.ESPObjects[player] or self:CreateESPObject(player)
        self.ESPObjects[player] = esp

        -- Расчет размеров
        local head = char:FindFirstChild("Head")
        if not head then return end
        local headPos = CurrentCamera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
        local legPos = CurrentCamera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
        local height = math.abs(headPos.Y - legPos.Y)
        local width = height / 1.5

        -- Обновление бокса
        if self.Settings.BoxEnable then
            esp.Box.Visible = true
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(pos.X - width / 2, headPos.Y)
            esp.Box.Color = self.Settings.BoxColor
        else
            esp.Box.Visible = false
        end

        -- Обновление ника
        if self.Settings.Nickname then
            esp.Nickname.Visible = true
            esp.Nickname.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
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
    for _, esp in pairs(self.ESPObjects) do
        esp.Box.Visible = false
        esp.Nickname.Visible = false
    end
end

return ESPLibrary
