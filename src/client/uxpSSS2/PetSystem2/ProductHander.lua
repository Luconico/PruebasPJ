local MarketPlaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local uxpRS = ReplicatedStorage.uxpRS
local uxpSSS = ServerScriptService.uxpSSS
local PetSystemRS = uxpRS.PetSystem
local PetSystemSSS = uxpSSS.PetSystem
local PetSystemSettings = require(PetSystemRS.PetSystemSettings)
local PlayerData = require(uxpSSS.ProfileService.Manager)
local PlayerDatam = require(PetSystemRS.PlayerData)

MarketPlaceService.PromptProductPurchaseFinished:Connect(function(playerId, assetId, isPruchased)
	local Player = Players:GetPlayerByUserId(playerId)
	local Profile = PlayerData.Profiles[Player]
	if isPruchased then
		if assetId == PetSystemSettings.DevProductsID.MorePetsEquip then
			Profile.Data.PetSystem.PetEquipSlot += 1
		elseif assetId == PetSystemSettings.DevProductsID.MorePetsSlot then
			Profile.Data.PetSystem.PetBackpackSlot += 25
		end
		PetSystemRS.GlobalEvents.RemoteEvent:FireClient(Player, "NotifyEvent", PetSystemSettings.Messages.PurchaseSucces[1], PetSystemSettings.Messages.PurchaseSucces[2])
	end
end)

MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(Player, gamePassId, isPruchased)
	local Profile = PlayerData.Profiles[Player]
	if isPruchased then
		if gamePassId == PetSystemSettings.Gamepass.Open3x then
			Profile.Data.GamepassList.Open3x = true
			PlayerDatam.EditPlayerData(PlayerData, Player, "Open3xGamepass", true)
		elseif gamePassId == PetSystemSettings.Gamepass.Open8x then
			Profile.Data.GamepassList.Open8x = true
			PlayerDatam.EditPlayerData(PlayerData, Player, "Open8xGamepass", true)
		elseif gamePassId == PetSystemSettings.Gamepass.AutoOpen then
			Profile.Data.GamepassList.AutoOpen = true
			PlayerDatam.EditPlayerData(PlayerData, Player, "AutoOpenGamepass", true)
		elseif gamePassId == PetSystemSettings.Gamepass.FastOpen then
			Profile.Data.GamepassList.FastOpen = true
			PlayerDatam.EditPlayerData(PlayerData, Player, "FastOpenGamepass", true)
		elseif gamePassId == PetSystemSettings.Gamepass.LuckGamepass1 then
			Profile.Data.GamepassList.Luck1 = true
			PlayerDatam.EditPlayerData(PlayerData, Player, "Luck1Gamepass", true)
		elseif gamePassId == PetSystemSettings.Gamepass.LuckGamepass2 then
			Profile.Data.GamepassList.Luck2 = true
			PlayerDatam.EditPlayerData(PlayerData, Player, "Luck2Gamepass", true)
		elseif gamePassId == PetSystemSettings.Gamepass.LuckGamepass3 then
			Profile.Data.GamepassList.Luck3 = true
			PlayerDatam.EditPlayerData(PlayerData, Player, "Luck3Gamepass", true)
		end
		PetSystemRS.GlobalEvents.RemoteEvent:FireClient(Player, "NotifyEvent", PetSystemSettings.Messages.PurchaseSucces[1], PetSystemSettings.Messages.PurchaseSucces[2])
	end
end)