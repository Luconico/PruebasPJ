--[[
	CosmeticsShop.client.lua
	Tienda de cosméticos visuales para pedos
	Compras con Robux - diferentes colores y efectos
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar módulos
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))

-- Esperar Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- ============================================
-- TAMAÑOS RESPONSIVE
-- ============================================

local function getResponsiveSizes()
	local info = ResponsiveUI.getViewportInfo()
	local scale = info.Scale
	local isMobile = info.IsMobile
	local isTablet = info.IsTablet

	return {
		-- Contenedor principal
		ContainerWidth = isMobile and 0.95 or (isTablet and 0.85 or 0.6),
		ContainerHeight = isMobile and 0.92 or (isTablet and 0.85 or 0.8),
		UseScale = isMobile or isTablet,

		-- Header
		HeaderHeight = isMobile and 70 or math.floor(90 * scale),
		TitleSize = isMobile and 24 or math.floor(36 * scale),
		CloseButtonSize = isMobile and 50 or math.floor(60 * scale),

		-- Grid de cosméticos
		CardSize = isMobile and 140 or math.floor(180 * scale),
		CardPadding = isMobile and 10 or math.floor(15 * scale),
		IconSize = isMobile and 50 or math.floor(70 * scale),
		IconTextSize = isMobile and 36 or math.floor(48 * scale),

		-- Textos
		NameTextSize = isMobile and 14 or math.floor(18 * scale),
		DescTextSize = isMobile and 11 or math.floor(13 * scale),
		TierTextSize = isMobile and 10 or math.floor(12 * scale),
		PriceTextSize = isMobile and 14 or math.floor(18 * scale),

		-- Botones
		ButtonHeight = isMobile and 32 or math.floor(40 * scale),
		ButtonTextSize = isMobile and 12 or math.floor(16 * scale),

		-- General
		CornerRadius = isMobile and 10 or math.floor(14 * scale),
		StrokeThickness = isMobile and 2 or math.floor(3 * scale),

		IsMobile = isMobile,
	}
end

local sizes = getResponsiveSizes()

-- ============================================
-- ESTILOS
-- ============================================

local Styles = {
	Colors = {
		Background = Color3.fromRGB(25, 25, 35),
		BackgroundLight = Color3.fromRGB(40, 40, 55),
		CardBackground = Color3.fromRGB(35, 35, 50),
		CardHover = Color3.fromRGB(50, 50, 70),
		Text = Color3.fromRGB(255, 255, 255),
		TextMuted = Color3.fromRGB(180, 180, 180),
		TextDark = Color3.fromRGB(50, 50, 60),
		Primary = Color3.fromRGB(255, 200, 50),
		Success = Color3.fromRGB(100, 200, 100),
		RobuxGreen = Color3.fromRGB(0, 180, 80),
		Equipped = Color3.fromRGB(100, 255, 150),
		Owned = Color3.fromRGB(150, 150, 180),
	},

	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
	},
}

-- ============================================
-- ESTADO
-- ============================================

local shopOpen = false
local mainContainer = nil
local cardRefs = {}
local playerData = nil

-- Forward declarations (funciones definidas más abajo)
local createCosmeticCard
local createCosmeticCards
local equipCosmetic
local purchaseCosmetic
local updateAllCards
local toggleShop

-- ============================================
-- HELPERS
-- ============================================

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, sizes.CornerRadius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Styles.Colors.Primary
	stroke.Thickness = thickness or sizes.StrokeThickness
	stroke.Parent = parent
	return stroke
end

local function createGradient(parent, topColor, bottomColor)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	gradient.Rotation = 90
	gradient.Parent = parent
	return gradient
end

-- ============================================
-- CREAR UI PRINCIPAL
-- ============================================

local function createShopUI()
	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CosmeticsShop"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Fondo oscuro
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	-- Contenedor principal
	mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	if sizes.UseScale then
		mainContainer.Size = UDim2.new(sizes.ContainerWidth, 0, sizes.ContainerHeight, 0)
	else
		mainContainer.Size = UDim2.new(0, 1000, 0, 700)
	end
	mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.BackgroundColor3 = Styles.Colors.Background
	mainContainer.Parent = screenGui

	createCorner(mainContainer, UDim.new(0, sizes.CornerRadius + 4))
	createStroke(mainContainer, Styles.Colors.Primary, sizes.StrokeThickness + 1)

	-- Header (usando UIComponentsManager)
	local navbar, titleLabel = UIComponentsManager.createNavbar(mainContainer, {
		height = sizes.HeaderHeight,
		color = Color3.fromRGB(120, 80, 180), -- Púrpura para contrastar con rojo
		cornerRadius = sizes.CornerRadius + 4,
		title = "✨ FART COSMETICS ✨",
		titleSize = sizes.TitleSize,
		titleFont = Styles.Fonts.Title,
	})

	-- Botón cerrar (usando UIComponentsManager)
	local closeButton = UIComponentsManager.createCloseButton(mainContainer, {
		size = sizes.CloseButtonSize,
		onClose = function()
			toggleShop(false)
		end
	})
	closeButton.ZIndex = 10

	-- Área de scroll para cosméticos
	local scrollArea = Instance.new("ScrollingFrame")
	scrollArea.Name = "ScrollArea"
	scrollArea.Size = UDim2.new(1, -20, 1, -(sizes.HeaderHeight + 20))
	scrollArea.Position = UDim2.new(0, 10, 0, sizes.HeaderHeight + 10)
	scrollArea.BackgroundTransparency = 1
	scrollArea.ScrollBarThickness = 6
	scrollArea.ScrollBarImageColor3 = Styles.Colors.Primary
	scrollArea.CanvasSize = UDim2.new(0, 0, 0, 0) -- Se ajusta dinámicamente
	scrollArea.Parent = mainContainer

	-- Grid layout para las cards
	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, sizes.CardSize, 0, sizes.CardSize + 50)
	gridLayout.CellPadding = UDim2.new(0, sizes.CardPadding, 0, sizes.CardPadding)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	gridLayout.Parent = scrollArea

	-- Crear cards de cosméticos
	createCosmeticCards(scrollArea)

	-- Ajustar canvas size
	gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollArea.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
	end)

	-- Click en backdrop para cerrar
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			toggleShop(false)
		end
	end)

	return screenGui
end

-- ============================================
-- CREAR CARDS DE COSMÉTICOS
-- ============================================

createCosmeticCard = function(parent, cosmeticId, cosmeticData, layoutOrder)
	local tierData = Config.CosmeticTiers[cosmeticData.Tier] or Config.CosmeticTiers.common
	local isOwned = playerData and playerData.OwnedCosmetics and playerData.OwnedCosmetics[cosmeticId]
	local isEquipped = playerData and playerData.EquippedCosmetic == cosmeticId
	local isFree = cosmeticData.CostRobux == 0

	local card = Instance.new("Frame")
	card.Name = "Card_" .. cosmeticId
	card.BackgroundTransparency = 1
	card.LayoutOrder = layoutOrder
	card.ClipsDescendants = true -- Necesario para el efecto shine
	card.Parent = parent

	createCorner(card)

	-- Fondo con textura de studs
	local studBackground = Instance.new("ImageLabel")
	studBackground.Name = "StudBackground"
	studBackground.Size = UDim2.new(1, 0, 1, 0)
	studBackground.BackgroundTransparency = 1
	studBackground.Image = TextureManager.Backgrounds.StudGray
	studBackground.ImageColor3 = Styles.Colors.CardBackground
	studBackground.ScaleType = Enum.ScaleType.Tile
	studBackground.TileSize = UDim2.new(0, 60, 0, 60)
	studBackground.ZIndex = 0
	studBackground.Parent = card
	createCorner(studBackground)
	local cardStroke = createStroke(card, tierData.Color, sizes.StrokeThickness)

	-- ========== EFECTO SHINE ==========
	-- Contenedor que recorta el shine
	local shineContainer = Instance.new("Frame")
	shineContainer.Name = "ShineContainer"
	shineContainer.Size = UDim2.new(1, 0, 1, 0)
	shineContainer.BackgroundTransparency = 1
	shineContainer.ClipsDescendants = true
	shineContainer.ZIndex = 2
	shineContainer.Parent = card
	createCorner(shineContainer)

	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(0, 20, 1, 0)
	shine.Position = UDim2.new(-0.1, 0, 0.5, 0)
	shine.AnchorPoint = Vector2.new(0.5, 0.5)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.7
	shine.BorderSizePixel = 0
	shine.Rotation = 15
	shine.Parent = shineContainer

	local shineGradient = Instance.new("UIGradient")
	shineGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.7),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(0.7, 0.7),
		NumberSequenceKeypoint.new(1, 1),
	})
	shineGradient.Parent = shine

	-- Animación del shine
	local shineDelay = 2 + math.random() * 3
	task.spawn(function()
		task.wait(math.random() * 2)
		while shineContainer.Parent do
			shine.Position = UDim2.new(-0.1, 0, 0.5, 0)
			local shineTween = TweenService:Create(shine, TweenInfo.new(0.4, Enum.EasingStyle.Linear), {
				Position = UDim2.new(1.1, 0, 0.5, 0)
			})
			shineTween:Play()
			shineTween.Completed:Wait()
			task.wait(shineDelay)
		end
	end)

	-- Efecto de brillo para tier (opcional)
	if cosmeticData.Tier == "legendary" or cosmeticData.Tier == "mythic" then
		local glow = Instance.new("ImageLabel")
		glow.Name = "Glow"
		glow.Size = UDim2.new(1, 20, 1, 20)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundTransparency = 1
		glow.Image = "rbxassetid://6015897843"
		glow.ImageColor3 = tierData.GlowColor
		glow.ImageTransparency = 0.7
		glow.ScaleType = Enum.ScaleType.Slice
		glow.SliceCenter = Rect.new(49, 49, 450, 450)
		glow.ZIndex = -1
		glow.Parent = card

		-- Animación de pulso para míticos
		if cosmeticData.Tier == "mythic" then
			spawn(function()
				while card.Parent do
					TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						ImageTransparency = 0.5
					}):Play()
					wait(1.5)
					TweenService:Create(glow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
						ImageTransparency = 0.8
					}):Play()
					wait(1.5)
				end
			end)
		end
	end

	-- Badge de tier
	local tierBadge = Instance.new("Frame")
	tierBadge.Name = "TierBadge"
	tierBadge.Size = UDim2.new(0.6, 0, 0, 18)
	tierBadge.Position = UDim2.new(0.5, 0, 0, 6)
	tierBadge.AnchorPoint = Vector2.new(0.5, 0)
	tierBadge.BackgroundColor3 = tierData.Color
	tierBadge.Parent = card
	createCorner(tierBadge, UDim.new(0, 8))

	local tierLabel = Instance.new("TextLabel")
	tierLabel.Size = UDim2.new(1, 0, 1, 0)
	tierLabel.BackgroundTransparency = 1
	tierLabel.Text = tierData.Name:upper()
	tierLabel.TextColor3 = Styles.Colors.TextDark
	tierLabel.TextSize = sizes.TierTextSize
	tierLabel.Font = Styles.Fonts.Body
	tierLabel.Parent = tierBadge

	local tierStroke = Instance.new("UIStroke")
	tierStroke.Color = Color3.fromRGB(0, 0, 0)
	tierStroke.Thickness = 1
	tierStroke.Transparency = 0.5
	tierStroke.Parent = tierLabel

	-- Icono del cosmético
	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(0, sizes.IconSize, 0, sizes.IconSize)
	iconContainer.Position = UDim2.new(0.5, 0, 0, 30)
	iconContainer.AnchorPoint = Vector2.new(0.5, 0)
	iconContainer.BackgroundTransparency = 1
	iconContainer.Parent = card

	-- Preview de colores (círculo con gradiente de los colores del pedo)
	local colorPreview = Instance.new("Frame")
	colorPreview.Name = "ColorPreview"
	colorPreview.Size = UDim2.new(1, 0, 1, 0)
	colorPreview.BackgroundColor3 = cosmeticData.Colors[1] or Color3.new(0.5, 0.5, 0.5)
	colorPreview.Parent = iconContainer
	createCorner(colorPreview, UDim.new(0.5, 0))

	if #cosmeticData.Colors > 1 then
		createGradient(colorPreview, cosmeticData.Colors[1], cosmeticData.Colors[#cosmeticData.Colors])
	end

	-- Icono emoji encima
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = cosmeticData.Icon or "💨"
	iconLabel.TextSize = sizes.IconTextSize
	iconLabel.Parent = iconContainer

	-- ========== EFECTO PULSE EN ICONO ==========
	local pulseDelay = 1.5 + math.random() * 1.5
	local baseFontSize = sizes.IconTextSize
	task.spawn(function()
		task.wait(math.random() * 1.5)
		while iconLabel.Parent do
			TweenService:Create(iconLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				TextSize = baseFontSize * 1.15
			}):Play()
			task.wait(0.3)
			TweenService:Create(iconLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				TextSize = baseFontSize
			}):Play()
			task.wait(0.3)
			task.wait(pulseDelay)
		end
	end)

	-- Nombre
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, -10, 0, 20)
	nameLabel.Position = UDim2.new(0, 5, 0, 30 + sizes.IconSize + 5)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = cosmeticData.Name
	nameLabel.TextColor3 = Styles.Colors.Text
	nameLabel.TextSize = sizes.NameTextSize
	nameLabel.Font = Styles.Fonts.Body
	nameLabel.TextScaled = true
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = card

	local nameConstraint = Instance.new("UITextSizeConstraint")
	nameConstraint.MaxTextSize = sizes.NameTextSize
	nameConstraint.MinTextSize = 10
	nameConstraint.Parent = nameLabel

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2
	nameStroke.Parent = nameLabel

	-- Descripción
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "DescLabel"
	descLabel.Size = UDim2.new(1, -10, 0, 24)
	descLabel.Position = UDim2.new(0, 5, 0, 30 + sizes.IconSize + 25)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = cosmeticData.Description
	descLabel.TextColor3 = Styles.Colors.TextMuted
	descLabel.TextSize = sizes.DescTextSize
	descLabel.Font = Styles.Fonts.Body
	descLabel.TextWrapped = true
	descLabel.TextYAlignment = Enum.TextYAlignment.Top
	descLabel.Parent = card

	local descStroke = Instance.new("UIStroke")
	descStroke.Color = Color3.fromRGB(0, 0, 0)
	descStroke.Thickness = 1
	descStroke.Transparency = 0.3
	descStroke.Parent = descLabel

	-- Botón de acción (comprar/equipar)
	local actionButton = Instance.new("TextButton")
	actionButton.Name = "ActionButton"
	actionButton.Size = UDim2.new(1, -16, 0, sizes.ButtonHeight)
	actionButton.Position = UDim2.new(0.5, 0, 1, -8)
	actionButton.AnchorPoint = Vector2.new(0.5, 1)
	actionButton.Font = Styles.Fonts.Body
	actionButton.TextSize = sizes.ButtonTextSize
	actionButton.Parent = card
	createCorner(actionButton, UDim.new(0, 8))

	local actionStroke = Instance.new("UIStroke")
	actionStroke.Color = Color3.fromRGB(0, 0, 0)
	actionStroke.Thickness = 2
	actionStroke.Parent = actionButton

	-- Frame para contenido de Robux (icono + precio)
	local robuxContent = Instance.new("Frame")
	robuxContent.Name = "RobuxContent"
	robuxContent.Size = UDim2.new(1, 0, 1, 0)
	robuxContent.BackgroundTransparency = 1
	robuxContent.Visible = false
	robuxContent.Parent = actionButton

	local robuxLayout = Instance.new("UIListLayout")
	robuxLayout.FillDirection = Enum.FillDirection.Horizontal
	robuxLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	robuxLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	robuxLayout.Padding = UDim.new(0, 4)
	robuxLayout.Parent = robuxContent

	local robuxIcon = Instance.new("ImageLabel")
	robuxIcon.Name = "RobuxIcon"
	robuxIcon.Size = UDim2.new(0, sizes.ButtonTextSize, 0, sizes.ButtonTextSize)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Image = TextureManager.Icons.Robux
	robuxIcon.ScaleType = Enum.ScaleType.Fit
	robuxIcon.Parent = robuxContent

	local robuxPriceLabel = Instance.new("TextLabel")
	robuxPriceLabel.Name = "PriceLabel"
	robuxPriceLabel.Size = UDim2.new(0, 60, 1, 0)
	robuxPriceLabel.BackgroundTransparency = 1
	robuxPriceLabel.Text = tostring(cosmeticData.CostRobux)
	robuxPriceLabel.TextColor3 = Styles.Colors.Text
	robuxPriceLabel.TextSize = sizes.ButtonTextSize
	robuxPriceLabel.Font = Styles.Fonts.Body
	robuxPriceLabel.Parent = robuxContent

	-- Estado del botón
	local function updateButtonState()
		isOwned = playerData and playerData.OwnedCosmetics and playerData.OwnedCosmetics[cosmeticId]
		isEquipped = playerData and playerData.EquippedCosmetic == cosmeticId

		if isEquipped then
			actionButton.Text = "✓ EQUIPPED"
			actionButton.BackgroundColor3 = Styles.Colors.Equipped
			actionButton.TextColor3 = Styles.Colors.TextDark
			cardStroke.Color = Styles.Colors.Equipped
			robuxContent.Visible = false
		elseif isOwned then
			actionButton.Text = "EQUIP"
			actionButton.BackgroundColor3 = Styles.Colors.Success
			actionButton.TextColor3 = Styles.Colors.Text
			cardStroke.Color = tierData.Color
			robuxContent.Visible = false
		elseif isFree then
			actionButton.Text = "FREE"
			actionButton.BackgroundColor3 = Styles.Colors.Success
			actionButton.TextColor3 = Styles.Colors.Text
			cardStroke.Color = tierData.Color
			robuxContent.Visible = false
		else
			actionButton.Text = ""
			actionButton.BackgroundColor3 = Styles.Colors.RobuxGreen
			cardStroke.Color = tierData.Color
			robuxContent.Visible = true
		end
	end

	updateButtonState()

	-- Click handler
	actionButton.MouseButton1Click:Connect(function()
		if isEquipped then
			-- Ya equipado, no hacer nada
			SoundManager.play("Error", 0.3, 1.0)
			return
		elseif isOwned then
			-- Equipar
			SoundManager.play("Equip", 0.5, 1.0)
			SoundManager.play("Sparkle", 0.3, 1.1)
			equipCosmetic(cosmeticId)
		else
			-- Comprar
			SoundManager.play("ButtonClick", 0.5, 1.0)
			SoundManager.play("CashRegister", 0.3, 1.1)
			purchaseCosmetic(cosmeticId, cosmeticData)
		end
	end)

	-- Hover effect
	card.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.15, 1.1)
		TweenService:Create(card, TweenInfo.new(0.15), {
			BackgroundColor3 = Styles.Colors.CardHover
		}):Play()
	end)

	card.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.15), {
			BackgroundColor3 = Styles.Colors.CardBackground
		}):Play()
	end)

	-- Guardar referencia
	cardRefs[cosmeticId] = {
		Card = card,
		ActionButton = actionButton,
		CardStroke = cardStroke,
		TierData = tierData,
		UpdateState = updateButtonState,
	}

	return card
end

createCosmeticCards = function(parent)
	cardRefs = {}

	for i, cosmeticId in ipairs(Config.CosmeticOrder) do
		local cosmeticData = Config.FartCosmetics[cosmeticId]
		if cosmeticData then
			createCosmeticCard(parent, cosmeticId, cosmeticData, i)
		end
	end
end

-- ============================================
-- FUNCIONES DE COMPRA Y EQUIPAR
-- ============================================

equipCosmetic = function(cosmeticId)
	if not Remotes then return end

	local EquipCosmetic = Remotes:FindFirstChild("EquipCosmetic")
	if EquipCosmetic then
		local success = EquipCosmetic:InvokeServer(cosmeticId)
		if success then
			-- 🔊 Sonido de equipar exitoso
			SoundManager.play("PurchaseSuccess", 0.4, 1.2)
			-- Actualizar UI
			updateAllCards()
		end
	end
end

purchaseCosmetic = function(cosmeticId, cosmeticData)
	if not Remotes then return end

	local PurchaseCosmetic = Remotes:FindFirstChild("PurchaseCosmetic")
	if PurchaseCosmetic then
		local success, message = PurchaseCosmetic:InvokeServer(cosmeticId)
		if success then
			-- Compra iniciada o completada
			print("[CosmeticsShop] Compra:", message)
		else
			warn("[CosmeticsShop] Error:", message)
		end
	end
end

updateAllCards = function()
	for cosmeticId, cardData in pairs(cardRefs) do
		if cardData.UpdateState then
			cardData.UpdateState()
		end
	end
end

-- ============================================
-- ABRIR/CERRAR TIENDA
-- ============================================

toggleShop = function(open)
	local screenGui = playerGui:FindFirstChild("CosmeticsShop")
	if not screenGui then
		screenGui = createShopUI()
	end

	if open == nil then
		open = not shopOpen
	end

	shopOpen = open
	screenGui.Enabled = shopOpen

	if shopOpen then
		-- 🔊 Sonido de apertura
		SoundManager.play("ShopOpen", 0.4, 0.9)
		task.delay(0.15, function()
			SoundManager.play("Sparkle", 0.3, 1.2)
		end)

		-- Animar entrada
		mainContainer.Size = UDim2.new(0, 0, 0, 0)
		local targetSize
		if sizes.UseScale then
			targetSize = UDim2.new(sizes.ContainerWidth, 0, sizes.ContainerHeight, 0)
		else
			targetSize = UDim2.new(0, 1000, 0, 700)
		end

		TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = targetSize
		}):Play()

		-- Actualizar estados de las cards
		updateAllCards()
	else
		-- 🔊 Sonido de cierre
		SoundManager.play("ShopClose", 0.3, 1.3)
	end
end

-- ============================================
-- CONEXIONES
-- ============================================

-- Tecla C para abrir tienda de cosméticos
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.C then
		toggleShop()
	end
end)

-- Datos del jugador
if Remotes then
	local OnDataLoaded = Remotes:FindFirstChild("OnDataLoaded")
	if OnDataLoaded then
		OnDataLoaded.OnClientEvent:Connect(function(data)
			if data and data.Data then
				playerData = data.Data
				updateAllCards()
			end
		end)
	end

	local OnDataUpdated = Remotes:FindFirstChild("OnDataUpdated")
	if OnDataUpdated then
		OnDataUpdated.OnClientEvent:Connect(function(data)
			if data then
				playerData = data
				updateAllCards()
			end
		end)
	end
end

-- Responsive
ResponsiveUI.onViewportChanged(function(info)
	sizes = getResponsiveSizes()
	-- Recrear UI si está abierta
	if shopOpen then
		local screenGui = playerGui:FindFirstChild("CosmeticsShop")
		if screenGui then
			screenGui:Destroy()
		end
		createShopUI().Enabled = true
	end
end)

print("[CosmeticsShop] Presiona 'C' para abrir la tienda de cosméticos")
