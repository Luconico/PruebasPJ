--[[
	PlayerData.server.lua
	Player data management system
	Server authority to prevent cheats
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

-- Wait for Shared to exist
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local RobuxManager = require(Shared:WaitForChild("RobuxManager"))

-- Cargar PetManager (está en la misma carpeta Server)
local PetManager = require(script.Parent.PetManager)
print("[PlayerData] ✓ PetManager loaded successfully")
print("[PlayerData] ✓ RobuxManager loaded - Centralized products")

-- ============================================
-- DEVELOPER PRODUCTS - AHORA CENTRALIZADOS EN ROBUXMANAGER
-- ============================================
-- Los DevProductIds se configuran en src/shared/RobuxManager.lua
-- Usar RobuxManager.findProductByDevId(productId) para obtener info del producto

-- Compras pendientes (para cuando el jugador compra pero aún no se procesa)
local pendingPurchases = {}
local pendingCosmeticPurchases = {} -- Para cosméticos
local pendingEggPurchases = {} -- Para huevos

-- Mapeo de ProductId -> Precio (para tracking de robux gastados)
-- Se llenará dinámicamente al obtener info del producto
local productPriceCache = {}

-- DataStore
local DATA_STORE_NAME = "FartTycoon_PlayerData_v10" -- Cambiar versión para resetear datos
local playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

-- OrderedDataStore para el leaderboard de Robux gastados
local robuxLeaderboardStore = DataStoreService:GetOrderedDataStore("RobuxLeaderboard_v1")

-- Cache de datos en memoria
local playerDataCache = {}

-- ============================================
-- ROBUX LEADERBOARD SYSTEM
-- ============================================

-- Función para registrar robux gastados
local function recordRobuxSpent(player, robuxAmount)
	local userId = player.UserId
	local data = playerDataCache[userId]
	if not data then return end

	-- Inicializar RobuxSpent si no existe
	if not data.RobuxSpent then
		data.RobuxSpent = 0
	end

	-- Sumar al total
	data.RobuxSpent = data.RobuxSpent + robuxAmount

	-- Actualizar el OrderedDataStore del leaderboard
	local success, err = pcall(function()
		robuxLeaderboardStore:SetAsync(tostring(userId), data.RobuxSpent)
	end)

	if not success then
		warn("[PlayerData] Error updating RobuxLeaderboard:", err)
	else
		print("[PlayerData] Robux recorded:", player.Name, "+", robuxAmount, "Total:", data.RobuxSpent)
	end

	return data.RobuxSpent
end

-- Función pública para obtener el leaderboard de robux (top 50)
local function getRobuxLeaderboard()
	local success, pages = pcall(function()
		return robuxLeaderboardStore:GetSortedAsync(false, 50, 1)
	end)

	if not success or not pages then
		warn("[PlayerData] Error getting RobuxLeaderboard")
		return {}
	end

	local topPlayers = {}
	local currentPage = pages:GetCurrentPage()

	for rank, data in ipairs(currentPage) do
		local userId = tonumber(data.key)
		local robuxSpent = data.value

		-- Obtener nombre del jugador
		local playerName = "Unknown"
		local nameSuccess, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if nameSuccess then
			playerName = name
		end

		table.insert(topPlayers, {
			Rank = rank,
			UserId = userId,
			Name = playerName,
			RobuxSpent = robuxSpent,
		})
	end

	return topPlayers
end

-- ============================================
-- CREAR REMOTES
-- ============================================
local function createRemotes()
	local remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage

	-- Eventos
	local events = {
		"OnDataLoaded",      -- Servidor → Cliente: datos cargados
		"OnDataUpdated",     -- Servidor → Cliente: datos actualizados
		"OnCoinCollected",   -- Servidor → Cliente: moneda recogida
		"OnMilestoneReached",-- Servidor → Cliente: hito alcanzado
		"CollectHeightBonus",-- Cliente → Servidor: recompensa por altura
		"OnTrophyCollected", -- Servidor → Cliente: trofeo recogido
		"OnTrophyVisibility",-- Servidor → Cliente: mostrar/ocultar trofeo
		"OnSpinsPurchased",  -- Servidor → Cliente: giros comprados con Robux
		"OnRobuxEggOpened",  -- Servidor → Cliente: huevo de Robux abierto (para animación)
		-- Replicación visual entre jugadores
		"VisualFatnessUpdate",   -- Cliente → Servidor → Otros: gordura actual
		"VisualPropulsionState", -- Cliente → Servidor → Otros: propulsión on/off
		"VisualEatingState",     -- Cliente → Servidor → Otros: comer on/off
	}

	-- Funciones (con respuesta)
	local functions = {
		"GetPlayerData",     -- Cliente → Servidor: obtener datos
		"PurchaseUpgrade",   -- Cliente → Servidor: comprar upgrade
		"PurchaseFood",      -- Cliente → Servidor: desbloquear comida
		"UpdateFatness",     -- Cliente → Servidor: sincronizar gordura
		"RegisterHeight",    -- Cliente → Servidor: registrar altura alcanzada
		"CollectCoin",       -- Cliente → Servidor: recoger moneda
		"PurchaseCosmetic",  -- Cliente → Servidor: comprar cosmético
		"EquipCosmetic",     -- Cliente → Servidor: equipar cosmético
		"CollectTrophy",     -- Cliente → Servidor: recoger trofeo
		-- Pet system
		"OpenEgg",           -- Cliente → Servidor: abrir huevo
		"EquipPet",          -- Cliente → Servidor: equipar mascota
		"UnequipPet",        -- Cliente → Servidor: desequipar mascota
		"DeletePet",         -- Cliente → Servidor: eliminar mascota
		"LockPet",           -- Cliente → Servidor: bloquear/desbloquear
		"GetPets",           -- Cliente → Servidor: obtener inventario
		"GetPetStats",       -- Cliente → Servidor: estadísticas
		"BuyInventorySlots", -- Cliente → Servidor: comprar slots de inventario
		"BuyEquipSlots",     -- Cliente → Servidor: comprar slots de equipo
	}

	for _, name in ipairs(events) do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end

	for _, name in ipairs(functions) do
		local remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotesFolder
	end

	-- BindableFunctions para comunicación servidor-servidor
	local bindables = {
		"CollectTrophyInternal", -- Servidor → Servidor: recoger trofeo
	}

	for _, name in ipairs(bindables) do
		local bindable = Instance.new("BindableFunction")
		bindable.Name = name
		bindable.Parent = remotesFolder
	end

	return remotesFolder
end

local Remotes = createRemotes()

-- ============================================
-- FUNCIONES DE DATOS
-- ============================================

-- Clonar tabla profundamente
local function deepClone(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepClone(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Fusionar datos guardados con valores por defecto (para manejar nuevos campos)
local function mergeWithDefaults(savedData)
	local result = deepClone(Config.DefaultPlayerData)

	local function merge(default, saved)
		for key, value in pairs(saved) do
			if type(value) == "table" and type(default[key]) == "table" then
				merge(default[key], value)
				default[key] = default[key] -- ya está mergeado
			else
				default[key] = value
			end
		end
	end

	if savedData then
		merge(result, savedData)
	end

	return result
end

-- Cargar datos del jugador
local function loadPlayerData(player)
	local userId = player.UserId
	local key = "Player_" .. userId

	local success, data = pcall(function()
		return playerDataStore:GetAsync(key)
	end)

	if success then
		local playerData = mergeWithDefaults(data)
		playerDataCache[userId] = playerData
		print("[PlayerData] Data loaded for", player.Name)
		return playerData
	else
		warn("[PlayerData] Error loading data for", player.Name, ":", data)
		playerDataCache[userId] = deepClone(Config.DefaultPlayerData)
		return playerDataCache[userId]
	end
end

-- Guardar datos del jugador
local function savePlayerData(player)
	local userId = player.UserId
	local key = "Player_" .. userId
	local data = playerDataCache[userId]

	if not data then
		warn("[PlayerData] No data to save for", player.Name)
		return false
	end

	local success, errorMessage = pcall(function()
		playerDataStore:SetAsync(key, data)
	end)

	if success then
		print("[PlayerData] Data saved for", player.Name)
		return true
	else
		warn("[PlayerData] Error saving data for", player.Name, ":", errorMessage)
		return false
	end
end

-- Obtener datos del jugador (desde cache)
local function getPlayerData(player)
	return playerDataCache[player.UserId]
end

-- Actualizar datos y notificar al cliente
local function updatePlayerData(player, newData)
	local userId = player.UserId
	if not playerDataCache[userId] then return end

	for key, value in pairs(newData) do
		if type(value) == "table" then
			for subKey, subValue in pairs(value) do
				playerDataCache[userId][key][subKey] = subValue
			end
		else
			playerDataCache[userId][key] = value
		end
	end

	-- Notificar al cliente
	Remotes.OnDataUpdated:FireClient(player, playerDataCache[userId])
end

-- ============================================
-- FUNCIONES DE UPGRADES
-- ============================================

-- Calcular valor de un upgrade según su nivel
local function getUpgradeValue(upgradeName, level)
	local upgradeConfig = Config.Upgrades[upgradeName]
	if not upgradeConfig then return nil end

	-- Si tiene ValuesPerLevel (exponencial), usar esos valores
	if upgradeConfig.ValuesPerLevel and level > 0 then
		return upgradeConfig.ValuesPerLevel[level] or upgradeConfig.BaseValue
	end

	-- Si no, usar IncrementPerLevel (lineal)
	return upgradeConfig.BaseValue + ((upgradeConfig.IncrementPerLevel or 0) * level)
end

-- Calcula todos los boosts de mascotas equipadas (definida aquí para uso en getPlayerUpgradeValues)
local function calculatePetBoosts(player)
	local data = getPlayerData(player)
	if not data or not data.PetSystem then return {} end

	local boosts = {}
	for _, pet in ipairs(data.PetSystem.Pets) do
		if pet.Equiped then
			local petConfig = Config.Pets[pet.PetName]
			if petConfig then
				-- Nueva estructura con Boosts
				if petConfig.Boosts then
					for boostType, value in pairs(petConfig.Boosts) do
						boosts[boostType] = (boosts[boostType] or 0) + value
					end
				-- Compatibilidad con estructura antigua (Boost simple)
				elseif petConfig.Boost then
					boosts.CoinBoost = (boosts.CoinBoost or 0) + petConfig.Boost
				end
			end
		end
	end
	return boosts
end

-- Obtener todos los valores calculados de upgrades del jugador (con boosts de mascotas)
local function getPlayerUpgradeValues(player)
	local data = getPlayerData(player)
	if not data then return nil end

	-- Valores base de upgrades
	local baseMaxFatness = getUpgradeValue("MaxFatness", data.Upgrades.MaxFatness)
	local baseEatSpeed = getUpgradeValue("EatSpeed", data.Upgrades.EatSpeed)
	local basePropulsion = getUpgradeValue("PropulsionForce", data.Upgrades.PropulsionForce)
	local baseFuelEff = getUpgradeValue("FuelEfficiency", data.Upgrades.FuelEfficiency)

	-- Aplicar boosts de mascotas
	local petBoosts = calculatePetBoosts(player)

	return {
		MaxFatness = baseMaxFatness * (1 + (petBoosts.FatnessBoost or 0)),
		EatSpeed = baseEatSpeed * (1 + (petBoosts.EatBoost or 0)),
		PropulsionForce = basePropulsion * (1 + (petBoosts.PropulsionBoost or 0)),
		-- EfficiencyBoost reduce la perdida de grasa (menor es mejor)
		FuelEfficiency = baseFuelEff * (1 - (petBoosts.EfficiencyBoost or 0)),
	}
end

-- Comprar un upgrade
local function purchaseUpgrade(player, upgradeName, useRobux)
	local data = getPlayerData(player)
	if not data then return false, "Data not available" end

	local upgradeConfig = Config.Upgrades[upgradeName]
	if not upgradeConfig then return false, "Upgrade does not exist" end

	local currentLevel = data.Upgrades[upgradeName] or 0
	if currentLevel >= upgradeConfig.MaxLevel then
		return false, "Max level reached"
	end

	if not useRobux then
		-- Compra con monedas (+1 nivel)
		local nextLevel = currentLevel + 1
		local cost = upgradeConfig.CostCoins[nextLevel]

		if not cost then
			return false, "Level not available"
		end

		if data.Coins < cost then
			return false, "Insufficient coins"
		end

		data.Coins = data.Coins - cost
		data.Upgrades[upgradeName] = nextLevel

		updatePlayerData(player, {
			Coins = data.Coins,
			Upgrades = data.Upgrades
		})

		return true, "Level " .. nextLevel .. " unlocked!"
	else
		-- Compra con Robux (10 R$ por +1 nivel, independiente del escalado de monedas)
		local nextLevel = currentLevel + 1

		-- Obtener DevProductId desde RobuxManager (fuente centralizada)
		local robuxProduct = RobuxManager.Upgrades[upgradeName]
		local productId = robuxProduct and robuxProduct.DevProductId or 0

		if not productId or productId == 0 then
			-- Si no hay producto configurado, usar modo de prueba
			warn("[PlayerData] Developer Product not configured for upgrade:", upgradeName)
			warn("[PlayerData] Using test mode - free upgrade (+1 level)")

			-- En modo de prueba, dar +1 nivel gratis
			data.Upgrades[upgradeName] = nextLevel
			updatePlayerData(player, {
				Upgrades = data.Upgrades
			})

			-- MODO PRUEBA: Registrar robux gastados (simulado)
			local testPrice = robuxProduct and robuxProduct.RobuxCost or 10
			recordRobuxSpent(player, testPrice)

			return true, "Level " .. nextLevel .. "! (Test mode)"
		end

		-- Guardar compra pendiente
		pendingPurchases[player.UserId] = {
			UpgradeName = upgradeName,
			TargetLevel = nextLevel,
			ProductId = productId,
		}

		-- Prompt de compra con Robux
		local success, errorMessage = pcall(function()
			MarketplaceService:PromptProductPurchase(player, productId)
		end)

		if success then
			return true, "Processing purchase..."
		else
			warn("[PlayerData] Error al iniciar compra:", errorMessage)
			return false, "Purchase error"
		end
	end
end

-- ============================================
-- FUNCIONES DE COSMÉTICOS
-- ============================================

-- Comprar un cosmético
local function purchaseCosmetic(player, cosmeticId)
	local data = getPlayerData(player)
	if not data then return false, "Data not available" end

	-- Verificar que el cosmético existe
	local cosmeticConfig = Config.FartCosmetics[cosmeticId]
	if not cosmeticConfig then return false, "Cosmetic does not exist" end

	-- Verificar que no lo tenga ya
	if data.OwnedCosmetics and data.OwnedCosmetics[cosmeticId] then
		return false, "You already own this cosmetic"
	end

	-- Si es gratis, darlo directamente
	if cosmeticConfig.CostRobux == 0 then
		if not data.OwnedCosmetics then
			data.OwnedCosmetics = {}
		end
		data.OwnedCosmetics[cosmeticId] = true

		updatePlayerData(player, {
			OwnedCosmetics = data.OwnedCosmetics
		})
		return true, "Cosmetic unlocked"
	end

	-- Compra con Robux - obtener DevProductId desde RobuxManager
	local robuxProduct = RobuxManager.Cosmetics[cosmeticId]
	local productId = robuxProduct and robuxProduct.DevProductId or 0

	if not productId or productId == 0 then
		-- Modo de prueba: dar gratis
		warn("[PlayerData] Developer Product not configured for cosmetic:", cosmeticId)
		warn("[PlayerData] Using test mode - free cosmetic")

		if not data.OwnedCosmetics then
			data.OwnedCosmetics = {}
		end
		data.OwnedCosmetics[cosmeticId] = true

		updatePlayerData(player, {
			OwnedCosmetics = data.OwnedCosmetics
		})

		-- MODO PRUEBA: Registrar robux gastados (simulado)
		local testPrice = robuxProduct and robuxProduct.RobuxCost or 25
		recordRobuxSpent(player, testPrice)

		return true, "Cosmetic unlocked (Test mode)"
	end

	-- Guardar compra pendiente
	pendingCosmeticPurchases[player.UserId] = {
		CosmeticId = cosmeticId,
		ProductId = productId,
	}

	-- Prompt de compra con Robux
	local success, errorMessage = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)

	if success then
		return true, "Processing purchase..."
	else
		warn("[PlayerData] Error al iniciar compra:", errorMessage)
		return false, "Purchase error"
	end
end

-- Equipar un cosmético
local function equipCosmetic(player, cosmeticId)
	local data = getPlayerData(player)
	if not data then return false end

	-- Verificar que el cosmético existe
	local cosmeticConfig = Config.FartCosmetics[cosmeticId]
	if not cosmeticConfig then return false end

	-- Verificar que lo tenga
	if not data.OwnedCosmetics or not data.OwnedCosmetics[cosmeticId] then
		-- Excepción: Default siempre está disponible
		if cosmeticId ~= "Default" then
			return false
		end
	end

	-- Equipar
	data.EquippedCosmetic = cosmeticId

	updatePlayerData(player, {
		EquippedCosmetic = data.EquippedCosmetic
	})

	print("[PlayerData] Cosmetic equipped:", player.Name, "->", cosmeticId)
	return true
end

-- ============================================
-- FUNCIONES DE MASCOTAS
-- ============================================

local HttpService = game:GetService("HttpService")
-- PetManager ya está cargado al inicio del script

local function generateUUID()
	return HttpService:GenerateGUID(false)
end

-- Mantener compatibilidad: retorna solo CoinBoost para sistemas antiguos
local function calculatePetBoost(player)
	local boosts = calculatePetBoosts(player)
	return boosts.CoinBoost or 0
end

local function openEgg(player, eggName)
	local data = getPlayerData(player)
	if not data then return false, "Data not available" end

	if not data.PetSystem then
		data.PetSystem = deepClone(Config.DefaultPlayerData.PetSystem)
	end

	local eggConfig = Config.Eggs[eggName]
	if not eggConfig then return false, "Egg does not exist" end

	-- Verificar espacio
	if #data.PetSystem.Pets >= data.PetSystem.InventorySlots then
		return false, "Inventory full"
	end

	-- Verificar costo
	if eggConfig.CostRobux then
		-- Es un huevo de Robux - obtener DevProductId desde RobuxManager
		local robuxProduct = RobuxManager.Pets[eggName]
		local productId = robuxProduct and robuxProduct.DevProductId or 0

		if not productId or productId == 0 then
			-- Modo de prueba: abrir gratis
			warn("[PlayerData] Developer Product not configured for egg:", eggName)
			warn("[PlayerData] Using test mode - free egg")

			-- MODO PRUEBA: Registrar robux gastados (simulado)
			local testPrice = robuxProduct and robuxProduct.RobuxCost or 99
			recordRobuxSpent(player, testPrice)
			-- Continuar con la lógica normal (no restar monedas)
		else
			-- Guardar compra pendiente
			pendingEggPurchases[player.UserId] = {
				EggName = eggName,
				ProductId = productId,
			}

			-- Iniciar prompt de compra
			MarketplaceService:PromptProductPurchase(player, productId)
			return false, "ROBUX_PROMPT", productId
		end
	elseif eggConfig.TrophyCost then
		-- Huevo de trofeos
		if data.Trophies < eggConfig.TrophyCost then
			return false, "Insufficient trophies"
		end
		data.Trophies = data.Trophies - eggConfig.TrophyCost
	end

	-- Selección aleatoria ponderada
	local totalWeight = 0
	for _, weight in pairs(eggConfig.Pets) do
		totalWeight = totalWeight + weight
	end

	local randomValue = math.random() * totalWeight
	local currentWeight = 0
	local selectedPet = nil

	for petName, weight in pairs(eggConfig.Pets) do
		currentWeight = currentWeight + weight
		if randomValue <= currentWeight then
			selectedPet = petName
			break
		end
	end

	if not selectedPet then
		selectedPet = next(eggConfig.Pets)
	end

	-- Crear mascota
	local newPet = {
		PetName = selectedPet,
		UUID = generateUUID(),
		Equiped = false,
		Locked = false,
	}

	table.insert(data.PetSystem.Pets, newPet)

	-- Índice
	if not table.find(data.PetSystem.PetIndex, selectedPet) then
		table.insert(data.PetSystem.PetIndex, selectedPet)
	end

	updatePlayerData(player, {
		Coins = data.Coins,
		PetSystem = data.PetSystem
	})

	print("[PetSystem] Egg opened:", player.Name, eggName, "→", selectedPet)
	return true, selectedPet, newPet.UUID
end

local function equipPet(player, uuid)
	local data = getPlayerData(player)
	if not data then return false, "Data not available" end

	-- Contar equipadas
	local equippedCount = 0
	for _, pet in ipairs(data.PetSystem.Pets) do
		if pet.Equiped then equippedCount = equippedCount + 1 end
	end

	if equippedCount >= data.PetSystem.EquipSlots then
		return false, "Limit reached"
	end

	-- Equipar
	for _, pet in ipairs(data.PetSystem.Pets) do
		if pet.UUID == uuid and not pet.Equiped then
			pet.Equiped = true

			-- Spawn en mundo
			print("[EquipPet] PetManager disponible?", PetManager ~= nil)
			if PetManager then
				print("[EquipPet] Llamando a PetManager:EquipPet para", pet.PetName, "UUID:", pet.UUID)
				PetManager:EquipPet(player, pet.PetName, pet.UUID)
			else
				warn("[EquipPet] PetManager not available yet")
			end

			updatePlayerData(player, {
				PetSystem = data.PetSystem
			})
			return true, "Pet equipped"
		end
	end

	return false, "Pet not found"
end

local function unequipPet(player, uuid)
	local data = getPlayerData(player)
	if not data then return false end

	for _, pet in ipairs(data.PetSystem.Pets) do
		if pet.UUID == uuid and pet.Equiped then
			pet.Equiped = false

			-- Despawn del mundo
			if PetManager then
				PetManager:UnequipPet(player, pet.PetName, pet.UUID)
			end

			updatePlayerData(player, {
				PetSystem = data.PetSystem
			})
			return true, "Pet unequipped"
		end
	end

	return false
end

local function deletePet(player, uuid)
	local data = getPlayerData(player)
	if not data then return false end

	for i, pet in ipairs(data.PetSystem.Pets) do
		if pet.UUID == uuid then
			if pet.Locked then
				return false, "Pet is locked"
			end
			if pet.Equiped then
				return false, "Unequip first"
			end

			table.remove(data.PetSystem.Pets, i)
			updatePlayerData(player, {
				PetSystem = data.PetSystem
			})
			return true, "Pet deleted"
		end
	end

	return false
end

local function lockPet(player, uuid)
	local data = getPlayerData(player)
	if not data then return false end

	for _, pet in ipairs(data.PetSystem.Pets) do
		if pet.UUID == uuid then
			pet.Locked = not pet.Locked
			updatePlayerData(player, {
				PetSystem = data.PetSystem
			})
			return true, pet.Locked
		end
	end

	return false
end

-- ============================================
-- PROCESAMIENTO DE COMPRAS ROBUX
-- ============================================

local function processReceipt(receiptInfo)
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local player = Players:GetPlayerByUserId(playerId)

	-- Obtener datos del jugador
	local data = playerDataCache[playerId]
	if not data then
		warn("[PlayerData] Datos no encontrados para jugador:", playerId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Obtener precio del producto para tracking de Robux gastados
	-- Primero intentar desde RobuxManager (funciona en modo prueba)
	-- Luego desde MarketplaceService (productos reales)
	local robuxPrice = 0
	local category, productKey, productInfo = RobuxManager.findProductByDevId(productId)

	if productInfo and productInfo.RobuxCost then
		-- Precio desde RobuxManager (siempre disponible)
		robuxPrice = productInfo.RobuxCost
	elseif not productPriceCache[productId] then
		-- Intentar desde MarketplaceService (productos reales)
		local priceSuccess, marketInfo = pcall(function()
			return MarketplaceService:GetProductInfo(productId, Enum.InfoType.Product)
		end)
		if priceSuccess and marketInfo then
			productPriceCache[productId] = marketInfo.PriceInRobux or 0
			robuxPrice = productPriceCache[productId]
		end
	else
		robuxPrice = productPriceCache[productId] or 0
	end

	-- ============================================
	-- VERIFICAR SI ES UN COSMÉTICO
	-- ============================================
	-- Reutilizar category y productKey del findProductByDevId de arriba
	local cosmeticId = (category == "Cosmetics") and productKey or nil

	-- También revisar compras pendientes de cosméticos
	if not cosmeticId then
		local pendingCosmetic = pendingCosmeticPurchases[playerId]
		if pendingCosmetic and pendingCosmetic.ProductId == productId then
			cosmeticId = pendingCosmetic.CosmeticId
		end
	end

	if cosmeticId then
		-- Es una compra de cosmético
		if not data.OwnedCosmetics then
			data.OwnedCosmetics = {}
		end

		-- Verificar que no lo tenga ya
		if data.OwnedCosmetics[cosmeticId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		-- Dar el cosmético
		data.OwnedCosmetics[cosmeticId] = true

		-- Notificar al jugador si está conectado
		if player then
			Remotes.OnDataUpdated:FireClient(player, data)
			print("[PlayerData] Cosmetic purchased with Robux:", cosmeticId)

			-- Registrar Robux gastados
			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		-- Limpiar compra pendiente
		pendingCosmeticPurchases[playerId] = nil

		-- Guardar datos
		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- VERIFICAR SI ES UN HUEVO (PET EGG)
	-- ============================================
	-- Reutilizar resultado de findProductByDevId (category ya está definido arriba)
	-- Excluir InventorySlots y EquipSlots (se manejan aparte)
	local eggName = (category == "Pets" and productKey ~= "InventorySlots" and productKey ~= "EquipSlots") and productKey or nil

	-- También revisar compras pendientes de huevos
	if not eggName then
		local pendingEgg = pendingEggPurchases[playerId]
		if pendingEgg and pendingEgg.ProductId == productId then
			eggName = pendingEgg.EggName
		end
	end

	if eggName then
		-- Es una compra de huevo - abrir el huevo y dar mascota
		local eggConfig = Config.Eggs[eggName]
		if not eggConfig then
			warn("[PlayerData] Egg not found in Config:", eggName)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Verificar espacio en inventario
		if not data.PetSystem then
			data.PetSystem = deepClone(Config.DefaultPlayerData.PetSystem)
		end

		if #data.PetSystem.Pets >= data.PetSystem.InventorySlots then
			warn("[PlayerData] Inventory full for Robux egg - refund")
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Selección aleatoria ponderada
		local totalWeight = 0
		for _, weight in pairs(eggConfig.Pets) do
			totalWeight = totalWeight + weight
		end

		local randomValue = math.random() * totalWeight
		local currentWeight = 0
		local selectedPet = nil

		for petName, weight in pairs(eggConfig.Pets) do
			currentWeight = currentWeight + weight
			if randomValue <= currentWeight then
				selectedPet = petName
				break
			end
		end

		if not selectedPet then
			selectedPet = next(eggConfig.Pets)
		end

		-- Crear mascota
		local newPet = {
			PetName = selectedPet,
			UUID = generateUUID(),
			Equiped = false,
			Locked = false,
		}

		table.insert(data.PetSystem.Pets, newPet)

		-- Añadir al índice de mascotas descubiertas
		if not table.find(data.PetSystem.PetIndex, selectedPet) then
			table.insert(data.PetSystem.PetIndex, selectedPet)
		end

		-- Notificar al jugador si está conectado
		if player then
			updatePlayerData(player, { PetSystem = data.PetSystem })
			print("[PlayerData] Robux egg opened:", eggName, "→", selectedPet)

			-- Notificar al cliente para reproducir animación de apertura
			local eggRemote = Remotes:FindFirstChild("OnRobuxEggOpened")
			if eggRemote then
				eggRemote:FireClient(player, eggName, selectedPet)
			end

			-- Registrar Robux gastados
			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		-- Limpiar compra pendiente
		pendingEggPurchases[playerId] = nil

		-- Guardar datos
		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- VERIFICAR SI ES UN UPGRADE (10 R$ por +1 nivel)
	-- ============================================
	-- Reutilizar resultado de findProductByDevId (category ya está definido arriba)
	local upgradeName = (category == "Upgrades" and productKey) or nil

	if not upgradeName then
		-- También revisar compras pendientes
		local pending = pendingPurchases[playerId]
		if pending and pending.ProductId == productId then
			upgradeName = pending.UpgradeName
		end
	end

	if upgradeName then
		local upgradeConfig = Config.Upgrades[upgradeName]
		if not upgradeConfig then
			warn("[PlayerData] Upgrade no existe en Config:", upgradeName)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		local currentLevel = data.Upgrades[upgradeName] or 0

		-- Verificar que no esté al máximo
		if currentLevel >= upgradeConfig.MaxLevel then
			print("[PlayerData] Player already at max level for", upgradeName)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		-- Aplicar el upgrade (+1 nivel)
		local newLevel = currentLevel + 1
		data.Upgrades[upgradeName] = newLevel

		-- Notificar al jugador si está conectado
		if player then
			Remotes.OnDataUpdated:FireClient(player, data)
			print("[PlayerData] Upgrade purchased with Robux:", upgradeName, "Nivel:", newLevel)

			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		pendingPurchases[playerId] = nil

		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- VERIFICAR SI ES UNA ZONA
	-- ============================================
	if category == "Zones" then
		local zoneName = productKey -- ej: "Zona1", "VIP1"

		if not data.UnlockedZones then
			data.UnlockedZones = {}
		end

		-- Si ya la tiene, confirmar compra
		if data.UnlockedZones[zoneName] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		data.UnlockedZones[zoneName] = true

		if player then
			updatePlayerData(player, { UnlockedZones = data.UnlockedZones })
			print("[PlayerData] Zone purchased with Robux:", zoneName)

			-- Notificar al cliente para hacer la zona invisible/pasable
			local makeZoneRemote = Remotes:FindFirstChild("MakeZoneInvisible")
			if makeZoneRemote then
				makeZoneRemote:FireClient(player, zoneName)
			end

			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- VERIFICAR SI ES UNA BASE
	-- ============================================
	if category == "Bases" then
		local baseName = productKey -- ej: "Base1"

		if not data.UnlockedBases then
			data.UnlockedBases = {}
		end

		if data.UnlockedBases[baseName] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		data.UnlockedBases[baseName] = true

		-- También desbloquear como zona (DesbloqueoZonaServer usa "BloqueoBase1")
		if not data.UnlockedZones then
			data.UnlockedZones = {}
		end
		data.UnlockedZones["Bloqueo" .. baseName] = true

		if player then
			updatePlayerData(player, {
				UnlockedBases = data.UnlockedBases,
				UnlockedZones = data.UnlockedZones,
			})
			print("[PlayerData] Base purchased with Robux:", baseName)

			-- Notificar a ambos sistemas (bases y zonas)
			local makeBaseRemote = Remotes:FindFirstChild("MakeBaseInvisible")
			if makeBaseRemote then
				makeBaseRemote:FireClient(player, baseName, "Bloqueo" .. baseName)
			end
			local makeZoneRemote = Remotes:FindFirstChild("MakeZoneInvisible")
			if makeZoneRemote then
				makeZoneRemote:FireClient(player, "Bloqueo" .. baseName)
			end

			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- VERIFICAR SI ES UNA COMIDA (FOOD)
	-- ============================================
	if category == "Foods" then
		local foodType = productKey -- ej: "Burger", "Pizza"

		if not data.UnlockedFood then
			data.UnlockedFood = {}
		end

		if data.UnlockedFood[foodType] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		data.UnlockedFood[foodType] = true

		if player then
			updatePlayerData(player, { UnlockedFood = data.UnlockedFood })
			print("[PlayerData] Food purchased with Robux:", foodType)

			-- Notificar al cliente
			local foodPurchasedRemote = Remotes:FindFirstChild("OnFoodPurchased")
			if foodPurchasedRemote then
				foodPurchasedRemote:FireClient(player, foodType, true)
			end

			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- VERIFICAR SI ES GIROS DE RULETA (SPINS)
	-- ============================================
	if category == "Spins" then
		local spinKey = productKey -- ej: "Spin1", "Spin10", "Spin100"
		local spinProduct = RobuxManager.Spins[spinKey]
		local spinAmount = spinProduct and spinProduct.Amount or 0

		if spinAmount <= 0 then
			warn("[PlayerData] Spin product sin cantidad:", spinKey)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Añadir giros al jugador
		if not data.PurchasedSpins then
			data.PurchasedSpins = 0
		end
		data.PurchasedSpins = data.PurchasedSpins + spinAmount

		if player then
			updatePlayerData(player, { PurchasedSpins = data.PurchasedSpins })
			print("[PlayerData] Spins purchased with Robux:", spinKey, "+" .. spinAmount)

			-- Notificar al cliente con los giros añadidos
			local spinsRemote = Remotes:FindFirstChild("OnSpinsPurchased")
			if spinsRemote then
				spinsRemote:FireClient(player, spinAmount, data.PurchasedSpins)
			end

			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- VERIFICAR SI ES PET SLOTS (Inventory / Equip)
	-- ============================================
	if category == "Pets" and (productKey == "InventorySlots" or productKey == "EquipSlots") then
		if not data.PetSystem then
			data.PetSystem = deepClone(Config.DefaultPlayerData.PetSystem)
		end

		if productKey == "InventorySlots" then
			local slotsToAdd = RobuxManager.Pets.InventorySlots.SlotsPerPurchase or 10
			local maxSlots = Config.PetSystem.MaxInventorySlots or 200
			local newSlots = math.min(data.PetSystem.InventorySlots + slotsToAdd, maxSlots)
			data.PetSystem.InventorySlots = newSlots
			print("[PlayerData] Inventory slots purchased with Robux:", player and player.Name or playerId, "->", newSlots)
		elseif productKey == "EquipSlots" then
			local slotsToAdd = RobuxManager.Pets.EquipSlots.SlotsPerPurchase or 1
			local maxSlots = Config.PetSystem.MaxEquipSlots or 10
			local newSlots = math.min(data.PetSystem.EquipSlots + slotsToAdd, maxSlots)
			data.PetSystem.EquipSlots = newSlots
			print("[PlayerData] Equip slots purchased with Robux:", player and player.Name or playerId, "->", newSlots)
		end

		if player then
			updatePlayerData(player, { PetSystem = data.PetSystem })

			if robuxPrice > 0 then
				recordRobuxSpent(player, robuxPrice)
			end
		end

		local saveKey = "Player_" .. playerId
		pcall(function()
			playerDataStore:SetAsync(saveKey, data)
		end)

		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- ============================================
	-- PRODUCTO NO RECONOCIDO
	-- ============================================
	warn("[PlayerData] Unrecognized product:", productId)
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Conectar el procesador de recibos
MarketplaceService.ProcessReceipt = processReceipt

-- ============================================
-- FUNCIONES DE JUEGO
-- ============================================

-- Recoger una moneda (con boost de pets)
local function collectCoin(player, coinValue)
	local data = getPlayerData(player)
	if not data then return false end

	coinValue = coinValue or Config.Rewards.CoinValue

	-- Aplicar boost de pets
	local petBoost = calculatePetBoost(player)
	local boostedValue = math.floor(coinValue * (1 + petBoost))

	data.Coins = data.Coins + boostedValue
	data.Records.TotalCoinsEarned = data.Records.TotalCoinsEarned + boostedValue

	updatePlayerData(player, {
		Coins = data.Coins,
		Records = data.Records
	})

	Remotes.OnCoinCollected:FireClient(player, boostedValue, data.Coins)
	return true
end

-- Recoger un trofeo
-- Recoger un trofeo (con boost de pets)
local function collectTrophy(player, trophyValue)
	local data = getPlayerData(player)
	if not data then return false end

	trophyValue = trophyValue or 1

	-- Aplicar boost de pets para trofeos
	local petBoosts = calculatePetBoosts(player)
	local boostedValue = math.floor(trophyValue * (1 + (petBoosts.TrophyBoost or 0)))

	data.Trophies = (data.Trophies or 0) + boostedValue

	updatePlayerData(player, {
		Trophies = data.Trophies
	})

	Remotes.OnTrophyCollected:FireClient(player, boostedValue, data.Trophies)
	return true
end

-- Registrar altura alcanzada y dar bonus si corresponde
local function registerHeight(player, height)
	local data = getPlayerData(player)
	if not data then return {} end

	local milestonesReached = {}

	-- Verificar hitos
	for _, milestone in ipairs(Config.Rewards.HeightMilestones) do
		-- Solo dar bonus si es la primera vez que alcanza este hito
		if height >= milestone.Height and data.Records.MaxHeight < milestone.Height then
			table.insert(milestonesReached, milestone)
			data.Coins = data.Coins + milestone.Bonus
		end
	end

	-- Actualizar récord si es mayor
	if height > data.Records.MaxHeight then
		data.Records.MaxHeight = height
	end

	if #milestonesReached > 0 then
		updatePlayerData(player, {
			Coins = data.Coins,
			Records = data.Records
		})

		-- Notificar cada hito
		for _, milestone in ipairs(milestonesReached) do
			Remotes.OnMilestoneReached:FireClient(player, milestone)
		end
	end

	return milestonesReached
end

-- ============================================
-- CONECTAR REMOTES
-- ============================================

Remotes.GetPlayerData.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	local upgradeValues = getPlayerUpgradeValues(player)

	-- Obtener cosmético equipado
	local equippedCosmetic = data.EquippedCosmetic or "Default"
	local cosmeticConfig = Config.FartCosmetics[equippedCosmetic]

	return {
		Data = data,
		UpgradeValues = upgradeValues,
		EquippedCosmeticConfig = cosmeticConfig,
		Config = {
			Fatness = Config.Fatness,
			Rewards = Config.Rewards,
		}
	}
end

Remotes.PurchaseUpgrade.OnServerInvoke = function(player, upgradeName, useRobux)
	local success, message = purchaseUpgrade(player, upgradeName, useRobux)
	if success then
		local upgradeValues = getPlayerUpgradeValues(player)
		return { Success = true, Message = message, UpgradeValues = upgradeValues }
	else
		return { Success = false, Message = message }
	end
end

Remotes.CollectCoin.OnServerInvoke = function(player, coinValue)
	return collectCoin(player, coinValue)
end

Remotes.CollectTrophy.OnServerInvoke = function(player, trophyValue)
	return collectTrophy(player, trophyValue)
end

-- BindableFunction para comunicación servidor-servidor
Remotes.CollectTrophyInternal.OnInvoke = function(player, trophyValue)
	return collectTrophy(player, trophyValue)
end

Remotes.RegisterHeight.OnServerInvoke = function(player, height)
	return registerHeight(player, height)
end

Remotes.PurchaseCosmetic.OnServerInvoke = function(player, cosmeticId)
	return purchaseCosmetic(player, cosmeticId)
end

Remotes.EquipCosmetic.OnServerInvoke = function(player, cosmeticId)
	return equipCosmetic(player, cosmeticId)
end

-- Pet system RemoteFunctions
Remotes.OpenEgg.OnServerInvoke = function(player, eggName)
	return openEgg(player, eggName)
end

Remotes.EquipPet.OnServerInvoke = function(player, uuid)
	return equipPet(player, uuid)
end

Remotes.UnequipPet.OnServerInvoke = function(player, uuid)
	return unequipPet(player, uuid)
end

Remotes.DeletePet.OnServerInvoke = function(player, uuid)
	return deletePet(player, uuid)
end

Remotes.LockPet.OnServerInvoke = function(player, uuid)
	return lockPet(player, uuid)
end

Remotes.GetPets.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	if not data or not data.PetSystem then return {} end
	return data.PetSystem.Pets
end

Remotes.GetPetStats.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	if not data or not data.PetSystem then
		return {TotalPets = 0, EquippedPets = 0, TotalBoost = 0, Boosts = {}}
	end

	local equippedCount = 0
	for _, pet in ipairs(data.PetSystem.Pets) do
		if pet.Equiped then equippedCount = equippedCount + 1 end
	end

	local allBoosts = calculatePetBoosts(player)

	return {
		TotalPets = #data.PetSystem.Pets,
		EquippedPets = equippedCount,
		InventorySlots = data.PetSystem.InventorySlots,
		EquipSlots = data.PetSystem.EquipSlots,
		TotalBoost = allBoosts.CoinBoost or 0, -- Compatibilidad
		Boosts = allBoosts, -- Todos los boosts
	}
end

-- Comprar slots de inventario con Robux
Remotes.BuyInventorySlots.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	if not data or not data.PetSystem then
		return false, "Data not available"
	end

	local purchaseConfig = Config.PetSystem.SlotPurchases.InventorySlots
	local maxSlots = Config.PetSystem.MaxInventorySlots

	-- Verificar límite máximo
	if data.PetSystem.InventorySlots >= maxSlots then
		return false, "Max inventory slots reached"
	end

	-- Obtener DevProductId desde RobuxManager (inyectado en Config)
	local devProductId = purchaseConfig.DevProductId
	if not devProductId or devProductId == 0 then
		-- Modo de prueba: dar slots gratis
		warn("[PlayerData] DevProductId no configurado para InventorySlots - modo testing")
		local newSlots = math.min(
			data.PetSystem.InventorySlots + purchaseConfig.SlotsPerPurchase,
			maxSlots
		)
		data.PetSystem.InventorySlots = newSlots
		updatePlayerData(player, { PetSystem = data.PetSystem })

		local testPrice = RobuxManager.Pets.InventorySlots and RobuxManager.Pets.InventorySlots.RobuxCost or 49
		recordRobuxSpent(player, testPrice)
		return true, "Inventory slots added (Test mode)"
	end

	-- Prompt de compra real con Robux (ProcessReceipt manejará el resultado)
	local success, errorMessage = pcall(function()
		MarketplaceService:PromptProductPurchase(player, devProductId)
	end)
	if success then
		return true, "Processing purchase..."
	else
		warn("[PlayerData] Error al iniciar compra InventorySlots:", errorMessage)
		return false, "Purchase error"
	end
end

-- Comprar slots de equipo con Robux
Remotes.BuyEquipSlots.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	if not data or not data.PetSystem then
		return false, "Data not available"
	end

	local purchaseConfig = Config.PetSystem.SlotPurchases.EquipSlots
	local maxSlots = Config.PetSystem.MaxEquipSlots

	-- Verificar límite máximo
	if data.PetSystem.EquipSlots >= maxSlots then
		return false, "Max equip slots reached"
	end

	-- Obtener DevProductId desde RobuxManager (inyectado en Config)
	local devProductId = purchaseConfig.DevProductId
	if not devProductId or devProductId == 0 then
		-- Modo de prueba: dar slots gratis
		warn("[PlayerData] DevProductId no configurado para EquipSlots - modo testing")
		local newSlots = math.min(
			data.PetSystem.EquipSlots + purchaseConfig.SlotsPerPurchase,
			maxSlots
		)
		data.PetSystem.EquipSlots = newSlots
		updatePlayerData(player, { PetSystem = data.PetSystem })

		local testPrice = RobuxManager.Pets.EquipSlots and RobuxManager.Pets.EquipSlots.RobuxCost or 99
		recordRobuxSpent(player, testPrice)
		return true, "Equip slot added (Test mode)"
	end

	-- Prompt de compra real con Robux (ProcessReceipt manejará el resultado)
	local success, errorMessage = pcall(function()
		MarketplaceService:PromptProductPurchase(player, devProductId)
	end)
	if success then
		return true, "Processing purchase..."
	else
		warn("[PlayerData] Error al iniciar compra EquipSlots:", errorMessage)
		return false, "Purchase error"
	end
end

-- Sistema anti-exploit para height bonus (tracking por vuelo)
local playerFlightBonuses = {} -- {playerId = {lastResetTime, claimedHeights}}

Remotes.CollectHeightBonus.OnServerEvent:Connect(function(player, height, bonus)
	local data = getPlayerData(player)
	if not data then return end

	-- Validar que el bonus corresponde a un milestone real
	local validMilestone = nil
	for _, milestone in ipairs(Config.Rewards.HeightMilestones) do
		if milestone.Height == height and milestone.Bonus == bonus then
			validMilestone = milestone
			break
		end
	end

	if not validMilestone then
		warn("[PlayerData] Invalid bonus attempt:", player.Name, height, bonus)
		return
	end

	-- Inicializar tracking del jugador
	if not playerFlightBonuses[player.UserId] then
		playerFlightBonuses[player.UserId] = {
			lastResetTime = tick(),
			claimedHeights = {}
		}
	end

	local flightData = playerFlightBonuses[player.UserId]

	-- Si han pasado más de 5 segundos desde el último claim, resetear
	-- (esto permite que cada vuelo tenga sus propios milestones)
	if tick() - flightData.lastResetTime > 10 then
		flightData.claimedHeights = {}
	end

	-- Verificar que no haya reclamado este milestone en este vuelo
	if flightData.claimedHeights[height] then
		return -- Ya reclamó este milestone en este vuelo
	end

	-- Marcar como reclamado
	flightData.claimedHeights[height] = true
	flightData.lastResetTime = tick()

	-- Dar las monedas
	data.Coins = data.Coins + bonus
	data.Records.TotalCoinsEarned = data.Records.TotalCoinsEarned + bonus

	-- Actualizar récord de altura si es mayor
	if height > data.Records.MaxHeight then
		data.Records.MaxHeight = height
	end

	updatePlayerData(player, {
		Coins = data.Coins,
		Records = data.Records
	})

	print("[PlayerData] Height bonus:", player.Name, "altura:", height, "bonus:", bonus)
end)

-- Limpiar datos cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	playerFlightBonuses[player.UserId] = nil
end)

-- ============================================
-- EVENTOS DE JUGADOR
-- ============================================

Players.PlayerAdded:Connect(function(player)
	local data = loadPlayerData(player)
	local upgradeValues = getPlayerUpgradeValues(player)

	-- Obtener cosmético equipado
	local equippedCosmetic = data.EquippedCosmetic or "Default"
	local cosmeticConfig = Config.FartCosmetics[equippedCosmetic]

	-- Esperar un momento para que el cliente esté listo
	task.wait(1)

	-- Enviar datos al cliente
	Remotes.OnDataLoaded:FireClient(player, {
		Data = data,
		UpgradeValues = upgradeValues,
		EquippedCosmeticConfig = cosmeticConfig,
		Config = {
			Fatness = Config.Fatness,
			Rewards = Config.Rewards,
		}
	})

	-- Función para equipar mascotas guardadas
	local function equipSavedPets()
		if data.PetSystem and PetManager then
			for _, pet in ipairs(data.PetSystem.Pets) do
				if pet.Equiped then
					PetManager:EquipPet(player, pet.PetName, pet.UUID)
				end
			end
		end
	end

	-- Equipar mascotas al entrar por primera vez
	local character = player.Character or player.CharacterAdded:Wait()
	if character then
		task.wait(0.5) -- Esperar a que el personaje esté completamente cargado
		equipSavedPets()
		print("[PlayerData] Pets equipped on join for", player.Name)
	end

	-- Re-equipar mascotas en cada respawn
	player.CharacterAdded:Connect(function(char)
		task.wait(1)
		equipSavedPets()
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Desequipar todas las mascotas antes de guardar
	if PetManager then
		PetManager:UnequipAllPets(player)
	end

	savePlayerData(player)
	playerDataCache[player.UserId] = nil
end)

-- Guardar datos periódicamente (cada 5 minutos)
task.spawn(function()
	while true do
		task.wait(300) -- 5 minutos
		for _, player in ipairs(Players:GetPlayers()) do
			savePlayerData(player)
		end
		print("[PlayerData] Auto-save completed")
	end
end)

-- Guardar al cerrar el servidor
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)

-- ============================================
-- BINDABLE FUNCTIONS PARA OTROS SCRIPTS DEL SERVIDOR
-- ============================================
local serverFolder = Instance.new("Folder")
serverFolder.Name = "ServerFunctions"
serverFolder.Parent = ReplicatedStorage

local getDataBindable = Instance.new("BindableFunction")
getDataBindable.Name = "GetPlayerDataServer"
getDataBindable.Parent = serverFolder

local modifyCoinsBindable = Instance.new("BindableFunction")
modifyCoinsBindable.Name = "ModifyCoinsServer"
modifyCoinsBindable.Parent = serverFolder

local modifyTrophiesBindable = Instance.new("BindableFunction")
modifyTrophiesBindable.Name = "ModifyTrophiesServer"
modifyTrophiesBindable.Parent = serverFolder

local unlockZoneBindable = Instance.new("BindableFunction")
unlockZoneBindable.Name = "UnlockZoneServer"
unlockZoneBindable.Parent = serverFolder

local unlockFoodBindable = Instance.new("BindableFunction")
unlockFoodBindable.Name = "UnlockFoodServer"
unlockFoodBindable.Parent = serverFolder

local hasFoodBindable = Instance.new("BindableFunction")
hasFoodBindable.Name = "HasFoodUnlocked"
hasFoodBindable.Parent = serverFolder

local unlockBaseBindable = Instance.new("BindableFunction")
unlockBaseBindable.Name = "UnlockBaseServer"
unlockBaseBindable.Parent = serverFolder

local hasBaseBindable = Instance.new("BindableFunction")
hasBaseBindable.Name = "HasBaseUnlocked"
hasBaseBindable.Parent = serverFolder

-- Obtener datos del jugador (para otros scripts del servidor)
getDataBindable.OnInvoke = function(player)
	local data = getPlayerData(player)
	if not data then return nil end
	return {
		Data = data,
		UpgradeValues = getPlayerUpgradeValues(player),
	}
end

-- Modificar monedas del jugador (para otros scripts del servidor)
modifyCoinsBindable.OnInvoke = function(player, amount)
	local data = getPlayerData(player)
	if not data then return false end

	-- Verificar si tiene suficientes monedas (si es negativo)
	if amount < 0 and data.Coins < math.abs(amount) then
		return false, "Insufficient coins"
	end

	data.Coins = data.Coins + amount

	updatePlayerData(player, {
		Coins = data.Coins
	})

	return true, data.Coins
end

-- Modificar trofeos del jugador (para otros scripts del servidor)
modifyTrophiesBindable.OnInvoke = function(player, amount)
	local data = getPlayerData(player)
	if not data then return false end

	-- Verificar si tiene suficientes trofeos (si es negativo)
	if amount < 0 and data.Trophies < math.abs(amount) then
		return false, "Insufficient trophies"
	end

	data.Trophies = data.Trophies + amount

	updatePlayerData(player, {
		Trophies = data.Trophies
	})

	return true, data.Trophies
end

-- Desbloquear zona del jugador (para otros scripts del servidor)
unlockZoneBindable.OnInvoke = function(player, zoneName)
	local data = getPlayerData(player)
	if not data then return false end

	-- Inicializar si no existe
	if not data.UnlockedZones then
		data.UnlockedZones = {}
	end

	-- Verificar si ya está desbloqueada
	if data.UnlockedZones[zoneName] then
		return true, "Already unlocked"
	end

	-- Desbloquear
	data.UnlockedZones[zoneName] = true

	updatePlayerData(player, {
		UnlockedZones = data.UnlockedZones
	})

	print("[PlayerData] Zone unlocked:", player.Name, "->", zoneName)
	return true, "Unlocked"
end

-- Verificar si el jugador tiene una comida desbloqueada
hasFoodBindable.OnInvoke = function(player, foodType)
	-- Salad siempre está desbloqueada
	if foodType == "Salad" then return true end

	local data = getPlayerData(player)
	if not data then return false end

	if not data.UnlockedFood then
		data.UnlockedFood = { Salad = true }
	end

	return data.UnlockedFood[foodType] or false
end

-- Desbloquear comida del jugador
unlockFoodBindable.OnInvoke = function(player, foodType)
	local data = getPlayerData(player)
	if not data then return false end

	-- Salad siempre está desbloqueada
	if foodType == "Salad" then
		return true, "Always unlocked"
	end

	-- Inicializar si no existe
	if not data.UnlockedFood then
		data.UnlockedFood = { Salad = true }
	end

	-- Verificar si ya está desbloqueada
	if data.UnlockedFood[foodType] then
		return true, "Already unlocked"
	end

	-- Desbloquear
	data.UnlockedFood[foodType] = true

	updatePlayerData(player, {
		UnlockedFood = data.UnlockedFood
	})

	print("[PlayerData] Food unlocked:", player.Name, "->", foodType)
	return true, "Unlocked"
end

-- Verificar si el jugador tiene una base desbloqueada
hasBaseBindable.OnInvoke = function(player, baseName)
	local data = getPlayerData(player)
	if not data then return false end

	if not data.UnlockedBases then
		data.UnlockedBases = {}
	end

	return data.UnlockedBases[baseName] or false
end

-- Desbloquear base del jugador
unlockBaseBindable.OnInvoke = function(player, baseName)
	local data = getPlayerData(player)
	if not data then return false end

	-- Inicializar si no existe
	if not data.UnlockedBases then
		data.UnlockedBases = {}
	end

	-- Verificar si ya está desbloqueada
	if data.UnlockedBases[baseName] then
		return true, "Already unlocked"
	end

	-- Desbloquear
	data.UnlockedBases[baseName] = true

	updatePlayerData(player, {
		UnlockedBases = data.UnlockedBases
	})

	print("[PlayerData] Base unlocked:", player.Name, "->", baseName)
	return true, "Unlocked"
end

-- ============================================
-- ROBUX LEADERBOARD BINDABLES
-- ============================================
local getRobuxLeaderboardBindable = Instance.new("BindableFunction")
getRobuxLeaderboardBindable.Name = "GetRobuxLeaderboard"
getRobuxLeaderboardBindable.Parent = serverFolder

getRobuxLeaderboardBindable.OnInvoke = function()
	return getRobuxLeaderboard()
end

local getPlayerRobuxSpentBindable = Instance.new("BindableFunction")
getPlayerRobuxSpentBindable.Name = "GetPlayerRobuxSpent"
getPlayerRobuxSpentBindable.Parent = serverFolder

getPlayerRobuxSpentBindable.OnInvoke = function(player)
	local data = getPlayerData(player)
	if not data then return 0 end
	return data.RobuxSpent or 0
end

print("[PlayerData] Data system initialized")
