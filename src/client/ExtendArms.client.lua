local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Variables de estado
local isExtending = false
local originalWalkSpeed = humanoid.WalkSpeed
local extendSpeed = 0.12
local maxExtension = 10
local currentExtension = 0

-- Referencias a las partes del brazo
local leftUpperArm, leftLowerArm, leftHand
local rightUpperArm, rightLowerArm, rightHand
local leftShoulder, leftElbow, leftWrist
local rightShoulder, rightElbow, rightWrist

-- Tamaños originales
local leftUpperArmOriginalSize, leftLowerArmOriginalSize
local rightUpperArmOriginalSize, rightLowerArmOriginalSize

-- C0 originales
local originalLeftShoulderC0, originalLeftElbowC0, originalLeftWristC0
local originalRightShoulderC0, originalRightElbowC0, originalRightWristC0

-- Función para detectar y configurar el rig
local function setupRig()
	if character:FindFirstChild("LeftUpperArm") then
		-- R15 Rig
		leftUpperArm = character:WaitForChild("LeftUpperArm")
		leftLowerArm = character:WaitForChild("LeftLowerArm")
		leftHand = character:WaitForChild("LeftHand")

		rightUpperArm = character:WaitForChild("RightUpperArm")
		rightLowerArm = character:WaitForChild("RightLowerArm")
		rightHand = character:WaitForChild("RightHand")

		leftShoulder = leftUpperArm:WaitForChild("LeftShoulder")
		leftElbow = leftLowerArm:WaitForChild("LeftElbow")
		leftWrist = leftHand:WaitForChild("LeftWrist")

		rightShoulder = rightUpperArm:WaitForChild("RightShoulder")
		rightElbow = rightLowerArm:WaitForChild("RightElbow")
		rightWrist = rightHand:WaitForChild("RightWrist")

		-- Guardar tamaños originales
		leftUpperArmOriginalSize = leftUpperArm.Size
		leftLowerArmOriginalSize = leftLowerArm.Size
		rightUpperArmOriginalSize = rightUpperArm.Size
		rightLowerArmOriginalSize = rightLowerArm.Size

		-- Guardar C0 originales
		originalLeftShoulderC0 = leftShoulder.C0
		originalLeftElbowC0 = leftElbow.C0
		originalLeftWristC0 = leftWrist.C0

		originalRightShoulderC0 = rightShoulder.C0
		originalRightElbowC0 = rightElbow.C0
		originalRightWristC0 = rightWrist.C0

		return true

	elseif character:FindFirstChild("Left Arm") then
		-- R6 Rig
		leftUpperArm = character:WaitForChild("Left Arm")
		rightUpperArm = character:WaitForChild("Right Arm")

		local torso = character:WaitForChild("Torso")
		leftShoulder = torso:WaitForChild("Left Shoulder")
		rightShoulder = torso:WaitForChild("Right Shoulder")

		leftUpperArmOriginalSize = leftUpperArm.Size
		rightUpperArmOriginalSize = rightUpperArm.Size

		originalLeftShoulderC0 = leftShoulder.C0
		originalRightShoulderC0 = rightShoulder.C0

		return true
	else
		warn("No se pudo detectar el tipo de rig")
		return false
	end
end

-- Función para iniciar la extensión
local function startExtending()
	if isExtending then return end

	isExtending = true
	currentExtension = 0

	-- Anclar al personaje para inmovilizarlo completamente
	humanoidRootPart.Anchored = true

	-- Poner los brazos completamente rectos hacia adelante
	if leftElbow then
		-- R15: Poner brazo recto hacia adelante
		leftShoulder.C0 = originalLeftShoulderC0 * CFrame.Angles(math.rad(90), 0, 0)
		rightShoulder.C0 = originalRightShoulderC0 * CFrame.Angles(math.rad(90), 0, 0)

		-- Enderezar los codos
		leftElbow.C0 = originalLeftElbowC0
		rightElbow.C0 = originalRightElbowC0

		-- Mantener las muñecas rectas
		leftWrist.C0 = originalLeftWristC0
		rightWrist.C0 = originalRightWristC0
	else
		-- R6: Poner brazo recto hacia adelante
		leftShoulder.C0 = originalLeftShoulderC0 * CFrame.Angles(math.rad(90), 0, 0)
		rightShoulder.C0 = originalRightShoulderC0 * CFrame.Angles(math.rad(90), 0, 0)
	end
end

-- Función para actualizar la extensión de los brazos
local function updateExtension()
	if not isExtending then return end

	if currentExtension < maxExtension then
		currentExtension = math.min(currentExtension + extendSpeed, maxExtension)

		if leftElbow then
			-- R15: Alargar las partes del brazo proporcionalmente
			local upperArmGrowth = currentExtension * 0.5
			local lowerArmGrowth = currentExtension * 0.5

			-- Actualizar tamaños
			leftUpperArm.Size = Vector3.new(
				leftUpperArmOriginalSize.X,
				leftUpperArmOriginalSize.Y + upperArmGrowth,
				leftUpperArmOriginalSize.Z
			)

			leftLowerArm.Size = Vector3.new(
				leftLowerArmOriginalSize.X,
				leftLowerArmOriginalSize.Y + lowerArmGrowth,
				leftLowerArmOriginalSize.Z
			)

			rightUpperArm.Size = Vector3.new(
				rightUpperArmOriginalSize.X,
				rightUpperArmOriginalSize.Y + upperArmGrowth,
				rightUpperArmOriginalSize.Z
			)

			rightLowerArm.Size = Vector3.new(
				rightLowerArmOriginalSize.X,
				rightLowerArmOriginalSize.Y + lowerArmGrowth,
				rightLowerArmOriginalSize.Z
			)

			-- Ajustar C0 del codo para compensar el crecimiento del brazo superior
			leftElbow.C0 = originalLeftElbowC0 * CFrame.new(0, -(upperArmGrowth / 2), 0)
			rightElbow.C0 = originalRightElbowC0 * CFrame.new(0, -(upperArmGrowth / 2), 0)

			-- Ajustar C0 de la muñeca para compensar el crecimiento del brazo inferior
			leftWrist.C0 = originalLeftWristC0 * CFrame.new(0, -(lowerArmGrowth / 2), 0)
			rightWrist.C0 = originalRightWristC0 * CFrame.new(0, -(lowerArmGrowth / 2), 0)

		else
			-- R6: Alargar los brazos
			leftUpperArm.Size = Vector3.new(
				leftUpperArmOriginalSize.X,
				leftUpperArmOriginalSize.Y + currentExtension,
				leftUpperArmOriginalSize.Z
			)

			rightUpperArm.Size = Vector3.new(
				rightUpperArmOriginalSize.X,
				rightUpperArmOriginalSize.Y + currentExtension,
				rightUpperArmOriginalSize.Z
			)
		end
	end
end

-- Función para detener y retraer los brazos
local function stopExtending()
	if not isExtending then return end

	isExtending = false

	-- Restaurar tamaños con animación
	local retractDuration = 0.3

	if leftElbow then
		-- R15
		local leftUpperTween = TweenService:Create(
			leftUpperArm,
			TweenInfo.new(retractDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = leftUpperArmOriginalSize}
		)

		local leftLowerTween = TweenService:Create(
			leftLowerArm,
			TweenInfo.new(retractDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = leftLowerArmOriginalSize}
		)

		local rightUpperTween = TweenService:Create(
			rightUpperArm,
			TweenInfo.new(retractDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = rightUpperArmOriginalSize}
		)

		local rightLowerTween = TweenService:Create(
			rightLowerArm,
			TweenInfo.new(retractDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = rightLowerArmOriginalSize}
		)

		leftUpperTween:Play()
		leftLowerTween:Play()
		rightUpperTween:Play()
		rightLowerTween:Play()

		-- Restaurar motors
		leftShoulder.C0 = originalLeftShoulderC0
		rightShoulder.C0 = originalRightShoulderC0
		leftElbow.C0 = originalLeftElbowC0
		rightElbow.C0 = originalRightElbowC0
		leftWrist.C0 = originalLeftWristC0
		rightWrist.C0 = originalRightWristC0

	else
		-- R6
		local leftTween = TweenService:Create(
			leftUpperArm,
			TweenInfo.new(retractDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = leftUpperArmOriginalSize}
		)

		local rightTween = TweenService:Create(
			rightUpperArm,
			TweenInfo.new(retractDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = rightUpperArmOriginalSize}
		)

		leftTween:Play()
		rightTween:Play()

		leftShoulder.C0 = originalLeftShoulderC0
		rightShoulder.C0 = originalRightShoulderC0
	end

	-- Desanclar al personaje para que vuelva a moverse normalmente
	humanoidRootPart.Anchored = false

	currentExtension = 0
end

-- Conectar eventos de input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startExtending()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stopExtending()
	end
end)

-- Loop para actualizar la extensión progresivamente
RunService.RenderStepped:Connect(function()
	if isExtending then
		updateExtension()
	end
end)

-- Manejar respawn del personaje
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	originalWalkSpeed = humanoid.WalkSpeed

	isExtending = false
	currentExtension = 0

	task.wait(0.5)
	setupRig()
end)

-- Configuración inicial
setupRig()
