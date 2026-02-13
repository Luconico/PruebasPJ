--[[
	FoodZones.server.lua
	Gestiona las zonas de comida en el lobby
	Crea carteles visuales cartoon con botón de compra
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

-- Esperar dependencias
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RobuxManager = require(Shared:WaitForChild("RobuxManager"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Crear RemoteEvents
local OnFoodZoneEnter = Remotes:FindFirstChild("OnFoodZoneEnter")
if not OnFoodZoneEnter then
	OnFoodZoneEnter = Instance.new("RemoteEvent")
	OnFoodZoneEnter.Name = "OnFoodZoneEnter"
	OnFoodZoneEnter.Parent = Remotes
end

local OnFoodZoneExit = Remotes:FindFirstChild("OnFoodZoneExit")
if not OnFoodZoneExit then
	OnFoodZoneExit = Instance.new("RemoteEvent")
	OnFoodZoneExit.Name = "OnFoodZoneExit"
	OnFoodZoneExit.Parent = Remotes
end

-- RemoteEvent para compra de comida desde carteles
local BuyFoodFromSign = Remotes:FindFirstChild("BuyFoodFromSign")
if not BuyFoodFromSign then
	BuyFoodFromSign = Instance.new("RemoteEvent")
	BuyFoodFromSign.Name = "BuyFoodFromSign"
	BuyFoodFromSign.Parent = Remotes
end

-- RemoteEvent para notificar compra exitosa
local OnFoodPurchased = Remotes:FindFirstChild("OnFoodPurchased")
if not OnFoodPurchased then
	OnFoodPurchased = Instance.new("RemoteEvent")
	OnFoodPurchased.Name = "OnFoodPurchased"
	OnFoodPurchased.Parent = Remotes
end

-- RemoteFunction para consultar comidas desbloqueadas
local GetUnlockedFoods = Remotes:FindFirstChild("GetUnlockedFoods")
if not GetUnlockedFoods then
	GetUnlockedFoods = Instance.new("RemoteFunction")
	GetUnlockedFoods.Name = "GetUnlockedFoods"
	GetUnlockedFoods.Parent = Remotes
end

-- Esperar ServerFunctions
local serverFolder = ReplicatedStorage:WaitForChild("ServerFunctions", 30)
local hasFoodUnlocked = serverFolder and serverFolder:WaitForChild("HasFoodUnlocked", 10)
local unlockFoodServer = serverFolder and serverFolder:WaitForChild("UnlockFoodServer", 10)

-- Estado de cada jugador
local playerFoodZone = {}
local foodZones = {}

-- Verificar si jugador tiene comida desbloqueada
local function playerHasFood(player, foodType)
	if foodType == "Salad" then return true end
	if hasFoodUnlocked then
		return hasFoodUnlocked:Invoke(player, foodType)
	end
	return false
end

-- ============================================
-- CARTELES VISUALES CON BOTÓN DE COMPRA
-- ============================================

local function createFoodSign(zonePart, foodType)
	local foodConfig = Config.Food[foodType]
	if not foodConfig then return end

	-- Eliminar cartel existente
	local existingSign = zonePart:FindFirstChild("FoodSign")
	if existingSign then
		existingSign:Destroy()
	end

	-- BillboardGui principal
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FoodSign"
	billboard.Size = UDim2.new(0, 200, 0, 160)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = zonePart

	-- Frame principal
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundColor3 = foodConfig.Color
	mainFrame.BorderSizePixel = 0
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

	-- Gradiente 3D
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
	})
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.7),
		NumberSequenceKeypoint.new(0.3, 0.85),
		NumberSequenceKeypoint.new(1, 0.7)
	})
	gradient.Rotation = 90
	gradient.Parent = mainFrame

	-- Icono grande
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, 0, 0.35, 0)
	iconLabel.Position = UDim2.new(0, 0, 0.02, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = foodConfig.Icon or "🍽️"
	iconLabel.TextScaled = true
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Parent = mainFrame

	-- Nombre
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "FoodName"
	nameLabel.Size = UDim2.new(1, -10, 0.18, 0)
	nameLabel.Position = UDim2.new(0, 5, 0.35, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = foodConfig.Name
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextStrokeColor3 = Color3.fromRGB(50, 50, 50)
	nameLabel.TextStrokeTransparency = 0
	nameLabel.Parent = mainFrame

	-- Velocidad
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "Speed"
	speedLabel.Size = UDim2.new(1, -10, 0.15, 0)
	speedLabel.Position = UDim2.new(0, 5, 0.52, 0)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: x" .. (foodConfig.SpeedMultiplier or 1)
	speedLabel.TextScaled = true
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextStrokeColor3 = Color3.fromRGB(0, 100, 0)
	speedLabel.TextStrokeTransparency = 0
	speedLabel.Parent = mainFrame

	-- Botón de compra (solo si no es gratis)
	if foodConfig.CostRobux > 0 then
		local buyButton = Instance.new("TextButton")
		buyButton.Name = "BuyButton"
		buyButton.Size = UDim2.new(0.9, 0, 0.22, 0)
		buyButton.Position = UDim2.new(0.05, 0, 0.72, 0)
		buyButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		buyButton.BorderSizePixel = 0
		buyButton.Text = "BUY " .. foodConfig.CostRobux .. " R$"
		buyButton.TextScaled = true
		buyButton.Font = Enum.Font.GothamBold
		buyButton.TextColor3 = Color3.new(1, 1, 1)
		buyButton.AutoButtonColor = true
		buyButton.Parent = mainFrame

		-- Guardar el tipo de comida en el botón
		buyButton:SetAttribute("FoodType", foodType)

		local btnCorner = Instance.new("UICorner")
		btnCorner.CornerRadius = UDim.new(0, 10)
		btnCorner.Parent = buyButton

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = Color3.fromRGB(0, 100, 50)
		btnStroke.Thickness = 3
		btnStroke.Parent = buyButton
	else
		-- Si es gratis, mostrar FREE
		local freeLabel = Instance.new("TextLabel")
		freeLabel.Name = "FreeLabel"
		freeLabel.Size = UDim2.new(0.9, 0, 0.22, 0)
		freeLabel.Position = UDim2.new(0.05, 0, 0.72, 0)
		freeLabel.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		freeLabel.BorderSizePixel = 0
		freeLabel.Text = "FREE!"
		freeLabel.TextScaled = true
		freeLabel.Font = Enum.Font.GothamBold
		freeLabel.TextColor3 = Color3.new(1, 1, 1)
		freeLabel.Parent = mainFrame

		local freeCorner = Instance.new("UICorner")
		freeCorner.CornerRadius = UDim.new(0, 10)
		freeCorner.Parent = freeLabel
	end

	print("[FoodZones] Cartel creado para:", foodType)
end

-- ============================================
-- BUSCAR ZONAS EN WORKSPACE
-- ============================================

local function findFoodZonesInWorkspace()
	local foodFolder = workspace:FindFirstChild("FoodZones")
	if not foodFolder then
		warn("[FoodZones] No se encontró carpeta FoodZones en Workspace")
		return {}
	end

	local zones = {}
	for _, child in ipairs(foodFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local foodType = child:GetAttribute("FoodType")
			if foodType and Config.Food[foodType] then
				table.insert(zones, {
					Name = child.Name,
					Position = child.Position,
					Size = child.Size,
					FoodType = foodType,
					Part = child,
				})
				-- Los carteles se crean en el cliente (FoodShop.client.lua)
			end
		end
	end

	return zones
end

-- ============================================
-- DETECCIÓN DE ZONAS
-- ============================================

local function isPointInZone(point, zone)
	local zonePos = zone.Position
	local zoneSize = zone.Size
	local halfX = zoneSize.X / 2
	local halfZ = zoneSize.Z / 2

	return point.X >= zonePos.X - halfX and point.X <= zonePos.X + halfX
		and point.Z >= zonePos.Z - halfZ and point.Z <= zonePos.Z + halfZ
end

local function getPlayerFoodZone(player)
	local character = player.Character
	if not character then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local playerPos = rootPart.Position

	for _, zone in ipairs(foodZones) do
		if isPointInZone(playerPos, zone) then
			return zone
		end
	end

	return nil
end

-- ============================================
-- COMPRA DE COMIDA
-- ============================================

BuyFoodFromSign.OnServerEvent:Connect(function(player, foodType)
	print("[FoodZones] Solicitud de compra:", player.Name, "->", foodType)

	local foodConfig = Config.Food[foodType]
	if not foodConfig then
		warn("[FoodZones] Comida no existe:", foodType)
		return
	end

	-- Verificar si ya la tiene
	if playerHasFood(player, foodType) then
		warn("[FoodZones] Ya tiene esta comida:", player.Name, foodType)
		return
	end

	-- Si es gratis, desbloquear directamente
	if foodConfig.CostRobux == 0 then
		if unlockFoodServer then
			unlockFoodServer:Invoke(player, foodType)
			OnFoodPurchased:FireClient(player, foodType, true)
		end
		return
	end

	-- Compra con Robux - obtener DevProductId desde RobuxManager
	local robuxProduct = RobuxManager.Foods[foodType]
	local productId = robuxProduct and robuxProduct.DevProductId or 0

	if not productId or productId == 0 then
		-- Modo de prueba: desbloquear gratis
		warn("[FoodZones] DevProductId no configurado para " .. foodType .. " - desbloqueando gratis para testing")
		if unlockFoodServer then
			unlockFoodServer:Invoke(player, foodType)
			OnFoodPurchased:FireClient(player, foodType, true)
		end
		return
	end

	-- Prompt de compra real con Robux (ProcessReceipt en PlayerData manejará el resultado)
	local success, errorMessage = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)

	if not success then
		warn("[FoodZones] Error al iniciar compra:", errorMessage)
	end
end)

-- ============================================
-- CONSULTAR COMIDAS DESBLOQUEADAS
-- ============================================

GetUnlockedFoods.OnServerInvoke = function(player)
	local unlockedFoods = {}
	for foodType, _ in pairs(Config.Food) do
		if playerHasFood(player, foodType) then
			unlockedFoods[foodType] = true
		end
	end
	return unlockedFoods
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

task.wait(1)
foodZones = findFoodZonesInWorkspace()

print("[FoodZones] Sistema inicializado")
print("[FoodZones] Zonas encontradas:", #foodZones)

-- ============================================
-- LOOP PRINCIPAL
-- ============================================

RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local currentZone = getPlayerFoodZone(player)
		local previousZone = playerFoodZone[player]

		local currentFoodType = currentZone and currentZone.FoodType or nil
		local previousFoodType = previousZone and previousZone.FoodType or nil

		if currentFoodType ~= previousFoodType then
			if previousZone then
				OnFoodZoneExit:FireClient(player, previousZone.FoodType)
			end

			if currentZone then
				local foodConfig = Config.Food[currentZone.FoodType]
				if foodConfig then
					local isUnlocked = playerHasFood(player, currentZone.FoodType)
					OnFoodZoneEnter:FireClient(player, currentZone.FoodType, foodConfig, isUnlocked)
				end
			end

			playerFoodZone[player] = currentZone
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	playerFoodZone[player] = nil
end)
