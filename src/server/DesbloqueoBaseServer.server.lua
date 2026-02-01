-- DesbloqueoBaseServer.lua
-- Sistema de bases/teleports desbloqueables con PERSISTENCIA
-- COMPATIBLE con PlayerData.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("[Bases] Iniciando sistema de bases desbloqueables...")

-- ========== CONFIGURACIÓN DE BASES ==========
local BASES_CONFIG = {
	{
		BlockName = "BloqueoBase1", -- Nombre del part de bloqueo en Workspace
		BaseName = "Base1",         -- Nombre interno para persistencia
		CoinsCost = 100000,         -- 100,000$
		RobuxCost = 500,            -- 500 Robux
		DisplayName = "Base Secreta", -- Nombre mostrado en la UI
	},
	-- Puedes agregar más bases aquí:
	-- {
	-- 	BlockName = "BloqueoBase2",
	-- 	BaseName = "Base2",
	-- 	CoinsCost = 250000,
	-- 	RobuxCost = 1000,
	-- 	DisplayName = "Base Premium",
	-- },
}
-- ============================================

-- Esperar a que PlayerData cree la carpeta Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotesFolder then
	warn("[Bases] No se encontró la carpeta Remotes. Asegúrate de que PlayerData.server.lua esté funcionando.")
	return
end
print("[Bases] Carpeta Remotes encontrada")

-- Esperar a que PlayerData cree ServerFunctions
local serverFolder = ReplicatedStorage:WaitForChild("ServerFunctions", 30)
if not serverFolder then
	warn("[Bases] No se encontró ServerFunctions. Asegúrate de que PlayerData.server.lua esté actualizado.")
	return
end

-- Obtener BindableFunctions para comunicación servidor-servidor
local getPlayerDataServer = serverFolder:WaitForChild("GetPlayerDataServer", 10)
local modifyCoinsServer = serverFolder:WaitForChild("ModifyCoinsServer", 10)
local unlockBaseServer = serverFolder:WaitForChild("UnlockBaseServer", 10)
local hasBaseUnlocked = serverFolder:WaitForChild("HasBaseUnlocked", 10)

if not getPlayerDataServer or not modifyCoinsServer or not unlockBaseServer or not hasBaseUnlocked then
	warn("[Bases] No se encontraron las BindableFunctions del servidor.")
	return
end
print("[Bases] BindableFunctions del servidor encontradas")

-- Crear RemoteEvents SOLO para el sistema de bases
local showBaseUIRemote = remotesFolder:FindFirstChild("ShowUnlockBaseUI")
if not showBaseUIRemote then
	showBaseUIRemote = Instance.new("RemoteEvent")
	showBaseUIRemote.Name = "ShowUnlockBaseUI"
	showBaseUIRemote.Parent = remotesFolder
end

local unlockBaseRemote = remotesFolder:FindFirstChild("UnlockBaseRemote")
if not unlockBaseRemote then
	unlockBaseRemote = Instance.new("RemoteEvent")
	unlockBaseRemote.Name = "UnlockBaseRemote"
	unlockBaseRemote.Parent = remotesFolder
end

local makeBaseInvisibleRemote = remotesFolder:FindFirstChild("MakeBaseInvisible")
if not makeBaseInvisibleRemote then
	makeBaseInvisibleRemote = Instance.new("RemoteEvent")
	makeBaseInvisibleRemote.Name = "MakeBaseInvisible"
	makeBaseInvisibleRemote.Parent = remotesFolder
end

local insufficientFundsRemote = remotesFolder:FindFirstChild("BaseInsufficientFunds")
if not insufficientFundsRemote then
	insufficientFundsRemote = Instance.new("RemoteEvent")
	insufficientFundsRemote.Name = "BaseInsufficientFunds"
	insufficientFundsRemote.Parent = remotesFolder
end

-- Crear BindableEvent para que otros scripts verifiquen si una base está desbloqueada
local checkBaseUnlocked = serverFolder:FindFirstChild("CheckBaseUnlocked")
if not checkBaseUnlocked then
	checkBaseUnlocked = Instance.new("BindableFunction")
	checkBaseUnlocked.Name = "CheckBaseUnlocked"
	checkBaseUnlocked.Parent = serverFolder
end

-- Cache local para evitar consultas repetidas (sincronizado con persistencia)
local playerBasesCache = {}

-- Función para verificar si una base está desbloqueada (usa persistencia)
local function isBaseUnlocked(player, baseName)
	-- Primero revisar cache local
	if playerBasesCache[player] and playerBasesCache[player][baseName] then
		return true
	end

	-- Si no está en cache, consultar datos persistentes
	local isUnlocked = hasBaseUnlocked:Invoke(player, baseName)
	return isUnlocked or false
end

-- Implementar la función para que otros scripts puedan verificar
checkBaseUnlocked.OnInvoke = function(player, baseName)
	return isBaseUnlocked(player, baseName)
end

-- Función para desbloquear base (guarda en persistencia)
local function unlockBase(player, baseName)
	-- Guardar en persistencia usando BindableFunction
	local success, message = unlockBaseServer:Invoke(player, baseName)

	if success then
		-- Actualizar cache local
		if not playerBasesCache[player] then
			playerBasesCache[player] = {}
		end
		playerBasesCache[player][baseName] = true
		print("[Bases] " .. baseName .. " desbloqueada y guardada para " .. player.Name)
	else
		warn("[Bases] Error al guardar base: " .. tostring(message))
	end

	return success
end

-- Función para hacer base invisible (envía al cliente)
local function makeBasePassable(player, baseName, blockName)
	makeBaseInvisibleRemote:FireClient(player, baseName, blockName)
end

-- Función para cargar bases desbloqueadas del jugador al conectarse
local function loadPlayerBases(player)
	-- Esperar un momento para que PlayerData cargue los datos
	task.wait(2)

	local playerInfo = getPlayerDataServer:Invoke(player)
	if not playerInfo or not playerInfo.Data then
		warn("[Bases] No se pudieron cargar datos de bases para " .. player.Name)
		return
	end

	local unlockedBases = playerInfo.Data.UnlockedBases or {}

	-- Guardar en cache local
	playerBasesCache[player] = {}

	-- Hacer invisibles las bases ya desbloqueadas
	for baseName, isUnlocked in pairs(unlockedBases) do
		if isUnlocked then
			playerBasesCache[player][baseName] = true

			-- Encontrar el nombre del bloqueo correspondiente
			for _, config in ipairs(BASES_CONFIG) do
				if config.BaseName == baseName then
					makeBasePassable(player, baseName, config.BlockName)
					break
				end
			end

			print("[Bases] Base " .. baseName .. " restaurada para " .. player.Name)
		end
	end

	local count = 0
	for _ in pairs(unlockedBases) do count = count + 1 end
	print("[Bases] " .. player.Name .. " tiene " .. count .. " bases desbloqueadas")
end

-- Configurar detectores de proximidad para cada bloqueo
local basesConfigured = 0

for _, config in ipairs(BASES_CONFIG) do
	local blockPart = Workspace:FindFirstChild(config.BlockName)

	if not blockPart then
		warn("[Bases] Bloqueo no encontrado: " .. config.BlockName)
		continue
	end

	-- Sistema de cooldown por jugador
	local playerCooldowns = {}

	-- Detectar cuando un jugador toca el bloqueo
	blockPart.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Cooldown de 3 segundos
		local now = os.clock()
		if playerCooldowns[player] and now - playerCooldowns[player] < 3 then
			return
		end
		playerCooldowns[player] = now

		-- Verificar si ya está desbloqueada
		if isBaseUnlocked(player, config.BaseName) then
			return
		end

		-- Enviar UI al cliente
		showBaseUIRemote:FireClient(player, config.BaseName, config.CoinsCost, config.RobuxCost, config.DisplayName, config.BlockName)
	end)

	basesConfigured = basesConfigured + 1
	print("[Bases] Sistema configurado para " .. config.BlockName .. " (" .. config.BaseName .. ")")
end

print("[Bases] Total de bases configuradas: " .. basesConfigured .. "/" .. #BASES_CONFIG)

-- Manejar desbloqueo de bases
unlockBaseRemote.OnServerEvent:Connect(function(player, baseName, paymentType)
	print("[Bases] Solicitud de desbloqueo de " .. player.Name .. " para " .. baseName .. " (" .. paymentType .. ")")

	-- Buscar configuración
	local config = nil
	for _, baseConfig in ipairs(BASES_CONFIG) do
		if baseConfig.BaseName == baseName then
			config = baseConfig
			break
		end
	end

	if not config then
		warn("[Bases] Configuración no encontrada: " .. baseName)
		return
	end

	-- Verificar si ya está desbloqueada
	if isBaseUnlocked(player, baseName) then
		warn("[Bases] Ya desbloqueada para " .. player.Name)
		return
	end

	-- PROCESAR PAGO
	if paymentType == "coins" then
		-- Obtener datos del jugador
		local playerInfo = getPlayerDataServer:Invoke(player)
		if not playerInfo or not playerInfo.Data then
			warn("[Bases] No se pudieron obtener datos del jugador")
			return
		end

		local currentCoins = playerInfo.Data.Coins or 0
		print("[Bases] Monedas actuales: " .. currentCoins .. " / Costo: " .. config.CoinsCost)

		-- Verificar que tenga suficientes monedas
		if currentCoins < config.CoinsCost then
			warn("[Bases] Monedas insuficientes: " .. currentCoins .. "/" .. config.CoinsCost)
			-- Enviar notificación al cliente
			insufficientFundsRemote:FireClient(player, baseName, config.CoinsCost, currentCoins)
			return
		end

		-- Descontar monedas
		local success, result = modifyCoinsServer:Invoke(player, -config.CoinsCost)
		if not success then
			warn("[Bases] Error al descontar monedas: " .. tostring(result))
			return
		end

		print("[Bases] Monedas descontadas. Nuevo balance: " .. tostring(result))

		-- Desbloquear base (guarda en persistencia)
		unlockBase(player, baseName)
		makeBasePassable(player, baseName, config.BlockName)

	elseif paymentType == "robux" then
		-- TODO: Implementar pago con Robux usando MarketplaceService
		warn("[Bases] Pago con Robux no implementado - desbloqueando gratis para testing")
		unlockBase(player, baseName)
		makeBasePassable(player, baseName, config.BlockName)
	end
end)

-- Cargar bases cuando un jugador se conecta
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		loadPlayerBases(player)
	end)
end)

-- Para jugadores que ya están conectados (por si el script carga tarde)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		loadPlayerBases(player)
	end)
end

-- Limpiar cache al desconectar
Players.PlayerRemoving:Connect(function(player)
	playerBasesCache[player] = nil
end)

print("[Bases] Sistema de bases desbloqueables con persistencia inicializado")
