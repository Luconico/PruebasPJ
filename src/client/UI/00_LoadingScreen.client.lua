--[[
	LoadingScreen.client.lua
	Pantalla de carga al iniciar el juego
	Se muestra hasta que todo esté cargado y luego hace fade out
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- CONFIGURACIÓN
-- ============================================

local Config = {
	-- Colores (estilo cartoon del juego)
	BackgroundColor = Color3.fromRGB(25, 25, 40),
	AccentColor = Color3.fromRGB(255, 200, 50),
	ProgressBarBg = Color3.fromRGB(60, 60, 80),
	ProgressBarFill = Color3.fromRGB(100, 220, 120),
	TextColor = Color3.fromRGB(255, 255, 255),

	-- Tiempos
	MinimumLoadTime = 2, -- Tiempo mínimo de carga (segundos)
	FadeOutTime = 0.8, -- Duración del fade out

	-- Texto
	GameTitle = "🚀 FART SIMULATOR 🚀",
	LoadingTexts = {
		"Cargando el universo...",
		"Preparando pedos cósmicos...",
		"Inflando personajes...",
		"Calentando motores...",
		"Casi listo...",
	},
}

-- ============================================
-- CREAR UI
-- ============================================

local function createLoadingScreen()
	-- ScreenGui principal
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LoadingScreen"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true
	screenGui.DisplayOrder = 999 -- Por encima de todo
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Fondo que cubre toda la pantalla
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Position = UDim2.new(0, 0, 0, 0)
	background.BackgroundColor3 = Config.BackgroundColor
	background.BorderSizePixel = 0
	background.Parent = screenGui

	-- Gradiente de fondo
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 55)),
		ColorSequenceKeypoint.new(0.5, Config.BackgroundColor),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 35)),
	})
	gradient.Rotation = 45
	gradient.Parent = background

	-- Contenedor central
	local centerContainer = Instance.new("Frame")
	centerContainer.Name = "CenterContainer"
	centerContainer.Size = UDim2.new(0.8, 0, 0.5, 0)
	centerContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	centerContainer.BackgroundTransparency = 1
	centerContainer.Parent = background

	-- Título del juego
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 80)
	title.Position = UDim2.new(0.5, 0, 0.3, 0)
	title.AnchorPoint = Vector2.new(0.5, 0.5)
	title.BackgroundTransparency = 1
	title.Text = Config.GameTitle
	title.TextColor3 = Config.AccentColor
	title.TextSize = 48
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.Parent = centerContainer

	local titleConstraint = Instance.new("UITextSizeConstraint")
	titleConstraint.MaxTextSize = 72
	titleConstraint.MinTextSize = 24
	titleConstraint.Parent = title

	-- Stroke del título
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 3
	titleStroke.Parent = title

	-- Icono animado (emoji grande)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, 120, 0, 120)
	iconLabel.Position = UDim2.new(0.5, 0, 0.55, 0)
	iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = "💨"
	iconLabel.TextSize = 80
	iconLabel.Parent = centerContainer

	-- Texto de carga
	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.Size = UDim2.new(1, 0, 0, 40)
	loadingText.Position = UDim2.new(0.5, 0, 0.75, 0)
	loadingText.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingText.BackgroundTransparency = 1
	loadingText.Text = Config.LoadingTexts[1]
	loadingText.TextColor3 = Config.TextColor
	loadingText.TextSize = 24
	loadingText.Font = Enum.Font.GothamMedium
	loadingText.TextScaled = true
	loadingText.Parent = centerContainer

	local loadingTextConstraint = Instance.new("UITextSizeConstraint")
	loadingTextConstraint.MaxTextSize = 28
	loadingTextConstraint.MinTextSize = 14
	loadingTextConstraint.Parent = loadingText

	-- Contenedor de la barra de progreso
	local progressContainer = Instance.new("Frame")
	progressContainer.Name = "ProgressContainer"
	progressContainer.Size = UDim2.new(0.6, 0, 0, 24)
	progressContainer.Position = UDim2.new(0.5, 0, 0.85, 0)
	progressContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	progressContainer.BackgroundColor3 = Config.ProgressBarBg
	progressContainer.Parent = centerContainer

	local progressCorner = Instance.new("UICorner")
	progressCorner.CornerRadius = UDim.new(0, 12)
	progressCorner.Parent = progressContainer

	local progressStroke = Instance.new("UIStroke")
	progressStroke.Color = Color3.fromRGB(80, 80, 100)
	progressStroke.Thickness = 2
	progressStroke.Parent = progressContainer

	-- Barra de progreso (fill)
	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(0, 0, 1, 0)
	progressFill.Position = UDim2.new(0, 0, 0, 0)
	progressFill.BackgroundColor3 = Config.ProgressBarFill
	progressFill.Parent = progressContainer

	local progressFillCorner = Instance.new("UICorner")
	progressFillCorner.CornerRadius = UDim.new(0, 12)
	progressFillCorner.Parent = progressFill

	-- Gradiente para la barra de progreso
	local progressGradient = Instance.new("UIGradient")
	progressGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 220, 120)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 180, 80)),
	})
	progressGradient.Rotation = 90
	progressGradient.Parent = progressFill

	-- Porcentaje
	local percentText = Instance.new("TextLabel")
	percentText.Name = "PercentText"
	percentText.Size = UDim2.new(1, 0, 0, 30)
	percentText.Position = UDim2.new(0.5, 0, 0.92, 0)
	percentText.AnchorPoint = Vector2.new(0.5, 0.5)
	percentText.BackgroundTransparency = 1
	percentText.Text = "0%"
	percentText.TextColor3 = Config.TextColor
	percentText.TextSize = 18
	percentText.Font = Enum.Font.GothamBold
	percentText.Parent = centerContainer

	return {
		ScreenGui = screenGui,
		Background = background,
		Title = title,
		Icon = iconLabel,
		LoadingText = loadingText,
		ProgressFill = progressFill,
		PercentText = percentText,
	}
end

-- ============================================
-- ANIMACIONES
-- ============================================

local function animateIcon(iconLabel)
	-- Animación de rotación/escala del icono
	local rotation = 0
	local scaleDirection = 1
	local scale = 1

	local connection
	connection = RunService.RenderStepped:Connect(function(dt)
		if not iconLabel or not iconLabel.Parent then
			connection:Disconnect()
			return
		end

		rotation = rotation + dt * 60
		scale = scale + dt * scaleDirection * 0.3

		if scale > 1.15 then
			scaleDirection = -1
		elseif scale < 0.9 then
			scaleDirection = 1
		end

		iconLabel.Rotation = math.sin(math.rad(rotation)) * 15
		iconLabel.Size = UDim2.new(0, 120 * scale, 0, 120 * scale)
	end)

	return connection
end

local function cycleLoadingText(loadingText)
	local index = 1
	local connection

	connection = task.spawn(function()
		while loadingText and loadingText.Parent do
			task.wait(0.8)
			index = index % #Config.LoadingTexts + 1
			if loadingText and loadingText.Parent then
				loadingText.Text = Config.LoadingTexts[index]
			end
		end
	end)

	return connection
end

-- ============================================
-- PROCESO DE CARGA
-- ============================================

local function preloadAssets()
	-- Obtener assets para precargar
	local assetsToPreload = {}

	-- Agregar todos los Decals, Textures, Sounds del juego
	for _, descendant in ipairs(game:GetDescendants()) do
		if descendant:IsA("Decal") or descendant:IsA("Texture") or descendant:IsA("Sound") then
			table.insert(assetsToPreload, descendant)
		end
	end

	return assetsToPreload
end

local function loadGame(ui)
	local startTime = tick()
	local assetsToPreload = preloadAssets()
	local totalAssets = math.max(#assetsToPreload, 1)
	local loadedAssets = 0

	-- Función para actualizar progreso
	local function updateProgress(progress)
		local percent = math.floor(progress * 100)
		ui.PercentText.Text = percent .. "%"

		TweenService:Create(ui.ProgressFill, TweenInfo.new(0.2), {
			Size = UDim2.new(progress, 0, 1, 0)
		}):Play()
	end

	-- Precargar assets
	if #assetsToPreload > 0 then
		ContentProvider:PreloadAsync(assetsToPreload, function(assetId, status)
			loadedAssets = loadedAssets + 1
			local progress = loadedAssets / totalAssets * 0.7 -- 70% para assets
			updateProgress(progress)
		end)
	else
		updateProgress(0.7)
	end

	-- Esperar al personaje del jugador
	updateProgress(0.8)

	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart", 10)

	updateProgress(0.9)

	-- Esperar a que Shared y Remotes estén listos
	ReplicatedStorage:WaitForChild("Shared", 10)
	ReplicatedStorage:WaitForChild("Remotes", 10)

	updateProgress(1)

	-- Asegurar tiempo mínimo de carga
	local elapsedTime = tick() - startTime
	if elapsedTime < Config.MinimumLoadTime then
		task.wait(Config.MinimumLoadTime - elapsedTime)
	end
end

-- ============================================
-- FADE OUT
-- ============================================

local function fadeOut(ui)
	-- Tween de fade out para el fondo
	local fadeOutTween = TweenService:Create(
		ui.Background,
		TweenInfo.new(Config.FadeOutTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 1 }
	)

	-- Hacer fade de todos los elementos de texto
	local textElements = {ui.Title, ui.LoadingText, ui.PercentText, ui.Icon}
	for _, element in ipairs(textElements) do
		TweenService:Create(element, TweenInfo.new(Config.FadeOutTime), {
			TextTransparency = 1
		}):Play()
	end

	-- Fade del progress bar
	TweenService:Create(ui.ProgressFill, TweenInfo.new(Config.FadeOutTime), {
		BackgroundTransparency = 1
	}):Play()

	TweenService:Create(ui.ProgressFill.Parent, TweenInfo.new(Config.FadeOutTime), {
		BackgroundTransparency = 1
	}):Play()

	-- Fade del stroke del progress bar
	local progressStroke = ui.ProgressFill.Parent:FindFirstChildOfClass("UIStroke")
	if progressStroke then
		TweenService:Create(progressStroke, TweenInfo.new(Config.FadeOutTime), {
			Transparency = 1
		}):Play()
	end

	-- Fade del stroke del título
	local titleStroke = ui.Title:FindFirstChildOfClass("UIStroke")
	if titleStroke then
		TweenService:Create(titleStroke, TweenInfo.new(Config.FadeOutTime), {
			Transparency = 1
		}):Play()
	end

	fadeOutTween:Play()
	fadeOutTween.Completed:Wait()

	-- Destruir la UI
	ui.ScreenGui:Destroy()
end

-- ============================================
-- INICIAR
-- ============================================

local ui = createLoadingScreen()

-- Iniciar animaciones
local iconAnimation = animateIcon(ui.Icon)
cycleLoadingText(ui.LoadingText)

-- Cargar el juego
loadGame(ui)

-- Detener animación del icono
if iconAnimation then
	iconAnimation:Disconnect()
end

-- Hacer fade out
fadeOut(ui)

print("[LoadingScreen] Carga completada")
