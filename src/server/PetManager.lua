--[[
	PetManager.lua
	Gestiona spawn/despawn de mascotas en Workspace
	Adaptado de UXR PetHanderModule.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PetManager = {}

-- Crear carpeta de mascotas
local ServerPets = Workspace:FindFirstChild("ServerPets")
if not ServerPets then
	ServerPets = Instance.new("Folder")
	ServerPets.Name = "ServerPets"
	ServerPets.Parent = Workspace
end

local function ensurePlayerFolder(player)
	local playerFolder = ServerPets:FindFirstChild(player.Name)
	if not playerFolder then
		playerFolder = Instance.new("Folder")
		playerFolder.Name = player.Name
		playerFolder.Parent = ServerPets
	end
	return playerFolder
end

function PetManager:EquipPet(player, petName, uuid)
	print("[PetManager] Intentando equipar:", petName, "(UUID:", uuid, ") para", player.Name)
	local playerFolder = ensurePlayerFolder(player)

	-- Usar UUID como identificador único para permitir múltiples mascotas del mismo tipo
	local modelName = uuid or petName
	if playerFolder:FindFirstChild(modelName) then
		print("[PetManager] Ya existe modelo con ID:", modelName)
		return
	end

	local petsFolder = ReplicatedStorage:FindFirstChild("Pets")
	if not petsFolder then
		warn("[PetManager] No se encontró carpeta Pets en ReplicatedStorage")
		return
	end

	print("[PetManager] Carpeta Pets encontrada, buscando:", petName)
	local petModel = petsFolder:FindFirstChild(petName)
	if not petModel then
		warn("[PetManager] No se encontró modelo:", petName)
		print("[PetManager] Modelos disponibles:", table.concat(petsFolder:GetChildren(), ", "))
		return
	end

	print("[PetManager] Modelo encontrado, clonando...")
	local clonedPet = petModel:Clone()
	clonedPet.Name = modelName -- Usar UUID como nombre para identificación única

	-- Guardar el nombre original del pet para referencia
	local petNameValue = Instance.new("StringValue")
	petNameValue.Name = "PetName"
	petNameValue.Value = petName
	petNameValue.Parent = clonedPet

	-- Configurar valores
	if not clonedPet:FindFirstChild("Flying") then
		local flyingValue = Instance.new("BoolValue")
		flyingValue.Name = "Flying"
		flyingValue.Value = petModel:GetAttribute("Flying") or false
		flyingValue.Parent = clonedPet
	end

	if not clonedPet:FindFirstChild("TimeDelay") then
		local timeDelayValue = Instance.new("NumberValue")
		timeDelayValue.Name = "TimeDelay"
		timeDelayValue.Value = math.random() * 10
		timeDelayValue.Parent = clonedPet
	end

	-- Calcular posición offset basada en cuántas mascotas ya hay
	local existingPets = playerFolder:GetChildren()
	local petIndex = #existingPets -- 0, 1, 2...
	local spacing = 3 -- Espaciado entre mascotas

	-- Posicionar cerca del jugador con offset para evitar superposición
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		print("[PetManager] Posicionando cerca del jugador (slot", petIndex, ")...")
		local hrp = player.Character.HumanoidRootPart
		-- Offset hacia atrás y a los lados basado en el índice
		local angle = (petIndex * 0.8) -- Distribución angular
		local offsetX = math.sin(angle) * spacing
		local offsetZ = spacing + math.cos(angle) * spacing
		clonedPet:PivotTo(hrp.CFrame * CFrame.new(offsetX, 0, offsetZ))
	else
		warn("[PetManager] No se encontró HumanoidRootPart del jugador")
	end

	clonedPet.Parent = playerFolder
	print("[PetManager] ✓ Equipada exitosamente:", player.Name, "→", petName, "(UUID:", modelName, ") en slot", petIndex)
end

function PetManager:UnequipPet(player, petName, uuid)
	local playerFolder = ServerPets:FindFirstChild(player.Name)
	if not playerFolder then return end

	-- Buscar por UUID primero (preferido), luego por petName (compatibilidad)
	local modelName = uuid or petName
	local petModel = playerFolder:FindFirstChild(modelName)

	-- Si no se encuentra por UUID, buscar por nombre de pet (para compatibilidad)
	if not petModel and uuid then
		for _, child in ipairs(playerFolder:GetChildren()) do
			local nameValue = child:FindFirstChild("PetName")
			if nameValue and nameValue.Value == petName then
				petModel = child
				break
			end
		end
	end

	if petModel then
		petModel:Destroy()
		print("[PetManager] Desequipada:", player.Name, "→", petName, "(UUID:", modelName, ")")
	end
end

function PetManager:UnequipAllPets(player)
	local playerFolder = ServerPets:FindFirstChild(player.Name)
	if playerFolder then
		playerFolder:Destroy()
	end
end

Players.PlayerRemoving:Connect(function(player)
	PetManager:UnequipAllPets(player)
end)

return PetManager
