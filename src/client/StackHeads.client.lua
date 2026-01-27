local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Variables de estado
local isStacking = false
local stackDelay = 0.2 -- Tiempo entre cada clon (en segundos)
local lastStackTime = 0
local clonedHeads = {}
local clonedAccessories = {}

-- Referencias
local originalHead
local originalAccessories = {}

-- Función para configurar referencias
local function setup()
	originalHead = character:WaitForChild("Head")

	-- Encontrar todos los accesorios
	originalAccessories = {}
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			table.insert(originalAccessories, child)
		end
	end
end

-- Función para obtener la última cabeza en la pila
local function getTopHead()
	if #clonedHeads > 0 then
		return clonedHeads[#clonedHeads]
	else
		return originalHead
	end
end

-- Función para clonar la cabeza con sus accesorios
local function cloneHead()
	local topHead = getTopHead()

	-- Clonar la cabeza
	local newHead = originalHead:Clone()
	newHead.Name = "ClonedHead_" .. #clonedHeads
	newHead.CanCollide = false
	newHead.Anchored = false

	-- Limpiar scripts y objetos innecesarios del clon
	for _, child in ipairs(newHead:GetChildren()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			child:Destroy()
		end
	end

	-- Añadir al personaje ANTES de posicionarla
	newHead.Parent = character

	-- IMPORTANTE: Calcular la distancia para subir
	-- La mitad de la cabeza superior + la mitad de la nueva cabeza
	local offset = (topHead.Size.Y / 2) + (newHead.Size.Y / 2)

	-- Obtener la posición de la cabeza superior
	local topPosition = topHead.Position

	-- Posicionar la nueva cabeza ENCIMA (sumar en Y que es hacia arriba)
	newHead.Position = topPosition + Vector3.new(0, offset, 0)

	-- Mantener la misma rotación que la cabeza superior
	newHead.CFrame = CFrame.new(newHead.Position) * (topHead.CFrame - topHead.Position)

	-- Soldar la nueva cabeza a la superior
	local weldConstraint = Instance.new("WeldConstraint")
	weldConstraint.Part0 = topHead
	weldConstraint.Part1 = newHead
	weldConstraint.Parent = newHead

	-- Guardar la cabeza clonada
	table.insert(clonedHeads, newHead)

	-- Clonar todos los accesorios (pelo, sombreros, etc.)
	local currentHeadAccessories = {}
	for _, accessory in ipairs(originalAccessories) do
		local clonedAccessory = accessory:Clone()
		clonedAccessory.Name = accessory.Name .. "_Clone_" .. #clonedHeads

		-- Obtener el handle del accesorio
		local handle = clonedAccessory:FindFirstChild("Handle")
		if handle then
			handle.CanCollide = false

			-- Limpiar welds existentes
			for _, child in ipairs(handle:GetChildren()) do
				if child:IsA("Weld") or child:IsA("WeldConstraint") then
					child:Destroy()
				end
			end

			-- Crear un nuevo attachment si no existe
			local headAttachment = newHead:FindFirstChild("FaceFrontAttachment") or newHead:FindFirstChild("HatAttachment")
			local handleAttachment = handle:FindFirstChild("HairAttachment") or handle:FindFirstChild("HatAttachment")

			-- Soldar el accesorio a la nueva cabeza
			local weldConstraint = Instance.new("WeldConstraint")
			weldConstraint.Part0 = newHead
			weldConstraint.Part1 = handle
			weldConstraint.Parent = handle

			-- Posicionar el handle relativo a la nueva cabeza
			-- Copiar la posición relativa del accesorio original
			local originalHandle = accessory:FindFirstChild("Handle")
			if originalHandle then
				local relativePos = originalHead.CFrame:ToObjectSpace(originalHandle.CFrame)
				handle.CFrame = newHead.CFrame * relativePos
			end
		end

		clonedAccessory.Parent = character
		table.insert(currentHeadAccessories, clonedAccessory)
	end

	-- Guardar los accesorios clonados
	table.insert(clonedAccessories, currentHeadAccessories)
end

-- Función para eliminar todas las cabezas clonadas
local function clearClones()
	-- Eliminar todas las cabezas clonadas
	for _, head in ipairs(clonedHeads) do
		if head and head.Parent then
			head:Destroy()
		end
	end

	-- Eliminar todos los accesorios clonados
	for _, accessories in ipairs(clonedAccessories) do
		for _, accessory in ipairs(accessories) do
			if accessory and accessory.Parent then
				accessory:Destroy()
			end
		end
	end

	clonedHeads = {}
	clonedAccessories = {}
end

-- Función para iniciar el apilamiento
local function startStacking()
	if isStacking then return end

	isStacking = true
	lastStackTime = tick()

	-- Clonar inmediatamente la primera cabeza
	cloneHead()
end

-- Función para detener el apilamiento
local function stopStacking()
	if not isStacking then return end

	isStacking = false

	-- Eliminar todas las cabezas clonadas después de un pequeño delay
	task.wait(0.1)
	clearClones()
end

-- Conectar eventos de input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		startStacking()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stopStacking()
	end
end)

-- Loop para clonar cabezas periódicamente
RunService.RenderStepped:Connect(function()
	if isStacking then
		local currentTime = tick()
		if currentTime - lastStackTime >= stackDelay then
			cloneHead()
			lastStackTime = currentTime
		end
	end
end)

-- Manejar respawn del personaje
player.CharacterAdded:Connect(function(newCharacter)
	-- Limpiar clones antiguos
	clearClones()

	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")

	isStacking = false

	task.wait(0.5)
	setup()
end)

-- Configuración inicial
setup()
