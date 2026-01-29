--[[
	FoodParcels.server.lua
	Sistema de parcelas de recoleccion de comida
	Los items son locales por jugador (cada uno tiene los suyos)
	Servidor valida colecciones y da monedas

	Las parcelas se generan automaticamente si no existen
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar dependencias
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Esperar ServerFunctions para modificar datos del jugador
local serverFolder = ReplicatedStorage:WaitForChild("ServerFunctions", 30)
local modifyCoinsServer = serverFolder and serverFolder:WaitForChild("ModifyCoinsServer", 10)

-- ============================================
-- CREAR REMOTES
-- ============================================
local CollectFoodParcelItem = Instance.new("RemoteEvent")
CollectFoodParcelItem.Name = "CollectFoodParcelItem"
CollectFoodParcelItem.Parent = Remotes

local GetFoodParcelsInfo = Instance.new("RemoteFunction")
GetFoodParcelsInfo.Name = "GetFoodParcelsInfo"
GetFoodParcelsInfo.Parent = Remotes

-- ============================================
-- ESTADO DEL SISTEMA
-- ============================================
local parcelsInfo = {} -- {parcelId = {Part, ParcelType, Position, Size}}
local parcelIdCounter = 0

local parcelConfig = Config.FoodParcels
local globalSettings = parcelConfig.GlobalSettings

-- Cooldown anti-spam por jugador
local playerCollectionCooldown = {}
local COLLECTION_COOLDOWN = 0.15 -- 150ms entre colecciones

-- ============================================
-- CONFIGURACION DE PARCELAS POR DEFECTO
-- ============================================
local DEFAULT_PARCELS = {
	{
		Name = "LettucePatch",
		ParcelType = "Lettuce",
		Position = Vector3.new(50, 1, 30),
		Size = Vector3.new(25, 2, 25),
	},
	{
		Name = "BurgerField",
		ParcelType = "Burger",
		Position = Vector3.new(-50, 1, 30),
		Size = Vector3.new(22, 2, 22),
	},
	{
		Name = "PizzaParadise",
		ParcelType = "Pizza",
		Position = Vector3.new(50, 1, -40),
		Size = Vector3.new(20, 2, 20),
	},
	{
		Name = "HotDogHaven",
		ParcelType = "HotDog",
		Position = Vector3.new(-50, 1, -40),
		Size = Vector3.new(18, 2, 18),
	},
	{
		Name = "GoldenFeast",
		ParcelType = "GoldenBurger",
		Position = Vector3.new(0, 1, -80),
		Size = Vector3.new(15, 2, 15),
	},
}

-- ============================================
-- CREAR PARCELA VISUAL
-- ============================================

local function createParcelPart(parcelData, parent)
	local typeConfig = parcelConfig.ParcelTypes[parcelData.ParcelType]
	if not typeConfig then return nil end

	local part = Instance.new("Part")
	part.Name = parcelData.Name
	part.Size = parcelData.Size
	part.Position = parcelData.Position
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1 -- Completamente invisible
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part:SetAttribute("ParcelType", parcelData.ParcelType)
	part.Parent = parent

	-- Borde sutil para indicar zona (opcional)
	local highlight = Instance.new("SelectionBox")
	highlight.Name = "Border"
	highlight.Adornee = part
	highlight.Color3 = typeConfig.Color
	highlight.LineThickness = 0.03
	highlight.Transparency = 0.6
	highlight.Parent = part

	return part
end

-- ============================================
-- GENERAR PARCELAS SI NO EXISTEN
-- ============================================

local function generateDefaultParcels()
	local parcelsFolder = workspace:FindFirstChild("FoodParcels")

	-- Crear carpeta si no existe
	if not parcelsFolder then
		parcelsFolder = Instance.new("Folder")
		parcelsFolder.Name = "FoodParcels"
		parcelsFolder.Parent = workspace
		print("[FoodParcels] Carpeta FoodParcels creada")
	end

	-- Verificar si ya hay parcelas
	local existingParcels = {}
	for _, child in ipairs(parcelsFolder:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("ParcelType") then
			existingParcels[child:GetAttribute("ParcelType")] = true
		end
	end

	-- Crear parcelas que faltan
	local createdCount = 0
	for _, parcelData in ipairs(DEFAULT_PARCELS) do
		if not existingParcels[parcelData.ParcelType] then
			local part = createParcelPart(parcelData, parcelsFolder)
			if part then
				createdCount = createdCount + 1
				print("[FoodParcels] Parcela generada:", parcelData.Name, "->", parcelData.ParcelType)
			end
		end
	end

	if createdCount > 0 then
		print("[FoodParcels] Total parcelas generadas:", createdCount)
	end

	return parcelsFolder
end

-- ============================================
-- BUSCAR/REGISTRAR PARCELAS EN WORKSPACE
-- ============================================

local function findParcelsInWorkspace()
	-- Generar parcelas si no existen
	local parcelsFolder = generateDefaultParcels()

	for _, child in ipairs(parcelsFolder:GetChildren()) do
		if child:IsA("BasePart") then
			local parcelType = child:GetAttribute("ParcelType")
			if parcelType and parcelConfig.ParcelTypes[parcelType] then
				-- Generar ID unico para cada parcela
				parcelIdCounter = parcelIdCounter + 1
				local parcelId = "Parcel_" .. parcelIdCounter

				-- Guardar el ID en el Part para referencia
				child:SetAttribute("ParcelId", parcelId)

				parcelsInfo[parcelId] = {
					Part = child,
					ParcelType = parcelType,
					Position = child.Position,
					Size = child.Size,
				}
				print("[FoodParcels] Parcela registrada:", parcelId, "(", child.Name, ") ->", parcelType)
			else
				warn("[FoodParcels] Parcela sin tipo valido:", child.Name, "ParcelType:", parcelType)
			end
		end
	end
end

-- ============================================
-- REMOTE FUNCTION: Obtener info de parcelas
-- ============================================

GetFoodParcelsInfo.OnServerInvoke = function(player)
	local info = {}
	for parcelName, data in pairs(parcelsInfo) do
		info[parcelName] = {
			ParcelType = data.ParcelType,
			Position = data.Position,
			Size = data.Size,
		}
	end
	return info
end

-- ============================================
-- REMOTE EVENT: Coleccion de item
-- ============================================

CollectFoodParcelItem.OnServerEvent:Connect(function(player, parcelType, itemPosition)
	-- Validar tipo de parcela
	local typeConfig = parcelConfig.ParcelTypes[parcelType]
	if not typeConfig then
		warn("[FoodParcels] Tipo de parcela invalido:", parcelType)
		return
	end

	-- Cooldown anti-spam
	local lastCollection = playerCollectionCooldown[player.UserId] or 0
	if tick() - lastCollection < COLLECTION_COOLDOWN then
		return -- Silenciosamente ignorar spam
	end
	playerCollectionCooldown[player.UserId] = tick()

	-- Validar que el jugador este cerca (anti-cheat basico)
	local character = player.Character
	if not character then return end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	-- Margen generoso para lag de red
	local distance = (rootPart.Position - itemPosition).Magnitude
	if distance > globalSettings.CollectionRadius + 15 then
		warn("[FoodParcels] Distancia sospechosa:", player.Name, distance)
		return
	end

	-- Dar monedas
	if modifyCoinsServer then
		modifyCoinsServer:Invoke(player, typeConfig.CoinsBonus)
	end
end)

-- ============================================
-- LIMPIAR COOLDOWNS AL SALIR JUGADOR
-- ============================================

Players.PlayerRemoving:Connect(function(player)
	playerCollectionCooldown[player.UserId] = nil
end)

-- ============================================
-- INICIALIZACION
-- ============================================

task.wait(1) -- Esperar a que cargue Workspace
findParcelsInWorkspace()

local parcelCount = 0
for _ in pairs(parcelsInfo) do
	parcelCount = parcelCount + 1
end

print("[FoodParcels] Sistema de servidor inicializado")
print("[FoodParcels] Parcelas activas:", parcelCount)
