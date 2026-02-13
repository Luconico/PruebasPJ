--[[
	PetInventory.client.lua
	UI de inventario de mascotas
	Gestión de mascotas: equipar, desequipar, bloquear, eliminar
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local Config = require(Shared:WaitForChild("Config"))
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))
local RunService = game:GetService("RunService")

-- Carpeta de modelos de mascotas
local PetsFolder = ReplicatedStorage:WaitForChild("Pets", 10)

-- Tamaños responsive
local function getResponsiveSizes()
	local info = ResponsiveUI.getViewportInfo()
	local scale = info.Scale
	local isMobile = info.IsMobile

	return {
		ContainerWidth = isMobile and 0.95 or 0.48,
		ContainerHeight = isMobile and 0.9 or 0.68,
		HeaderHeight = isMobile and 80 or math.floor(100 * scale),
		TitleSize = isMobile and 28 or math.floor(42 * scale),
		CardSize = isMobile and 140 or math.floor(180 * scale),
		CardPadding = isMobile and 10 or math.floor(14 * scale),
		IconSize = isMobile and 60 or math.floor(80 * scale),
		ButtonHeight = isMobile and 35 or math.floor(42 * scale),
		ButtonTextSize = isMobile and 14 or math.floor(18 * scale),
		TextSize = isMobile and 14 or math.floor(18 * scale),
		CornerRadius = isMobile and 12 or math.floor(18 * scale),
		IsMobile = isMobile,
	}
end

local sizes = getResponsiveSizes()

-- Estilos
local Styles = {
	Colors = {
		Background = Color3.fromRGB(25, 25, 45),
		Header = Color3.fromRGB(100, 180, 255),
		Card = Color3.fromRGB(45, 45, 75),
		CardEquipped = Color3.fromRGB(60, 120, 60),
		ButtonEquip = Color3.fromRGB(100, 200, 100),
		ButtonUnequip = Color3.fromRGB(255, 150, 80),
		ButtonLock = Color3.fromRGB(255, 200, 50),
		ButtonDelete = Color3.fromRGB(255, 80, 80),
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(40, 40, 60),
		TextMuted = Color3.fromRGB(180, 180, 200),
	},
	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
	},
}

-- ============================================
-- VIEWPORT FRAME HELPER
-- ============================================

local function createPetViewport(parent, petName, size)
	-- Crear ViewportFrame
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "PetViewport"
	viewport.Size = size or UDim2.new(1, 0, 1, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parent

	-- Buscar modelo de la mascota
	if not PetsFolder then
		warn("[PetInventory] No se encontró carpeta Pets")
		return viewport
	end

	local petModel = PetsFolder:FindFirstChild(petName)
	if not petModel then
		-- Si no hay modelo, mostrar un placeholder
		local placeholder = Instance.new("TextLabel")
		placeholder.Size = UDim2.new(1, 0, 1, 0)
		placeholder.BackgroundTransparency = 1
		placeholder.Text = "?"
		placeholder.TextScaled = true
		placeholder.TextColor3 = Color3.fromRGB(200, 200, 200)
		placeholder.Parent = viewport
		return viewport
	end

	-- Crear WorldModel para contener el modelo
	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	-- Clonar y agregar el modelo
	local clonedPet = petModel:Clone()
	clonedPet.Parent = worldModel

	-- Calcular bounding box del modelo
	local _, size3d = clonedPet:GetBoundingBox()
	local maxSize = math.max(size3d.X, size3d.Y, size3d.Z)

	-- Posicionar modelo en origen
	if clonedPet.PrimaryPart then
		clonedPet:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	else
		clonedPet:MoveTo(Vector3.new(0, 0, 0))
	end

	-- Crear cámara
	local camera = Instance.new("Camera")
	camera.FieldOfView = 50

	-- Posicionar cámara para ver el modelo completo
	local distance = maxSize * 1.8
	camera.CFrame = CFrame.new(Vector3.new(distance * 0.7, distance * 0.3, distance * 0.7), Vector3.new(0, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	-- Animación de rotación suave
	local rotation = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not viewport or not viewport.Parent then
			connection:Disconnect()
			return
		end
		rotation = rotation + dt * 30
		local rad = math.rad(rotation)
		camera.CFrame = CFrame.new(
			Vector3.new(math.cos(rad) * distance * 0.7, distance * 0.3, math.sin(rad) * distance * 0.7),
			Vector3.new(0, 0, 0)
		)
	end)

	return viewport
end

-- Estado
local pets = {}
local inventoryOpen = false

-- ============================================
-- CREAR UI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetInventory"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Backdrop invisible (solo para detectar clicks fuera del menú)
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundTransparency = 1
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.Parent = screenGui

-- Main container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.Size = UDim2.new(sizes.ContainerWidth, 0, sizes.ContainerHeight, 0)
mainContainer.BackgroundColor3 = Styles.Colors.Background
mainContainer.BorderSizePixel = 0
mainContainer.Parent = backdrop

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
mainCorner.Parent = mainContainer

-- Header (usando UIComponentsManager)
local navbar, titleLabel, statsLabel = UIComponentsManager.createNavbar(mainContainer, {
	height = sizes.HeaderHeight,
	color = Styles.Colors.Header,
	cornerRadius = sizes.CornerRadius,
	title = "🐾 PET INVENTORY 🐾",
	titleSize = sizes.TitleSize,
	titleFont = Styles.Fonts.Title,
	rightText = "0/50 | 0/3 equipped",
	rightTextSize = sizes.TextSize,
	rightTextFont = Styles.Fonts.Body,
})

-- Close button (usando UIComponentsManager)
local closeButton = UIComponentsManager.createCloseButton(mainContainer, {
	size = 52,
	onClose = function()
		SoundManager.playClose()
		backdrop.Visible = false
		inventoryOpen = false
	end
})
closeButton.ZIndex = 10

-- Footer height for slot boxes
local FOOTER_HEIGHT = 90

-- Content container (adjusted for footer)
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Name = "ContentContainer"
contentContainer.Position = UDim2.new(0, 0, 0, sizes.HeaderHeight)
contentContainer.Size = UDim2.new(1, 0, 1, -sizes.HeaderHeight - FOOTER_HEIGHT)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.ScrollBarThickness = 8
contentContainer.Parent = mainContainer

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.PaddingLeft = UDim.new(0, 20)
contentPadding.PaddingRight = UDim.new(0, 20)
contentPadding.Parent = contentContainer

local contentLayout = Instance.new("UIGridLayout")
contentLayout.CellSize = UDim2.new(0, sizes.CardSize, 0, sizes.CardSize + 90) -- +90 para boosts mas grandes
contentLayout.CellPadding = UDim2.new(0, sizes.CardPadding, 0, sizes.CardPadding)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentContainer

-- ============================================
-- FOOTER CON SLOTS (INVENTARIO + EQUIP)
-- ============================================

local footer = Instance.new("Frame")
footer.Name = "Footer"
footer.Size = UDim2.new(1, 0, 0, FOOTER_HEIGHT)
footer.Position = UDim2.new(0, 0, 1, -FOOTER_HEIGHT)
footer.BackgroundTransparency = 1
footer.Parent = mainContainer

local footerPadding = Instance.new("UIPadding")
footerPadding.PaddingLeft = UDim.new(0, 20)
footerPadding.PaddingRight = UDim.new(0, 20)
footerPadding.PaddingTop = UDim.new(0, 10)
footerPadding.PaddingBottom = UDim.new(0, 10)
footerPadding.Parent = footer

local footerLayout = Instance.new("UIListLayout")
footerLayout.FillDirection = Enum.FillDirection.Horizontal
footerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
footerLayout.Padding = UDim.new(0, 20)
footerLayout.Parent = footer

-- Variables para actualizar dinámicamente
local inventorySlotsLabel = nil
local equipSlotsLabel = nil

-- Función para crear un cuadro de slot
local function createSlotBox(parent, slotType, icon, color, currentSlots, maxSlots, robuxCost)
	local box = Instance.new("Frame")
	box.Name = slotType .. "SlotBox"
	box.Size = UDim2.new(0.45, 0, 1, 0)
	box.BackgroundTransparency = 1
	box.Parent = parent

	-- Fondo con studs
	local studBg = Instance.new("ImageLabel")
	studBg.Name = "StudBackground"
	studBg.Size = UDim2.new(1, 0, 1, 0)
	studBg.BackgroundTransparency = 1
	studBg.Image = TextureManager.Backgrounds.StudGray
	studBg.ImageColor3 = color
	studBg.ScaleType = Enum.ScaleType.Tile
	studBg.TileSize = UDim2.new(0, 40, 0, 40)
	studBg.Parent = box

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, 12)
	bgCorner.Parent = studBg

	local boxStroke = Instance.new("UIStroke")
	boxStroke.Color = color
	boxStroke.Thickness = 3
	boxStroke.Parent = box

	local boxCorner = Instance.new("UICorner")
	boxCorner.CornerRadius = UDim.new(0, 12)
	boxCorner.Parent = box

	-- Contenido del box (icono + texto + contador)
	local contentFrame = Instance.new("Frame")
	contentFrame.Size = UDim2.new(1, -60, 1, 0)
	contentFrame.Position = UDim2.new(0, 10, 0, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.Parent = box

	-- Icono
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.new(0, 35, 0, 35)
	iconLabel.Position = UDim2.new(0, 0, 0.5, 0)
	iconLabel.AnchorPoint = Vector2.new(0, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon
	iconLabel.TextSize = 28
	iconLabel.Parent = contentFrame

	-- Texto descriptivo
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 20)
	titleLabel.Position = UDim2.new(0, 40, 0, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = slotType == "Inventory" and "Inventory" or "Following"
	titleLabel.TextColor3 = Styles.Colors.Text
	titleLabel.TextSize = 14
	titleLabel.Font = Styles.Fonts.Body
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = contentFrame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.5
	titleStroke.Parent = titleLabel

	-- Contador de slots
	local slotsLabel = Instance.new("TextLabel")
	slotsLabel.Name = "SlotsLabel"
	slotsLabel.Size = UDim2.new(1, -40, 0, 24)
	slotsLabel.Position = UDim2.new(0, 40, 0, 28)
	slotsLabel.BackgroundTransparency = 1
	slotsLabel.Text = currentSlots .. "/" .. maxSlots
	slotsLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	slotsLabel.TextSize = 20
	slotsLabel.Font = Styles.Fonts.Title
	slotsLabel.TextXAlignment = Enum.TextXAlignment.Left
	slotsLabel.Parent = contentFrame

	local slotsStroke = Instance.new("UIStroke")
	slotsStroke.Color = Color3.fromRGB(0, 0, 0)
	slotsStroke.Thickness = 2
	slotsStroke.Parent = slotsLabel

	-- Botón "+" para comprar más
	local plusButton = Instance.new("TextButton")
	plusButton.Name = "PlusButton"
	plusButton.Size = UDim2.new(0, 45, 0, 45)
	plusButton.Position = UDim2.new(1, -50, 0.5, 0)
	plusButton.AnchorPoint = Vector2.new(0, 0.5)
	plusButton.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
	plusButton.Text = "+"
	plusButton.TextColor3 = Styles.Colors.Text
	plusButton.TextSize = 32
	plusButton.Font = Styles.Fonts.Title
	plusButton.Parent = box

	local plusCorner = Instance.new("UICorner")
	plusCorner.CornerRadius = UDim.new(0, 10)
	plusCorner.Parent = plusButton

	local plusStroke = Instance.new("UIStroke")
	plusStroke.Color = Color3.fromRGB(0, 0, 0)
	plusStroke.Thickness = 3
	plusStroke.Parent = plusButton

	-- Efecto hover
	plusButton.MouseEnter:Connect(function()
		TweenService:Create(plusButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(100, 255, 100),
			Size = UDim2.new(0, 50, 0, 50)
		}):Play()
	end)

	plusButton.MouseLeave:Connect(function()
		TweenService:Create(plusButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(80, 200, 80),
			Size = UDim2.new(0, 45, 0, 45)
		}):Play()
	end)

	-- Click para abrir diálogo de compra
	plusButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.3, 1.0)
		showPurchaseDialog(slotType, robuxCost)
	end)

	return slotsLabel
end

-- Función para mostrar diálogo de compra
local purchaseDialog = nil

function showPurchaseDialog(slotType, robuxCost)
	-- Cerrar diálogo existente si hay uno
	if purchaseDialog then
		purchaseDialog:Destroy()
	end

	local isInventory = slotType == "Inventory"
	local slotsPerPurchase = isInventory
		and (Config.PetSystem.SlotPurchases and Config.PetSystem.SlotPurchases.InventorySlots.SlotsPerPurchase or 10)
		or (Config.PetSystem.SlotPurchases and Config.PetSystem.SlotPurchases.EquipSlots.SlotsPerPurchase or 1)
	local title = isInventory and "Buy Inventory Slots" or "Buy Pet Slots"
	local description = isInventory and ("+" .. slotsPerPurchase .. " Inventory Slots") or ("+" .. slotsPerPurchase .. " Pet Following Slot")
	local icon = isInventory and "📦" or "🐾"
	local color = isInventory and Color3.fromRGB(100, 150, 255) or Color3.fromRGB(255, 150, 100)

	-- Crear diálogo
	purchaseDialog = Instance.new("Frame")
	purchaseDialog.Name = "PurchaseDialog"
	purchaseDialog.Size = UDim2.new(0, 320, 0, 220)
	purchaseDialog.Position = UDim2.new(0.5, 0, 0.5, 0)
	purchaseDialog.AnchorPoint = Vector2.new(0.5, 0.5)
	purchaseDialog.BackgroundColor3 = Styles.Colors.Background
	purchaseDialog.ZIndex = 100
	purchaseDialog.Parent = screenGui

	local dialogCorner = Instance.new("UICorner")
	dialogCorner.CornerRadius = UDim.new(0, 16)
	dialogCorner.Parent = purchaseDialog

	local dialogStroke = Instance.new("UIStroke")
	dialogStroke.Color = color
	dialogStroke.Thickness = 4
	dialogStroke.Parent = purchaseDialog

	-- Fondo con studs
	local dialogBg = Instance.new("ImageLabel")
	dialogBg.Size = UDim2.new(1, 0, 1, 0)
	dialogBg.BackgroundTransparency = 1
	dialogBg.Image = TextureManager.Backgrounds.StudGray
	dialogBg.ImageColor3 = Styles.Colors.Background
	dialogBg.ImageTransparency = 0.5
	dialogBg.ScaleType = Enum.ScaleType.Tile
	dialogBg.TileSize = UDim2.new(0, 40, 0, 40)
	dialogBg.ZIndex = 100
	dialogBg.Parent = purchaseDialog

	local dialogBgCorner = Instance.new("UICorner")
	dialogBgCorner.CornerRadius = UDim.new(0, 16)
	dialogBgCorner.Parent = dialogBg

	-- Título
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, 0, 0, 40)
	titleLabel.Position = UDim2.new(0, 0, 0, 15)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = icon .. " " .. title
	titleLabel.TextColor3 = Styles.Colors.Text
	titleLabel.TextSize = 24
	titleLabel.Font = Styles.Fonts.Title
	titleLabel.ZIndex = 101
	titleLabel.Parent = purchaseDialog

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 2
	titleStroke.Parent = titleLabel

	-- Descripción
	local descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -20, 0, 30)
	descLabel.Position = UDim2.new(0.5, 0, 0, 60)
	descLabel.AnchorPoint = Vector2.new(0.5, 0)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
	descLabel.TextSize = 20
	descLabel.Font = Styles.Fonts.Body
	descLabel.ZIndex = 101
	descLabel.Parent = purchaseDialog

	local descStroke = Instance.new("UIStroke")
	descStroke.Color = Color3.fromRGB(0, 0, 0)
	descStroke.Thickness = 1.5
	descStroke.Parent = descLabel

	-- Precio con icono de Robux
	local priceContainer = Instance.new("Frame")
	priceContainer.Size = UDim2.new(1, 0, 0, 35)
	priceContainer.Position = UDim2.new(0.5, 0, 0, 95)
	priceContainer.AnchorPoint = Vector2.new(0.5, 0)
	priceContainer.BackgroundTransparency = 1
	priceContainer.ZIndex = 101
	priceContainer.Parent = purchaseDialog

	local priceLayout = Instance.new("UIListLayout")
	priceLayout.FillDirection = Enum.FillDirection.Horizontal
	priceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	priceLayout.Padding = UDim.new(0, 8)
	priceLayout.Parent = priceContainer

	local robuxIcon = Instance.new("ImageLabel")
	robuxIcon.Size = UDim2.new(0, 28, 0, 28)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Image = "rbxassetid://4458901886" -- Robux icon
	robuxIcon.ZIndex = 101
	robuxIcon.LayoutOrder = 1
	robuxIcon.Parent = priceContainer

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Size = UDim2.new(0, 80, 0, 30)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = tostring(robuxCost)
	priceLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	priceLabel.TextSize = 26
	priceLabel.Font = Styles.Fonts.Title
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.ZIndex = 101
	priceLabel.LayoutOrder = 2
	priceLabel.Parent = priceContainer

	local priceStroke = Instance.new("UIStroke")
	priceStroke.Color = Color3.fromRGB(0, 0, 0)
	priceStroke.Thickness = 2
	priceStroke.Parent = priceLabel

	-- Botones
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Size = UDim2.new(1, -40, 0, 45)
	buttonsContainer.Position = UDim2.new(0.5, 0, 1, -60)
	buttonsContainer.AnchorPoint = Vector2.new(0.5, 0)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.ZIndex = 101
	buttonsContainer.Parent = purchaseDialog

	local buttonsLayout = Instance.new("UIListLayout")
	buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonsLayout.Padding = UDim.new(0, 15)
	buttonsLayout.Parent = buttonsContainer

	-- Botón Cancelar
	local cancelButton = Instance.new("TextButton")
	cancelButton.Size = UDim2.new(0, 120, 0, 42)
	cancelButton.BackgroundColor3 = Color3.fromRGB(150, 80, 80)
	cancelButton.Text = "Cancel"
	cancelButton.TextColor3 = Styles.Colors.Text
	cancelButton.TextSize = 18
	cancelButton.Font = Styles.Fonts.Body
	cancelButton.ZIndex = 101
	cancelButton.LayoutOrder = 1
	cancelButton.Parent = buttonsContainer

	local cancelCorner = Instance.new("UICorner")
	cancelCorner.CornerRadius = UDim.new(0, 10)
	cancelCorner.Parent = cancelButton

	local cancelStroke = Instance.new("UIStroke")
	cancelStroke.Color = Color3.fromRGB(0, 0, 0)
	cancelStroke.Thickness = 2
	cancelStroke.Parent = cancelButton

	-- Botón Comprar
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(0, 120, 0, 42)
	buyButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
	buyButton.Text = "Buy"
	buyButton.TextColor3 = Styles.Colors.Text
	buyButton.TextSize = 18
	buyButton.Font = Styles.Fonts.Body
	buyButton.ZIndex = 101
	buyButton.LayoutOrder = 2
	buyButton.Parent = buttonsContainer

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 10)
	buyCorner.Parent = buyButton

	local buyStroke = Instance.new("UIStroke")
	buyStroke.Color = Color3.fromRGB(0, 0, 0)
	buyStroke.Thickness = 2
	buyStroke.Parent = buyButton

	-- Animación de entrada
	purchaseDialog.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(purchaseDialog, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 320, 0, 220)
	}):Play()

	-- Eventos
	cancelButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.3, 1.2)
		TweenService:Create(purchaseDialog, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.wait(0.25)
		if purchaseDialog then
			purchaseDialog:Destroy()
			purchaseDialog = nil
		end
	end)

	buyButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.3, 1.0)
		-- Llamar al servidor para procesar la compra
		local remoteName = isInventory and "BuyInventorySlots" or "BuyEquipSlots"
		local success, result = pcall(function()
			return Remotes[remoteName]:InvokeServer()
		end)

		if success and result then
			SoundManager.play("Sparkle", 0.5, 1.2)
			-- Actualizar UI
			updateInventory()
		else
			warn("[PetInventory] Error al comprar slots:", result)
		end

		-- Cerrar diálogo
		TweenService:Create(purchaseDialog, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()
		task.wait(0.25)
		if purchaseDialog then
			purchaseDialog:Destroy()
			purchaseDialog = nil
		end
	end)
end

-- Crear los dos cuadros de slots (precios desde Config)
local inventoryPrice = Config.PetSystem.SlotPurchases and Config.PetSystem.SlotPurchases.InventorySlots.RobuxCost or 49
local equipPrice = Config.PetSystem.SlotPurchases and Config.PetSystem.SlotPurchases.EquipSlots.RobuxCost or 99
inventorySlotsLabel = createSlotBox(footer, "Inventory", "📦", Color3.fromRGB(100, 150, 255), 0, 50, inventoryPrice)
equipSlotsLabel = createSlotBox(footer, "Equip", "🐾", Color3.fromRGB(255, 150, 100), 0, 3, equipPrice)

-- ============================================
-- CREAR TARJETA DE MASCOTA
-- ============================================

local function createPetCard(pet)
	local petConfig = Config.Pets[pet.PetName]
	if not petConfig then return end

	local card = Instance.new("Frame")
	card.Name = pet.UUID
	card.BackgroundTransparency = 1
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = contentContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
	cardCorner.Parent = card

	-- Fondo con textura de studs
	local studBackground = Instance.new("ImageLabel")
	studBackground.Name = "StudBackground"
	studBackground.Size = UDim2.new(1, 0, 1, 0)
	studBackground.BackgroundTransparency = 1
	studBackground.Image = TextureManager.Backgrounds.StudGray
	studBackground.ImageColor3 = pet.Equiped and Styles.Colors.CardEquipped or Styles.Colors.Card
	studBackground.ScaleType = Enum.ScaleType.Tile
	studBackground.TileSize = UDim2.new(0, 50, 0, 50)
	studBackground.ZIndex = 0
	studBackground.Parent = card

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
	bgCorner.Parent = studBackground

	-- UIStroke del card
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Name = "CardStroke"
	cardStroke.Color = pet.Equiped and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(100, 180, 255)
	cardStroke.Thickness = 3
	cardStroke.Parent = card

	-- ViewportFrame con modelo 3D de la mascota
	local viewportContainer = Instance.new("Frame")
	viewportContainer.Name = "ViewportContainer"
	viewportContainer.Size = UDim2.new(0, sizes.IconSize, 0, sizes.IconSize)
	viewportContainer.Position = UDim2.new(0.5, 0, 0, 10)
	viewportContainer.AnchorPoint = Vector2.new(0.5, 0)
	viewportContainer.BackgroundTransparency = 1
	viewportContainer.Parent = card

	createPetViewport(viewportContainer, pet.PetName, UDim2.new(1, 0, 1, 0))

	-- Nombre
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -10, 0, 22)
	name.Position = UDim2.new(0.5, 0, 0, sizes.IconSize + 12)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.BackgroundTransparency = 1
	name.Text = petConfig.Name
	name.Font = Styles.Fonts.Body
	name.TextSize = sizes.TextSize
	name.TextColor3 = Styles.Colors.Text
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = card

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2
	nameStroke.Parent = name

	-- Rareza
	local rarityConfig = Config.PetRarities[petConfig.Rarity]
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Size = UDim2.new(1, -10, 0, 16)
	rarityLabel.Position = UDim2.new(0.5, 0, 0, sizes.IconSize + 32)
	rarityLabel.AnchorPoint = Vector2.new(0.5, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = petConfig.Rarity
	rarityLabel.Font = Styles.Fonts.Body
	rarityLabel.TextSize = sizes.TextSize - 4
	rarityLabel.TextColor3 = rarityConfig and rarityConfig.Color or Color3.fromRGB(180, 180, 180)
	rarityLabel.Parent = card

	local rarityStroke = Instance.new("UIStroke")
	rarityStroke.Color = Color3.fromRGB(0, 0, 0)
	rarityStroke.Thickness = 1.5
	rarityStroke.Parent = rarityLabel

	-- Boosts container (para múltiples boosts)
	local boostsContainer = Instance.new("Frame")
	boostsContainer.Name = "BoostsContainer"
	boostsContainer.Size = UDim2.new(1, -6, 0, 50)
	boostsContainer.Position = UDim2.new(0.5, 0, 0, sizes.IconSize + 48)
	boostsContainer.AnchorPoint = Vector2.new(0.5, 0)
	boostsContainer.BackgroundTransparency = 1
	boostsContainer.Parent = card

	-- Obtener boosts de la mascota
	local boostsToShow = {}
	if petConfig.Boosts then
		for boostType, value in pairs(petConfig.Boosts) do
			local boostInfo = Config.PetBoostTypes[boostType]
			if boostInfo then
				table.insert(boostsToShow, {
					Type = boostType,
					Value = value,
					Icon = boostInfo.Icon,
					Color = boostInfo.Color,
					Name = boostInfo.Name,
				})
			end
		end
	elseif petConfig.Boost then
		-- Compatibilidad con estructura antigua
		table.insert(boostsToShow, {
			Type = "CoinBoost",
			Value = petConfig.Boost,
			Icon = "💰",
			Color = Color3.fromRGB(255, 220, 50),
			Name = "Coins",
		})
	end

	-- Crear texto de boosts (formato compacto)
	local boostTexts = {}
	for _, b in ipairs(boostsToShow) do
		table.insert(boostTexts, b.Icon .. "+" .. math.floor(b.Value * 100) .. "%")
	end

	-- Si hay muchos boosts, mostrar en 2 lineas
	local boostText1 = ""
	local boostText2 = ""
	if #boostTexts <= 2 then
		boostText1 = table.concat(boostTexts, "  ")
	else
		-- Primera linea: primeros 2-3 boosts
		local mid = math.ceil(#boostTexts / 2)
		for i = 1, mid do
			boostText1 = boostText1 .. (i > 1 and "  " or "") .. boostTexts[i]
		end
		for i = mid + 1, #boostTexts do
			boostText2 = boostText2 .. (i > mid + 1 and "  " or "") .. boostTexts[i]
		end
	end

	local boost1 = Instance.new("TextLabel")
	boost1.Size = UDim2.new(1, 0, 0, 24)
	boost1.Position = UDim2.new(0, 0, 0, 0)
	boost1.BackgroundTransparency = 1
	boost1.Text = boostText1
	boost1.Font = Styles.Fonts.Body
	boost1.TextSize = sizes.TextSize + 2
	boost1.TextColor3 = Color3.fromRGB(100, 255, 100)
	boost1.Parent = boostsContainer

	local boost1Stroke = Instance.new("UIStroke")
	boost1Stroke.Color = Color3.fromRGB(0, 0, 0)
	boost1Stroke.Thickness = 2.5
	boost1Stroke.Parent = boost1

	if boostText2 ~= "" then
		local boost2 = Instance.new("TextLabel")
		boost2.Size = UDim2.new(1, 0, 0, 24)
		boost2.Position = UDim2.new(0, 0, 0, 22)
		boost2.BackgroundTransparency = 1
		boost2.Text = boostText2
		boost2.Font = Styles.Fonts.Body
		boost2.TextSize = sizes.TextSize + 2
		boost2.TextColor3 = Color3.fromRGB(100, 255, 100)
		boost2.Parent = boostsContainer

		local boost2Stroke = Instance.new("UIStroke")
		boost2Stroke.Color = Color3.fromRGB(0, 0, 0)
		boost2Stroke.Thickness = 2.5
		boost2Stroke.Parent = boost2
	end

	-- Botones container
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Size = UDim2.new(1, -20, 0, sizes.ButtonHeight)
	buttonsContainer.Position = UDim2.new(0.5, 0, 1, -sizes.ButtonHeight - 10)
	buttonsContainer.AnchorPoint = Vector2.new(0.5, 0)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = card

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.Padding = UDim.new(0, 5)
	buttonLayout.Parent = buttonsContainer

	-- Botón Equip/Unequip
	local equipButton = Instance.new("TextButton")
	equipButton.Size = UDim2.new(0.55, 0, 1, 0)
	equipButton.BackgroundColor3 = pet.Equiped and Styles.Colors.ButtonUnequip or Styles.Colors.ButtonEquip
	equipButton.Text = pet.Equiped and "Unequip" or "Equip"
	equipButton.Font = Styles.Fonts.Body
	equipButton.TextSize = sizes.ButtonTextSize
	equipButton.TextColor3 = Styles.Colors.Text
	equipButton.Parent = buttonsContainer

	local equipCorner = Instance.new("UICorner")
	equipCorner.CornerRadius = UDim.new(0, sizes.CornerRadius * 0.7)
	equipCorner.Parent = equipButton

	local equipStroke = Instance.new("UIStroke")
	equipStroke.Color = Color3.fromRGB(0, 0, 0)
	equipStroke.Thickness = 2
	equipStroke.Parent = equipButton

	equipButton.MouseButton1Click:Connect(function()
		local remoteName = pet.Equiped and "UnequipPet" or "EquipPet"
		local success, result = pcall(function()
			return Remotes[remoteName]:InvokeServer(pet.UUID)
		end)

		if not success then
			warn("[PetInventory] Error:", result)
		end
		-- La UI se actualiza automáticamente via OnDataUpdated
	end)

	-- Botón Lock
	local lockButton = Instance.new("TextButton")
	lockButton.Size = UDim2.new(0.20, 0, 1, 0)
	lockButton.BackgroundColor3 = pet.Locked and Styles.Colors.ButtonLock or Color3.fromRGB(100, 100, 120)
	lockButton.Text = pet.Locked and "🔒" or "🔓"
	lockButton.Font = Styles.Fonts.Body
	lockButton.TextSize = sizes.ButtonTextSize
	lockButton.Parent = buttonsContainer

	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, sizes.CornerRadius * 0.7)
	lockCorner.Parent = lockButton

	local lockStroke = Instance.new("UIStroke")
	lockStroke.Color = Color3.fromRGB(0, 0, 0)
	lockStroke.Thickness = 2
	lockStroke.Parent = lockButton

	lockButton.MouseButton1Click:Connect(function()
		local success = pcall(function()
			return Remotes.LockPet:InvokeServer(pet.UUID)
		end)
		-- La UI se actualiza automáticamente via OnDataUpdated
	end)

	-- Botón Delete
	local deleteButton = Instance.new("TextButton")
	deleteButton.Size = UDim2.new(0.20, 0, 1, 0)
	deleteButton.BackgroundColor3 = Styles.Colors.ButtonDelete
	deleteButton.Text = "🗑️"
	deleteButton.Font = Styles.Fonts.Body
	deleteButton.TextSize = sizes.ButtonTextSize
	deleteButton.Parent = buttonsContainer

	local deleteCorner = Instance.new("UICorner")
	deleteCorner.CornerRadius = UDim.new(0, sizes.CornerRadius * 0.7)
	deleteCorner.Parent = deleteButton

	local deleteStroke = Instance.new("UIStroke")
	deleteStroke.Color = Color3.fromRGB(0, 0, 0)
	deleteStroke.Thickness = 2
	deleteStroke.Parent = deleteButton

	deleteButton.MouseButton1Click:Connect(function()
		if pet.Locked then
			warn("[PetInventory] Mascota bloqueada")
			return
		end

		local success = pcall(function()
			return Remotes.DeletePet:InvokeServer(pet.UUID)
		end)
		-- La UI se actualiza automáticamente via OnDataUpdated
	end)
end

-- ============================================
-- ACTUALIZAR INVENTARIO
-- ============================================

function updateInventory()
	-- Limpiar tarjetas existentes (ignorar UIPadding y UIGridLayout)
	for _, child in ipairs(contentContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UIPadding" and child.Name ~= "UIGridLayout" then
			child:Destroy()
		end
	end

	-- Obtener mascotas del servidor
	local success, result = pcall(function()
		return Remotes.GetPets:InvokeServer()
	end)

	if success then
		pets = result or {}
	end

	-- Obtener stats
	local statsSuccess, stats = pcall(function()
		return Remotes.GetPetStats:InvokeServer()
	end)

	if statsSuccess and stats then
		statsLabel.Text = stats.TotalPets .. "/" .. stats.InventorySlots .. " | " .. stats.EquippedPets .. "/" .. stats.EquipSlots .. " equipped"

		-- Actualizar labels del footer
		if inventorySlotsLabel then
			inventorySlotsLabel.Text = stats.TotalPets .. "/" .. stats.InventorySlots
		end
		if equipSlotsLabel then
			equipSlotsLabel.Text = stats.EquippedPets .. "/" .. stats.EquipSlots
		end
	end

	-- Crear tarjetas
	for _, pet in ipairs(pets) do
		createPetCard(pet)
	end

	-- Actualizar CanvasSize
	contentContainer.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 40)
end

-- ============================================
-- ABRIR/CERRAR INVENTARIO
-- ============================================

local function openInventory()
	if inventoryOpen then return end
	inventoryOpen = true

	-- Sonido de apertura
	SoundManager.play("ShopOpen", 0.4, 0.9)
	task.delay(0.15, function()
		SoundManager.play("Sparkle", 0.3, 1.2)
	end)

	-- Preparar animación de entrada
	mainContainer.Size = UDim2.new(0, 0, 0, 0)
	mainContainer.BackgroundTransparency = 1
	backdrop.Visible = true

	-- Animación de entrada (colapso inverso)
	local targetSize = UDim2.new(sizes.ContainerWidth, 0, sizes.ContainerHeight, 0)
	TweenService:Create(mainContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = targetSize,
		BackgroundTransparency = 0
	}):Play()

	updateInventory()
end

local function closeInventory()
	if not inventoryOpen then return end

	-- Sonido de cierre
	SoundManager.play("ShopClose", 0.3, 1.3)

	-- Animación de salida (colapso)
	local tween = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1
	})
	tween:Play()
	tween.Completed:Wait()

	backdrop.Visible = false
	inventoryOpen = false
end

-- Actualizar cuando cambien los datos
Remotes.OnDataUpdated.OnClientEvent:Connect(function(newData)
	if inventoryOpen then
		updateInventory()
	end
end)

-- Escuchar BindableEvent del menú lateral
local function setupUIEvents(events)
	local toggleEvent = events:FindFirstChild("TogglePetInventory")
	if toggleEvent then
		toggleEvent.Event:Connect(function()
			if inventoryOpen then
				closeInventory()
			else
				openInventory()
			end
		end)
	end

	-- Escuchar evento de cierre (para exclusividad de menús)
	local closeEvent = events:FindFirstChild("ClosePetInventory")
	if closeEvent then
		closeEvent.Event:Connect(function()
			if inventoryOpen then
				closeInventory()
			end
		end)
	end
end

-- UIEvents vive dentro de UIEventsGui (ScreenGui con ResetOnSpawn=false)
local eventsGui = playerGui:FindFirstChild("UIEventsGui")
if eventsGui then
	local UIEvents = eventsGui:FindFirstChild("UIEvents")
	if UIEvents then
		setupUIEvents(UIEvents)
	end
else
	-- Esperar a que se cree UIEventsGui (si LeftMenu se carga después)
	task.spawn(function()
		local gui = playerGui:WaitForChild("UIEventsGui", 5)
		if gui then
			local events = gui:WaitForChild("UIEvents", 5)
			if events then
				setupUIEvents(events)
			end
		end
	end)
end

print("[PetInventory] Inventario de mascotas inicializado")
