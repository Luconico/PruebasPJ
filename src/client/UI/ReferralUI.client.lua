--[[
	ReferralUI.client.lua
	Referral system UI: shows invite progress,
	allows claiming 3,500 coins per friend who joins (max 3).
	Opens from a button positioned top-right, left of the audio controls.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimReferralReward = Remotes:WaitForChild("ClaimReferralReward")
local GetReferralStatus = Remotes:WaitForChild("GetReferralStatus")
local OnReferralReceived = Remotes:WaitForChild("OnReferralReceived")

-- Local state
local isUIOpen = false
local currentStatus = nil
local isProcessing = false

-- UI references (populated on creation)
local screenGui, overlay, mainFrame
local progressSlots = {}
local claimButton, claimButtonText, claimButtonStroke
local descLabel, progressLabel
local notifBadge

-- ============================================
-- CREATE UI
-- ============================================

local function createUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ReferralGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Calculate position to sit left of the MusicPlayer audio controls
	-- MusicPlayer uses: BUTTON_SIZE=scale(38), SPACING=scale(6), PADDING=scale(8), MARGIN=scale(12)
	-- Container width = (38*3) + (6*2) + (8*2) = 142 scaled pixels
	local MARGIN = ResponsiveUI.scale(12)
	local MUSIC_WIDTH = (ResponsiveUI.scale(38) * 3) + (ResponsiveUI.scale(6) * 2) + (ResponsiveUI.scale(8) * 2)
	local GAP = ResponsiveUI.scale(8) -- gap between referral button and music controls

	local info = ResponsiveUI.getViewportInfo()
	local isMobile = info.IsMobile
	local openBtnSize = isMobile and 42 or 48

	-- Position: top-right, just left of the MusicPlayer container
	local openButton = Instance.new("ImageButton")
	openButton.Name = "OpenReferralBtn"
	openButton.Size = UDim2.new(0, openBtnSize, 0, openBtnSize)
	openButton.Position = UDim2.new(1, -(MARGIN + MUSIC_WIDTH + GAP + openBtnSize), 0, MARGIN)
	openButton.BackgroundTransparency = 1
	openButton.Image = TextureManager.Backgrounds.StudGray
	openButton.ImageColor3 = Color3.fromRGB(80, 180, 255)
	openButton.ImageTransparency = 0.1
	openButton.ScaleType = Enum.ScaleType.Tile
	openButton.TileSize = UDim2.new(0, 32, 0, 32)
	openButton.ZIndex = 5
	openButton.Parent = screenGui

	local openCorner = Instance.new("UICorner")
	openCorner.CornerRadius = UDim.new(0, 10)
	openCorner.Parent = openButton

	local openStroke = Instance.new("UIStroke")
	openStroke.Color = Color3.fromRGB(40, 100, 180)
	openStroke.Thickness = 2
	openStroke.Transparency = 0.3
	openStroke.Parent = openButton

	local openIcon = Instance.new("TextLabel")
	openIcon.Size = UDim2.new(0.75, 0, 0.75, 0)
	openIcon.Position = UDim2.new(0.125, 0, 0.125, 0)
	openIcon.BackgroundTransparency = 1
	openIcon.Text = "🎁"
	openIcon.TextScaled = true
	openIcon.ZIndex = 6
	openIcon.Parent = openButton

	-- Notification badge (pending rewards)
	notifBadge = Instance.new("Frame")
	notifBadge.Name = "NotifBadge"
	notifBadge.Size = UDim2.new(0, 22, 0, 22)
	notifBadge.Position = UDim2.new(1, -8, 0, -8)
	notifBadge.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	notifBadge.ZIndex = 7
	notifBadge.Visible = false
	notifBadge.Parent = openButton

	local badgeCorner = Instance.new("UICorner")
	badgeCorner.CornerRadius = UDim.new(1, 0)
	badgeCorner.Parent = notifBadge

	local badgeStroke = Instance.new("UIStroke")
	badgeStroke.Color = Color3.fromRGB(150, 20, 20)
	badgeStroke.Thickness = 2
	badgeStroke.Parent = notifBadge

	local badgeText = Instance.new("TextLabel")
	badgeText.Name = "BadgeText"
	badgeText.Size = UDim2.new(1, 0, 1, 0)
	badgeText.BackgroundTransparency = 1
	badgeText.Text = "0"
	badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
	badgeText.Font = Enum.Font.FredokaOne
	badgeText.TextScaled = true
	badgeText.ZIndex = 8
	badgeText.Parent = notifBadge

	-- Hover effect
	openButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover")
		TweenService:Create(openButton, TweenInfo.new(0.15), { ImageTransparency = 0 }):Play()
		TweenService:Create(openStroke, TweenInfo.new(0.15), { Thickness = 3 }):Play()
	end)
	openButton.MouseLeave:Connect(function()
		TweenService:Create(openButton, TweenInfo.new(0.15), { ImageTransparency = 0.1 }):Play()
		TweenService:Create(openStroke, TweenInfo.new(0.15), { Thickness = 2 }):Play()
	end)

	openButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick")
		if isUIOpen then
			closeUI()
		else
			openUI()
		end
	end)

	-- ============================================
	-- OVERLAY
	-- ============================================
	overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 1
	overlay.BorderSizePixel = 0
	overlay.ZIndex = 50
	overlay.Visible = false
	overlay.Parent = screenGui

	overlay.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			closeUI()
		end
	end)

	-- ============================================
	-- MAIN PANEL
	-- ============================================
	local panelW = isMobile and 360 or 440
	local panelH = isMobile and 420 or 460

	mainFrame = Instance.new("ImageLabel")
	mainFrame.Name = "ReferralPanel"
	mainFrame.Size = UDim2.new(0, panelW, 0, panelH)
	mainFrame.Position = UDim2.new(0.5, -panelW / 2, 0.5, -panelH / 2)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Image = TextureManager.Backgrounds.StudGray
	mainFrame.ImageColor3 = Color3.fromRGB(35, 40, 65)
	mainFrame.ImageTransparency = 0.05
	mainFrame.ScaleType = Enum.ScaleType.Tile
	mainFrame.TileSize = UDim2.new(0, 32, 0, 32)
	mainFrame.ZIndex = 51
	mainFrame.Visible = false
	mainFrame.Parent = screenGui

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 16)
	panelCorner.Parent = mainFrame

	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(80, 180, 255)
	panelStroke.Thickness = 3
	panelStroke.Parent = mainFrame

	-- Top icon (overflows)
	local topIcon = Instance.new("TextLabel")
	topIcon.Size = UDim2.new(0, 80, 0, 80)
	topIcon.Position = UDim2.new(0.5, -40, 0, -40)
	topIcon.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
	topIcon.Text = "🎁"
	topIcon.TextScaled = true
	topIcon.ZIndex = 53
	topIcon.Parent = mainFrame

	local topIconCorner = Instance.new("UICorner")
	topIconCorner.CornerRadius = UDim.new(1, 0)
	topIconCorner.Parent = topIcon

	local topIconStroke = Instance.new("UIStroke")
	topIconStroke.Color = Color3.fromRGB(40, 100, 180)
	topIconStroke.Thickness = 3
	topIconStroke.Parent = topIcon

	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(1, -40, 0, 36)
	titleLabel.Position = UDim2.new(0, 20, 0, 50)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "INVITE FRIENDS"
	titleLabel.TextColor3 = Color3.fromRGB(80, 200, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.FredokaOne
	titleLabel.ZIndex = 52
	titleLabel.Parent = mainFrame

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(20, 60, 120)
	titleStroke.Thickness = 2
	titleStroke.Parent = titleLabel

	-- Separator
	local sep = Instance.new("Frame")
	sep.Size = UDim2.new(0.8, 0, 0, 3)
	sep.Position = UDim2.new(0.1, 0, 0, 92)
	sep.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
	sep.BorderSizePixel = 0
	sep.ZIndex = 52
	sep.Parent = mainFrame

	local sepCorner = Instance.new("UICorner")
	sepCorner.CornerRadius = UDim.new(0, 2)
	sepCorner.Parent = sep

	-- Description
	descLabel = Instance.new("TextLabel")
	descLabel.Size = UDim2.new(1, -40, 0, 36)
	descLabel.Position = UDim2.new(0, 20, 0, 102)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = "Invite friends and earn 3,500 coins for each one"
	descLabel.TextColor3 = Color3.fromRGB(200, 210, 230)
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.Font = Enum.Font.GothamBold
	descLabel.ZIndex = 52
	descLabel.Parent = mainFrame

	-- Reward per friend
	local rewardLine = Instance.new("TextLabel")
	rewardLine.Size = UDim2.new(1, -40, 0, 32)
	rewardLine.Position = UDim2.new(0, 20, 0, 142)
	rewardLine.BackgroundTransparency = 1
	rewardLine.Text = "💰 3,500 coins per friend 💰"
	rewardLine.TextColor3 = Color3.fromRGB(100, 255, 100)
	rewardLine.TextScaled = true
	rewardLine.Font = Enum.Font.FredokaOne
	rewardLine.ZIndex = 52
	rewardLine.Parent = mainFrame

	local rewardStroke = Instance.new("UIStroke")
	rewardStroke.Color = Color3.fromRGB(0, 80, 0)
	rewardStroke.Thickness = 1.5
	rewardStroke.Parent = rewardLine

	-- ============================================
	-- PROGRESS SLOTS (3 friend slots)
	-- ============================================
	local slotsContainer = Instance.new("Frame")
	slotsContainer.Name = "SlotsContainer"
	slotsContainer.Size = UDim2.new(0.9, 0, 0, 90)
	slotsContainer.Position = UDim2.new(0.05, 0, 0, 185)
	slotsContainer.BackgroundTransparency = 1
	slotsContainer.ZIndex = 52
	slotsContainer.Parent = mainFrame

	local slotsLayout = Instance.new("UIListLayout")
	slotsLayout.FillDirection = Enum.FillDirection.Horizontal
	slotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	slotsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	slotsLayout.Padding = UDim.new(0, 12)
	slotsLayout.Parent = slotsContainer

	progressSlots = {}
	for i = 1, 3 do
		local slot = Instance.new("ImageLabel")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 110, 0, 85)
		slot.BackgroundTransparency = 1
		slot.Image = TextureManager.Backgrounds.StudGray
		slot.ImageColor3 = Color3.fromRGB(55, 55, 75)
		slot.ImageTransparency = 0.15
		slot.ScaleType = Enum.ScaleType.Tile
		slot.TileSize = UDim2.new(0, 32, 0, 32)
		slot.LayoutOrder = i
		slot.ZIndex = 52
		slot.Parent = slotsContainer

		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 10)
		slotCorner.Parent = slot

		local slotStroke = Instance.new("UIStroke")
		slotStroke.Name = "SlotStroke"
		slotStroke.Color = Color3.fromRGB(80, 80, 100)
		slotStroke.Thickness = 2
		slotStroke.Parent = slot

		-- State icon
		local stateIcon = Instance.new("TextLabel")
		stateIcon.Name = "StateIcon"
		stateIcon.Size = UDim2.new(1, 0, 0, 40)
		stateIcon.Position = UDim2.new(0, 0, 0, 5)
		stateIcon.BackgroundTransparency = 1
		stateIcon.Text = "❓"
		stateIcon.TextScaled = true
		stateIcon.ZIndex = 53
		stateIcon.Parent = slot

		-- Friend name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "FriendName"
		nameLabel.Size = UDim2.new(1, -8, 0, 14)
		nameLabel.Position = UDim2.new(0, 4, 0, 47)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = "Waiting..."
		nameLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.ZIndex = 53
		nameLabel.Parent = slot

		-- Status (claimed / pending)
		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "StatusLabel"
		statusLabel.Size = UDim2.new(1, -8, 0, 14)
		statusLabel.Position = UDim2.new(0, 4, 0, 63)
		statusLabel.BackgroundTransparency = 1
		statusLabel.Text = ""
		statusLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
		statusLabel.TextScaled = true
		statusLabel.Font = Enum.Font.GothamBold
		statusLabel.ZIndex = 53
		statusLabel.Parent = slot

		progressSlots[i] = slot
	end

	-- Overall progress label
	progressLabel = Instance.new("TextLabel")
	progressLabel.Size = UDim2.new(1, -40, 0, 24)
	progressLabel.Position = UDim2.new(0, 20, 0, 282)
	progressLabel.BackgroundTransparency = 1
	progressLabel.Text = "Friends invited: 0/3"
	progressLabel.TextColor3 = Color3.fromRGB(180, 190, 210)
	progressLabel.TextScaled = true
	progressLabel.Font = Enum.Font.GothamBold
	progressLabel.ZIndex = 52
	progressLabel.Parent = mainFrame

	-- ============================================
	-- CLAIM BUTTON
	-- ============================================
	claimButton = Instance.new("ImageButton")
	claimButton.Name = "ClaimButton"
	claimButton.Size = UDim2.new(0.75, 0, 0, 55)
	claimButton.Position = UDim2.new(0.125, 0, 0, 318)
	claimButton.BackgroundTransparency = 1
	claimButton.Image = TextureManager.Backgrounds.StudGray
	claimButton.ImageColor3 = Color3.fromRGB(80, 80, 80)
	claimButton.ImageTransparency = 0.1
	claimButton.ScaleType = Enum.ScaleType.Tile
	claimButton.TileSize = UDim2.new(0, 32, 0, 32)
	claimButton.ZIndex = 52
	claimButton.Parent = mainFrame

	local claimCorner = Instance.new("UICorner")
	claimCorner.CornerRadius = UDim.new(0, 12)
	claimCorner.Parent = claimButton

	claimButtonStroke = Instance.new("UIStroke")
	claimButtonStroke.Color = Color3.fromRGB(50, 50, 50)
	claimButtonStroke.Thickness = 2.5
	claimButtonStroke.Parent = claimButton

	claimButtonText = Instance.new("TextLabel")
	claimButtonText.Name = "ButtonText"
	claimButtonText.Size = UDim2.new(1, 0, 1, 0)
	claimButtonText.BackgroundTransparency = 1
	claimButtonText.Text = "NO REWARDS"
	claimButtonText.TextColor3 = Color3.fromRGB(200, 200, 200)
	claimButtonText.TextScaled = true
	claimButtonText.Font = Enum.Font.FredokaOne
	claimButtonText.ZIndex = 53
	claimButtonText.Parent = claimButton

	local claimTextStroke = Instance.new("UIStroke")
	claimTextStroke.Color = Color3.fromRGB(30, 30, 30)
	claimTextStroke.Thickness = 2
	claimTextStroke.Parent = claimButtonText

	-- Footer note
	local footerLabel = Instance.new("TextLabel")
	footerLabel.Size = UDim2.new(1, -30, 0, 28)
	footerLabel.Position = UDim2.new(0, 15, 0, 382)
	footerLabel.BackgroundTransparency = 1
	footerLabel.Text = "Your friends must join through your invite link"
	footerLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
	footerLabel.TextScaled = true
	footerLabel.TextWrapped = true
	footerLabel.Font = Enum.Font.Gotham
	footerLabel.ZIndex = 52
	footerLabel.Parent = mainFrame

	-- Claim button hover
	claimButton.MouseEnter:Connect(function()
		if isProcessing then return end
		if currentStatus and currentStatus.PendingRewards > 0 then
			SoundManager.play("ButtonHover")
			TweenService:Create(claimButton, TweenInfo.new(0.15), { ImageTransparency = 0 }):Play()
			TweenService:Create(claimButtonStroke, TweenInfo.new(0.15), { Thickness = 3.5 }):Play()
		end
	end)
	claimButton.MouseLeave:Connect(function()
		TweenService:Create(claimButton, TweenInfo.new(0.15), { ImageTransparency = 0.1 }):Play()
		TweenService:Create(claimButtonStroke, TweenInfo.new(0.15), { Thickness = 2.5 }):Play()
	end)

	-- Claim button click
	claimButton.MouseButton1Click:Connect(function()
		onClaimClicked()
	end)

	-- Close button
	UIComponentsManager.createCloseButton(mainFrame, {
		onClose = function()
			closeUI()
		end,
	})
end

-- ============================================
-- OPEN / CLOSE UI
-- ============================================

function openUI()
	if isUIOpen then return end
	isUIOpen = true

	SoundManager.play("PopupOpen")

	-- Refresh data
	refreshStatus()

	overlay.Visible = true
	mainFrame.Visible = true

	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.5,
	}):Play()

	local info = ResponsiveUI.getViewportInfo()
	local isMobile = info.IsMobile
	local panelW = isMobile and 360 or 440
	local panelH = isMobile and 420 or 460

	TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, panelW, 0, panelH),
		Position = UDim2.new(0.5, -panelW / 2, 0.5, -panelH / 2),
	}):Play()
end

function closeUI()
	if not isUIOpen then return end
	isUIOpen = false

	SoundManager.play("PopupClose")

	TweenService:Create(overlay, TweenInfo.new(0.25), {
		BackgroundTransparency = 1,
	}):Play()

	local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.5, 0),
	})
	closeTween:Play()
	closeTween.Completed:Wait()

	overlay.Visible = false
	mainFrame.Visible = false
end

-- ============================================
-- UPDATE UI WITH DATA
-- ============================================

local function updateSlotsUI(status)
	for i = 1, 3 do
		local slot = progressSlots[i]
		local stateIcon = slot:FindFirstChild("StateIcon")
		local friendName = slot:FindFirstChild("FriendName")
		local statusLabel = slot:FindFirstChild("StatusLabel")
		local slotStroke = slot:FindFirstChild("SlotStroke")

		if i <= status.TotalReferrals then
			-- Slot filled: friend joined
			local name = status.ReferredNames[i] or "Friend #" .. i
			friendName.Text = name
			friendName.TextColor3 = Color3.fromRGB(255, 255, 255)

			if i <= status.ClaimedCount then
				-- Already claimed
				stateIcon.Text = "✅"
				statusLabel.Text = "Claimed"
				statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				slotStroke.Color = Color3.fromRGB(50, 180, 70)
				slot.ImageColor3 = Color3.fromRGB(40, 70, 50)
			else
				-- Pending claim
				stateIcon.Text = "💰"
				statusLabel.Text = "Pending!"
				statusLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
				slotStroke.Color = Color3.fromRGB(255, 200, 50)
				slot.ImageColor3 = Color3.fromRGB(70, 60, 35)

				-- Glow animation
				TweenService:Create(slotStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
					Color = Color3.fromRGB(255, 255, 120),
				}):Play()
			end
		else
			-- Empty slot
			stateIcon.Text = "❓"
			friendName.Text = "Waiting..."
			friendName.TextColor3 = Color3.fromRGB(150, 150, 170)
			statusLabel.Text = ""
			slotStroke.Color = Color3.fromRGB(80, 80, 100)
			slot.ImageColor3 = Color3.fromRGB(55, 55, 75)
		end
	end
end

local function updateClaimButton(status)
	if status.PendingRewards > 0 then
		claimButton.ImageColor3 = Color3.fromRGB(50, 200, 80)
		claimButtonStroke.Color = Color3.fromRGB(30, 130, 50)
		claimButtonText.Text = "CLAIM 3,500 COINS (" .. status.PendingRewards .. ")"
		claimButtonText.TextColor3 = Color3.fromRGB(255, 255, 255)
	elseif status.ClaimedCount >= status.MaxReferrals then
		claimButton.ImageColor3 = Color3.fromRGB(60, 60, 80)
		claimButtonStroke.Color = Color3.fromRGB(40, 40, 60)
		claimButtonText.Text = "ALL CLAIMED ✓"
		claimButtonText.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		claimButton.ImageColor3 = Color3.fromRGB(80, 80, 80)
		claimButtonStroke.Color = Color3.fromRGB(50, 50, 50)
		claimButtonText.Text = "NO REWARDS"
		claimButtonText.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end

local function updateBadge(status)
	if status.PendingRewards > 0 then
		notifBadge.Visible = true
		local badgeText = notifBadge:FindFirstChild("BadgeText")
		if badgeText then
			badgeText.Text = tostring(status.PendingRewards)
		end
	else
		notifBadge.Visible = false
	end
end

local function updateFullUI(status)
	currentStatus = status
	progressLabel.Text = "Friends invited: " .. status.TotalReferrals .. "/" .. status.MaxReferrals
	updateSlotsUI(status)
	updateClaimButton(status)
	updateBadge(status)
end

-- ============================================
-- REFRESH DATA FROM SERVER
-- ============================================

function refreshStatus()
	local status = GetReferralStatus:InvokeServer()
	if status then
		updateFullUI(status)
	end
end

-- ============================================
-- CLAIM REWARD
-- ============================================

function onClaimClicked()
	if isProcessing then return end
	if not currentStatus or currentStatus.PendingRewards <= 0 then return end

	isProcessing = true
	claimButtonText.Text = "PROCESSING..."
	claimButton.ImageColor3 = Color3.fromRGB(150, 150, 150)

	local success, coins, claimedCount, pendingLeft = ClaimReferralReward:InvokeServer()

	if success then
		SoundManager.play("CashRegister")

		-- Success animation
		claimButton.ImageColor3 = Color3.fromRGB(255, 200, 50)
		claimButtonStroke.Color = Color3.fromRGB(180, 140, 30)
		claimButtonText.Text = "+3,500 COINS!"

		-- Pop effect on the claimed slot
		if currentStatus then
			local slotIdx = claimedCount or (currentStatus.ClaimedCount + 1)
			if slotIdx >= 1 and slotIdx <= 3 then
				local slot = progressSlots[slotIdx]
				TweenService:Create(slot, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0, 120, 0, 95),
				}):Play()
				task.delay(0.3, function()
					TweenService:Create(slot, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 110, 0, 85),
					}):Play()
				end)
			end
		end

		task.wait(1.2)

		-- Refresh full status
		refreshStatus()
	else
		SoundManager.play("Error")
		claimButtonText.Text = coins or "Error"
		claimButton.ImageColor3 = Color3.fromRGB(200, 60, 60)

		task.wait(1.5)
		refreshStatus()
	end

	isProcessing = false
end

-- ============================================
-- REAL-TIME NOTIFICATION
-- ============================================

OnReferralReceived.OnClientEvent:Connect(function(data)
	-- A friend just joined via referral
	print("[ReferralUI] New referral:", data.ReferredPlayerName)

	-- Refresh UI
	refreshStatus()

	-- Show notification
	local StarterGui = game:GetService("StarterGui")
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Friend Invited!",
			Text = data.ReferredPlayerName .. " joined through your invite. Claim your reward!",
			Duration = 6,
		})
	end)

	-- Pulse the badge
	if notifBadge.Visible then
		TweenService:Create(notifBadge, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 30, 0, 30),
		}):Play()
		task.delay(0.3, function()
			TweenService:Create(notifBadge, TweenInfo.new(0.2), {
				Size = UDim2.new(0, 22, 0, 22),
			}):Play()
		end)
	end
end)

-- ============================================
-- INITIALIZATION
-- ============================================

createUI()

-- Load initial status
task.spawn(function()
	task.wait(4) -- Wait for player data to load
	refreshStatus()
end)

print("[ReferralUI] Referral UI initialized")
