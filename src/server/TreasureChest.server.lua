--[[
	TreasureChest.server.lua
	Cofre del tesoro: recompensa 10,000 monedas si el jugador
	está en el grupo (ID 803229435). Una sola vez por jugador.
]]

local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Esperar a que existan los ServerFunctions (creados por PlayerData)
local ServerFunctions = ReplicatedStorage:WaitForChild("ServerFunctions")
local ModifyCoinsServer = ServerFunctions:WaitForChild("ModifyCoinsServer")
local GetPlayerDataServer = ServerFunctions:WaitForChild("GetPlayerDataServer")

-- Esperar a los Remotes (creados por PlayerData)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OnDataUpdated = Remotes:WaitForChild("OnDataUpdated")

-- Configuración
local GROUP_ID = 803229435
local REWARD_COINS = 10000

-- ============================================
-- CREAR REMOTES PARA EL COFRE
-- ============================================
local claimTreasureRemote = Instance.new("RemoteFunction")
claimTreasureRemote.Name = "ClaimTreasure"
claimTreasureRemote.Parent = Remotes

local checkTreasureRemote = Instance.new("RemoteFunction")
checkTreasureRemote.Name = "CheckTreasureStatus"
checkTreasureRemote.Parent = Remotes

-- ============================================
-- FUNCIONES
-- ============================================

-- Verificar si el jugador está en el grupo
local function isInGroup(player)
	local success, result = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)
	if not success then
		warn("[TreasureChest] Error verificando grupo para", player.Name, ":", result)
		return false
	end
	return result
end

-- Obtener datos del jugador
local function getPlayerData(player)
	local result = GetPlayerDataServer:Invoke(player)
	if result and result.Data then
		return result.Data
	end
	return nil
end

-- ============================================
-- HANDLERS DE REMOTES
-- ============================================

-- Consultar estado del cofre (si ya reclamó, si está en el grupo)
checkTreasureRemote.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	if not data then
		return { CanClaim = false, Reason = "DataError" }
	end

	-- Ya reclamó
	if data.TreasureClaimed then
		return { CanClaim = false, Reason = "AlreadyClaimed" }
	end

	-- Verificar grupo
	local inGroup = isInGroup(player)
	if not inGroup then
		return { CanClaim = false, Reason = "NotInGroup", GroupId = GROUP_ID }
	end

	return { CanClaim = true }
end

-- Reclamar la recompensa del cofre
claimTreasureRemote.OnServerInvoke = function(player)
	local data = getPlayerData(player)
	if not data then
		return false, "Error de datos"
	end

	-- Verificar que no haya reclamado ya
	if data.TreasureClaimed then
		return false, "Ya reclamaste esta recompensa"
	end

	-- Verificar grupo
	local inGroup = isInGroup(player)
	if not inGroup then
		return false, "Debes unirte al grupo primero"
	end

	-- Dar las monedas
	local success, newCoins = ModifyCoinsServer:Invoke(player, REWARD_COINS)
	if not success then
		return false, "Error al dar monedas"
	end

	-- Marcar como reclamado
	data.TreasureClaimed = true

	-- Notificar al cliente que los datos cambiaron
	OnDataUpdated:FireClient(player, {
		TreasureClaimed = true,
		Coins = newCoins,
	})

	print("[TreasureChest]", player.Name, "reclamó el cofre del tesoro! +", REWARD_COINS, "monedas")
	return true, "Has recibido " .. REWARD_COINS .. " monedas!"
end

print("[TreasureChest] Sistema de cofre del tesoro inicializado")
