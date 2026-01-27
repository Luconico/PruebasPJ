--[[
	GameHUD.client.lua
	Interfaz de usuario del juego
	Estilo cartoon, grande y claro
	RESPONSIVE: Adaptado para móviles y PC
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar Remotes y módulos
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))

-- ============================================
-- CONFIGURACIÓN DE ESTILOS
-- ============================================

local Styles = {
	-- Colores principales
	Colors = {
		Primary = Color3.fromRGB(255, 200, 50),     -- Amarillo dorado
		Secondary = Color3.fromRGB(100, 200, 100),  -- Verde
		Accent = Color3.fromRGB(255, 100, 100),     -- Rojo/Rosa
		Background = Color3.fromRGB(40, 40, 60),    -- Azul oscuro
		Text = Color3.fromRGB(255, 255, 255),       -- Blanco
		Shadow = Color3.fromRGB(0, 0, 0),           -- Negro
	},

	-- Fuentes
	Font = Enum.Font.FredokaOne,
	FontBold = Enum.Font.GothamBold,

	-- Tamaños base (se escalarán según dispositivo)
	CornerRadius = UDim.new(0, 12),
	Padding = UDim.new(0, 10),
}

-- ============================================
-- TAMAÑOS RESPONSIVE
-- ============================================

local function getResponsiveSizes()
	local info = ResponsiveUI.getViewportInfo()
	local scale = info.Scale
	local isMobile = info.IsMobile

	return {
		-- Barra de gordura (más grande en móvil para fácil visibilidad)
		FatnessBarWidth = isMobile and 200 or math.floor(250 * scale),
		FatnessBarHeight = isMobile and 45 or math.floor(50 * scale),
		FatnessBarMargin = isMobile and 12 or math.floor(20 * scale),
		FatnessIconSize = isMobile and 35 or math.floor(40 * scale),
		FatnessIconTextSize = isMobile and 26 or math.floor(28 * scale),

		-- Contadores (monedas, altura récord) - más anchos para el padding extra
		CounterWidth = isMobile and 145 or math.floor(180 * scale),
		CounterHeight = isMobile and 50 or math.floor(60 * scale),
		CounterMargin = isMobile and 10 or math.floor(20 * scale),
		CounterIconSize = isMobile and 38 or math.floor(50 * scale),
		CounterIconTextSize = isMobile and 30 or math.floor(36 * scale),
		CounterTextSize = isMobile and 24 or math.floor(32 * scale),

		-- Max height counter (más ancho para el padding)
		MaxHeightWidth = isMobile and 125 or math.floor(150 * scale),
		MaxHeightTextSize = isMobile and 20 or math.floor(26 * scale),
		MaxHeightIconTextSize = isMobile and 26 or math.floor(28 * scale),

		-- Medidor de altura actual (más ancho para el padding)
		HeightMeterWidth = isMobile and 110 or math.floor(120 * scale),
		HeightMeterHeight = isMobile and 44 or math.floor(50 * scale),
		HeightMeterIconSize = isMobile and 26 or math.floor(30 * scale),
		HeightMeterTextSize = isMobile and 22 or math.floor(24 * scale),

		-- Milestone notification
		MilestoneWidth = isMobile and 300 or math.floor(400 * scale),
		MilestoneHeight = isMobile and 80 or math.floor(100 * scale),
		MilestoneMainTextSize = isMobile and 36 or math.floor(48 * scale),
		MilestoneBonusTextSize = isMobile and 28 or math.floor(32 * scale),

		-- Corner radius
		CornerRadius = isMobile and 10 or math.floor(12 * scale),

		-- Stroke thickness
		StrokeThickness = isMobile and 3 or math.floor(4 * scale),
	}
end

local sizes = getResponsiveSizes()

-- ============================================
-- DATOS DEL JUGADOR (actualizados por eventos)
-- ============================================

local playerData = {
	Coins = 0,
	CurrentFatness = 0.5,
	MaxFatness = 3.0,
	CurrentHeight = 0,
	MaxHeight = 0,
}

-- ============================================
-- CREAR UI
-- ============================================

local function createScreenGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	return screenGui
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, sizes.CornerRadius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Styles.Colors.Shadow
	stroke.Thickness = thickness or sizes.StrokeThickness
	stroke.Parent = parent
	return stroke
end

local function createShadow(parent)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6015897843" -- Sombra suave
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -10)
	shadow.ZIndex = -1
	shadow.Parent = parent
	return shadow
end

-- ============================================
-- COMPONENTES DE UI
-- ============================================

-- Barra de gordura
local function createFatnessBar(parent)
	local container = Instance.new("Frame")
	container.Name = "FatnessBar"
	container.Size = UDim2.new(0, sizes.FatnessBarWidth, 0, sizes.FatnessBarHeight)
	container.Position = UDim2.new(0, sizes.FatnessBarMargin, 1, -(sizes.FatnessBarMargin + sizes.FatnessBarHeight + 10))
	container.AnchorPoint = Vector2.new(0, 1)
	container.BackgroundColor3 = Styles.Colors.Background
	container.Parent = parent

	createCorner(container)
	createStroke(container, Styles.Colors.Primary)

	-- Icono de hamburguesa
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, sizes.FatnessIconSize, 0, sizes.FatnessIconSize)
	icon.Position = UDim2.new(0, 5, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "🍔"
	icon.TextSize = sizes.FatnessIconTextSize
	icon.Parent = container

	-- Barra de fondo
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBackground"
	barBg.Size = UDim2.new(1, -(sizes.FatnessIconSize + 15), 0, math.floor(sizes.FatnessBarHeight * 0.5))
	barBg.Position = UDim2.new(0, sizes.FatnessIconSize + 8, 0.5, 0)
	barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	barBg.Parent = container
	createCorner(barBg, UDim.new(0, math.floor(sizes.CornerRadius * 0.6)))

	-- Barra de llenado
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(0.5, 0, 1, 0)
	barFill.BackgroundColor3 = Styles.Colors.Secondary
	barFill.Parent = barBg
	createCorner(barFill, UDim.new(0, math.floor(sizes.CornerRadius * 0.6)))

	-- Gradiente
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80)),
	})
	gradient.Rotation = 90
	gradient.Parent = barFill

	return container, barFill
end

-- Contador de monedas
local function createCoinCounter(parent)
	local info = ResponsiveUI.getViewportInfo()
	local iconLeftMargin = 8
	local iconTextGap = info.IsMobile and 12 or 14  -- Espacio ENTRE icono y texto

	local container = Instance.new("Frame")
	container.Name = "CoinCounter"
	container.Size = UDim2.new(0, sizes.CounterWidth, 0, sizes.CounterHeight)
	container.Position = UDim2.new(1, -sizes.CounterMargin, 0, sizes.CounterMargin)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundColor3 = Styles.Colors.Background
	container.Parent = parent

	createCorner(container)
	createStroke(container, Styles.Colors.Primary)

	-- Icono de moneda
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, sizes.CounterIconSize, 0, sizes.CounterIconSize)
	icon.Position = UDim2.new(0, iconLeftMargin, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "💰"
	icon.TextSize = sizes.CounterIconTextSize
	icon.Parent = container

	-- Texto de cantidad (posición = margen + icono + gap)
	local textStartX = iconLeftMargin + sizes.CounterIconSize + iconTextGap
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Size = UDim2.new(1, -(textStartX + 8), 1, 0)
	amount.Position = UDim2.new(0, textStartX, 0, 0)
	amount.BackgroundTransparency = 1
	amount.Text = "0"
	amount.TextColor3 = Styles.Colors.Primary
	amount.TextSize = sizes.CounterTextSize
	amount.Font = Styles.Font
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.TextScaled = true
	amount.Parent = container

	-- Constraint para texto escalado
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = sizes.CounterTextSize
	textConstraint.MinTextSize = 14
	textConstraint.Parent = amount

	return container, amount
end

-- Contador de récord de altura (al lado de monedas)
local function createMaxHeightCounter(parent)
	local info = ResponsiveUI.getViewportInfo()
	local spacing = info.IsMobile and 8 or 10
	local iconLeftMargin = 8
	local iconTextGap = info.IsMobile and 12 or 14  -- Espacio ENTRE icono y texto

	local container = Instance.new("Frame")
	container.Name = "MaxHeightCounter"
	container.Size = UDim2.new(0, sizes.MaxHeightWidth, 0, sizes.CounterHeight)
	-- Posición: a la izquierda del contador de monedas
	container.Position = UDim2.new(1, -(sizes.CounterMargin + sizes.CounterWidth + spacing + sizes.MaxHeightWidth), 0, sizes.CounterMargin)
	container.AnchorPoint = Vector2.new(0, 0)
	container.BackgroundColor3 = Styles.Colors.Background
	container.Parent = parent

	createCorner(container)
	createStroke(container, Styles.Colors.Secondary) -- Borde verde para diferenciarlo

	-- Icono de trofeo/altura
	local iconSize = math.floor(sizes.CounterHeight * 0.7)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, iconSize, 0, iconSize)
	icon.Position = UDim2.new(0, iconLeftMargin, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "🏆"
	icon.TextSize = sizes.MaxHeightIconTextSize
	icon.Parent = container

	-- Texto de altura máxima (posición = margen + icono + gap)
	local textStartX = iconLeftMargin + iconSize + iconTextGap
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Size = UDim2.new(1, -(textStartX + 8), 1, 0)
	amount.Position = UDim2.new(0, textStartX, 0, 0)
	amount.BackgroundTransparency = 1
	amount.Text = "0m"
	amount.TextColor3 = Styles.Colors.Secondary
	amount.TextSize = sizes.MaxHeightTextSize
	amount.Font = Styles.Font
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.TextScaled = true
	amount.Parent = container

	-- Constraint para texto escalado
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = sizes.MaxHeightTextSize
	textConstraint.MinTextSize = 12
	textConstraint.Parent = amount

	return container, amount
end

-- Medidor de altura
local function createHeightMeter(parent)
	local info = ResponsiveUI.getViewportInfo()
	local iconLeftMargin = 8
	local iconTextGap = info.IsMobile and 10 or 12  -- Espacio ENTRE icono y texto

	local container = Instance.new("Frame")
	container.Name = "HeightMeter"
	container.Size = UDim2.new(0, sizes.HeightMeterWidth, 0, sizes.HeightMeterHeight)

	-- En móvil: posición más arriba y a la izquierda para evitar solapamiento
	-- En PC: centrado arriba
	if info.IsMobile then
		container.Position = UDim2.new(0, sizes.CounterMargin, 0, sizes.CounterMargin)
		container.AnchorPoint = Vector2.new(0, 0)
	else
		container.Position = UDim2.new(0.5, 0, 0, sizes.CounterMargin)
		container.AnchorPoint = Vector2.new(0.5, 0)
	end

	container.BackgroundColor3 = Styles.Colors.Background
	container.Parent = parent

	createCorner(container)
	createStroke(container, Styles.Colors.Secondary)

	-- Icono
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, sizes.HeightMeterIconSize, 0, sizes.HeightMeterIconSize)
	icon.Position = UDim2.new(0, iconLeftMargin, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "📏"
	icon.TextSize = math.floor(sizes.HeightMeterIconSize * 0.85)
	icon.Parent = container

	-- Altura actual (posición = margen + icono + gap)
	local textStartX = iconLeftMargin + sizes.HeightMeterIconSize + iconTextGap
	local height = Instance.new("TextLabel")
	height.Name = "Height"
	height.Size = UDim2.new(1, -(textStartX + 6), 1, 0)
	height.Position = UDim2.new(0, textStartX, 0, 0)
	height.BackgroundTransparency = 1
	height.Text = "0m"
	height.TextColor3 = Styles.Colors.Text
	height.TextSize = sizes.HeightMeterTextSize
	height.Font = Styles.Font
	height.TextXAlignment = Enum.TextXAlignment.Center
	height.TextScaled = true
	height.Parent = container

	-- Constraint para texto escalado
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = sizes.HeightMeterTextSize
	textConstraint.MinTextSize = 12
	textConstraint.Parent = height

	return container, height
end

-- Notificación de hito
local function createMilestoneNotification(parent)
	local container = Instance.new("Frame")
	container.Name = "MilestoneNotification"
	container.Size = UDim2.new(0, sizes.MilestoneWidth, 0, sizes.MilestoneHeight)
	container.Position = UDim2.new(0.5, 0, 0.3, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Styles.Colors.Primary
	container.BackgroundTransparency = 1
	container.Visible = false
	container.Parent = parent

	createCorner(container, UDim.new(0, math.floor(sizes.CornerRadius * 1.5)))

	-- Texto principal
	local mainText = Instance.new("TextLabel")
	mainText.Name = "MainText"
	mainText.Size = UDim2.new(1, 0, 0.6, 0)
	mainText.Position = UDim2.new(0, 0, 0, 0)
	mainText.BackgroundTransparency = 1
	mainText.Text = "🎉 100 METROS! 🎉"
	mainText.TextColor3 = Styles.Colors.Text
	mainText.TextSize = sizes.MilestoneMainTextSize
	mainText.Font = Styles.Font
	mainText.TextStrokeTransparency = 0
	mainText.TextStrokeColor3 = Styles.Colors.Shadow
	mainText.TextScaled = true
	mainText.Parent = container

	local mainTextConstraint = Instance.new("UITextSizeConstraint")
	mainTextConstraint.MaxTextSize = sizes.MilestoneMainTextSize
	mainTextConstraint.MinTextSize = 18
	mainTextConstraint.Parent = mainText

	-- Texto de bonus
	local bonusText = Instance.new("TextLabel")
	bonusText.Name = "BonusText"
	bonusText.Size = UDim2.new(1, 0, 0.4, 0)
	bonusText.Position = UDim2.new(0, 0, 0.6, 0)
	bonusText.BackgroundTransparency = 1
	bonusText.Text = "+50 💰"
	bonusText.TextColor3 = Styles.Colors.Primary
	bonusText.TextSize = sizes.MilestoneBonusTextSize
	bonusText.Font = Styles.Font
	bonusText.TextStrokeTransparency = 0
	bonusText.TextScaled = true
	bonusText.Parent = container

	local bonusTextConstraint = Instance.new("UITextSizeConstraint")
	bonusTextConstraint.MaxTextSize = sizes.MilestoneBonusTextSize
	bonusTextConstraint.MinTextSize = 14
	bonusTextConstraint.Parent = bonusText

	return container, mainText, bonusText
end

-- Número flotante de moneda
local function createFloatingNumber(parent)
	local info = ResponsiveUI.getViewportInfo()
	local floatTextSize = info.IsMobile and 20 or 28

	local template = Instance.new("TextLabel")
	template.Name = "FloatingNumber"
	template.Size = UDim2.new(0, 100, 0, 40)
	template.BackgroundTransparency = 1
	template.Text = "+10 💰"
	template.TextColor3 = Styles.Colors.Primary
	template.TextSize = floatTextSize
	template.Font = Styles.Font
	template.TextStrokeTransparency = 0
	template.Visible = false
	template.Parent = parent
	return template
end

-- ============================================
-- INICIALIZAR UI
-- ============================================

local screenGui = createScreenGui()
local fatnessContainer, fatnessBar = createFatnessBar(screenGui)
local coinContainer, coinText = createCoinCounter(screenGui)
local maxHeightContainer, maxHeightText = createMaxHeightCounter(screenGui)
local heightContainer, heightText = createHeightMeter(screenGui)
local milestoneContainer, milestoneMain, milestoneBonus = createMilestoneNotification(screenGui)
local floatingNumberTemplate = createFloatingNumber(screenGui)

-- ============================================
-- FUNCIONES DE ACTUALIZACIÓN
-- ============================================

local function updateFatnessBar(current, max)
	local percentage = math.clamp((current - 0.5) / (max - 0.5), 0, 1)
	TweenService:Create(fatnessBar, TweenInfo.new(0.2), {
		Size = UDim2.new(percentage, 0, 1, 0)
	}):Play()
end

-- Tamaño base fijo para evitar acumulación de animaciones
local coinTextBaseSize = nil

local function updateCoins(amount)
	coinText.Text = tostring(amount)

	-- Guardar tamaño base la primera vez
	if not coinTextBaseSize then
		coinTextBaseSize = coinText.Size
	end

	-- Animación de "pop" - siempre volver al tamaño base fijo
	TweenService:Create(coinText, TweenInfo.new(0.1), {
		Size = UDim2.new(coinTextBaseSize.X.Scale * 1.1, coinTextBaseSize.X.Offset, coinTextBaseSize.Y.Scale, coinTextBaseSize.Y.Offset)
	}):Play()
	task.delay(0.1, function()
		TweenService:Create(coinText, TweenInfo.new(0.1), {
			Size = coinTextBaseSize
		}):Play()
	end)
end

local function updateHeight(height)
	heightText.Text = math.floor(height) .. "m"
end

-- Tamaño base fijo para evitar acumulación de animaciones
local maxHeightTextBaseSize = nil

local function updateMaxHeight(maxHeight)
	-- Formatear altura (metros o km)
	local displayText
	if maxHeight >= 1000 then
		displayText = string.format("%.1fkm", maxHeight / 1000)
	else
		displayText = math.floor(maxHeight) .. "m"
	end

	-- Guardar tamaño base la primera vez
	if not maxHeightTextBaseSize then
		maxHeightTextBaseSize = maxHeightText.Size
	end

	-- Solo animar si cambió el récord
	if maxHeight > playerData.MaxHeight then
		playerData.MaxHeight = maxHeight

		-- Animación de "pop" cuando se supera el récord - siempre volver al tamaño base fijo
		maxHeightText.Text = displayText
		TweenService:Create(maxHeightText, TweenInfo.new(0.1), {
			Size = UDim2.new(maxHeightTextBaseSize.X.Scale * 1.15, maxHeightTextBaseSize.X.Offset, maxHeightTextBaseSize.Y.Scale, maxHeightTextBaseSize.Y.Offset)
		}):Play()
		task.delay(0.1, function()
			TweenService:Create(maxHeightText, TweenInfo.new(0.1), {
				Size = maxHeightTextBaseSize
			}):Play()
		end)
	else
		maxHeightText.Text = displayText
	end
end

local function showMilestone(milestone)
	milestoneMain.Text = "🎉 " .. milestone.Message .. " 🎉"
	milestoneBonus.Text = "+" .. milestone.Bonus .. " 💰"

	milestoneContainer.Visible = true
	milestoneContainer.BackgroundTransparency = 0
	milestoneContainer.Size = UDim2.new(0, 0, 0, 0)

	-- Animación de entrada (usa tamaños responsive)
	local tweenIn = TweenService:Create(milestoneContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, sizes.MilestoneWidth, 0, sizes.MilestoneHeight),
		BackgroundTransparency = 0.2
	})
	tweenIn:Play()
	tweenIn.Completed:Wait()

	task.wait(2)

	-- Animación de salida
	local tweenOut = TweenService:Create(milestoneContainer, TweenInfo.new(0.3), {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.2, 0)
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	milestoneContainer.Visible = false
	milestoneContainer.Position = UDim2.new(0.5, 0, 0.3, 0)
end

local function showFloatingNumber(amount, worldPosition)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local screenPos, onScreen = camera:WorldToScreenPoint(worldPosition)
	if not onScreen then return end

	local floater = floatingNumberTemplate:Clone()
	floater.Text = "+" .. amount .. " 💰"
	floater.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
	floater.Visible = true
	floater.Parent = screenGui

	-- Animación hacia arriba y desvanecimiento
	local tweenUp = TweenService:Create(floater, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, screenPos.X, 0, screenPos.Y - 100),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})
	tweenUp:Play()
	tweenUp.Completed:Connect(function()
		floater:Destroy()
	end)
end

-- ============================================
-- CONEXIONES CON SERVIDOR
-- ============================================

if Remotes then
	-- Datos cargados
	local OnDataLoaded = Remotes:FindFirstChild("OnDataLoaded")
	if OnDataLoaded then
		OnDataLoaded.OnClientEvent:Connect(function(data)
			if data and data.Data then
				playerData.Coins = data.Data.Coins or 0
				playerData.MaxFatness = data.UpgradeValues and data.UpgradeValues.MaxFatness or 3.0
				updateCoins(playerData.Coins)

				-- Actualizar récord de altura
				if data.Data.Records and data.Data.Records.MaxHeight then
					updateMaxHeight(data.Data.Records.MaxHeight)
				end
			end
		end)
	end

	-- Datos actualizados
	local OnDataUpdated = Remotes:FindFirstChild("OnDataUpdated")
	if OnDataUpdated then
		OnDataUpdated.OnClientEvent:Connect(function(data)
			if data then
				playerData.Coins = data.Coins or playerData.Coins
				updateCoins(playerData.Coins)

				-- Actualizar récord de altura si hay nuevos datos
				if data.Records and data.Records.MaxHeight then
					updateMaxHeight(data.Records.MaxHeight)
				end
			end
		end)
	end

	-- Moneda recogida
	local OnCoinCollected = Remotes:FindFirstChild("OnCoinCollected")
	if OnCoinCollected then
		OnCoinCollected.OnClientEvent:Connect(function(amount, totalCoins)
			updateCoins(totalCoins)

			-- Mostrar número flotante
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					showFloatingNumber(amount, rootPart.Position + Vector3.new(0, 3, 0))
				end
			end
		end)
	end

	-- Hito alcanzado
	local OnMilestoneReached = Remotes:FindFirstChild("OnMilestoneReached")
	if OnMilestoneReached then
		OnMilestoneReached.OnClientEvent:Connect(function(milestone)
			showMilestone(milestone)
		end)
	end
end

-- ============================================
-- ACTUALIZACIÓN EN TIEMPO REAL
-- ============================================

-- Exponer función para que FartController actualice la UI
local FartController = {}

function FartController.UpdateFatness(current, max)
	playerData.CurrentFatness = current
	playerData.MaxFatness = max
	updateFatnessBar(current, max)
end

function FartController.UpdateHeight(height)
	playerData.CurrentHeight = height
	updateHeight(height)
end

-- Guardar en _G para acceso desde otros scripts (temporal, mejor usar módulos)
_G.GameHUD = FartController

-- ============================================
-- RESPONSIVE: ACTUALIZAR AL CAMBIAR VIEWPORT
-- ============================================

local function rebuildUI()
	-- Actualizar tamaños responsive
	sizes = getResponsiveSizes()

	-- Recrear UI con nuevos tamaños (simplificado: solo actualizar posiciones clave)
	local info = ResponsiveUI.getViewportInfo()

	-- Actualizar barra de gordura
	fatnessContainer.Size = UDim2.new(0, sizes.FatnessBarWidth, 0, sizes.FatnessBarHeight)
	fatnessContainer.Position = UDim2.new(0, sizes.FatnessBarMargin, 1, -(sizes.FatnessBarMargin + sizes.FatnessBarHeight + 10))

	-- Actualizar contador de monedas
	coinContainer.Size = UDim2.new(0, sizes.CounterWidth, 0, sizes.CounterHeight)
	coinContainer.Position = UDim2.new(1, -sizes.CounterMargin, 0, sizes.CounterMargin)

	-- Actualizar contador de altura máxima
	local spacing = info.IsMobile and 8 or 10
	maxHeightContainer.Size = UDim2.new(0, sizes.MaxHeightWidth, 0, sizes.CounterHeight)
	maxHeightContainer.Position = UDim2.new(1, -(sizes.CounterMargin + sizes.CounterWidth + spacing + sizes.MaxHeightWidth), 0, sizes.CounterMargin)

	-- Actualizar medidor de altura (posición diferente en móvil)
	heightContainer.Size = UDim2.new(0, sizes.HeightMeterWidth, 0, sizes.HeightMeterHeight)
	if info.IsMobile then
		heightContainer.Position = UDim2.new(0, sizes.CounterMargin, 0, sizes.CounterMargin)
		heightContainer.AnchorPoint = Vector2.new(0, 0)
	else
		heightContainer.Position = UDim2.new(0.5, 0, 0, sizes.CounterMargin)
		heightContainer.AnchorPoint = Vector2.new(0.5, 0)
	end

	-- Actualizar milestone
	milestoneContainer.Size = UDim2.new(0, sizes.MilestoneWidth, 0, sizes.MilestoneHeight)
end

-- Escuchar cambios de viewport (rotación de dispositivo, redimensionar ventana)
ResponsiveUI.onViewportChanged(function(info)
	rebuildUI()
end)

print("[GameHUD] UI inicializada (Responsive)")
