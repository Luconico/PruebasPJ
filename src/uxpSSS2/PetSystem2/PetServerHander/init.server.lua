local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local WorkspaceService = game:GetService("Workspace")
local MarketplaceService = game:GetService("MarketplaceService")
local HTTPService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ServerPets = WorkspaceService.ServerPets
local uxpRS = ReplicatedStorage.uxpRS
local uxpSSS = ServerScriptService.uxpSSS
local PetSystemRS = uxpRS.PetSystem
local PetSystemSSS = uxpSSS.PetSystem
local PetHanderModule = require(PetSystemSSS.PetHanderModule)
local Manager = require(uxpSSS.ProfileService.Manager)
local PetHatchList = require(PetSystemSSS.PetServerHander.PetHatchList)
local PetSystemSettings = require(PetSystemRS.PetSystemSettings)
local PlayerData = require(PetSystemRS.PlayerData)
local GlobalPetCount = require(PetSystemSSS.GlobalPetCount)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(playerId, assetId, isPruchased)
	local Player = Players:GetPlayerByUserId(playerId)
	local Profile = Manager.Profiles[Player]
	if isPruchased then
		for i,PrizeTable in pairs(PetHatchList) do
			if PrizeTable.RobuxPet and PrizeTable.DevID == assetId then
				local GeneralLuckBoost = 0
				if PlayerData.GivePlayerData(PlayerData, Player).Luck1Gamepass then
					GeneralLuckBoost += PetSystemSettings.LuckRate.Luck1
				end
				if PlayerData.GivePlayerData(PlayerData, Player).Luck2Gamepass then
					GeneralLuckBoost += PetSystemSettings.LuckRate.Luck2
				end
				if PlayerData.GivePlayerData(PlayerData, Player).Luck3Gamepass then
					GeneralLuckBoost += PetSystemSettings.LuckRate.Luck3
				end
				for i, Chance in pairs(PrizeTable.PetList) do
					PrizeTable[i] = Chance + GeneralLuckBoost
				end
				local Weight = 0
				for i, Chance in pairs(PrizeTable.PetList) do
					Weight += (Chance * 1000)
				end
				local ranNumber = math.random(1, Weight)
				Weight = 0
				for petName, Chance in pairs(PrizeTable.PetList) do
					Weight += (Chance * 1000)
					if Weight >= ranNumber then	
						table.insert(Profile.Data.PetSystem.Pets, {
							PetName = petName,
							PetType = "Normal", -- Normal, Golden, Rainbow
							UUID = HTTPService:GenerateGUID(),
							Equiped = false,
							Locked = false,
							Tradeable = true,
						})
						GlobalPetCount.CountPet(petName)
						if Profile.Data.PetSystem.Index == nil then
							table.insert(Profile.Data.PetSystem.Index, petName)
							PetSystemRS.GlobalEvents.RemoteEvent:FireClient(Player, "PetPurchaseEvent", true, petName)
							return
						end
						for i,v in pairs(Profile.Data.PetSystem.Index) do
							if v == petName then 	
								PetSystemRS.GlobalEvents.RemoteEvent:FireClient(Player, "PetPurchaseEvent", true, petName) 
								return
							end
						end
						table.insert(Profile.Data.PetSystem.Index, petName)
					end
				end
			end
		end
	end
end)

PetSystemRS.GlobalEvents.RemoteEvent.OnServerEvent:Connect(function(player, rtype, value1, value2, value3)
	if rtype == "GoldCraftEvent" then
		local Profile = Manager.Profiles[player]
		local nameList = {}
		local deleteCount = 0
		for _, v in pairs(value1) do
			for i1, v1 in pairs(Profile.Data.PetSystem.Pets) do
				if v1.UUID == v then
					table.remove(Profile.Data.PetSystem.Pets, i1)
					table.insert(nameList, v1.PetName)
					deleteCount += 1
					break
				end
			end
		end
		local firstName = nameList[1]
		if #value1 > 1 then
			for _, name in pairs(nameList) do
				if name ~= firstName then
					return
				end
			end
		end
		if #value1 == deleteCount then
			local Number = math.random(1, 5)
			local shouldCreateGoldenPet = false
			if deleteCount == 5 then
				shouldCreateGoldenPet = true
			elseif deleteCount == 4 and Number <= 4 then
				shouldCreateGoldenPet = true
			elseif deleteCount == 3 and Number <= 3 then
				shouldCreateGoldenPet = true
			elseif deleteCount == 2 and Number <= 2 then
				shouldCreateGoldenPet = true
			elseif deleteCount == 1 and Number == 1 then
				shouldCreateGoldenPet = true
			end
			if shouldCreateGoldenPet then
				local newPet = {
					PetName = "Golden" .. firstName,
					PetType = "Golden", -- Normal, Golden, Rainbow
					UUID = HTTPService:GenerateGUID(),
					Equiped = false,
					Locked = false,
					Tradeable = true,
				}
				table.insert(Profile.Data.PetSystem.Pets, newPet)
				GlobalPetCount.CountPet("Golden"..firstName)
				PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeSucces[1], PetSystemSettings.Messages.MergeSucces[2])
			else
				PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeFail[1], PetSystemSettings.Messages.MergeFail[2])
			end
		end
	elseif rtype == "RainbowCraftEvent" then
		local Profile = Manager.Profiles[player]
		local nameList = {}
		local deleteCount = 0 
		for i,v in pairs(value1) do
			for i1, v1 in pairs(Profile.Data.PetSystem.Pets) do
				if v1.UUID == v then
					table.remove(Profile.Data.PetSystem.Pets, i1)
					table.insert(nameList, v1.PetName)
					deleteCount += 1
				end
			end
		end
		local firstName = nameList[1]
		if not (#value1 == 1) then
			for i = 1, #value1, 1 do
				if not (nameList[i] == firstName) then
					return
				end
			end
		end
		if #value1 == deleteCount then
			local Number = math.random(1, 5)
			if deleteCount == 5 then
				table.insert(Profile.Data.PetSystem.Pets, {
					PetName = "Rainbow"..firstName,
					PetType = "Rainbow", -- Normal, Golden, Rainbow
					UUID = HTTPService:GenerateGUID(),
					Equiped = false,
					Locked = false,
					Tradeable = true,
				})
				GlobalPetCount.CountPet("Rainbow"..firstName)
				PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeSucces[1], PetSystemSettings.Messages.MergeSucces[2])
			else
				if deleteCount == 4 and (Number == 1 or Number == 2 or Number == 3 or Number == 4) then
					table.insert(Profile.Data.PetSystem.Pets, {
						PetName = "Rainbow"..firstName,
						PetType = "Rainbow", -- Normal, Golden, Rainbow
						UUID = HTTPService:GenerateGUID(),
						Equiped = false,
						Locked = false,
						Tradeable = true,
					})
					GlobalPetCount.CountPet("Rainbow"..firstName)
					PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeSucces[1], PetSystemSettings.Messages.MergeSucces[2])
				elseif deleteCount == 3 and (Number == 1 or Number == 2 or Number == 3) then
					table.insert(Profile.Data.PetSystem.Pets, {
						PetName = "Rainbow"..firstName,
						PetType = "Rainbow", -- Normal, Golden, Rainbow
						UUID = HTTPService:GenerateGUID(),
						Equiped = false,
						Locked = false,
						Tradeable = true,
					})
					GlobalPetCount.CountPet("Rainbow"..firstName)
					PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeSucces[1], PetSystemSettings.Messages.MergeSucces[2])
				elseif deleteCount == 2 and (Number == 1 or Number == 2) then
					table.insert(Profile.Data.PetSystem.Pets, {
						PetName = "Rainbow"..firstName,
						PetType = "Rainbow", -- Normal, Golden, Rainbow
						UUID = HTTPService:GenerateGUID(),
						Equiped = false,
						Locked = false,
						Tradeable = true,
					})
					GlobalPetCount.CountPet("Rainbow"..firstName)
					PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeSucces[1], PetSystemSettings.Messages.MergeSucces[2])
				elseif deleteCount == 1 and Number == 1 then
					table.insert(Profile.Data.PetSystem.Pets, {
						PetName = "Rainbow"..firstName,
						PetType = "Rainbow", -- Normal, Golden, Rainbow
						UUID = HTTPService:GenerateGUID(),
						Equiped = false,
						Locked = false,
						Tradeable = true,
					})
					GlobalPetCount.CountPet("Rainbow"..firstName)
					PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeSucces[1], PetSystemSettings.Messages.MergeSucces[2])
				else
					PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MergeFail[1], PetSystemSettings.Messages.MergeFail[2])
				end
			end
		end
	elseif rtype == "DeleteEvent" then
		local Profile = Manager.Profiles[player]
		for i,v in ipairs(Profile.Data.PetSystem.Pets) do
			if v.UUID == value1 then
				table.remove(Profile.Data.PetSystem.Pets, i)
				return
			end
		end
	elseif rtype == "UnEquipEvent" then
		local Profile = Manager.Profiles[player]
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if value1 == v.UUID then
				v.Equiped = false
				PetHanderModule.UnequipPet(player, v.PetName)
				PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "UnequipPetEvent")
				return
			end
		end
	elseif rtype == "FastOpenEvent" then
		if PlayerData.GivePlayerData(PlayerData, player).AutoOpenGamepass then
			player.FastOpenEnabled.Value = false
		else
			player.FastOpenEnabled.Value = true
		end
	end
end)

PetSystemRS.GlobalEvents.RemoteFunction.OnServerInvoke = function(player, rtype, value1, value2, value3)
	if rtype == "GetIndexEvent" then
		local Profile = Manager.Profiles[player]
		return Profile.Data.PetSystem.Index
	elseif rtype == "GetPlayerDataEvent" then
		return PlayerData.GivePlayerData(PlayerData, player)
	elseif rtype == "EquipEvent" then
		
		local Profile = Manager.Profiles[player]
		local EquipedPetsCount = 0
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if v.Equiped then
				EquipedPetsCount += 1
			end
		end
		if EquipedPetsCount >= Profile.Data.PetSystem.PetEquipSlot then
			PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MaxEquip[1], PetSystemSettings.Messages.MaxEquip[2])
			return false
		end
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if value1 == v.UUID then
				v.Equiped = true
				PetHanderModule.EquipPet(player, v.PetName)
				return true
			end
		end
	
	elseif rtype == "TradeStatusEvent" then
		if Players:FindFirstChild(tostring(value1)) then

			local PDFull = PlayerData.GivePlayerData(PlayerData, player)
			local TargetPlayer = Players:FindFirstChild(tostring(value1))

			if TargetPlayer == player then
				PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.CantTradeSelf[1], PetSystemSettings.Messages.CantTradeSelf[2])
				return false
			end
			if PDFull.TradeOpen == false then
				PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.TradesClosed[1], PetSystemSettings.Messages.TradesClosed[2])
				return false
			end
			if PDFull.Trading then
				PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.AlreadyTrading[1], PetSystemSettings.Messages.AlreadyTrading[2])
				return false
			end
			PetSystemRS.GlobalEvents.RemoteEvent:FireClient(TargetPlayer, "TradeReqEvent", player)

			PlayerData.EditPlayerData(PlayerData, player, "LastTradeReq", TargetPlayer.Name)
		else
			PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.PlayerNotFound[1], PetSystemSettings.Messages.PlayerNotFound[2])
		end
	elseif rtype == "PetStatsEvent" then
		local Profile = Manager.Profiles[player]
		local EquipedPetsCount = 0
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if v.Equiped then
				EquipedPetsCount += 1
			end
		end
		local PetCount = GlobalPetCount.GetPetCounts()
		return Profile.Data.PetSystem.PetEquipSlot, Profile.Data.PetSystem.PetBackpackSlot, #Profile.Data.PetSystem.Pets, EquipedPetsCount, PetCount
	elseif rtype == "LockEvent" then
		local Profile = Manager.Profiles[player]
		for i,v in ipairs(Profile.Data.PetSystem.Pets) do
			if v.UUID == value1 then
				if v.Locked then
					v.Locked = false
				else
					v.Locked = true
				end
				return
			end
		end
	elseif rtype == "GetPetsEvent" then
		local Profile = Manager.Profiles[player]
		local equipedPets = {}
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if not v.Equiped then
				table.insert(equipedPets, v)
			end
		end
		return equipedPets
	elseif rtype == "GetEquipedPetsEvent" then
		local Profile = Manager.Profiles[player]
		local equipedPets = {}
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if v.Equiped then
				table.insert(equipedPets, v)
			end
		end
		return equipedPets
	elseif rtype == "EquipPetEvent" then
		local Profile = Manager.Profiles[player]
		local EquipedPetsCount = 0
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if v.Equiped then
				EquipedPetsCount += 1
			end
		end
		if EquipedPetsCount >= Profile.Data.PetSystem.PetEquipSlot then
			PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MaxEquip[1], PetSystemSettings.Messages.MaxEquip[2])
			return false
		end
		for i,v in pairs(Profile.Data.PetSystem.Pets) do
			if value1 == v.UUID and not v.Equiped then
				v.Equiped = true
				PetHanderModule.EquipPet(player, v.PetName)
				return true
			end
		end
	elseif rtype == "PetOpenEvent" then
		local Profile = Manager.Profiles[player]
		for i, PrizeTable in pairs(PetHatchList) do
			if i == value1 then
				if #Profile.Data.PetSystem.Pets >= Profile.Data.PetSystem.PetBackpackSlot then
					PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.MaxSpace[1], PetSystemSettings.Messages.MaxSpace[2])
					return false
				end
				local Timer = script.PlayerData:FindFirstChild(player.Name)
				if Timer then
					if Timer.Value > os.time() then return false end
					if player.FastOpenEnabled.Value then
						Timer.Value = os.time() + 3
					else
						Timer.Value = os.time() + 5
					end
				else
					local TimerValue = Instance.new("IntValue")
					TimerValue.Name = player.Name
					TimerValue.Parent = script.PlayerData
					if player.FastOpenEnabled.Value then
						TimerValue.Value = os.time() + 3.5
					else
						TimerValue.Value = os.time() + 5.5
					end
				end
				if value2 == 1 then
					if player:WaitForChild(PetSystemSettings.CurrencyFolder):FindFirstChild(PetSystemSettings.Currency).Value >= PrizeTable.Price then
						player:WaitForChild(PetSystemSettings.CurrencyFolder):FindFirstChild(PetSystemSettings.Currency).Value -= PrizeTable.Price
						local GeneralLuckBoost = 0
						if PlayerData.GivePlayerData(PlayerData, player).Luck1Gamepass then
							GeneralLuckBoost += PetSystemSettings.LuckRate.Luck1
						end
						if PlayerData.GivePlayerData(PlayerData, player).Luck2Gamepass then
							GeneralLuckBoost += PetSystemSettings.LuckRate.Luck2
						end
						if PlayerData.GivePlayerData(PlayerData, player).Luck3Gamepass then
							GeneralLuckBoost += PetSystemSettings.LuckRate.Luck3
						end
						for i, Chance in pairs(PrizeTable.PetList) do
							PrizeTable[i] = Chance + GeneralLuckBoost
						end
						local Weight = 0
						for i, Chance in pairs(PrizeTable.PetList) do
							Weight += (Chance * 1000)
						end
						local ranNumber = math.random(1, Weight)
						Weight = 0
						for petName, Chance in pairs(PrizeTable.PetList) do
							Weight += (Chance * 1000)
							if Weight >= ranNumber then
								local delete = false
								for z, y in pairs(value3) do
									if y == petName then
										delete = true
										break
									end
								end
								if not delete then
									table.insert(Profile.Data.PetSystem.Pets, {
										PetName = petName,
										PetType = "Normal", -- Normal, Golden, Rainbow
										UUID = HTTPService:GenerateGUID(),
										Equiped = false,
										Locked = false,
										Tradeable = true,
									})
									GlobalPetCount.CountPet(petName)
									if Profile.Data.PetSystem.Index == nil then
										table.insert(Profile.Data.PetSystem.Index, petName)
										return true, petName
									end
									for i,v in pairs(Profile.Data.PetSystem.Index) do
										if v == petName then return true, petName end
									end
									table.insert(Profile.Data.PetSystem.Index, petName)
								end
								return true, petName
							end
						end
					else
						PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.InsufficientBalance[1], PetSystemSettings.Messages.InsufficientBalance[2])
						return false
					end
				elseif value2 == 3 then
					if not PlayerData.GivePlayerData(PlayerData, player).Open3xGamepass then
						PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.NeedGamepass[1], PetSystemSettings.Messages.NeedGamepass[2])
						MarketplaceService:PromptGamePassPurchase(player, PetSystemSettings.Gamepass.Open3x)
						return false
					end
					if #Profile.Data.PetSystem.Pets + 2 >= Profile.Data.PetSystem.PetBackpackSlot then
						PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.NoSpace[1], PetSystemSettings.Messages.NoSpace[2])
						return false
					end
					if player:WaitForChild(PetSystemSettings.CurrencyFolder):FindFirstChild(PetSystemSettings.Currency).Value >= PrizeTable.Price * 3 then
						player:WaitForChild(PetSystemSettings.CurrencyFolder):FindFirstChild(PetSystemSettings.Currency).Value -= PrizeTable.Price * 3
						local PetNames = {}
						for i = 1, 3, 1 do
							local GeneralLuckBoost = 0
							if PlayerData.GivePlayerData(PlayerData, player).Luck1Gamepass then
								GeneralLuckBoost += PetSystemSettings.LuckRate.Luck1
							end
							if PlayerData.GivePlayerData(PlayerData, player).Luck2Gamepass then
								GeneralLuckBoost += PetSystemSettings.LuckRate.Luck2
							end
							if PlayerData.GivePlayerData(PlayerData, player).Luck3Gamepass then
								GeneralLuckBoost += PetSystemSettings.LuckRate.Luck3
							end
							for i, Chance in pairs(PrizeTable.PetList) do
								PrizeTable[i] = Chance + GeneralLuckBoost
							end
							local Weight = 0
							for i, Chance in pairs(PrizeTable.PetList) do
								Weight += (Chance * 1000)
							end
							local ranNumber = math.random(1, Weight)
							Weight = 0
							for petName, Chance in pairs(PrizeTable.PetList) do
								Weight += (Chance * 1000)
								if Weight >= ranNumber then
									local delete = false
									for z, y in pairs(value3) do
										if y == petName then
											delete = true
											break
										end
									end
									if not delete then
										table.insert(Profile.Data.PetSystem.Pets, {
											PetName = petName,
											PetType = "Normal", -- Normal, Golden, Rainbow
											UUID = HTTPService:GenerateGUID(),
											Equiped = false,
											Locked = false,
											Tradeable = true,
										})
										GlobalPetCount.CountPet(petName)
										if Profile.Data.PetSystem.Index == nil then
											table.insert(Profile.Data.PetSystem.Index, petName)
										end
										local found = false
										for i,v in pairs(Profile.Data.PetSystem.Index) do
											if v == petName then 
												found = true
											end
										end
										if not found then
											table.insert(Profile.Data.PetSystem.Index, petName)
										end
									end
									table.insert(PetNames, petName)
									break
								end
							end
						end
						return true, PetNames
					else
						PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.InsufficientBalance[1], PetSystemSettings.Messages.InsufficientBalance[2])
						return false
					end
				elseif value2 == 8 then
					if not PlayerData.GivePlayerData(PlayerData, player).Open8xGamepass then
						PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.NeedGamepass[1], PetSystemSettings.Messages.NeedGamepass[2])
						MarketplaceService:PromptGamePassPurchase(player, PetSystemSettings.Gamepass.Open8x)
						return false
					end
					if #Profile.Data.PetSystem.Pets + 7 >= Profile.Data.PetSystem.PetBackpackSlot then
						PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.NoSpace[1], PetSystemSettings.Messages.NoSpace[2])
						return false
					end
					if player:WaitForChild(PetSystemSettings.CurrencyFolder):FindFirstChild(PetSystemSettings.Currency).Value >= PrizeTable.Price * 8 then
						player:WaitForChild(PetSystemSettings.CurrencyFolder):FindFirstChild(PetSystemSettings.Currency).Value -= PrizeTable.Price * 8
						local PetNames = {}
						for i = 1, 8, 1 do
							local GeneralLuckBoost = 0
							if PlayerData.GivePlayerData(PlayerData, player).Luck1Gamepass then
								GeneralLuckBoost += PetSystemSettings.LuckRate.Luck1
							end
							if PlayerData.GivePlayerData(PlayerData, player).Luck2Gamepass then
								GeneralLuckBoost += PetSystemSettings.LuckRate.Luck2
							end
							if PlayerData.GivePlayerData(PlayerData, player).Luck3Gamepass then
								GeneralLuckBoost += PetSystemSettings.LuckRate.Luck3
							end
							for i, Chance in pairs(PrizeTable.PetList) do
								PrizeTable[i] = Chance + GeneralLuckBoost
							end
							local Weight = 0
							for i, Chance in pairs(PrizeTable.PetList) do
								Weight += (Chance * 1000)
							end
							local ranNumber = math.random(1, Weight)
							Weight = 0
							for petName, Chance in pairs(PrizeTable.PetList) do
								Weight += (Chance * 1000)
								if Weight >= ranNumber then
									local delete = false
									for z, y in pairs(value3) do
										if y == petName then
											delete = true
											break
										end
									end
									if not delete then
										table.insert(Profile.Data.PetSystem.Pets, {

											PetName = petName,
											PetType = "Normal", -- Normal, Golden, Rainbow
											UUID = HTTPService:GenerateGUID(),
											Equiped = false,
											Locked = false,
											Tradeable = true,

										})
										GlobalPetCount.CountPet(petName)
										if Profile.Data.PetSystem.Index == nil then
											table.insert(Profile.Data.PetSystem.Index, petName)
										end
										local found = false
										for i,v in pairs(Profile.Data.PetSystem.Index) do
											if v == petName then 
												found = true
											end
										end
										if not found then
											table.insert(Profile.Data.PetSystem.Index, petName)
										end
									end
									table.insert(PetNames, petName)
									break
								end
							end
						end
						return true, PetNames
					else
						PetSystemRS.GlobalEvents.RemoteEvent:FireClient(player, "NotifyEvent", PetSystemSettings.Messages.InsufficientBalance[1], PetSystemSettings.Messages.InsufficientBalance[2])
						return false
					end
				end
			end
		end 	
	end
end