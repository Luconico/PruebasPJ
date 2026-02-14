--[[
	TreasureChestUI.client.lua
	Treasure chest UI: detects proximity, shows popup to
	claim 10,000 coins if the player is in the group.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimTreasure = Remotes:WaitForChild("ClaimTreasure")
local CheckTreasureStatus = Remotes:WaitForChild("CheckTreasureStatus")

-- Config
local PROXIMITY_DISTANCE = 15 -- Studs to activate UI
local GROUP_ID = 803229435
local REWARD_AMOUNT = 10000

-- State
local isUIOpen = false
local hasClaimed = false
local treasureModel = nil

-- ============================================
-- FIND TREASURE MODEL IN WORKSPACE
-- ============================================
local function findTreasure()
	local model = workspace:FindFirstChild("Treasure", true)
	if model then
		return model
	end
	return nil
end

-- Wait for the model to exist
task.spawn(function()
	while not treasureModel do
		treasureModel = findTreasure()
		if not treasureModel then
			task.wait(2)
		end
	end
	print("[TreasureChestUI] Treasure model found")
end)

-- ============================================
-- CREATE UI
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TreasureChestGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

-- Proximity indicator (floating icon above the chest)
local proximityBillboard = Instance.new("BillboardGui")
proximityBillboard.Name = "TreasureIndicator"
proximityBillboard.Size = UDim2.new(0, 80, 0, 80)
proximityBillboard.StudsOffset = Vector3.new(0, 5, 0)
proximityBillboard.AlwaysOnTop = true
proximityBillboard.Active = false
proximityBillboard.Enabled = false

local indicatorIcon = Instance.new("TextLabel")
indicatorIcon.Name = "Icon"
indicatorIcon.Size = UDim2.new(1, 0, 1, 0)
indicatorIcon.BackgroundTransparency = 1
indicatorIcon.Text = "💰"
indicatorIcon.TextScaled = true
indicatorIcon.Parent = proximityBillboard

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.ZIndex = 50
overlay.Visible = false
overlay.Parent = screenGui

-- Main popup panel
local mainFrame = Instance.new("ImageLabel")
mainFrame.Name = "TreasurePanel"
mainFrame.Size = UDim2.new(0, 420, 0, 380)
mainFrame.Position = UDim2.new(0.5, -210, 0.5, -190)
mainFrame.BackgroundTransparency = 1
mainFrame.Image = TextureManager.Backgrounds.StudGray
mainFrame.ImageColor3 = Color3.fromRGB(45, 35, 55)
mainFrame.ImageTransparency = 0.05
mainFrame.ScaleType = Enum.ScaleType.Tile
mainFrame.TileSize = UDim2.new(0, 32, 0, 32)
mainFrame.ZIndex = 51
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(255, 200, 50)
mainStroke.Thickness = 3
mainStroke.Parent = mainFrame

-- Chest icon (top, overflows)
local chestIcon = Instance.new("TextLabel")
chestIcon.Name = "ChestIcon"
chestIcon.Size = UDim2.new(0, 90, 0, 90)
chestIcon.Position = UDim2.new(0.5, -45, 0, -45)
chestIcon.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
chestIcon.Text = "🏴‍☠️"
chestIcon.TextScaled = true
chestIcon.ZIndex = 53
chestIcon.Parent = mainFrame

local chestIconCorner = Instance.new("UICorner")
chestIconCorner.CornerRadius = UDim.new(1, 0)
chestIconCorner.Parent = chestIcon

local chestIconStroke = Instance.new("UIStroke")
chestIconStroke.Color = Color3.fromRGB(180, 140, 30)
chestIconStroke.Thickness = 3
chestIconStroke.Parent = chestIcon

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 40)
titleLabel.Position = UDim2.new(0, 20, 0, 55)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "TREASURE CHEST"
titleLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.ZIndex = 52
titleLabel.Parent = mainFrame

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(100, 70, 0)
titleStroke.Thickness = 2
titleStroke.Parent = titleLabel

-- Golden separator line
local separator = Instance.new("Frame")
separator.Name = "Separator"
separator.Size = UDim2.new(0.8, 0, 0, 3)
separator.Position = UDim2.new(0.1, 0, 0, 100)
separator.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
separator.BorderSizePixel = 0
separator.ZIndex = 52
separator.Parent = mainFrame

local sepCorner = Instance.new("UICorner")
sepCorner.CornerRadius = UDim.new(0, 2)
sepCorner.Parent = separator

-- Reward (coins)
local rewardLabel = Instance.new("TextLabel")
rewardLabel.Name = "Reward"
rewardLabel.Size = UDim2.new(1, -40, 0, 50)
rewardLabel.Position = UDim2.new(0, 20, 0, 115)
rewardLabel.BackgroundTransparency = 1
rewardLabel.Text = "💰 10,000 Coins 💰"
rewardLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
rewardLabel.TextScaled = true
rewardLabel.Font = Enum.Font.FredokaOne
rewardLabel.ZIndex = 52
rewardLabel.Parent = mainFrame

local rewardStroke = Instance.new("UIStroke")
rewardStroke.Color = Color3.fromRGB(0, 80, 0)
rewardStroke.Thickness = 2
rewardStroke.Parent = rewardLabel

-- Description / status
local descLabel = Instance.new("TextLabel")
descLabel.Name = "Description"
descLabel.Size = UDim2.new(1, -40, 0, 40)
descLabel.Position = UDim2.new(0, 20, 0, 170)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Join the group to unlock this reward"
descLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
descLabel.TextScaled = true
descLabel.Font = Enum.Font.GothamBold
descLabel.TextWrapped = true
descLabel.ZIndex = 52
descLabel.Parent = mainFrame

-- Main action button
local actionButton = Instance.new("ImageButton")
actionButton.Name = "ActionButton"
actionButton.Size = UDim2.new(0.75, 0, 0, 55)
actionButton.Position = UDim2.new(0.125, 0, 0, 225)
actionButton.BackgroundTransparency = 1
actionButton.Image = TextureManager.Backgrounds.StudGray
actionButton.ImageColor3 = Color3.fromRGB(50, 200, 80)
actionButton.ImageTransparency = 0.1
actionButton.ScaleType = Enum.ScaleType.Tile
actionButton.TileSize = UDim2.new(0, 32, 0, 32)
actionButton.ZIndex = 52
actionButton.Parent = mainFrame

local actionCorner = Instance.new("UICorner")
actionCorner.CornerRadius = UDim.new(0, 12)
actionCorner.Parent = actionButton

local actionStroke = Instance.new("UIStroke")
actionStroke.Color = Color3.fromRGB(30, 130, 50)
actionStroke.Thickness = 2.5
actionStroke.Parent = actionButton

local actionText = Instance.new("TextLabel")
actionText.Name = "ButtonText"
actionText.Size = UDim2.new(1, 0, 1, 0)
actionText.BackgroundTransparency = 1
actionText.Text = "CLAIM REWARD"
actionText.TextColor3 = Color3.fromRGB(255, 255, 255)
actionText.TextScaled = true
actionText.Font = Enum.Font.FredokaOne
actionText.ZIndex = 53
actionText.Parent = actionButton

local actionTextStroke = Instance.new("UIStroke")
actionTextStroke.Color = Color3.fromRGB(20, 80, 30)
actionTextStroke.Thickness = 2
actionTextStroke.Parent = actionText

-- Close button
UIComponentsManager.createCloseButton(mainFrame, {
	onClose = function()
		if isUIOpen then
			closeUI()
		end
	end,
})

-- ============================================
-- ANIMATIONS AND UI LOGIC
-- ============================================

local function openUI()
	if isUIOpen then return end
	isUIOpen = true

	SoundManager.play("PopupOpen")

	overlay.Visible = true
	mainFrame.Visible = true

	-- Entry animation
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.5
	}):Play()

	local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 420, 0, 380),
		Position = UDim2.new(0.5, -210, 0.5, -190),
	})
	openTween:Play()
end

function closeUI()
	if not isUIOpen then return end
	isUIOpen = false

	SoundManager.play("PopupClose")

	TweenService:Create(overlay, TweenInfo.new(0.25), {
		BackgroundTransparency = 1
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

-- Close when tapping overlay
overlay.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		closeUI()
	end
end)

-- ============================================
-- UPDATE UI BASED ON STATUS
-- ============================================

local function updateUIState(status)
	if status.CanClaim then
		-- Can claim
		descLabel.Text = "You're in the group! Claim your reward"
		descLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		actionButton.ImageColor3 = Color3.fromRGB(50, 200, 80)
		actionStroke.Color = Color3.fromRGB(30, 130, 50)
		actionText.Text = "CLAIM 10,000 COINS"
		actionButton.Visible = true

	elseif status.Reason == "AlreadyClaimed" then
		-- Already claimed
		descLabel.Text = "You already claimed this reward!"
		descLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

		actionButton.ImageColor3 = Color3.fromRGB(80, 80, 80)
		actionStroke.Color = Color3.fromRGB(50, 50, 50)
		actionText.Text = "ALREADY CLAIMED ✓"
		actionButton.Visible = true
		hasClaimed = true

	elseif status.Reason == "NotInGroup" then
		-- Not in the group
		descLabel.Text = "You must join the group to unlock this reward"
		descLabel.TextColor3 = Color3.fromRGB(255, 150, 150)

		actionButton.ImageColor3 = Color3.fromRGB(80, 130, 255)
		actionStroke.Color = Color3.fromRGB(40, 70, 180)
		actionText.Text = "JOIN THE GROUP"
		actionButton.Visible = true

	else
		-- Error
		descLabel.Text = "Error verifying. Please try again later."
		descLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		actionButton.Visible = false
	end
end

-- ============================================
-- ACTION BUTTON HANDLER
-- ============================================

local isProcessing = false

actionButton.MouseButton1Click:Connect(function()
	if isProcessing or hasClaimed then return end

	-- Check current status
	local status = CheckTreasureStatus:InvokeServer()

	if status.Reason == "NotInGroup" then
		-- Show group notification
		SoundManager.play("ButtonClick")

		pcall(function()
			local StarterGui = game:GetService("StarterGui")
			StarterGui:SetCore("SendNotification", {
				Title = "Join the Group",
				Text = "Go to Roblox and search for group ID: " .. GROUP_ID,
				Duration = 8,
			})
		end)

		-- After joining, the player can close and interact again
		descLabel.Text = "Join the group and come back to the chest"
		descLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
		return
	end

	if status.Reason == "AlreadyClaimed" then
		updateUIState(status)
		return
	end

	if not status.CanClaim then
		updateUIState(status)
		return
	end

	-- Try to claim
	isProcessing = true
	actionText.Text = "PROCESSING..."
	actionButton.ImageColor3 = Color3.fromRGB(150, 150, 150)

	local success, message = ClaimTreasure:InvokeServer()

	if success then
		SoundManager.play("CashRegister")
		hasClaimed = true

		-- Success animation
		actionButton.ImageColor3 = Color3.fromRGB(255, 200, 50)
		actionStroke.Color = Color3.fromRGB(180, 140, 30)
		actionText.Text = "CLAIMED! ✓"
		descLabel.Text = "You received 10,000 coins!"
		descLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

		-- Celebration effect on reward text
		local popTween = TweenService:Create(rewardLabel, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextColor3 = Color3.fromRGB(255, 255, 100),
		})
		popTween:Play()
		task.wait(0.15)
		TweenService:Create(rewardLabel, TweenInfo.new(0.3), {
			TextColor3 = Color3.fromRGB(100, 255, 100),
		}):Play()

		-- Auto-close after 2 seconds
		task.wait(2)
		closeUI()
	else
		SoundManager.play("Error")
		actionText.Text = message or "Error"
		actionButton.ImageColor3 = Color3.fromRGB(200, 60, 60)

		task.wait(1.5)
		-- Restore
		local newStatus = CheckTreasureStatus:InvokeServer()
		updateUIState(newStatus)
	end

	isProcessing = false
end)

-- Hover effect
actionButton.MouseEnter:Connect(function()
	if hasClaimed or isProcessing then return end
	SoundManager.play("ButtonHover")
	TweenService:Create(actionButton, TweenInfo.new(0.15), {
		ImageTransparency = 0,
	}):Play()
	TweenService:Create(actionStroke, TweenInfo.new(0.15), {
		Thickness = 3.5,
	}):Play()
end)

actionButton.MouseLeave:Connect(function()
	TweenService:Create(actionButton, TweenInfo.new(0.15), {
		ImageTransparency = 0.1,
	}):Play()
	TweenService:Create(actionStroke, TweenInfo.new(0.15), {
		Thickness = 2.5,
	}):Play()
end)

-- ============================================
-- PROXIMITY DETECTION
-- ============================================

local isNear = false

local function getTreasurePosition()
	if not treasureModel then return nil end

	if treasureModel:IsA("Model") and treasureModel.PrimaryPart then
		return treasureModel.PrimaryPart.Position
	elseif treasureModel:IsA("Model") then
		return treasureModel:GetBoundingBox().Position
	elseif treasureModel:IsA("BasePart") then
		return treasureModel.Position
	end
	return nil
end

RunService.Heartbeat:Connect(function()
	if not treasureModel or not treasureModel.Parent then
		treasureModel = findTreasure()
		return
	end

	local character = player.Character
	if not character then return end

	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return end

	local treasurePos = getTreasurePosition()
	if not treasurePos then return end

	local distance = (humanoidRootPart.Position - treasurePos).Magnitude

	-- Attach billboard to the model if not already attached
	if not proximityBillboard.Parent or proximityBillboard.Parent ~= treasureModel then
		if treasureModel:IsA("Model") then
			proximityBillboard.Adornee = treasureModel.PrimaryPart or treasureModel:FindFirstChildWhichIsA("BasePart")
		else
			proximityBillboard.Adornee = treasureModel
		end
		proximityBillboard.Parent = treasureModel
	end

	if distance <= PROXIMITY_DISTANCE then
		-- Show indicator
		if not hasClaimed then
			proximityBillboard.Enabled = true
		end

		if not isNear then
			isNear = true
			-- Auto-open UI when approaching
			if not isUIOpen and not hasClaimed then
				-- Query status from server
				task.spawn(function()
					local status = CheckTreasureStatus:InvokeServer()
					if status.Reason == "AlreadyClaimed" then
						hasClaimed = true
						proximityBillboard.Enabled = false
						return
					end
					updateUIState(status)
					openUI()
				end)
			end
		end
	else
		proximityBillboard.Enabled = false
		if isNear then
			isNear = false
			if isUIOpen then
				closeUI()
			end
		end
	end
end)

-- ============================================
-- CHECK INITIAL STATUS
-- ============================================
task.spawn(function()
	task.wait(3) -- Wait for data to load
	local status = CheckTreasureStatus:InvokeServer()
	if status and status.Reason == "AlreadyClaimed" then
		hasClaimed = true
	end
end)

print("[TreasureChestUI] Treasure chest UI initialized")
