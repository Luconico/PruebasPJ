--[[
	HeightRewards.client.lua
	Sistema de recompensas por altura con feedback visual tipo "gambling"
	Efectos llamativos, números grandes, colores brillantes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Esperar dependencias
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- ============================================
-- CONFIGURACIÓN VISUAL
-- ============================================

local SOUNDS = {
	coin_small = "rbxassetid://9119713951",     -- Tic suave (pop/click)
	coin_medium = "rbxassetid://9119713951",    -- Tic medio
	coin_big = "rbxassetid://9119713951",       -- Tic para tiers altos
}

-- ============================================
-- CREAR UI PRINCIPAL
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "HeightRewardsUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Container para las notificaciones (centro-arriba de la pantalla)
local notificationContainer = Instance.new("Frame")
notificationContainer.Name = "NotificationContainer"
notificationContainer.Size = UDim2.new(1, 0, 0.5, 0)
notificationContainer.Position = UDim2.new(0, 0, 0.1, 0)
notificationContainer.BackgroundTransparency = 1
notificationContainer.Parent = screenGui

-- ============================================
-- EFECTOS DE SONIDO
-- ============================================

local sounds = {}

-- Volúmenes por tier (más bajo = más suave)
local VOLUME_BY_TIER = {
	common = 0.15,
	uncommon = 0.2,
	rare = 0.25,
	epic = 0.3,
	legendary = 0.4,
	mythic = 0.5,
}

local function createSound(name, soundId)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = 0.2 -- Volumen base bajo
	sound.Parent = screenGui
	sounds[name] = sound
	return sound
end

for name, id in pairs(SOUNDS) do
	createSound(name, id)
end

local function playSound(tier)
	local soundName = "coin_small"
	if tier == "rare" or tier == "epic" then
		soundName = "coin_medium"
	elseif tier == "legendary" or tier == "mythic" then
		soundName = "coin_big"
	end

	if sounds[soundName] then
		local sound = sounds[soundName]
		-- Volumen según tier
		sound.Volume = VOLUME_BY_TIER[tier] or 0.2
		-- Pitch aleatorio para variedad (0.9 a 1.15)
		sound.PlaybackSpeed = 0.9 + math.random() * 0.25
		sound:Play()
	end
end

-- ============================================
-- CREAR PARTÍCULAS DE MONEDAS
-- ============================================

local function createCoinParticles(parent, tier)
	local tierConfig = Config.Rewards.TierEffects[tier] or Config.Rewards.TierEffects.common

	-- Emitter principal de monedas/estrellas
	local particles = Instance.new("Frame")
	particles.Name = "Particles"
	particles.Size = UDim2.new(1, 0, 1, 0)
	particles.BackgroundTransparency = 1
	particles.Parent = parent

	-- Crear partículas individuales
	local numParticles = tier == "mythic" and 30 or (tier == "legendary" and 20 or (tier == "epic" and 15 or 8))

	for i = 1, numParticles do
		local particle = Instance.new("TextLabel")
		particle.Name = "Particle_" .. i
		particle.Size = UDim2.new(0, 30, 0, 30)
		particle.Position = UDim2.new(0.5, 0, 0.5, 0)
		particle.AnchorPoint = Vector2.new(0.5, 0.5)
		particle.BackgroundTransparency = 1
		particle.Text = math.random() > 0.5 and "$" or "*"
		particle.TextColor3 = tierConfig.Color
		particle.TextSize = math.random(20, 40)
		particle.Font = Enum.Font.GothamBlack
		particle.TextTransparency = 0
		particle.ZIndex = 5
		particle.Parent = particles

		-- Animación aleatoria de explosión
		local angle = math.rad(math.random(0, 360))
		local distance = math.random(100, 300)
		local targetX = 0.5 + math.cos(angle) * (distance / 500)
		local targetY = 0.5 + math.sin(angle) * (distance / 300)

		local tween = TweenService:Create(particle, TweenInfo.new(
			tierConfig.Duration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		), {
			Position = UDim2.new(targetX, 0, targetY, 0),
			TextTransparency = 1,
			Rotation = math.random(-180, 180)
		})
		tween:Play()
	end

	-- Limpiar después
	task.delay(tierConfig.Duration + 0.5, function()
		particles:Destroy()
	end)
end

-- ============================================
-- CREAR NOTIFICACIÓN DE RECOMPENSA
-- ============================================

-- Referencia a la notificación actual (para eliminarla cuando llegue una nueva)
local currentNotification = nil

local function showRewardNotification(milestone)
	local tier = milestone.Tier or "common"
	local tierConfig = Config.Rewards.TierEffects[tier] or Config.Rewards.TierEffects.common

	-- Eliminar notificación anterior con fade out rápido
	if currentNotification and currentNotification.Parent then
		local oldNotification = currentNotification
		-- Fade out rápido
		for _, child in ipairs(oldNotification:GetDescendants()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, TweenInfo.new(0.15), {TextTransparency = 1}):Play()
			elseif child:IsA("ImageLabel") then
				TweenService:Create(child, TweenInfo.new(0.15), {ImageTransparency = 1}):Play()
			end
		end
		task.delay(0.15, function()
			if oldNotification and oldNotification.Parent then
				oldNotification:Destroy()
			end
		end)
	end

	-- Container principal de la notificación
	local notification = Instance.new("Frame")
	notification.Name = "Notification"
	notification.Size = UDim2.new(0, 400 * tierConfig.Scale, 0, 150 * tierConfig.Scale)
	notification.Position = UDim2.new(0.5, 0, 0.3, 0)
	notification.AnchorPoint = Vector2.new(0.5, 0.5)
	notification.BackgroundTransparency = 1
	notification.Parent = notificationContainer

	-- Guardar referencia a la notificación actual
	currentNotification = notification

	-- Fondo con gradiente (solo para tiers altos)
	if tier ~= "common" then
		local glow = Instance.new("ImageLabel")
		glow.Name = "Glow"
		glow.Size = UDim2.new(1.5, 0, 2, 0)
		glow.Position = UDim2.new(0.5, 0, 0.5, 0)
		glow.AnchorPoint = Vector2.new(0.5, 0.5)
		glow.BackgroundTransparency = 1
		glow.Image = "rbxassetid://5153561933" -- Glow circular
		glow.ImageColor3 = tierConfig.Color
		glow.ImageTransparency = 0.7
		glow.ZIndex = 1
		glow.Parent = notification

		-- Animación de pulsación del glow
		local glowTween = TweenService:Create(glow, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut, -1, true), {
			Size = UDim2.new(1.8, 0, 2.5, 0),
			ImageTransparency = 0.5
		})
		glowTween:Play()
	end

	-- Texto de altura alcanzada
	local heightText = Instance.new("TextLabel")
	heightText.Name = "HeightText"
	heightText.Size = UDim2.new(1, 0, 0.5, 0)
	heightText.Position = UDim2.new(0, 0, 0, 0)
	heightText.BackgroundTransparency = 1
	heightText.Text = milestone.Message
	heightText.TextColor3 = tierConfig.Color
	heightText.TextSize = 48 * tierConfig.Scale
	heightText.Font = Enum.Font.GothamBlack
	heightText.TextStrokeTransparency = 0
	heightText.TextStrokeColor3 = Color3.new(0, 0, 0)
	heightText.ZIndex = 10
	heightText.Parent = notification

	-- Texto de monedas ganadas con efecto de contador
	local coinsText = Instance.new("TextLabel")
	coinsText.Name = "CoinsText"
	coinsText.Size = UDim2.new(1, 0, 0.5, 0)
	coinsText.Position = UDim2.new(0, 0, 0.5, 0)
	coinsText.BackgroundTransparency = 1
	coinsText.Text = "+0"
	coinsText.TextColor3 = Color3.fromRGB(255, 215, 0) -- Dorado
	coinsText.TextSize = 56 * tierConfig.Scale
	coinsText.Font = Enum.Font.GothamBlack
	coinsText.TextStrokeTransparency = 0
	coinsText.TextStrokeColor3 = Color3.new(0, 0, 0)
	coinsText.ZIndex = 10
	coinsText.Parent = notification

	-- Animación de entrada (scale + fade)
	notification.Size = UDim2.new(0, 0, 0, 0)
	heightText.TextTransparency = 1
	coinsText.TextTransparency = 1

	-- Pop in
	local popIn = TweenService:Create(notification, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400 * tierConfig.Scale, 0, 150 * tierConfig.Scale)
	})
	popIn:Play()

	TweenService:Create(heightText, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
	TweenService:Create(coinsText, TweenInfo.new(0.15), {TextTransparency = 0}):Play()

	-- Efecto de contador de monedas (tipo slot machine)
	local targetCoins = milestone.Bonus
	local countDuration = math.min(0.5, targetCoins / 100)
	local startTime = tick()

	local countConnection
	countConnection = RunService.Heartbeat:Connect(function()
		local elapsed = tick() - startTime
		local progress = math.min(elapsed / countDuration, 1)

		-- Easing para el contador
		local easedProgress = 1 - (1 - progress) ^ 3
		local currentValue = math.floor(targetCoins * easedProgress)

		coinsText.Text = "+" .. currentValue

		-- Shake effect para tiers altos
		if tier == "legendary" or tier == "mythic" or tier == "epic" then
			local shake = (1 - progress) * 5
			coinsText.Position = UDim2.new(
				0, math.random(-shake, shake),
				0.5, math.random(-shake, shake)
			)
		end

		if progress >= 1 then
			countConnection:Disconnect()
			coinsText.Position = UDim2.new(0, 0, 0.5, 0)
			coinsText.Text = "+" .. targetCoins

			-- Flash final
			local flash = TweenService:Create(coinsText, TweenInfo.new(0.1), {
				TextSize = 70 * tierConfig.Scale
			})
			flash:Play()
			flash.Completed:Connect(function()
				TweenService:Create(coinsText, TweenInfo.new(0.1), {
					TextSize = 56 * tierConfig.Scale
				}):Play()
			end)
		end
	end)

	-- Crear partículas
	createCoinParticles(notification, tier)

	-- Reproducir sonido
	playSound(tier)

	-- Animación de salida
	task.delay(tierConfig.Duration, function()
		local fadeOut = TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0.2, 0),
		})
		TweenService:Create(heightText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		TweenService:Create(coinsText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			-- Solo destruir si sigue siendo la notificación actual
			if currentNotification == notification then
				currentNotification = nil
			end
			notification:Destroy()
		end)
	end)
end

-- ============================================
-- SISTEMA DE DETECCIÓN DE ALTURA
-- ============================================

local baseHeight = 0
local achievedMilestones = {}
local currentFlightMaxHeight = 0
local isInFlight = false
local lastGroundedTime = 0

local function getPlayerHeight()
	local character = player.Character
	if not character then return 0 end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return 0 end

	return rootPart.Position.Y - baseHeight
end

local function isGrounded()
	local character = player.Character
	if not character then return true end

	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return true end

	-- Considera que está en el suelo si está muy bajo o el estado es correcto
	local height = getPlayerHeight()
	return height < 3 or humanoid.FloorMaterial ~= Enum.Material.Air
end

local function resetFlightMilestones()
	achievedMilestones = {}
	currentFlightMaxHeight = 0
end

local function checkHeightMilestones()
	local height = getPlayerHeight()

	-- Actualizar altura máxima del vuelo actual
	if height > currentFlightMaxHeight then
		currentFlightMaxHeight = height
	end

	-- Revisar milestones
	for _, milestone in ipairs(Config.Rewards.HeightMilestones) do
		local milestoneKey = milestone.Height

		if height >= milestone.Height and not achievedMilestones[milestoneKey] then
			achievedMilestones[milestoneKey] = true

			-- Mostrar notificación
			showRewardNotification(milestone)

			-- Notificar al servidor para dar las monedas
			local CollectHeightBonus = Remotes:FindFirstChild("CollectHeightBonus")
			if CollectHeightBonus then
				CollectHeightBonus:FireServer(milestone.Height, milestone.Bonus)
			end
		end
	end
end

-- ============================================
-- LOOP PRINCIPAL
-- ============================================

-- Obtener altura base al inicio
task.spawn(function()
	task.wait(2) -- Esperar a que cargue el personaje
	local character = player.Character or player.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if rootPart then
		-- La altura base es aproximadamente donde spawneamos
		baseHeight = math.floor(rootPart.Position.Y - 3)
		print("[HeightRewards] Altura base establecida:", baseHeight)
	end
end)

RunService.Heartbeat:Connect(function()
	local grounded = isGrounded()

	if grounded then
		if isInFlight then
			-- Acaba de aterrizar, resetear para el próximo vuelo
			isInFlight = false
			lastGroundedTime = tick()

			-- Pequeño delay antes de resetear (para evitar falsos positivos)
			task.delay(1, function()
				if not isInFlight and (tick() - lastGroundedTime) >= 0.9 then
					resetFlightMilestones()
				end
			end)
		end
	else
		-- Está en el aire
		if not isInFlight then
			isInFlight = true
		end

		checkHeightMilestones()
	end
end)

-- Reset cuando el personaje muere/respawnea
player.CharacterAdded:Connect(function(character)
	resetFlightMilestones()

	-- Actualizar altura base
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)
	if rootPart then
		task.wait(0.5)
		baseHeight = math.floor(rootPart.Position.Y - 3)
	end
end)

print("[HeightRewards] Sistema de recompensas por altura inicializado")
