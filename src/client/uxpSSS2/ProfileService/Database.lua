local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local WorkspaceService = game:GetService("Workspace")
local ServerPetList = WorkspaceService:WaitForChild("ServerPets")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local uxpRS = ReplicatedStorage.uxpRS
local uxpSSS = ServerScriptService.uxpSSS
local PetSystemRS = uxpRS.PetSystem
local PetSystemSSS = uxpSSS.PetSystem
local DataLibs = uxpSSS.ProfileService.Database
local ProfileService = require(uxpSSS.ProfileService.ProfileService)
local ProfileTemplate = require(uxpSSS.ProfileService.Template)
local Manager = require(uxpSSS.ProfileService.Manager)
local PlayerData = require(PetSystemRS.PlayerData)
local PetModule = require(PetSystemSSS.PetHanderModule)
local PetEasyManager = require(PetSystemSSS.PetEasyManager)
local PetSystemSettings = require(PetSystemRS.PetSystemSettings)

local ProfileStore = ProfileService.GetProfileStore(
	
	"PlayerData",
	ProfileTemplate
	
)

local function GiveLeaderstats(player: Player)
	
	local Profile = Manager.Profiles[player]
	
	if not Profile then return end
	
	local leaderstats = Instance.new("Folder")
	local Currency = Instance.new("IntValue")
	
	leaderstats.Name = PetSystemSettings.CurrencyFolder
	Currency.Name = PetSystemSettings.Currency
	
	leaderstats.Parent = player
	Currency.Parent = leaderstats
	
	Currency.Value = Profile.Data.BalanceData.Currency
	
end

local function PlayerAdded(player)
	
	local Profile = ProfileStore:LoadProfileAsync("Player_"..player.UserId)
	
	if Profile ~= nil then
		
		Profile:AddUserId(player.UserId)
		Profile:Reconcile()
		Profile:ListenToRelease(function()
			
			Manager.Profiles[player] = nil
			player:Kick("Data Load Fail, Try Again!")
			
		end)
		
		if player:IsDescendantOf(Players) == true then
			
			Manager.Profiles[player] = Profile
			
			if not Profile then return end
			
			GiveLeaderstats(player)
			
			local PetFolder = Instance.new("Folder")
			PetFolder.Name = player.Name
			PetFolder.Parent = ServerPetList
			
			PlayerData.AddPlayerData(
				PlayerData,
				player,
				Profile.Data.GamepassList.AutoOpen,
				Profile.Data.GamepassList.FastOpen,
				Profile.Data.GamepassList.Luck1,
				Profile.Data.GamepassList.Luck2,
				Profile.Data.GamepassList.Luck3,
				Profile.Data.GamepassList.Open3x,
				Profile.Data.GamepassList.Open8x)
			
			local FastOpenEnabled = Instance.new("BoolValue")
			FastOpenEnabled.Name = "FastOpenEnabled"
			FastOpenEnabled.Parent = player
			
			task.wait(3)
			
			for i,v in pairs(Profile.Data.PetSystem.Pets) do

				if v.Equiped then

					PetModule.EquipPet(player, v.PetName)
					task.wait(0.5)

				end

			end
			
		else
			
			Profile:Release()
			
		end
		
	else
		
		player:Kick("Data Load Fail, Try Again!")
		
	end
	
end

for i,v in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, v)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	if PetSystemSSS.PetHanderModule:FindFirstChild(player.Name) then
		PetSystemSSS.PetHanderModule:FindFirstChild(player.Name):Destroy()
	end
	local Profile = Manager.Profiles[player]
	Profile.Data.BalanceData.Currency = player.leaderstats:FindFirstChild(PetSystemSettings.Currency).Value
	if Profile ~= nil then
		Profile:Release()
		PlayerData.RemovePlayerData(PlayerData, player)
	end
	local PetFolder = ServerPetList:FindFirstChild(player.Name)
	if PetFolder ~= nil then
		PetFolder:Destroy()
	end
end)