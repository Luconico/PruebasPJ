--[[
	PlayerData.server.lua
	Sistema de gestión de datos del jugador
	Autoridad del servidor para evitar cheats
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar a que exista Shared
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

-- DataStore
local DATA_STORE_NAME = "FartTycoon_PlayerData_v1"
local playerDataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)

-- Cache de datos en memoria
local playerDataCache = {}

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
	}

	-- Funciones (con respuesta)
	local functions = {
		"GetPlayerData",     -- Cliente → Servidor: obtener datos
		"PurchaseUpgrade",   -- Cliente → Servidor: comprar upgrade
		"PurchaseFood",      -- Cliente → Servidor: desbloquear comida
		"UpdateFatness",     -- Cliente → Servidor: sincronizar gordura
		"RegisterHeight",    -- Cliente → Servidor: registrar altura alcanzada
		"CollectCoin",       -- Cliente → Servidor: recoger moneda
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
		print("[PlayerData] Datos cargados para", player.Name)
		return playerData
	else
		warn("[PlayerData] Error cargando datos para", player.Name, ":", data)
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
		warn("[PlayerData] No hay datos para guardar de", player.Name)
		return false
	end

	local success, errorMessage = pcall(function()
		playerDataStore:SetAsync(key, data)
	end)

	if success then
		print("[PlayerData] Datos guardados para", player.Name)
		return true
	else
		warn("[PlayerData] Error guardando datos para", player.Name, ":", errorMessage)
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

	return upgradeConfig.BaseValue + (upgradeConfig.IncrementPerLevel * level)
end

-- Obtener todos los valores calculados de upgrades del jugador
local function getPlayerUpgradeValues(player)
	local data = getPlayerData(player)
	if not data then return nil end

	return {
		MaxFatness = getUpgradeValue("MaxFatness", data.Upgrades.MaxFatness),
		EatSpeed = getUpgradeValue("EatSpeed", data.Upgrades.EatSpeed),
		PropulsionForce = getUpgradeValue("PropulsionForce", data.Upgrades.PropulsionForce),
		FuelEfficiency = getUpgradeValue("FuelEfficiency", data.Upgrades.FuelEfficiency),
	}
end

-- Comprar un upgrade
local function purchaseUpgrade(player, upgradeName, useRobux)
	local data = getPlayerData(player)
	if not data then return false, "Datos no disponibles" end

	local upgradeConfig = Config.Upgrades[upgradeName]
	if not upgradeConfig then return false, "Upgrade no existe" end

	local currentLevel = data.Upgrades[upgradeName] or 0
	if currentLevel >= upgradeConfig.MaxLevel then
		return false, "Nivel máximo alcanzado"
	end

	local nextLevel = currentLevel + 1
	local cost = useRobux
		and upgradeConfig.CostRobux[nextLevel]
		or upgradeConfig.CostCoins[nextLevel]

	if not useRobux then
		-- Compra con monedas
		if data.Coins < cost then
			return false, "Monedas insuficientes"
		end

		data.Coins = data.Coins - cost
		data.Upgrades[upgradeName] = nextLevel

		updatePlayerData(player, {
			Coins = data.Coins,
			Upgrades = data.Upgrades
		})

		return true, "Compra exitosa"
	else
		-- Compra con Robux (aquí iría la integración con MarketplaceService)
		-- Por ahora, solo simulamos
		data.Upgrades[upgradeName] = nextLevel

		updatePlayerData(player, {
			Upgrades = data.Upgrades
		})

		return true, "Compra exitosa (Robux)"
	end
end

-- ============================================
-- FUNCIONES DE JUEGO
-- ============================================

-- Recoger una moneda
local function collectCoin(player, coinValue)
	local data = getPlayerData(player)
	if not data then return false end

	coinValue = coinValue or Config.Rewards.CoinValue
	data.Coins = data.Coins + coinValue
	data.Records.TotalCoinsEarned = data.Records.TotalCoinsEarned + coinValue

	updatePlayerData(player, {
		Coins = data.Coins,
		Records = data.Records
	})

	Remotes.OnCoinCollected:FireClient(player, coinValue, data.Coins)
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
	return {
		Data = data,
		UpgradeValues = upgradeValues,
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

Remotes.RegisterHeight.OnServerInvoke = function(player, height)
	return registerHeight(player, height)
end

-- ============================================
-- EVENTOS DE JUGADOR
-- ============================================

Players.PlayerAdded:Connect(function(player)
	local data = loadPlayerData(player)
	local upgradeValues = getPlayerUpgradeValues(player)

	-- Esperar un momento para que el cliente esté listo
	task.wait(1)

	-- Enviar datos al cliente
	Remotes.OnDataLoaded:FireClient(player, {
		Data = data,
		UpgradeValues = upgradeValues,
		Config = {
			Fatness = Config.Fatness,
			Rewards = Config.Rewards,
		}
	})
end)

Players.PlayerRemoving:Connect(function(player)
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
		print("[PlayerData] Auto-guardado completado")
	end
end)

-- Guardar al cerrar el servidor
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		savePlayerData(player)
	end
end)

print("[PlayerData] Sistema de datos inicializado")
