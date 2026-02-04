-- TrophyClient.client.lua
-- Maneja la visibilidad de trofeos per-jugador

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OnTrophyVisibility = Remotes:WaitForChild("OnTrophyVisibility")

-- Cache de transparencias originales de los Parts
local originalTransparency = {}

-- Cuando el servidor dice que oculte/muestre un trofeo
OnTrophyVisibility.OnClientEvent:Connect(function(trophyPart, visible)
	if not trophyPart then return end

	-- Solo procesar BaseParts
	if trophyPart:IsA("BasePart") then
		-- Guardar transparencia original la primera vez
		if originalTransparency[trophyPart] == nil then
			originalTransparency[trophyPart] = trophyPart.Transparency
		end

		if visible then
			-- Restaurar visibilidad
			trophyPart.Transparency = originalTransparency[trophyPart]
			trophyPart.CanCollide = true
		else
			-- Ocultar para este jugador
			trophyPart.Transparency = 1
			trophyPart.CanCollide = false
		end
	elseif trophyPart:IsA("Model") then
		-- Si es un Model, procesar todos los BaseParts hijos
		for _, descendant in ipairs(trophyPart:GetDescendants()) do
			if descendant:IsA("BasePart") then
				if originalTransparency[descendant] == nil then
					originalTransparency[descendant] = descendant.Transparency
				end

				if visible then
					descendant.Transparency = originalTransparency[descendant]
					descendant.CanCollide = true
				else
					descendant.Transparency = 1
					descendant.CanCollide = false
				end
			end
		end
	end
end)

-- Limpiar cache cuando el Part es destruido
workspace.DescendantRemoving:Connect(function(descendant)
	if originalTransparency[descendant] then
		originalTransparency[descendant] = nil
	end
end)
