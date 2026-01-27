local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Variables de estado
local isGrowing = false
local isShrinking = false
local growSpeed = 0.08 -- Velocidad de crecimiento
local shrinkSpeed = 0.06 -- Velocidad de adelgazamiento
local thinMultiplier = 0.5 -- Multiplicador para estar delgado (50% del tamaño normal)
local muscularMultiplier = 3.0 -- Multiplicador para estar musculoso (200% del tamaño normal)
local currentGrowth = thinMultiplier -- Empieza delgado

-- Partes del cuerpo y sus tamaños originales
local bodyParts = {}
local originalSizes = {}

-- Motors y sus C0 originales (para ajustar hombros y caderas)
local leftShoulder, rightShoulder
local leftHip, rightHip
local originalLeftShoulderC0, originalRightShoulderC0
local originalLeftHipC0, originalRightHipC0
local upperTorso, lowerTorso

-- Función para configurar las partes del cuerpo
local function setupBody()
	bodyParts = {}
	originalSizes = {}

	if character:FindFirstChild("LeftUpperArm") then
		-- R15 Rig - Agregar todas las partes musculares
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

		-- Obtener los motors de los hombros
		local leftUpperArm = character:WaitForChild("LeftUpperArm")
		local rightUpperArm = character:WaitForChild("RightUpperArm")
		leftShoulder = leftUpperArm:FindFirstChild("LeftShoulder")
		rightShoulder = rightUpperArm:FindFirstChild("RightShoulder")

		-- Obtener los motors de las caderas
		local leftUpperLeg = character:WaitForChild("LeftUpperLeg")
		local rightUpperLeg = character:WaitForChild("RightUpperLeg")
		leftHip = leftUpperLeg:FindFirstChild("LeftHip")
		rightHip = rightUpperLeg:FindFirstChild("RightHip")

		-- Guardar C0 originales
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
		warn("No se pudo detectar el tipo de rig")
		return false
	end

	-- Guardar tamaños originales
	for _, part in ipairs(bodyParts) do
		originalSizes[part] = part.Size
	end

	-- Aplicar tamaño delgado inicial
	applyBodySize(thinMultiplier)

	return true
end

-- Función para aplicar tamaño al cuerpo
local function applyBodySize(multiplier)
	for _, part in ipairs(bodyParts) do
		local originalSize = originalSizes[part]
		if originalSize then
			-- Hacer delgado/musculoso en X y Z (ancho y profundidad)
			-- Y (altura) se mantiene casi igual
			local newSize = Vector3.new(
				originalSize.X * multiplier,
				originalSize.Y, -- Mantener altura
				originalSize.Z * multiplier
			)
			part.Size = newSize
		end
	end

	-- Ajustar los motors de los hombros para que los brazos sigan conectados
	if upperTorso and originalLeftShoulderC0 and originalRightShoulderC0 then
		local originalTorsoSize = originalSizes[upperTorso]
		if originalTorsoSize then
			-- Calcular cuánto se ha reducido el torso en X
			local xScale = multiplier
			local xOffset = (originalTorsoSize.X / 2) * (1 - xScale)

			-- Ajustar hombros: moverlos hacia dentro cuando está delgado
			if leftShoulder then
				leftShoulder.C0 = originalLeftShoulderC0 * CFrame.new(xOffset, 0, 0)
			end
			if rightShoulder then
				rightShoulder.C0 = originalRightShoulderC0 * CFrame.new(-xOffset, 0, 0)
			end
		end
	end

	-- Ajustar los motors de las caderas SOLO cuando está en tamaño normal (1.0) o más grande
	if multiplier >= 1.0 and lowerTorso and originalLeftHipC0 and originalRightHipC0 then
		local originalTorsoSize = originalSizes[lowerTorso]
		if originalTorsoSize then
			-- Calcular el offset basado en cuánto ha crecido desde el tamaño normal
			local xScale = multiplier
			local xOffset = (originalTorsoSize.X / 2) * (xScale - 1)

			if leftHip then
				leftHip.C0 = originalLeftHipC0 * CFrame.new(-xOffset, 0, 0)
			end
			if rightHip then
				rightHip.C0 = originalRightHipC0 * CFrame.new(xOffset, 0, 0)
			end
		end
	elseif multiplier < 1.0 and originalLeftHipC0 and originalRightHipC0 then
		-- Cuando está delgado, mantener las caderas en su posición original
		if leftHip then leftHip.C0 = originalLeftHipC0 end
		if rightHip then rightHip.C0 = originalRightHipC0 end
	end
end

-- Función para iniciar el crecimiento
local function startGrowing()
	if isGrowing then return end

	isGrowing = true
	isShrinking = false -- Detener adelgazamiento si estaba en proceso
end

-- Función para actualizar el crecimiento muscular
local function updateGrowth()
	if not isGrowing then return end

	if currentGrowth < muscularMultiplier then
		currentGrowth = math.min(currentGrowth + growSpeed, muscularMultiplier)
		applyBodySize(currentGrowth)
	end
end

-- Función para detener y comenzar a adelgazar gradualmente
local function stopGrowing()
	if not isGrowing then return end

	isGrowing = false
	isShrinking = true
end

-- Función para actualizar el adelgazamiento gradual
local function updateShrinking()
	if not isShrinking then return end

	if currentGrowth > thinMultiplier then
		currentGrowth = math.max(currentGrowth - shrinkSpeed, thinMultiplier)
		applyBodySize(currentGrowth)
	else
		-- Llegó al tamaño delgado, dejar de adelgazar
		isShrinking = false
		currentGrowth = thinMultiplier
	end
end

-- Conectar eventos de input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startGrowing()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stopGrowing()
	end
end)

-- Loop para actualizar el crecimiento/adelgazamiento progresivamente
RunService.RenderStepped:Connect(function()
	if isGrowing then
		updateGrowth()
	elseif isShrinking then
		updateShrinking()
	end
end)

-- Manejar respawn del personaje
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")

	isGrowing = false
	isShrinking = false
	currentGrowth = thinMultiplier

	task.wait(0.5)
	setupBody()
end)

-- Configuración inicial
setupBody()
