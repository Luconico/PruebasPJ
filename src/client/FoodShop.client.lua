--[[
	FoodShop.client.lua
	Crea carteles visuales con botón de compra clickeable
	Los carteles se crean en el cliente para que sean interactivos
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer

-- Esperar dependencias
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local BuyFoodFromSign = Remotes:WaitForChild("BuyFoodFromSign", 10)
local OnFoodPurchased = Remotes:WaitForChild("OnFoodPurchased", 10)
local GetUnlockedFoods = Remotes:WaitForChild("GetUnlockedFoods", 10)
local OnFoodZoneEnter = Remotes:WaitForChild("OnFoodZoneEnter", 10)
local OnFoodZoneExit = Remotes:WaitForChild("OnFoodZoneExit", 10)

if not BuyFoodFromSign then
	warn("[FoodShop] No se encontró BuyFoodFromSign remote")
	return
end

-- Cache de comidas desbloqueadas
local unlockedFoods = {}

-- Referencia al popup actual
local currentPopup = nil
local currentPopupFoodType = nil

-- IDs de imágenes
local SHINING_IMAGE = "rbxassetid://18113508685"
local ROBUX_ICON = "rbxassetid://18113165803"

-- IDs de sonidos (verificados de Roblox)
local SOUNDS = {
	PopupOpen = "rbxassetid://2235655773",      -- Swoosh Sound Effect
	PopupClose = "rbxassetid://231731980",      -- Whoosh
	ButtonHover = "rbxassetid://6324801967",    -- Button hover (cartoony)
	ButtonClick = "rbxassetid://4307186075",    -- Click sound (cartoony/bubble)
	PurchaseSuccess = "rbxassetid://4764628264", -- Final Fantasy VII - Victory Fanfare
	CashRegister = "rbxassetid://7112275565",   -- Cash Register (Kaching)
	Sparkle = "rbxassetid://3292075199",        -- Sparkle Noise - Sound Effect
	Error = "rbxassetid://5852470908",          -- Cartoon bubble button Sound
}

-- Función para reproducir sonidos
local function playSound(soundId, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	return sound
end

-- Contador para nombres únicos
local signCounter = 0

-- ============================================
-- CREAR CARTEL CON EFECTOS
-- ============================================

local function createFoodSign(zonePart, foodType, isOwned)
	local foodConfig = Config.Food[foodType]
	if not foodConfig then return end

	local playerGui = player:WaitForChild("PlayerGui")

	-- Eliminar cartel existente para esta zona específica (buscar por Adornee)
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("BillboardGui") and gui.Adornee == zonePart then
			gui:Destroy()
			break
		end
	end

	-- BillboardGui principal - DEBE estar en PlayerGui para que los clicks funcionen
	signCounter = signCounter + 1
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FoodSign_" .. foodType .. "_" .. signCounter
	billboard.Size = UDim2.new(0, 220, 0, 180)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = false
	billboard.Active = true
	billboard.Adornee = zonePart -- Apunta al Part en Workspace
	billboard.MaxDistance = 100
	billboard.ResetOnSpawn = false
	billboard.Parent = playerGui -- En PlayerGui, NO en el Part

	-- Frame principal
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = foodConfig.Color
	mainFrame.BackgroundTransparency = 0.25
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Active = false -- No bloquear clicks
	mainFrame.Parent = billboard

	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = mainFrame

	-- Borde grueso cartoon
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 50, 50)
	stroke.Thickness = 4
	stroke.Parent = mainFrame

	-- ============================================
	-- EFECTO SHINING GIRANDO (contenido en un frame con bordes redondeados)
	-- ============================================
	local shiningContainer = Instance.new("Frame")
	shiningContainer.Name = "ShiningContainer"
	shiningContainer.Size = UDim2.new(1, 0, 1, 0)
	shiningContainer.BackgroundTransparency = 1
	shiningContainer.ClipsDescendants = true
	shiningContainer.Active = false -- No bloquear clicks
	shiningContainer.Parent = mainFrame

	local shiningCorner = Instance.new("UICorner")
	shiningCorner.CornerRadius = UDim.new(0, 16)
	shiningCorner.Parent = shiningContainer

	local shiningImage = Instance.new("ImageLabel")
	shiningImage.Name = "Shining"
	shiningImage.Size = UDim2.new(1.5, 0, 1.5, 0)
	shiningImage.AnchorPoint = Vector2.new(0.5, 0.5)
	shiningImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	shiningImage.BackgroundTransparency = 1
	shiningImage.Image = SHINING_IMAGE
	shiningImage.ImageTransparency = 0.85
	shiningImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
	shiningImage.ZIndex = 1
	shiningImage.Parent = shiningContainer

	-- Animación de rotación lenta del shining
	task.spawn(function()
		while shiningImage and shiningImage.Parent do
			local rotateTween = TweenService:Create(shiningImage, TweenInfo.new(8, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {
				Rotation = shiningImage.Rotation + 360
			})
			rotateTween:Play()
			rotateTween.Completed:Wait()
		end
	end)

	-- ============================================
	-- ICONO CON ANIMACIÓN PULSE
	-- ============================================
	local iconContainer = Instance.new("Frame")
	iconContainer.Name = "IconContainer"
	iconContainer.Size = UDim2.new(1, 0, 0.35, 0)
	iconContainer.Position = UDim2.new(0, 0, 0.02, 0)
	iconContainer.BackgroundTransparency = 1
	iconContainer.ZIndex = 2
	iconContainer.Active = false -- No bloquear clicks
	iconContainer.Parent = mainFrame

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 1, 0)
	iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = foodConfig.Icon or "🍽️"
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.ZIndex = 2
	iconLabel.Parent = iconContainer

	-- Animación pulse del icono
	task.spawn(function()
		while iconLabel and iconLabel.Parent do
			local pulseUp = TweenService:Create(iconLabel, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(1.15, 0, 1.15, 0)
			})
			pulseUp:Play()
			pulseUp.Completed:Wait()

			local pulseDown = TweenService:Create(iconLabel, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(1, 0, 1, 0)
			})
			pulseDown:Play()
			pulseDown.Completed:Wait()
		end
	end)

	-- ============================================
	-- NOMBRE Y VELOCIDAD
	-- ============================================
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "FoodName"
	nameLabel.Size = UDim2.new(1, -10, 0.16, 0)
	nameLabel.Position = UDim2.new(0, 5, 0.36, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = foodConfig.Name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.ZIndex = 2
	nameLabel.Parent = mainFrame

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2.5
	nameStroke.Parent = nameLabel

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "Speed"
	speedLabel.Size = UDim2.new(1, -10, 0.12, 0)
	speedLabel.Position = UDim2.new(0, 5, 0.52, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: x" .. (foodConfig.SpeedMultiplier or 1)
	speedLabel.TextScaled = true
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.ZIndex = 2
	speedLabel.Parent = mainFrame

	local speedStroke = Instance.new("UIStroke")
	speedStroke.Color = Color3.fromRGB(0, 0, 0)
	speedStroke.Thickness = 2.5
	speedStroke.Parent = speedLabel

	-- ============================================
	-- BOTÓN DE COMPRA
	-- ============================================
	if foodConfig.CostRobux > 0 then
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0.85, 0, 0.22, 0)
		buyButton.Position = UDim2.new(0.075, 0, 0.7, 0)
		buyButton.BorderSizePixel = 0
		buyButton.Active = true
		buyButton.AutoButtonColor = false
		buyButton.ZIndex = 3
		buyButton.Parent = mainFrame

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent = buyButton

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Thickness = 3
		btnStroke.Parent = buyButton

		-- Si ya lo tiene, mostrar OWNED
		if isOwned then
			buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
			buyButton.Text = "OWNED!"
			buyButton.TextScaled = true
			buyButton.Font = Enum.Font.GothamBold
			buyButton.TextColor3 = Color3.new(1, 1, 1)
			btnStroke.Color = Color3.fromRGB(60, 60, 60)
		else
			buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
			buyButton.Text = ""
			btnStroke.Color = Color3.fromRGB(0, 100, 50)

			-- Contenedor horizontal para texto + icono Robux
			local buttonContent = Instance.new("Frame")
			buttonContent.Name = "ButtonContent"
			buttonContent.Size = UDim2.new(1, 0, 1, 0)
			buttonContent.BackgroundTransparency = 1
			buttonContent.ZIndex = 4
			buttonContent.Active = false -- No bloquear clicks
			buttonContent.Parent = buyButton

			local contentLayout = Instance.new("UIListLayout")
			contentLayout.FillDirection = Enum.FillDirection.Horizontal
			contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			contentLayout.Padding = UDim.new(0, 4)
			contentLayout.Parent = buttonContent

			local buyText = Instance.new("TextLabel")
			buyText.Name = "BuyText"
			buyText.Size = UDim2.new(0, 70, 0, 28)
			buyText.BackgroundTransparency = 1
			buyText.Text = "BUY " .. foodConfig.CostRobux
			buyText.TextScaled = true
			buyText.Font = Enum.Font.GothamBold
			buyText.TextColor3 = Color3.new(1, 1, 1)
			buyText.TextXAlignment = Enum.TextXAlignment.Right
			buyText.ZIndex = 4
			buyText.Parent = buttonContent

			local robuxIcon = Instance.new("ImageLabel")
			robuxIcon.Name = "RobuxIcon"
			robuxIcon.Size = UDim2.new(0, 24, 0, 24)
			robuxIcon.BackgroundTransparency = 1
			robuxIcon.Image = ROBUX_ICON
			robuxIcon.ScaleType = Enum.ScaleType.Fit
			robuxIcon.ZIndex = 4
			robuxIcon.Parent = buttonContent

			-- Click para comprar (Activated funciona mejor en BillboardGui)
			buyButton.Activated:Connect(function()
				playSound(SOUNDS.ButtonClick, 0.5, 1.0)
				playSound(SOUNDS.CashRegister, 0.3, 1.1)
				print("[FoodShop] Comprando:", foodType)
				BuyFoodFromSign:FireServer(foodType)
			end)

			-- Efecto hover
			buyButton.MouseEnter:Connect(function()
				playSound(SOUNDS.ButtonHover, 0.2, 1.1)
				TweenService:Create(buyButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(0, 255, 130),
					Size = UDim2.new(0.9, 0, 0.24, 0)
				}):Play()
			end)

			buyButton.MouseLeave:Connect(function()
				TweenService:Create(buyButton, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(0, 200, 100),
					Size = UDim2.new(0.85, 0, 0.22, 0)
				}):Play()
			end)
		end

		-- Guardar referencia para actualizar después
		buyButton:SetAttribute("FoodType", foodType)

	else
		-- Si es gratis, mostrar FREE
		local freeLabel = Instance.new("TextLabel")
		freeLabel.Name = "FreeLabel"
		freeLabel.Size = UDim2.new(0.85, 0, 0.22, 0)
		freeLabel.Position = UDim2.new(0.075, 0, 0.7, 0)
		freeLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		freeLabel.BorderSizePixel = 0
		freeLabel.Text = "FREE!"
		freeLabel.TextScaled = true
		freeLabel.Font = Enum.Font.GothamBold
		freeLabel.TextColor3 = Color3.new(1, 1, 1)
		freeLabel.ZIndex = 4
		freeLabel.Parent = mainFrame

		local freeCorner = Instance.new("UICorner")
		freeCorner.CornerRadius = UDim.new(0, 10)
		freeCorner.Parent = freeLabel

		local freeStroke = Instance.new("UIStroke")
		freeStroke.Color = Color3.fromRGB(50, 150, 50)
		freeStroke.Thickness = 3
		freeStroke.Parent = freeLabel
	end

	print("[FoodShop] Cartel creado para:", foodType)
	return billboard
end

-- ============================================
-- BUSCAR ZONAS Y CREAR CARTELES
-- ============================================

local function setupFoodZones()
	local foodFolder = workspace:WaitForChild("FoodZones", 10)
	if not foodFolder then
		warn("[FoodShop] No se encontró carpeta FoodZones")
		return
	end

	-- Obtener comidas desbloqueadas del servidor
	if GetUnlockedFoods then
		unlockedFoods = GetUnlockedFoods:InvokeServer() or {}
		print("[FoodShop] Comidas desbloqueadas:", unlockedFoods)
	end

	for _, zonePart in ipairs(foodFolder:GetChildren()) do
		if zonePart:IsA("BasePart") then
			local foodType = zonePart:GetAttribute("FoodType")
			if foodType and Config.Food[foodType] then
				-- Eliminar cartel del servidor si existe
				local serverSign = zonePart:FindFirstChild("FoodSign")
				if serverSign then
					serverSign:Destroy()
				end

				-- Crear cartel del cliente (pasar si ya está desbloqueada)
				local isOwned = unlockedFoods[foodType] or false
				createFoodSign(zonePart, foodType, isOwned)
			end
		end
	end
end

-- ============================================
-- POPUP DE COMPRA (cuando entras en zona sin desbloquear)
-- ============================================

local function closePurchasePopup()
	if currentPopup then
		-- Sonido de cierre (whoosh reverso)
		playSound(SOUNDS.PopupClose, 0.3, 1.3)

		-- Animación de cierre
		local mainFrame = currentPopup:FindFirstChild("MainFrame")
		if mainFrame then
			TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 0, 0, 0),
				Position = UDim2.new(0.5, 0, 0.5, 0)
			}):Play()
			task.wait(0.2)
		end
		currentPopup:Destroy()
		currentPopup = nil
		currentPopupFoodType = nil
	end
end

local function showPurchasePopup(foodType, foodConfig)
	-- Cerrar popup anterior si existe
	closePurchasePopup()

	local playerGui = player:WaitForChild("PlayerGui")

	-- ScreenGui para el popup
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FoodPurchasePopup"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	currentPopup = screenGui
	currentPopupFoodType = foodType

	-- Sonidos de apertura (whoosh + sparkle)
	playSound(SOUNDS.PopupOpen, 0.4, 0.9)
	task.delay(0.15, function()
		playSound(SOUNDS.Sparkle, 0.3, 1.2)
	end)

	-- Fondo semi-transparente
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.BorderSizePixel = 0
	background.Parent = screenGui

	-- Frame principal del popup
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 0, 0, 0) -- Empieza pequeño para animación
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = foodConfig.Color
	mainFrame.BackgroundTransparency = 0.1
	mainFrame.BorderSizePixel = 0
	mainFrame.ClipsDescendants = true
	mainFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 24)
	corner.Parent = mainFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(50, 50, 50)
	stroke.Thickness = 6
	stroke.Parent = mainFrame

	-- Animación de apertura
	TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 380, 0, 420),
		Position = UDim2.new(0.5, 0, 0.5, 0)
	}):Play()

	-- Shining de fondo giratorio
	local shiningContainer = Instance.new("Frame")
	shiningContainer.Name = "ShiningContainer"
	shiningContainer.Size = UDim2.new(1, 0, 1, 0)
	shiningContainer.BackgroundTransparency = 1
	shiningContainer.ClipsDescendants = true
	shiningContainer.Parent = mainFrame

	local shiningCorner = Instance.new("UICorner")
	shiningCorner.CornerRadius = UDim.new(0, 24)
	shiningCorner.Parent = shiningContainer

	local shiningImage = Instance.new("ImageLabel")
	shiningImage.Name = "Shining"
	shiningImage.Size = UDim2.new(2, 0, 2, 0)
	shiningImage.AnchorPoint = Vector2.new(0.5, 0.5)
	shiningImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	shiningImage.BackgroundTransparency = 1
	shiningImage.Image = SHINING_IMAGE
	shiningImage.ImageTransparency = 0.8
	shiningImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
	shiningImage.ZIndex = 1
	shiningImage.Parent = shiningContainer

	-- Animación de rotación del shining
	task.spawn(function()
		while shiningImage and shiningImage.Parent do
			local rotateTween = TweenService:Create(shiningImage, TweenInfo.new(6, Enum.EasingStyle.Linear), {
				Rotation = shiningImage.Rotation + 360
			})
			rotateTween:Play()
			rotateTween.Completed:Wait()
		end
	end)

	-- Botón X para cerrar
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 50, 0, 50)
	closeButton.Position = UDim2.new(1, -60, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextColor3 = Color3.new(1, 1, 1)
	closeButton.ZIndex = 10
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 12)
	closeCorner.Parent = closeButton

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(150, 30, 30)
	closeStroke.Thickness = 3
	closeStroke.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		playSound(SOUNDS.ButtonClick, 0.4, 1.1)
		closePurchasePopup()
	end)

	-- Hover effect para X
	closeButton.MouseEnter:Connect(function()
		playSound(SOUNDS.ButtonHover, 0.2, 1.2)
		TweenService:Create(closeButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(255, 80, 80),
			Size = UDim2.new(0, 55, 0, 55)
		}):Play()
	end)

	closeButton.MouseLeave:Connect(function()
		TweenService:Create(closeButton, TweenInfo.new(0.15), {
			BackgroundColor3 = Color3.fromRGB(220, 60, 60),
			Size = UDim2.new(0, 50, 0, 50)
		}):Play()
	end)

	-- Título "UNLOCK"
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, -20, 0, 50)
	titleLabel.Position = UDim2.new(0, 10, 0, 15)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🔓 UNLOCK 🔓"
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.TextColor3 = Color3.new(1, 1, 1)
	titleLabel.ZIndex = 2
	titleLabel.Parent = mainFrame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 3
	titleStroke.Parent = titleLabel

	-- Icono grande con animación bounce
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 120, 0, 120)
	iconLabel.Position = UDim2.new(0.5, 0, 0, 75)
	iconLabel.AnchorPoint = Vector2.new(0.5, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = foodConfig.Icon or "🍽️"
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.ZIndex = 2
	iconLabel.Parent = mainFrame

	-- Animación bounce del icono
	task.spawn(function()
		while iconLabel and iconLabel.Parent do
			local bounceUp = TweenService:Create(iconLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				Position = UDim2.new(0.5, 0, 0, 60)
			})
			bounceUp:Play()
			bounceUp.Completed:Wait()

			local bounceDown = TweenService:Create(iconLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, 75)
			})
			bounceDown:Play()
			bounceDown.Completed:Wait()
		end
	end)

	-- Nombre de la comida
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "FoodName"
	nameLabel.Size = UDim2.new(1, -20, 0, 45)
	nameLabel.Position = UDim2.new(0, 10, 0, 200)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = foodConfig.Name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.ZIndex = 2
	nameLabel.Parent = mainFrame

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 3
	nameStroke.Parent = nameLabel

	-- Velocidad
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "Speed"
	speedLabel.Size = UDim2.new(1, -20, 0, 35)
	speedLabel.Position = UDim2.new(0, 10, 0, 250)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "⚡ Speed: x" .. (foodConfig.SpeedMultiplier or 1) .. " ⚡"
	speedLabel.TextScaled = true
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	speedLabel.ZIndex = 2
	speedLabel.Parent = mainFrame

	local speedStroke = Instance.new("UIStroke")
	speedStroke.Color = Color3.fromRGB(0, 0, 0)
	speedStroke.Thickness = 2
	speedStroke.Parent = speedLabel

	-- Descripción
	local descLabel = Instance.new("TextLabel")
	descLabel.Name = "Description"
	descLabel.Size = UDim2.new(1, -30, 0, 40)
	descLabel.Position = UDim2.new(0, 15, 0, 290)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = "Get fatter " .. (foodConfig.SpeedMultiplier or 1) .. "x faster!"
	descLabel.TextScaled = true
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	descLabel.ZIndex = 2
	descLabel.Parent = mainFrame

	-- Botón de compra grande
	local buyButton = Instance.new("TextButton")
	buyButton.Name = "BuyButton"
	buyButton.Size = UDim2.new(0.85, 0, 0, 65)
	buyButton.Position = UDim2.new(0.075, 0, 0, 340)
	buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	buyButton.BorderSizePixel = 0
	buyButton.Text = ""
	buyButton.AutoButtonColor = false
	buyButton.ZIndex = 3
	buyButton.Parent = mainFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 16)
	btnCorner.Parent = buyButton

	local btnStroke = Instance.new("UIStroke")
	btnStroke.Color = Color3.fromRGB(0, 120, 60)
	btnStroke.Thickness = 4
	btnStroke.Parent = buyButton

	-- Contenido del botón
	local buttonContent = Instance.new("Frame")
	buttonContent.Name = "ButtonContent"
	buttonContent.Size = UDim2.new(1, 0, 1, 0)
	buttonContent.BackgroundTransparency = 1
	buttonContent.ZIndex = 4
	buttonContent.Parent = buyButton

	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Horizontal
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.Padding = UDim.new(0, 8)
	contentLayout.Parent = buttonContent

	local buyText = Instance.new("TextLabel")
	buyText.Name = "BuyText"
	buyText.Size = UDim2.new(0, 150, 0, 50)
	buyText.BackgroundTransparency = 1
	buyText.Text = "BUY FOR " .. foodConfig.CostRobux
	buyText.TextScaled = true
	buyText.Font = Enum.Font.FredokaOne
	buyText.TextColor3 = Color3.new(1, 1, 1)
	buyText.ZIndex = 4
	buyText.Parent = buttonContent

	local robuxIcon = Instance.new("ImageLabel")
	robuxIcon.Name = "RobuxIcon"
	robuxIcon.Size = UDim2.new(0, 40, 0, 40)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Image = ROBUX_ICON
	robuxIcon.ScaleType = Enum.ScaleType.Fit
	robuxIcon.ZIndex = 4
	robuxIcon.Parent = buttonContent

	-- Click para comprar
	buyButton.MouseButton1Click:Connect(function()
		playSound(SOUNDS.ButtonClick, 0.5, 1.0)
		playSound(SOUNDS.CashRegister, 0.4, 1.0)
		print("[FoodShop] Comprando desde popup:", foodType)
		BuyFoodFromSign:FireServer(foodType)
	end)

	-- Hover del botón de compra
	buyButton.MouseEnter:Connect(function()
		playSound(SOUNDS.ButtonHover, 0.25, 1.0)
		TweenService:Create(buyButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(0, 255, 130),
			Size = UDim2.new(0.9, 0, 0, 70)
		}):Play()
	end)

	buyButton.MouseLeave:Connect(function()
		TweenService:Create(buyButton, TweenInfo.new(0.2), {
			BackgroundColor3 = Color3.fromRGB(0, 200, 100),
			Size = UDim2.new(0.85, 0, 0, 65)
		}):Play()
	end)

	-- Animación de brillo en el botón
	task.spawn(function()
		while buyButton and buyButton.Parent do
			local glow = TweenService:Create(btnStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Color = Color3.fromRGB(100, 255, 150)
			})
			glow:Play()
			glow.Completed:Wait()

			local unglow = TweenService:Create(btnStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Color = Color3.fromRGB(0, 120, 60)
			})
			unglow:Play()
			unglow.Completed:Wait()
		end
	end)
end

-- ============================================
-- MANEJAR ENTRADA/SALIDA DE ZONAS
-- ============================================

if OnFoodZoneEnter then
	OnFoodZoneEnter.OnClientEvent:Connect(function(foodType, foodConfig, isUnlocked)
		print("[FoodShop] Entrando en zona:", foodType, "Desbloqueado:", isUnlocked)

		-- Solo mostrar popup si NO está desbloqueado y tiene costo
		if not isUnlocked and foodConfig and foodConfig.CostRobux > 0 then
			showPurchasePopup(foodType, foodConfig)
		end
	end)
end

if OnFoodZoneExit then
	OnFoodZoneExit.OnClientEvent:Connect(function(foodType)
		print("[FoodShop] Saliendo de zona:", foodType)

		-- Cerrar popup si es de esta comida
		if currentPopupFoodType == foodType then
			closePurchasePopup()
		end
	end)
end

-- ============================================
-- MANEJAR COMPRA EXITOSA
-- ============================================

if OnFoodPurchased then
	OnFoodPurchased.OnClientEvent:Connect(function(foodType, success)
		if success then
			print("[FoodShop] Compra exitosa:", foodType)

			-- 🎉 Sonidos de celebración mágicos
			playSound(SOUNDS.PurchaseSuccess, 0.6, 1.0)  -- Fanfarria principal
			task.delay(0.1, function()
				playSound(SOUNDS.CashRegister, 0.5, 1.1) -- Ka-ching!
			end)
			task.delay(0.3, function()
				playSound(SOUNDS.Sparkle, 0.5, 0.9)      -- Brillo mágico
			end)
			task.delay(0.6, function()
				playSound(SOUNDS.Sparkle, 0.4, 1.3)      -- Segundo brillo más agudo
			end)

			-- Cerrar popup si existe
			if currentPopupFoodType == foodType then
				closePurchasePopup()
			end

			-- Actualizar cache de desbloqueados
			unlockedFoods[foodType] = true

			-- Cambiar TODOS los botones de este tipo a "OWNED"
			local playerGui = player:FindFirstChild("PlayerGui")
			if playerGui then
				-- Buscar todos los BillboardGuis que son carteles de comida
				for _, gui in ipairs(playerGui:GetChildren()) do
					if gui:IsA("BillboardGui") and gui.Name:sub(1, 9) == "FoodSign_" then
						-- Verificar si el Adornee tiene el FoodType correcto
						local adornee = gui.Adornee
						if adornee and adornee:GetAttribute("FoodType") == foodType then
							local mainFrame = gui:FindFirstChild("MainFrame")
							if mainFrame then
								local buyButton = mainFrame:FindFirstChild("BuyButton")
								if buyButton then
									buyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
									-- Limpiar contenido y poner texto OWNED
									local buttonContent = buyButton:FindFirstChild("ButtonContent")
									if buttonContent then
										buttonContent:Destroy()
									end
									buyButton.Text = "OWNED!"
									buyButton.TextScaled = true
									buyButton.Font = Enum.Font.GothamBold
									buyButton.TextColor3 = Color3.new(1, 1, 1)
								end
							end
						end
					end
				end
			end
		end
	end)
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

task.wait(2)
setupFoodZones()

print("[FoodShop] Sistema de compra de comida inicializado")
