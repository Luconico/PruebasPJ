local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Variables de estado
local isGrowing = false
local growSpeed = 0.08 -- Velocidad de crecimiento
local thinMultiplier = 0.5 -- Multiplicador para estar delgado (50% del tamaño normal)
local muscularMultiplier = 2.0 -- Multiplicador para estar musculoso (200% del tamaño normal)
local currentGrowth = thinMultiplier -- Empieza delgado

-- Partes del cuerpo y sus tamaños originales
local bodyParts = {}
local originalSizes = {}

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

		table.insert(bodyParts, character:WaitForChild("UpperTorso"))
		table.insert(bodyParts, character:WaitForChild("LowerTorso"))

	elseif character:FindFirstChild("Left Arm") then
		-- R6 Rig
		table.insert(bodyParts, character:WaitForChild("Left Arm"))
		table.insert(bodyParts, character:WaitForChild("Right Arm"))
		table.insert(bodyParts, character:WaitForChild("Left Leg"))
		table.insert(bodyParts, character:WaitForChild("Right Leg"))
		table.insert(bodyParts, character:WaitForChild("Torso"))
	else
		warn("No se pudo detectar el tipo de rig")
		return false
	end

	-- Guardar tamaños originales
	for _, part in ipairs(bodyParts) do
		originalSizes[part] = part.Size
	end

	-- Aplicar tamaño delgado inicial
	applyThinBody()

	return true
end

-- Función para aplicar cuerpo delgado
local function applyThinBody()
	for _, part in ipairs(bodyParts) do
		local originalSize = originalSizes[part]
		if originalSize then
			-- Hacer delgado en X y Z (ancho y profundidad)
			-- Y (altura) se mantiene casi igual
			local newSize = Vector3.new(
				originalSize.X * thinMultiplier,
				originalSize.Y, -- Mantener altura
				originalSize.Z * thinMultiplier
			)
			part.Size = newSize
		end
	end
end

-- Función para iniciar el crecimiento
local function startGrowing()
	if isGrowing then return end

	isGrowing = true
	currentGrowth = thinMultiplier
end

-- Función para actualizar el crecimiento muscular
local function updateGrowth()
	if not isGrowing then return end

	if currentGrowth < muscularMultiplier then
		currentGrowth = math.min(currentGrowth + growSpeed, muscularMultiplier)

		-- Hacer crecer todas las partes del cuerpo
		for _, part in ipairs(bodyParts) do
			local originalSize = originalSizes[part]
			if originalSize then
				-- Hacer crecer en X y Z (ancho y profundidad) para efecto muscular
				-- Y (altura) se mantiene constante
				local newSize = Vector3.new(
					originalSize.X * currentGrowth,
					originalSize.Y, -- Mantener altura constante
					originalSize.Z * currentGrowth
				)
				part.Size = newSize
			end
		end
	end
end

-- Función para detener y volver a delgado
local function stopGrowing()
	if not isGrowing then return end

	isGrowing = false

	local retractDuration = 0.4

	-- Volver al tamaño delgado con animación
	for _, part in ipairs(bodyParts) do
		local originalSize = originalSizes[part]
		if originalSize then
			local thinSize = Vector3.new(
				originalSize.X * thinMultiplier,
				originalSize.Y,
				originalSize.Z * thinMultiplier
			)

			local tween = TweenService:Create(
				part,
				TweenInfo.new(retractDuration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
				{Size = thinSize}
			)
			tween:Play()
		end
	end

	currentGrowth = thinMultiplier
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

-- Loop para actualizar el crecimiento progresivamente
RunService.RenderStepped:Connect(function()
	if isGrowing then
		updateGrowth()
	end
end)

-- Manejar respawn del personaje
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")

	isGrowing = false
	currentGrowth = thinMultiplier

	task.wait(0.5)
	setupBody()
end)

-- Configuración inicial
setupBody()
