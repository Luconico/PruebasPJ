--[[
	VisualRelay.server.lua
	Retransmite estados visuales de un cliente a todos los demás
	Para que los jugadores vean: gordura, gas, animaciones de comer de otros
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then
	warn("[VisualRelay] No se encontraron Remotes")
	return
end

-- Cache de último estado por jugador (para late-joiners)
local playerStates = {} -- { [Player] = { fatness, propulsion = {isActive, cosmeticId}, eating = {isActive, foodIcon} } }

-- ============================================
-- HELPERS
-- ============================================

local function ensureState(player)
	if not playerStates[player] then
		playerStates[player] = {
			fatness = 0.5,
			propulsion = { isActive = false, cosmeticId = nil },
			eating = { isActive = false, foodIcon = nil },
		}
	end
	return playerStates[player]
end

local function fireToOthers(remote, sender, ...)
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= sender then
			remote:FireClient(otherPlayer, sender, ...)
		end
	end
end

-- ============================================
-- GORDURA
-- ============================================

local VisualFatnessUpdate = Remotes:WaitForChild("VisualFatnessUpdate", 10)
if VisualFatnessUpdate then
	VisualFatnessUpdate.OnServerEvent:Connect(function(sender, fatness)
		if type(fatness) ~= "number" then return end
		fatness = math.clamp(fatness, 0.1, 10) -- Sanity check

		local state = ensureState(sender)
		state.fatness = fatness

		fireToOthers(VisualFatnessUpdate, sender, fatness)
	end)
end

-- ============================================
-- PROPULSIÓN (gas/pedos)
-- ============================================

local VisualPropulsionState = Remotes:WaitForChild("VisualPropulsionState", 10)
if VisualPropulsionState then
	VisualPropulsionState.OnServerEvent:Connect(function(sender, isActive, cosmeticId)
		if type(isActive) ~= "boolean" then return end

		local state = ensureState(sender)
		state.propulsion.isActive = isActive
		state.propulsion.cosmeticId = cosmeticId

		fireToOthers(VisualPropulsionState, sender, isActive, cosmeticId)
	end)
end

-- ============================================
-- COMER
-- ============================================

local VisualEatingState = Remotes:WaitForChild("VisualEatingState", 10)
if VisualEatingState then
	VisualEatingState.OnServerEvent:Connect(function(sender, isEating, foodIcon)
		if type(isEating) ~= "boolean" then return end

		local state = ensureState(sender)
		state.eating.isActive = isEating
		state.eating.foodIcon = foodIcon

		fireToOthers(VisualEatingState, sender, isEating, foodIcon)
	end)
end

-- ============================================
-- SINCRONIZACIÓN PARA LATE-JOINERS
-- ============================================

Players.PlayerAdded:Connect(function(newPlayer)
	-- Esperar a que el cliente esté listo
	task.wait(3)

	for otherPlayer, state in pairs(playerStates) do
		if otherPlayer ~= newPlayer and otherPlayer.Parent then
			-- Enviar gordura actual
			if state.fatness and state.fatness ~= 0.5 then
				VisualFatnessUpdate:FireClient(newPlayer, otherPlayer, state.fatness)
			end

			-- Enviar estado de propulsión si está activo
			if state.propulsion.isActive then
				VisualPropulsionState:FireClient(newPlayer, otherPlayer, true, state.propulsion.cosmeticId)
			end

			-- Enviar estado de comer si está activo
			if state.eating.isActive then
				VisualEatingState:FireClient(newPlayer, otherPlayer, true, state.eating.foodIcon)
			end
		end
	end
end)

-- ============================================
-- LIMPIEZA
-- ============================================

Players.PlayerRemoving:Connect(function(player)
	playerStates[player] = nil
end)

print("[VisualRelay] Inicializado")
