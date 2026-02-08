local Workspace = game:GetService("Workspace")

-- ========== CONFIGURACIÓN DE TORRES ==========
local TOWERS_CONFIG = {
	-- Torre 1: Configuración estándar
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre1",
		BlockCount = 28,
		XReduction = 3,
		YScalePercentage = 29.25,
	},

	-- Torre 2: Más alta y delgada
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre2",
		BlockCount = 29,
		XReduction = 3,
		YScalePercentage = 29.5,
	},

	-- Torre 3: Baja y ancha
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre3",
		BlockCount = 30,
		XReduction = 3,
		YScalePercentage = 29.75,
	},

	-- Torre 4: Torre muy alta
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre4",
		BlockCount = 31,
		XReduction = 3,
		YScalePercentage = 30,
	},

	-- Torre 5: Reducción agresiva
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre5",
		BlockCount = 32,
		XReduction = 3,
		YScalePercentage = 30.5,
	},

	-- Torre 6: Crecimiento vertical rápido
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre6",
		BlockCount = 33,
		XReduction = 3,
		YScalePercentage = 31,
	},

	-- Torre 7: Torre equilibrada
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre7",
		BlockCount = 16,
		XReduction = 2,
		YScalePercentage = 20,
	},

	-- Torre 8: Torre compacta
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre8",
		BlockCount = 8,
		XReduction = 3,
		YScalePercentage = 35,
	},

	-- Torre 9: Torre gigante
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre9",
		BlockCount = 30,
		XReduction = 1,
		YScalePercentage = 12,
	},

	-- Torre 10: Torre experimental
	{
		FolderPath = "BurgueteNotoca",
		TowerName = "Torre10",
		BlockCount = 22,
		XReduction = 2.5,
		YScalePercentage = 25,
	},
}
-- ============================================

local function generateTower(config)
	local FOLDER_PATH = config.FolderPath
	local BASE_TOWER_NAME = config.TowerName
	local BLOCK_COUNT = config.BlockCount
	local X_REDUCTION = config.XReduction
	local Y_SCALE_PERCENTAGE = config.YScalePercentage

	print("\n🏗️ Generando " .. BASE_TOWER_NAME .. "...")

	-- Buscar la carpeta y la torre base
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

	-- Buscar el bloque base dentro de la torre (el primer Part que encuentre)
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

	-- Los bloques generados se pondrán dentro de la torre
	local towerFolder = baseTower

	-- Calcular el factor de escala Y (de porcentaje a multiplicador)
	local yScaleFactor = 1 + (Y_SCALE_PERCENTAGE / 100)

	-- Variables para tracking
	local previousBlock = baseBlock
	local currentX = baseBlock.Size.X
	local currentY = baseBlock.Size.Y
	local currentZ = baseBlock.Size.Z
	local basePositionX = baseBlock.Position.X  -- Guardar posición X base

	-- Aplicar color inicial al bloque base (Hue = 0)
	baseBlock.Color = Color3.fromHSV(0, 1, 1)

	-- Generar los bloques restantes
	for i = 2, BLOCK_COUNT do
		-- Calcular nuevo tamaño según las reglas:
		-- X: Reducir X_REDUCTION studs (solo por un lado)
		-- Y: Multiplicar por yScaleFactor (acumulativo)
		-- Z: Mantener igual
		currentX = math.max(currentX - X_REDUCTION, 0.5)
		currentY = currentY * yScaleFactor

		local newSize = Vector3.new(currentX, currentY, currentZ)

		-- Crear nuevo bloque
		local newBlock = Instance.new("Part")
		newBlock.Name = "Block_" .. i
		newBlock.Size = newSize
		newBlock.Anchored = true
		newBlock.Material = baseBlock.Material

		-- Calcular Hue (0 a 1 a lo largo de la torre)
		local hue = (i - 1) / (BLOCK_COUNT - 1)
		newBlock.Color = Color3.fromHSV(hue, 1, 1)

		-- Posicionar encima del bloque anterior
		-- El offset en Y considera la altura de ambos bloques
		local yOffset = previousBlock.Position.Y + (previousBlock.Size.Y / 2) + (newBlock.Size.Y / 2)

		-- IMPORTANTE: Ajustar posición X para que la reducción sea solo por un lado
		-- Calculamos cuánto se ha reducido X desde el bloque base
		local xReductionTotal = baseBlock.Size.X - currentX
		-- Desplazamos la mitad de esa reducción para mantener un lado alineado
		-- Cambiado el signo para invertir el lado de reducción
		local xOffset = basePositionX - (xReductionTotal / 2)

		newBlock.Position = Vector3.new(
			xOffset,
			yOffset,
			previousBlock.Position.Z
		)

		newBlock.Parent = towerFolder

		-- Actualizar para siguiente iteración
		previousBlock = newBlock

		-- Feedback de progreso (cada 5 bloques)
		if i % 5 == 0 then
			print("  Progreso: " .. i .. "/" .. BLOCK_COUNT .. " bloques")
		end
	end

	print("✅ " .. BASE_TOWER_NAME .. " completada: " .. BLOCK_COUNT .. " bloques")
	print("  📏 Tamaño inicial: X=" .. baseBlock.Size.X .. ", Y=" .. baseBlock.Size.Y .. ", Z=" .. baseBlock.Size.Z)
	print("  📏 Tamaño final: X=" .. string.format("%.2f", currentX) .. ", Y=" .. string.format("%.2f", currentY) .. ", Z=" .. currentZ)

	return true
end

-- ========== GENERAR TODAS LAS TORRES ==========
print("🏗️ Iniciando generación de torres...")
print("Total de torres a generar:", #TOWERS_CONFIG)

local successCount = 0
local failCount = 0

for i, config in ipairs(TOWERS_CONFIG) do
	local success = generateTower(config)
	if success then
		successCount = successCount + 1
	else
		failCount = failCount + 1
	end
end

print("\n✅ ========== RESUMEN ==========")
print("Torres generadas exitosamente:", successCount)
print("Torres con errores:", failCount)
print("================================")
