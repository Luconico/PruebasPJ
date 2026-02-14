--[[
	ReferralSystem.server.lua
	Referral system: when an invited friend joins the game,
	the player who invited them can claim 3,500 coins (up to 3 times).
	Uses Player:GetJoinData().ReferredByPlayerId from the official Roblox API.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for ServerFunctions (created by PlayerData)
local ServerFunctions = ReplicatedStorage:WaitForChild("ServerFunctions")
local ModifyCoinsServer = ServerFunctions:WaitForChild("ModifyCoinsServer")
local GetReferralDataServer = ServerFunctions:WaitForChild("GetReferralDataServer")
local AddReferralServer = ServerFunctions:WaitForChild("AddReferralServer")
local ClaimReferralServer = ServerFunctions:WaitForChild("ClaimReferralServer")

-- Wait for Remotes (created by PlayerData)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OnDataUpdated = Remotes:WaitForChild("OnDataUpdated")

-- Config
local REWARD_COINS = 3500
local MAX_REFERRALS = 3

-- ============================================
-- CREATE REMOTES FOR REFERRALS
-- ============================================
local claimReferralRemote = Instance.new("RemoteFunction")
claimReferralRemote.Name = "ClaimReferralReward"
claimReferralRemote.Parent = Remotes

local getReferralStatusRemote = Instance.new("RemoteFunction")
getReferralStatusRemote.Name = "GetReferralStatus"
getReferralStatusRemote.Parent = Remotes

-- Event to notify the referrer in real time
local onReferralReceived = Instance.new("RemoteEvent")
onReferralReceived.Name = "OnReferralReceived"
onReferralReceived.Parent = Remotes

-- ============================================
-- REFERRAL DETECTION ON JOIN
-- ============================================

local function onPlayerAdded(player)
	-- Wait a moment for data to load
	task.wait(3)

	local joinData = player:GetJoinData()
	local referredByPlayerId = joinData.ReferredByPlayerId

	-- Check if this player joined via referral
	if not referredByPlayerId or referredByPlayerId == 0 then
		return
	end

	print("[ReferralSystem]", player.Name, "joined via referral from UserId:", referredByPlayerId)

	-- Find the player who invited them (must be in the server)
	local referrerPlayer = Players:GetPlayerByUserId(referredByPlayerId)
	if not referrerPlayer then
		print("[ReferralSystem] Referrer (ID:", referredByPlayerId, ") is not in the server")
		return
	end

	-- Register referral via BindableFunction (modifies the REAL cache)
	local success, result = AddReferralServer:Invoke(referrerPlayer, player.UserId, MAX_REFERRALS)

	if not success then
		print("[ReferralSystem] Could not add referral:", result)
		return
	end

	-- Get updated data to notify client
	local referralData = GetReferralDataServer:Invoke(referrerPlayer)

	-- Notify the referrer that they have a new reward
	if referralData then
		OnDataUpdated:FireClient(referrerPlayer, {
			ReferralData = referralData,
		})
	end

	-- Send real-time notification
	onReferralReceived:FireClient(referrerPlayer, {
		ReferredPlayerName = player.Name,
		PendingRewards = referralData and referralData.PendingRewards or 0,
		TotalReferrals = referralData and #referralData.ReferredPlayers or 0,
		MaxReferrals = MAX_REFERRALS,
	})

	print("[ReferralSystem] Referral registered!", referrerPlayer.Name, "->", player.Name)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- ============================================
-- GET REFERRAL STATUS
-- ============================================

getReferralStatusRemote.OnServerInvoke = function(player)
	local referralData = GetReferralDataServer:Invoke(player)

	if not referralData then
		return {
			TotalReferrals = 0,
			ClaimedCount = 0,
			PendingRewards = 0,
			MaxReferrals = MAX_REFERRALS,
			RewardPerReferral = REWARD_COINS,
			ReferredNames = {},
		}
	end

	-- Get names of referred players
	local referredNames = {}
	for _, userId in ipairs(referralData.ReferredPlayers or {}) do
		local success, name = pcall(function()
			return Players:GetNameFromUserIdAsync(userId)
		end)
		if success then
			table.insert(referredNames, name)
		else
			table.insert(referredNames, "Player #" .. userId)
		end
	end

	return {
		TotalReferrals = #(referralData.ReferredPlayers or {}),
		ClaimedCount = referralData.ClaimedCount or 0,
		PendingRewards = referralData.PendingRewards or 0,
		MaxReferrals = MAX_REFERRALS,
		RewardPerReferral = REWARD_COINS,
		ReferredNames = referredNames,
	}
end

-- ============================================
-- CLAIM REFERRAL REWARD
-- ============================================

claimReferralRemote.OnServerInvoke = function(player)
	-- Claim via BindableFunction (modifies the REAL cache)
	local success, claimedCount, pendingLeft = ClaimReferralServer:Invoke(player, MAX_REFERRALS)

	if not success then
		-- claimedCount contains the error message in this case
		local errorMsg = claimedCount
		if errorMsg == "NoPending" then
			return false, "No pending rewards"
		elseif errorMsg == "MaxClaimed" then
			return false, "Maximum rewards already claimed"
		end
		return false, "Error claiming reward"
	end

	-- Give coins
	local coinSuccess, newCoins = ModifyCoinsServer:Invoke(player, REWARD_COINS)
	if not coinSuccess then
		return false, "Error granting coins"
	end

	-- Notify client with updated data
	local referralData = GetReferralDataServer:Invoke(player)
	OnDataUpdated:FireClient(player, {
		Coins = newCoins,
		ReferralData = referralData,
	})

	print("[ReferralSystem]", player.Name, "claimed referral reward! +", REWARD_COINS,
		"coins (", claimedCount, "/", MAX_REFERRALS, ")")

	return true, REWARD_COINS, claimedCount, pendingLeft
end

print("[ReferralSystem] Referral system initialized")
