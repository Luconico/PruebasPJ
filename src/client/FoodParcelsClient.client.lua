--[[
	FoodParcelsClient.client.lua
	Sistema de parcelas de recoleccion - Cliente
	Cada jugador tiene sus propios items (locales)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar dependencias
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Esperar un poco para que el servidor cree los remotes
task.wait(2)

-- RemoteEvents
local CollectFoodParcelItem = Remotes:WaitForChild("CollectFoodParcelItem", 15)
local GetFoodParcelsInfo = Remotes:WaitForChild("GetFoodParcelsInfo", 15)

if not CollectFoodParcelItem or not GetFoodParcelsInfo then
	warn("[FoodParcelsClient] No se encontraron los RemoteEvents del servidor")
	return
end

local parcelConfig = Config.FoodParcels
local globalSettings = parcelConfig.GlobalSettings

-- ============================================
-- ESTADO LOCAL
-- ============================================
local parcelsData = {}       -- {parcelId = {Part, ParcelType, Position, Size}}
local activeItems = {}       -- {itemPart = itemData}
local itemIdCounter = 0
local isSystemReady = false

-- ============================================
-- UTILIDADES
-- ============================================

local function getRandomPointInParcel(parcelData)
	local size = parcelData.Size
	local pos = parcelData.Position

	-- Margen para no spawnar en los bordes
	local margin = 2
	local randomX = pos.X + (math.random() - 0.5) * math.max(size.X - margin * 2, 2)
	local randomZ = pos.Z + (math.random() - 0.5) * math.max(size.Z - margin * 2, 2)
	local y = pos.Y + (size.Y / 2) + globalSettings.ItemFloatHeight

	return Vector3.new(randomX, y, randomZ)
end

local function countItemsInParcel(parcelName)
	local count = 0
	for _, itemData in pairs(activeItems) do
		if itemData.ParcelName == parcelName then
			count = count + 1
		end
	end
	return count
end

-- ============================================
-- CREAR ITEM VISUAL
-- ============================================

local function createFoodItem(parcelName)
	local parcelData = parcelsData[parcelName]
	if not parcelData then return nil end

	local parcelType = parcelData.ParcelType
	local typeConfig = parcelConfig.ParcelTypes[parcelType]
	if not typeConfig then return nil end

	-- Verificar limite de items
	if countItemsInParcel(parcelName) >= typeConfig.MaxItems then
		return nil
	end

	-- Crear ID unico
	itemIdCounter = itemIdCounter + 1
	local itemId = "FoodItem_" .. itemIdCounter

	local spawnPos = getRandomPointInParcel(parcelData)

	-- Crear Part para colision (pequeña, invisible)
	local itemPart = Instance.new("Part")
	itemPart.Name = itemId
	itemPart.Size = Vector3.new(3, 3, 3)
	itemPart.Position = spawnPos
	itemPart.Anchored = true
	itemPart.CanCollide = false
	itemPart.Transparency = 1
	itemPart.Parent = workspace

	-- BillboardGui con emoji (tamaño fijo, no escala con distancia)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ItemBillboard"
	billboard.Size = UDim2.new(4, 0, 4, 0) -- Tamaño en studs (fijo)
	billboard.StudsOffset = Vector3.new(0, 1, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 150
	billboard.Parent = itemPart

	-- Emoji directamente (sin contenedor con fondo)
	local emojiLabel = Instance.new("TextLabel")
	emojiLabel.Name = "Emoji"
	emojiLabel.Size = UDim2.new(1, 0, 1, 0)
	emojiLabel.BackgroundTransparency = 1
	emojiLabel.Text = typeConfig.Icon
	emojiLabel.TextScaled = true
	emojiLabel.TextStrokeTransparency = 0.5
	emojiLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	emojiLabel.Parent = billboard

	-- Guardar datos del item
	local itemData = {
		Id = itemId,
		Part = itemPart,
		Billboard = billboard,
		ParcelName = parcelName,
		ParcelType = parcelType,
		Config = typeConfig,
		SpawnTime = tick(),
		OriginalY = spawnPos.Y,
		Collected = false,
	}
	activeItems[itemPart] = itemData

	-- Animacion de aparicion
	emojiLabel.TextTransparency = 1
	TweenService:Create(emojiLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextTransparency = 0
	}):Play()

	-- Conectar touch para coleccion
	itemPart.Touched:Connect(function(otherPart)
		local touchPlayer = Players:GetPlayerFromCharacter(otherPart.Parent)
		if touchPlayer == player and not itemData.Collected then
			collectItem(itemPart)
		end
	end)

	return itemData
end

-- ============================================
-- COLECTAR ITEM
-- ============================================

function collectItem(itemPart)
	local itemData = activeItems[itemPart]
	if not itemData or itemData.Collected then return end

	itemData.Collected = true

	local typeConfig = itemData.Config
	local position = itemPart.Position

	-- Notificar servidor para monedas
	CollectFoodParcelItem:FireServer(itemData.ParcelType, position)

	-- Aplicar gas bonus localmente
	if _G.FoodParcelGasBonus then
		_G.FoodParcelGasBonus(typeConfig.GasBonus)
	end

	-- Efectos visuales
	showCollectionEffect(position, itemData.ParcelType, typeConfig.GasBonus, typeConfig.CoinsBonus)

	-- Sonido
	SoundManager.play("CashRegister", 0.4, 1.0 + math.random() * 0.2)
	if typeConfig.Rarity == "rare" or typeConfig.Rarity == "epic" or typeConfig.Rarity == "legendary" then
		task.delay(0.1, function()
			SoundManager.play("Sparkle", 0.5, 1.0)
		end)
	end

	-- Animacion de desaparicion
	local emoji = itemData.Billboard:FindFirstChild("Emoji")
	if emoji then
		TweenService:Create(emoji, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1
		}):Play()
	end

	-- Destruir y programar respawn
	task.delay(0.25, function()
		activeItems[itemPart] = nil
		itemPart:Destroy()

		-- Respawn despues del tiempo configurado
		task.delay(globalSettings.RespawnTime, function()
			if parcelsData[itemData.ParcelName] then
				createFoodItem(itemData.ParcelName)
			end
		end)
	end)
end

-- ============================================
-- EFECTO DE COLECCION
-- ============================================

function showCollectionEffect(position, parcelType, gasBonus, coinsBonus)
	local typeConfig = parcelConfig.ParcelTypes[parcelType]
	if not typeConfig then return end

	local rarityConfig = parcelConfig.RarityEffects[typeConfig.Rarity]

	-- Crear ScreenGui si no existe
	local screenGui = playerGui:FindFirstChild("FoodParcelEffects")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "FoodParcelEffects"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end

	local camera = workspace.CurrentCamera
	local screenPos, onScreen = camera:WorldToScreenPoint(position)
	if not onScreen then return end

	-- Texto flotante de gas
	local gasFloater = Instance.new("TextLabel")
	gasFloater.Size = UDim2.new(0, 150, 0, 40)
	gasFloater.Position = UDim2.new(0, screenPos.X - 75, 0, screenPos.Y - 20)
	gasFloater.BackgroundTransparency = 1
	gasFloater.Text = string.format("+%.0f%% Gas", gasBonus * 100)
	gasFloater.TextColor3 = Color3.fromRGB(100, 255, 100)
	gasFloater.TextScaled = true
	gasFloater.Font = Enum.Font.FredokaOne
	gasFloater.TextStrokeTransparency = 0
	gasFloater.TextStrokeColor3 = Color3.new(0, 0, 0)
	gasFloater.Parent = screenGui

	-- Texto flotante de monedas
	local coinsFloater = Instance.new("TextLabel")
	coinsFloater.Size = UDim2.new(0, 150, 0, 40)
	coinsFloater.Position = UDim2.new(0, screenPos.X - 75, 0, screenPos.Y + 15)
	coinsFloater.BackgroundTransparency = 1
	coinsFloater.Text = string.format("+%d Coins", coinsBonus)
	coinsFloater.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsFloater.TextScaled = true
	coinsFloater.Font = Enum.Font.FredokaOne
	coinsFloater.TextStrokeTransparency = 0
	coinsFloater.TextStrokeColor3 = Color3.new(0, 0, 0)
	coinsFloater.Parent = screenGui

	-- Animacion hacia arriba + fade (gas)
	TweenService:Create(gasFloater, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, screenPos.X - 75, 0, screenPos.Y - 80),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	}):Play()

	-- Animacion hacia arriba + fade (coins)
	TweenService:Create(coinsFloater, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, screenPos.X - 75, 0, screenPos.Y - 45),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	}):Play()

	-- Particulas en el mundo
	local particleAnchor = Instance.new("Part")
	particleAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
	particleAnchor.Position = position
	particleAnchor.Anchored = true
	particleAnchor.CanCollide = false
	particleAnchor.Transparency = 1
	particleAnchor.Parent = workspace

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(rarityConfig and rarityConfig.ParticleColor or Color3.new(1, 1, 1))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Rate = 0
	particles.Parent = particleAnchor

	particles:Emit(12)

	-- Limpiar
	task.delay(1.5, function()
		gasFloater:Destroy()
		coinsFloater:Destroy()
		particleAnchor:Destroy()
	end)
end

-- ============================================
-- ANIMACION IDLE DE ITEMS (flotacion)
-- ============================================

local function updateItemAnimations()
	local currentTime = tick()

	for itemPart, itemData in pairs(activeItems) do
		if itemPart and itemPart.Parent and not itemData.Collected then
			local elapsed = currentTime - itemData.SpawnTime

			-- Flotacion (bobbing)
			local bobOffset = math.sin(elapsed * globalSettings.ItemBobSpeed) * globalSettings.ItemBobAmount
			local newY = itemData.OriginalY + bobOffset

			itemPart.Position = Vector3.new(
				itemPart.Position.X,
				newY,
				itemPart.Position.Z
			)
		end
	end
end

-- ============================================
-- LOOP DE SPAWN
-- ============================================

local function spawnLoop()
	while true do
		task.wait(globalSettings.SpawnInterval)

		if not isSystemReady then continue end

		for parcelName, parcelData in pairs(parcelsData) do
			local typeConfig = parcelConfig.ParcelTypes[parcelData.ParcelType]
			if typeConfig then
				local currentCount = countItemsInParcel(parcelName)
				if currentCount < typeConfig.MaxItems then
					createFoodItem(parcelName)
				end
			end
		end
	end
end

-- ============================================
-- INICIALIZACION
-- ============================================

local function initialize()
	print("[FoodParcelsClient] Iniciando sistema...")

	-- Esperar a que el jugador tenga personaje
	if not player.Character then
		player.CharacterAdded:Wait()
	end

	task.wait(1)

	-- Obtener info de parcelas del servidor
	print("[FoodParcelsClient] Solicitando parcelas...")
	local parcelsInfo = GetFoodParcelsInfo:InvokeServer()

	if not parcelsInfo then
		warn("[FoodParcelsClient] Servidor no respondio")
		return
	end

	local count = 0
	for _ in pairs(parcelsInfo) do count = count + 1 end
	print("[FoodParcelsClient] Parcelas del servidor:", count)

	if count == 0 then
		warn("[FoodParcelsClient] No hay parcelas")
		return
	end

	-- Buscar las Parts en el Workspace
	local parcelsFolder = workspace:WaitForChild("FoodParcels", 10)
	if not parcelsFolder then
		warn("[FoodParcelsClient] No existe FoodParcels en Workspace")
		return
	end

	-- Buscar parcelas por su ParcelId (permite multiples con mismo nombre)
	for parcelId, info in pairs(parcelsInfo) do
		local foundPart = nil

		-- Buscar el Part que tenga este ParcelId
		for _, child in ipairs(parcelsFolder:GetChildren()) do
			if child:IsA("BasePart") and child:GetAttribute("ParcelId") == parcelId then
				foundPart = child
				break
			end
		end

		if foundPart then
			parcelsData[parcelId] = {
				Part = foundPart,
				ParcelType = info.ParcelType,
				Position = info.Position,
				Size = info.Size,
			}
			print("[FoodParcelsClient] Parcela:", parcelId, "(", foundPart.Name, ")")
		else
			warn("[FoodParcelsClient] Part no encontrada con ParcelId:", parcelId)
		end
	end

	-- Spawn inicial de items
	local parcelCount = 0
	for parcelName, parcelData in pairs(parcelsData) do
		parcelCount = parcelCount + 1
		local typeConfig = parcelConfig.ParcelTypes[parcelData.ParcelType]
		if typeConfig then
			-- Spawn mitad de los items inicialmente
			local initialCount = math.ceil(typeConfig.MaxItems / 2)
			for i = 1, initialCount do
				task.delay(i * 0.3, function()
					createFoodItem(parcelName)
				end)
			end
		end
	end

	isSystemReady = true

	print("[FoodParcelsClient] Sistema inicializado")
	print("[FoodParcelsClient] Parcelas activas:", parcelCount)
end

-- Conectar animacion
RunService.RenderStepped:Connect(updateItemAnimations)

-- Iniciar spawn loop en background
task.spawn(spawnLoop)

-- Inicializar sistema
task.spawn(initialize)
