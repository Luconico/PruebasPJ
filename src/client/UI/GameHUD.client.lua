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
		Secondary = Color3.fromRGB(50, 200, 80),    -- Verde vibrante
		Accent = Color3.fromRGB(255, 100, 100),     -- Rojo/Rosa
		Background = Color3.fromRGB(40, 40, 60),    -- Azul oscuro
		Text = Color3.fromRGB(255, 255, 255),       -- Blanco
		Shadow = Color3.fromRGB(0, 0, 0),           -- Negro
		-- Nuevos colores para contadores estilo cartoon
		CounterBg = Color3.fromRGB(255, 255, 255),  -- Blanco para contenedores
		CounterStroke = Color3.fromRGB(20, 20, 20), -- Borde oscuro
		-- Colores por tipo de contador
		CoinTextColor = Color3.fromRGB(50, 180, 80),      -- Verde para dinero
		HeightTextColor = Color3.fromRGB(0, 150, 255),    -- Azul para altura actual
		MaxHeightTextColor = Color3.fromRGB(255, 180, 0), -- Dorado/naranja para récord
	},

	-- Fuentes
	Font = Enum.Font.FredokaOne,
	FontBold = Enum.Font.GothamBlack,

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
		-- ============================================
		-- BARRA DE GAS/GORDURA (Estilo Cartoon) - GRANDE
		-- ============================================
		FatnessBarWidth = isMobile and 360 or math.floor(450 * scale), -- Doble de ancho
		FatnessBarHeight = isMobile and 60 or math.floor(70 * scale), -- Más alto
		FatnessBarMargin = isMobile and 12 or math.floor(20 * scale),
		FatnessIconSize = isMobile and 80 or math.floor(95 * scale), -- Icono más grande
		FatnessIconOverflow = isMobile and 22 or math.floor(28 * scale), -- Cuánto sobresale
		FatnessIconTextSize = isMobile and 60 or math.floor(72 * scale), -- Emoji más grande
		FatnessCornerRadius = isMobile and 30 or math.floor(35 * scale), -- Pill shape
		FatnessProgressHeight = isMobile and 28 or math.floor(32 * scale), -- Barra interna más alta

		-- ============================================
		-- NUEVOS CONTADORES ESTILO CARTOON (CENTRADOS)
		-- ============================================
		-- Contenedor más ancho (rectángulo blanco con esquinas redondeadas)
		CounterWidth = isMobile and 160 or math.floor(200 * scale),
		CounterHeight = isMobile and 55 or math.floor(65 * scale),
		CounterMargin = isMobile and 10 or math.floor(15 * scale),
		CounterSpacing = isMobile and 12 or math.floor(18 * scale), -- Espacio entre contadores
		CounterCornerRadius = isMobile and 25 or math.floor(30 * scale), -- Muy redondeado (pill shape)

		-- Icono que sobresale (más grande que el contenedor)
		CounterIconSize = isMobile and 70 or math.floor(85 * scale), -- Icono grande que sobresale
		CounterIconOverflow = isMobile and 20 or math.floor(25 * scale), -- Cuánto sobresale
		CounterIconTextSize = isMobile and 55 or math.floor(65 * scale), -- Emoji grande

		-- Texto con efecto "wow"
		CounterTextSize = isMobile and 30 or math.floor(38 * scale),
		CounterTextStroke = isMobile and 3 or math.floor(4 * scale), -- Borde del texto

		-- Medidor de altura actual (mismo estilo)
		HeightMeterWidth = isMobile and 130 or math.floor(160 * scale),
		HeightMeterHeight = isMobile and 55 or math.floor(65 * scale),

		-- Milestone notification
		MilestoneWidth = isMobile and 300 or math.floor(400 * scale),
		MilestoneHeight = isMobile and 80 or math.floor(100 * scale),
		MilestoneMainTextSize = isMobile and 36 or math.floor(48 * scale),
		MilestoneBonusTextSize = isMobile and 28 or math.floor(32 * scale),

		-- Corner radius general
		CornerRadius = isMobile and 10 or math.floor(12 * scale),

		-- Stroke thickness general
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

-- ============================================
-- BARRA DE GAS/GORDURA (Estilo Cartoon)
-- ============================================
local function createFatnessBar(parent)
	-- Wrapper principal (incluye espacio para icono que sobresale)
	local wrapper = Instance.new("Frame")
	wrapper.Name = "FatnessBar"
	wrapper.Size = UDim2.new(0, sizes.FatnessBarWidth + sizes.FatnessIconOverflow, 0, sizes.FatnessIconSize)
	wrapper.Position = UDim2.new(0, sizes.FatnessBarMargin, 1, -(sizes.FatnessBarMargin + 10))
	wrapper.AnchorPoint = Vector2.new(0, 1)
	wrapper.BackgroundTransparency = 1
	wrapper.Parent = parent

	-- Contenedor blanco (el rectángulo visible)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, sizes.FatnessBarWidth, 0, sizes.FatnessBarHeight)
	container.Position = UDim2.new(0, sizes.FatnessIconOverflow, 0.5, 0)
	container.AnchorPoint = Vector2.new(0, 0.5)
	container.BackgroundColor3 = Styles.Colors.CounterBg
	container.Parent = wrapper

	-- Esquinas muy redondeadas (pill shape)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, sizes.FatnessCornerRadius)
	corner.Parent = container

	-- Borde grueso oscuro
	local stroke = Instance.new("UIStroke")
	stroke.Color = Styles.Colors.CounterStroke
	stroke.Thickness = sizes.StrokeThickness + 1
	stroke.Parent = container

	-- Icono grande que sobresale por la izquierda
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, sizes.FatnessIconSize, 0, sizes.FatnessIconSize)
	iconFrame.Position = UDim2.new(0, 0, 0.5, 0)
	iconFrame.AnchorPoint = Vector2.new(0, 0.5)
	iconFrame.BackgroundTransparency = 1
	iconFrame.ZIndex = 5
	iconFrame.Parent = wrapper

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "🍔"
	iconLabel.TextSize = sizes.FatnessIconTextSize
	iconLabel.ZIndex = 5
	iconLabel.Parent = iconFrame

	-- Calcular offset de la barra para que no se tape con el icono
	local iconOverlapInContainer = sizes.FatnessIconSize - sizes.FatnessIconOverflow
	local barLeftPadding = iconOverlapInContainer + 5

	-- Fondo de la barra de progreso (dentro del contenedor blanco)
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBackground"
	barBg.Size = UDim2.new(1, -(barLeftPadding + 15), 0, sizes.FatnessProgressHeight)
	barBg.Position = UDim2.new(0, barLeftPadding, 0.5, 0)
	barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	barBg.Parent = container

	local barBgCorner = Instance.new("UICorner")
	barBgCorner.CornerRadius = UDim.new(0, math.floor(sizes.FatnessProgressHeight / 2))
	barBgCorner.Parent = barBg

	-- Barra de llenado (verde gradiente)
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(0.5, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	barFill.Parent = barBg

	local barFillCorner = Instance.new("UICorner")
	barFillCorner.CornerRadius = UDim.new(0, math.floor(sizes.FatnessProgressHeight / 2))
	barFillCorner.Parent = barFill

	-- Gradiente verde vibrante
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 220, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 180, 80)),
	})
	gradient.Rotation = 90
	gradient.Parent = barFill

	return wrapper, barFill
end

-- ============================================
-- NUEVO ESTILO: Contador Cartoon (icono sobresale)
-- ============================================
local function createCartoonCounter(parent, name, icon, textColor, position)
	-- Contenedor principal (incluye espacio para icono que sobresale)
	local wrapper = Instance.new("Frame")
	wrapper.Name = name
	wrapper.Size = UDim2.new(0, sizes.CounterWidth + sizes.CounterIconOverflow, 0, sizes.CounterHeight)
	wrapper.Position = position
	wrapper.AnchorPoint = Vector2.new(0, 0)
	wrapper.BackgroundTransparency = 1
	wrapper.Parent = parent

	-- Contenedor blanco (el rectángulo visible)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0, sizes.CounterWidth, 0, sizes.CounterHeight)
	container.Position = UDim2.new(0, sizes.CounterIconOverflow, 0, 0)
	container.BackgroundColor3 = Styles.Colors.CounterBg
	container.Parent = wrapper

	-- Esquinas muy redondeadas (pill shape)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, sizes.CounterCornerRadius)
	corner.Parent = container

	-- Borde grueso oscuro
	local stroke = Instance.new("UIStroke")
	stroke.Color = Styles.Colors.CounterStroke
	stroke.Thickness = sizes.StrokeThickness + 1
	stroke.Parent = container

	-- Icono grande que sobresale por la izquierda
	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "IconFrame"
	iconFrame.Size = UDim2.new(0, sizes.CounterIconSize, 0, sizes.CounterIconSize)
	iconFrame.Position = UDim2.new(0, 0, 0.5, 0)
	iconFrame.AnchorPoint = Vector2.new(0, 0.5)
	iconFrame.BackgroundTransparency = 1
	iconFrame.ZIndex = 5
	iconFrame.Parent = wrapper

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextSize = sizes.CounterIconTextSize
	iconLabel.ZIndex = 5
	iconLabel.Parent = iconFrame

	-- Calcular offset del texto para que no se tape con el icono
	-- El icono ocupa (CounterIconSize - CounterIconOverflow) dentro del container
	local iconOverlapInContainer = sizes.CounterIconSize - sizes.CounterIconOverflow
	local textLeftPadding = iconOverlapInContainer + 5 -- +5 de margen extra

	-- Texto con efecto "wow" (stroke grueso usando UIStroke)
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Size = UDim2.new(1, -(textLeftPadding + 15), 1, 0)
	amount.Position = UDim2.new(0, textLeftPadding, 0, 0)
	amount.BackgroundTransparency = 1
	amount.Text = "0"
	amount.TextColor3 = textColor or Styles.Colors.Text
	amount.TextSize = sizes.CounterTextSize
	amount.Font = Styles.FontBold
	amount.TextXAlignment = Enum.TextXAlignment.Center
	amount.TextScaled = true
	amount.Parent = container

	-- UIStroke para outline grueso del texto (mejor que TextStroke)
	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.new(0, 0, 0)
	textStroke.Thickness = 3 -- Outline grueso
	textStroke.Transparency = 0
	textStroke.Parent = amount

	-- Constraint para texto escalado
	local textConstraint = Instance.new("UITextSizeConstraint")
	textConstraint.MaxTextSize = sizes.CounterTextSize
	textConstraint.MinTextSize = 16
	textConstraint.Parent = amount

	return wrapper, amount, container
end

-- ============================================
-- CREAR CONTENEDOR CENTRADO PARA LOS 3 CONTADORES
-- ============================================
local function createCenteredCountersContainer(parent)
	local totalWidth = sizes.CounterWidth + sizes.CounterIconOverflow
	local totalContainersWidth = (totalWidth * 3) + (sizes.CounterSpacing * 2)

	local container = Instance.new("Frame")
	container.Name = "CountersContainer"
	container.Size = UDim2.new(0, totalContainersWidth, 0, sizes.CounterHeight)
	container.Position = UDim2.new(0.5, 0, 0, sizes.CounterMargin)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.Parent = parent

	return container
end

-- Contador de altura actual (izquierda)
local function createHeightMeter(parent)
	local totalWidth = sizes.CounterWidth + sizes.CounterIconOverflow

	local wrapper, height = createCartoonCounter(
		parent,
		"HeightMeter",
		"📏",
		Styles.Colors.HeightTextColor, -- Azul para altura actual
		UDim2.new(0, 0, 0, 0) -- Primera posición (izquierda)
	)

	height.Text = "0m"

	return wrapper, height
end

-- Contador de trofeos (centro)
local function createTrophyCounter(parent)
	local totalWidth = sizes.CounterWidth + sizes.CounterIconOverflow

	local wrapper, amount = createCartoonCounter(
		parent,
		"TrophyCounter",
		"🏆",
		Styles.Colors.MaxHeightTextColor, -- Dorado/naranja para trofeos
		UDim2.new(0, totalWidth + sizes.CounterSpacing, 0, 0) -- Segunda posición (centro)
	)

	amount.Text = "0"

	return wrapper, amount
end

-- Contador de monedas (derecha)
local function createCoinCounter(parent)
	local totalWidth = sizes.CounterWidth + sizes.CounterIconOverflow

	local wrapper, amount = createCartoonCounter(
		parent,
		"CoinCounter",
		"💰",
		Styles.Colors.CoinTextColor, -- Verde para monedas
		UDim2.new(0, (totalWidth + sizes.CounterSpacing) * 2, 0, 0) -- Tercera posición (derecha)
	)

	return wrapper, amount
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

-- Crear contenedor centrado para los 3 contadores
local countersContainer = createCenteredCountersContainer(screenGui)

-- Crear contadores dentro del contenedor centrado
local heightContainer, heightText = createHeightMeter(countersContainer)
local trophyContainer, trophyText = createTrophyCounter(countersContainer)
local coinContainer, coinText = createCoinCounter(countersContainer)

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
local trophyTextBaseSize = nil

local function updateTrophies(trophies)
	local displayText = tostring(trophies)

	-- Guardar tamaño base la primera vez
	if not trophyTextBaseSize then
		trophyTextBaseSize = trophyText.Size
	end

	-- Solo animar si aumentaron los trofeos
	if trophies > (playerData.Trophies or 0) then
		playerData.Trophies = trophies

		-- Animación de "pop" cuando aumentan trofeos
		trophyText.Text = displayText
		TweenService:Create(trophyText, TweenInfo.new(0.1), {
			Size = UDim2.new(trophyTextBaseSize.X.Scale * 1.15, trophyTextBaseSize.X.Offset, trophyTextBaseSize.Y.Scale, trophyTextBaseSize.Y.Offset)
		}):Play()
		task.delay(0.1, function()
			TweenService:Create(trophyText, TweenInfo.new(0.1), {
				Size = trophyTextBaseSize
			}):Play()
		end)
	else
		playerData.Trophies = trophies
		trophyText.Text = displayText
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

local function showFloatingTrophy(amount, worldPosition)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local screenPos, onScreen = camera:WorldToScreenPoint(worldPosition)
	if not onScreen then return end

	local floater = floatingNumberTemplate:Clone()
	floater.Text = "+" .. amount .. " 🏆"
	floater.TextColor3 = Styles.Colors.MaxHeightTextColor -- Dorado
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

				-- Actualizar trofeos
				if data.Data.Trophies then
					updateTrophies(data.Data.Trophies)
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

				-- Actualizar trofeos si hay nuevos datos
				if data.Trophies then
					updateTrophies(data.Trophies)
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

	-- Trofeo recogido
	local OnTrophyCollected = Remotes:FindFirstChild("OnTrophyCollected")
	if OnTrophyCollected then
		OnTrophyCollected.OnClientEvent:Connect(function(amount, totalTrophies)
			updateTrophies(totalTrophies)

			-- Mostrar número flotante de trofeo
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					showFloatingTrophy(amount, rootPart.Position + Vector3.new(0, 3, 0))
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

	-- Actualizar barra de gordura (wrapper)
	fatnessContainer.Size = UDim2.new(0, sizes.FatnessBarWidth + sizes.FatnessIconOverflow, 0, sizes.FatnessIconSize)
	fatnessContainer.Position = UDim2.new(0, sizes.FatnessBarMargin, 1, -(sizes.FatnessBarMargin + 10))

	-- Calcular ancho total del contenedor centrado
	local totalWidth = sizes.CounterWidth + sizes.CounterIconOverflow
	local totalContainersWidth = (totalWidth * 3) + (sizes.CounterSpacing * 2)

	-- Actualizar contenedor centrado
	countersContainer.Size = UDim2.new(0, totalContainersWidth, 0, sizes.CounterHeight)
	countersContainer.Position = UDim2.new(0.5, 0, 0, sizes.CounterMargin)

	-- Actualizar posiciones de los contadores dentro del contenedor
	heightContainer.Size = UDim2.new(0, totalWidth, 0, sizes.CounterHeight)
	heightContainer.Position = UDim2.new(0, 0, 0, 0)

	trophyContainer.Size = UDim2.new(0, totalWidth, 0, sizes.CounterHeight)
	trophyContainer.Position = UDim2.new(0, totalWidth + sizes.CounterSpacing, 0, 0)

	coinContainer.Size = UDim2.new(0, totalWidth, 0, sizes.CounterHeight)
	coinContainer.Position = UDim2.new(0, (totalWidth + sizes.CounterSpacing) * 2, 0, 0)

	-- Actualizar milestone
	milestoneContainer.Size = UDim2.new(0, sizes.MilestoneWidth, 0, sizes.MilestoneHeight)
end

-- Escuchar cambios de viewport (rotación de dispositivo, redimensionar ventana)
ResponsiveUI.onViewportChanged(function(info)
	rebuildUI()
end)

print("[GameHUD] UI inicializada (Responsive)")
