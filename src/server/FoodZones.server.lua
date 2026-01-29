--[[
	FoodZones.server.lua
	Gestiona las zonas de comida en el lobby
	Detecta cuando un jugador está cerca de comida y notifica al cliente
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Esperar dependencias
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Crear RemoteEvents adicionales para comida
local OnFoodZoneEnter = Instance.new("RemoteEvent")
OnFoodZoneEnter.Name = "OnFoodZoneEnter"
OnFoodZoneEnter.Parent = Remotes

local OnFoodZoneExit = Instance.new("RemoteEvent")
OnFoodZoneExit.Name = "OnFoodZoneExit"
OnFoodZoneExit.Parent = Remotes

-- ============================================
-- CONFIGURACIÓN DE ZONAS DE COMIDA
-- ============================================

-- Las zonas de comida se definen por posición y radio
-- En producción, esto vendría de objetos en Workspace
local foodZones = {
	{
		Name = "Salad",
		Position = Vector3.new(-20, 0, -20),
		Radius = 5,
		FoodType = "Salad",
	},
	{
		Name = "Burger",
		Position = Vector3.new(-10, 0, -20),
		Radius = 5,
		FoodType = "Burger",
	},
	{
		Name = "Pizza",
		Position = Vector3.new(0, 0, -20),
		Radius = 5,
		FoodType = "Pizza",
	},
	{
		Name = "HotDog",
		Position = Vector3.new(10, 0, -20),
		Radius = 5,
		FoodType = "HotDog",
	},
	{
		Name = "GoldenBurger",
		Position = Vector3.new(20, 0, -20),
		Radius = 5,
		FoodType = "GoldenBurger",
	},
}

-- Estado de cada jugador (en qué zona de comida está)
local playerFoodZone = {}

-- ============================================
-- FUNCIONES
-- ============================================

-- Verificar si el jugador tiene desbloqueada una comida
local function hasUnlockedFood(player, foodType)
	local GetPlayerData = Remotes:FindFirstChild("GetPlayerData")
	if not GetPlayerData then return false end

	-- La ensalada siempre está desbloqueada
	if foodType == "Salad" then return true end

	-- Por ahora, asumimos que tienen todo desbloqueado para testing
	-- En producción, esto consultaría PlayerData directamente
	-- TODO: Verificar en playerDataCache si el jugador tiene la comida desbloqueada
	return true
end

-- Buscar zonas de comida en Workspace (para zonas creadas manualmente)
local function findFoodZonesInWorkspace()
	local foodFolder = workspace:FindFirstChild("FoodZones")
	if not foodFolder then
		-- Crear carpeta y zonas de ejemplo
		foodFolder = Instance.new("Folder")
		foodFolder.Name = "FoodZones"
		foodFolder.Parent = workspace

		-- Crear zonas visuales de ejemplo
		for _, zoneData in ipairs(foodZones) do
			local zone = Instance.new("Part")
			zone.Name = zoneData.Name
			zone.Size = Vector3.new(zoneData.Radius * 2, 1, zoneData.Radius * 2)
			zone.Position = zoneData.Position + Vector3.new(0, 0.5, 0)
			zone.Anchored = true
			zone.CanCollide = false
			zone.Transparency = 0.7
			zone.BrickColor = BrickColor.new("Bright green")
			zone.Parent = foodFolder

			-- Añadir etiqueta
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(0, 100, 0, 40)
			billboard.StudsOffset = Vector3.new(0, 3, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = zone

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = Config.Food[zoneData.FoodType] and Config.Food[zoneData.FoodType].Name or zoneData.Name
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.Parent = billboard

			-- Guardar tipo de comida como atributo
			zone:SetAttribute("FoodType", zoneData.FoodType)
		end
	end

	-- Leer zonas del workspace
	local zones = {}
	for _, child in ipairs(foodFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local foodType = child:GetAttribute("FoodType")
			if foodType then
				table.insert(zones, {
					Name = child.Name,
					Position = child.Position,
					Radius = math.max(child.Size.X, child.Size.Z) / 2,
					FoodType = foodType,
					Part = child,
				})
			end
		end
	end

	return zones
end

-- Verificar en qué zona de comida está un jugador
local function getPlayerFoodZone(player)
	local character = player.Character
	if not character then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local playerPos = rootPart.Position

	for _, zone in ipairs(foodZones) do
		local distance = (Vector3.new(playerPos.X, zone.Position.Y, playerPos.Z) - zone.Position).Magnitude
		if distance <= zone.Radius then
			return zone
		end
	end

	return nil
end

-- ============================================
-- LOOP PRINCIPAL
-- ============================================

-- Actualizar zonas desde workspace
foodZones = findFoodZonesInWorkspace()

-- Verificar jugadores periódicamente
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local currentZone = getPlayerFoodZone(player)
		local previousZone = playerFoodZone[player]

		-- Comparar por FoodType en lugar de por referencia de tabla
		local currentFoodType = currentZone and currentZone.FoodType or nil
		local previousFoodType = previousZone and previousZone.FoodType or nil

		if currentFoodType ~= previousFoodType then
			-- Salió de la zona anterior
			if previousZone then
				OnFoodZoneExit:FireClient(player, previousZone.FoodType)
				print("[FoodZones] Jugador salió de:", previousZone.FoodType)
			end

			-- Entró a nueva zona
			if currentZone then
				local foodConfig = Config.Food[currentZone.FoodType]
				if foodConfig then
					OnFoodZoneEnter:FireClient(player, currentZone.FoodType, foodConfig)
					print("[FoodZones] Jugador entró a:", currentZone.FoodType)
				end
			end

			playerFoodZone[player] = currentZone
		end
	end
end)

-- Limpiar cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	playerFoodZone[player] = nil
end)

print("[FoodZones] Sistema de zonas de comida inicializado")
print("[FoodZones] Zonas encontradas:", #foodZones)
