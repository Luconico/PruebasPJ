--[[
	EggShop.client.lua
	Sistema de huevos con BillboardGui clickeable
	Estilo cartoon con texturas stud y un solo botón de abrir
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local Config = require(Shared:WaitForChild("Config"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))

-- Carpeta de modelos de mascotas y huevos
local PetsFolder = ReplicatedStorage:WaitForChild("Pets", 10)
local EggsFolder = ReplicatedStorage:WaitForChild("Eggs", 10)

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
		warn("[EggShop] No se encontró carpeta Pets")
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

-- ============================================
-- CONFIGURACIÓN
-- ============================================

local PROXIMITY_DISTANCE = 12
local EGG_PART_PREFIX = "Egg_"

-- Estilos Cartoon
local Styles = {
	Colors = {
		Background = Color3.fromRGB(45, 45, 75),
		Header = Color3.fromRGB(255, 200, 100),
		HeaderDark = Color3.fromRGB(200, 150, 50),
		ButtonCoin = Color3.fromRGB(255, 220, 80),
		ButtonRobux = Color3.fromRGB(80, 220, 120),
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(40, 40, 60),
		CardBg = Color3.fromRGB(60, 60, 90),
	},
	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
	},
}

local RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 220, 100),
	Rare = Color3.fromRGB(100, 180, 255),
	Epic = Color3.fromRGB(220, 120, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
}

-- ============================================
-- VIEWPORT PARA HUEVO 3D (Animación de apertura)
-- ============================================

local function createEggViewport(parent, eggIndex, size)
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "EggViewport"
	viewport.Size = size or UDim2.new(1, 0, 1, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = parent

	if not EggsFolder then
		warn("[EggShop] No se encontró carpeta Eggs")
		return viewport, nil, nil
	end

	-- Buscar el modelo del huevo (Egg1, Egg2, etc.)
	local eggModelName = "Egg" .. tostring(eggIndex)
	local eggModel = EggsFolder:FindFirstChild(eggModelName)

	if not eggModel then
		-- Fallback al primer huevo disponible
		eggModel = EggsFolder:FindFirstChildWhichIsA("Model") or EggsFolder:FindFirstChild("Egg1")
		if not eggModel then
			warn("[EggShop] No se encontró modelo de huevo:", eggModelName)
			return viewport, nil, nil
		end
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = viewport

	local clonedEgg = eggModel:Clone()
	clonedEgg.Parent = worldModel

	-- Calcular bounding box
	local _, size3d = clonedEgg:GetBoundingBox()
	local maxSize = math.max(size3d.X, size3d.Y, size3d.Z)

	-- Posicionar en origen
	if clonedEgg.PrimaryPart then
		clonedEgg:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
	else
		clonedEgg:MoveTo(Vector3.new(0, 0, 0))
	end

	-- Cámara
	local camera = Instance.new("Camera")
	camera.FieldOfView = 50
	local distance = maxSize * 2.2
	camera.CFrame = CFrame.new(Vector3.new(0, distance * 0.2, distance), Vector3.new(0, 0, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	return viewport, clonedEgg, camera
end

-- ============================================
-- ANIMACIÓN DE APERTURA DE HUEVO
-- ============================================

-- Mapeo de tipo de huevo a índice de modelo
local EggModelMapping = {
	BasicEgg = 1,
	PremiumEgg = 5,
	RobuxEgg = 10,
}

local isAnimationPlaying = false

local function playEggOpenAnimation(eggName, petName)
	if isAnimationPlaying then return end
	isAnimationPlaying = true

	local petConfig = Config.Pets[petName]
	if not petConfig then
		warn("[EggShop] No se encontró config de mascota:", petName)
		isAnimationPlaying = false
		return
	end

	local rarityColor = RarityColors[petConfig.Rarity] or RarityColors.Common
	local eggIndex = EggModelMapping[eggName] or 1

	-- ========== CREAR SCREENGUI DE ANIMACIÓN ==========
	local animGui = Instance.new("ScreenGui")
	animGui.Name = "EggOpenAnimation"
	animGui.DisplayOrder = 100
	animGui.IgnoreGuiInset = true
	animGui.ResetOnSpawn = false
	animGui.Parent = playerGui

	-- Fondo oscuro
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 1
	backdrop.BorderSizePixel = 0
	backdrop.Parent = animGui

	-- Animar aparición del fondo
	TweenService:Create(backdrop, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.6
	}):Play()

	-- ========== CONTENEDOR PRINCIPAL ==========
	local mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.new(0, 500, 0, 650)
	mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = animGui

	-- ========== VIEWPORT DEL HUEVO ==========
	local eggViewportContainer = Instance.new("Frame")
	eggViewportContainer.Name = "EggViewportContainer"
	eggViewportContainer.Size = UDim2.new(0, 450, 0, 450)
	eggViewportContainer.Position = UDim2.new(0.5, 0, 0.38, 0)
	eggViewportContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	eggViewportContainer.BackgroundTransparency = 1
	eggViewportContainer.Parent = mainContainer

	local _eggViewport, _eggModel, _eggCamera = createEggViewport(eggViewportContainer, eggIndex, UDim2.new(1, 0, 1, 0))

	-- Efecto de brillo detrás del huevo
	local glow = Instance.new("ImageLabel")
	glow.Name = "Glow"
	glow.Size = UDim2.new(1.5, 0, 1.5, 0)
	glow.Position = UDim2.new(0.5, 0, 0.5, 0)
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.BackgroundTransparency = 1
	glow.Image = "rbxassetid://5028857084" -- Radial gradient
	glow.ImageColor3 = rarityColor
	glow.ImageTransparency = 0.5
	glow.ZIndex = 0
	glow.Parent = eggViewportContainer

	-- Animar entrada del huevo (desde abajo)
	eggViewportContainer.Position = UDim2.new(0.5, 0, 1.5, 0)
	TweenService:Create(eggViewportContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.38, 0)
	}):Play()

	-- 🔊 Sonido de aparición
	SoundManager.play("Sparkle", 0.5, 1.0)

	task.wait(0.6)

	-- ========== ANIMACIÓN DE SHAKE ==========
	local shakeCount = 6
	local shakeDuration = 0.15

	for i = 1, shakeCount do
		local direction = (i % 2 == 0) and 1 or -1
		local intensity = 12 + (i * 2) -- Incrementa intensidad

		TweenService:Create(eggViewportContainer, TweenInfo.new(shakeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			Rotation = direction * intensity
		}):Play()

		-- 🔊 Sonido de crack
		if i == 3 or i == 5 then
			SoundManager.play("ButtonClick", 0.3, 0.8)
		end

		task.wait(shakeDuration)
	end

	-- Volver a posición neutral
	TweenService:Create(eggViewportContainer, TweenInfo.new(0.1), {
		Rotation = 0
	}):Play()

	task.wait(0.15)

	-- ========== EFECTO DE EXPLOSIÓN ==========
	-- Flash blanco
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 1
	flash.ZIndex = 10
	flash.Parent = animGui

	TweenService:Create(flash, TweenInfo.new(0.1), {
		BackgroundTransparency = 0.3
	}):Play()

	-- 🔊 Sonido de apertura
	SoundManager.play("ShopOpen", 0.6, 1.2)

	-- Ocultar huevo
	eggViewportContainer.Visible = false

	-- Expandir glow
	TweenService:Create(glow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(3, 0, 3, 0),
		ImageTransparency = 0.2
	}):Play()

	task.wait(0.15)

	-- Desvanecer flash
	TweenService:Create(flash, TweenInfo.new(0.3), {
		BackgroundTransparency = 1
	}):Play()

	-- ========== MOSTRAR MASCOTA ==========
	local petViewportContainer = Instance.new("Frame")
	petViewportContainer.Name = "PetViewportContainer"
	petViewportContainer.Size = UDim2.new(0, 380, 0, 380)
	petViewportContainer.Position = UDim2.new(0.5, 0, 0.35, 0)
	petViewportContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	petViewportContainer.BackgroundTransparency = 1
	petViewportContainer.Parent = mainContainer

	-- Escalar desde pequeño
	petViewportContainer.Size = UDim2.new(0, 0, 0, 0)

	local _petViewport = createPetViewport(petViewportContainer, petName, UDim2.new(1, 0, 1, 0))

	TweenService:Create(petViewportContainer, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 380, 0, 380)
	}):Play()

	-- 🔊 Sonido de revelación
	task.delay(0.1, function()
		SoundManager.play("Sparkle", 0.6, 1.3)
	end)

	task.wait(0.3)

	-- Normalizar glow
	TweenService:Create(glow, TweenInfo.new(0.5), {
		Size = UDim2.new(1.8, 0, 1.8, 0),
		ImageTransparency = 0.4
	}):Play()

	-- ========== TEXTOS DE INFORMACIÓN ==========
	-- Nombre de la mascota
	local petNameLabel = Instance.new("TextLabel")
	petNameLabel.Name = "PetName"
	petNameLabel.Size = UDim2.new(1, 0, 0, 60)
	petNameLabel.Position = UDim2.new(0.5, 0, 0.68, 0)
	petNameLabel.AnchorPoint = Vector2.new(0.5, 0)
	petNameLabel.BackgroundTransparency = 1
	petNameLabel.Text = petConfig.Name
	petNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	petNameLabel.TextSize = 52
	petNameLabel.Font = Enum.Font.FredokaOne
	petNameLabel.TextTransparency = 1
	petNameLabel.Parent = mainContainer

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 4
	nameStroke.Parent = petNameLabel

	-- Rareza
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "Rarity"
	rarityLabel.Size = UDim2.new(1, 0, 0, 35)
	rarityLabel.Position = UDim2.new(0.5, 0, 0.78, 0)
	rarityLabel.AnchorPoint = Vector2.new(0.5, 0)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = petConfig.Rarity
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.TextSize = 32
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.TextTransparency = 1
	rarityLabel.Parent = mainContainer

	local rarityStroke = Instance.new("UIStroke")
	rarityStroke.Color = Color3.fromRGB(0, 0, 0)
	rarityStroke.Thickness = 2
	rarityStroke.Parent = rarityLabel

	-- Perk/Boost
	local perkLabel = Instance.new("TextLabel")
	perkLabel.Name = "Perk"
	perkLabel.Size = UDim2.new(1, 0, 0, 32)
	perkLabel.Position = UDim2.new(0.5, 0, 0.85, 0)
	perkLabel.AnchorPoint = Vector2.new(0.5, 0)
	perkLabel.BackgroundTransparency = 1
	perkLabel.Text = "+" .. (petConfig.Boost * 100) .. "% Coin Boost"
	perkLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	perkLabel.TextSize = 28
	perkLabel.Font = Enum.Font.GothamBold
	perkLabel.TextTransparency = 1
	perkLabel.Parent = mainContainer

	local perkStroke = Instance.new("UIStroke")
	perkStroke.Color = Color3.fromRGB(0, 0, 0)
	perkStroke.Thickness = 2
	perkStroke.Parent = perkLabel

	-- Animar textos
	task.wait(0.2)
	TweenService:Create(petNameLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		TextTransparency = 0
	}):Play()

	task.wait(0.1)
	TweenService:Create(rarityLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		TextTransparency = 0
	}):Play()

	task.wait(0.1)
	TweenService:Create(perkLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		TextTransparency = 0
	}):Play()

	-- ========== BOTÓN DE CERRAR / TAP TO CLOSE ==========
	local closeHint = Instance.new("TextLabel")
	closeHint.Name = "CloseHint"
	closeHint.Size = UDim2.new(1, 0, 0, 28)
	closeHint.Position = UDim2.new(0.5, 0, 0.94, 0)
	closeHint.AnchorPoint = Vector2.new(0.5, 0)
	closeHint.BackgroundTransparency = 1
	closeHint.Text = "Tap anywhere to close"
	closeHint.TextColor3 = Color3.fromRGB(200, 200, 200)
	closeHint.TextSize = 20
	closeHint.Font = Enum.Font.Gotham
	closeHint.TextTransparency = 1
	closeHint.Parent = mainContainer

	task.wait(0.5)
	TweenService:Create(closeHint, TweenInfo.new(0.3), {
		TextTransparency = 0.3
	}):Play()

	-- ========== CERRAR AL HACER CLICK ==========
	local function closeAnimation()
		-- Evitar doble click
		backdrop.Active = false

		-- Animar salida
		TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		}):Play()

		TweenService:Create(backdrop, TweenInfo.new(0.3), {
			BackgroundTransparency = 1
		}):Play()

		task.wait(0.35)
		animGui:Destroy()
		isAnimationPlaying = false
	end

	backdrop.Active = true
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			closeAnimation()
		end
	end)

	-- También cerrar con tecla E o Escape
	local inputConnection
	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Return then
			inputConnection:Disconnect()
			closeAnimation()
		end
	end)
end

-- ============================================
-- ESTADO
-- ============================================

local eggDisplays = {} -- {eggName = {part, billboard}}
local currentVisibleEgg = nil

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================

player.CharacterAdded:Connect(function(char)
	character = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

local function getPartPosition(part)
	if part:IsA("Model") then
		return part.PrimaryPart and part.PrimaryPart.Position or part:GetPivot().Position
	end
	return part.Position
end

local function getAdorneePart(part)
	if part:IsA("Model") then
		if part.PrimaryPart then
			return part.PrimaryPart
		end
		for _, child in ipairs(part:GetDescendants()) do
			if child:IsA("BasePart") then
				return child
			end
		end
	end
	return part
end

local function sortPetsByChance(pets)
	local sorted = {}
	for petName, chance in pairs(pets) do
		table.insert(sorted, {name = petName, chance = chance})
	end
	table.sort(sorted, function(a, b) return a.chance > b.chance end)
	return sorted
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or UDim.new(0, 12)
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(0, 0, 0)
	stroke.Thickness = thickness or 3
	stroke.Parent = parent
	return stroke
end

-- ============================================
-- FUNCIONES DE COMPRA
-- ============================================

local function buyEgg(eggName)
	local success, petNameOrError, _ = Remotes.OpenEgg:InvokeServer(eggName)

	if not success then
		if petNameOrError == "ROBUX_PROMPT" then
			print("[EggShop] Esperando compra con Robux...")
			return false
		else
			warn("[EggShop] Error:", petNameOrError or "Desconocido")
			return false
		end
	end

	print("[EggShop] Huevo abierto! Obtenido:", petNameOrError)

	-- 🎬 Reproducir animación de apertura
	playEggOpenAnimation(eggName, petNameOrError)

	return true
end

-- ============================================
-- CREAR BILLBOARD PARA UN HUEVO (ESTILO CARTOON)
-- ============================================

local function createEggBillboard(eggPart, eggName, eggConfig)
	local adorneePart = getAdorneePart(eggPart)
	local isRobux = eggConfig.CostRobux ~= nil

	-- BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EggShopBillboard_" .. eggName
	billboard.Size = UDim2.new(12, 0, 14, 0)
	billboard.StudsOffset = Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.Active = true
	billboard.ClipsDescendants = false
	billboard.MaxDistance = 50
	billboard.ResetOnSpawn = false
	billboard.Adornee = adorneePart
	billboard.Enabled = false
	billboard.Parent = playerGui

	-- Frame principal con textura stud
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Active = false
	mainFrame.Parent = billboard

	-- Fondo con studs
	local bgStud = Instance.new("ImageLabel")
	bgStud.Name = "Background"
	bgStud.Size = UDim2.new(1, 0, 1, 0)
	bgStud.BackgroundTransparency = 1
	bgStud.Image = TextureManager.Backgrounds.StudGray
	bgStud.ImageColor3 = Styles.Colors.Background
	bgStud.ImageTransparency = 0.05
	bgStud.ScaleType = Enum.ScaleType.Tile
	bgStud.TileSize = UDim2.new(0, 40, 0, 40)
	bgStud.ZIndex = 1
	bgStud.Parent = mainFrame
	createCorner(bgStud, UDim.new(0, 16))

	-- Stroke del frame principal
	createStroke(mainFrame, Styles.Colors.Header, 5)
	createCorner(mainFrame, UDim.new(0, 16))

	-- ========== HEADER CON STUDS ==========
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, -16, 0.13, 0)
	header.Position = UDim2.new(0, 8, 0, 8)
	header.BackgroundTransparency = 1
	header.ZIndex = 2
	header.Parent = mainFrame

	-- Fondo header con studs
	local headerBg = Instance.new("ImageLabel")
	headerBg.Name = "HeaderBg"
	headerBg.Size = UDim2.new(1, 0, 1, 0)
	headerBg.BackgroundTransparency = 1
	headerBg.Image = TextureManager.Backgrounds.StudGray
	headerBg.ImageColor3 = Styles.Colors.Header
	headerBg.ImageTransparency = 0
	headerBg.ScaleType = Enum.ScaleType.Tile
	headerBg.TileSize = UDim2.new(0, 30, 0, 30)
	headerBg.ZIndex = 2
	headerBg.Parent = header
	createCorner(headerBg, UDim.new(0, 12))

	-- Stroke del header
	createStroke(header, Styles.Colors.HeaderDark, 4)
	createCorner(header, UDim.new(0, 12))

	-- Gradiente sutil en header
	local headerGradient = Instance.new("UIGradient")
	headerGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	})
	headerGradient.Rotation = 90
	headerGradient.Parent = headerBg

	-- Icono del huevo
	local eggIcon = Instance.new("TextLabel")
	eggIcon.Name = "EggIcon"
	eggIcon.Size = UDim2.new(0.15, 0, 0.9, 0)
	eggIcon.Position = UDim2.new(0.02, 0, 0.05, 0)
	eggIcon.BackgroundTransparency = 1
	eggIcon.Text = "🥚"
	eggIcon.TextScaled = true
	eggIcon.ZIndex = 3
	eggIcon.Parent = header

	-- Nombre del huevo
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
	nameLabel.Position = UDim2.new(0.17, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = eggConfig.Name
	nameLabel.Font = Styles.Fonts.Title
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Styles.Colors.Text
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 3
	nameLabel.Parent = header
	createStroke(nameLabel, Color3.fromRGB(0, 0, 0), 2)

	-- Precio container
	local priceContainer = Instance.new("Frame")
	priceContainer.Name = "PriceContainer"
	priceContainer.Size = UDim2.new(0.32, 0, 0.7, 0)
	priceContainer.Position = UDim2.new(0.66, 0, 0.15, 0)
	priceContainer.BackgroundColor3 = isRobux and Color3.fromRGB(80, 180, 100) or Color3.fromRGB(180, 140, 50)
	priceContainer.ZIndex = 3
	priceContainer.Parent = header
	createCorner(priceContainer, UDim.new(0, 8))
	createStroke(priceContainer, Color3.fromRGB(0, 0, 0), 2)

	local priceLayout = Instance.new("UIListLayout")
	priceLayout.FillDirection = Enum.FillDirection.Horizontal
	priceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	priceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	priceLayout.Padding = UDim.new(0, 4)
	priceLayout.Parent = priceContainer

	-- Icono de moneda/robux/trofeo
	if isRobux then
		local robuxIcon = Instance.new("ImageLabel")
		robuxIcon.Name = "RobuxIcon"
		robuxIcon.Size = UDim2.new(0, 20, 0, 20)
		robuxIcon.BackgroundTransparency = 1
		robuxIcon.Image = TextureManager.Icons.Robux
		robuxIcon.ScaleType = Enum.ScaleType.Fit
		robuxIcon.ZIndex = 4
		robuxIcon.LayoutOrder = 1
		robuxIcon.Parent = priceContainer
	else
		local trophyIcon = Instance.new("TextLabel")
		trophyIcon.Name = "TrophyIcon"
		trophyIcon.Size = UDim2.new(0, 20, 0, 20)
		trophyIcon.BackgroundTransparency = 1
		trophyIcon.Text = "🏆"
		trophyIcon.TextScaled = true
		trophyIcon.ZIndex = 4
		trophyIcon.LayoutOrder = 1
		trophyIcon.Parent = priceContainer
	end

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Size = UDim2.new(0, 45, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = isRobux and tostring(eggConfig.CostRobux) or tostring(eggConfig.TrophyCost)
	priceLabel.Font = Styles.Fonts.Title
	priceLabel.TextScaled = true
	priceLabel.TextColor3 = Styles.Colors.Text
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.ZIndex = 4
	priceLabel.LayoutOrder = 2
	priceLabel.Parent = priceContainer
	createStroke(priceLabel, Color3.fromRGB(0, 0, 0), 2)

	-- ========== CONTAINER DE MASCOTAS ==========
	local petsContainer = Instance.new("Frame")
	petsContainer.Name = "PetsContainer"
	petsContainer.Size = UDim2.new(1, -16, 0.55, 0)
	petsContainer.Position = UDim2.new(0, 8, 0.16, 0)
	petsContainer.BackgroundTransparency = 1
	petsContainer.ZIndex = 2
	petsContainer.Parent = mainFrame

	local petsLayout = Instance.new("UIGridLayout")
	petsLayout.CellSize = UDim2.new(0.31, 0, 0.47, 0)
	petsLayout.CellPadding = UDim2.new(0.02, 0, 0.03, 0)
	petsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	petsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	petsLayout.Parent = petsContainer

	-- Crear tarjetas de mascotas con studs
	local sortedPets = sortPetsByChance(eggConfig.Pets)
	for i, petData in ipairs(sortedPets) do
		local petConfig = Config.Pets[petData.name]
		if petConfig then
			local rarityColor = RarityColors[petConfig.Rarity] or RarityColors.Common

			local petCard = Instance.new("Frame")
			petCard.Name = petData.name
			petCard.BackgroundTransparency = 1
			petCard.LayoutOrder = i
			petCard.ClipsDescendants = true
			petCard.Parent = petsContainer

			-- Fondo con studs tintado por rareza
			local petBg = Instance.new("ImageLabel")
			petBg.Name = "PetBg"
			petBg.Size = UDim2.new(1, 0, 1, 0)
			petBg.BackgroundTransparency = 1
			petBg.Image = TextureManager.Backgrounds.StudGray
			petBg.ImageColor3 = rarityColor
			petBg.ImageTransparency = 0.15
			petBg.ScaleType = Enum.ScaleType.Tile
			petBg.TileSize = UDim2.new(0, 25, 0, 25)
			petBg.ZIndex = 2
			petBg.Parent = petCard
			createCorner(petBg, UDim.new(0, 10))

			createCorner(petCard, UDim.new(0, 10))
			createStroke(petCard, rarityColor, 3)

			-- Gradiente sutil
			local petGradient = Instance.new("UIGradient")
			petGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
			})
			petGradient.Rotation = 90
			petGradient.Parent = petBg

			-- Probabilidad
			local chanceLabel = Instance.new("TextLabel")
			chanceLabel.Size = UDim2.new(1, 0, 0.28, 0)
			chanceLabel.BackgroundTransparency = 1
			chanceLabel.Text = math.floor(petData.chance * 100) .. "%"
			chanceLabel.Font = Styles.Fonts.Body
			chanceLabel.TextScaled = true
			chanceLabel.TextColor3 = Styles.Colors.Text
			chanceLabel.ZIndex = 3
			chanceLabel.Parent = petCard
			createStroke(chanceLabel, Color3.fromRGB(0, 0, 0), 2)

			-- ViewportFrame con modelo 3D de la mascota
			local viewportContainer = Instance.new("Frame")
			viewportContainer.Name = "ViewportContainer"
			viewportContainer.Size = UDim2.new(1, -8, 0.45, 0)
			viewportContainer.Position = UDim2.new(0, 4, 0.22, 0)
			viewportContainer.BackgroundTransparency = 1
			viewportContainer.ZIndex = 3
			viewportContainer.Parent = petCard

			local petViewport = createPetViewport(viewportContainer, petData.name, UDim2.new(1, 0, 1, 0))
			petViewport.ZIndex = 3

			-- Nombre
			local petNameLabel = Instance.new("TextLabel")
			petNameLabel.Size = UDim2.new(1, -4, 0.25, 0)
			petNameLabel.Position = UDim2.new(0, 2, 0.72, 0)
			petNameLabel.BackgroundTransparency = 1
			petNameLabel.Text = petConfig.Name
			petNameLabel.Font = Styles.Fonts.Body
			petNameLabel.TextScaled = true
			petNameLabel.TextColor3 = Styles.Colors.Text
			petNameLabel.ZIndex = 3
			petNameLabel.Parent = petCard
			createStroke(petNameLabel, Color3.fromRGB(0, 0, 0), 2)
		end
	end

	-- ========== BOTÓN ÚNICO DE ABRIR ==========
	local buttonContainer = Instance.new("Frame")
	buttonContainer.Name = "ButtonContainer"
	buttonContainer.Size = UDim2.new(1, -16, 0.18, 0)
	buttonContainer.Position = UDim2.new(0, 8, 0.74, 0)
	buttonContainer.BackgroundTransparency = 1
	buttonContainer.ZIndex = 2
	buttonContainer.Parent = mainFrame

	-- Sombra del botón
	local buttonShadow = Instance.new("Frame")
	buttonShadow.Name = "Shadow"
	buttonShadow.Size = UDim2.new(0.85, 0, 0.85, 0)
	buttonShadow.Position = UDim2.new(0.075, 4, 0.075, 4)
	buttonShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	buttonShadow.BackgroundTransparency = 0.5
	buttonShadow.ZIndex = 2
	buttonShadow.Parent = buttonContainer
	createCorner(buttonShadow, UDim.new(0, 14))

	-- Botón principal con studs
	local btnColor = isRobux and Styles.Colors.ButtonRobux or Styles.Colors.ButtonCoin
	local btnStrokeColor = isRobux and Color3.fromRGB(40, 150, 80) or Color3.fromRGB(180, 140, 40)
	local txtColor = Styles.Colors.Text

	local openButton = Instance.new("ImageButton")
	openButton.Name = "OpenButton"
	openButton.Size = UDim2.new(0.85, 0, 0.85, 0)
	openButton.Position = UDim2.new(0.075, 0, 0.075, 0)
	openButton.BackgroundTransparency = 1
	openButton.Image = TextureManager.Backgrounds.StudGray
	openButton.ImageColor3 = btnColor
	openButton.ImageTransparency = 0.05
	openButton.ScaleType = Enum.ScaleType.Tile
	openButton.TileSize = UDim2.new(0, 30, 0, 30)
	openButton.ZIndex = 3
	openButton.Parent = buttonContainer
	createCorner(openButton, UDim.new(0, 14))

	createStroke(openButton, btnStrokeColor, 4)

	-- Gradiente del botón
	local btnGradient = Instance.new("UIGradient")
	btnGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	})
	btnGradient.Rotation = 90
	btnGradient.Parent = openButton

	-- Contenido del botón
	local btnContent = Instance.new("Frame")
	btnContent.Name = "Content"
	btnContent.Size = UDim2.new(1, 0, 1, 0)
	btnContent.BackgroundTransparency = 1
	btnContent.ZIndex = 4
	btnContent.Parent = openButton

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Horizontal
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.Parent = btnContent

	-- Icono en el botón (Robux si es de pago, trofeo si es de trofeos)
	if isRobux then
		local robuxIcon = Instance.new("ImageLabel")
		robuxIcon.Name = "Icon"
		robuxIcon.Size = UDim2.new(0, 28, 0, 28)
		robuxIcon.BackgroundTransparency = 1
		robuxIcon.Image = TextureManager.Icons.Robux
		robuxIcon.ScaleType = Enum.ScaleType.Fit
		robuxIcon.ZIndex = 5
		robuxIcon.LayoutOrder = 1
		robuxIcon.Parent = btnContent
	else
		local btnIcon = Instance.new("TextLabel")
		btnIcon.Name = "Icon"
		btnIcon.Size = UDim2.new(0, 30, 0, 30)
		btnIcon.BackgroundTransparency = 1
		btnIcon.Text = "🏆"
		btnIcon.TextScaled = true
		btnIcon.ZIndex = 5
		btnIcon.LayoutOrder = 1
		btnIcon.Parent = btnContent
	end

	-- Texto "OPEN"
	local btnText = Instance.new("TextLabel")
	btnText.Name = "Text"
	btnText.Size = UDim2.new(0, 80, 0, 35)
	btnText.BackgroundTransparency = 1
	btnText.Text = "OPEN"
	btnText.Font = Styles.Fonts.Title
	btnText.TextScaled = true
	btnText.TextColor3 = txtColor
	btnText.ZIndex = 5
	btnText.LayoutOrder = 2
	btnText.Parent = btnContent
	createStroke(btnText, Color3.fromRGB(0, 0, 0), 2)

	-- Efectos hover y click
	local originalSize = openButton.Size
	local originalShadowPos = buttonShadow.Position

	openButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.2, 1.1)
		TweenService:Create(openButton, TweenInfo.new(0.12), {
			ImageColor3 = Color3.fromRGB(
				math.min(255, btnColor.R * 255 + 30),
				math.min(255, btnColor.G * 255 + 30),
				math.min(255, btnColor.B * 255 + 30)
			)
		}):Play()
		TweenService:Create(openButton, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
			Size = UDim2.new(0.88, 0, 0.88, 0),
			Position = UDim2.new(0.06, 0, 0.06, 0)
		}):Play()
	end)

	openButton.MouseLeave:Connect(function()
		TweenService:Create(openButton, TweenInfo.new(0.15), {
			ImageColor3 = btnColor
		}):Play()
		TweenService:Create(openButton, TweenInfo.new(0.15), {
			Size = originalSize,
			Position = UDim2.new(0.075, 0, 0.075, 0)
		}):Play()
	end)

	openButton.MouseButton1Down:Connect(function()
		TweenService:Create(openButton, TweenInfo.new(0.05), {
			Size = UDim2.new(0.82, 0, 0.82, 0),
			Position = UDim2.new(0.09, 0, 0.09, 0)
		}):Play()
		TweenService:Create(buttonShadow, TweenInfo.new(0.05), {
			Position = UDim2.new(0.09, 2, 0.09, 2)
		}):Play()
	end)

	openButton.MouseButton1Up:Connect(function()
		TweenService:Create(openButton, TweenInfo.new(0.12, Enum.EasingStyle.Back), {
			Size = originalSize,
			Position = UDim2.new(0.075, 0, 0.075, 0)
		}):Play()
		TweenService:Create(buttonShadow, TweenInfo.new(0.12), {
			Position = originalShadowPos
		}):Play()
	end)

	openButton.Activated:Connect(function()
		SoundManager.play("ButtonClick", 0.4, 1.0)
		buyEgg(eggName)
	end)

	-- ========== TEXTO DE AYUDA (KEYBIND) ==========
	local helpText = Instance.new("TextLabel")
	helpText.Name = "HelpText"
	helpText.Size = UDim2.new(1, 0, 0.06, 0)
	helpText.Position = UDim2.new(0, 0, 0.93, 0)
	helpText.BackgroundTransparency = 1
	helpText.Text = "Press [E] to open"
	helpText.Font = Styles.Fonts.Body
	helpText.TextScaled = true
	helpText.TextColor3 = Color3.fromRGB(150, 150, 180)
	helpText.ZIndex = 2
	helpText.Parent = mainFrame
	createStroke(helpText, Color3.fromRGB(0, 0, 0), 1).Transparency = 0.5

	return billboard
end

-- ============================================
-- BUSCAR E INICIALIZAR HUEVOS
-- ============================================

local function findAndSetupEggs()
	local function searchInFolder(folder)
		for _, child in ipairs(folder:GetChildren()) do
			if child.Name:sub(1, #EGG_PART_PREFIX) == EGG_PART_PREFIX then
				local eggName = child.Name:sub(#EGG_PART_PREFIX + 1)
				local eggConfig = Config.Eggs[eggName]

				if eggConfig then
					print("[EggShop] Encontrado:", child.Name)
					local billboard = createEggBillboard(child, eggName, eggConfig)
					eggDisplays[eggName] = {
						part = child,
						billboard = billboard,
					}
				end
			end

			if child:IsA("Folder") or child:IsA("Model") then
				searchInFolder(child)
			end
		end
	end

	searchInFolder(Workspace)
end

-- ============================================
-- ACTUALIZAR VISIBILIDAD POR PROXIMIDAD
-- ============================================

local function updateProximity()
	if not humanoidRootPart then return end

	local playerPos = humanoidRootPart.Position
	local closestEgg = nil
	local closestDistance = math.huge

	for eggName, data in pairs(eggDisplays) do
		local partPos = getPartPosition(data.part)
		local distance = (partPos - playerPos).Magnitude

		if distance <= PROXIMITY_DISTANCE and distance < closestDistance then
			closestDistance = distance
			closestEgg = eggName
		end
	end

	if closestEgg ~= currentVisibleEgg then
		if currentVisibleEgg and eggDisplays[currentVisibleEgg] then
			eggDisplays[currentVisibleEgg].billboard.Enabled = false
		end

		if closestEgg and eggDisplays[closestEgg] then
			eggDisplays[closestEgg].billboard.Enabled = true
		end

		currentVisibleEgg = closestEgg
	end
end

-- ============================================
-- TECLAS RÁPIDAS
-- ============================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not currentVisibleEgg then return end

	if input.KeyCode == Enum.KeyCode.E then
		SoundManager.play("ButtonClick", 0.4, 1.0)
		buyEgg(currentVisibleEgg)
	end
end)

-- ============================================
-- INICIALIZACIÓN
-- ============================================

task.wait(1)
findAndSetupEggs()

RunService.Heartbeat:Connect(updateProximity)

Remotes.OnDataUpdated.OnClientEvent:Connect(function(newData)
	-- Datos actualizados
end)

print("[EggShop] Sistema de huevos cartoon inicializado")
