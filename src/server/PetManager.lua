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

function PetManager:EquipPet(player, petName)
	print("[PetManager] Intentando equipar:", petName, "para", player.Name)
	local playerFolder = ensurePlayerFolder(player)

	if playerFolder:FindFirstChild(petName) then
		print("[PetManager] Ya existe:", petName)
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

	-- Posicionar cerca del jugador
	if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
		print("[PetManager] Posicionando cerca del jugador...")
		clonedPet:PivotTo(player.Character.HumanoidRootPart.CFrame)
	else
		warn("[PetManager] No se encontró HumanoidRootPart del jugador")
	end

	clonedPet.Parent = playerFolder
	print("[PetManager] ✓ Equipada exitosamente:", player.Name, "→", petName, "en", playerFolder:GetFullName())
end

function PetManager:UnequipPet(player, petName)
	local playerFolder = ServerPets:FindFirstChild(player.Name)
	if not playerFolder then return end

	local petModel = playerFolder:FindFirstChild(petName)
	if petModel then
		petModel:Destroy()
		print("[PetManager] Desequipada:", player.Name, "→", petName)
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
