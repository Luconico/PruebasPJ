--[[
	TextureManager.lua
	Módulo centralizado para todas las texturas e imágenes de UI del juego
	Permite mantener consistencia visual en todas las interfaces
]]

local TextureManager = {}

-- ============================================
-- TEXTURAS DE FONDO (Backgrounds)
-- ============================================
TextureManager.Backgrounds = {
	-- Fondos de paneles/ventanas
	StudGray = "rbxassetid://6348166067",      -- Textura de stud gris para fondos de UI
}

-- ============================================
-- ICONOS DE UI
-- ============================================
TextureManager.Icons = {
	-- Iconos generales (añadir según se necesiten)
}

-- ============================================
-- DECORACIONES
-- ============================================
TextureManager.Decorations = {
	-- Bordes, esquinas, separadores, etc.
}

-- ============================================
-- BOTONES
-- ============================================
TextureManager.Buttons = {
	-- Texturas de botones
}

-- ============================================
-- FUNCIONES DE UTILIDAD
-- ============================================

--[[
	Obtiene el ID de una textura por su categoría y nombre
	@param category string - Categoría (Backgrounds, Icons, Decorations, Buttons)
	@param name string - Nombre de la textura
	@return string|nil - ID de la textura o nil si no existe
]]
function TextureManager.get(category, name)
	local cat = TextureManager[category]
	if cat and cat[name] then
		return cat[name]
	end
	return nil
end

--[[
	Aplica una textura de fondo a un Frame o ImageLabel
	@param guiObject GuiObject - El objeto UI al que aplicar la textura
	@param textureName string - Nombre de la textura en Backgrounds
	@param options table? - Opciones adicionales {
		scaleType: Enum.ScaleType (default: Tile),
		tileSize: UDim2 (default: UDim2.new(0, 128, 0, 128)),
		transparency: number (default: 0),
		color: Color3 (default: Color3.new(1,1,1))
	}
	@return ImageLabel - El ImageLabel creado (si guiObject es Frame) o el mismo objeto modificado
]]
function TextureManager.applyBackground(guiObject, textureName, options)
	options = options or {}

	local textureId = TextureManager.Backgrounds[textureName]
	if not textureId then
		warn("[TextureManager] Textura no encontrada:", textureName)
		return nil
	end

	local imageLabel

	-- Si es un Frame, crear un ImageLabel hijo
	if guiObject:IsA("Frame") then
		-- Buscar si ya existe un ImageLabel de fondo
		imageLabel = guiObject:FindFirstChild("_BackgroundTexture")
		if not imageLabel then
			imageLabel = Instance.new("ImageLabel")
			imageLabel.Name = "_BackgroundTexture"
			imageLabel.Size = UDim2.new(1, 0, 1, 0)
			imageLabel.Position = UDim2.new(0, 0, 0, 0)
			imageLabel.ZIndex = guiObject.ZIndex
			imageLabel.Parent = guiObject
		end
	elseif guiObject:IsA("ImageLabel") or guiObject:IsA("ImageButton") then
		imageLabel = guiObject
	else
		warn("[TextureManager] Tipo de objeto no soportado:", guiObject.ClassName)
		return nil
	end

	-- Aplicar propiedades
	imageLabel.Image = textureId
	imageLabel.ScaleType = options.scaleType or Enum.ScaleType.Tile
	imageLabel.TileSize = options.tileSize or UDim2.new(0, 128, 0, 128)
	imageLabel.ImageTransparency = options.transparency or 0
	imageLabel.ImageColor3 = options.color or Color3.new(1, 1, 1)
	imageLabel.BackgroundTransparency = 1

	return imageLabel
end

--[[
	Crea un ImageLabel con una textura específica
	@param textureName string - Nombre de la textura (busca en todas las categorías)
	@param parent Instance? - Padre del ImageLabel
	@return ImageLabel
]]
function TextureManager.createImageLabel(textureName, parent)
	-- Buscar en todas las categorías
	local textureId = nil
	for _, category in pairs({"Backgrounds", "Icons", "Decorations", "Buttons"}) do
		if TextureManager[category][textureName] then
			textureId = TextureManager[category][textureName]
			break
		end
	end

	if not textureId then
		warn("[TextureManager] Textura no encontrada:", textureName)
		textureId = ""
	end

	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Image = textureId
	imageLabel.BackgroundTransparency = 1
	imageLabel.Size = UDim2.new(1, 0, 1, 0)

	if parent then
		imageLabel.Parent = parent
	end

	return imageLabel
end

return TextureManager
