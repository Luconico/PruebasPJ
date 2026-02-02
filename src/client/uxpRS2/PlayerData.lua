local PlayerData = {}

local PlayerDatas = {}

function PlayerData:AddPlayerData(player, gp1, gp2, gp3, gp4, gp5, gp6, gp7)
	
	local playerD = {
		
		AutoOpenGamepass = gp1,
		FastOpenGamepass = gp2,
		Luck1Gamepass = gp3,
		Luck2Gamepass = gp4,
		Luck3Gamepass = gp5,
		Open3xGamepass = gp6,
		Open8xGamepass = gp7,
		LastTradeReq = nil,
		TradeAccepted = false,
		TradeOpen = true,
		Trading = false,
		TradingWith = nil,
		
	}
	
	PlayerDatas[player.UserId] = playerD
	
	
end

function PlayerData:RemovePlayerData(player)
	PlayerDatas[player.UserId] = nil
end

function PlayerData:GivePlayerData(player)

	return PlayerDatas[player.UserId]

end

function PlayerData:EditPlayerData(player, data, value)
	
	local newPlayerData = PlayerDatas[player.UserId]
	
	if newPlayerData then
		
		PlayerDatas[player.UserId][data] = value
		
	end
	
	return PlayerDatas[player.UserId]

end

function PlayerData:PrintPlayerData(player)
	
	print(PlayerDatas[player.UserId])
	
end

return PlayerData
