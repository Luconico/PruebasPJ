--[[
	HeightLeaderboard.client.lua
	Barra vertical de altura con posiciones de todos los jugadores en tiempo real
	Estilo: Barra arcoíris con "SPACE" arriba y avatares de jugadores
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar módulos
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))

-- ============================================
-- CONFIGURACIÓN
-- ============================================

local MAX_HEIGHT = 5000 -- 5km = SPACE
local UPDATE_INTERVAL = 0.1 -- Actualizar cada 100ms
local AVATAR_SIZE = 50 -- Tamaño del avatar circular (más grande que la barra)
local BAR_WIDTH = 32 -- Ancho de la barra arcoíris (estrecha para que avatar sobresalga)
local BAR_MARGIN = 20 -- Margen desde el borde derecho
local TOP_MARGIN = 130 -- Margen superior para no pisar otros elementos de UI

-- Colores del arcoíris (de abajo hacia arriba)
local RAINBOW_COLORS = {
	Color3.fromRGB(255, 0, 255),    -- Magenta/Rosa (abajo)
	Color3.fromRGB(128, 0, 255),    -- Violeta
	Color3.fromRGB(0, 0, 255),      -- Azul
	Color3.fromRGB(0, 255, 255),    -- Cyan
	Color3.fromRGB(0, 255, 0),      -- Verde
	Color3.fromRGB(255, 255, 0),    -- Amarillo
	Color3.fromRGB(255, 128, 0),    -- Naranja
	Color3.fromRGB(255, 0, 0),      -- Rojo (arriba)
}

-- ============================================
-- TAMAÑOS RESPONSIVE
-- ============================================

local function getResponsiveSizes()
	local info = ResponsiveUI.getViewportInfo()
	local isMobile = info.IsMobile

	return {
		BarWidth = isMobile and 26 or BAR_WIDTH,
		BarMargin = isMobile and 12 or BAR_MARGIN,
		BarHeight = isMobile and 0.55 or 0.6, -- Porcentaje de la pantalla (más corta)
		TopMargin = isMobile and 100 or TOP_MARGIN, -- Margen superior
		AvatarSize = isMobile and 40 or AVATAR_SIZE,
		SpaceLabelHeight = isMobile and 45 or 55,
		SpaceIconSize = isMobile and 28 or 36,
		SpaceTextSize = isMobile and 12 or 14,
		IsMobile = isMobile,
	}
end

local sizes = getResponsiveSizes()

-- ============================================
-- ESTADO
-- ============================================

local playerIndicators = {} -- {[Player] = {Frame, Avatar, ...}}
local mainContainer = nil
local rainbowBar = nil
local baseHeight = 0 -- Altura base del mundo

-- ============================================
-- CREAR UI
-- ============================================

local function createLeaderboardUI()
	-- ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HeightLeaderboard"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Contenedor principal (barra + etiqueta SPACE)
	-- Posicionado en el lado derecho de la pantalla, debajo de la UI superior
	mainContainer = Instance.new("Frame")
	mainContainer.Name = "MainContainer"
	mainContainer.Size = UDim2.new(0, sizes.AvatarSize + 10, sizes.BarHeight, sizes.SpaceLabelHeight)
	mainContainer.Position = UDim2.new(1, -sizes.BarMargin, 0, sizes.TopMargin)
	mainContainer.AnchorPoint = Vector2.new(1, 0)
	mainContainer.BackgroundTransparency = 1
	mainContainer.Parent = screenGui

	-- ============================================
	-- BARRA ARCOÍRIS (primero para que quede detrás)
	-- ============================================

	rainbowBar = Instance.new("Frame")
	rainbowBar.Name = "RainbowBar"
	rainbowBar.Size = UDim2.new(0, sizes.BarWidth, 1, -10)
	rainbowBar.Position = UDim2.new(0.5, 0, 0, 5)
	rainbowBar.AnchorPoint = Vector2.new(0.5, 0)
	rainbowBar.BackgroundColor3 = Color3.new(1, 1, 1)
	rainbowBar.BorderSizePixel = 0
	rainbowBar.ZIndex = 1
	rainbowBar.Parent = mainContainer

	-- ============================================
	-- ETIQUETA "SPACE" SUPERPUESTA EN LA PARTE SUPERIOR
	-- ============================================

	local spaceContainer = Instance.new("Frame")
	spaceContainer.Name = "SpaceContainer"
	spaceContainer.Size = UDim2.new(1, 0, 0, sizes.SpaceLabelHeight)
	spaceContainer.Position = UDim2.new(0.5, 0, 0, 0)
	spaceContainer.AnchorPoint = Vector2.new(0.5, 0)
	spaceContainer.BackgroundTransparency = 1
	spaceContainer.ZIndex = 5
	spaceContainer.Parent = mainContainer

	-- Icono de planeta/saturno (naranja/dorado como en la imagen)
	local spaceIcon = Instance.new("TextLabel")
	spaceIcon.Name = "SpaceIcon"
	spaceIcon.Size = UDim2.new(0, sizes.SpaceIconSize, 0, sizes.SpaceIconSize)
	spaceIcon.Position = UDim2.new(0.5, 0, 0, 0)
	spaceIcon.AnchorPoint = Vector2.new(0.5, 0)
	spaceIcon.BackgroundTransparency = 1
	spaceIcon.Text = "🪐"
	spaceIcon.TextSize = sizes.SpaceIconSize
	spaceIcon.ZIndex = 5
	spaceIcon.Parent = spaceContainer

	-- Texto "SPACE" con fondo naranja/rojo
	local spaceLabel = Instance.new("TextLabel")
	spaceLabel.Name = "SpaceLabel"
	spaceLabel.Size = UDim2.new(0, sizes.AvatarSize + 6, 0, 18)
	spaceLabel.Position = UDim2.new(0.5, 0, 0, sizes.SpaceIconSize - 2)
	spaceLabel.AnchorPoint = Vector2.new(0.5, 0)
	spaceLabel.BackgroundColor3 = Color3.fromRGB(255, 80, 30)
	spaceLabel.Text = "SPACE"
	spaceLabel.TextColor3 = Color3.new(1, 1, 1)
	spaceLabel.TextSize = sizes.SpaceTextSize
	spaceLabel.Font = Enum.Font.GothamBlack
	spaceLabel.ZIndex = 5
	spaceLabel.Parent = spaceContainer

	local spaceLabelCorner = Instance.new("UICorner")
	spaceLabelCorner.CornerRadius = UDim.new(0, 5)
	spaceLabelCorner.Parent = spaceLabel

	-- Esquinas redondeadas (muy redondeadas para aspecto de píldora)
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0.5, 0) -- Totalmente redondeado
	barCorner.Parent = rainbowBar

	-- Borde negro grueso
	local barStroke = Instance.new("UIStroke")
	barStroke.Color = Color3.new(0, 0, 0)
	barStroke.Thickness = 3
	barStroke.Parent = rainbowBar

	-- Gradiente arcoíris (de abajo hacia arriba)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = -90 -- De abajo hacia arriba

	-- Crear color sequence con los colores del arcoíris
	local colorKeypoints = {}
	for i, color in ipairs(RAINBOW_COLORS) do
		local time = (i - 1) / (#RAINBOW_COLORS - 1)
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(time, color))
	end
	gradient.Color = ColorSequence.new(colorKeypoints)
	gradient.Parent = rainbowBar

	return screenGui
end

-- ============================================
-- CREAR INDICADOR DE JUGADOR
-- ============================================

local function createPlayerIndicator(targetPlayer)
	if playerIndicators[targetPlayer] then return end

	-- Contenedor del indicador (centrado en la barra)
	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator_" .. targetPlayer.Name
	indicator.Size = UDim2.new(0, sizes.AvatarSize, 0, sizes.AvatarSize)
	-- Posición X: centrado en el contenedor (donde está la barra)
	indicator.Position = UDim2.new(0.5, 0, 1, 0) -- Empieza abajo
	indicator.AnchorPoint = Vector2.new(0.5, 0.5)
	indicator.BackgroundTransparency = 1
	indicator.ZIndex = 10
	indicator.Parent = mainContainer

	-- Contenedor circular para el avatar
	local avatarContainer = Instance.new("Frame")
	avatarContainer.Name = "AvatarContainer"
	avatarContainer.Size = UDim2.new(1, 0, 1, 0)
	avatarContainer.BackgroundColor3 = Color3.new(1, 1, 1)
	avatarContainer.ZIndex = 10
	avatarContainer.Parent = indicator

	local avatarCorner = Instance.new("UICorner")
	avatarCorner.CornerRadius = UDim.new(0.5, 0)
	avatarCorner.Parent = avatarContainer

	-- Borde del avatar (dorado para el jugador local, negro para otros)
	local avatarStroke = Instance.new("UIStroke")
	if targetPlayer == player then
		avatarStroke.Color = Color3.fromRGB(255, 200, 0) -- Dorado para el jugador local
		avatarStroke.Thickness = 4
	else
		avatarStroke.Color = Color3.new(0, 0, 0)
		avatarStroke.Thickness = 3
	end
	avatarStroke.Parent = avatarContainer

	-- Imagen del avatar
	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "AvatarImage"
	avatarImage.Size = UDim2.new(1, -4, 1, -4)
	avatarImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	avatarImage.AnchorPoint = Vector2.new(0.5, 0.5)
	avatarImage.BackgroundTransparency = 1
	avatarImage.ZIndex = 11
	avatarImage.Parent = avatarContainer

	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(0.5, 0)
	imageCorner.Parent = avatarImage

	-- Cargar thumbnail del jugador
	spawn(function()
		local success, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				targetPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)

		if success and content then
			avatarImage.Image = content
		end
	end)

	-- Guardar referencia
	playerIndicators[targetPlayer] = {
		Frame = indicator,
		AvatarImage = avatarImage,
		CurrentHeight = 0,
	}

	return indicator
end

-- ============================================
-- OBTENER ALTURA DEL JUGADOR
-- ============================================

local function getPlayerHeight(targetPlayer)
	local character = targetPlayer.Character
	if not character then return 0 end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return 0 end

	-- Calcular altura relativa al suelo base
	local height = rootPart.Position.Y - baseHeight
	return math.max(0, height)
end

-- ============================================
-- ACTUALIZAR POSICIÓN DEL INDICADOR
-- ============================================

local function updateIndicatorPosition(targetPlayer, indicator, height)
	if not rainbowBar then return end

	-- Esperar a que el tamaño absoluto esté disponible
	local barHeight = rainbowBar.AbsoluteSize.Y
	if barHeight <= 0 then return end

	-- Calcular posición en la barra (0 = abajo, 1 = arriba)
	local normalizedHeight = math.clamp(height / MAX_HEIGHT, 0, 1)

	-- La barra empieza en Y = 5 del contenedor y tiene altura barHeight
	local barStartY = 5

	-- Límites para el avatar:
	-- - Abajo: parte inferior de la barra (barStartY + barHeight)
	-- - Arriba: debajo del label SPACE (sizes.SpaceLabelHeight)
	local bottomY = barStartY + barHeight
	local topY = sizes.SpaceLabelHeight

	-- Interpolar: normalizedHeight=0 -> bottomY, normalizedHeight=1 -> topY
	local targetY = bottomY - normalizedHeight * (bottomY - topY)

	-- Animar suavemente (centrado en X = 0.5)
	TweenService:Create(indicator.Frame, TweenInfo.new(UPDATE_INTERVAL, Enum.EasingStyle.Linear), {
		Position = UDim2.new(0.5, 0, 0, targetY)
	}):Play()

	indicator.CurrentHeight = height
end

-- ============================================
-- ACTUALIZAR TODOS LOS JUGADORES
-- ============================================

local function updateAllPlayers()
	for _, targetPlayer in ipairs(Players:GetPlayers()) do
		-- Crear indicador si no existe
		if not playerIndicators[targetPlayer] then
			createPlayerIndicator(targetPlayer)
		end

		-- Actualizar posición
		local indicator = playerIndicators[targetPlayer]
		if indicator then
			local height = getPlayerHeight(targetPlayer)
			updateIndicatorPosition(targetPlayer, indicator, height)
		end
	end
end

-- ============================================
-- LIMPIAR JUGADOR DESCONECTADO
-- ============================================

local function removePlayerIndicator(targetPlayer)
	local indicator = playerIndicators[targetPlayer]
	if indicator then
		indicator.Frame:Destroy()
		playerIndicators[targetPlayer] = nil
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

-- Crear UI
createLeaderboardUI()

-- Detectar altura base del mundo
local function detectBaseHeight()
	local character = player.Character
	if character then
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if rootPart then
			-- Asumir que el jugador empieza cerca del suelo
			baseHeight = rootPart.Position.Y - 3
		end
	end
end

-- Esperar al personaje inicial
if player.Character then
	task.wait(0.5)
	detectBaseHeight()
end

player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	detectBaseHeight()
end)

-- Crear indicadores para jugadores existentes
for _, p in ipairs(Players:GetPlayers()) do
	createPlayerIndicator(p)
end

-- Escuchar nuevos jugadores
Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(1) -- Esperar a que cargue
	createPlayerIndicator(newPlayer)
end)

-- Escuchar jugadores que se van
Players.PlayerRemoving:Connect(removePlayerIndicator)

-- Loop de actualización
RunService.Heartbeat:Connect(function()
	updateAllPlayers()
end)

-- Responsive
ResponsiveUI.onViewportChanged(function(info)
	sizes = getResponsiveSizes()
	-- Recrear UI
	local screenGui = playerGui:FindFirstChild("HeightLeaderboard")
	if screenGui then
		screenGui:Destroy()
	end
	playerIndicators = {}
	createLeaderboardUI()

	-- Recrear indicadores
	for _, p in ipairs(Players:GetPlayers()) do
		createPlayerIndicator(p)
	end
end)

print("[HeightLeaderboard] Leaderboard de altura inicializado")
