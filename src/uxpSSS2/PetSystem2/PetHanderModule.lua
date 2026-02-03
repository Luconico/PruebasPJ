local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorkspaceService = game:GetService("Workspace")
local ServerPets = WorkspaceService.ServerPets
local uxpRS = ReplicatedStorage.uxpRS
local PetSystemRS = uxpRS.PetSystem

local Pets = PetSystemRS.Pets

local module = {}

function module.EquipPet(Player, PetName)
	
	local Pet = Pets:FindFirstChild(PetName)
	
	if Pet == nil then return end
	
	local ClonePet = Pet:Clone()
	
	if not Player.Character then return end
	if Player.Character:FindFirstChild("HumanoidRootPart") == nil then return end
	
	ClonePet:PivotTo(Player.Character:WaitForChild("HumanoidRootPart").CFrame)
	ClonePet.Parent = workspace.ServerPets[Player.Name]
	
end

function module.UnequipPet(Player, PetName)
	
	local Pet = ServerPets[Player.Name]:FindFirstChild(PetName)

	if Pet == nil then return end
	
	Pet:Destroy()
	
end

return module
