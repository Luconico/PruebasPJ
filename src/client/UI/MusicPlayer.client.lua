--[[
	MusicPlayer.client.lua
	Small bottom-right UI widget for music controls
	- Mute/Unmute all sounds
	- Play/Pause background music
	- Next track (loops playlist)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))

-- ============================================
-- CONFIG
-- ============================================

local BUTTON_SIZE = ResponsiveUI.scale(38)
local BUTTON_SPACING = ResponsiveUI.scale(6)
local CONTAINER_PADDING = ResponsiveUI.scale(8)
local CORNER_RADIUS = ResponsiveUI.scale(14)
local MARGIN = ResponsiveUI.scale(12)
local EMOJI_SIZE = ResponsiveUI.scaleText(22)

local Colors = {
	ContainerBg = Color3.fromRGB(30, 30, 50),
	Stroke = Color3.fromRGB(60, 60, 90),
	ButtonBg = Color3.fromRGB(50, 50, 75),
	ButtonHover = Color3.fromRGB(70, 70, 100),
	MuteActive = Color3.fromRGB(200, 60, 60),
	Text = Color3.fromRGB(255, 255, 255),
}

-- ============================================
-- CREATE UI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MusicPlayer"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Container
local totalButtons = 3
local containerWidth = (BUTTON_SIZE * totalButtons) + (BUTTON_SPACING * (totalButtons - 1)) + (CONTAINER_PADDING * 2)
local containerHeight = BUTTON_SIZE + (CONTAINER_PADDING * 2)

local container = Instance.new("Frame")
container.Name = "MusicControls"
container.Size = UDim2.new(0, containerWidth, 0, containerHeight)
container.Position = UDim2.new(1, -(MARGIN), 1, -(MARGIN))
container.AnchorPoint = Vector2.new(1, 1)
container.BackgroundColor3 = Colors.ContainerBg
container.BackgroundTransparency = 0.15
container.Parent = screenGui

local containerCorner = Instance.new("UICorner")
containerCorner.CornerRadius = UDim.new(0, CORNER_RADIUS)
containerCorner.Parent = container

local containerStroke = Instance.new("UIStroke")
containerStroke.Color = Colors.Stroke
containerStroke.Thickness = 2
containerStroke.Transparency = 0.3
containerStroke.Parent = container

-- ============================================
-- BUTTON FACTORY
-- ============================================

local function createControlButton(name, emoji, positionIndex)
	local xOffset = CONTAINER_PADDING + (positionIndex - 1) * (BUTTON_SIZE + BUTTON_SPACING)

	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
	btn.Position = UDim2.new(0, xOffset, 0.5, 0)
	btn.AnchorPoint = Vector2.new(0, 0.5)
	btn.BackgroundColor3 = Colors.ButtonBg
	btn.Text = emoji
	btn.TextSize = EMOJI_SIZE
	btn.Font = Enum.Font.GothamBold
	btn.TextColor3 = Colors.Text
	btn.AutoButtonColor = false
	btn.Parent = container

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, ResponsiveUI.scale(10))
	btnCorner.Parent = btn

	-- Hover
	btn.MouseEnter:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Colors.ButtonHover,
			Size = UDim2.new(0, BUTTON_SIZE * 1.08, 0, BUTTON_SIZE * 1.08)
		}):Play()
	end)

	btn.MouseLeave:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.15), {
			BackgroundColor3 = Colors.ButtonBg,
			Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		}):Play()
	end)

	-- Click press effect
	btn.MouseButton1Down:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {
			Size = UDim2.new(0, BUTTON_SIZE * 0.92, 0, BUTTON_SIZE * 0.92)
		}):Play()
	end)

	btn.MouseButton1Up:Connect(function()
		TweenService:Create(btn, TweenInfo.new(0.08), {
			Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
		}):Play()
	end)

	return btn
end

-- ============================================
-- CREATE BUTTONS
-- ============================================

local muteBtn = createControlButton("MuteButton", "\xF0\x9F\x94\x8A", 1) -- speaker emoji
local playPauseBtn = createControlButton("PlayPauseButton", "\xE2\x96\xB6", 2) -- play emoji
local nextBtn = createControlButton("NextButton", "\xE2\x8F\xAD", 3) -- next emoji

-- ============================================
-- BUTTON LOGIC
-- ============================================

-- Update button visuals based on state
local function updateMuteButton()
	if SoundManager.Muted then
		muteBtn.Text = "\xF0\x9F\x94\x87" -- muted speaker
		muteBtn.BackgroundColor3 = Colors.MuteActive
	else
		muteBtn.Text = "\xF0\x9F\x94\x8A" -- speaker with sound
		muteBtn.BackgroundColor3 = Colors.ButtonBg
	end
end

local function updatePlayPauseButton()
	if SoundManager.MusicPlaying then
		playPauseBtn.Text = "\xE2\x8F\xB8" -- pause
	else
		playPauseBtn.Text = "\xE2\x96\xB6" -- play
	end
end

-- Mute/Unmute
muteBtn.MouseButton1Click:Connect(function()
	SoundManager.toggleMute()
	updateMuteButton()
	updatePlayPauseButton()
end)

-- Play/Pause
playPauseBtn.MouseButton1Click:Connect(function()
	SoundManager.playClick()

	if SoundManager.MusicPlaying then
		SoundManager.pauseMusic()
	else
		if SoundManager.MusicInstance and SoundManager.MusicInstance.TimePosition > 0 then
			SoundManager.resumeMusic()
		else
			SoundManager.playMusic()
		end
	end
	updatePlayPauseButton()
end)

-- Next Track
nextBtn.MouseButton1Click:Connect(function()
	SoundManager.playClick()
	SoundManager.nextTrack()
	updatePlayPauseButton()
end)

-- ============================================
-- AUTO-START MUSIC
-- ============================================

task.defer(function()
	if #SoundManager.Playlist > 0 then
		SoundManager.playMusic()
		updatePlayPauseButton()
	end
end)

print("[MusicPlayer] UI initialized")
