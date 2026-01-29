-- DesbloqueoZonasServer.lua
-- Coloca este script en ServerScriptService

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

print("🚀 DesbloqueoZonasServer iniciando...")

-- Esperar a que ReplicatedStorage esté disponible
if not ReplicatedStorage then
	warn("❌ ReplicatedStorage no disponible")
	return
end

-- ========== CONFIGURACIÓN DE ZONAS ==========
local ZONES_CONFIG = {
	{
		ZonePath = "Zonas",
		ZoneName = "Zona1",
		CoinsCost = 5000,
		RobuxCost = 10,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona2",
		CoinsCost = 10000,
		RobuxCost = 20,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona3",
		CoinsCost = 15000,
		RobuxCost = 30,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona4",
		CoinsCost = 25000,
		RobuxCost = 50,
	},
	{
		ZonePath = "Zonas",
		ZoneName = "Zona5",
		CoinsCost = 50000,
		RobuxCost = 100,
	},
}
-- ============================================

-- Esperar o crear carpeta Remotes
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
	print("✅ Carpeta Remotes creada")
else
	print("✅ Carpeta Remotes encontrada")
end

-- Crear RemoteEvents
local showZoneUIRemote = remotesFolder:FindFirstChild("ShowUnlockZoneUI")
if not showZoneUIRemote then
	showZoneUIRemote = Instance.new("RemoteEvent")
	showZoneUIRemote.Name = "ShowUnlockZoneUI"
	showZoneUIRemote.Parent = remotesFolder
	print("✅ ShowUnlockZoneUI creado")
end

local unlockZoneRemote = remotesFolder:FindFirstChild("UnlockZoneRemote")
if not unlockZoneRemote then
	unlockZoneRemote = Instance.new("RemoteEvent")
	unlockZoneRemote.Name = "UnlockZoneRemote"
	unlockZoneRemote.Parent = remotesFolder
	print("✅ UnlockZoneRemote creado")
end

local makeInvisibleRemote = remotesFolder:FindFirstChild("MakeZoneInvisible")
if not makeInvisibleRemote then
	makeInvisibleRemote = Instance.new("RemoteEvent")
	makeInvisibleRemote.Name = "MakeZoneInvisible"
	makeInvisibleRemote.Parent = remotesFolder
	print("✅ MakeZoneInvisible creado")
end

print("✅ Todos los RemoteEvents configurados")

-- Almacenar zonas desbloqueadas por jugador
local playerUnlockedZones = {}

-- Función para verificar si una zona está desbloqueada
local function isZoneUnlocked(player, zoneName)
	if not playerUnlockedZones[player] then
		playerUnlockedZones[player] = {}
	end
	return playerUnlockedZones[player][zoneName] or false
end

-- Función para desbloquear zona
local function unlockZone(player, zoneName)
	if not playerUnlockedZones[player] then
		playerUnlockedZones[player] = {}
	end
	playerUnlockedZones[player][zoneName] = true
	print("🔓 " .. zoneName .. " desbloqueada para " .. player.Name)
end

-- Función para hacer zona invisible (envia al cliente)
local function makeZonePassable(player, zoneName)
	makeInvisibleRemote:FireClient(player, zoneName)
	print("📤 Enviado comando de invisibilidad para " .. zoneName)
end

-- Configurar detectores de proximidad para cada zona
local zonesConfigured = 0

for _, config in ipairs(ZONES_CONFIG) do
	local zonesFolder = Workspace:FindFirstChild(config.ZonePath)

	if not zonesFolder then
		warn("⚠️ Carpeta no encontrada: " .. config.ZonePath)
		continue
	end

	local zone = zonesFolder:FindFirstChild(config.ZoneName)

	if not zone then
		warn("⚠️ Zona no encontrada: " .. config.ZoneName)
		continue
	end

	-- Buscar el primer BasePart
	local triggerPart = nil
	for _, child in ipairs(zone:GetDescendants()) do
		if child:IsA("BasePart") then
			triggerPart = child
			break
		end
	end

	if not triggerPart then
		warn("⚠️ No hay Parts en " .. config.ZoneName)
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

		-- Cooldown de 5 segundos (aumentado para evitar spam)
		local now = os.clock()
		if playerCooldowns[player] and now - playerCooldowns[player] < 5 then
			return
		end

		playerCooldowns[player] = now

		print("👣 " .. player.Name .. " tocó " .. config.ZoneName)

		-- Verificar si ya está desbloqueada
		if isZoneUnlocked(player, config.ZoneName) then
			print("⚠️ Ya desbloqueada para " .. player.Name)
			return
		end

		-- Enviar UI al cliente
		print("📤 Enviando UI para " .. config.ZoneName .. " a " .. player.Name)
		showZoneUIRemote:FireClient(player, config.ZoneName, config.CoinsCost, config.RobuxCost)
	end)

	zonesConfigured = zonesConfigured + 1
	print("✅ Sistema configurado para " .. config.ZoneName)
end

print("✅ Total de zonas configuradas: " .. zonesConfigured .. "/" .. #ZONES_CONFIG)

-- Manejar desbloqueo de zonas
unlockZoneRemote.OnServerEvent:Connect(function(player, zoneName, paymentType)
	print("💰 Solicitud de desbloqueo de " .. player.Name .. " para " .. zoneName .. " (" .. paymentType .. ")")

	-- Buscar configuración
	local config = nil
	for _, zoneConfig in ipairs(ZONES_CONFIG) do
		if zoneConfig.ZoneName == zoneName then
			config = zoneConfig
			break
		end
	end

	if not config then
		warn("❌ Configuración no encontrada: " .. zoneName)
		return
	end

	-- Verificar si ya está desbloqueada
	if isZoneUnlocked(player, zoneName) then
		warn("⚠️ Ya desbloqueada")
		return
	end

	-- Obtener datos usando GetPlayerData (función del servidor, no remote)
	local getPlayerDataFunc = remotesFolder:FindFirstChild("GetPlayerData")
	if not getPlayerDataFunc or not getPlayerDataFunc.OnServerInvoke then
		warn("❌ GetPlayerData no disponible")
		return
	end

	local result = getPlayerDataFunc.OnServerInvoke(player)
	if not result or not result.Data then
		warn("❌ No se pudieron obtener datos")
		return
	end

	local playerData = result.Data
	local currentCoins = playerData.Coins or 0

	print("💵 Monedas actuales: " .. currentCoins .. " / Costo: " .. config.CoinsCost)

	-- PROCESAR PAGO
	if paymentType == "coins" then
		-- Verificar que tenga suficientes monedas
		if currentCoins < config.CoinsCost then
			warn("❌ Monedas insuficientes: " .. currentCoins .. "/" .. config.CoinsCost)
			return
		end

		-- Descontar monedas NEGATIVAMENTE (restar monedas usando CollectCoin)
		local collectCoinFunc = remotesFolder:FindFirstChild("CollectCoin")
		if collectCoinFunc and collectCoinFunc.OnServerInvoke then
			-- Descontar usando valor negativo
			collectCoinFunc.OnServerInvoke(player, -config.CoinsCost)
			print("✅ Monedas descontadas: -" .. config.CoinsCost)
		else
			warn("⚠️ No se pudo descontar monedas, pero se desbloqueará la zona")
		end

		-- Desbloquear zona
		unlockZone(player, zoneName)
		makeZonePassable(player, zoneName)

		print("✅ " .. player.Name .. " desbloqueó " .. zoneName)

	elseif paymentType == "robux" then
		warn("⚠️ Pago con Robux (testing - desbloqueado gratis)")
		unlockZone(player, zoneName)
		makeZonePassable(player, zoneName)
	end
end)

-- Limpiar al desconectar
Players.PlayerRemoving:Connect(function(player)
	playerUnlockedZones[player] = nil
	print("🧹 Datos limpiados para " .. player.Name)
end)

-- ============================================
-- REMOTEEVENTS PARA OTROS SISTEMAS
-- ============================================

-- Crear RemoteEvents que otros scripts necesitan
local onDataLoaded = remotesFolder:FindFirstChild("OnDataLoaded")
if not onDataLoaded then
	onDataLoaded = Instance.new("RemoteEvent")
	onDataLoaded.Name = "OnDataLoaded"
	onDataLoaded.Parent = remotesFolder
	print("✅ OnDataLoaded creado")
end

local onDataUpdated = remotesFolder:FindFirstChild("OnDataUpdated")
if not onDataUpdated then
	onDataUpdated = Instance.new("RemoteEvent")
	onDataUpdated.Name = "OnDataUpdated"
	onDataUpdated.Parent = remotesFolder
	print("✅ OnDataUpdated creado")
end

local getPlayerData = remotesFolder:FindFirstChild("GetPlayerData")
if not getPlayerData then
	getPlayerData = Instance.new("RemoteFunction")
	getPlayerData.Name = "GetPlayerData"
	getPlayerData.Parent = remotesFolder
	print("✅ GetPlayerData creado")
end

local registerHeight = remotesFolder:FindFirstChild("RegisterHeight")
if not registerHeight then
	registerHeight = Instance.new("RemoteFunction")
	registerHeight.Name = "RegisterHeight"
	registerHeight.Parent = remotesFolder
	print("✅ RegisterHeight creado")
end

print("✅ Sistema de zonas desbloqueables COMPLETAMENTE inicializado")
