local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Variables de estado
local isGrowing = false
local growSpeed = 0.08 -- Velocidad de crecimiento por frame
local maxGrowth = 5 -- Multiplicador máximo de tamaño
local currentGrowth = 1 -- Empieza en 1 (tamaño normal)

-- Referencias a la cabeza y accesorios
local head
local neck
local originalHeadSize
local originalHeadMesh
local originalNeckC0
local hairAccessories = {}
local originalAccessorySizes = {}

-- Función para configurar la cabeza
local function setupHead()
	head = character:WaitForChild("Head")
	originalHeadSize = head.Size

	-- Buscar el motor del cuello
	local upperTorso = character:FindFirstChild("UpperTorso")
	local torso = character:FindFirstChild("Torso")

	if upperTorso then
		-- R15
		neck = upperTorso:FindFirstChild("Neck")
	elseif torso then
		-- R6
		neck = torso:FindFirstChild("Neck")
	end

	if neck then
		originalNeckC0 = neck.C0
	end

	-- Buscar si hay un mesh en la cabeza
	originalHeadMesh = head:FindFirstChildOfClass("SpecialMesh")

	-- Encontrar todos los accesorios de pelo
	hairAccessories = {}
	originalAccessorySizes = {}

	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			local handle = child:FindFirstChild("Handle")
			if handle then
				table.insert(hairAccessories, child)

				-- Guardar el tamaño original del handle
				originalAccessorySizes[child] = handle.Size
			end
		end
	end

	return true
end

-- Función para iniciar el crecimiento
local function startGrowing()
	if isGrowing then return end

	isGrowing = true
	currentGrowth = 1
end

-- Función para actualizar el crecimiento de la cabeza
local function updateGrowth()
	if not isGrowing then return end

	if currentGrowth < maxGrowth then
		currentGrowth = math.min(currentGrowth + growSpeed, maxGrowth)

		-- Hacer crecer la cabeza
		head.Size = originalHeadSize * currentGrowth

		-- Si hay un mesh, también escalarlo
		if originalHeadMesh then
			originalHeadMesh.Scale = Vector3.new(currentGrowth, currentGrowth, currentGrowth)
		end

		-- Ajustar el cuello para que la cabeza crezca hacia arriba
		if neck and originalNeckC0 then
			-- Calcular cuánto ha crecido la cabeza
			local growthAmount = (currentGrowth - 1) * originalHeadSize.Y

			-- Mover el C0 del cuello hacia arriba para compensar
			neck.C0 = originalNeckC0 * CFrame.new(0, growthAmount / 2, 0)
		end

		-- Escalar los accesorios (pelo, sombreros, etc.)
		for _, accessory in ipairs(hairAccessories) do
			local handle = accessory:FindFirstChild("Handle")
			if handle then
				local originalSize = originalAccessorySizes[accessory]
				if originalSize then
					handle.Size = originalSize * currentGrowth
				end

				-- Escalar el mesh del accesorio si tiene uno
				local mesh = handle:FindFirstChildOfClass("SpecialMesh")
				if mesh then
					mesh.Scale = mesh.Scale * (currentGrowth / (currentGrowth - growSpeed))
				end
			end
		end
	end
end

-- Función para detener y retraer la cabeza
local function stopGrowing()
	if not isGrowing then return end

	isGrowing = false

	local retractDuration = 0.3

	-- Restaurar tamaño con animación suave
	local headTween = TweenService:Create(
		head,
		TweenInfo.new(retractDuration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{Size = originalHeadSize}
	)

	headTween:Play()

	-- Si hay mesh, también restaurarlo
	if originalHeadMesh then
		local meshTween = TweenService:Create(
			originalHeadMesh,
			TweenInfo.new(retractDuration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{Scale = Vector3.new(1, 1, 1)}
		)
		meshTween:Play()
	end

	-- Restaurar el cuello
	if neck and originalNeckC0 then
		neck.C0 = originalNeckC0
	end

	-- Restaurar accesorios
	for _, accessory in ipairs(hairAccessories) do
		local handle = accessory:FindFirstChild("Handle")
		if handle then
			local originalSize = originalAccessorySizes[accessory]
			if originalSize then
				local handleTween = TweenService:Create(
					handle,
					TweenInfo.new(retractDuration, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
					{Size = originalSize}
				)
				handleTween:Play()
			end

			-- Restaurar mesh del accesorio
			local mesh = handle:FindFirstChildOfClass("SpecialMesh")
			if mesh then
				-- Restablecer el scale original (asumimos que era 1,1,1 o el valor original)
				-- Como no guardamos el scale original, lo recalculamos
				task.spawn(function()
					local steps = 20
					for i = 1, steps do
						if mesh then
							mesh.Scale = mesh.Scale * 0.95
						end
						task.wait(retractDuration / steps)
					end
					-- Asegurarse de que quede en el valor correcto al final
					if mesh then
						mesh.Scale = Vector3.new(1, 1, 1)
					end
				end)
			end
		end
	end

	currentGrowth = 1
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
	currentGrowth = 1

	task.wait(0.5)
	setupHead()
end)

-- Configuración inicial
setupHead()
