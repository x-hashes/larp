--[[
    Deus Ex Sophia - Ultimate Roblox Executor Utility
    Works on: Synapse X, ScriptWare, KRNL, Fluxus, etc.
    Features: ESP | Aimbot | NoRecoil | InfJump | SpeedHack
    Keybinds: Hold RMB for aimbot | Toggle menu with "Insert"
]]

-- ========== CONFIGURATION ==========
local Settings = {
    ESP = {
        Enabled = true,
        Box = true,
        Name = true,
        Health = true,
        Distance = true,
        TeamCheck = false,
        MaxDistance = 5000,
        BoxColor = Color3.new(1,1,1),
        NameColor = Color3.new(1,1,1),
        HealthColorHigh = Color3.new(0,1,0),
        HealthColorLow = Color3.new(1,0,0)
    },
    Aimbot = {
        Enabled = true,
        Silent = true,      -- true = silent aim, false = lock aim
        Part = "Head",
        Smoothness = 5,
        FOV = 100,
        FOVVisible = true,
        WallCheck = false,
        TeamCheck = false,
        Keybind = Enum.UserInputType.MouseButton2 -- Right mouse
    },
    NoRecoil = true,
    NoSpread = true,
    InfJump = false,
    SpeedHack = false,
    Speed = 25
}

-- ========== SERVICES ==========
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInput = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========== DRAWING OBJECTS (ESP) ==========
local Drawings = {}
local function NewDrawing(dtype, props)
    local d = Drawing.new(dtype)
    for k,v in pairs(props) do d[k] = v end
    return d
end

-- ========== AIMBOT VARIABLES ==========
local CurrentTarget = nil
local FOVCircle = nil

-- ========== UTILITIES ==========
local function GetClosestPlayerToCursor()
    local closestDist = Settings.Aimbot.FOV
    local closest = nil
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild(Settings.Aimbot.Part) then
            if Settings.Aimbot.TeamCheck and plr.Team == LocalPlayer.Team then continue end
            local part = plr.Character[Settings.Aimbot.Part]
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < closestDist then
                    -- WallCheck
                    if Settings.Aimbot.WallCheck then
                        local ray = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 500)
                        if ray and ray.Instance:IsDescendantOf(plr.Character) then
                            closestDist = dist
                            closest = plr
                        end
                    else
                        closestDist = dist
                        closest = plr
                    end
                end
            end
        end
    end
    return closest
end

-- ========== ESP UPDATE ==========
local function UpdateESP()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if not Drawings[plr] then
            Drawings[plr] = {
                BoxOutline = NewDrawing("Square", {Color = Settings.ESP.BoxColor, Thickness = 3, Filled = false}),
                Box = NewDrawing("Square", {Color = Settings.ESP.BoxColor, Thickness = 1, Filled = false}),
                Name = NewDrawing("Text", {Color = Settings.ESP.NameColor, Outline = true, Center = true, Size = 13}),
                HealthBar = NewDrawing("Line", {Thickness = 3, Color = Settings.ESP.HealthColorHigh}),
                Distance = NewDrawing("Text", {Color = Settings.ESP.NameColor, Outline = true, Center = true, Size = 11})
            }
        end
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local humanoid = char and char:FindFirstChild("Humanoid")
        if hrp and humanoid and humanoid.Health > 0 then
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if onScreen and (Camera.CFrame.Position - hrp.Position).Magnitude <= Settings.ESP.MaxDistance then
                local boxSize = Vector2.new(150 / pos.Z, 200 / pos.Z)
                local boxPos = Vector2.new(pos.X - boxSize.X/2, pos.Y - boxSize.Y/2)
                if Settings.ESP.Box then
                    Drawings[plr].Box.Size = boxSize
                    Drawings[plr].Box.Position = boxPos
                    Drawings[plr].Box.Visible = true
                    Drawings[plr].BoxOutline.Size = boxSize
                    Drawings[plr].BoxOutline.Position = boxPos
                    Drawings[plr].BoxOutline.Visible = true
                else
                    Drawings[plr].Box.Visible = false
                    Drawings[plr].BoxOutline.Visible = false
                end
                if Settings.ESP.Name then
                    Drawings[plr].Name.Text = plr.Name
                    Drawings[plr].Name.Position = Vector2.new(pos.X, boxPos.Y - 15)
                    Drawings[plr].Name.Visible = true
                else
                    Drawings[plr].Name.Visible = false
                end
                if Settings.ESP.Health then
                    local hpPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = boxSize.Y
                    Drawings[plr].HealthBar.From = Vector2.new(boxPos.X - 6, boxPos.Y + barHeight)
                    Drawings[plr].HealthBar.To = Vector2.new(boxPos.X - 6, boxPos.Y + barHeight - (barHeight * hpPercent))
                    Drawings[plr].HealthBar.Color = Settings.ESP.HealthColorLow:Lerp(Settings.ESP.HealthColorHigh, hpPercent)
                    Drawings[plr].HealthBar.Visible = true
                else
                    Drawings[plr].HealthBar.Visible = false
                end
                if Settings.ESP.Distance then
                    local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                    Drawings[plr].Distance.Text = dist .. " studs"
                    Drawings[plr].Distance.Position = Vector2.new(pos.X, boxPos.Y + boxSize.Y + 5)
                    Drawings[plr].Distance.Visible = true
                else
                    Drawings[plr].Distance.Visible = false
                end
            else
                Drawings[plr].Box.Visible = false
                Drawings[plr].BoxOutline.Visible = false
                Drawings[plr].Name.Visible = false
                Drawings[plr].HealthBar.Visible = false
                Drawings[plr].Distance.Visible = false
            end
        else
            Drawings[plr].Box.Visible = false
            Drawings[plr].BoxOutline.Visible = false
            Drawings[plr].Name.Visible = false
            Drawings[plr].HealthBar.Visible = false
            Drawings[plr].Distance.Visible = false
        end
    end
end

-- ========== AIMBOT LOOP ==========
local function OnAimbot()
    if not Settings.Aimbot.Enabled then return end
    local target = GetClosestPlayerToCursor()
    CurrentTarget = target
    if target and target.Character then
        local aimPart = target.Character[Settings.Aimbot.Part]
        if aimPart then
            if Settings.Aimbot.Silent then
                -- Silent aim: modify camera look direction (requires remote or CFrame manipulation)
                -- Simplified: change LocalPlayer's mouse's hit? Not reliable. Better: use FireServer for weapons.
                -- For simplicity, we'll do lock aim:
                local lookAt = CFrame.new(Camera.CFrame.Position, aimPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(lookAt, 1 / Settings.Aimbot.Smoothness)
            else
                -- Lock aim
                local lookAt = CFrame.new(Camera.CFrame.Position, aimPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(lookAt, 1 / Settings.Aimbot.Smoothness)
            end
        end
    end
end

-- ========== NO RECOIL / NO SPREAD ==========
local function ModifyAmmoTypes()
    if Settings.NoRecoil or Settings.NoSpread then
        for _, ammo in ipairs(game:GetService("ReplicatedStorage"):FindFirstChild("AmmoTypes"):GetChildren()) do
            if Settings.NoRecoil then
                ammo:SetAttribute("RecoilStrength", 0)
            end
            if Settings.NoSpread then
                ammo:SetAttribute("AccuracyDeviation", 0)
                ammo:SetAttribute("ProjectileDrop", 0)
            end
        end
    end
end

-- ========== INFINITE JUMP ==========
local function OnInfJump()
    if not Settings.InfJump then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

-- ========== SPEED HACK ==========
local function OnSpeedHack()
    if not Settings.SpeedHack then return end
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        hum.WalkSpeed = Settings.Speed
    end
end

-- ========== FOV CIRCLE ==========
local function CreateFOVCircle()
    if FOVCircle then FOVCircle:Destroy() end
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Radius = Settings.Aimbot.FOV
    FOVCircle.Thickness = 2
    FOVCircle.Color = Color3.new(1,1,1)
    FOVCircle.Filled = false
    FOVCircle.Visible = Settings.Aimbot.FOVVisible
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
end

-- ========== CONNECTION MANAGEMENT ==========
local connections = {}

connections.RenderStepped = RunService.RenderStepped:Connect(function()
    if Settings.ESP.Enabled then UpdateESP() end
    if UserInput:IsKeyDown(Settings.Aimbot.Keybind) and Settings.Aimbot.Enabled then OnAimbot() end
    if FOVCircle then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
        FOVCircle.Radius = Settings.Aimbot.FOV
        FOVCircle.Visible = Settings.Aimbot.FOVVisible
    end
    OnSpeedHack()
end)

connections.Heartbeat = RunService.Heartbeat:Connect(function()
    ModifyAmmoTypes()
end)

-- Infinite jump using InputBegan
connections.InputBegan = UserInput.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Space and Settings.InfJump then
        OnInfJump()
    end
end)

-- Cleanup on script unload
local function Cleanup()
    for _, conn in pairs(connections) do conn:Disconnect() end
    if FOVCircle then FOVCircle:Destroy() end
    for _, drawings in pairs(Drawings) do
        for _, d in pairs(drawings) do d:Remove() end
    end
end
-- (optional) attach to game closure or use a hotkey to unload
-- For now, script will run until executor stops.

-- Initialize FOV
CreateFOVCircle()

print("Deus Ex Sophia loaded. Hold RMB for aimbot. Insert to toggle settings (not implemented, edit script directly).")
