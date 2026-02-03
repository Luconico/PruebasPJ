--[[
	EggShop.client.lua
	UI para comprar y abrir huevos de mascotas
	Estilo consistente con UpgradeShop
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local Config = require(Shared:WaitForChild("Config"))
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))

-- Tamaños responsive
local function getResponsiveSizes()
	local info = ResponsiveUI.getViewportInfo()
	local scale = info.Scale
	local isMobile = info.IsMobile

	return {
		ContainerWidth = isMobile and 0.95 or 0.6,
		ContainerHeight = isMobile and 0.85 or 0.7,
		HeaderHeight = isMobile and 80 or math.floor(100 * scale),
		TitleSize = isMobile and 28 or math.floor(42 * scale),
		CardSize = isMobile and 160 or math.floor(220 * scale),
		CardPadding = isMobile and 12 or math.floor(18 * scale),
		IconSize = isMobile and 80 or math.floor(120 * scale),
		ButtonHeight = isMobile and 45 or math.floor(60 * scale),
		ButtonTextSize = isMobile and 18 or math.floor(24 * scale),
		TextSize = isMobile and 16 or math.floor(20 * scale),
		CornerRadius = isMobile and 12 or math.floor(18 * scale),
		IsMobile = isMobile,
	}
end

local sizes = getResponsiveSizes()

-- Estilos
local Styles = {
	Colors = {
		Background = Color3.fromRGB(25, 25, 45),
		Header = Color3.fromRGB(255, 180, 50),
		Card = Color3.fromRGB(45, 45, 75),
		ButtonCoin = Color3.fromRGB(255, 200, 50),
		ButtonRobux = Color3.fromRGB(100, 200, 100),
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(40, 40, 60),
		TextMuted = Color3.fromRGB(180, 180, 200),
		Border = Color3.fromRGB(255, 255, 255),
	},
	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
	},
}

-- Estado
local playerData = nil
local shopOpen = false

-- ============================================
-- CREAR UI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggShop"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Backdrop (fondo semi-transparente)
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.Parent = screenGui

-- Main container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.Size = UDim2.new(sizes.ContainerWidth, 0, sizes.ContainerHeight, 0)
mainContainer.BackgroundColor3 = Styles.Colors.Background
mainContainer.BorderSizePixel = 0
mainContainer.Parent = backdrop

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
mainCorner.Parent = mainContainer

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, sizes.HeaderHeight)
header.BackgroundColor3 = Styles.Colors.Header
header.BorderSizePixel = 0
header.Parent = mainContainer

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
headerCorner.Parent = header

local headerGradient = Instance.new("UIGradient")
headerGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 150, 50)),
}
headerGradient.Rotation = 90
headerGradient.Parent = header

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 300, 1, 0)
title.Position = UDim2.new(0, 20, 0, 0)
title.BackgroundTransparency = 1
title.Text = "🥚 PET EGGS 🥚"
title.Font = Styles.Fonts.Title
title.TextSize = sizes.TitleSize
title.TextColor3 = Styles.Colors.TextDark
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.AnchorPoint = Vector2.new(1, 0.5)
closeButton.Position = UDim2.new(1, -15, 0.5, 0)
closeButton.Size = UDim2.new(0, 60, 0, 60)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeButton.Text = "✕"
closeButton.Font = Styles.Fonts.Title
closeButton.TextSize = 36
closeButton.TextColor3 = Styles.Colors.Text
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	backdrop.Visible = false
	shopOpen = false
end)

-- Content container
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Name = "ContentContainer"
contentContainer.Position = UDim2.new(0, 0, 0, sizes.HeaderHeight)
contentContainer.Size = UDim2.new(1, 0, 1, -sizes.HeaderHeight)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.ScrollBarThickness = 8
contentContainer.Parent = mainContainer

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.PaddingLeft = UDim.new(0, 20)
contentPadding.PaddingRight = UDim.new(0, 20)
contentPadding.Parent = contentContainer

local contentLayout = Instance.new("UIGridLayout")
contentLayout.CellSize = UDim2.new(0, sizes.CardSize, 0, sizes.CardSize + 80)
contentLayout.CellPadding = UDim2.new(0, sizes.CardPadding, 0, sizes.CardPadding)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentContainer

-- ============================================
-- FUNCIONES (Forward declarations)
-- ============================================

local updateEggShop -- Forward declaration

-- ============================================
-- CREAR TARJETA DE HUEVO
-- ============================================

local function createEggCard(eggName, eggConfig)
	local card = Instance.new("Frame")
	card.Name = eggName
	card.BackgroundColor3 = Styles.Colors.Card
	card.BorderSizePixel = 0
	card.Parent = contentContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
	cardCorner.Parent = card

	-- Icono del huevo
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, sizes.IconSize, 0, sizes.IconSize)
	icon.Position = UDim2.new(0.5, 0, 0, 15)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Text = eggConfig.Icon
	icon.Font = Enum.Font.SourceSans
	icon.TextSize = sizes.IconSize
	icon.Parent = card

	-- Nombre del huevo
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -20, 0, 30)
	name.Position = UDim2.new(0.5, 0, 0, sizes.IconSize + 25)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.BackgroundTransparency = 1
	name.Text = eggConfig.Name
	name.Font = Styles.Fonts.Title
	name.TextSize = sizes.TextSize + 4
	name.TextColor3 = Styles.Colors.Text
	name.Parent = card

	-- Descripción
	local desc = Instance.new("TextLabel")
	desc.Size = UDim2.new(1, -20, 0, 30)
	desc.Position = UDim2.new(0.5, 0, 0, sizes.IconSize + 55)
	desc.AnchorPoint = Vector2.new(0.5, 0)
	desc.BackgroundTransparency = 1
	desc.Text = eggConfig.Description
	desc.Font = Styles.Fonts.Body
	desc.TextSize = sizes.TextSize - 4
	desc.TextColor3 = Styles.Colors.TextMuted
	desc.TextWrapped = true
	desc.Parent = card

	-- Botón de compra
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.new(1, -30, 0, sizes.ButtonHeight)
	buyButton.Position = UDim2.new(0.5, 0, 1, -sizes.ButtonHeight - 15)
	buyButton.AnchorPoint = Vector2.new(0.5, 0)
	buyButton.BackgroundColor3 = eggConfig.CostRobux and Styles.Colors.ButtonRobux or Styles.Colors.ButtonCoin
	buyButton.Text = eggConfig.CostRobux and ("💎 " .. eggConfig.CostRobux .. " R$") or ("💰 " .. eggConfig.Cost)
	buyButton.Font = Styles.Fonts.Title
	buyButton.TextSize = sizes.ButtonTextSize
	buyButton.TextColor3 = eggConfig.CostRobux and Styles.Colors.Text or Styles.Colors.TextDark
	buyButton.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
	buyCorner.Parent = buyButton

	local buyStroke = Instance.new("UIStroke")
	buyStroke.Color = Styles.Colors.Border
	buyStroke.Thickness = 3
	buyStroke.Transparency = 0.7
	buyStroke.Parent = buyButton

	buyButton.MouseButton1Click:Connect(function()
		if not playerData then return end

		local success, result, petName, uuid = pcall(function()
			return Remotes.OpenEgg:InvokeServer(eggName)
		end)

		if success and result then
			print("[EggShop] Mascota obtenida:", petName)
			-- Mostrar notificación (puede mejorarse con UI animada)
			-- Por ahora solo print
			updateEggShop()
		else
			warn("[EggShop] Error:", result)
		end
	end)
end

-- ============================================
-- ACTUALIZAR UI
-- ============================================

updateEggShop = function()
	-- Limpiar tarjetas existentes
	for _, child in ipairs(contentContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Obtener datos del jugador
	local success, result = pcall(function()
		return Remotes.GetPlayerData:InvokeServer()
	end)

	if success then
		playerData = result.Data
	end

	-- Crear tarjetas para cada huevo
	for eggName, eggConfig in pairs(Config.Eggs) do
		createEggCard(eggName, eggConfig)
	end
end

-- ============================================
-- ABRIR/CERRAR TIENDA
-- ============================================

local function openShop()
	if shopOpen then return end
	shopOpen = true
	backdrop.Visible = true
	updateEggShop()
end

local function closeShop()
	shopOpen = false
	backdrop.Visible = false
end

-- Toggle con tecla E
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.E then
		if shopOpen then
			closeShop()
		else
			openShop()
		end
	end
end)

-- Actualizar cuando cambien los datos
Remotes.OnDataUpdated.OnClientEvent:Connect(function(newData)
	playerData = newData
	if shopOpen then
		updateEggShop()
	end
end)

print("[EggShop] Inicializado - Presiona E para abrir")
