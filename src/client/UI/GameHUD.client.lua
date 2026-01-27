--[[
	GameHUD.client.lua
	Interfaz de usuario del juego
	Estilo cartoon, grande y claro
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- ============================================
-- CONFIGURACIÓN DE ESTILOS
-- ============================================

local Styles = {
	-- Colores principales
	Colors = {
		Primary = Color3.fromRGB(255, 200, 50),     -- Amarillo dorado
		Secondary = Color3.fromRGB(100, 200, 100),  -- Verde
		Accent = Color3.fromRGB(255, 100, 100),     -- Rojo/Rosa
		Background = Color3.fromRGB(40, 40, 60),    -- Azul oscuro
		Text = Color3.fromRGB(255, 255, 255),       -- Blanco
		Shadow = Color3.fromRGB(0, 0, 0),           -- Negro
	},

	-- Fuentes
	Font = Enum.Font.FredokaOne,
	FontBold = Enum.Font.GothamBold,

	-- Tamaños
	CornerRadius = UDim.new(0, 12),
	Padding = UDim.new(0, 10),
}

-- ============================================
-- DATOS DEL JUGADOR (actualizados por eventos)
-- ============================================

local playerData = {
	Coins = 0,
	CurrentFatness = 0.5,
	MaxFatness = 3.0,
	CurrentHeight = 0,
	MaxHeight = 0,
}

-- ============================================
-- CREAR UI
-- ============================================

local function createScreenGui()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GameHUD"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	return screenGui
end

local function createCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius or Styles.CornerRadius
	corner.Parent = parent
	return corner
end

local function createStroke(parent, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Styles.Colors.Shadow
	stroke.Thickness = thickness or 3
	stroke.Parent = parent
	return stroke
end

local function createShadow(parent)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://6015897843" -- Sombra suave
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.5
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(49, 49, 450, 450)
	shadow.Size = UDim2.new(1, 30, 1, 30)
	shadow.Position = UDim2.new(0, -15, 0, -10)
	shadow.ZIndex = -1
	shadow.Parent = parent
	return shadow
end

-- ============================================
-- COMPONENTES DE UI
-- ============================================

-- Barra de gordura
local function createFatnessBar(parent)
	local container = Instance.new("Frame")
	container.Name = "FatnessBar"
	container.Size = UDim2.new(0, 250, 0, 50)
	container.Position = UDim2.new(0, 20, 1, -80)
	container.AnchorPoint = Vector2.new(0, 1)
	container.BackgroundColor3 = Styles.Colors.Background
	container.Parent = parent

	createCorner(container)
	createStroke(container, Styles.Colors.Primary, 4)

	-- Icono de hamburguesa
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 5, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "🍔"
	icon.TextSize = 28
	icon.Parent = container

	-- Barra de fondo
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBackground"
	barBg.Size = UDim2.new(1, -60, 0, 25)
	barBg.Position = UDim2.new(0, 50, 0.5, 0)
	barBg.AnchorPoint = Vector2.new(0, 0.5)
	barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	barBg.Parent = container
	createCorner(barBg, UDim.new(0, 8))

	-- Barra de llenado
	local barFill = Instance.new("Frame")
	barFill.Name = "BarFill"
	barFill.Size = UDim2.new(0.5, 0, 1, 0)
	barFill.BackgroundColor3 = Styles.Colors.Secondary
	barFill.Parent = barBg
	createCorner(barFill, UDim.new(0, 8))

	-- Gradiente
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 255, 150)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 180, 80)),
	})
	gradient.Rotation = 90
	gradient.Parent = barFill

	return container, barFill
end

-- Contador de monedas
local function createCoinCounter(parent)
	local container = Instance.new("Frame")
	container.Name = "CoinCounter"
	container.Size = UDim2.new(0, 180, 0, 60)
	container.Position = UDim2.new(1, -20, 0, 20)
	container.AnchorPoint = Vector2.new(1, 0)
	container.BackgroundColor3 = Styles.Colors.Background
	container.Parent = parent

	createCorner(container)
	createStroke(container, Styles.Colors.Primary, 4)

	-- Icono de moneda
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 50, 0, 50)
	icon.Position = UDim2.new(0, 5, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "💰"
	icon.TextSize = 36
	icon.Parent = container

	-- Texto de cantidad
	local amount = Instance.new("TextLabel")
	amount.Name = "Amount"
	amount.Size = UDim2.new(1, -60, 1, 0)
	amount.Position = UDim2.new(0, 55, 0, 0)
	amount.BackgroundTransparency = 1
	amount.Text = "0"
	amount.TextColor3 = Styles.Colors.Primary
	amount.TextSize = 32
	amount.Font = Styles.Font
	amount.TextXAlignment = Enum.TextXAlignment.Left
	amount.Parent = container

	return container, amount
end

-- Medidor de altura
local function createHeightMeter(parent)
	local container = Instance.new("Frame")
	container.Name = "HeightMeter"
	container.Size = UDim2.new(0, 120, 0, 50)
	container.Position = UDim2.new(0.5, 0, 0, 20)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundColor3 = Styles.Colors.Background
	container.Parent = parent

	createCorner(container)
	createStroke(container, Styles.Colors.Secondary, 4)

	-- Icono
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0, 5, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.Text = "📏"
	icon.TextSize = 20
	icon.Parent = container

	-- Altura actual
	local height = Instance.new("TextLabel")
	height.Name = "Height"
	height.Size = UDim2.new(1, -40, 1, 0)
	height.Position = UDim2.new(0, 35, 0, 0)
	height.BackgroundTransparency = 1
	height.Text = "0m"
	height.TextColor3 = Styles.Colors.Text
	height.TextSize = 24
	height.Font = Styles.Font
	height.TextXAlignment = Enum.TextXAlignment.Center
	height.Parent = container

	return container, height
end

-- Notificación de hito
local function createMilestoneNotification(parent)
	local container = Instance.new("Frame")
	container.Name = "MilestoneNotification"
	container.Size = UDim2.new(0, 400, 0, 100)
	container.Position = UDim2.new(0.5, 0, 0.3, 0)
	container.AnchorPoint = Vector2.new(0.5, 0.5)
	container.BackgroundColor3 = Styles.Colors.Primary
	container.BackgroundTransparency = 1
	container.Visible = false
	container.Parent = parent

	createCorner(container, UDim.new(0, 20))

	-- Texto principal
	local mainText = Instance.new("TextLabel")
	mainText.Name = "MainText"
	mainText.Size = UDim2.new(1, 0, 0.6, 0)
	mainText.Position = UDim2.new(0, 0, 0, 0)
	mainText.BackgroundTransparency = 1
	mainText.Text = "🎉 100 METROS! 🎉"
	mainText.TextColor3 = Styles.Colors.Text
	mainText.TextSize = 48
	mainText.Font = Styles.Font
	mainText.TextStrokeTransparency = 0
	mainText.TextStrokeColor3 = Styles.Colors.Shadow
	mainText.Parent = container

	-- Texto de bonus
	local bonusText = Instance.new("TextLabel")
	bonusText.Name = "BonusText"
	bonusText.Size = UDim2.new(1, 0, 0.4, 0)
	bonusText.Position = UDim2.new(0, 0, 0.6, 0)
	bonusText.BackgroundTransparency = 1
	bonusText.Text = "+50 💰"
	bonusText.TextColor3 = Styles.Colors.Primary
	bonusText.TextSize = 32
	bonusText.Font = Styles.Font
	bonusText.TextStrokeTransparency = 0
	bonusText.Parent = container

	return container, mainText, bonusText
end

-- Número flotante de moneda
local function createFloatingNumber(parent)
	local template = Instance.new("TextLabel")
	template.Name = "FloatingNumber"
	template.Size = UDim2.new(0, 100, 0, 40)
	template.BackgroundTransparency = 1
	template.Text = "+10 💰"
	template.TextColor3 = Styles.Colors.Primary
	template.TextSize = 28
	template.Font = Styles.Font
	template.TextStrokeTransparency = 0
	template.Visible = false
	template.Parent = parent
	return template
end

-- ============================================
-- INICIALIZAR UI
-- ============================================

local screenGui = createScreenGui()
local fatnessContainer, fatnessBar = createFatnessBar(screenGui)
local coinContainer, coinText = createCoinCounter(screenGui)
local heightContainer, heightText = createHeightMeter(screenGui)
local milestoneContainer, milestoneMain, milestoneBonus = createMilestoneNotification(screenGui)
local floatingNumberTemplate = createFloatingNumber(screenGui)

-- ============================================
-- FUNCIONES DE ACTUALIZACIÓN
-- ============================================

local function updateFatnessBar(current, max)
	local percentage = math.clamp((current - 0.5) / (max - 0.5), 0, 1)
	TweenService:Create(fatnessBar, TweenInfo.new(0.2), {
		Size = UDim2.new(percentage, 0, 1, 0)
	}):Play()
end

local function updateCoins(amount)
	coinText.Text = tostring(amount)

	-- Animación de "pop"
	local tween = TweenService:Create(coinText, TweenInfo.new(0.1), {
		TextSize = 40
	})
	tween:Play()
	tween.Completed:Wait()
	TweenService:Create(coinText, TweenInfo.new(0.1), {
		TextSize = 32
	}):Play()
end

local function updateHeight(height)
	heightText.Text = math.floor(height) .. "m"
end

local function showMilestone(milestone)
	milestoneMain.Text = "🎉 " .. milestone.Message .. " 🎉"
	milestoneBonus.Text = "+" .. milestone.Bonus .. " 💰"

	milestoneContainer.Visible = true
	milestoneContainer.BackgroundTransparency = 0
	milestoneContainer.Size = UDim2.new(0, 0, 0, 0)

	-- Animación de entrada
	local tweenIn = TweenService:Create(milestoneContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 400, 0, 100),
		BackgroundTransparency = 0.2
	})
	tweenIn:Play()
	tweenIn.Completed:Wait()

	task.wait(2)

	-- Animación de salida
	local tweenOut = TweenService:Create(milestoneContainer, TweenInfo.new(0.3), {
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0.2, 0)
	})
	tweenOut:Play()
	tweenOut.Completed:Wait()

	milestoneContainer.Visible = false
	milestoneContainer.Position = UDim2.new(0.5, 0, 0.3, 0)
end

local function showFloatingNumber(amount, worldPosition)
	local camera = workspace.CurrentCamera
	if not camera then return end

	local screenPos, onScreen = camera:WorldToScreenPoint(worldPosition)
	if not onScreen then return end

	local floater = floatingNumberTemplate:Clone()
	floater.Text = "+" .. amount .. " 💰"
	floater.Position = UDim2.new(0, screenPos.X, 0, screenPos.Y)
	floater.Visible = true
	floater.Parent = screenGui

	-- Animación hacia arriba y desvanecimiento
	local tweenUp = TweenService:Create(floater, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, screenPos.X, 0, screenPos.Y - 100),
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})
	tweenUp:Play()
	tweenUp.Completed:Connect(function()
		floater:Destroy()
	end)
end

-- ============================================
-- CONEXIONES CON SERVIDOR
-- ============================================

if Remotes then
	-- Datos cargados
	local OnDataLoaded = Remotes:FindFirstChild("OnDataLoaded")
	if OnDataLoaded then
		OnDataLoaded.OnClientEvent:Connect(function(data)
			if data and data.Data then
				playerData.Coins = data.Data.Coins or 0
				playerData.MaxFatness = data.UpgradeValues and data.UpgradeValues.MaxFatness or 3.0
				updateCoins(playerData.Coins)
			end
		end)
	end

	-- Datos actualizados
	local OnDataUpdated = Remotes:FindFirstChild("OnDataUpdated")
	if OnDataUpdated then
		OnDataUpdated.OnClientEvent:Connect(function(data)
			if data then
				playerData.Coins = data.Coins or playerData.Coins
				updateCoins(playerData.Coins)
			end
		end)
	end

	-- Moneda recogida
	local OnCoinCollected = Remotes:FindFirstChild("OnCoinCollected")
	if OnCoinCollected then
		OnCoinCollected.OnClientEvent:Connect(function(amount, totalCoins)
			updateCoins(totalCoins)

			-- Mostrar número flotante
			local character = player.Character
			if character then
				local rootPart = character:FindFirstChild("HumanoidRootPart")
				if rootPart then
					showFloatingNumber(amount, rootPart.Position + Vector3.new(0, 3, 0))
				end
			end
		end)
	end

	-- Hito alcanzado
	local OnMilestoneReached = Remotes:FindFirstChild("OnMilestoneReached")
	if OnMilestoneReached then
		OnMilestoneReached.OnClientEvent:Connect(function(milestone)
			showMilestone(milestone)
		end)
	end
end

-- ============================================
-- ACTUALIZACIÓN EN TIEMPO REAL
-- ============================================

-- Exponer función para que FartController actualice la UI
local FartController = {}

function FartController.UpdateFatness(current, max)
	playerData.CurrentFatness = current
	playerData.MaxFatness = max
	updateFatnessBar(current, max)
end

function FartController.UpdateHeight(height)
	playerData.CurrentHeight = height
	updateHeight(height)
end

-- Guardar en _G para acceso desde otros scripts (temporal, mejor usar módulos)
_G.GameHUD = FartController

print("[GameHUD] UI inicializada")
