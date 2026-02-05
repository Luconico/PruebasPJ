--[[
	EggShop.client.lua
	Sistema de huevos con BillboardGui clickeable
	El BillboardGui debe estar en PlayerGui con Adornee apuntando al Part
	Busca Parts/Models con nombre Egg_[NombreHuevo]
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
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

-- ============================================
-- CONFIGURACIÓN
-- ============================================

local PROXIMITY_DISTANCE = 12
local EGG_PART_PREFIX = "Egg_"

-- Estilos
local Styles = {
	Colors = {
		Background = Color3.fromRGB(35, 35, 55),
		Header = Color3.fromRGB(255, 200, 100),
		ButtonCoin = Color3.fromRGB(255, 200, 50),
		ButtonRobux = Color3.fromRGB(100, 200, 100),
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(40, 40, 60),
	},
	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
	},
}

local RarityColors = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(100, 200, 100),
	Rare = Color3.fromRGB(100, 150, 255),
	Epic = Color3.fromRGB(200, 100, 255),
	Legendary = Color3.fromRGB(255, 200, 50),
}

-- ============================================
-- ESTADO
-- ============================================

local eggDisplays = {} -- {eggName = {part, billboard}}
local autoOpenEnabled = {}
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
	-- Si es Model, devolver PrimaryPart o la primera BasePart
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

-- ============================================
-- FUNCIONES DE COMPRA
-- ============================================

local function buyEgg(eggName, amount)
	for i = 1, amount do
		-- InvokeServer devuelve: success, petName/errorMsg, productId
		local success, petNameOrError, extra = Remotes.OpenEgg:InvokeServer(eggName)

		if not success then
			if petNameOrError == "ROBUX_PROMPT" then
				-- Se abrió el prompt de Robux - esperar a que el jugador compre
				print("[EggShop] Esperando compra con Robux...")
				return false -- No continuar, el ProcessReceipt manejará la compra
			else
				warn("[EggShop] Error:", petNameOrError or "Desconocido")
				return false
			end
		end

		print("[EggShop] Huevo abierto! Obtenido:", petNameOrError)
		if amount > 1 then task.wait(0.3) end
	end
	return true
end

local function toggleAuto(eggName, autoButton)
	autoOpenEnabled[eggName] = not autoOpenEnabled[eggName]

	if autoOpenEnabled[eggName] then
		autoButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		autoButton.Text = "Auto ✓"

		task.spawn(function()
			while autoOpenEnabled[eggName] do
				if not buyEgg(eggName, 1) then
					autoOpenEnabled[eggName] = false
					autoButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
					autoButton.Text = "Auto"
					break
				end
				task.wait(0.5)
			end
		end)
	else
		autoButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
		autoButton.Text = "Auto"
	end
end

-- ============================================
-- CREAR BILLBOARD PARA UN HUEVO
-- ============================================

local function createEggBillboard(eggPart, eggName, eggConfig)
	-- Obtener el Part para el Adornee
	local adorneePart = getAdorneePart(eggPart)

	-- BillboardGui en PlayerGui con Adornee (ESTO ES LA CLAVE PARA CLICKS)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EggShopBillboard_" .. eggName
	billboard.Size = UDim2.new(14, 0, 18, 0) -- Tamaño en studs (perspectiva natural)
	billboard.StudsOffset = Vector3.new(0, 8, 0)
	billboard.AlwaysOnTop = true
	billboard.Active = true
	billboard.ClipsDescendants = false
	billboard.MaxDistance = 50
	billboard.ResetOnSpawn = false
	billboard.Adornee = adorneePart -- Apunta al Part
	billboard.Enabled = false
	billboard.Parent = playerGui -- EN PLAYERGUI, NO EN EL PART

	-- Frame principal
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = Styles.Colors.Background
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = false -- No bloquear clicks a hijos
	mainFrame.Parent = billboard

	local mainCorner = Instance.new("UICorner")
	mainCorner.CornerRadius = UDim.new(0.05, 0)
	mainCorner.Parent = mainFrame

	local mainStroke = Instance.new("UIStroke")
	mainStroke.Color = Styles.Colors.Header
	mainStroke.Thickness = 4
	mainStroke.Parent = mainFrame

	-- Header
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.12, 0)
	header.BackgroundColor3 = Styles.Colors.Header
	header.BorderSizePixel = 0
	header.Parent = mainFrame

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0.3, 0)
	headerCorner.Parent = header

	-- Nombre
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
	nameLabel.Position = UDim2.new(0.02, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = eggConfig.Name
	nameLabel.Font = Styles.Fonts.Title
	nameLabel.TextScaled = true
	nameLabel.TextColor3 = Styles.Colors.TextDark
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.Parent = header

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 2
	nameStroke.Transparency = 0.3
	nameStroke.Parent = nameLabel

	-- Precio (con icono de Robux si aplica)
	local priceContainer = Instance.new("Frame")
	priceContainer.Name = "PriceContainer"
	priceContainer.Size = UDim2.new(0.4, 0, 1, 0)
	priceContainer.Position = UDim2.new(0.58, 0, 0, 0)
	priceContainer.BackgroundTransparency = 1
	priceContainer.Parent = header

	local priceLayout = Instance.new("UIListLayout")
	priceLayout.FillDirection = Enum.FillDirection.Horizontal
	priceLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	priceLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	priceLayout.Padding = UDim.new(0, 4)
	priceLayout.Parent = priceContainer

	-- Icono de Robux (solo si es compra con Robux)
	if eggConfig.CostRobux then
		local robuxIcon = Instance.new("ImageLabel")
		robuxIcon.Name = "RobuxIcon"
		robuxIcon.Size = UDim2.new(0, 24, 0, 24)
		robuxIcon.BackgroundTransparency = 1
		robuxIcon.Image = TextureManager.Icons.Robux
		robuxIcon.ScaleType = Enum.ScaleType.Fit
		robuxIcon.LayoutOrder = 1
		robuxIcon.Parent = priceContainer
	end

	local priceLabel = Instance.new("TextLabel")
	priceLabel.Name = "PriceLabel"
	priceLabel.Size = UDim2.new(0, 60, 1, 0)
	priceLabel.BackgroundTransparency = 1
	priceLabel.Text = eggConfig.CostRobux and tostring(eggConfig.CostRobux) or ("$ " .. eggConfig.Cost)
	priceLabel.Font = Styles.Fonts.Title
	priceLabel.TextScaled = true
	priceLabel.TextColor3 = Styles.Colors.TextDark
	priceLabel.TextXAlignment = Enum.TextXAlignment.Left
	priceLabel.LayoutOrder = 2
	priceLabel.Parent = priceContainer

	local priceStroke = Instance.new("UIStroke")
	priceStroke.Color = Color3.fromRGB(0, 0, 0)
	priceStroke.Thickness = 2
	priceStroke.Transparency = 0.3
	priceStroke.Parent = priceLabel

	-- Container de mascotas
	local petsContainer = Instance.new("Frame")
	petsContainer.Name = "PetsContainer"
	petsContainer.Size = UDim2.new(0.96, 0, 0.55, 0)
	petsContainer.Position = UDim2.new(0.02, 0, 0.14, 0)
	petsContainer.BackgroundTransparency = 1
	petsContainer.Parent = mainFrame

	local petsLayout = Instance.new("UIGridLayout")
	petsLayout.CellSize = UDim2.new(0.3, 0, 0.45, 0)
	petsLayout.CellPadding = UDim2.new(0.02, 0, 0.03, 0)
	petsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	petsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	petsLayout.Parent = petsContainer

	-- Crear tarjetas de mascotas
	local sortedPets = sortPetsByChance(eggConfig.Pets)
	for i, petData in ipairs(sortedPets) do
		local petConfig = Config.Pets[petData.name]
		if petConfig then
			local petCard = Instance.new("Frame")
			petCard.Name = petData.name
			petCard.BackgroundColor3 = RarityColors[petConfig.Rarity] or RarityColors.Common
			petCard.BorderSizePixel = 0
			petCard.LayoutOrder = i
			petCard.Parent = petsContainer

			local petCorner = Instance.new("UICorner")
			petCorner.CornerRadius = UDim.new(0.15, 0)
			petCorner.Parent = petCard

			-- Probabilidad
			local chanceLabel = Instance.new("TextLabel")
			chanceLabel.Size = UDim2.new(1, 0, 0.25, 0)
			chanceLabel.BackgroundTransparency = 1
			chanceLabel.Text = math.floor(petData.chance * 100) .. "%"
			chanceLabel.Font = Styles.Fonts.Body
			chanceLabel.TextScaled = true
			chanceLabel.TextColor3 = Styles.Colors.Text
			chanceLabel.Parent = petCard

			local chanceStroke = Instance.new("UIStroke")
			chanceStroke.Color = Color3.fromRGB(0, 0, 0)
			chanceStroke.Thickness = 2
			chanceStroke.Parent = chanceLabel

			-- Icono
			local petIcon = Instance.new("TextLabel")
			petIcon.Size = UDim2.new(1, 0, 0.5, 0)
			petIcon.Position = UDim2.new(0, 0, 0.2, 0)
			petIcon.BackgroundTransparency = 1
			petIcon.Text = petConfig.Icon
			petIcon.TextScaled = true
			petIcon.Parent = petCard

			-- Nombre
			local petNameLabel = Instance.new("TextLabel")
			petNameLabel.Size = UDim2.new(1, 0, 0.25, 0)
			petNameLabel.Position = UDim2.new(0, 0, 0.72, 0)
			petNameLabel.BackgroundTransparency = 1
			petNameLabel.Text = petConfig.Name
			petNameLabel.Font = Styles.Fonts.Body
			petNameLabel.TextScaled = true
			petNameLabel.TextColor3 = Styles.Colors.Text
			petNameLabel.Parent = petCard

			local petNameStroke = Instance.new("UIStroke")
			petNameStroke.Color = Color3.fromRGB(0, 0, 0)
			petNameStroke.Thickness = 2
			petNameStroke.Parent = petNameLabel
		end
	end

	-- Container de botones
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Name = "ButtonsContainer"
	buttonsContainer.Size = UDim2.new(0.96, 0, 0.15, 0)
	buttonsContainer.Position = UDim2.new(0.02, 0, 0.72, 0)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = mainFrame

	local buttonsLayout = Instance.new("UIListLayout")
	buttonsLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonsLayout.Padding = UDim.new(0.02, 0)
	buttonsLayout.Parent = buttonsContainer

	local btnColor = eggConfig.CostRobux and Styles.Colors.ButtonRobux or Styles.Colors.ButtonCoin
	local txtColor = eggConfig.CostRobux and Styles.Colors.Text or Styles.Colors.TextDark

	-- Botón x1
	local btnX1 = Instance.new("TextButton")
	btnX1.Name = "BtnX1"
	btnX1.Size = UDim2.new(0.28, 0, 1, 0)
	btnX1.BackgroundColor3 = btnColor
	btnX1.Text = "x1"
	btnX1.Font = Styles.Fonts.Body
	btnX1.TextScaled = true
	btnX1.TextColor3 = txtColor
	btnX1.AutoButtonColor = true
	btnX1.Parent = buttonsContainer
	Instance.new("UICorner", btnX1).CornerRadius = UDim.new(0.2, 0)

	local btnX1Stroke = Instance.new("UIStroke")
	btnX1Stroke.Color = Color3.fromRGB(0, 0, 0)
	btnX1Stroke.Thickness = 2
	btnX1Stroke.Parent = btnX1

	btnX1.Activated:Connect(function()
		buyEgg(eggName, 1)
	end)

	-- Botón x3
	local btnX3 = Instance.new("TextButton")
	btnX3.Name = "BtnX3"
	btnX3.Size = UDim2.new(0.28, 0, 1, 0)
	btnX3.BackgroundColor3 = btnColor
	btnX3.Text = "x3"
	btnX3.Font = Styles.Fonts.Body
	btnX3.TextScaled = true
	btnX3.TextColor3 = txtColor
	btnX3.AutoButtonColor = true
	btnX3.Parent = buttonsContainer
	Instance.new("UICorner", btnX3).CornerRadius = UDim.new(0.2, 0)

	local btnX3Stroke = Instance.new("UIStroke")
	btnX3Stroke.Color = Color3.fromRGB(0, 0, 0)
	btnX3Stroke.Thickness = 2
	btnX3Stroke.Parent = btnX3

	btnX3.Activated:Connect(function()
		buyEgg(eggName, 3)
	end)

	-- Botón Auto
	local btnAuto = Instance.new("TextButton")
	btnAuto.Name = "BtnAuto"
	btnAuto.Size = UDim2.new(0.35, 0, 1, 0)
	btnAuto.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	btnAuto.Text = "Auto"
	btnAuto.Font = Styles.Fonts.Body
	btnAuto.TextScaled = true
	btnAuto.TextColor3 = Styles.Colors.Text
	btnAuto.AutoButtonColor = true
	btnAuto.Parent = buttonsContainer
	Instance.new("UICorner", btnAuto).CornerRadius = UDim.new(0.2, 0)

	local btnAutoStroke = Instance.new("UIStroke")
	btnAutoStroke.Color = Color3.fromRGB(0, 0, 0)
	btnAutoStroke.Thickness = 2
	btnAutoStroke.Parent = btnAuto

	btnAuto.Activated:Connect(function()
		toggleAuto(eggName, btnAuto)
	end)

	-- Texto de ayuda
	local helpText = Instance.new("TextLabel")
	helpText.Size = UDim2.new(1, 0, 0.08, 0)
	helpText.Position = UDim2.new(0, 0, 0.9, 0)
	helpText.BackgroundTransparency = 1
	helpText.Text = "E: x1 | R: x3 | Y: Auto"
	helpText.Font = Styles.Fonts.Body
	helpText.TextScaled = true
	helpText.TextColor3 = Color3.fromRGB(150, 150, 170)
	helpText.Parent = mainFrame

	local helpStroke = Instance.new("UIStroke")
	helpStroke.Color = Color3.fromRGB(0, 0, 0)
	helpStroke.Thickness = 1
	helpStroke.Transparency = 0.3
	helpStroke.Parent = helpText

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

	-- Encontrar huevo más cercano
	for eggName, data in pairs(eggDisplays) do
		local partPos = getPartPosition(data.part)
		local distance = (partPos - playerPos).Magnitude

		if distance <= PROXIMITY_DISTANCE and distance < closestDistance then
			closestDistance = distance
			closestEgg = eggName
		end
	end

	-- Solo actualizar si cambió el huevo visible
	if closestEgg ~= currentVisibleEgg then
		-- Ocultar el anterior
		if currentVisibleEgg and eggDisplays[currentVisibleEgg] then
			eggDisplays[currentVisibleEgg].billboard.Enabled = false
		end

		-- Mostrar el nuevo
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

	-- Encontrar huevo visible
	local visibleEgg = currentVisibleEgg
	if not visibleEgg then return end

	if input.KeyCode == Enum.KeyCode.E then
		buyEgg(visibleEgg, 1)
	elseif input.KeyCode == Enum.KeyCode.R then
		buyEgg(visibleEgg, 3)
	elseif input.KeyCode == Enum.KeyCode.T then
		buyEgg(visibleEgg, 5)
	elseif input.KeyCode == Enum.KeyCode.Y then
		local data = eggDisplays[visibleEgg]
		local btnAuto = data.billboard:FindFirstChild("MainFrame")
			and data.billboard.MainFrame:FindFirstChild("ButtonsContainer")
			and data.billboard.MainFrame.ButtonsContainer:FindFirstChild("BtnAuto")
		if btnAuto then
			toggleAuto(visibleEgg, btnAuto)
		end
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

print("[EggShop] Sistema con BillboardGui clickeable inicializado")
