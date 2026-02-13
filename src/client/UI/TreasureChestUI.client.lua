--[[
	TreasureChestUI.client.lua
	UI del cofre del tesoro: detecta proximidad, muestra popup para
	reclamar 10,000 monedas si el jugador está en el grupo.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimTreasure = Remotes:WaitForChild("ClaimTreasure")
local CheckTreasureStatus = Remotes:WaitForChild("CheckTreasureStatus")

-- Configuración
local PROXIMITY_DISTANCE = 15 -- Studs para activar la UI
local GROUP_ID = 803229435
local REWARD_AMOUNT = 10000
local GROUP_URL = "https://www.roblox.com/groups/" .. GROUP_ID

-- Estado
local isUIOpen = false
local hasClaimed = false
local treasureModel = nil

-- ============================================
-- BUSCAR MODELO TREASURE EN WORKSPACE
-- ============================================
local function findTreasure()
	-- Buscar directamente
	local model = workspace:FindFirstChild("Treasure", true)
	if model then
		return model
	end
	return nil
end

-- Esperar a que el modelo exista
task.spawn(function()
	while not treasureModel do
		treasureModel = findTreasure()
		if not treasureModel then
			task.wait(2)
		end
	end
	print("[TreasureChestUI] Modelo Treasure encontrado")
end)

-- ============================================
-- CREAR UI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TreasureChestGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Indicador de proximidad (icono flotante sobre el cofre)
local proximityBillboard = Instance.new("BillboardGui")
proximityBillboard.Name = "TreasureIndicator"
proximityBillboard.Size = UDim2.new(0, 80, 0, 80)
proximityBillboard.StudsOffset = Vector3.new(0, 5, 0)
proximityBillboard.AlwaysOnTop = true
proximityBillboard.Active = false
proximityBillboard.Enabled = false

local indicatorIcon = Instance.new("TextLabel")
indicatorIcon.Name = "Icon"
indicatorIcon.Size = UDim2.new(1, 0, 1, 0)
indicatorIcon.BackgroundTransparency = 1
indicatorIcon.Text = "💰"
indicatorIcon.TextScaled = true
indicatorIcon.Parent = proximityBillboard

-- Fondo oscuro (overlay)
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.ZIndex = 50
overlay.Visible = false
overlay.Parent = screenGui

-- Panel principal del popup
local mainFrame = Instance.new("ImageLabel")
mainFrame.Name = "TreasurePanel"
mainFrame.Size = UDim2.new(0, 420, 0, 380)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -190)
mainFrame.BackgroundTransparency = 1
mainFrame.Image = TextureManager.Backgrounds.StudGray
mainFrame.ImageColor3 = Color3.fromRGB(45, 35, 55)
mainFrame.ImageTransparency = 0.05
mainFrame.ScaleType = Enum.ScaleType.Tile
mainFrame.TileSize = UDim2.new(0, 32, 0, 32)
mainFrame.ZIndex = 51
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 200, 50)
mainStroke.Thickness = 3
mainStroke.Parent = mainFrame

-- Icono del cofre (arriba, sobresale)
local chestIcon = Instance.new("TextLabel")
chestIcon.Name = "ChestIcon"
chestIcon.Size = UDim2.new(0, 90, 0, 90)
chestIcon.Position = UDim2.new(0.5, -45, 0, -45)
chestIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
chestIcon.Text = "🏴‍☠️"
chestIcon.TextScaled = true
chestIcon.ZIndex = 53
chestIcon.Parent = mainFrame

local chestIconCorner = Instance.new("UICorner")
chestIconCorner.CornerRadius = UDim.new(1, 0)
chestIconCorner.Parent = chestIcon

local chestIconStroke = Instance.new("UIStroke")
chestIconStroke.Color = Color3.fromRGB(180, 140, 30)
chestIconStroke.Thickness = 3
chestIconStroke.Parent = chestIcon

-- Título
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.Position = UDim2.new(0, 20, 0, 55)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "COFRE DEL TESORO"
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.ZIndex = 52
titleLabel.Parent = mainFrame

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(100, 70, 0)
titleStroke.Thickness = 2
titleStroke.Parent = titleLabel

-- Línea separadora dorada
local separator = Instance.new("Frame")
separator.Name = "Separator"
separator.Size = UDim2.new(0.8, 0, 0, 3)
separator.Position = UDim2.new(0.1, 0, 0, 100)
separator.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
separator.BorderSizePixel = 0
separator.ZIndex = 52
separator.Parent = mainFrame

local sepCorner = Instance.new("UICorner")
sepCorner.CornerRadius = UDim.new(0, 2)
sepCorner.Parent = separator

-- Recompensa (monedas)
local rewardLabel = Instance.new("TextLabel")
rewardLabel.Name = "Reward"
rewardLabel.Size = UDim2.new(1, -40, 0, 50)
rewardLabel.Position = UDim2.new(0, 20, 0, 115)
rewardLabel.BackgroundTransparency = 1
rewardLabel.Text = "💰 10,000 Monedas 💰"
rewardLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
rewardLabel.TextScaled = true
rewardLabel.Font = Enum.Font.FredokaOne
rewardLabel.ZIndex = 52
rewardLabel.Parent = mainFrame

local rewardStroke = Instance.new("UIStroke")
rewardStroke.Color = Color3.fromRGB(0, 80, 0)
rewardStroke.Thickness = 2
rewardStroke.Parent = rewardLabel

-- Descripción / estado
local descLabel = Instance.new("TextLabel")
descLabel.Name = "Description"
descLabel.Size = UDim2.new(1, -40, 0, 40)
descLabel.Position = UDim2.new(0, 20, 0, 170)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Únete al grupo para desbloquear esta recompensa"
descLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
descLabel.TextScaled = true
descLabel.Font = Enum.Font.GothamBold
descLabel.TextWrapped = true
descLabel.ZIndex = 52
descLabel.Parent = mainFrame

-- Botón de acción principal
local actionButton = Instance.new("ImageButton")
actionButton.Name = "ActionButton"
actionButton.Size = UDim2.new(0.75, 0, 0, 55)
actionButton.Position = UDim2.new(0.125, 0, 0, 225)
actionButton.BackgroundTransparency = 1
actionButton.Image = TextureManager.Backgrounds.StudGray
actionButton.ImageColor3 = Color3.fromRGB(50, 200, 80)
actionButton.ImageTransparency = 0.1
actionButton.ScaleType = Enum.ScaleType.Tile
actionButton.TileSize = UDim2.new(0, 32, 0, 32)
actionButton.ZIndex = 52
actionButton.Parent = mainFrame

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 12)
actionCorner.Parent = actionButton

local actionStroke = Instance.new("UIStroke")
actionStroke.Color = Color3.fromRGB(30, 130, 50)
actionStroke.Thickness = 2.5
actionStroke.Parent = actionButton

local actionText = Instance.new("TextLabel")
actionText.Name = "ButtonText"
actionText.Size = UDim2.new(1, 0, 1, 0)
actionText.BackgroundTransparency = 1
actionText.Text = "COBRAR RECOMPENSA"
actionText.TextColor3 = Color3.fromRGB(255, 255, 255)
actionText.TextScaled = true
actionText.Font = Enum.Font.FredokaOne
actionText.ZIndex = 53
actionText.Parent = actionButton

local actionTextStroke = Instance.new("UIStroke")
actionTextStroke.Color = Color3.fromRGB(20, 80, 30)
actionTextStroke.Thickness = 2
actionTextStroke.Parent = actionText

-- Botón de cerrar
UIComponentsManager.createCloseButton(mainFrame, {
	onClose = function()
		if isUIOpen then
			closeUI()
		end
	end,
})

-- ============================================
-- ANIMACIONES Y LÓGICA DE UI
-- ============================================

local function openUI()
	if isUIOpen then return end
	isUIOpen = true

	SoundManager.play("PopupOpen")

	overlay.Visible = true
	mainFrame.Visible = true

	-- Animación de entrada
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.5
	}):Play()

	local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 380),
		Position = UDim2.new(0.5, -210, 0.5, -190),
	})
	openTween:Play()
end

function closeUI()
	if not isUIOpen then return end
	isUIOpen = false

	SoundManager.play("PopupClose")

	TweenService:Create(overlay, TweenInfo.new(0.25), {
		BackgroundTransparency = 1
	}):Play()

	local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	})
	closeTween:Play()
	closeTween.Completed:Wait()

	overlay.Visible = false
	mainFrame.Visible = false
end

-- Cerrar al tocar el overlay
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		closeUI()
	end
end)

-- ============================================
-- ACTUALIZAR UI SEGÚN ESTADO
-- ============================================

local function updateUIState(status)
	if status.CanClaim then
		-- Puede cobrar
		descLabel.Text = "¡Estás en el grupo! Reclama tu recompensa"
		descLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		actionButton.ImageColor3 = Color3.fromRGB(50, 200, 80)
		actionStroke.Color = Color3.fromRGB(30, 130, 50)
		actionText.Text = "COBRAR 10,000 MONEDAS"
		actionButton.Visible = true

	elseif status.Reason == "AlreadyClaimed" then
		-- Ya reclamó
		descLabel.Text = "¡Ya reclamaste esta recompensa!"
		descLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

		actionButton.ImageColor3 = Color3.fromRGB(80, 80, 80)
		actionStroke.Color = Color3.fromRGB(50, 50, 50)
		actionText.Text = "YA RECLAMADO ✓"
		actionButton.Visible = true
		hasClaimed = true

	elseif status.Reason == "NotInGroup" then
		-- No está en el grupo
		descLabel.Text = "Debes unirte al grupo para desbloquear esta recompensa"
		descLabel.TextColor3 = Color3.fromRGB(255, 150, 150)

		actionButton.ImageColor3 = Color3.fromRGB(80, 130, 255)
		actionStroke.Color = Color3.fromRGB(40, 70, 180)
		actionText.Text = "UNIRSE AL GRUPO"
		actionButton.Visible = true

	else
		-- Error
		descLabel.Text = "Error al verificar. Intenta de nuevo más tarde."
		descLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		actionButton.Visible = false
	end
end

-- ============================================
-- HANDLER DEL BOTÓN DE ACCIÓN
-- ============================================

local isProcessing = false

actionButton.MouseButton1Click:Connect(function()
	if isProcessing or hasClaimed then return end

	-- Verificar estado actual
	local status = CheckTreasureStatus:InvokeServer()

	if status.Reason == "NotInGroup" then
		-- Abrir página del grupo
		SoundManager.play("ButtonClick")

		-- Intentar abrir el enlace del grupo
		local success, err = pcall(function()
			-- SetCore para abrir URL en el navegador del juego
			local StarterGui = game:GetService("StarterGui")
			StarterGui:SetCore("SendNotification", {
				Title = "Únete al grupo",
				Text = "Ve a Roblox y busca el grupo ID: " .. GROUP_ID,
				Duration = 8,
			})
		end)

		-- Después de unirse, el jugador puede cerrar y volver a interactuar
		descLabel.Text = "Únete al grupo y vuelve a abrir el cofre"
		descLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
		return
	end

	if status.Reason == "AlreadyClaimed" then
		updateUIState(status)
		return
	end

	if not status.CanClaim then
		updateUIState(status)
		return
	end

	-- Intentar reclamar
	isProcessing = true
	actionText.Text = "PROCESANDO..."
	actionButton.ImageColor3 = Color3.fromRGB(150, 150, 150)

	local success, message = ClaimTreasure:InvokeServer()

	if success then
		SoundManager.play("CashRegister")
		hasClaimed = true

		-- Animación de éxito
		actionButton.ImageColor3 = Color3.fromRGB(255, 200, 50)
		actionStroke.Color = Color3.fromRGB(180, 140, 30)
		actionText.Text = "¡RECLAMADO! ✓"
		descLabel.Text = "¡Has recibido 10,000 monedas!"
		descLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Efecto de celebración en el texto de recompensa
		local popTween = TweenService:Create(rewardLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextColor3 = Color3.fromRGB(255, 255, 100),
		})
		popTween:Play()
		task.wait(0.15)
		TweenService:Create(rewardLabel, TweenInfo.new(0.3), {
			TextColor3 = Color3.fromRGB(100, 255, 100),
		}):Play()

		-- Cerrar automáticamente después de 2 segundos
		task.wait(2)
		closeUI()
	else
		SoundManager.play("Error")
		actionText.Text = message or "Error"
		actionButton.ImageColor3 = Color3.fromRGB(200, 60, 60)

		task.wait(1.5)
		-- Restaurar
		local newStatus = CheckTreasureStatus:InvokeServer()
		updateUIState(newStatus)
	end

	isProcessing = false
end)

-- Efecto hover del botón
actionButton.MouseEnter:Connect(function()
	if hasClaimed or isProcessing then return end
	SoundManager.play("ButtonHover")
	TweenService:Create(actionButton, TweenInfo.new(0.15), {
		ImageTransparency = 0,
	}):Play()
	TweenService:Create(actionStroke, TweenInfo.new(0.15), {
		Thickness = 3.5,
	}):Play()
end)

actionButton.MouseLeave:Connect(function()
	TweenService:Create(actionButton, TweenInfo.new(0.15), {
		ImageTransparency = 0.1,
	}):Play()
	TweenService:Create(actionStroke, TweenInfo.new(0.15), {
		Thickness = 2.5,
	}):Play()
end)

-- ============================================
-- DETECCIÓN DE PROXIMIDAD
-- ============================================

local isNear = false

local function getTreasurePosition()
	if not treasureModel then return nil end

	if treasureModel:IsA("Model") and treasureModel.PrimaryPart then
		return treasureModel.PrimaryPart.Position
	elseif treasureModel:IsA("Model") then
		return treasureModel:GetBoundingBox().Position
	elseif treasureModel:IsA("BasePart") then
		return treasureModel.Position
	end
	return nil
end

RunService.Heartbeat:Connect(function()
	if not treasureModel or not treasureModel.Parent then
		treasureModel = findTreasure()
		return
	end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local treasurePos = getTreasurePosition()
	if not treasurePos then return end

	local distance = (humanoidRootPart.Position - treasurePos).Magnitude

	-- Asignar el billboard al modelo si no está asignado
	if not proximityBillboard.Parent or proximityBillboard.Parent ~= treasureModel then
		if treasureModel:IsA("Model") then
			proximityBillboard.Adornee = treasureModel.PrimaryPart or treasureModel:FindFirstChildWhichIsA("BasePart")
		else
			proximityBillboard.Adornee = treasureModel
		end
		proximityBillboard.Parent = treasureModel
	end

	if distance <= PROXIMITY_DISTANCE then
		-- Mostrar indicador
		if not hasClaimed then
			proximityBillboard.Enabled = true
		end

		if not isNear then
			isNear = true
			-- Abrir UI automáticamente al acercarse
			if not isUIOpen and not hasClaimed then
				-- Consultar estado al servidor
				task.spawn(function()
					local status = CheckTreasureStatus:InvokeServer()
					if status.Reason == "AlreadyClaimed" then
						hasClaimed = true
						proximityBillboard.Enabled = false
						return
					end
					updateUIState(status)
					openUI()
				end)
			end
		end
	else
		proximityBillboard.Enabled = false
		if isNear then
			isNear = false
			if isUIOpen then
				closeUI()
			end
		end
	end
end)

-- ============================================
-- VERIFICAR ESTADO INICIAL
-- ============================================
task.spawn(function()
	task.wait(3) -- Esperar a que carguen los datos
	local status = CheckTreasureStatus:InvokeServer()
	if status and status.Reason == "AlreadyClaimed" then
		hasClaimed = true
	end
end)

print("[TreasureChestUI] UI del cofre del tesoro inicializada")
