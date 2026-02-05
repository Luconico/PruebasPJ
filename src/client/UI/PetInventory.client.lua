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

-- Content container
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Name = "ContentContainer"
contentContainer.Position = UDim2.new(0, 0, 0, sizes.HeaderHeight)
contentContainer.Size = UDim2.new(1, 0, 1, -sizes.HeaderHeight)
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

	if statsSuccess then
		statsLabel.Text = stats.TotalPets .. "/" .. stats.InventorySlots .. " | " .. stats.EquippedPets .. "/" .. stats.EquipSlots .. " equipped"
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

local UIEvents = playerGui:FindFirstChild("UIEvents")
if UIEvents then
	setupUIEvents(UIEvents)
else
	-- Esperar a que se cree UIEvents (si LeftMenu se carga después)
	task.spawn(function()
		local events = playerGui:WaitForChild("UIEvents", 5)
		if events then
			setupUIEvents(events)
		end
	end)
end

print("[PetInventory] Inventario de mascotas inicializado")
