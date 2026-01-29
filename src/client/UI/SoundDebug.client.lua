--[[
	SoundDebug.client.lua
	UI de depuración para probar todos los sonidos del juego
	Presiona L para abrir/cerrar
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cargar SoundManager
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundManager = require(Shared:WaitForChild("SoundManager"))

-- Variables
local debugUI = nil
local isOpen = false

-- ============================================
-- CREAR UI DE DEBUG
-- ============================================

local function createDebugUI()
	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SoundDebugUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Fondo oscuro
	local backdrop = Instance.new("Frame")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.new(1, 0, 1, 0)
	backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	backdrop.BackgroundTransparency = 0.5
	backdrop.BorderSizePixel = 0
	backdrop.Parent = screenGui

	-- Panel principal
	local mainPanel = Instance.new("Frame")
	mainPanel.Name = "MainPanel"
	mainPanel.Size = UDim2.new(0, 500, 0, 600)
	mainPanel.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainPanel.AnchorPoint = Vector2.new(0.5, 0.5)
	mainPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainPanel.BorderSizePixel = 0
	mainPanel.Parent = backdrop

	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 12)
	panelCorner.Parent = mainPanel

	-- Borde brillante
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 150, 255)
	stroke.Thickness = 2
	stroke.Parent = mainPanel

	-- Título
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -60, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "🔊 Sound Debug Panel"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = mainPanel

	-- Botón cerrar
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 20
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainPanel

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	closeButton.MouseButton1Click:Connect(function()
		toggleDebugUI(false)
	end)

	-- Subtítulo
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -40, 0, 25)
	subtitle.Position = UDim2.new(0, 20, 0, 55)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Presiona L para cerrar | Click en ▶ para reproducir"
	subtitle.TextColor3 = Color3.fromRGB(150, 150, 150)
	subtitle.TextSize = 14
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.Parent = mainPanel

	-- Scroll frame para los sonidos
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "SoundsList"
	scrollFrame.Size = UDim2.new(1, -30, 1, -100)
	scrollFrame.Position = UDim2.new(0, 15, 0, 90)
	scrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 8
	scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 150, 255)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.Parent = mainPanel

	local scrollCorner = Instance.new("UICorner")
	scrollCorner.CornerRadius = UDim.new(0, 8)
	scrollCorner.Parent = scrollFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.Name
	listLayout.Padding = UDim.new(0, 5)
	listLayout.Parent = scrollFrame

	local listPadding = Instance.new("UIPadding")
	listPadding.PaddingTop = UDim.new(0, 10)
	listPadding.PaddingBottom = UDim.new(0, 10)
	listPadding.PaddingLeft = UDim.new(0, 10)
	listPadding.PaddingRight = UDim.new(0, 10)
	listPadding.Parent = scrollFrame

	-- Crear entrada para cada sonido
	local function createSoundEntry(soundName, soundId)
		local entry = Instance.new("Frame")
		entry.Name = soundName
		entry.Size = UDim2.new(1, -20, 0, 50)
		entry.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		entry.BorderSizePixel = 0
		entry.Parent = scrollFrame

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 8)
		entryCorner.Parent = entry

		-- Nombre del sonido
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.4, -10, 1, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = soundName
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextSize = 16
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entry

		-- ID del sonido (truncado)
		local idLabel = Instance.new("TextLabel")
		idLabel.Name = "ID"
		idLabel.Size = UDim2.new(0.35, 0, 1, 0)
		idLabel.Position = UDim2.new(0.4, 0, 0, 0)
		idLabel.BackgroundTransparency = 1
		idLabel.Text = soundId
		idLabel.TextColor3 = Color3.fromRGB(120, 120, 140)
		idLabel.TextSize = 11
		idLabel.Font = Enum.Font.Code
		idLabel.TextXAlignment = Enum.TextXAlignment.Left
		idLabel.TextTruncate = Enum.TextTruncate.AtEnd
		idLabel.Parent = entry

		-- Botón play
		local playButton = Instance.new("TextButton")
		playButton.Name = "PlayButton"
		playButton.Size = UDim2.new(0, 60, 0, 35)
		playButton.Position = UDim2.new(1, -70, 0.5, 0)
		playButton.AnchorPoint = Vector2.new(0, 0.5)
		playButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
		playButton.BorderSizePixel = 0
		playButton.Text = "▶"
		playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		playButton.TextSize = 20
		playButton.Font = Enum.Font.GothamBold
		playButton.Parent = entry

		local playCorner = Instance.new("UICorner")
		playCorner.CornerRadius = UDim.new(0, 6)
		playCorner.Parent = playButton

		-- Animación y sonido al hacer click
		playButton.MouseButton1Click:Connect(function()
			-- Feedback visual
			local originalColor = playButton.BackgroundColor3
			playButton.BackgroundColor3 = Color3.fromRGB(100, 220, 100)
			playButton.Text = "🔊"

			-- Reproducir sonido
			SoundManager.play(soundName, 0.6, 1.0)

			-- Restaurar después de un momento
			task.delay(0.3, function()
				playButton.BackgroundColor3 = originalColor
				playButton.Text = "▶"
			end)
		end)

		-- Hover effect
		playButton.MouseEnter:Connect(function()
			TweenService:Create(playButton, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(100, 200, 100)
			}):Play()
		end)

		playButton.MouseLeave:Connect(function()
			TweenService:Create(playButton, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(80, 180, 80)
			}):Play()
		end)

		return entry
	end

	-- Sección: Sonidos básicos
	local sectionBasic = Instance.new("TextLabel")
	sectionBasic.Name = "00_SectionBasic"
	sectionBasic.Size = UDim2.new(1, -20, 0, 30)
	sectionBasic.BackgroundTransparency = 1
	sectionBasic.Text = "── SONIDOS BÁSICOS ──"
	sectionBasic.TextColor3 = Color3.fromRGB(100, 150, 255)
	sectionBasic.TextSize = 14
	sectionBasic.Font = Enum.Font.GothamBold
	sectionBasic.Parent = scrollFrame

	-- Agregar todos los sonidos del SoundManager
	for soundName, soundId in pairs(SoundManager.Sounds) do
		-- Solo mostrar los sonidos principales, no alias
		if type(soundId) == "string" and soundId:match("^rbxassetid://") then
			createSoundEntry(soundName, soundId)
		end
	end

	-- Sección: Funciones de conveniencia
	local sectionFunctions = Instance.new("TextLabel")
	sectionFunctions.Name = "zz_SectionFunctions"
	sectionFunctions.Size = UDim2.new(1, -20, 0, 30)
	sectionFunctions.BackgroundTransparency = 1
	sectionFunctions.Text = "── FUNCIONES ESPECIALES ──"
	sectionFunctions.TextColor3 = Color3.fromRGB(255, 180, 100)
	sectionFunctions.TextSize = 14
	sectionFunctions.Font = Enum.Font.GothamBold
	sectionFunctions.Parent = scrollFrame

	-- Funciones especiales
	local specialFunctions = {
		{ name = "playHover()", func = SoundManager.playHover, desc = "Hover de botón" },
		{ name = "playClick()", func = SoundManager.playClick, desc = "Click de botón" },
		{ name = "playOpen()", func = SoundManager.playOpen, desc = "Abrir popup" },
		{ name = "playClose()", func = SoundManager.playClose, desc = "Cerrar popup" },
		{ name = "playError()", func = SoundManager.playError, desc = "Error" },
		{ name = "playCelebration()", func = SoundManager.playCelebration, desc = "Celebración compra" },
		{ name = "playPurchase()", func = SoundManager.playPurchase, desc = "Compra rápida" },
		{ name = "playEquip()", func = SoundManager.playEquip, desc = "Equipar item" },
		{ name = "playReward('common')", func = function() SoundManager.playReward("common") end, desc = "Recompensa común" },
		{ name = "playReward('rare')", func = function() SoundManager.playReward("rare") end, desc = "Recompensa rara" },
		{ name = "playReward('epic')", func = function() SoundManager.playReward("epic") end, desc = "Recompensa épica" },
		{ name = "playReward('legendary')", func = function() SoundManager.playReward("legendary") end, desc = "Recompensa legendaria" },
		{ name = "playReward('mythic')", func = function() SoundManager.playReward("mythic") end, desc = "Recompensa mítica" },
		{ name = "playWin(false)", func = function() SoundManager.playWin(false) end, desc = "Victoria pequeña" },
		{ name = "playWin(true)", func = function() SoundManager.playWin(true) end, desc = "Victoria grande" },
	}

	for i, funcData in ipairs(specialFunctions) do
		local entry = Instance.new("Frame")
		entry.Name = "zz_Func_" .. string.format("%02d", i)
		entry.Size = UDim2.new(1, -20, 0, 50)
		entry.BackgroundColor3 = Color3.fromRGB(50, 40, 55)
		entry.BorderSizePixel = 0
		entry.Parent = scrollFrame

		local entryCorner = Instance.new("UICorner")
		entryCorner.CornerRadius = UDim.new(0, 8)
		entryCorner.Parent = entry

		-- Nombre de la función
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(0.5, -10, 0.5, 0)
		nameLabel.Position = UDim2.new(0, 10, 0, 2)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = funcData.name
		nameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
		nameLabel.TextSize = 14
		nameLabel.Font = Enum.Font.Code
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = entry

		-- Descripción
		local descLabel = Instance.new("TextLabel")
		descLabel.Name = "Desc"
		descLabel.Size = UDim2.new(0.6, 0, 0.5, 0)
		descLabel.Position = UDim2.new(0, 10, 0.5, -2)
		descLabel.BackgroundTransparency = 1
		descLabel.Text = funcData.desc
		descLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
		descLabel.TextSize = 12
		descLabel.Font = Enum.Font.Gotham
		descLabel.TextXAlignment = Enum.TextXAlignment.Left
		descLabel.Parent = entry

		-- Botón play
		local playButton = Instance.new("TextButton")
		playButton.Name = "PlayButton"
		playButton.Size = UDim2.new(0, 60, 0, 35)
		playButton.Position = UDim2.new(1, -70, 0.5, 0)
		playButton.AnchorPoint = Vector2.new(0, 0.5)
		playButton.BackgroundColor3 = Color3.fromRGB(180, 120, 60)
		playButton.BorderSizePixel = 0
		playButton.Text = "▶"
		playButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		playButton.TextSize = 20
		playButton.Font = Enum.Font.GothamBold
		playButton.Parent = entry

		local playCorner = Instance.new("UICorner")
		playCorner.CornerRadius = UDim.new(0, 6)
		playCorner.Parent = playButton

		playButton.MouseButton1Click:Connect(function()
			local originalColor = playButton.BackgroundColor3
			playButton.BackgroundColor3 = Color3.fromRGB(220, 160, 80)
			playButton.Text = "🔊"

			funcData.func()

			task.delay(0.5, function()
				playButton.BackgroundColor3 = originalColor
				playButton.Text = "▶"
			end)
		end)

		playButton.MouseEnter:Connect(function()
			TweenService:Create(playButton, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(200, 140, 80)
			}):Play()
		end)

		playButton.MouseLeave:Connect(function()
			TweenService:Create(playButton, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(180, 120, 60)
			}):Play()
		end)
	end

	-- Actualizar canvas size
	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)
	end)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 20)

	-- Click en backdrop cierra
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local mousePos = UserInputService:GetMouseLocation()
			local panelPos = mainPanel.AbsolutePosition
			local panelSize = mainPanel.AbsoluteSize

			-- Solo cerrar si el click fue fuera del panel
			if mousePos.X < panelPos.X or mousePos.X > panelPos.X + panelSize.X or
				mousePos.Y < panelPos.Y or mousePos.Y > panelPos.Y + panelSize.Y then
				toggleDebugUI(false)
			end
		end
	end)

	return screenGui
end

-- ============================================
-- TOGGLE UI
-- ============================================

function toggleDebugUI(open)
	if open == nil then
		open = not isOpen
	end

	if not debugUI then
		debugUI = createDebugUI()
	end

	isOpen = open
	debugUI.Enabled = isOpen

	if isOpen then
		-- Animación de entrada
		local mainPanel = debugUI:FindFirstChild("Backdrop"):FindFirstChild("MainPanel")
		if mainPanel then
			mainPanel.Size = UDim2.new(0, 0, 0, 0)
			TweenService:Create(mainPanel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 500, 0, 600)
			}):Play()
		end
		SoundManager.playOpen()
	else
		SoundManager.playClose()
	end
end

-- ============================================
-- INPUT
-- ============================================

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.L then
		toggleDebugUI()
	end
end)

print("[SoundDebug] Presiona 'L' para abrir el panel de debug de sonidos")
