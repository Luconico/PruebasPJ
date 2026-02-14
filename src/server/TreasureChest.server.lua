--[[
	TreasureChest.server.lua
	Treasure chest: rewards 10,000 coins if the player
	is in the group (ID 803229435). One time per player.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for ServerFunctions (created by PlayerData)
local ServerFunctions = ReplicatedStorage:WaitForChild("ServerFunctions")
local ModifyCoinsServer = ServerFunctions:WaitForChild("ModifyCoinsServer")
local ClaimTreasureServer = ServerFunctions:WaitForChild("ClaimTreasureServer")
local CheckTreasureClaimedServer = ServerFunctions:WaitForChild("CheckTreasureClaimedServer")

-- Wait for Remotes (created by PlayerData)
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Config
local GROUP_ID = 803229435
local REWARD_COINS = 10000

-- ============================================
-- CREATE REMOTES FOR THE CHEST
-- ============================================
local claimTreasureRemote = Instance.new("RemoteFunction")
claimTreasureRemote.Name = "ClaimTreasure"
claimTreasureRemote.Parent = Remotes

local checkTreasureRemote = Instance.new("RemoteFunction")
checkTreasureRemote.Name = "CheckTreasureStatus"
checkTreasureRemote.Parent = Remotes

-- ============================================
-- FUNCTIONS
-- ============================================

-- Check if the player is in the group
local function isInGroup(player)
	local success, result = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)
	if not success then
		warn("[TreasureChest] Error checking group for", player.Name, ":", result)
		return false
	end
	return result
end

-- ============================================
-- REMOTE HANDLERS
-- ============================================

-- Check chest status (already claimed, in group, etc.)
checkTreasureRemote.OnServerInvoke = function(player)
	-- Use BindableFunction to check the REAL cache
	local alreadyClaimed = CheckTreasureClaimedServer:Invoke(player)

	if alreadyClaimed then
		return { CanClaim = false, Reason = "AlreadyClaimed" }
	end

	-- Check group membership
	local inGroup = isInGroup(player)
	if not inGroup then
		return { CanClaim = false, Reason = "NotInGroup", GroupId = GROUP_ID }
	end

	return { CanClaim = true }
end

-- Claim the chest reward
claimTreasureRemote.OnServerInvoke = function(player)
	-- Check not already claimed (on the REAL cache)
	local alreadyClaimed = CheckTreasureClaimedServer:Invoke(player)
	if alreadyClaimed then
		return false, "You already claimed this reward"
	end

	-- Check group membership
	local inGroup = isInGroup(player)
	if not inGroup then
		return false, "You must join the group first"
	end

	-- Give coins
	local success, newCoins = ModifyCoinsServer:Invoke(player, REWARD_COINS)
	if not success then
		return false, "Error granting coins"
	end

	-- Mark as claimed on the REAL cache (via BindableFunction)
	local claimSuccess = ClaimTreasureServer:Invoke(player)
	if not claimSuccess then
		return false, "Error saving claim status"
	end

	print("[TreasureChest]", player.Name, "claimed the treasure chest! +", REWARD_COINS, "coins")
	return true, "You received " .. REWARD_COINS .. " coins!"
end

print("[TreasureChest] Treasure chest system initialized")
