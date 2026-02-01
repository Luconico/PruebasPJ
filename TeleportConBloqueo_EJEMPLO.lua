--[[
	SCRIPT DE TELEPORT CON BLOQUEO

	Este script debe colocarse dentro de cada Telepad que quieras bloquear.
	Configura las variables al inicio según tus necesidades.

	REQUISITOS:
	- El part "BloqueoBase1" debe existir en Workspace
	- Los scripts DesbloqueoBaseServer y DesbloqueoBaseClient deben estar activos
]]

local Teleport_To_This_Tag = "0002" -- Tag del telepad de destino

-- ========== CONFIGURACIÓN DE BLOQUEO ==========
local REQUIRED_BASE = "Base1" -- Nombre de la base que debe estar desbloqueada (debe coincidir con BASES_CONFIG en DesbloqueoBaseServer)
-- Si no quieres bloqueo, deja esto como nil:
-- local REQUIRED_BASE = nil
-- ===============================================

-- Cooldown GLOBAL compartido entre TODOS los portales
if not _G.TeleportCooldowns then
	_G.TeleportCooldowns = {}
end

local playerCooldowns = _G.TeleportCooldowns
local COOLDOWN_TIME = 5

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Función para verificar si el jugador tiene la base desbloqueada
local function isBaseUnlockedForPlayer(player)
	if not REQUIRED_BASE then
		return true -- Si no hay requisito de base, siempre permitir
	end

	-- Esperar a que ServerFunctions exista
	local serverFolder = ReplicatedStorage:FindFirstChild("ServerFunctions")
	if not serverFolder then
		warn("[Teleport] ServerFunctions no encontrado, permitiendo teleport por defecto")
		return true
	end

	-- Buscar la función de verificación
	local checkBaseUnlocked = serverFolder:FindFirstChild("CheckBaseUnlocked")
	if not checkBaseUnlocked then
		warn("[Teleport] CheckBaseUnlocked no encontrado, permitiendo teleport por defecto")
		return true
	end

	-- Verificar si está desbloqueada
	local isUnlocked = checkBaseUnlocked:Invoke(player, REQUIRED_BASE)
	return isUnlocked
end

-- Función para encontrar el telepad con el tag especificado
local function findTelepad(tag)
	local workspace = game:GetService("Workspace")

	local function scan(parent)
		for _, child in ipairs(parent:GetChildren()) do
			if child.Name == "Telepad" then
				local tagValue = child:FindFirstChild("Tag")
				if tagValue and tagValue.Value == tag then
					return child
				end
			end

			if #child:GetChildren() > 0 then
				local found = scan(child)
				if found then
					return found
				end
			end
		end
		return nil
	end

	return scan(workspace)
end

-- Función para teletransportar al jugador
local function teleportPlayer(player, destinationPad)
	if not player.Character then return end

	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local targetPosition = destinationPad.CFrame.Position + Vector3.new(0, 3.25, 0)
	humanoidRootPart.CFrame = CFrame.new(targetPosition)

	print("[Teleport] " .. player.Name .. " teletransportado a " .. Teleport_To_This_Tag)
end

-- Evento de toque
script.Parent.Touched:Connect(function(hit)
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Verificar cooldown
	local now = os.clock()
	if playerCooldowns[player] and now - playerCooldowns[player] < COOLDOWN_TIME then
		return
	end

	-- ========== VERIFICAR BLOQUEO ==========
	if not isBaseUnlockedForPlayer(player) then
		-- El jugador no tiene la base desbloqueada
		-- No hacer nada, la UI se mostrará cuando toque el BloqueoBase1
		print("[Teleport] " .. player.Name .. " no tiene " .. REQUIRED_BASE .. " desbloqueada")
		return
	end
	-- =======================================

	-- Buscar telepad de destino
	local destinationPad = findTelepad(Teleport_To_This_Tag)
	if not destinationPad then
		warn("[Teleport] No se encontró telepad con tag: " .. Teleport_To_This_Tag)
		return
	end

	-- Aplicar cooldown
	playerCooldowns[player] = now

	-- Teletransportar
	teleportPlayer(player, destinationPad)
end)

-- Limpiar cooldowns cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	_G.TeleportCooldowns[player] = nil
end)

print("[Teleport] Script inicializado (Tag destino: " .. Teleport_To_This_Tag .. ")")
if REQUIRED_BASE then
	print("[Teleport] Requiere base desbloqueada: " .. REQUIRED_BASE)
else
	print("[Teleport] Sin restricción de base")
end
