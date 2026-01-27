--[[
	UpgradeZones.server.lua
	Sistema de zonas de compra de upgrades
	Detecta cuando un jugador entra/sale de una zona de upgrades
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Esperar dependencias
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- ============================================
-- CREAR REMOTE EVENTS PARA ZONAS DE UPGRADE
-- ============================================

local OnUpgradeZoneEnter = Instance.new("RemoteEvent")
OnUpgradeZoneEnter.Name = "OnUpgradeZoneEnter"
OnUpgradeZoneEnter.Parent = Remotes

local OnUpgradeZoneExit = Instance.new("RemoteEvent")
OnUpgradeZoneExit.Name = "OnUpgradeZoneExit"
OnUpgradeZoneExit.Parent = Remotes

-- ============================================
-- CONFIGURACIÓN DE ZONAS
-- ============================================

-- Las zonas de upgrade se definen por posición y radio
-- En producción, esto vendría de objetos en Workspace
local upgradeZones = {
	{
		Name = "MainUpgradeShop",
		Position = Vector3.new(0, 0, 20), -- Frente al spawn
		Radius = 8,
	},
}

-- Estado de cada jugador
local playerInUpgradeZone = {}

-- ============================================
-- FUNCIONES
-- ============================================

-- Buscar zonas de upgrade en Workspace
local function findUpgradeZonesInWorkspace()
	local upgradeFolder = workspace:FindFirstChild("UpgradeZones")
	if not upgradeFolder then
		-- Crear carpeta y zona de ejemplo
		upgradeFolder = Instance.new("Folder")
		upgradeFolder.Name = "UpgradeZones"
		upgradeFolder.Parent = workspace

		-- Crear zona visual de ejemplo
		for _, zoneData in ipairs(upgradeZones) do
			local zone = Instance.new("Part")
			zone.Name = zoneData.Name
			zone.Size = Vector3.new(zoneData.Radius * 2, 0.5, zoneData.Radius * 2)
			zone.Position = zoneData.Position + Vector3.new(0, 0.25, 0)
			zone.Anchored = true
			zone.CanCollide = false
			zone.Transparency = 0.5
			zone.BrickColor = BrickColor.new("Bright blue")
			zone.Material = Enum.Material.Neon
			zone.Parent = upgradeFolder

			-- Añadir etiqueta 3D
			local billboard = Instance.new("BillboardGui")
			billboard.Size = UDim2.new(0, 200, 0, 80)
			billboard.StudsOffset = Vector3.new(0, 5, 0)
			billboard.AlwaysOnTop = true
			billboard.Parent = zone

			local label = Instance.new("TextLabel")
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundTransparency = 1
			label.Text = "🛒 TIENDA 🛒"
			label.TextColor3 = Color3.new(1, 1, 1)
			label.TextStrokeTransparency = 0
			label.TextStrokeColor3 = Color3.new(0, 0, 0)
			label.TextScaled = true
			label.Font = Enum.Font.FredokaOne
			label.Parent = billboard

			-- Marcar como zona de upgrade
			zone:SetAttribute("IsUpgradeZone", true)

			-- Añadir efecto de partículas
			local particles = Instance.new("ParticleEmitter")
			particles.Texture = "rbxassetid://243660364"
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 200, 50))
			particles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0),
			})
			particles.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			particles.Rate = 10
			particles.Lifetime = NumberRange.new(2, 3)
			particles.Speed = NumberRange.new(2, 4)
			particles.SpreadAngle = Vector2.new(360, 360)
			particles.Parent = zone
		end
	end

	-- Leer zonas del workspace
	local zones = {}
	for _, child in ipairs(upgradeFolder:GetChildren()) do
		if child:IsA("BasePart") and child:GetAttribute("IsUpgradeZone") then
			table.insert(zones, {
				Name = child.Name,
				Position = child.Position,
				Radius = math.max(child.Size.X, child.Size.Z) / 2,
				Part = child,
			})
		end
	end

	return zones
end

-- Verificar si el jugador está en una zona de upgrade
local function getPlayerUpgradeZone(player)
	local character = player.Character
	if not character then return nil end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return nil end

	local playerPos = rootPart.Position

	for _, zone in ipairs(upgradeZones) do
		local distance = (Vector3.new(playerPos.X, zone.Position.Y, playerPos.Z) - zone.Position).Magnitude
		if distance <= zone.Radius then
			return zone
		end
	end

	return nil
end

-- ============================================
-- LOOP PRINCIPAL
-- ============================================

-- Actualizar zonas desde workspace
upgradeZones = findUpgradeZonesInWorkspace()

-- Verificar jugadores periódicamente
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local currentZone = getPlayerUpgradeZone(player)
		local wasInZone = playerInUpgradeZone[player]

		local isNowInZone = currentZone ~= nil
		local wasInZoneBefore = wasInZone ~= nil

		if isNowInZone and not wasInZoneBefore then
			-- Entró a una zona
			playerInUpgradeZone[player] = currentZone
			OnUpgradeZoneEnter:FireClient(player)
			print("[UpgradeZones] Jugador entró a zona de upgrades:", currentZone.Name)

		elseif not isNowInZone and wasInZoneBefore then
			-- Salió de la zona
			playerInUpgradeZone[player] = nil
			OnUpgradeZoneExit:FireClient(player)
			print("[UpgradeZones] Jugador salió de zona de upgrades")
		end
	end
end)

-- Limpiar cuando el jugador se va
Players.PlayerRemoving:Connect(function(player)
	playerInUpgradeZone[player] = nil
end)

print("[UpgradeZones] Sistema de zonas de upgrade inicializado")
print("[UpgradeZones] Zonas encontradas:", #upgradeZones)
