--[[
	UpgradeShop.client.lua
	Sistema de tienda de upgrades con estilo cartoon
	Gran impacto visual, botones grandes, animaciones fluidas
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local Config = require(Shared:WaitForChild("Config"))

-- ============================================
-- CONFIGURACIÓN DE ESTILOS (CARTOON)
-- ============================================

local Styles = {
	Colors = {
		-- Fondo principal
		Background = Color3.fromRGB(25, 25, 45),
		BackgroundLight = Color3.fromRGB(45, 45, 75),

		-- Colores de acento
		Primary = Color3.fromRGB(255, 200, 50),      -- Amarillo dorado
		Secondary = Color3.fromRGB(100, 220, 100),   -- Verde brillante
		Accent = Color3.fromRGB(255, 100, 150),      -- Rosa
		Purple = Color3.fromRGB(180, 100, 255),      -- Morado
		Blue = Color3.fromRGB(100, 180, 255),        -- Azul cielo

		-- Botones
		CoinButton = Color3.fromRGB(255, 200, 50),
		CoinButtonHover = Color3.fromRGB(255, 220, 100),
		RobuxButton = Color3.fromRGB(100, 200, 100),
		RobuxButtonHover = Color3.fromRGB(130, 230, 130),
		DisabledButton = Color3.fromRGB(100, 100, 100),

		-- Texto
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(40, 40, 60),
		TextMuted = Color3.fromRGB(180, 180, 200),

		-- Bordes
		Border = Color3.fromRGB(255, 255, 255),
		Shadow = Color3.fromRGB(0, 0, 0),
	},

	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
		Button = Enum.Font.FredokaOne,
	},

	-- Iconos para cada upgrade
	UpgradeIcons = {
		MaxFatness = "🍔",
		EatSpeed = "⚡",
		PropulsionForce = "🚀",
		FuelEfficiency = "⛽",
	},

	-- Colores para cada upgrade
	UpgradeColors = {
		MaxFatness = Color3.fromRGB(255, 150, 50),      -- Naranja
		EatSpeed = Color3.fromRGB(255, 220, 50),        -- Amarillo
		PropulsionForce = Color3.fromRGB(100, 200, 255), -- Azul
		FuelEfficiency = Color3.fromRGB(150, 255, 150),  -- Verde
	},
}

-- ============================================
-- ESTADO
-- ============================================

local isShopOpen = false
local playerData = nil
local upgradeValues = nil
local shopGui = nil

-- ============================================
-- FUNCIONES HELPER
-- ============================================

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 16)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Styles.Colors.Border
	stroke.Thickness = thickness or 4
	stroke.Parent = parent
	return stroke
end

local function createGradient(parent, color1, color2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2),
	})
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

local function createPadding(parent, padding)
	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingTop = UDim.new(0, padding)
	uiPadding.PaddingBottom = UDim.new(0, padding)
	uiPadding.PaddingLeft = UDim.new(0, padding)
	uiPadding.PaddingRight = UDim.new(0, padding)
	uiPadding.Parent = parent
	return uiPadding
end

-- Animación de "bounce" para botones
local function animateButtonPress(button)
	local originalSize = button.Size
	TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(originalSize.X.Scale * 0.95, originalSize.X.Offset * 0.95,
						  originalSize.Y.Scale * 0.95, originalSize.Y.Offset * 0.95)
	}):Play()
	task.wait(0.1)
	TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = originalSize
	}):Play()
end

-- Formatear números grandes
local function formatNumber(num)
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(num)
end

-- ============================================
-- CREAR UI PRINCIPAL
-- ============================================

local function createShopUI()
	-- ScreenGui principal
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "UpgradeShop"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 10
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Fondo oscuro semi-transparente
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	-- Contenedor principal de la tienda
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.new(0, 900, 0, 650)
	mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.BackgroundColor3 = Styles.Colors.Background
	mainContainer.Parent = screenGui

	createCorner(mainContainer, UDim.new(0, 24))
	createStroke(mainContainer, Styles.Colors.Primary, 6)

	-- Gradiente de fondo sutil
	createGradient(mainContainer,
		Color3.fromRGB(35, 35, 65),
		Color3.fromRGB(25, 25, 45),
		180)

	-- ============================================
	-- HEADER
	-- ============================================

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 100)
	header.BackgroundColor3 = Styles.Colors.Primary
	header.Parent = mainContainer

	createCorner(header, UDim.new(0, 24))
	createGradient(header,
		Color3.fromRGB(255, 220, 100),
		Color3.fromRGB(255, 180, 50),
		90)

	-- Parche inferior para que no se vea el corner abajo
	local headerPatch = Instance.new("Frame")
	headerPatch.Name = "HeaderPatch"
	headerPatch.Size = UDim2.new(1, 0, 0, 30)
	headerPatch.Position = UDim2.new(0, 0, 1, -30)
	headerPatch.BackgroundColor3 = Styles.Colors.Primary
	headerPatch.BorderSizePixel = 0
	headerPatch.Parent = header
	createGradient(headerPatch,
		Color3.fromRGB(255, 200, 70),
		Color3.fromRGB(255, 180, 50),
		90)

	-- Título
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -120, 1, 0)
	title.Position = UDim2.new(0, 20, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "🛒 TIENDA DE UPGRADES 🛒"
	title.TextColor3 = Styles.Colors.TextDark
	title.TextSize = 42
	title.Font = Styles.Fonts.Title
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Botón de cerrar
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 70, 0, 70)
	closeButton.Position = UDim2.new(1, -85, 0.5, 0)
	closeButton.AnchorPoint = Vector2.new(0, 0.5)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.TextSize = 42
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Parent = header

	createCorner(closeButton, UDim.new(0, 16))
	createStroke(closeButton, Color3.fromRGB(200, 50, 50), 4)

	-- Mostrar monedas del jugador
	local coinsDisplay = Instance.new("Frame")
	coinsDisplay.Name = "CoinsDisplay"
	coinsDisplay.Size = UDim2.new(0, 200, 0, 50)
	coinsDisplay.Position = UDim2.new(1, -300, 0.5, 0)
	coinsDisplay.AnchorPoint = Vector2.new(0, 0.5)
	coinsDisplay.BackgroundColor3 = Styles.Colors.Background
	coinsDisplay.Parent = header

	createCorner(coinsDisplay, UDim.new(0, 12))
	createStroke(coinsDisplay, Styles.Colors.TextDark, 3)

	local coinsIcon = Instance.new("TextLabel")
	coinsIcon.Size = UDim2.new(0, 40, 1, 0)
	coinsIcon.BackgroundTransparency = 1
	coinsIcon.Text = "💰"
	coinsIcon.TextSize = 28
	coinsIcon.Parent = coinsDisplay

	local coinsText = Instance.new("TextLabel")
	coinsText.Name = "CoinsText"
	coinsText.Size = UDim2.new(1, -50, 1, 0)
	coinsText.Position = UDim2.new(0, 45, 0, 0)
	coinsText.BackgroundTransparency = 1
	coinsText.Text = "0"
	coinsText.TextColor3 = Styles.Colors.Primary
	coinsText.TextSize = 28
	coinsText.Font = Styles.Fonts.Title
	coinsText.TextXAlignment = Enum.TextXAlignment.Left
	coinsText.Parent = coinsDisplay

	-- ============================================
	-- CONTENEDOR DE UPGRADES
	-- ============================================

	local upgradesContainer = Instance.new("ScrollingFrame")
	upgradesContainer.Name = "UpgradesContainer"
	upgradesContainer.Size = UDim2.new(1, -40, 1, -130)
	upgradesContainer.Position = UDim2.new(0, 20, 0, 110)
	upgradesContainer.BackgroundTransparency = 1
	upgradesContainer.ScrollBarThickness = 8
	upgradesContainer.ScrollBarImageColor3 = Styles.Colors.Primary
	upgradesContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	upgradesContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	upgradesContainer.Parent = mainContainer

	-- Layout para upgrades
	local upgradesLayout = Instance.new("UIListLayout")
	upgradesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	upgradesLayout.Padding = UDim.new(0, 20)
	upgradesLayout.Parent = upgradesContainer

	return screenGui, mainContainer, upgradesContainer, coinsText, closeButton, backdrop
end

-- ============================================
-- CREAR TARJETA DE UPGRADE
-- ============================================

local function createUpgradeCard(parent, upgradeName, upgradeConfig, layoutOrder)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. upgradeName
	card.Size = UDim2.new(1, 0, 0, 140)
	card.BackgroundColor3 = Styles.Colors.BackgroundLight
	card.LayoutOrder = layoutOrder
	card.Parent = parent

	createCorner(card, UDim.new(0, 16))

	local accentColor = Styles.UpgradeColors[upgradeName] or Styles.Colors.Primary
	createStroke(card, accentColor, 4)

	-- Barra de color lateral
	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 8, 1, -20)
	accentBar.Position = UDim2.new(0, 10, 0.5, 0)
	accentBar.AnchorPoint = Vector2.new(0, 0.5)
	accentBar.BackgroundColor3 = accentColor
	accentBar.Parent = card
	createCorner(accentBar, UDim.new(0, 4))

	-- Icono grande
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 80, 0, 80)
	icon.Position = UDim2.new(0, 30, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundColor3 = accentColor
	icon.BackgroundTransparency = 0.3
	icon.Text = Styles.UpgradeIcons[upgradeName] or "⭐"
	icon.TextSize = 48
	icon.Parent = card
	createCorner(icon, UDim.new(0, 16))

	-- Contenedor de información
	local infoContainer = Instance.new("Frame")
	infoContainer.Name = "InfoContainer"
	infoContainer.Size = UDim2.new(0, 350, 1, -20)
	infoContainer.Position = UDim2.new(0, 130, 0.5, 0)
	infoContainer.AnchorPoint = Vector2.new(0, 0.5)
	infoContainer.BackgroundTransparency = 1
	infoContainer.Parent = card

	-- Nombre del upgrade
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 35)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = upgradeConfig.Name
	nameLabel.TextColor3 = Styles.Colors.Text
	nameLabel.TextSize = 28
	nameLabel.Font = Styles.Fonts.Title
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = infoContainer

	-- Descripción
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(1, 0, 0, 25)
	descLabel.Position = UDim2.new(0, 0, 0, 35)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = upgradeConfig.Description
	descLabel.TextColor3 = Styles.Colors.TextMuted
	descLabel.TextSize = 16
	descLabel.Font = Styles.Fonts.Body
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.Parent = infoContainer

	-- Nivel actual
	local levelContainer = Instance.new("Frame")
	levelContainer.Name = "LevelContainer"
	levelContainer.Size = UDim2.new(1, 0, 0, 30)
	levelContainer.Position = UDim2.new(0, 0, 0, 65)
	levelContainer.BackgroundTransparency = 1
	levelContainer.Parent = infoContainer

	local levelLabel = Instance.new("TextLabel")
	levelLabel.Name = "LevelLabel"
	levelLabel.Size = UDim2.new(0, 100, 1, 0)
	levelLabel.BackgroundTransparency = 1
	levelLabel.Text = "Nivel: 0/10"
	levelLabel.TextColor3 = accentColor
	levelLabel.TextSize = 20
	levelLabel.Font = Styles.Fonts.Body
	levelLabel.TextXAlignment = Enum.TextXAlignment.Left
	levelLabel.Parent = levelContainer

	-- Barra de progreso de nivel
	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(0, 200, 0, 16)
	progressBg.Position = UDim2.new(0, 110, 0.5, 0)
	progressBg.AnchorPoint = Vector2.new(0, 0.5)
	progressBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	progressBg.Parent = levelContainer
	createCorner(progressBg, UDim.new(0, 8))

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.BackgroundColor3 = accentColor
	progressFill.Parent = progressBg
	createCorner(progressFill, UDim.new(0, 8))

	-- Valor actual → próximo valor
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "ValueLabel"
	valueLabel.Size = UDim2.new(1, 0, 0, 25)
	valueLabel.Position = UDim2.new(0, 0, 0, 95)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "Valor: 3.0 → 3.5"
	valueLabel.TextColor3 = Styles.Colors.Text
	valueLabel.TextSize = 16
	valueLabel.Font = Styles.Fonts.Body
	valueLabel.TextXAlignment = Enum.TextXAlignment.Left
	valueLabel.Parent = infoContainer

	-- ============================================
	-- BOTONES DE COMPRA
	-- ============================================

	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(0, 280, 1, -20)
	buttonsContainer.Position = UDim2.new(1, -20, 0.5, 0)
	buttonsContainer.AnchorPoint = Vector2.new(1, 0.5)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = card

	-- Botón de monedas
	local coinButton = Instance.new("TextButton")
	coinButton.Name = "CoinButton"
	coinButton.Size = UDim2.new(1, 0, 0, 50)
	coinButton.Position = UDim2.new(0, 0, 0, 10)
	coinButton.BackgroundColor3 = Styles.Colors.CoinButton
	coinButton.Text = ""
	coinButton.AutoButtonColor = false
	coinButton.Parent = buttonsContainer

	createCorner(coinButton, UDim.new(0, 12))
	createStroke(coinButton, Color3.fromRGB(200, 150, 30), 3)
	createGradient(coinButton,
		Color3.fromRGB(255, 220, 100),
		Color3.fromRGB(255, 180, 50),
		90)

	local coinButtonContent = Instance.new("Frame")
	coinButtonContent.Size = UDim2.new(1, 0, 1, 0)
	coinButtonContent.BackgroundTransparency = 1
	coinButtonContent.Parent = coinButton

	local coinIcon = Instance.new("TextLabel")
	coinIcon.Size = UDim2.new(0, 40, 1, 0)
	coinIcon.BackgroundTransparency = 1
	coinIcon.Text = "💰"
	coinIcon.TextSize = 24
	coinIcon.Parent = coinButtonContent

	local coinPriceLabel = Instance.new("TextLabel")
	coinPriceLabel.Name = "PriceLabel"
	coinPriceLabel.Size = UDim2.new(1, -50, 1, 0)
	coinPriceLabel.Position = UDim2.new(0, 45, 0, 0)
	coinPriceLabel.BackgroundTransparency = 1
	coinPriceLabel.Text = "100 Monedas"
	coinPriceLabel.TextColor3 = Styles.Colors.TextDark
	coinPriceLabel.TextSize = 22
	coinPriceLabel.Font = Styles.Fonts.Button
	coinPriceLabel.TextXAlignment = Enum.TextXAlignment.Left
	coinPriceLabel.Parent = coinButtonContent

	-- Botón de Robux
	local robuxButton = Instance.new("TextButton")
	robuxButton.Name = "RobuxButton"
	robuxButton.Size = UDim2.new(1, 0, 0, 50)
	robuxButton.Position = UDim2.new(0, 0, 0, 70)
	robuxButton.BackgroundColor3 = Styles.Colors.RobuxButton
	robuxButton.Text = ""
	robuxButton.AutoButtonColor = false
	robuxButton.Parent = buttonsContainer

	createCorner(robuxButton, UDim.new(0, 12))
	createStroke(robuxButton, Color3.fromRGB(70, 150, 70), 3)
	createGradient(robuxButton,
		Color3.fromRGB(130, 230, 130),
		Color3.fromRGB(80, 180, 80),
		90)

	local robuxButtonContent = Instance.new("Frame")
	robuxButtonContent.Size = UDim2.new(1, 0, 1, 0)
	robuxButtonContent.BackgroundTransparency = 1
	robuxButtonContent.Parent = robuxButton

	local robuxIcon = Instance.new("TextLabel")
	robuxIcon.Size = UDim2.new(0, 40, 1, 0)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Text = "💎"
	robuxIcon.TextSize = 24
	robuxIcon.Parent = robuxButtonContent

	local robuxPriceLabel = Instance.new("TextLabel")
	robuxPriceLabel.Name = "PriceLabel"
	robuxPriceLabel.Size = UDim2.new(1, -50, 1, 0)
	robuxPriceLabel.Position = UDim2.new(0, 45, 0, 0)
	robuxPriceLabel.BackgroundTransparency = 1
	robuxPriceLabel.Text = "10 Robux"
	robuxPriceLabel.TextColor3 = Styles.Colors.TextDark
	robuxPriceLabel.TextSize = 22
	robuxPriceLabel.Font = Styles.Fonts.Button
	robuxPriceLabel.TextXAlignment = Enum.TextXAlignment.Left
	robuxPriceLabel.Parent = robuxButtonContent

	-- Etiqueta de "MAX" cuando está al máximo
	local maxLabel = Instance.new("TextLabel")
	maxLabel.Name = "MaxLabel"
	maxLabel.Size = UDim2.new(1, 0, 1, -20)
	maxLabel.Position = UDim2.new(0, 0, 0.5, 0)
	maxLabel.AnchorPoint = Vector2.new(0, 0.5)
	maxLabel.BackgroundTransparency = 1
	maxLabel.Text = "⭐ MÁXIMO ⭐"
	maxLabel.TextColor3 = Styles.Colors.Primary
	maxLabel.TextSize = 32
	maxLabel.Font = Styles.Fonts.Title
	maxLabel.Visible = false
	maxLabel.Parent = buttonsContainer

	return {
		Card = card,
		LevelLabel = levelLabel,
		ProgressFill = progressFill,
		ValueLabel = valueLabel,
		CoinButton = coinButton,
		CoinPriceLabel = coinPriceLabel,
		RobuxButton = robuxButton,
		RobuxPriceLabel = robuxPriceLabel,
		MaxLabel = maxLabel,
		UpgradeName = upgradeName,
		UpgradeConfig = upgradeConfig,
	}
end

-- ============================================
-- ACTUALIZAR TARJETA DE UPGRADE
-- ============================================

local function updateUpgradeCard(cardData)
	if not playerData then return end

	local upgradeName = cardData.UpgradeName
	local upgradeConfig = cardData.UpgradeConfig
	local currentLevel = playerData.Upgrades[upgradeName] or 0
	local maxLevel = upgradeConfig.MaxLevel
	local isMaxed = currentLevel >= maxLevel

	-- Actualizar nivel
	cardData.LevelLabel.Text = "Nivel: " .. currentLevel .. "/" .. maxLevel

	-- Actualizar barra de progreso
	local progressWidth = (currentLevel / maxLevel) * 200
	TweenService:Create(cardData.ProgressFill, TweenInfo.new(0.3), {
		Size = UDim2.new(0, progressWidth, 1, 0)
	}):Play()

	-- Calcular valores (soporta ValuesPerLevel exponencial o IncrementPerLevel lineal)
	local function getValueAtLevel(config, level)
		if config.ValuesPerLevel and level > 0 then
			return config.ValuesPerLevel[level] or config.BaseValue
		end
		return config.BaseValue + ((config.IncrementPerLevel or 0) * level)
	end

	local currentValue = getValueAtLevel(upgradeConfig, currentLevel)
	local nextValue = getValueAtLevel(upgradeConfig, currentLevel + 1)

	if isMaxed then
		cardData.ValueLabel.Text = "Valor: " .. string.format("%.2f", currentValue) .. " (MAX)"
		cardData.CoinButton.Visible = false
		cardData.RobuxButton.Visible = false
		cardData.MaxLabel.Visible = true
	else
		cardData.ValueLabel.Text = "Valor: " .. string.format("%.2f", currentValue) .. " → " .. string.format("%.2f", nextValue)
		cardData.CoinButton.Visible = true
		cardData.RobuxButton.Visible = true
		cardData.MaxLabel.Visible = false

		-- Actualizar precios
		local coinCost = upgradeConfig.CostCoins[currentLevel + 1]
		local robuxCost = upgradeConfig.CostRobux[currentLevel + 1]

		cardData.CoinPriceLabel.Text = formatNumber(coinCost) .. " Monedas"
		cardData.RobuxPriceLabel.Text = robuxCost .. " Robux"

		-- Verificar si puede comprar con monedas
		local canAfford = playerData.Coins >= coinCost
		if canAfford then
			cardData.CoinButton.BackgroundColor3 = Styles.Colors.CoinButton
		else
			cardData.CoinButton.BackgroundColor3 = Styles.Colors.DisabledButton
		end
	end
end

-- ============================================
-- SISTEMA DE COMPRA
-- ============================================

local function purchaseUpgrade(upgradeName, useRobux)
	if not Remotes then return end

	local PurchaseUpgrade = Remotes:FindFirstChild("PurchaseUpgrade")
	if not PurchaseUpgrade then
		warn("[UpgradeShop] RemoteFunction PurchaseUpgrade no encontrada")
		return
	end

	-- Llamar al servidor
	local result = PurchaseUpgrade:InvokeServer(upgradeName, useRobux)

	if result then
		if result.Success then
			print("[UpgradeShop] Compra exitosa:", result.Message)
			-- Los datos se actualizarán automáticamente via OnDataUpdated
		else
			warn("[UpgradeShop] Compra fallida:", result.Message)
			-- TODO: Mostrar mensaje de error al jugador
		end
	end

	return result
end

-- ============================================
-- CREAR NOTIFICACIÓN DE COMPRA
-- ============================================

local function showPurchaseNotification(success, message)
	if not shopGui then return end

	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 400, 0, 60)
	notification.Position = UDim2.new(0.5, 0, 0, -80)
	notification.AnchorPoint = Vector2.new(0.5, 0)
	notification.BackgroundColor3 = success and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(200, 80, 80)
	notification.Parent = shopGui

	createCorner(notification, UDim.new(0, 12))

	local notifText = Instance.new("TextLabel")
	notifText.Size = UDim2.new(1, 0, 1, 0)
	notifText.BackgroundTransparency = 1
	notifText.Text = success and "✓ " .. message or "✗ " .. message
	notifText.TextColor3 = Color3.new(1, 1, 1)
	notifText.TextSize = 24
	notifText.Font = Styles.Fonts.Title
	notifText.Parent = notification

	-- Animación de entrada
	TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 20)
	}):Play()

	-- Esperar y salir
	task.delay(2, function()
		TweenService:Create(notification, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, -80)
		}):Play()
		task.wait(0.3)
		notification:Destroy()
	end)
end

-- ============================================
-- ABRIR/CERRAR TIENDA
-- ============================================

local upgradeCards = {}

local function openShop()
	if isShopOpen then return end
	isShopOpen = true

	-- Solicitar datos actualizados
	if Remotes then
		local GetPlayerData = Remotes:FindFirstChild("GetPlayerData")
		if GetPlayerData then
			local data = GetPlayerData:InvokeServer()
			if data then
				playerData = data.Data
				upgradeValues = data.UpgradeValues
			end
		end
	end

	shopGui.Enabled = true

	-- Animación de entrada
	local mainContainer = shopGui:FindFirstChild("MainContainer")
	if mainContainer then
		mainContainer.Size = UDim2.new(0, 0, 0, 0)
		mainContainer.BackgroundTransparency = 1

		TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 900, 0, 650),
			BackgroundTransparency = 0
		}):Play()
	end

	-- Actualizar todas las tarjetas
	for _, cardData in pairs(upgradeCards) do
		updateUpgradeCard(cardData)
	end

	-- Actualizar monedas mostradas
	local coinsText = shopGui.MainContainer.Header.CoinsDisplay:FindFirstChild("CoinsText")
	if coinsText and playerData then
		coinsText.Text = formatNumber(playerData.Coins)
	end
end

local function closeShop()
	if not isShopOpen then return end

	local mainContainer = shopGui:FindFirstChild("MainContainer")
	if mainContainer then
		local tween = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		})
		tween:Play()
		tween.Completed:Wait()
	end

	shopGui.Enabled = false
	isShopOpen = false
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

local function initialize()
	-- Crear UI
	local gui, mainContainer, upgradesContainer, coinsText, closeButton, backdrop = createShopUI()
	shopGui = gui

	-- Crear tarjetas para cada upgrade
	local layoutOrder = 1
	for upgradeName, upgradeConfig in pairs(Config.Upgrades) do
		local cardData = createUpgradeCard(upgradesContainer, upgradeName, upgradeConfig, layoutOrder)
		upgradeCards[upgradeName] = cardData
		layoutOrder = layoutOrder + 1

		-- Conectar botones
		cardData.CoinButton.MouseButton1Click:Connect(function()
			animateButtonPress(cardData.CoinButton)
			local result = purchaseUpgrade(upgradeName, false)
			if result then
				showPurchaseNotification(result.Success, result.Message)
			end
		end)

		cardData.RobuxButton.MouseButton1Click:Connect(function()
			animateButtonPress(cardData.RobuxButton)
			local result = purchaseUpgrade(upgradeName, true)
			if result then
				showPurchaseNotification(result.Success, result.Message)
			end
		end)

		-- Efectos hover
		cardData.CoinButton.MouseEnter:Connect(function()
			TweenService:Create(cardData.CoinButton, TweenInfo.new(0.1), {
				Size = UDim2.new(1, 4, 0, 54)
			}):Play()
		end)

		cardData.CoinButton.MouseLeave:Connect(function()
			TweenService:Create(cardData.CoinButton, TweenInfo.new(0.1), {
				Size = UDim2.new(1, 0, 0, 50)
			}):Play()
		end)

		cardData.RobuxButton.MouseEnter:Connect(function()
			TweenService:Create(cardData.RobuxButton, TweenInfo.new(0.1), {
				Size = UDim2.new(1, 4, 0, 54)
			}):Play()
		end)

		cardData.RobuxButton.MouseLeave:Connect(function()
			TweenService:Create(cardData.RobuxButton, TweenInfo.new(0.1), {
				Size = UDim2.new(1, 0, 0, 50)
			}):Play()
		end)
	end

	-- Botón de cerrar
	closeButton.MouseButton1Click:Connect(function()
		animateButtonPress(closeButton)
		closeShop()
	end)

	-- Click en backdrop cierra
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			closeShop()
		end
	end)

	-- Escuchar actualizaciones de datos
	if Remotes then
		local OnDataUpdated = Remotes:FindFirstChild("OnDataUpdated")
		if OnDataUpdated then
			OnDataUpdated.OnClientEvent:Connect(function(data)
				if data then
					playerData = data

					-- Actualizar monedas
					local coinsTextLabel = shopGui.MainContainer.Header.CoinsDisplay:FindFirstChild("CoinsText")
					if coinsTextLabel then
						coinsTextLabel.Text = formatNumber(data.Coins)
					end

					-- Actualizar tarjetas
					for _, cardData in pairs(upgradeCards) do
						updateUpgradeCard(cardData)
					end
				end
			end)
		end

		local OnDataLoaded = Remotes:FindFirstChild("OnDataLoaded")
		if OnDataLoaded then
			OnDataLoaded.OnClientEvent:Connect(function(data)
				if data and data.Data then
					playerData = data.Data
					upgradeValues = data.UpgradeValues
				end
			end)
		end
	end

	print("[UpgradeShop] Sistema de tienda inicializado")
end

-- ============================================
-- EVENTOS DE ZONA DE UPGRADE
-- ============================================

if Remotes then
	local OnUpgradeZoneEnter = Remotes:WaitForChild("OnUpgradeZoneEnter", 5)
	if OnUpgradeZoneEnter then
		OnUpgradeZoneEnter.OnClientEvent:Connect(function()
			openShop()
		end)
	end

	local OnUpgradeZoneExit = Remotes:WaitForChild("OnUpgradeZoneExit", 5)
	if OnUpgradeZoneExit then
		OnUpgradeZoneExit.OnClientEvent:Connect(function()
			closeShop()
		end)
	end
end

-- Exponer funciones globalmente para testing
_G.UpgradeShop = {
	Open = openShop,
	Close = closeShop,
	IsOpen = function() return isShopOpen end,
}

-- ============================================
-- TECLA PARA ABRIR TIENDA (P = tienda/Purchase)
-- ============================================

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	-- Tecla P para abrir/cerrar tienda
	if input.KeyCode == Enum.KeyCode.P then
		if isShopOpen then
			closeShop()
		else
			openShop()
		end
	end

	-- Tecla Escape para cerrar
	if input.KeyCode == Enum.KeyCode.Escape and isShopOpen then
		closeShop()
	end
end)

-- Inicializar
initialize()

print("[UpgradeShop] Presiona 'P' para abrir la tienda de upgrades")
