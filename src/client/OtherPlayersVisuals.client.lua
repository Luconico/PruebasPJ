--[[
	OtherPlayersVisuals.client.lua
	Aplica efectos visuales (gordura, gas, comer) en los personajes de OTROS jugadores
	Recibe eventos retransmitidos por VisualRelay.server.lua
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if not Remotes then
	warn("[OtherPlayersVisuals] No se encontraron Remotes")
	return
end

-- ============================================
-- ESTADO POR JUGADOR
-- ============================================
-- { [Player] = { targetFatness, displayedFatness, bodyParts, originalSizes, joints, fartParticles, isEating, ... } }
local otherStates = {}

-- ============================================
-- HELPER: Inicializar body parts de un character ajeno
-- ============================================
local function initBodyParts(character)
	local data = {
		bodyParts = {},
		originalSizes = {},
		leftShoulder = nil,
		rightShoulder = nil,
		leftHip = nil,
		rightHip = nil,
		origLeftShoulderC0 = nil,
		origRightShoulderC0 = nil,
		origLeftHipC0 = nil,
		origRightHipC0 = nil,
		upperTorso = nil,
		lowerTorso = nil,
		leftElbow = nil,
		rightElbow = nil,
		origLeftElbowC0 = nil,
		origRightElbowC0 = nil,
		isR15 = false,
	}

	if character:FindFirstChild("LeftUpperArm") then
		-- R15
		data.isR15 = true
		local partNames = {
			"LeftUpperArm", "LeftLowerArm", "RightUpperArm", "RightLowerArm",
			"LeftUpperLeg", "LeftLowerLeg", "RightUpperLeg", "RightLowerLeg",
		}
		for _, name in ipairs(partNames) do
			local part = character:FindFirstChild(name)
			if part then
				table.insert(data.bodyParts, part)
			end
		end

		data.upperTorso = character:FindFirstChild("UpperTorso")
		data.lowerTorso = character:FindFirstChild("LowerTorso")
		if data.upperTorso then table.insert(data.bodyParts, data.upperTorso) end
		if data.lowerTorso then table.insert(data.bodyParts, data.lowerTorso) end

		local leftUpperArm = character:FindFirstChild("LeftUpperArm")
		local rightUpperArm = character:FindFirstChild("RightUpperArm")
		if leftUpperArm then data.leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder") end
		if rightUpperArm then data.rightShoulder = rightUpperArm:FindFirstChild("RightShoulder") end

		local leftUpperLeg = character:FindFirstChild("LeftUpperLeg")
		local rightUpperLeg = character:FindFirstChild("RightUpperLeg")
		if leftUpperLeg then data.leftHip = leftUpperLeg:FindFirstChild("LeftHip") end
		if rightUpperLeg then data.rightHip = rightUpperLeg:FindFirstChild("RightHip") end

		local leftLowerArm = character:FindFirstChild("LeftLowerArm")
		local rightLowerArm = character:FindFirstChild("RightLowerArm")
		if leftLowerArm then data.leftElbow = leftLowerArm:FindFirstChild("LeftElbow") end
		if rightLowerArm then data.rightElbow = rightLowerArm:FindFirstChild("RightElbow") end

	elseif character:FindFirstChild("Left Arm") then
		-- R6
		data.isR15 = false
		local partNames = {"Left Arm", "Right Arm", "Left Leg", "Right Leg", "Torso"}
		for _, name in ipairs(partNames) do
			local part = character:FindFirstChild(name)
			if part then
				table.insert(data.bodyParts, part)
			end
		end

		local torso = character:FindFirstChild("Torso")
		data.lowerTorso = torso
		data.upperTorso = torso
		if torso then
			data.leftShoulder = torso:FindFirstChild("Left Shoulder")
			data.rightShoulder = torso:FindFirstChild("Right Shoulder")
			data.leftHip = torso:FindFirstChild("Left Hip")
			data.rightHip = torso:FindFirstChild("Right Hip")
		end
	end

	-- Guardar tamaños y C0 originales
	for _, part in ipairs(data.bodyParts) do
		data.originalSizes[part] = part.Size
	end

	if data.leftShoulder then data.origLeftShoulderC0 = data.leftShoulder.C0 end
	if data.rightShoulder then data.origRightShoulderC0 = data.rightShoulder.C0 end
	if data.leftHip then data.origLeftHipC0 = data.leftHip.C0 end
	if data.rightHip then data.origRightHipC0 = data.rightHip.C0 end
	if data.leftElbow then data.origLeftElbowC0 = data.leftElbow.C0 end
	if data.rightElbow then data.origRightElbowC0 = data.rightElbow.C0 end

	return data
end

-- ============================================
-- APLICAR GORDURA A UN CHARACTER
-- ============================================
local function applyBodySizeToCharacter(bodyData, multiplier)
	for _, part in ipairs(bodyData.bodyParts) do
		local originalSize = bodyData.originalSizes[part]
		if originalSize then
			part.Size = Vector3.new(
				originalSize.X * multiplier,
				originalSize.Y,
				originalSize.Z * multiplier
			)
			part.CanCollide = false
		end
	end

	-- Ajustar joints (igual que FartController)
	local upperTorso = bodyData.upperTorso
	local lowerTorso = bodyData.lowerTorso

	if multiplier < 1.0 then
		if upperTorso and bodyData.origLeftShoulderC0 and bodyData.origRightShoulderC0 then
			local originalTorsoSize = bodyData.originalSizes[upperTorso]
			if originalTorsoSize then
				local xOffset = (originalTorsoSize.X / 2) * (1 - multiplier)
				if bodyData.leftShoulder then
					bodyData.leftShoulder.C0 = bodyData.origLeftShoulderC0 * CFrame.new(xOffset, 0, 0)
				end
				if bodyData.rightShoulder then
					bodyData.rightShoulder.C0 = bodyData.origRightShoulderC0 * CFrame.new(-xOffset, 0, 0)
				end
			end
		end
		if bodyData.leftHip and bodyData.origLeftHipC0 then bodyData.leftHip.C0 = bodyData.origLeftHipC0 end
		if bodyData.rightHip and bodyData.origRightHipC0 then bodyData.rightHip.C0 = bodyData.origRightHipC0 end

	elseif multiplier > 1.0 then
		if upperTorso and bodyData.origLeftShoulderC0 and bodyData.origRightShoulderC0 then
			local originalTorsoSize = bodyData.originalSizes[upperTorso]
			if originalTorsoSize then
				local xOffset = (originalTorsoSize.X / 2) * (multiplier - 1)
				if bodyData.leftShoulder then
					bodyData.leftShoulder.C0 = bodyData.origLeftShoulderC0 * CFrame.new(-xOffset, 0, 0)
				end
				if bodyData.rightShoulder then
					bodyData.rightShoulder.C0 = bodyData.origRightShoulderC0 * CFrame.new(xOffset, 0, 0)
				end
			end
		end
		if lowerTorso and bodyData.origLeftHipC0 and bodyData.origRightHipC0 then
			local originalTorsoSize = bodyData.originalSizes[lowerTorso]
			if originalTorsoSize then
				local xOffset = (originalTorsoSize.X / 2) * (multiplier - 1)
				if bodyData.leftHip then
					bodyData.leftHip.C0 = bodyData.origLeftHipC0 * CFrame.new(-xOffset, 0, 0)
				end
				if bodyData.rightHip then
					bodyData.rightHip.C0 = bodyData.origRightHipC0 * CFrame.new(xOffset, 0, 0)
				end
			end
		end
	else
		if bodyData.leftShoulder and bodyData.origLeftShoulderC0 then bodyData.leftShoulder.C0 = bodyData.origLeftShoulderC0 end
		if bodyData.rightShoulder and bodyData.origRightShoulderC0 then bodyData.rightShoulder.C0 = bodyData.origRightShoulderC0 end
		if bodyData.leftHip and bodyData.origLeftHipC0 then bodyData.leftHip.C0 = bodyData.origLeftHipC0 end
		if bodyData.rightHip and bodyData.origRightHipC0 then bodyData.rightHip.C0 = bodyData.origRightHipC0 end
	end
end

-- ============================================
-- CREAR PARTÍCULAS DE GAS PARA OTRO JUGADOR
-- ============================================
local function createFartParticlesForOther(parent, cosmeticId)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "OtherFartParticles"
	particles.Texture = "rbxasset://textures/particles/smoke_main.dds"

	-- Colores del cosmético o por defecto
	local colors = {
		Color3.fromRGB(140, 160, 80),
		Color3.fromRGB(100, 120, 50),
		Color3.fromRGB(80, 100, 40),
	}

	local cosmeticConfig = cosmeticId and Config.FartCosmetics[cosmeticId] or nil
	if cosmeticConfig and cosmeticConfig.Colors and #cosmeticConfig.Colors > 0 then
		colors = cosmeticConfig.Colors
	end

	local colorKeypoints = {}
	for i, color in ipairs(colors) do
		local t = (i - 1) / math.max(#colors - 1, 1)
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(t, color))
	end
	if #colorKeypoints == 1 then
		table.insert(colorKeypoints, ColorSequenceKeypoint.new(1, colors[1]))
	end

	particles.Color = ColorSequence.new(colorKeypoints)

	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0),
		NumberSequenceKeypoint.new(1, 0.3),
	})

	local sizeMin = 3
	local sizeMax = 8
	if cosmeticConfig and cosmeticConfig.ParticleSize then
		sizeMin = (cosmeticConfig.ParticleSize.Min or 0.5) * 3
		sizeMax = (cosmeticConfig.ParticleSize.Max or 2) * 4
	end

	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sizeMin),
		NumberSequenceKeypoint.new(0.3, sizeMax),
		NumberSequenceKeypoint.new(1, sizeMax * 1.2),
	})

	particles.Rate = 80
	particles.Lifetime = NumberRange.new(0.6, 1)
	particles.Speed = NumberRange.new(12, 20)
	particles.SpreadAngle = Vector2.new(50, 50)
	particles.Rotation = NumberRange.new(0, 360)
	particles.RotSpeed = NumberRange.new(-10, 10)
	particles.Acceleration = Vector3.new(0, 2, 0)
	particles.Drag = 2
	particles.EmissionDirection = Enum.NormalId.Back

	if cosmeticConfig and cosmeticConfig.Glow then
		particles.LightEmission = 0.5
	else
		particles.LightEmission = 0
	end
	particles.LightInfluence = 1
	particles.Enabled = true

	particles.Parent = parent
	return particles
end

-- ============================================
-- SONIDO DE PEDO PARA OTRO JUGADOR
-- ============================================
local function createFartSoundForOther(parent)
	local sound = Instance.new("Sound")
	sound.Name = "OtherFartSound"
	sound.Volume = 1
	sound.RollOffMaxDistance = 50
	sound.Parent = parent
	return sound
end

-- ============================================
-- ANIMACIÓN DE COMER PARA OTRO JUGADOR
-- ============================================
local function playEatingOnCharacter(character, foodIcon, state)
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
	local icon = foodIcon or "🍔"
	local armSpeed = 0.08
	local cycles = 4

	-- Helper para crear icono de comida en la mano
	local function createFoodInHand(hand)
		local existing = hand:FindFirstChild("FoodInHand")
		if existing then existing:Destroy() end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = "FoodInHand"
		billboard.Size = UDim2.new(1.5, 0, 1.5, 0)
		billboard.StudsOffset = Vector3.new(0, 0.3, 0)
		billboard.AlwaysOnTop = false
		billboard.Parent = hand

		local label = Instance.new("TextLabel")
		label.Name = "Icon"
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = icon
		label.TextScaled = true
		label.Parent = billboard

		return billboard
	end

	local function removeFoodFromHand(hand)
		local existing = hand:FindFirstChild("FoodInHand")
		if existing then existing:Destroy() end
	end

	task.spawn(function()
		while state.isEating and character and character.Parent do
			if isR15 then
				local rightUpperArm = character:FindFirstChild("RightUpperArm")
				local leftUpperArm = character:FindFirstChild("LeftUpperArm")
				local rightLowerArm = character:FindFirstChild("RightLowerArm")
				local leftLowerArm = character:FindFirstChild("LeftLowerArm")
				local rightHand = character:FindFirstChild("RightHand")
				local leftHand = character:FindFirstChild("LeftHand")

				if not rightUpperArm or not leftUpperArm then break end

				local rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")
				local leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
				local rightElbow = rightLowerArm and rightLowerArm:FindFirstChild("RightElbow")
				local leftElbow = leftLowerArm and leftLowerArm:FindFirstChild("LeftElbow")

				if not rightShoulder or not leftShoulder then break end

				local origRS = rightShoulder.C0
				local origLS = leftShoulder.C0
				local origRE = rightElbow and rightElbow.C0
				local origLE = leftElbow and leftElbow.C0

				local rightShoulderEat = origRS * CFrame.Angles(math.rad(70), math.rad(30), math.rad(-20))
				local leftShoulderEat = origLS * CFrame.Angles(math.rad(70), math.rad(-30), math.rad(20))
				local rightElbowEat = origRE and (origRE * CFrame.Angles(math.rad(90), 0, 0))
				local leftElbowEat = origLE and (origLE * CFrame.Angles(math.rad(90), 0, 0))

				for i = 1, cycles do
					if not state.isEating then break end

					-- Mano derecha
					if rightHand then createFoodInHand(rightHand) end
					TweenService:Create(rightShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = rightShoulderEat}):Play()
					if rightElbow and rightElbowEat then
						TweenService:Create(rightElbow, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = rightElbowEat}):Play()
					end
					task.wait(armSpeed)
					if rightHand then removeFoodFromHand(rightHand) end

					TweenService:Create(rightShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = origRS}):Play()
					if rightElbow and origRE then
						TweenService:Create(rightElbow, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = origRE}):Play()
					end

					if not state.isEating then break end

					-- Mano izquierda
					if leftHand then createFoodInHand(leftHand) end
					TweenService:Create(leftShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = leftShoulderEat}):Play()
					if leftElbow and leftElbowEat then
						TweenService:Create(leftElbow, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = leftElbowEat}):Play()
					end
					task.wait(armSpeed)
					if leftHand then removeFoodFromHand(leftHand) end

					TweenService:Create(leftShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = origLS}):Play()
					if leftElbow and origLE then
						TweenService:Create(leftElbow, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = origLE}):Play()
					end
					task.wait(armSpeed * 0.5)
				end

				-- Restaurar
				task.wait(armSpeed)
				rightShoulder.C0 = origRS
				leftShoulder.C0 = origLS
				if rightElbow and origRE then rightElbow.C0 = origRE end
				if leftElbow and origLE then leftElbow.C0 = origLE end
				if rightHand then removeFoodFromHand(rightHand) end
				if leftHand then removeFoodFromHand(leftHand) end

			else
				-- R6
				local torso = character:FindFirstChild("Torso")
				local rightArm = character:FindFirstChild("Right Arm")
				local leftArm = character:FindFirstChild("Left Arm")
				if not torso then break end

				local rightShoulder = torso:FindFirstChild("Right Shoulder")
				local leftShoulder = torso:FindFirstChild("Left Shoulder")
				if not rightShoulder or not leftShoulder then break end

				local origRC0 = rightShoulder.C0
				local origLC0 = leftShoulder.C0
				local rightEat = origRC0 * CFrame.Angles(math.rad(90), math.rad(40), 0)
				local leftEat = origLC0 * CFrame.Angles(math.rad(-90), math.rad(40), 0)

				for i = 1, cycles do
					if not state.isEating then break end

					if rightArm then createFoodInHand(rightArm) end
					TweenService:Create(rightShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = rightEat}):Play()
					task.wait(armSpeed)
					if rightArm then removeFoodFromHand(rightArm) end
					TweenService:Create(rightShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = origRC0}):Play()

					if not state.isEating then break end

					if leftArm then createFoodInHand(leftArm) end
					TweenService:Create(leftShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {C0 = leftEat}):Play()
					task.wait(armSpeed)
					if leftArm then removeFoodFromHand(leftArm) end
					TweenService:Create(leftShoulder, TweenInfo.new(armSpeed, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {C0 = origLC0}):Play()
					task.wait(armSpeed * 0.5)
				end

				task.wait(armSpeed)
				rightShoulder.C0 = origRC0
				leftShoulder.C0 = origLC0
				if rightArm then removeFoodFromHand(rightArm) end
				if leftArm then removeFoodFromHand(leftArm) end
			end

			-- Pausa entre ciclos de animación
			task.wait(0.2)
		end
	end)
end

-- ============================================
-- GESTIÓN DE ESTADO
-- ============================================
local function ensureState(sourcePlayer)
	if not otherStates[sourcePlayer] then
		otherStates[sourcePlayer] = {
			targetFatness = 0.5,
			displayedFatness = 0.5,
			bodyData = nil,
			fartParticles = nil,
			fartSound = nil,
			fartSoundThread = nil,
			isEating = false,
			isPropelling = false,
			cosmeticId = nil,
		}
	end
	return otherStates[sourcePlayer]
end

local function ensureBodyData(sourcePlayer, state)
	local character = sourcePlayer.Character
	if not character or not character.Parent then return nil end

	if not state.bodyData then
		state.bodyData = initBodyParts(character)
		-- Aplicar gordura inicial
		if state.displayedFatness ~= 1.0 then
			applyBodySizeToCharacter(state.bodyData, state.displayedFatness)
		end
	end

	return state.bodyData
end

-- ============================================
-- EVENTO: GORDURA
-- ============================================
local VisualFatnessUpdate = Remotes:WaitForChild("VisualFatnessUpdate", 10)
if VisualFatnessUpdate then
	VisualFatnessUpdate.OnClientEvent:Connect(function(sourcePlayer, fatness)
		if sourcePlayer == localPlayer then return end

		local state = ensureState(sourcePlayer)
		state.targetFatness = fatness
	end)
end

-- ============================================
-- EVENTO: PROPULSIÓN (GAS)
-- ============================================
local VisualPropulsionState = Remotes:WaitForChild("VisualPropulsionState", 10)
if VisualPropulsionState then
	VisualPropulsionState.OnClientEvent:Connect(function(sourcePlayer, isActive, cosmeticId)
		if sourcePlayer == localPlayer then return end

		local character = sourcePlayer.Character
		if not character then return end

		local state = ensureState(sourcePlayer)
		state.isPropelling = isActive
		state.cosmeticId = cosmeticId

		if isActive then
			-- Crear partículas si no existen
			local parent = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
			if parent then
				-- Limpiar partículas anteriores
				if state.fartParticles then
					state.fartParticles:Destroy()
					state.fartParticles = nil
				end
				state.fartParticles = createFartParticlesForOther(parent, cosmeticId)
			end

			-- Crear sonido de pedo
			if parent then
				if state.fartSound then
					state.fartSound:Destroy()
					state.fartSound = nil
				end
				state.fartSound = createFartSoundForOther(parent)

				-- Loop de sonido de pedos
				if state.fartSoundThread then
					task.cancel(state.fartSoundThread)
				end
				state.fartSoundThread = task.spawn(function()
					while state.isPropelling and state.fartSound and state.fartSound.Parent do
						state.fartSound.SoundId = SoundManager.Sounds.Fart
						state.fartSound.PlaybackSpeed = math.random(80, 120) / 100
						state.fartSound:Play()
						task.wait(0.3)
					end
				end)
			end
		else
			-- Desactivar partículas
			if state.fartParticles then
				state.fartParticles.Enabled = false
			end
			-- Parar sonido
			if state.fartSoundThread then
				task.cancel(state.fartSoundThread)
				state.fartSoundThread = nil
			end
			if state.fartSound then
				state.fartSound:Stop()
			end
		end
	end)
end

-- ============================================
-- EVENTO: COMER
-- ============================================
local VisualEatingState = Remotes:WaitForChild("VisualEatingState", 10)
if VisualEatingState then
	VisualEatingState.OnClientEvent:Connect(function(sourcePlayer, isEating, foodIcon)
		if sourcePlayer == localPlayer then return end

		local character = sourcePlayer.Character
		if not character then return end

		local state = ensureState(sourcePlayer)

		if isEating then
			state.isEating = true
			playEatingOnCharacter(character, foodIcon, state)
		else
			state.isEating = false
		end
	end)
end

-- ============================================
-- RENDER LOOP: Interpolación suave de gordura
-- ============================================
RunService.RenderStepped:Connect(function()
	for sourcePlayer, state in pairs(otherStates) do
		if not sourcePlayer.Parent then continue end

		local character = sourcePlayer.Character
		if not character or not character.Parent then continue end

		-- Interpolar gordura suavemente
		if math.abs(state.displayedFatness - state.targetFatness) > 0.005 then
			state.displayedFatness = state.displayedFatness + (state.targetFatness - state.displayedFatness) * 0.1

			local bodyData = ensureBodyData(sourcePlayer, state)
			if bodyData then
				applyBodySizeToCharacter(bodyData, state.displayedFatness)
			end
		end
	end
end)

-- ============================================
-- LIMPIEZA: Player Leave
-- ============================================
Players.PlayerRemoving:Connect(function(leavingPlayer)
	local state = otherStates[leavingPlayer]
	if state then
		if state.fartParticles then state.fartParticles:Destroy() end
		if state.fartSound then state.fartSound:Destroy() end
		if state.fartSoundThread then task.cancel(state.fartSoundThread) end
		state.isEating = false
		otherStates[leavingPlayer] = nil
	end
end)

-- ============================================
-- CHARACTER RESPAWN: Reinicializar body data
-- ============================================
local function onOtherCharacterAdded(otherPlayer)
	local state = otherStates[otherPlayer]
	if not state then return end

	-- Esperar a que el character cargue
	task.wait(0.5)

	-- Limpiar datos anteriores
	if state.fartParticles then
		state.fartParticles:Destroy()
		state.fartParticles = nil
	end
	if state.fartSound then
		state.fartSound:Destroy()
		state.fartSound = nil
	end
	if state.fartSoundThread then
		task.cancel(state.fartSoundThread)
		state.fartSoundThread = nil
	end
	state.bodyData = nil

	-- Re-inicializar body parts con el nuevo character
	local character = otherPlayer.Character
	if character then
		state.bodyData = initBodyParts(character)
		-- Re-aplicar última gordura conocida
		if state.displayedFatness ~= 1.0 then
			applyBodySizeToCharacter(state.bodyData, state.displayedFatness)
		end
		-- Re-crear partículas si estaba propulsándose
		if state.isPropelling then
			local parent = character:FindFirstChild("LowerTorso") or character:FindFirstChild("Torso")
			if parent then
				state.fartParticles = createFartParticlesForOther(parent, state.cosmeticId)
				state.fartSound = createFartSoundForOther(parent)
			end
		end
	end
end

-- Conectar CharacterAdded de todos los jugadores
for _, otherPlayer in ipairs(Players:GetPlayers()) do
	if otherPlayer ~= localPlayer then
		otherPlayer.CharacterAdded:Connect(function()
			onOtherCharacterAdded(otherPlayer)
		end)
	end
end

Players.PlayerAdded:Connect(function(newPlayer)
	if newPlayer ~= localPlayer then
		newPlayer.CharacterAdded:Connect(function()
			onOtherCharacterAdded(newPlayer)
		end)
	end
end)

print("[OtherPlayersVisuals] Inicializado")
