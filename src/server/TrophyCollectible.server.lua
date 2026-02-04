-- TrophyCollectible.server.lua
-- Gestor central de trofeos coleccionables
-- Detecta automáticamente cualquier Part en el workspace con atributo "TrophyValue"
--
-- USO: Crear un Part en el workspace y añadirle el atributo "TrophyValue" (number)
-- El sistema lo detectará automáticamente y lo convertirá en un trofeo coleccionable

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local RESPAWN_HEIGHT_THRESHOLD = 10 -- metros
local TROPHY_TAG = "TrophyCollectible" -- Tag opcional para CollectionService

-- Esperar a que los Remotes existan
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CollectTrophyInternal = Remotes:WaitForChild("CollectTrophyInternal") -- BindableFunction servidor-servidor
local OnTrophyVisibility = Remotes:WaitForChild("OnTrophyVisibility")

-- Tracking global
local trophyParts = {} -- {[part] = {value = number, collectedBy = {[userId] = true}}}
local playerConnections = {} -- {[userId] = connection}
local touchCooldowns = {} -- {[part] = {[userId] = lastTouchTime}}

-- ============================================
-- FUNCIONES DE TELEPORT
-- ============================================

-- Busca el part de destino TP en el workspace
local function findTPDestination(tpNumber)
	local tpName = "TP" .. tostring(tpNumber)

	-- Primero intentar en workspace.Teleports
	local teleportsFolder = workspace:FindFirstChild("Teleports")
	if teleportsFolder then
		local tpPart = teleportsFolder:FindFirstChild(tpName)
		if tpPart then
			return tpPart
		end
	end

	-- Si no se encontró, buscar en todo el workspace
	return workspace:FindFirstChild(tpName, true)
end

-- Teleporta un jugador a un destino TP
local function teleportPlayerToTP(player, tpNumber)
	local character = player.Character
	if not character then return false end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end

	local destination = findTPDestination(tpNumber)
	if not destination or not destination:IsA("BasePart") then
		warn("[TrophyCollectible] No se encontró TP" .. tostring(tpNumber))
		return false
	end

	-- Teleportar
	humanoidRootPart.CFrame = destination.CFrame + Vector3.new(0, 3, 0)
	return true
end

-- Registrar un Part como trofeo
local function registerTrophy(part)
	local trophyValue = part:GetAttribute("TrophyValue")
	if not trophyValue or trophyValue <= 0 then return end

	-- Ya está registrado?
	if trophyParts[part] then return end

	trophyParts[part] = {
		value = trophyValue,
		collectedBy = {},
		connection = nil
	}
	touchCooldowns[part] = {}

	-- Conectar evento Touched
	trophyParts[part].connection = part.Touched:Connect(function(hit)
		local character = hit.Parent
		if not character then return end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then return end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then return end

		local trophyData = trophyParts[part]
		if not trophyData then return end

		-- Ya lo recogió este jugador?
		if trophyData.collectedBy[player.UserId] then return end

		-- Cooldown anti-spam
		local now = tick()
		if touchCooldowns[part][player.UserId] and (now - touchCooldowns[part][player.UserId]) < 0.5 then
			return
		end
		touchCooldowns[part][player.UserId] = now

		-- Marcar como recogido y ocultar
		trophyData.collectedBy[player.UserId] = true
		OnTrophyVisibility:FireClient(player, part, false)

		-- Dar trofeos al jugador
		task.spawn(function()
			CollectTrophyInternal:Invoke(player, trophyData.value)
		end)

		-- Verificar si tiene atributo TP para teleportar
		local tpValue = part:GetAttribute("TP")
		if tpValue then
			local tpNumber = tonumber(tpValue)
			if tpNumber then
				task.spawn(function()
					task.wait(0.1) -- Pequeño delay para que se vea el efecto de recolección
					teleportPlayerToTP(player, tpNumber)
				end)
			end
		end
	end)

	-- Mostrar a todos los jugadores actuales
	for _, player in ipairs(Players:GetPlayers()) do
		OnTrophyVisibility:FireClient(player, part, true)
	end

	print("[TrophyCollectible] Registrado:", part:GetFullName(), "Valor:", trophyValue)
end

-- Desregistrar un Part
local function unregisterTrophy(part)
	local trophyData = trophyParts[part]
	if not trophyData then return end

	if trophyData.connection then
		trophyData.connection:Disconnect()
	end

	trophyParts[part] = nil
	touchCooldowns[part] = nil
end

-- Mostrar trofeo a un jugador específico (para respawn)
local function showTrophyForPlayer(player, part)
	local trophyData = trophyParts[part]
	if not trophyData then return end

	trophyData.collectedBy[player.UserId] = nil
	OnTrophyVisibility:FireClient(player, part, true)
end

-- Monitorear altura de un jugador para respawn de trofeos
local function monitorPlayerHeight(player)
	-- Desconectar conexión anterior si existe
	if playerConnections[player.UserId] then
		playerConnections[player.UserId]:Disconnect()
	end

	playerConnections[player.UserId] = RunService.Heartbeat:Connect(function()
		local character = player.Character
		if not character then return end

		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if not rootPart then return end

		local height = rootPart.Position.Y

		-- Si bajó de 10m, restaurar todos los trofeos que había recogido
		if height < RESPAWN_HEIGHT_THRESHOLD then
			for part, trophyData in pairs(trophyParts) do
				if trophyData.collectedBy[player.UserId] then
					showTrophyForPlayer(player, part)
				end
			end
		end
	end)
end

-- Buscar trofeos en el workspace
local function scanForTrophies()
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("TrophyValue") then
			registerTrophy(descendant)
		end
	end
end

-- Detectar nuevos Parts añadidos al workspace
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") and descendant:GetAttribute("TrophyValue") then
		registerTrophy(descendant)
	end
end)

-- Detectar Parts eliminados
workspace.DescendantRemoving:Connect(function(descendant)
	if trophyParts[descendant] then
		unregisterTrophy(descendant)
	end
end)

-- Detectar cuando cambia el atributo TrophyValue
workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") then
		descendant:GetAttributeChangedSignal("TrophyValue"):Connect(function()
			local value = descendant:GetAttribute("TrophyValue")
			if value and value > 0 then
				registerTrophy(descendant)
			else
				unregisterTrophy(descendant)
			end
		end)
	end
end)

-- Configurar jugadores existentes
for _, player in ipairs(Players:GetPlayers()) do
	monitorPlayerHeight(player)
end

-- Configurar nuevos jugadores
Players.PlayerAdded:Connect(function(player)
	monitorPlayerHeight(player)

	-- Esperar y mostrar todos los trofeos al nuevo jugador
	task.wait(1)
	for part, _ in pairs(trophyParts) do
		OnTrophyVisibility:FireClient(player, part, true)
	end
end)

-- Limpiar cuando un jugador se va
Players.PlayerRemoving:Connect(function(player)
	-- Limpiar datos del jugador de todos los trofeos
	for _, trophyData in pairs(trophyParts) do
		trophyData.collectedBy[player.UserId] = nil
	end

	-- Limpiar cooldowns
	for part, _ in pairs(touchCooldowns) do
		touchCooldowns[part][player.UserId] = nil
	end

	-- Desconectar monitoreo de altura
	if playerConnections[player.UserId] then
		playerConnections[player.UserId]:Disconnect()
		playerConnections[player.UserId] = nil
	end
end)

-- Escaneo inicial
scanForTrophies()

print("[TrophyCollectible] Sistema de trofeos inicializado")
