-- ============================================
-- 🚀 SCRIPT CORRIGIDO: DUDU PANEL + COMBO KILLER PRO + ESP
-- ============================================

-- 1. CARREGANDO O DUDU PANEL V2
local success, err = pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Imp3rson/Dudu-Panel-V2/refs/heads/main/DuduPanelV2.lua?v=" .. os.time()))()
end)

if not success then
    warn("❌ Falha ao carregar Dudu Panel: " .. tostring(err))
end

task.wait(2)

-- ============================================
-- SERVIÇOS
-- ============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============================================
-- CONFIGURAÇÕES
-- ============================================
local Config = {
    AutoShoot    = false,
    AutoSlash    = false,
    Aimbot       = false,
    TeamCheck    = true,    -- Afeta apenas Aimbot/Auto-Ataque
    ClickDelay   = 0.15,
}

local ESP_Settings = {
    Enabled        = true,
    ShowBox        = true,
    ShowName       = true,
    ShowDistance   = true,
    ShowTeamColor  = true,  -- 🔵/🔴 por time
    UpdateRate     = 0.1,   -- Atualização do texto (10x/seg)
}

local ESP_Storage = {}
local lastClickTime = 0
local menuOpen = false
local lastESPTextUpdate = 0

-- ============================================
-- FUNÇÕES AUXILIARES
-- ============================================

local function isEnemy(player)
    if not Config.TeamCheck then return true end
    
    local myTeam = LocalPlayer.Team
    local enemyTeam = player.Team
    if myTeam and enemyTeam then
        return myTeam ~= enemyTeam
    end
    
    local myCustom = LocalPlayer:FindFirstChild("Team") or LocalPlayer:FindFirstChild("team")
    local enemyCustom = player:FindFirstChild("Team") or player:FindFirstChild("team")
    if myCustom and enemyCustom then
        return myCustom.Value ~= enemyCustom.Value
    end
    
    return true
end

local function getEquippedTool()
    local character = LocalPlayer.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Tool")
end

local function isVisible(targetHead)
    local character = LocalPlayer.Character
    if not character then return false end
    local myHead = character:FindFirstChild("Head")
    if not myHead then return false end
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    
    local direction = targetHead.Position - myHead.Position
    local result = workspace:Raycast(myHead.Position, direction, raycastParams)
    
    if not result then return true end
    if result.Instance:IsDescendantOf(targetHead.Parent) then return true end
    return false
end

local function isOnScreen(targetHead)
    if not targetHead then return false end
    local _, onScreen = Camera:WorldToScreenPoint(targetHead.Position)
    return onScreen
end

local function getClosestEnemy()
    local character = LocalPlayer.Character
    if not character then return nil end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return nil end
    
    local closest, closestDist = nil, math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and isEnemy(player) then
            local enemyRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local enemyHead = player.Character:FindFirstChild("Head")
            local enemyHum  = player.Character:FindFirstChildOfClass("Humanoid")
            
            if enemyRoot and enemyHead and enemyHum and enemyHum.Health > 0 then
                if isOnScreen(enemyHead) and isVisible(enemyHead) then
                    local dist = (enemyRoot.Position - rootPart.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- ============================================
-- INTERFACE GRÁFICA
-- ============================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ComboKillerFinal"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = game:GetService("CoreGui") end)
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- BOTÃO FLUTUANTE
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(1, -60, 0.5, -25)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 40)
ToggleBtn.Text = "⚔️"
ToggleBtn.TextSize = 24
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

-- FRAME PRINCIPAL
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 230, 0, 310)
MainFrame.Position = UDim2.new(0, 10, 0.5, -155)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Visible = false
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
Title.Text = "🔫⚔️ COMBO KILLER + ESP"
Title.TextColor3 = Color3.fromRGB(255, 200, 100)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

-- FUNÇÃO CRIADORA DE BOTÕES
local function setBtnState(btn, text, state)
    if state then
        btn.Text = text .. ": ON"
        btn.TextColor3 = Color3.fromRGB(100, 255, 100)
        btn.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
    else
        btn.Text = text .. ": OFF"
        btn.TextColor3 = Color3.fromRGB(255, 100, 100)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    end
end

local function createBtn(text, pos, configTable, configKey)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, pos)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.Text = text .. ": OFF"
    btn.TextColor3 = Color3.fromRGB(255, 100, 100)
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.AutoButtonColor = true
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        configTable[configKey] = not configTable[configKey]
        setBtnState(btn, text, configTable[configKey])
    end)
    
    return btn
end

createBtn("🔫 Auto-Shoot",   35, Config, "AutoShoot")
createBtn("⚔️ Auto-Slash",   75, Config, "AutoSlash")
createBtn("🎯 Aimbot",      115, Config, "Aimbot")
createBtn("👥 Team Check",  155, Config, "TeamCheck")
createBtn("👁️ ESP Visual",  195, ESP_Settings, "Enabled")
createBtn("📦 ESP Box",     235, ESP_Settings, "ShowBox")

-- DRAGGING
local dragging, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch 
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

Title.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch 
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch 
    or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    MainFrame.Visible = menuOpen
    ToggleBtn.Text = menuOpen and "✖️" or "⚔️"
    ToggleBtn.BackgroundColor3 = menuOpen 
        and Color3.fromRGB(40, 80, 40) 
        or Color3.fromRGB(255, 80, 40)
end)

-- ============================================
-- AUTO-ATAQUE
-- ============================================
RunService.Heartbeat:Connect(function()
    if not (Config.AutoShoot or Config.AutoSlash) then return end
    
    local currentTime = tick()
    if currentTime - lastClickTime < Config.ClickDelay then return end
    
    local tool = getEquippedTool()
    if not tool then return end
    
    local enemy = getClosestEnemy()
    if not enemy then return end
    
    local shouldAttack = false
    local toolName = string.lower(tool.Name)
    
    local gunKeywords  = {"gun","pistol","rifle","ak","m4","sniper","shotgun","smg","uzi","mg","lmg"}
    local meleeKeywords = {"knife","sword","blade","katana","bat","axe","machete","dagger","club","hammer"}
    
    if Config.AutoShoot then
        for _, kw in ipairs(gunKeywords) do
            if string.find(toolName, kw) then shouldAttack = true break end
        end
    end
    
    if Config.AutoSlash then
        for _, kw in ipairs(meleeKeywords) do
            if string.find(toolName, kw) then shouldAttack = true break end
        end
    end
    
    -- Fallback: se ambos ativos e a ferramenta for desconhecida, ataca mesmo assim
    if not shouldAttack and Config.AutoShoot and Config.AutoSlash then
        shouldAttack = true
    end
    
    if shouldAttack then
        pcall(function() tool:Activate() end)
        lastClickTime = currentTime
    end
end)

-- ============================================
-- AIMBOT
-- ============================================
RunService.RenderStepped:Connect(function()
    if not Config.Aimbot then return end
    local enemy = getClosestEnemy()
    if enemy and enemy.Character then
        local head = enemy.Character:FindFirstChild("Head")
        if head then
            local camPos = Camera.CFrame.Position
            Camera.CFrame = CFrame.lookAt(camPos, head.Position)
        end
    end
end)

-- ============================================
-- ESP VISUAL
-- ============================================
local function getPlayerColor(player)
    local color = Color3.fromRGB(255, 255, 255)
    local teamName = ""
    
    if player.Team then
        teamName = string.lower(player.Team.Name)
    else
        local customTeam = player:FindFirstChild("Team") or player:FindFirstChild("team")
        if customTeam and customTeam.Value then
            teamName = string.lower(tostring(customTeam.Value))
        end
    end
    
    if string.find(teamName, "blue") or string.find(teamName, "azul") then
        return Color3.fromRGB(0, 150, 255)
    elseif string.find(teamName, "red") or string.find(teamName, "vermelho") then
        return Color3.fromRGB(255, 50, 50)
    end
    
    -- Fallback por inimigo/aliado
    if isEnemy(player) then
        return Color3.fromRGB(255, 50, 50)
    else
        return Color3.fromRGB(0, 150, 255)
    end
end

local function createESP(player, rootPart)
    local data = {}
    local color = getPlayerColor(player)
    
    -- Box
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "ESP_Box"
    box.Adornee = rootPart
    box.Size = Vector3.new(2, 2, 2)
    box.Color3 = color
    box.Transparency = 0.5
    box.AlwaysOnTop = true
    box.ZIndex = 10
    box.Parent = workspace.Terrain
    data.Box = box
    
    -- Billboard
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = rootPart
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = workspace.Terrain
    
    local label = Instance.new("TextLabel")
    label.Name = "ESP_Label"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextStrokeTransparency = 0.5
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = color
    label.Parent = bb
    
    data.Billboard = bb
    data.Label = label
    data.LastCharacter = player.Character
    
    return data
end

local function destroyESP(data)
    if data.Box then data.Box:Destroy() end
    if data.Billboard then data.Billboard:Destroy() end
end

local function updateESP(player)
    -- Se o player não tem character, limpa
    if not player.Character then
        if ESP_Storage[player] then
            destroyESP(ESP_Storage[player])
            ESP_Storage[player] = nil
        end
        return
    end
    
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        if ESP_Storage[player] then
            ESP_Storage[player].Box.Visible = false
            ESP_Storage[player].Billboard.Visible = false
        end
        return
    end
    
    -- Se mudou de personagem (respawn), recria
    if ESP_Storage[player] and ESP_Storage[player].LastCharacter ~= player.Character then
        destroyESP(ESP_Storage[player])
        ESP_Storage[player] = nil
    end
    
    -- Cria se não existir
    if not ESP_Storage[player] then
        ESP_Storage[player] = createESP(player, rootPart)
    end
    
    local data = ESP_Storage[player]
    local color = getPlayerColor(player)
    
    -- Atualiza Box
    if ESP_Settings.ShowBox then
        data.Box.Adornee = rootPart
        data.Box.Color3 = color
        data.Box.Visible = true
    else
        data.Box.Visible = false
    end
    
    -- Atualiza texto (com throttling)
    local now = tick()
    if now - lastESPTextUpdate >= ESP_Settings.UpdateRate then
        local text = ""
        if ESP_Settings.ShowName then text = player.Name end
        if ESP_Settings.ShowDistance then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local dist = math.floor((rootPart.Position - myRoot.Position).Magnitude)
                text = text .. " [" .. dist .. "m]"
            end
        end
        data.Label.Text = text
        data.Label.TextColor3 = color
    end
    
    data.Billboard.Adornee = rootPart
    data.Billboard.Visible = ESP_Settings.ShowName or ESP_Settings.ShowDistance
end

-- LOOP PRINCIPAL DO ESP
RunService.RenderStepped:Connect(function()
    -- Atualiza o timestamp de throttling global (1x por frame)
    local now = tick()
    if now - lastESPTextUpdate >= ESP_Settings.UpdateRate then
        lastESPTextUpdate = now
    end
    
    if not ESP_Settings.Enabled then
        for _, data in pairs(ESP_Storage) do
            if data.Box then data.Box.Visible = false end
            if data.Billboard then data.Billboard.Visible = false end
        end
        return
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            pcall(updateESP, player)
        end
    end
end)

-- CLEANUP AO SAIR DO SERVIDOR
Players.PlayerRemoving:Connect(function(player)
    if ESP_Storage[player] then
        destroyESP(ESP_Storage[player])
        ESP_Storage[player] = nil
    end
end)

-- CLEANUP AO RESPAWNAR (para não vazar memória)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    for player, data in pairs(ESP_Storage) do
        destroyESP(data)
        ESP_Storage[player] = nil
    end
end)

-- ============================================
-- FINALIZAÇÃO
-- ============================================
print("✅ DUDU PANEL + COMBO KILLER + ESP CARREGADOS!")
print("🔵 Time Azul | 🔴 Time Vermelho")
print("📌 Pressione o botão ⚔️ na lateral direita para abrir o menu.")
