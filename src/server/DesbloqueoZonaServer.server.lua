-- DesbloqueoZonasServer.lua
-- Sistema de zonas desbloqueables con PERSISTENCIA
-- COMPATIBLE con PlayerData.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("[Zonas] Iniciando sistema de zonas desbloqueables...")

-- ========== CONFIGURACIÓN DE ZONAS ==========
local ZONES_CONFIG = {
	-- ========== BASE (antes en DesbloqueoBaseServer) ==========
	-- ZonePath = nil significa que está directamente en Workspace
	{
		ZonePath = nil,
		ZoneName = "BloqueoBase1",
		TrophyCost = 500,
		RobuxCost = 500,
		DisplayName = "Base Secreta",
	},

	-- ========== ZONAS NORMALES (trofeos o Robux) ==========
	{
		ZonePath = "Zonas",
		ZoneName = "Zona1",
		TrophyCost = 10,
		RobuxCost = 19,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona2",
		TrophyCost = 25,
		RobuxCost = 39,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona3",
		TrophyCost = 50,
		RobuxCost = 69,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona4",
		TrophyCost = 100,
		RobuxCost = 99,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona5",
		TrophyCost = 250,
		RobuxCost = 399,
	},

	-- ========== ZONAS VIP (Solo Robux) ==========
	-- VIPOnly = true hace que solo aparezca el botón de Robux
	{
		ZonePath = "Zonas",
		ZoneName = "VIP1",
		RobuxCost = 49,      -- Cambia este valor
		VIPOnly = true,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "VIP2",
		RobuxCost = 99,     -- Cambia este valor
		VIPOnly = true,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "VIP3",
		RobuxCost = 149,     -- Cambia este valor
		VIPOnly = true,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "VIP4",
		RobuxCost = 199,     -- Cambia este valor
		VIPOnly = true,
	},
	-- Agrega más zonas VIP aquí:
	-- {
	-- 	ZonePath = "Zonas",
	-- 	ZoneName = "VIP4",
	-- 	RobuxCost = 200,
	-- 	VIPOnly = true,
	-- },
}
-- ============================================

-- Esperar a que PlayerData cree la carpeta Remotes
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotesFolder then
	warn("[Zonas] No se encontró la carpeta Remotes. Asegúrate de que PlayerData.server.lua esté funcionando.")
	return
end
print("[Zonas] Carpeta Remotes encontrada")

-- Esperar a que PlayerData cree ServerFunctions
local serverFolder = ReplicatedStorage:WaitForChild("ServerFunctions", 30)
if not serverFolder then
	warn("[Zonas] No se encontró ServerFunctions. Asegúrate de que PlayerData.server.lua esté actualizado.")
	return
end

-- Obtener BindableFunctions para comunicación servidor-servidor
local getPlayerDataServer = serverFolder:WaitForChild("GetPlayerDataServer", 10)
local modifyCoinsServer = serverFolder:WaitForChild("ModifyCoinsServer", 10)
local modifyTrophiesServer = serverFolder:WaitForChild("ModifyTrophiesServer", 10)
local unlockZoneServer = serverFolder:WaitForChild("UnlockZoneServer", 10)

if not getPlayerDataServer or not modifyCoinsServer or not modifyTrophiesServer or not unlockZoneServer then
	warn("[Zonas] No se encontraron las BindableFunctions del servidor.")
	return
end
print("[Zonas] BindableFunctions del servidor encontradas")

-- Crear RemoteEvents SOLO para el sistema de zonas
local showZoneUIRemote = remotesFolder:FindFirstChild("ShowUnlockZoneUI")
if not showZoneUIRemote then
	showZoneUIRemote = Instance.new("RemoteEvent")
	showZoneUIRemote.Name = "ShowUnlockZoneUI"
	showZoneUIRemote.Parent = remotesFolder
end

local unlockZoneRemote = remotesFolder:FindFirstChild("UnlockZoneRemote")
if not unlockZoneRemote then
	unlockZoneRemote = Instance.new("RemoteEvent")
	unlockZoneRemote.Name = "UnlockZoneRemote"
	unlockZoneRemote.Parent = remotesFolder
end

local makeInvisibleRemote = remotesFolder:FindFirstChild("MakeZoneInvisible")
if not makeInvisibleRemote then
	makeInvisibleRemote = Instance.new("RemoteEvent")
	makeInvisibleRemote.Name = "MakeZoneInvisible"
	makeInvisibleRemote.Parent = remotesFolder
end

local insufficientFundsRemote = remotesFolder:FindFirstChild("ZoneInsufficientFunds")
if not insufficientFundsRemote then
	insufficientFundsRemote = Instance.new("RemoteEvent")
	insufficientFundsRemote.Name = "ZoneInsufficientFunds"
	insufficientFundsRemote.Parent = remotesFolder
end

-- Cache local para evitar consultas repetidas (sincronizado con persistencia)
local playerZonesCache = {}

-- Función para verificar si una zona está desbloqueada (usa persistencia)
local function isZoneUnlocked(player, zoneName)
	-- Primero revisar cache local
	if playerZonesCache[player] and playerZonesCache[player][zoneName] then
		return true
	end

	-- Si no está en cache, consultar datos persistentes
	local playerInfo = getPlayerDataServer:Invoke(player)
	if playerInfo and playerInfo.Data and playerInfo.Data.UnlockedZones then
		return playerInfo.Data.UnlockedZones[zoneName] or false
	end

	return false
end

-- Función para desbloquear zona (guarda en persistencia)
local function unlockZone(player, zoneName)
	-- Guardar en persistencia usando BindableFunction
	local success, message = unlockZoneServer:Invoke(player, zoneName)

	if success then
		-- Actualizar cache local
		if not playerZonesCache[player] then
			playerZonesCache[player] = {}
		end
		playerZonesCache[player][zoneName] = true
		print("[Zonas] " .. zoneName .. " desbloqueada y guardada para " .. player.Name)
	else
		warn("[Zonas] Error al guardar zona: " .. tostring(message))
	end

	return success
end

-- Función para hacer zona invisible (envía al cliente)
local function makeZonePassable(player, zoneName)
	makeInvisibleRemote:FireClient(player, zoneName)
end

-- Función para cargar zonas desbloqueadas del jugador al conectarse
local function loadPlayerZones(player)
	-- Esperar un momento para que PlayerData cargue los datos
	task.wait(2)

	local playerInfo = getPlayerDataServer:Invoke(player)
	if not playerInfo or not playerInfo.Data then
		warn("[Zonas] No se pudieron cargar datos de zonas para " .. player.Name)
		return
	end

	local unlockedZones = playerInfo.Data.UnlockedZones or {}

	-- Guardar en cache local
	playerZonesCache[player] = {}

	-- Hacer invisibles las zonas ya desbloqueadas
	for zoneName, isUnlocked in pairs(unlockedZones) do
		if isUnlocked then
			playerZonesCache[player][zoneName] = true
			makeZonePassable(player, zoneName)
			print("[Zonas] Zona " .. zoneName .. " restaurada para " .. player.Name)
		end
	end

	local count = 0
	for _ in pairs(unlockedZones) do count = count + 1 end
	print("[Zonas] " .. player.Name .. " tiene " .. count .. " zonas desbloqueadas")
end

-- Configurar detectores de proximidad para cada zona
local zonesConfigured = 0

for _, config in ipairs(ZONES_CONFIG) do
	local triggerPart = nil

	if config.ZonePath then
		-- Buscar en carpeta (zonas normales)
		local zonesFolder = Workspace:FindFirstChild(config.ZonePath)

		if not zonesFolder then
			warn("[Zonas] Carpeta no encontrada: " .. config.ZonePath)
			continue
		end

		local zone = zonesFolder:FindFirstChild(config.ZoneName)

		if not zone then
			warn("[Zonas] Zona no encontrada: " .. config.ZoneName)
			continue
		end

		-- Buscar el primer BasePart dentro de la zona
		for _, child in ipairs(zone:GetDescendants()) do
			if child:IsA("BasePart") then
				triggerPart = child
				break
			end
		end
	else
		-- Buscar directamente en Workspace (bases/bloqueos)
		local part = Workspace:FindFirstChild(config.ZoneName)
		if part and part:IsA("BasePart") then
			triggerPart = part
		end
	end

	if not triggerPart then
		warn("[Zonas] No hay Parts válidos para " .. config.ZoneName)
		continue
	end

	-- Sistema de cooldown por jugador
	local playerCooldowns = {}

	-- Detectar cuando un jugador toca la zona
	triggerPart.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		-- Cooldown de 5 segundos
		local now = os.clock()
		if playerCooldowns[player] and now - playerCooldowns[player] < 5 then
			return
		end
		playerCooldowns[player] = now

		-- Verificar si ya está desbloqueada
		if isZoneUnlocked(player, config.ZoneName) then
			return
		end

		-- Enviar UI al cliente (incluye VIPOnly para zonas que solo aceptan Robux, y DisplayName opcional)
		-- Ahora usa TrophyCost en lugar de CoinsCost para zonas normales
		showZoneUIRemote:FireClient(player, config.ZoneName, config.TrophyCost or 0, config.RobuxCost, config.VIPOnly or false, config.DisplayName)
	end)

	zonesConfigured = zonesConfigured + 1
	print("[Zonas] Sistema configurado para " .. config.ZoneName)
end

print("[Zonas] Total de zonas configuradas: " .. zonesConfigured .. "/" .. #ZONES_CONFIG)

-- Manejar desbloqueo de zonas
unlockZoneRemote.OnServerEvent:Connect(function(player, zoneName, paymentType)
	print("[Zonas] Solicitud de desbloqueo de " .. player.Name .. " para " .. zoneName .. " (" .. paymentType .. ")")

	-- Buscar configuración
	local config = nil
	for _, zoneConfig in ipairs(ZONES_CONFIG) do
		if zoneConfig.ZoneName == zoneName then
			config = zoneConfig
			break
		end
	end

	if not config then
		warn("[Zonas] Configuración no encontrada: " .. zoneName)
		return
	end

	-- Verificar si ya está desbloqueada
	if isZoneUnlocked(player, zoneName) then
		warn("[Zonas] Ya desbloqueada para " .. player.Name)
		return
	end

	-- PROCESAR PAGO
	if paymentType == "trophies" then
		-- Verificar que no sea zona VIP (solo Robux)
		if config.VIPOnly then
			warn("[Zonas] " .. zoneName .. " es VIP, solo acepta Robux")
			return
		end

		-- Obtener datos del jugador
		local playerInfo = getPlayerDataServer:Invoke(player)
		if not playerInfo or not playerInfo.Data then
			warn("[Zonas] No se pudieron obtener datos del jugador")
			return
		end

		local currentTrophies = playerInfo.Data.Trophies or 0
		print("[Zonas] Trofeos actuales: " .. currentTrophies .. " / Costo: " .. config.TrophyCost)

		-- Verificar que tenga suficientes trofeos
		if currentTrophies < config.TrophyCost then
			warn("[Zonas] Trofeos insuficientes: " .. currentTrophies .. "/" .. config.TrophyCost)
			-- Enviar notificación al cliente
			insufficientFundsRemote:FireClient(player, zoneName, config.TrophyCost, currentTrophies, "trophies")
			return
		end

		-- Descontar trofeos
		local success, result = modifyTrophiesServer:Invoke(player, -config.TrophyCost)
		if not success then
			warn("[Zonas] Error al descontar trofeos: " .. tostring(result))
			return
		end

		print("[Zonas] Trofeos descontados. Nuevo balance: " .. tostring(result))

		-- Desbloquear zona (guarda en persistencia)
		unlockZone(player, zoneName)
		makeZonePassable(player, zoneName)

	elseif paymentType == "robux" then
		-- TODO: Implementar pago con Robux usando MarketplaceService
		if config.VIPOnly then
			warn("[Zonas VIP] Pago con Robux para " .. zoneName .. " - desbloqueando gratis para testing")
		else
			warn("[Zonas] Pago con Robux no implementado - desbloqueando gratis para testing")
		end
		unlockZone(player, zoneName)
		makeZonePassable(player, zoneName)
	end
end)

-- Cargar zonas cuando un jugador se conecta
Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		loadPlayerZones(player)
	end)
end)

-- Para jugadores que ya están conectados (por si el script carga tarde)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(function()
		loadPlayerZones(player)
	end)
end

-- Limpiar cache al desconectar
Players.PlayerRemoving:Connect(function(player)
	playerZonesCache[player] = nil
end)

print("[Zonas] Sistema de zonas desbloqueables con persistencia inicializado")
