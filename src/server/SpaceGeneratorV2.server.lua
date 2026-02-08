print("🚀🚀🚀 [SpaceGenerator] SCRIPT INICIADO 🚀🚀🚀")

local Workspace = game:GetService("Workspace")

-- ========== CONFIGURACIÓN DE ESTRUCTURAS ESPACIALES ==========
local SPACE_CONFIG = {
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Space1",
		BlockCount = 38,
		XReduction = 2.5,
		YScalePercentage = 35,
	},
}

-- ========== MATERIALES ESPACIALES (todos opacos/visibles) ==========
local SPACE_MATERIALS = {
	Enum.Material.Neon,           -- Brillante como estrellas (opaco, brilla)
	Enum.Material.Foil,           -- Metálico reflectante espacial
	Enum.Material.Metal,          -- Metal oscuro de nave espacial
	Enum.Material.Marble,         -- Mármol como superficie planetaria
	Enum.Material.Neon,           -- Nebulosa brillante
	Enum.Material.Granite,        -- Roca de asteroide
	Enum.Material.SmoothPlastic,  -- Superficie limpia futurista
	Enum.Material.Foil,           -- Reflejo estelar
}

-- Colores espaciales para acompañar los materiales
local SPACE_COLORS = {
	Color3.fromRGB(10, 0, 40),      -- Negro-violeta profundo (vacío)
	Color3.fromRGB(60, 0, 120),     -- Púrpura oscuro (nebulosa)
	Color3.fromRGB(0, 20, 80),      -- Azul profundo (espacio)
	Color3.fromRGB(0, 60, 120),     -- Azul cósmico
	Color3.fromRGB(100, 0, 150),    -- Violeta brillante (estrella)
	Color3.fromRGB(200, 180, 255),  -- Blanco-lila (estrella lejana)
	Color3.fromRGB(0, 100, 100),    -- Cian oscuro (aurora)
	Color3.fromRGB(150, 0, 80),     -- Magenta (supernova)
	Color3.fromRGB(255, 200, 80),   -- Dorado (sol lejano)
	Color3.fromRGB(20, 0, 60),      -- Índigo (cielo nocturno)
}

-- ============================================

local function generateSpaceTower(config)
	local FOLDER_PATH = config.FolderPath
	local BASE_TOWER_NAME = config.TowerName
	local BLOCK_COUNT = config.BlockCount
	local X_REDUCTION = config.XReduction
	local Y_SCALE_PERCENTAGE = config.YScalePercentage

	print("\n🚀 Generando " .. BASE_TOWER_NAME .. "...")

	-- Buscar la carpeta y la base
	local baseFolder = Workspace:FindFirstChild(FOLDER_PATH)

	if not baseFolder then
		warn("❌ No se encontró la carpeta '" .. FOLDER_PATH .. "' en Workspace")
		return false
	end

	local baseTower = baseFolder:FindFirstChild(BASE_TOWER_NAME)

	if not baseTower then
		warn("❌ No se encontró '" .. BASE_TOWER_NAME .. "' en " .. FOLDER_PATH)
		return false
	end

	-- Buscar el bloque base dentro de la estructura
	local baseBlock = nil
	for _, child in ipairs(baseTower:GetChildren()) do
		if child:IsA("BasePart") then
			baseBlock = child
			break
		end
	end

	if not baseBlock then
		warn("❌ No se encontró ningún bloque (Part) dentro de '" .. BASE_TOWER_NAME .. "'")
		return false
	end

	print("✅ Bloque base encontrado:", baseBlock.Name)

	local towerFolder = baseTower

	-- Calcular el factor de escala Y
	local yScaleFactor = 1 + (Y_SCALE_PERCENTAGE / 100)

	-- Variables para tracking
	local previousBlock = baseBlock
	local currentX = baseBlock.Size.X
	local currentY = baseBlock.Size.Y
	local currentZ = baseBlock.Size.Z
	local basePositionZ = baseBlock.Position.Z -- Usamos Z para la reducción (rotado 90°)

	-- Aplicar material y color espacial al bloque base
	baseBlock.Material = SPACE_MATERIALS[1]
	baseBlock.Color = SPACE_COLORS[1]

	-- Generar los bloques restantes
	for i = 2, BLOCK_COUNT do
		-- La reducción ahora va en Z (rotado 90° a la izquierda)
		currentX = math.max(currentX - X_REDUCTION, 0.5)
		currentY = currentY * yScaleFactor

		local newSize = Vector3.new(currentX, currentY, currentZ)

		local newBlock = Instance.new("Part")
		newBlock.Name = "Block_" .. i
		newBlock.Size = newSize
		newBlock.Anchored = true

		-- Asignar material espacial (ciclo entre los disponibles)
		local materialIndex = ((i - 1) % #SPACE_MATERIALS) + 1
		newBlock.Material = SPACE_MATERIALS[materialIndex]

		-- Asignar color espacial (ciclo entre los colores)
		local colorIndex = ((i - 1) % #SPACE_COLORS) + 1
		newBlock.Color = SPACE_COLORS[colorIndex]

		-- Posicionar encima del bloque anterior
		local yOffset = previousBlock.Position.Y + (previousBlock.Size.Y / 2) + (newBlock.Size.Y / 2)

		-- Reducción en Z en vez de X (girado 90° a la izquierda)
		local zReductionTotal = baseBlock.Size.X - currentX
		local zOffset = basePositionZ + (zReductionTotal / 2)

		newBlock.Position = Vector3.new(
			previousBlock.Position.X, -- X se mantiene fijo
			yOffset,
			zOffset                   -- Z tiene la reducción lateral
		)

		newBlock.Parent = towerFolder

		previousBlock = newBlock

		if i % 5 == 0 then
			print("  Progreso: " .. i .. "/" .. BLOCK_COUNT .. " bloques")
		end
	end

	print("✅ " .. BASE_TOWER_NAME .. " completada: " .. BLOCK_COUNT .. " bloques")
	return true
end

-- ========== GENERAR TODAS LAS ESTRUCTURAS ESPACIALES ==========
print("🚀 Iniciando generación de estructuras espaciales...")

local successCount = 0
local failCount = 0

for i, config in ipairs(SPACE_CONFIG) do
	local success = generateSpaceTower(config)
	if success then
		successCount = successCount + 1
	else
		failCount = failCount + 1
	end
end

print("\n✅ ========== RESUMEN ==========")
print("Estructuras espaciales generadas:", successCount)
print("Estructuras con errores:", failCount)
print("================================")
