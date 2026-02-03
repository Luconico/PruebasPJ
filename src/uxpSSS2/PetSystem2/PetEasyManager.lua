local PetEasyManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local HTTPService = game:GetService("HttpService")
local uxpRS = ReplicatedStorage.uxpRS
local uxpSSS = ServerScriptService.uxpSSS
local PetSystemRS = uxpRS.PetSystem
local PetSettings = require(uxpRS.PetSystem.PetSystemSettings)
local PetList = require(uxpRS.PetSystem.PetList)
local Manager = require(uxpSSS.ProfileService.Manager)
local PlayerData = require(PetSystemRS.PlayerData)

local function formatCurrency(value)
	if value >= 1e9 then
		return string.format("%.1fb", math.floor(value / 1e8) / 10)
	elseif value >= 1e6 then
		return string.format("%.1fm", math.floor(value / 1e5) / 10)
	elseif value >= 1e3 then
		return string.format("%.1fk", math.floor(value / 1e2) / 10)
	else
		return tostring(value)
	end
end

function PetEasyManager:GetPlayerBalanceRaw(player)
	
	return player:FindFirstChild(PetSettings.CurrencyFolder):FindFirstChild(PetSettings.Currency).Value
	
end

function PetEasyManager:GetPlayerBalanceFormated(player)

	return formatCurrency(player:FindFirstChild(PetSettings.CurrencyFolder):FindFirstChild(PetSettings.Currency).Value)

end

function PetEasyManager:GetEquipedPetsBoostRaw(player)
	
	local Profile = Manager.Profiles[player]
	local TotalBoost = 0
	
	for i,v in pairs(Profile.Data.PetSystem.Pets) do
		
		if v.Equiped then
			
			for i2, v2 in pairs(PetList) do
				
				if v2.PetName == v.PetName then
					
					TotalBoost += v2.Boost
					break
				end
				
			end
			
		end
		
	end
	
	return TotalBoost
	
end

function PetEasyManager:GetEquipedPetsBoostRounded(player)

	local Profile = Manager.Profiles[player]
	local TotalBoost = 0

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.Equiped then

			for i2, v2 in pairs(PetList) do

				if v2.PetName == v.PetName then

					TotalBoost += v2.Boost
					break
				end

			end

		end

	end

	return math.floor(TotalBoost * 100) / 100

end

function PetEasyManager:GetUnequipedPetsBoostRaw(player)

	local Profile = Manager.Profiles[player]
	local TotalBoost = 0

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if not v.Equiped then

			for i2, v2 in pairs(PetList) do

				if v2.PetName == v.PetName then

					TotalBoost += v2.Boost
					break
				end

			end

		end

	end

	return TotalBoost

end

function PetEasyManager:GetUnequipedPetsBoostRounded(player)

	local Profile = Manager.Profiles[player]
	local TotalBoost = 0

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if not v.Equiped then

			for i2, v2 in pairs(PetList) do

				if v2.PetName == v.PetName then

					TotalBoost += v2.Boost
					break
				end

			end

		end

	end

	return math.floor(TotalBoost * 100) / 100

end

function PetEasyManager:GetAllPetsBoostRaw(player)

	local Profile = Manager.Profiles[player]
	local TotalBoost = 0

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		for i2, v2 in pairs(PetList) do

			if v2.PetName == v.PetName then

				TotalBoost += v2.Boost
				break
			end

		end

	end

	return TotalBoost

end

function PetEasyManager:GetAllPetsBoostRounded(player)

	local Profile = Manager.Profiles[player]
	local TotalBoost = 0

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		for i2, v2 in pairs(PetList) do

			if v2.PetName == v.PetName then

				TotalBoost += v2.Boost
				break
			end

		end

	end

	return math.floor(TotalBoost * 100) / 100

end

function PetEasyManager:GetPlayerBackpackSize(player)

	local Profile = Manager.Profiles[player]

	return Profile.Data.PetBackpackSlot

end

function PetEasyManager:GetPlayerEquipSize(player)

	local Profile = Manager.Profiles[player]

	return Profile.Data.PetEquipSlot

end

function PetEasyManager:GetPlayerCurrentEquipedCount(player)

	local Profile = Manager.Profiles[player]
	local int = 0
	
	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.Equiped then

			int += 1

		end

	end

	return int

end

function PetEasyManager:GetPlayerCurrentBackpackCount(player)

	local Profile = Manager.Profiles[player]

	return #Profile.Data.PetSystem.Pets

end

function PetEasyManager:GetPlayerPetsRemainSize(player)

	local Profile = Manager.Profiles[player]
	local int = 0

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.Equiped then

			int += 1

		end

	end

	return Profile.Data.PetSystem.PetEquipSlot - int

end

function PetEasyManager:GetPlayerBackpackRemainSize(player)

	local Profile = Manager.Profiles[player]

	return Profile.Data.PetSystem.PetBackpackSlot - #Profile.Data.PetSystem.Pets

end

function PetEasyManager:GetPetIsLocked(player, uuid)

	local Profile = Manager.Profiles[player]
	
	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.UUID == uuid then
			
			if v.Locked then
				
				return true
				
			else
				
				return false
				
			end
			
		end

	end

	return nil

end

function PetEasyManager:GetPetIsTradeable(player, uuid)

	local Profile = Manager.Profiles[player]

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.UUID == uuid then

			if v.Tradeable then

				return true

			else

				return false

			end

		end

	end

	return nil

end

function PetEasyManager:GetPlayerHasAutoOpenGamepass(player)

	return PlayerData.GivePlayerData(PlayerData, player).AutoOpenGamepass

end

function PetEasyManager:GetPlayerHasFastOpenGamepass(player)

	return PlayerData.GivePlayerData(PlayerData, player).FastOpenGamepass

end

function PetEasyManager:GetPlayerHasLuck1Gamepass(player)

	return PlayerData.GivePlayerData(PlayerData, player).Luck1Gamepass

end

function PetEasyManager:GetPlayerHasLuck2Gamepass(player)

	return PlayerData.GivePlayerData(PlayerData, player).Luck2Gamepass

end

function PetEasyManager:GetPlayerHasLuck3Gamepass(player)

	return PlayerData.GivePlayerData(PlayerData, player).Luck3Gamepass

end

function PetEasyManager:GetPlayerHasOpen3xGamepass(player)

	return PlayerData.GivePlayerData(PlayerData, player).Open3xGamepass

end

function PetEasyManager:GetPlayerHasOpen8xGamepass(player)

	return PlayerData.GivePlayerData(PlayerData, player).Open8xGamepass

end

function PetEasyManager:GetPlayerTradeAccepting(player)

	return PlayerData.GivePlayerData(PlayerData, player).TradeOpen

end

function PetEasyManager:GetPlayerIsTrading(player)

	return PlayerData.GivePlayerData(PlayerData, player).Trading

end

function PetEasyManager:GetPlayerTradingWith(player)

	return PlayerData.GivePlayerData(PlayerData, player).TradingWith

end

function PetEasyManager:GetPlayerLastTradeRequest(player)

	return PlayerData.GivePlayerData(PlayerData, player).LastTradeReq

end

function PetEasyManager:GetPlayerTradeAccepted(player)

	return PlayerData.GivePlayerData(PlayerData, player).TradeAccepted

end

function PetEasyManager:SetPlayerBalance(player, value)
	
	player:FindFirstChild(PetSettings.CurrencyFolder):FindFirstChild(PetSettings.Currency).Value = value

end

function PetEasyManager:SetPlayerBackpackSize(player, value)

	local Profile = Manager.Profiles[player]
	
	Profile.Data.PetSystem.PetBackpackSlot = value

end

function PetEasyManager:AddPlayerBackpackSize(player, value)

	local Profile = Manager.Profiles[player]

	Profile.Data.PetSystem.PetBackpackSlot += value

end

function PetEasyManager:RemovePlayerBackpackSize(player, value)

	local Profile = Manager.Profiles[player]

	Profile.Data.PetSystem.PetBackpackSlot -= value

end

function PetEasyManager:SetPetEquipSize(player, value)

	local Profile = Manager.Profiles[player]

	Profile.Data.PetSystem.PetEquipSlot = value

end

function PetEasyManager:AddPetEquipSize(player, value)

	local Profile = Manager.Profiles[player]

	Profile.Data.PetSystem.PetEquipSlot += value

end

function PetEasyManager:RemovePetEquipSize(player, value)

	local Profile = Manager.Profiles[player]

	Profile.Data.PetSystem.PetEquipSlot -= value

end

function PetEasyManager:SetPetLockedUUID(player, uuid, value)
	
	local Profile = Manager.Profiles[player]

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.UUID == uuid then

			v.Locked = value
			break
		end

	end

end

function PetEasyManager:SetPetTradeableUUID(player, uuid, value)

	local Profile = Manager.Profiles[player]

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.UUID == uuid then

			v.Tradeable = value
			break
		end

	end

end

function PetEasyManager:SetPlayerHasAutoOpenGamepass(player, value)
	
	PlayerData.EditPlayerData(PlayerData, player, "AutoOpenGamepass", value)

end

function PetEasyManager:SetPlayerHasFastOpenGamepass(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "FastOpenGamepass", value)

end

function PetEasyManager:SetPlayerHasLuck1Gamepass(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "Luck1Gamepass", value)

end

function PetEasyManager:SetPlayerHasLuck2Gamepass(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "Luck2Gamepass", value)

end

function PetEasyManager:SetPlayerHasLuck3Gamepass(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "Luck3Gamepass", value)

end

function PetEasyManager:SetPlayerHasOpen3xGamepass(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "Open3xGamepass", value)

end

function PetEasyManager:SetPlayerHasOpen8xGamepass(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "Open8xGamepass", value)

end

function PetEasyManager:SetPlayerTradeAccepting(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "TradeOpen", value)

end

function PetEasyManager:SetPlayerIsTrading(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "Trading", value)

end

function PetEasyManager:SetPlayerTradingWith(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "TradingWith", value)

end

function PetEasyManager:SetPlayerLastTradeRequest(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "LastTradeReq", value)

end

function PetEasyManager:SetPlayerTradeAccepted(player, value)

	PlayerData.EditPlayerData(PlayerData, player, "TradeAccepted", value)

end

function PetEasyManager:RemovePlayerPetWithUUID(player, uuid)

	local Profile = Manager.Profiles[player]

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.UUID == uuid then

			table.remove(Profile.Data.PetSystem.Pets, i)
			break
		end

	end

end

function PetEasyManager:RemovePlayerPetWithName(player, name)

	local Profile = Manager.Profiles[player]

	for i,v in pairs(Profile.Data.PetSystem.Pets) do

		if v.PetName == name then

			table.remove(Profile.Data.PetSystem.Pets, i)
			break
		end

	end

end

function PetEasyManager:GivePlayerPet(player, petName, petType, equiped, locked, tradeable, addIndex)

	local Profile = Manager.Profiles[player]

	table.insert(Profile.Data.PetSystem.Pets, {
		PetName = petName,
		PetType = petType, -- Normal, Golden, Rainbow
		UUID = HTTPService:GenerateGUID(),
		Equiped = equiped,
		Locked = locked,
		Tradeable = tradeable,
	})
	
	if addIndex then
		
		if Profile.Data.PetSystem.Index == nil then
			table.insert(Profile.Data.PetSystem.Index, petName)
			return true, petName
		end
		for i,v in pairs(Profile.Data.PetSystem.Index) do
			if v == petName then return true, petName end
		end
		table.insert(Profile.Data.PetSystem.Index, petName)
		
	end

end





return PetEasyManager
