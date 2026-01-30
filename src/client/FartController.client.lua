--[[
	FartController.client.lua
	Controlador principal de la mecánica de engorde y propulsión
	Los valores se obtienen del servidor para evitar cheats
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Esperar Remotes del servidor
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then
	warn("[FartController] No se encontraron Remotes del servidor")
	return
end

-- Cargar módulo de sonidos
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundManager = require(Shared:WaitForChild("SoundManager"))

-- ============================================
-- VARIABLES DE ESTADO
-- ============================================
local character = nil
local humanoid = nil
local humanoidRootPart = nil

-- Estado del juego
local isDataLoaded = false
local isEating = false      -- Si está cerca de comida y engordando
local isPropelling = false  -- Si está propulsándose

-- Valores del servidor (se actualizan al cargar datos)
local playerStats = {
	MaxFatness = 1.5,      -- Base sin upgrades (máximo 4.0 con upgrades)
	EatSpeed = 0.08,
	PropulsionForce = 50,
	FuelEfficiency = 0.04,
}

-- Estado actual
local currentFatness = 0.5  -- Empieza delgado
local thinMultiplier = 0.5
local currentHeight = 0
local maxHeightThisFlight = 0
local isInGameZone = false

-- Zona de comida actual
local currentFoodZone = nil
local currentFoodConfig = nil

-- Zona física donde está el jugador (incluso si está bloqueada)
local currentPhysicalZone = nil
local currentPhysicalConfig = nil


-- Efectos
local fartSound = nil
local fartParticles = nil
local lastFartTime = 0
local fartInterval = 0.3

-- Sonido de comer
local eatSound = nil

-- Partes del cuerpo
local bodyParts = {}
local originalSizes = {}
local leftShoulder, rightShoulder
local leftHip, rightHip
local originalLeftShoulderC0, originalRightShoulderC0
local originalLeftHipC0, originalRightHipC0
local upperTorso, lowerTorso

-- Propulsión
local bodyVelocity = nil

-- Cosmético equipado
local equippedCosmeticConfig = nil

-- ============================================
-- EFECTOS VISUALES (Solo cliente)
-- ============================================

local function createFartParticles(parent)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "FartParticles"
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"

	-- Usar colores del cosmético equipado o colores por defecto
	local colors = {
		Color3.fromRGB(140, 160, 80),
		Color3.fromRGB(100, 120, 50),
		Color3.fromRGB(80, 100, 40),
	}

	if equippedCosmeticConfig and equippedCosmeticConfig.Colors and #equippedCosmeticConfig.Colors > 0 then
		colors = equippedCosmeticConfig.Colors
	end

	-- Crear ColorSequence basado en los colores del cosmético
	local colorKeypoints = {}
	for i, color in ipairs(colors) do
		local time = (i - 1) / math.max(#colors - 1, 1)
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(time, color))
	end

	-- Asegurar que haya al menos 2 keypoints
	if #colorKeypoints == 1 then
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(1, colors[1]))
	end

	particles.Color = ColorSequence.new(colorKeypoints)

	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.4, 0.1),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})

	-- Tamaño basado en cosmético
	local sizeMin = 1.5
	local sizeMax = 5
	if equippedCosmeticConfig and equippedCosmeticConfig.ParticleSize then
		sizeMin = equippedCosmeticConfig.ParticleSize.Min or 0.5
		sizeMax = (equippedCosmeticConfig.ParticleSize.Max or 2) * 2.5
	end

	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sizeMin),
		NumberSequenceKeypoint.new(0.5, (sizeMin + sizeMax) / 2),
		NumberSequenceKeypoint.new(1, sizeMax),
	})

	particles.Rate = 20
	particles.Lifetime = NumberRange.new(1.2, 2)
	particles.Speed = NumberRange.new(4, 8)
	particles.SpreadAngle = Vector2.new(40, 40)
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-10, 10)
	particles.Acceleration = Vector3.new(0, 2, 0)
	particles.Drag = 2
	particles.EmissionDirection = Enum.NormalId.Back

	-- Brillo para cosméticos con glow
	if equippedCosmeticConfig and equippedCosmeticConfig.Glow then
		particles.LightEmission = 0.5
	else
		particles.LightEmission = 0
	end
	particles.LightInfluence = 1
	particles.Enabled = false

	particles.Parent = parent
	return particles
end

-- Actualizar colores de partículas cuando cambia el cosmético
local function updateFartParticleColors()
	if not fartParticles then return end

	local colors = {
		Color3.fromRGB(140, 160, 80),
		Color3.fromRGB(100, 120, 50),
		Color3.fromRGB(80, 100, 40),
	}

	if equippedCosmeticConfig and equippedCosmeticConfig.Colors and #equippedCosmeticConfig.Colors > 0 then
		colors = equippedCosmeticConfig.Colors
	end

	local colorKeypoints = {}
	for i, color in ipairs(colors) do
		local time = (i - 1) / math.max(#colors - 1, 1)
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(time, color))
	end

	if #colorKeypoints == 1 then
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(1, colors[1]))
	end

	fartParticles.Color = ColorSequence.new(colorKeypoints)

	-- Actualizar glow
	if equippedCosmeticConfig and equippedCosmeticConfig.Glow then
		fartParticles.LightEmission = 0.5
	else
		fartParticles.LightEmission = 0
	end
end

local function createFartSound(parent)
	local sound = Instance.new("Sound")
	sound.Name = "FartSound"
	sound.Volume = 1
	sound.RollOffMaxDistance = 50
	sound.Parent = parent
	return sound
end

local function createEatSound(parent)
	local sound = Instance.new("Sound")
	sound.Name = "EatSound"
	sound.SoundId = SoundManager.Sounds.Eat
	sound.Volume = 0.8
	sound.Looped = true
	sound.RollOffMaxDistance = 30
	sound.Parent = parent
	return sound
end

local function playRandomFart()
	if not fartSound then return end

	local randomId = SoundManager.Sounds.Fart
	fartSound.SoundId = randomId
	fartSound.PlaybackSpeed = math.random(80, 120) / 100
	fartSound:Play()
end

-- ============================================
-- SISTEMA DE CUERPO
-- ============================================

local function applyBodySize(multiplier)
	for _, part in ipairs(bodyParts) do
		local originalSize = originalSizes[part]
		if originalSize then
			local newSize = Vector3.new(
				originalSize.X * multiplier,
				originalSize.Y,
				originalSize.Z * multiplier
			)
			part.Size = newSize
		end
	end

	-- Ajustar hombros y caderas según el tamaño
	if multiplier < 1.0 then
		-- Cuando está delgado: solo ajustar hombros (no caderas)
		if upperTorso and originalLeftShoulderC0 and originalRightShoulderC0 then
			local originalTorsoSize = originalSizes[upperTorso]
			if originalTorsoSize then
				local xOffset = (originalTorsoSize.X / 2) * (1 - multiplier)

				if leftShoulder then
					leftShoulder.C0 = originalLeftShoulderC0 * CFrame.new(xOffset, 0, 0)
				end
				if rightShoulder then
					rightShoulder.C0 = originalRightShoulderC0 * CFrame.new(-xOffset, 0, 0)
				end
			end
		end

		-- Caderas en posición original cuando está delgado
		if leftHip and originalLeftHipC0 then leftHip.C0 = originalLeftHipC0 end
		if rightHip and originalRightHipC0 then rightHip.C0 = originalRightHipC0 end
	elseif multiplier > 1.0 then
		-- Cuando está gordo: mover joints hacia afuera
		if upperTorso and originalLeftShoulderC0 and originalRightShoulderC0 then
			local originalTorsoSize = originalSizes[upperTorso]
			if originalTorsoSize then
				local xOffset = (originalTorsoSize.X / 2) * (multiplier - 1)

				if leftShoulder then
					leftShoulder.C0 = originalLeftShoulderC0 * CFrame.new(-xOffset, 0, 0)
				end
				if rightShoulder then
					rightShoulder.C0 = originalRightShoulderC0 * CFrame.new(xOffset, 0, 0)
				end
			end
		end

		if lowerTorso and originalLeftHipC0 and originalRightHipC0 then
			local originalTorsoSize = originalSizes[lowerTorso]
			if originalTorsoSize then
				local xOffset = (originalTorsoSize.X / 2) * (multiplier - 1)

				if leftHip then
					leftHip.C0 = originalLeftHipC0 * CFrame.new(-xOffset, 0, 0)
				end
				if rightHip then
					rightHip.C0 = originalRightHipC0 * CFrame.new(xOffset, 0, 0)
				end
			end
		end
	else
		-- multiplier == 1.0: restaurar posiciones originales
		if leftShoulder and originalLeftShoulderC0 then leftShoulder.C0 = originalLeftShoulderC0 end
		if rightShoulder and originalRightShoulderC0 then rightShoulder.C0 = originalRightShoulderC0 end
		if leftHip and originalLeftHipC0 then leftHip.C0 = originalLeftHipC0 end
		if rightHip and originalRightHipC0 then rightHip.C0 = originalRightHipC0 end
	end
end

local function setupBody()
	if not character then return false end

	bodyParts = {}
	originalSizes = {}

	if character:FindFirstChild("LeftUpperArm") then
		-- R15 Rig
		table.insert(bodyParts, character:WaitForChild("LeftUpperArm"))
		table.insert(bodyParts, character:WaitForChild("LeftLowerArm"))
		table.insert(bodyParts, character:WaitForChild("RightUpperArm"))
		table.insert(bodyParts, character:WaitForChild("RightLowerArm"))
		table.insert(bodyParts, character:WaitForChild("LeftUpperLeg"))
		table.insert(bodyParts, character:WaitForChild("LeftLowerLeg"))
		table.insert(bodyParts, character:WaitForChild("RightUpperLeg"))
		table.insert(bodyParts, character:WaitForChild("RightLowerLeg"))

		upperTorso = character:WaitForChild("UpperTorso")
		lowerTorso = character:WaitForChild("LowerTorso")
		table.insert(bodyParts, upperTorso)
		table.insert(bodyParts, lowerTorso)

		local leftUpperArm = character:WaitForChild("LeftUpperArm")
		local rightUpperArm = character:WaitForChild("RightUpperArm")
		leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
		rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")

		local leftUpperLeg = character:WaitForChild("LeftUpperLeg")
		local rightUpperLeg = character:WaitForChild("RightUpperLeg")
		leftHip = leftUpperLeg:FindFirstChild("LeftHip")
		rightHip = rightUpperLeg:FindFirstChild("RightHip")

		if leftShoulder then originalLeftShoulderC0 = leftShoulder.C0 end
		if rightShoulder then originalRightShoulderC0 = rightShoulder.C0 end
		if leftHip then originalLeftHipC0 = leftHip.C0 end
		if rightHip then originalRightHipC0 = rightHip.C0 end

	elseif character:FindFirstChild("Left Arm") then
		-- R6 Rig
		table.insert(bodyParts, character:WaitForChild("Left Arm"))
		table.insert(bodyParts, character:WaitForChild("Right Arm"))
		table.insert(bodyParts, character:WaitForChild("Left Leg"))
		table.insert(bodyParts, character:WaitForChild("Right Leg"))
		table.insert(bodyParts, character:WaitForChild("Torso"))

		local torso = character:WaitForChild("Torso")
		leftShoulder = torso:FindFirstChild("Left Shoulder")
		rightShoulder = torso:FindFirstChild("Right Shoulder")
		leftHip = torso:FindFirstChild("Left Hip")
		rightHip = torso:FindFirstChild("Right Hip")

		if leftShoulder then originalLeftShoulderC0 = leftShoulder.C0 end
		if rightShoulder then originalRightShoulderC0 = rightShoulder.C0 end
		if leftHip then originalLeftHipC0 = leftHip.C0 end
		if rightHip then originalRightHipC0 = rightHip.C0 end
	else
		warn("[FartController] No se pudo detectar el tipo de rig")
		return false
	end

	-- Guardar tamaños originales
	for _, part in ipairs(bodyParts) do
		originalSizes[part] = part.Size
	end

	-- Aplicar tamaño delgado inicial
	applyBodySize(thinMultiplier)

	-- Configurar efectos de pedo
	local fartParent = lowerTorso or character:FindFirstChild("Torso")
	if fartParent then
		if fartParticles then fartParticles:Destroy() end
		if fartSound then fartSound:Destroy() end

		fartParticles = createFartParticles(fartParent)
		fartSound = createFartSound(fartParent)
	end

	-- Configurar sonido de comer (en la cabeza)
	local head = character:FindFirstChild("Head")
	if head then
		if eatSound then eatSound:Destroy() end
		eatSound = createEatSound(head)
	end

	return true
end

-- ============================================
-- MECÁNICAS DE JUEGO
-- ============================================

local function stopPropelling()
	isPropelling = false

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if humanoidRootPart then
		for _, child in ipairs(humanoidRootPart:GetChildren()) do
			if child:IsA("BodyVelocity") then
				child:Destroy()
			end
		end
	end

	if fartParticles then
		fartParticles.Enabled = false
	end

	-- Registrar altura máxima en el servidor
	if maxHeightThisFlight > 0 then
		Remotes.RegisterHeight:InvokeServer(maxHeightThisFlight)
		maxHeightThisFlight = 0
	end
end

local function startPropelling()
	if isPropelling then return end
	if currentFatness <= thinMultiplier then return end
	if not isDataLoaded then return end

	isPropelling = true
	isEating = false
	lastFartTime = 0
	maxHeightThisFlight = 0

	if not bodyVelocity then
		bodyVelocity = Instance.new("BodyVelocity")
		bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
		bodyVelocity.Velocity = Vector3.new(0, 0, 0)
		bodyVelocity.Parent = humanoidRootPart
	end

	if fartParticles then
		fartParticles.Enabled = true
	end

	playRandomFart()
end

local function updatePropulsion()
	if not isPropelling then return end

	-- Si ya está delgado, detener propulsión
	if currentFatness <= thinMultiplier then
		currentFatness = thinMultiplier
		applyBodySize(currentFatness)
		stopPropelling()
		return
	end

	-- Calcular fuerza de propulsión
	local weightFactor = (currentFatness - thinMultiplier) / (playerStats.MaxFatness - thinMultiplier)
	local currentForce = playerStats.PropulsionForce * weightFactor

	if bodyVelocity then
		bodyVelocity.Velocity = Vector3.new(0, currentForce, 0)
	end

	-- Reproducir pedos periódicamente
	local currentTime = tick()
	if currentTime - lastFartTime >= fartInterval then
		playRandomFart()
		lastFartTime = currentTime
	end

	-- Ajustar intensidad de partículas
	if fartParticles then
		fartParticles.Rate = 15 + (weightFactor * 35)
	end

	-- Perder peso gradualmente (usando eficiencia del servidor)
	currentFatness = math.max(currentFatness - playerStats.FuelEfficiency, thinMultiplier)
	applyBodySize(currentFatness)

	-- Trackear altura
	if humanoidRootPart then
		currentHeight = humanoidRootPart.Position.Y
		if currentHeight > maxHeightThisFlight then
			maxHeightThisFlight = currentHeight
		end
	end
end

-- ============================================
-- SISTEMA DE COMIDA (simplificado por ahora)
-- ============================================

local function stopEating()
	isEating = false
	if eatSound and eatSound.Playing then
		eatSound:Stop()
	end
end

local function updateEating()
	-- Comer automáticamente si está en zona de comida
	if not currentFoodZone then
		if isEating then
			stopEating()
		end
		return
	end

	if isPropelling then
		if isEating then
			stopEating()
		end
		return
	end
	if not isDataLoaded then return end

	-- Iniciar sonido de comer si no está sonando
	if not isEating then
		isEating = true
		if eatSound and not eatSound.Playing then
			eatSound:Play()
		end
	end

	-- La comida determina la velocidad base
	-- El upgrade EatSpeed del jugador da un bonus multiplicador
	local baseSpeed = 0.00125 -- Velocidad mínima (ensalada)
	if currentFoodConfig and currentFoodConfig.FatnessPerSecond then
		baseSpeed = currentFoodConfig.FatnessPerSecond
	end

	-- EatSpeed upgrade da bonus: cada nivel aumenta 25% la velocidad
	local eatSpeedBonus = 1 + (playerStats.EatSpeed - 0.08) * 3 -- 0.08 es el base
	local eatSpeed = baseSpeed * math.max(1, eatSpeedBonus)

	if currentFatness < playerStats.MaxFatness then
		currentFatness = math.min(currentFatness + eatSpeed, playerStats.MaxFatness)
		applyBodySize(currentFatness)

		-- Ejecutar animacion de comer en loop mientras come (con icono de la comida)
		if _G.PlayEatingAnimation then
			local foodIcon = currentFoodConfig and currentFoodConfig.Icon or "🍔"
			_G.PlayEatingAnimation(nil, foodIcon)
		end
	else
		-- Ya está lleno, detener sonido
		if eatSound and eatSound.Playing then
			eatSound:Stop()
		end
	end
end

-- ============================================
-- INPUT (Keyboard, Console, Mobile)
-- ============================================

-- Helper to check if input is a jump/fart button
local function isFartInput(input)
	return input.KeyCode == Enum.KeyCode.Space          -- Keyboard
		or input.KeyCode == Enum.KeyCode.ButtonA        -- Xbox / Generic gamepad (also PlayStation X)
end

-- Keyboard & Gamepad: Listen to jump buttons
-- NOTE: We intentionally DON'T check gameProcessed because we want to
-- catch the jump input even when Roblox processes it for jumping
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if isFartInput(input) then
		startPropelling()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if isFartInput(input) then
		stopPropelling()
	end
end)

-- Mobile: Touch anywhere on screen to fart (hold to propel)
local isTouchDevice = UserInputService.TouchEnabled

if isTouchDevice then
	local touchHolding = false

	UserInputService.TouchStarted:Connect(function(touch, gameProcessed)
		if gameProcessed then return end
		touchHolding = true
		startPropelling()
	end)

	UserInputService.TouchEnded:Connect(function(touch, gameProcessed)
		if touchHolding then
			touchHolding = false
			stopPropelling()
		end
	end)
end

-- ============================================
-- GAME LOOP
-- ============================================

RunService.RenderStepped:Connect(function()
	-- Comer es automático cuando está en zona de comida
	updateEating()

	if isPropelling then
		updatePropulsion()
	end

	-- Seguridad: si está delgado, asegurar que todo esté desactivado
	if currentFatness <= thinMultiplier then
		if bodyVelocity then
			bodyVelocity:Destroy()
			bodyVelocity = nil
		end
		if fartParticles and fartParticles.Enabled then
			fartParticles.Enabled = false
		end
		isPropelling = false
	end

	-- Actualizar UI
	if _G.GameHUD then
		_G.GameHUD.UpdateFatness(currentFatness, playerStats.MaxFatness)

		if humanoidRootPart then
			_G.GameHUD.UpdateHeight(humanoidRootPart.Position.Y)
		end
	end
end)

-- ============================================
-- COMUNICACIÓN CON SERVIDOR
-- ============================================

local function onDataLoaded(data)
	if not data then return end

	print("[FartController] Datos recibidos del servidor")

	if data.UpgradeValues then
		playerStats.MaxFatness = data.UpgradeValues.MaxFatness
		playerStats.EatSpeed = data.UpgradeValues.EatSpeed
		playerStats.PropulsionForce = data.UpgradeValues.PropulsionForce
		playerStats.FuelEfficiency = data.UpgradeValues.FuelEfficiency
	end

	if data.Config and data.Config.Fatness then
		thinMultiplier = data.Config.Fatness.ThinMultiplier
	end

	-- Cargar cosmético equipado
	if data.EquippedCosmeticConfig then
		equippedCosmeticConfig = data.EquippedCosmeticConfig
		updateFartParticleColors()
		print("[FartController] Cosmético cargado:", equippedCosmeticConfig.Name or "Default")
	end

	isDataLoaded = true
end

local function onDataUpdated(data)
	if not data then return end

	-- Solicitar valores actualizados
	local result = Remotes.GetPlayerData:InvokeServer()
	if result and result.UpgradeValues then
		playerStats.MaxFatness = result.UpgradeValues.MaxFatness
		playerStats.EatSpeed = result.UpgradeValues.EatSpeed
		playerStats.PropulsionForce = result.UpgradeValues.PropulsionForce
		playerStats.FuelEfficiency = result.UpgradeValues.FuelEfficiency
	end

	-- Actualizar cosmético si cambió
	if result and result.EquippedCosmeticConfig then
		local newCosmetic = result.EquippedCosmeticConfig
		if not equippedCosmeticConfig or equippedCosmeticConfig.Name ~= newCosmetic.Name then
			equippedCosmeticConfig = newCosmetic
			updateFartParticleColors()
			print("[FartController] Cosmético actualizado:", equippedCosmeticConfig.Name or "Default")
		end
	end
end

Remotes.OnDataLoaded.OnClientEvent:Connect(onDataLoaded)
Remotes.OnDataUpdated.OnClientEvent:Connect(onDataUpdated)

-- ============================================
-- SISTEMA DE ZONAS DE COMIDA
-- ============================================

local function onFoodZoneEnter(foodType, foodConfig, isUnlocked)
	-- Siempre guardar la zona física donde está el jugador
	currentPhysicalZone = foodType
	currentPhysicalConfig = foodConfig

	-- Solo permitir comer si la comida está desbloqueada
	if isUnlocked then
		currentFoodZone = foodType
		currentFoodConfig = foodConfig
		print("[FartController] Entrando a zona de comida (desbloqueada):", foodType)
	else
		-- No establecer la zona activa si no está desbloqueada
		currentFoodZone = nil
		currentFoodConfig = nil
		print("[FartController] Zona de comida bloqueada:", foodType)
	end
end

local function onFoodZoneExit(foodType)
	-- Limpiar zona física
	if currentPhysicalZone == foodType then
		currentPhysicalZone = nil
		currentPhysicalConfig = nil
	end

	-- Limpiar zona activa si corresponde
	if currentFoodZone == foodType then
		currentFoodZone = nil
		currentFoodConfig = nil
		stopEating()
	end
	print("[FartController] Saliendo de zona de comida:", foodType)
end

-- Cuando el jugador compra una comida mientras está parado en esa zona
local function onFoodPurchased(foodType, success)
	if success and currentPhysicalZone == foodType and currentPhysicalConfig then
		-- Ahora puede comer en esta zona
		currentFoodZone = foodType
		currentFoodConfig = currentPhysicalConfig
		print("[FartController] Comida comprada, ahora puedes comer:", foodType)
	end
end

-- Esperar a que existan los eventos de comida
task.spawn(function()
	local OnFoodZoneEnter = Remotes:WaitForChild("OnFoodZoneEnter", 10)
	local OnFoodZoneExit = Remotes:WaitForChild("OnFoodZoneExit", 10)
	local OnFoodPurchased = Remotes:WaitForChild("OnFoodPurchased", 10)

	if OnFoodZoneEnter then
		OnFoodZoneEnter.OnClientEvent:Connect(onFoodZoneEnter)
	end
	if OnFoodZoneExit then
		OnFoodZoneExit.OnClientEvent:Connect(onFoodZoneExit)
	end
	if OnFoodPurchased then
		OnFoodPurchased.OnClientEvent:Connect(onFoodPurchased)
	end
end)

-- ============================================
-- SETUP PERSONAJE
-- ============================================

local function onCharacterAdded(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	isEating = false
	isPropelling = false
	currentFatness = thinMultiplier
	maxHeightThisFlight = 0

	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end

	if fartParticles then
		fartParticles:Destroy()
		fartParticles = nil
	end
	if fartSound then
		fartSound:Destroy()
		fartSound = nil
	end
	if eatSound then
		eatSound:Destroy()
		eatSound = nil
	end

	task.wait(0.5)
	setupBody()
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Setup inicial si ya tiene personaje
if player.Character then
	onCharacterAdded(player.Character)
end

-- ============================================
-- FOOD PARCELS INTEGRATION
-- ============================================

-- Funcion llamada cuando se recoge un item de parcela
local function applyFoodParcelGasBonus(gasBonus)
	if not isDataLoaded then return end

	-- Calcular el bonus real (porcentaje del max fatness)
	local actualBonus = gasBonus * playerStats.MaxFatness

	-- Aplicar gas (sin exceder el maximo)
	currentFatness = math.min(currentFatness + actualBonus, playerStats.MaxFatness)
	applyBodySize(currentFatness)

	-- Efecto de sonido de comer rapido
	SoundManager.playEat(0.3)
end

-- Registrar la funcion globalmente para que FoodParcelsClient pueda llamarla
_G.FoodParcelGasBonus = applyFoodParcelGasBonus

print("[FartController] Controlador inicializado")
