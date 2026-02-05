--[[
	SpinWheel.client.lua
	Ruleta de la suerte con premios de oro
	- Giro animado con física realista
	- 3 giros gratis cada hora
	- Compra de giros adicionales con Robux
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar módulos
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- ============================================
-- CONFIGURACIÓN DE PREMIOS
-- ============================================

local WHEEL_PRIZES = {
	{
		Name = "Jackpot",
		Icon = "💰",
		Gold = 10000,
		Chance = 0.01,
		Color = Color3.fromRGB(180, 100, 255), -- Morado
	},
	{
		Name = "Mega Prize",
		Icon = "🍕",
		Gold = 5000,
		Chance = 5,
		Color = Color3.fromRGB(255, 180, 100), -- Naranja
	},
	{
		Name = "Grand Prize",
		Icon = "🌈",
		Gold = 2500,
		Chance = 9.99,
		Color = Color3.fromRGB(255, 150, 200), -- Rosa
	},
	{
		Name = "Major Prize",
		Icon = "🍔",
		Gold = 1000,
		Chance = 35,
		Color = Color3.fromRGB(255, 200, 100), -- Amarillo
	},
	{
		Name = "Medium Prize",
		Icon = "💨",
		Gold = 500,
		Chance = 45,
		Color = Color3.fromRGB(255, 150, 200), -- Rosa claro
	},
	{
		Name = "Minor Prize",
		Icon = "🍣",
		Gold = 250,
		Chance = 5,
		Color = Color3.fromRGB(255, 200, 100), -- Naranja claro
	},
}

-- Configuración de giros
local FREE_SPINS_PER_HOUR = 3
local FREE_SPIN_COOLDOWN = 3600 -- 1 hora en segundos

-- Precios de Robux para giros
local SPIN_PRICES = {
	{Amount = 1, Robux = 25, Sale = false},
	{Amount = 10, Robux = 200, Sale = false},
	{Amount = 100, Robux = 1500, Sale = true},
}

-- ============================================
-- ESTADO
-- ============================================

local isWheelOpen = false
local isSpinning = false
local currentRotation = 0
local availableSpins = 0
local lastFreeSpinTime = 0
local wheelContainer = nil
local wheelFrame = nil
local spinButton = nil
local spinsCountLabel = nil
local timerLabel = nil

-- Botón persistente
local persistentButton = nil
local persistentBadge = nil
local persistentTimer = nil

-- Forward declarations
local spinWheel
local toggleWheel
local showPrizeNotification
local updateFreeSpins

-- ============================================
-- TAMAÑOS RESPONSIVE
-- ============================================

local function getResponsiveSizes()
	local info = ResponsiveUI.getViewportInfo()
	local isMobile = info.IsMobile

	return {
		WheelSize = isMobile and 280 or 400,
		CenterButtonSize = isMobile and 70 or 100,
		ArrowSize = isMobile and 40 or 60,
		CloseButtonSize = isMobile and 50 or 70,
		SidePanelWidth = isMobile and 120 or 180,
		ButtonHeight = isMobile and 50 or 65,
		ButtonSpacing = isMobile and 8 or 12,
		BottomPanelHeight = isMobile and 50 or 60,
		FontSizeSmall = isMobile and 14 or 18,
		FontSizeMedium = isMobile and 18 or 24,
		FontSizeLarge = isMobile and 24 or 32,
		IconSize = isMobile and 30 or 45,
		IsMobile = isMobile,
	}
end

local sizes = getResponsiveSizes()

-- ============================================
-- HELPERS
-- ============================================

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 12)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.new(0, 0, 0)
	stroke.Thickness = thickness or 3
	stroke.Parent = parent
	return stroke
end

-- Seleccionar premio basado en probabilidades
local function selectPrize()
	local totalWeight = 0
	for _, prize in ipairs(WHEEL_PRIZES) do
		totalWeight = totalWeight + prize.Chance
	end

	local random = math.random() * totalWeight
	local cumulative = 0

	for i, prize in ipairs(WHEEL_PRIZES) do
		cumulative = cumulative + prize.Chance
		if random <= cumulative then
			return i, prize
		end
	end

	return #WHEEL_PRIZES, WHEEL_PRIZES[#WHEEL_PRIZES]
end

-- Formatear tiempo
local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", mins, secs)
end

-- Formatear oro
local function formatGold(amount)
	if amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	end
	return tostring(amount)
end

-- ============================================
-- CREAR BOTÓN PERSISTENTE (SIEMPRE VISIBLE)
-- ============================================

local function createPersistentButton()
	-- ScreenGui separado para el botón persistente
	local buttonGui = Instance.new("ScreenGui")
	buttonGui.Name = "SpinWheelButton"
	buttonGui.ResetOnSpawn = false
	buttonGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	buttonGui.Parent = playerGui

	-- Contenedor principal del botón
	persistentButton = Instance.new("TextButton")
	persistentButton.Name = "WheelButton"
	persistentButton.Size = UDim2.new(0, sizes.IsMobile and 55 or 70, 0, sizes.IsMobile and 55 or 70)
	persistentButton.Position = UDim2.new(0, sizes.IsMobile and 15 or 20, 0, sizes.IsMobile and 150 or 180)
	persistentButton.AnchorPoint = Vector2.new(0, 0)
	persistentButton.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
	persistentButton.Text = ""
	persistentButton.AutoButtonColor = true
	persistentButton.Parent = buttonGui

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 15)
	buttonCorner.Parent = persistentButton

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Color3.fromRGB(40, 80, 140)
	buttonStroke.Thickness = 3
	buttonStroke.Parent = persistentButton

	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 160, 230)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 180)),
	})
	buttonGradient.Rotation = 90
	buttonGradient.Parent = persistentButton

	-- Icono de ruleta arcoíris
	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(0, sizes.IsMobile and 38 or 48, 0, sizes.IsMobile and 38 or 48)
	iconContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	iconContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	iconContainer.BackgroundColor3 = Color3.new(1, 1, 1)
	iconContainer.Parent = persistentButton

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.5, 0)
	iconCorner.Parent = iconContainer

	local iconGradient = Instance.new("UIGradient")
	iconGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 100)),
		ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 180, 100)),
		ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 255, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 255, 100)),
		ColorSequenceKeypoint.new(0.67, Color3.fromRGB(100, 200, 255)),
		ColorSequenceKeypoint.new(0.83, Color3.fromRGB(150, 100, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200)),
	})
	iconGradient.Rotation = 45
	iconGradient.Parent = iconContainer

	local iconStroke = Instance.new("UIStroke")
	iconStroke.Color = Color3.fromRGB(80, 80, 80)
	iconStroke.Thickness = 2
	iconStroke.Parent = iconContainer

	local iconCenter = Instance.new("Frame")
	iconCenter.Name = "Center"
	iconCenter.Size = UDim2.new(0, sizes.IsMobile and 14 or 18, 0, sizes.IsMobile and 14 or 18)
	iconCenter.Position = UDim2.new(0.5, 0, 0.5, 0)
	iconCenter.AnchorPoint = Vector2.new(0.5, 0.5)
	iconCenter.BackgroundColor3 = Color3.new(1, 1, 1)
	iconCenter.ZIndex = 2
	iconCenter.Parent = iconContainer

	local centerCorner = Instance.new("UICorner")
	centerCorner.CornerRadius = UDim.new(0.5, 0)
	centerCorner.Parent = iconCenter

	-- Badge verde con contador de giros
	persistentBadge = Instance.new("TextLabel")
	persistentBadge.Name = "SpinsBadge"
	persistentBadge.Size = UDim2.new(0, sizes.IsMobile and 22 or 28, 0, sizes.IsMobile and 22 or 28)
	persistentBadge.Position = UDim2.new(1, sizes.IsMobile and -2 or -4, 0, sizes.IsMobile and -2 or -4)
	persistentBadge.AnchorPoint = Vector2.new(1, 0)
	persistentBadge.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	persistentBadge.Text = "0"
	persistentBadge.TextColor3 = Color3.new(1, 1, 1)
	persistentBadge.TextSize = sizes.IsMobile and 14 or 18
	persistentBadge.Font = Enum.Font.GothamBlack
	persistentBadge.ZIndex = 5
	persistentBadge.Parent = persistentButton

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(0.5, 0)
	badgeCorner.Parent = persistentBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = Color3.fromRGB(40, 120, 40)
	badgeStroke.Thickness = 2
	badgeStroke.Parent = persistentBadge

	-- Timer debajo del botón
	local timerContainer = Instance.new("Frame")
	timerContainer.Name = "TimerContainer"
	timerContainer.Size = UDim2.new(0, sizes.IsMobile and 55 or 70, 0, sizes.IsMobile and 22 or 26)
	timerContainer.Position = UDim2.new(0.5, 0, 1, 5)
	timerContainer.AnchorPoint = Vector2.new(0.5, 0)
	timerContainer.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
	timerContainer.Parent = persistentButton

	local timerCorner = Instance.new("UICorner")
	timerCorner.CornerRadius = UDim.new(0, 8)
	timerCorner.Parent = timerContainer

	local timerStroke = Instance.new("UIStroke")
	timerStroke.Color = Color3.fromRGB(200, 130, 30)
	timerStroke.Thickness = 2
	timerStroke.Parent = timerContainer

	local timerGradient = Instance.new("UIGradient")
	timerGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 30)),
	})
	timerGradient.Rotation = 90
	timerGradient.Parent = timerContainer

	persistentTimer = Instance.new("TextLabel")
	persistentTimer.Name = "TimerText"
	persistentTimer.Size = UDim2.new(1, 0, 1, 0)
	persistentTimer.BackgroundTransparency = 1
	persistentTimer.Text = "00:00"
	persistentTimer.TextColor3 = Color3.new(1, 1, 1)
	persistentTimer.TextSize = sizes.IsMobile and 12 or 14
	persistentTimer.Font = Enum.Font.GothamBold
	persistentTimer.TextStrokeTransparency = 0.5
	persistentTimer.TextStrokeColor3 = Color3.new(0, 0, 0)
	persistentTimer.Parent = timerContainer

	-- Conectar click para abrir la ruleta
	persistentButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.4, 1.0)
		toggleWheel(true)
	end)

	persistentButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.2, 1.1)
	end)

	return buttonGui
end

-- ============================================
-- CREAR RUEDA (Versión simplificada que funciona)
-- ============================================

local function createWheel(parent)
	local numSegments = #WHEEL_PRIZES
	local anglePerSegment = 360 / numSegments

	-- Contenedor de la rueda (para rotar)
	wheelFrame = Instance.new("Frame")
	wheelFrame.Name = "WheelFrame"
	wheelFrame.Size = UDim2.new(0, sizes.WheelSize, 0, sizes.WheelSize)
	wheelFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	wheelFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelFrame.BackgroundTransparency = 1
	wheelFrame.Parent = parent

	-- Fondo circular de la rueda con borde
	local wheelBg = Instance.new("Frame")
	wheelBg.Name = "WheelBackground"
	wheelBg.Size = UDim2.new(1, 0, 1, 0)
	wheelBg.Position = UDim2.new(0.5, 0, 0.5, 0)
	wheelBg.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelBg.BackgroundColor3 = Color3.fromRGB(120, 130, 150)
	wheelBg.ZIndex = 1
	wheelBg.Parent = wheelFrame

	local wheelCorner = Instance.new("UICorner")
	wheelCorner.CornerRadius = UDim.new(0.5, 0)
	wheelCorner.Parent = wheelBg

	local wheelStroke = Instance.new("UIStroke")
	wheelStroke.Color = Color3.fromRGB(80, 80, 100)
	wheelStroke.Thickness = 8
	wheelStroke.Parent = wheelBg

	-- Contenedor interno para los segmentos (con ClipsDescendants)
	local segmentsContainer = Instance.new("Frame")
	segmentsContainer.Name = "SegmentsContainer"
	segmentsContainer.Size = UDim2.new(1, -16, 1, -16)
	segmentsContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	segmentsContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	segmentsContainer.BackgroundTransparency = 1
	segmentsContainer.ClipsDescendants = true
	segmentsContainer.ZIndex = 2
	segmentsContainer.Parent = wheelBg

	local segCorner = Instance.new("UICorner")
	segCorner.CornerRadius = UDim.new(0.5, 0)
	segCorner.Parent = segmentsContainer

	-- Crear segmentos usando la técnica de "conic sections" simulada
	-- Cada segmento es un frame grande rotado que se superpone parcialmente
	for i, prize in ipairs(WHEEL_PRIZES) do
		local startAngle = (i - 1) * anglePerSegment

		-- Crear el segmento usando un frame con forma de "rebanada"
		-- Usamos un frame que ocupa la mitad superior y lo rotamos
		local segmentContainer = Instance.new("Frame")
		segmentContainer.Name = "Segment_" .. i
		segmentContainer.Size = UDim2.new(1, 0, 1, 0)
		segmentContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
		segmentContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		segmentContainer.BackgroundTransparency = 1
		segmentContainer.Rotation = startAngle
		segmentContainer.ZIndex = 2
		segmentContainer.ClipsDescendants = true
		segmentContainer.Parent = segmentsContainer

		-- Mitad visible del segmento
		local halfContainer = Instance.new("Frame")
		halfContainer.Name = "HalfContainer"
		halfContainer.Size = UDim2.new(1, 0, 0.5, 0)
		halfContainer.Position = UDim2.new(0, 0, 0, 0)
		halfContainer.BackgroundTransparency = 1
		halfContainer.ClipsDescendants = true
		halfContainer.ZIndex = 2
		halfContainer.Parent = segmentContainer

		-- El segmento de color
		local segment = Instance.new("Frame")
		segment.Name = "ColorSegment"
		segment.Size = UDim2.new(1, 0, 2, 0)
		segment.Position = UDim2.new(0.5, 0, 1, 0)
		segment.AnchorPoint = Vector2.new(0.5, 1)
		segment.BackgroundColor3 = prize.Color
		segment.Rotation = anglePerSegment / 2
		segment.ZIndex = 2
		segment.Parent = halfContainer

		-- Hacer que solo se vea el ángulo correcto
		if anglePerSegment < 180 then
			-- Crear máscara para ocultar el exceso
			local mask = Instance.new("Frame")
			mask.Name = "Mask"
			mask.Size = UDim2.new(1, 0, 2, 0)
			mask.Position = UDim2.new(0.5, 0, 1, 0)
			mask.AnchorPoint = Vector2.new(0.5, 1)
			mask.BackgroundColor3 = Color3.fromRGB(120, 130, 150) -- Mismo color que el fondo
			mask.Rotation = -anglePerSegment / 2
			mask.ZIndex = 3
			mask.Parent = halfContainer
		end
	end

	-- Como la técnica de segmentos es compleja en Roblox, usamos un enfoque más simple:
	-- Dibujar líneas divisorias y mostrar los premios en posiciones calculadas

	-- Limpiar los segmentos complejos y usar un gradiente simple
	for _, child in ipairs(segmentsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Fondo con gradiente de colores alternados (simulación simple)
	-- Crear 6 "rebanadas" usando ImageLabels o simplemente mostrar colores
	local innerCircle = Instance.new("Frame")
	innerCircle.Name = "InnerCircle"
	innerCircle.Size = UDim2.new(1, 0, 1, 0)
	innerCircle.Position = UDim2.new(0.5, 0, 0.5, 0)
	innerCircle.AnchorPoint = Vector2.new(0.5, 0.5)
	innerCircle.BackgroundColor3 = Color3.fromRGB(255, 200, 150) -- Color base
	innerCircle.ZIndex = 2
	innerCircle.Parent = segmentsContainer

	local innerCorner = Instance.new("UICorner")
	innerCorner.CornerRadius = UDim.new(0.5, 0)
	innerCorner.Parent = innerCircle

	-- Crear contenido de los segmentos (iconos y cantidades)
	-- Posicionamos cada elemento usando coordenadas polares
	for i, prize in ipairs(WHEEL_PRIZES) do
		local startAngle = (i - 1) * anglePerSegment - 90 -- -90 para que empiece arriba
		local midAngle = startAngle + anglePerSegment / 2

		-- Calcular posición usando coordenadas polares
		-- El contenido está a ~70% del radio desde el centro
		local radius = 0.35 -- 35% del tamaño total (70% del radio)
		local angleRad = math.rad(midAngle)
		local posX = 0.5 + math.cos(angleRad) * radius
		local posY = 0.5 + math.sin(angleRad) * radius

		-- Contenedor para icono y texto (rotado para apuntar hacia afuera)
		local contentHolder = Instance.new("Frame")
		contentHolder.Name = "Content_" .. i
		contentHolder.Size = UDim2.new(0, sizes.IconSize * 2, 0, sizes.IconSize * 1.5)
		contentHolder.Position = UDim2.new(posX, 0, posY, 0)
		contentHolder.AnchorPoint = Vector2.new(0.5, 0.5)
		contentHolder.BackgroundTransparency = 1
		contentHolder.ZIndex = 5
		-- Rotar para que apunte hacia afuera (el ángulo + 90 para que "arriba" del contenedor apunte hacia el borde)
		contentHolder.Rotation = midAngle + 90
		contentHolder.Parent = innerCircle

		-- Icono del premio
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, 0, 0.6, 0)
		icon.Position = UDim2.new(0.5, 0, 0.3, 0)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.BackgroundTransparency = 1
		icon.Text = prize.Icon
		icon.TextSize = sizes.IconSize
		icon.ZIndex = 6
		icon.Parent = contentHolder

		-- Cantidad de oro
		local goldLabel = Instance.new("TextLabel")
		goldLabel.Name = "Gold"
		goldLabel.Size = UDim2.new(1, 0, 0.4, 0)
		goldLabel.Position = UDim2.new(0.5, 0, 0.75, 0)
		goldLabel.AnchorPoint = Vector2.new(0.5, 0.5)
		goldLabel.BackgroundTransparency = 1
		goldLabel.Text = formatGold(prize.Gold)
		goldLabel.TextColor3 = Color3.new(1, 1, 1)
		goldLabel.TextSize = sizes.FontSizeMedium
		goldLabel.Font = Enum.Font.GothamBold
		goldLabel.TextStrokeTransparency = 0
		goldLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		goldLabel.ZIndex = 6
		goldLabel.Parent = contentHolder
	end

	-- Líneas divisorias entre segmentos
	for i = 1, numSegments do
		local angle = (i - 1) * anglePerSegment - 90

		local lineHolder = Instance.new("Frame")
		lineHolder.Name = "LineHolder_" .. i
		lineHolder.Size = UDim2.new(1, 0, 1, 0)
		lineHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
		lineHolder.AnchorPoint = Vector2.new(0.5, 0.5)
		lineHolder.BackgroundTransparency = 1
		lineHolder.Rotation = angle
		lineHolder.ZIndex = 4
		lineHolder.Parent = innerCircle

		local line = Instance.new("Frame")
		line.Name = "Line"
		line.Size = UDim2.new(0.5, 0, 0, 3)
		line.Position = UDim2.new(0.5, 0, 0.5, 0)
		line.AnchorPoint = Vector2.new(0, 0.5)
		line.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
		line.BorderSizePixel = 0
		line.ZIndex = 4
		line.Parent = lineHolder
	end

	-- Puntos decorativos alrededor del borde
	for i = 1, 12 do
		local angle = (i - 1) * 30
		local dot = Instance.new("Frame")
		dot.Name = "Dot_" .. i
		dot.Size = UDim2.new(0, 12, 0, 12)
		dot.Position = UDim2.new(
			0.5 + math.cos(math.rad(angle - 90)) * 0.46,
			0,
			0.5 + math.sin(math.rad(angle - 90)) * 0.46,
			0
		)
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.BackgroundColor3 = Color3.new(1, 1, 1)
		dot.ZIndex = 7
		dot.Parent = wheelBg

		local dotCorner = Instance.new("UICorner")
		dotCorner.CornerRadius = UDim.new(0.5, 0)
		dotCorner.Parent = dot

		local dotStroke = Instance.new("UIStroke")
		dotStroke.Color = Color3.fromRGB(80, 80, 80)
		dotStroke.Thickness = 1
		dotStroke.Parent = dot
	end

	-- Botón central "Spin"
	spinButton = Instance.new("TextButton")
	spinButton.Name = "SpinButton"
	spinButton.Size = UDim2.new(0, sizes.CenterButtonSize, 0, sizes.CenterButtonSize)
	spinButton.Position = UDim2.new(0.5, 0, 0.5, 0)
	spinButton.AnchorPoint = Vector2.new(0.5, 0.5)
	spinButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	spinButton.Text = "Spin"
	spinButton.TextColor3 = Color3.new(1, 1, 1)
	spinButton.TextSize = sizes.FontSizeLarge
	spinButton.Font = Enum.Font.GothamBlack
	spinButton.ZIndex = 10
	spinButton.Parent = wheelFrame

	local spinCorner = Instance.new("UICorner")
	spinCorner.CornerRadius = UDim.new(0.5, 0)
	spinCorner.Parent = spinButton

	local spinStroke = Instance.new("UIStroke")
	spinStroke.Color = Color3.fromRGB(255, 200, 50)
	spinStroke.Thickness = 5
	spinStroke.Parent = spinButton

	local spinGradient = Instance.new("UIGradient")
	spinGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80)),
	})
	spinGradient.Rotation = 90
	spinGradient.Parent = spinButton

	return wheelFrame
end

-- ============================================
-- CREAR FLECHA INDICADORA
-- ============================================

local function createArrow(parent)
	local arrowContainer = Instance.new("Frame")
	arrowContainer.Name = "ArrowContainer"
	arrowContainer.Size = UDim2.new(0, sizes.ArrowSize, 0, sizes.ArrowSize * 1.5)
	arrowContainer.Position = UDim2.new(0.5, 0, 0, -10)
	arrowContainer.AnchorPoint = Vector2.new(0.5, 0)
	arrowContainer.BackgroundTransparency = 1
	arrowContainer.ZIndex = 20
	arrowContainer.Parent = parent

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.Size = UDim2.new(1, 0, 1, 0)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▼"
	arrow.TextColor3 = Color3.fromRGB(220, 50, 50)
	arrow.TextSize = sizes.ArrowSize * 1.5
	arrow.Font = Enum.Font.GothamBlack
	arrow.TextStrokeColor3 = Color3.fromRGB(150, 30, 30)
	arrow.TextStrokeTransparency = 0
	arrow.ZIndex = 20
	arrow.Parent = arrowContainer

	return arrowContainer
end

-- ============================================
-- CREAR PANEL LATERAL (COMPRA DE GIROS)
-- ============================================

local function createSidePanel(parent)
	local panel = Instance.new("Frame")
	panel.Name = "SidePanel"
	panel.Size = UDim2.new(0, sizes.SidePanelWidth, 0, (sizes.ButtonHeight + sizes.ButtonSpacing) * 3)
	panel.Position = UDim2.new(1, 20, 0.5, 0)
	panel.AnchorPoint = Vector2.new(0, 0.5)
	panel.BackgroundTransparency = 1
	panel.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, sizes.ButtonSpacing)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Parent = panel

	for i, priceInfo in ipairs(SPIN_PRICES) do
		local button = Instance.new("TextButton")
		button.Name = "BuySpins_" .. priceInfo.Amount
		button.Size = UDim2.new(1, 0, 0, sizes.ButtonHeight)
		button.BackgroundColor3 = priceInfo.Sale and Color3.fromRGB(255, 180, 50) or Color3.fromRGB(80, 180, 255)
		button.Text = ""
		button.LayoutOrder = i
		button.Parent = panel

		createCorner(button)
		createStroke(button, Color3.fromRGB(50, 50, 50), 2)

		local gradient = Instance.new("UIGradient")
		if priceInfo.Sale then
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 80)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 30)),
			})
		else
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 150, 220)),
			})
		end
		gradient.Rotation = 90
		gradient.Parent = button

		-- Icono de ruleta
		local icon = Instance.new("TextLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 30, 0, 30)
		icon.Position = UDim2.new(0, 10, 0.5, 0)
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.BackgroundColor3 = Color3.new(1, 1, 1)
		icon.Text = "🌈"
		icon.TextSize = 20
		icon.Parent = button

		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(0.5, 0)
		iconCorner.Parent = icon

		-- Texto de cantidad
		local amountLabel = Instance.new("TextLabel")
		amountLabel.Name = "Amount"
		amountLabel.Size = UDim2.new(0.6, 0, 1, 0)
		amountLabel.Position = UDim2.new(0.4, 0, 0, 0)
		amountLabel.BackgroundTransparency = 1
		amountLabel.Text = "+" .. priceInfo.Amount
		amountLabel.TextColor3 = Color3.new(1, 1, 1)
		amountLabel.TextSize = sizes.FontSizeMedium
		amountLabel.Font = Enum.Font.GothamBlack
		amountLabel.TextStrokeTransparency = 0.5
		amountLabel.Parent = button

		-- Etiqueta de SALE
		if priceInfo.Sale then
			local saleTag = Instance.new("TextLabel")
			saleTag.Name = "SaleTag"
			saleTag.Size = UDim2.new(0, 45, 0, 20)
			saleTag.Position = UDim2.new(1, -5, 0, -5)
			saleTag.AnchorPoint = Vector2.new(1, 0)
			saleTag.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			saleTag.Text = "SALE"
			saleTag.TextColor3 = Color3.new(1, 1, 1)
			saleTag.TextSize = 12
			saleTag.Font = Enum.Font.GothamBold
			saleTag.ZIndex = 5
			saleTag.Parent = button

			local saleCorner = Instance.new("UICorner")
			saleCorner.CornerRadius = UDim.new(0, 5)
			saleCorner.Parent = saleTag
		end

		-- Conectar evento de compra
		button.MouseButton1Click:Connect(function()
			if not isSpinning then
				-- TODO: Implementar compra con Robux
				print("[SpinWheel] Comprar " .. priceInfo.Amount .. " giros por " .. priceInfo.Robux .. " R$")
				-- Por ahora, dar giros gratis para pruebas
				availableSpins = availableSpins + priceInfo.Amount
				if spinsCountLabel then
					spinsCountLabel.Text = tostring(availableSpins)
				end
				if persistentBadge then
					persistentBadge.Text = tostring(availableSpins)
					persistentBadge.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
				end
			end
		end)
	end

	return panel
end

-- ============================================
-- CREAR PANEL INFERIOR (CONTADOR Y TIMER)
-- ============================================

local function createBottomPanel(parent)
	local panel = Instance.new("Frame")
	panel.Name = "BottomPanel"
	panel.Size = UDim2.new(0, sizes.WheelSize * 0.6, 0, sizes.BottomPanelHeight)
	panel.Position = UDim2.new(0.5, 0, 1, 30)
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	panel.Parent = parent

	createCorner(panel)
	createStroke(panel, Color3.fromRGB(50, 150, 50), 3)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 220, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80)),
	})
	gradient.Rotation = 90
	gradient.Parent = panel

	-- Icono
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 15, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundColor3 = Color3.new(1, 1, 1)
	icon.Text = "🌈"
	icon.TextSize = 28
	icon.Parent = panel

	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(0.5, 0)
	iconCorner.Parent = icon

	-- Contador de giros disponibles
	spinsCountLabel = Instance.new("TextLabel")
	spinsCountLabel.Name = "SpinsCount"
	spinsCountLabel.Size = UDim2.new(0.5, 0, 1, 0)
	spinsCountLabel.Position = UDim2.new(0.5, 0, 0, 0)
	spinsCountLabel.BackgroundTransparency = 1
	spinsCountLabel.Text = tostring(availableSpins)
	spinsCountLabel.TextColor3 = Color3.new(1, 1, 1)
	spinsCountLabel.TextSize = sizes.FontSizeLarge
	spinsCountLabel.Font = Enum.Font.GothamBlack
	spinsCountLabel.Parent = panel

	local spinsStroke = Instance.new("UIStroke")
	spinsStroke.Color = Color3.fromRGB(0, 0, 0)
	spinsStroke.Thickness = 3
	spinsStroke.Parent = spinsCountLabel

	-- Timer de giro gratis
	timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "Timer"
	timerLabel.Size = UDim2.new(0, sizes.WheelSize * 0.6, 0, 25)
	timerLabel.Position = UDim2.new(0.5, 0, 1, 10)
	timerLabel.AnchorPoint = Vector2.new(0.5, 0)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "Free Spin In 00:00"
	timerLabel.TextColor3 = Color3.new(1, 1, 1)
	timerLabel.TextSize = sizes.FontSizeSmall
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.TextStrokeTransparency = 0.5
	timerLabel.Parent = parent

	return panel
end

-- ============================================
-- CREAR UI COMPLETA
-- ============================================

local function createWheelUI()
	sizes = getResponsiveSizes()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpinWheelUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.IgnoreGuiInset = true -- Ignorar el espacio de la barra superior para cubrir toda la pantalla
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Fondo oscuro
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.ZIndex = 1
	backdrop.Parent = screenGui

	-- Contenedor principal
	wheelContainer = Instance.new("Frame")
	wheelContainer.Name = "WheelContainer"
	wheelContainer.Size = UDim2.new(0, sizes.WheelSize + sizes.SidePanelWidth + 50, 0, sizes.WheelSize + 120)
	wheelContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	wheelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	wheelContainer.BackgroundTransparency = 1
	wheelContainer.ZIndex = 2
	wheelContainer.Parent = screenGui

	-- Contenedor de la rueda
	local wheelArea = Instance.new("Frame")
	wheelArea.Name = "WheelArea"
	wheelArea.Size = UDim2.new(0, sizes.WheelSize, 0, sizes.WheelSize)
	wheelArea.Position = UDim2.new(0, 0, 0.5, 0)
	wheelArea.AnchorPoint = Vector2.new(0, 0.5)
	wheelArea.BackgroundTransparency = 1
	wheelArea.Parent = wheelContainer

	-- Crear componentes
	createWheel(wheelArea)
	createArrow(wheelArea)
	createSidePanel(wheelArea)
	createBottomPanel(wheelArea)

	-- Botón de cerrar (usando UIComponentsManager)
	local closeButton = UIComponentsManager.createCloseButton(wheelContainer, {
		size = sizes.CloseButtonSize,
		onClose = function()
			toggleWheel(false)
		end
	})
	closeButton.ZIndex = 10

	-- Conectar botón de spin
	spinButton.MouseButton1Click:Connect(function()
		if not isSpinning and availableSpins > 0 then
			spinWheel()
		elseif availableSpins <= 0 then
			SoundManager.play("Error", 0.4, 0.8)
			local originalColor = spinButton.BackgroundColor3
			spinButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
			task.delay(0.3, function()
				spinButton.BackgroundColor3 = originalColor
			end)
		end
	end)

	spinButton.MouseEnter:Connect(function()
		if not isSpinning then
			SoundManager.play("ButtonHover", 0.2, 1.0)
		end
	end)

	return screenGui
end

-- ============================================
-- NOTIFICACIÓN DE PREMIO
-- ============================================

showPrizeNotification = function(prize)
	local screenGui = playerGui:FindFirstChild("SpinWheelUI")
	if not screenGui then return end

	local notification = Instance.new("Frame")
	notification.Name = "PrizeNotification"
	notification.Size = UDim2.new(0, 300, 0, 150)
	notification.Position = UDim2.new(0.5, 0, 0.5, 0)
	notification.AnchorPoint = Vector2.new(0.5, 0.5)
	notification.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	notification.ZIndex = 100
	notification.Parent = screenGui

	createCorner(notification, UDim.new(0, 20))
	createStroke(notification, prize.Color, 4)

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 50)),
	})
	gradient.Rotation = 90
	gradient.Parent = notification

	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, 60, 0, 60)
	icon.Position = UDim2.new(0.5, 0, 0, 20)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Text = prize.Icon
	icon.TextSize = 50
	icon.ZIndex = 101
	icon.Parent = notification

	local prizeText = Instance.new("TextLabel")
	prizeText.Size = UDim2.new(1, -20, 0, 30)
	prizeText.Position = UDim2.new(0.5, 0, 0.55, 0)
	prizeText.AnchorPoint = Vector2.new(0.5, 0)
	prizeText.BackgroundTransparency = 1
	prizeText.Text = prize.Name
	prizeText.TextColor3 = prize.Color
	prizeText.TextSize = 24
	prizeText.Font = Enum.Font.GothamBold
	prizeText.ZIndex = 101
	prizeText.Parent = notification

	local prizeStroke = Instance.new("UIStroke")
	prizeStroke.Color = Color3.fromRGB(0, 0, 0)
	prizeStroke.Thickness = 2
	prizeStroke.Parent = prizeText

	local goldText = Instance.new("TextLabel")
	goldText.Size = UDim2.new(1, -20, 0, 35)
	goldText.Position = UDim2.new(0.5, 0, 0.75, 0)
	goldText.AnchorPoint = Vector2.new(0.5, 0)
	goldText.BackgroundTransparency = 1
	goldText.Text = "+" .. prize.Gold .. " 💰"
	goldText.TextColor3 = Color3.fromRGB(255, 215, 0)
	goldText.TextSize = 32
	goldText.Font = Enum.Font.GothamBlack
	goldText.ZIndex = 101
	goldText.Parent = notification

	local goldStroke = Instance.new("UIStroke")
	goldStroke.Color = Color3.fromRGB(0, 0, 0)
	goldStroke.Thickness = 3
	goldStroke.Parent = goldText

	notification.Size = UDim2.new(0, 0, 0, 0)
	local showTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 300, 0, 150)
	})
	showTween:Play()

	task.delay(2.5, function()
		local hideTween = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		hideTween:Play()
		hideTween.Completed:Connect(function()
			notification:Destroy()
		end)
	end)
end

-- ============================================
-- ANIMACIÓN DE GIRO
-- ============================================

spinWheel = function()
	if isSpinning or availableSpins <= 0 then return end

	-- 🔊 Sonido de inicio de giro
	SoundManager.play("SpinStart", 0.5, 1.0)
	SoundManager.play("ButtonClick", 0.4, 1.0)

	isSpinning = true
	availableSpins = availableSpins - 1

	if spinsCountLabel then
		spinsCountLabel.Text = tostring(availableSpins)
	end

	if persistentBadge then
		persistentBadge.Text = tostring(availableSpins)
		if availableSpins > 0 then
			persistentBadge.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
		else
			persistentBadge.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
		end
	end

	local prizeIndex, prize = selectPrize()

	local numSegments = #WHEEL_PRIZES
	local anglePerSegment = 360 / numSegments

	local targetSegmentCenter = (prizeIndex - 1) * anglePerSegment + anglePerSegment / 2

	local fullRotations = math.random(5, 8) * 360
	local finalAngle = currentRotation + fullRotations + (360 - targetSegmentCenter)

	local spinDuration = 4 + math.random() * 2

	local tweenInfo = TweenInfo.new(
		spinDuration,
		Enum.EasingStyle.Quart,
		Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(wheelFrame, tweenInfo, {
		Rotation = finalAngle
	})

	spinButton.Text = "..."
	spinButton.BackgroundColor3 = Color3.fromRGB(150, 150, 150)

	tween:Play()

	tween.Completed:Connect(function()
		currentRotation = finalAngle
		isSpinning = false

		spinButton.Text = "Spin"
		spinButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)

		-- 🔊 Sonidos de victoria según el premio
		if prize.Gold >= 5000 then
			-- Gran premio: fanfarria completa
			SoundManager.play("WinBig", 0.6, 1.0)
			task.delay(0.2, function()
				SoundManager.play("WinSmall", 0.5, 1.1)
			end)
			task.delay(0.4, function()
				SoundManager.play("Sparkle", 0.5, 0.9)
			end)
			task.delay(0.7, function()
				SoundManager.play("Sparkle", 0.4, 1.3)
			end)
		else
			-- Premio normal: cash register y sparkle
			SoundManager.play("WinSmall", 0.5, 1.0)
			task.delay(0.2, function()
				SoundManager.play("Sparkle", 0.4, 1.1)
			end)
		end

		showPrizeNotification(prize)

		print("[SpinWheel] Premio ganado: " .. prize.Name .. " - " .. prize.Gold .. " oro")
	end)
end

-- ============================================
-- TOGGLE RUEDA
-- ============================================

toggleWheel = function(open)
	local screenGui = playerGui:FindFirstChild("SpinWheelUI")
	if not screenGui then
		screenGui = createWheelUI()
	end

	if open == nil then
		open = not isWheelOpen
	end

	-- 🔊 Sonidos de abrir/cerrar
	if open and not isWheelOpen then
		SoundManager.play("WheelOpen", 0.4, 0.9)
		task.delay(0.15, function()
			SoundManager.play("Sparkle", 0.3, 1.2)
		end)
	elseif not open and isWheelOpen then
		SoundManager.play("WheelClose", 0.3, 1.3)
	end

	isWheelOpen = open
	screenGui.Enabled = open
end

-- ============================================
-- SISTEMA DE GIROS GRATIS
-- ============================================

updateFreeSpins = function()
	local currentTime = os.time()
	local timeSinceLastFree = currentTime - lastFreeSpinTime

	local freeSpinsEarned = math.floor(timeSinceLastFree / (FREE_SPIN_COOLDOWN / FREE_SPINS_PER_HOUR))

	if freeSpinsEarned > 0 and availableSpins < FREE_SPINS_PER_HOUR then
		local spinsToAdd = math.min(freeSpinsEarned, FREE_SPINS_PER_HOUR - availableSpins)
		availableSpins = availableSpins + spinsToAdd
		lastFreeSpinTime = currentTime

		if spinsCountLabel then
			spinsCountLabel.Text = tostring(availableSpins)
		end
	end

	local timeUntilNext = 0
	local spinsAreFull = availableSpins >= FREE_SPINS_PER_HOUR

	if not spinsAreFull then
		timeUntilNext = (FREE_SPIN_COOLDOWN / FREE_SPINS_PER_HOUR) - (timeSinceLastFree % (FREE_SPIN_COOLDOWN / FREE_SPINS_PER_HOUR))
	end

	if timerLabel then
		if spinsAreFull then
			timerLabel.Text = "Spins Full!"
		else
			timerLabel.Text = "Free Spin In " .. formatTime(timeUntilNext)
		end
	end

	if persistentBadge then
		persistentBadge.Text = tostring(availableSpins)
		if availableSpins > 0 then
			persistentBadge.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
		else
			persistentBadge.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
		end
	end

	if persistentTimer then
		if spinsAreFull then
			persistentTimer.Text = "FULL!"
		else
			persistentTimer.Text = formatTime(timeUntilNext)
		end
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

-- Crear UI de la ruleta
createWheelUI()

-- Crear botón persistente
createPersistentButton()

-- Dar giros iniciales para pruebas
availableSpins = 3
lastFreeSpinTime = os.time()

-- Actualizar badge inicial
if persistentBadge then
	persistentBadge.Text = tostring(availableSpins)
end

-- Input para abrir la rueda (tecla R)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.R then
		toggleWheel()
	end
end)

-- Loop de actualización del timer
local lastUpdateTime = 0
RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	if currentTime - lastUpdateTime >= 0.5 then
		lastUpdateTime = currentTime
		updateFreeSpins()
	end
end)

-- Responsive
ResponsiveUI.onViewportChanged(function()
	local screenGui = playerGui:FindFirstChild("SpinWheelUI")
	if screenGui then
		screenGui:Destroy()
	end
	isWheelOpen = false
	sizes = getResponsiveSizes()
	createWheelUI()

	local buttonGui = playerGui:FindFirstChild("SpinWheelButton")
	if buttonGui then
		buttonGui:Destroy()
	end
	createPersistentButton()

	if persistentBadge then
		persistentBadge.Text = tostring(availableSpins)
	end
end)

print("[SpinWheel] Ruleta de la suerte inicializada")
