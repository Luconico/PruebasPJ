--[[
	ResponsiveUI.lua
	Utilidades para diseño responsive en móviles y PC
	Detecta tamaño de pantalla y provee escalas apropiadas
]]

local ResponsiveUI = {}

-- Breakpoints (ancho de pantalla) - Ajustados para Roblox
ResponsiveUI.Breakpoints = {
	Mobile = 600,      -- Móviles pequeños (muy pocos dispositivos)
	Tablet = 1000,     -- Tablets y móviles grandes
	Desktop = 1400,    -- PC/Monitor
}

-- Obtener información del viewport
function ResponsiveUI.getViewportInfo()
	local camera = workspace.CurrentCamera
	if not camera then
		return {
			Width = 1920,
			Height = 1080,
			IsMobile = false,
			IsTablet = false,
			IsDesktop = true,
			Scale = 1,
			TextScale = 1,
		}
	end

	local viewportSize = camera.ViewportSize
	local width = viewportSize.X
	local height = viewportSize.Y

	-- Detectar dispositivo real usando UserInputService (más confiable que solo tamaño de ventana)
	local UserInputService = game:GetService("UserInputService")
	local isTouchDevice = UserInputService.TouchEnabled
	local isKeyboardDevice = UserInputService.KeyboardEnabled

	-- Determinar tipo de dispositivo
	-- Si tiene teclado y NO es táctil → PC/Desktop (Studio, PC con teclado)
	-- Si es táctil → usar tamaño de pantalla para mobile/tablet/desktop (móviles, tablets reales)
	local isMobile, isTablet, isDesktop

	if isKeyboardDevice and not isTouchDevice then
		-- PC/Desktop - siempre Desktop independientemente del tamaño de ventana
		-- (El tamaño de ventana en Studio no debe cambiar el modo, solo la escala)
		isMobile = false
		isTablet = false
		isDesktop = true
	elseif isTouchDevice then
		-- Dispositivo táctil real - usar tamaño de pantalla
		isMobile = width <= ResponsiveUI.Breakpoints.Mobile
		isTablet = width > ResponsiveUI.Breakpoints.Mobile and width <= ResponsiveUI.Breakpoints.Tablet
		isDesktop = width > ResponsiveUI.Breakpoints.Tablet
	else
		-- Fallback (no debería ocurrir, pero por si acaso)
		isMobile = width <= ResponsiveUI.Breakpoints.Mobile
		isTablet = width > ResponsiveUI.Breakpoints.Mobile and width <= ResponsiveUI.Breakpoints.Tablet
		isDesktop = width > ResponsiveUI.Breakpoints.Tablet
	end

	-- Escala base según el ancho
	-- En Desktop: escalar suavemente según tamaño de ventana (para ventanas pequeñas en Studio)
	-- En Mobile/Tablet: escalar según sus propias reglas
	local scale = 1
	if isMobile then
		scale = math.clamp(width / 400, 0.6, 1)
	elseif isTablet then
		scale = math.clamp(width / 800, 0.8, 1)
	elseif isDesktop and width < 1400 then
		-- Desktop con ventana pequeña: escalar suavemente
		scale = math.clamp(width / 1400, 0.85, 1)
	end

	-- Escala de texto (ligeramente diferente para legibilidad)
	local textScale = 1
	if isMobile then
		textScale = math.clamp(width / 450, 0.7, 1)
	elseif isTablet then
		textScale = math.clamp(width / 850, 0.85, 1)
	end

	return {
		Width = width,
		Height = height,
		IsMobile = isMobile,
		IsTablet = isTablet,
		IsDesktop = isDesktop,
		Scale = scale,
		TextScale = textScale,
		AspectRatio = width / height,
	}
end

-- Escalar un valor de tamaño según el viewport
function ResponsiveUI.scale(baseValue)
	local info = ResponsiveUI.getViewportInfo()
	return math.floor(baseValue * info.Scale)
end

-- Escalar texto según el viewport
function ResponsiveUI.scaleText(baseSize)
	local info = ResponsiveUI.getViewportInfo()
	return math.floor(baseSize * info.TextScale)
end

-- Crear UDim2 responsivo para tamaños
-- Usa Scale cuando es posible, pero con constraints de Offset mínimo/máximo
function ResponsiveUI.size(scaleX, offsetX, scaleY, offsetY)
	local info = ResponsiveUI.getViewportInfo()
	local scaledOffsetX = math.floor(offsetX * info.Scale)
	local scaledOffsetY = math.floor(offsetY * info.Scale)
	return UDim2.new(scaleX, scaledOffsetX, scaleY, scaledOffsetY)
end

-- Crear UDim2 responsivo para posiciones
function ResponsiveUI.position(scaleX, offsetX, scaleY, offsetY)
	local info = ResponsiveUI.getViewportInfo()
	local scaledOffsetX = math.floor(offsetX * info.Scale)
	local scaledOffsetY = math.floor(offsetY * info.Scale)
	return UDim2.new(scaleX, scaledOffsetX, scaleY, scaledOffsetY)
end

-- Tamaño mínimo para botones táctiles (44px recomendado por Apple/Google)
function ResponsiveUI.minTouchSize()
	return 44
end

-- Obtener padding responsive
function ResponsiveUI.padding(basePadding)
	local info = ResponsiveUI.getViewportInfo()
	local scaled = math.floor(basePadding * info.Scale)
	return math.max(scaled, 8) -- Mínimo 8px de padding
end

-- Crear constraint de tamaño mínimo/máximo
function ResponsiveUI.createSizeConstraint(parent, minWidth, minHeight, maxWidth, maxHeight)
	local constraint = Instance.new("UISizeConstraint")
	if minWidth then constraint.MinSize = Vector2.new(minWidth, minHeight or 0) end
	if maxWidth then constraint.MaxSize = Vector2.new(maxWidth, maxHeight or math.huge) end
	constraint.Parent = parent
	return constraint
end

-- Aplicar escala responsive a un elemento existente
function ResponsiveUI.applyResponsiveScale(element, baseSize, basePosition, baseTextSize)
	local info = ResponsiveUI.getViewportInfo()

	if baseSize then
		element.Size = UDim2.new(
			baseSize.X.Scale,
			math.floor(baseSize.X.Offset * info.Scale),
			baseSize.Y.Scale,
			math.floor(baseSize.Y.Offset * info.Scale)
		)
	end

	if basePosition then
		element.Position = UDim2.new(
			basePosition.X.Scale,
			math.floor(basePosition.X.Offset * info.Scale),
			basePosition.Y.Scale,
			math.floor(basePosition.Y.Offset * info.Scale)
		)
	end

	if baseTextSize and element:IsA("TextLabel") or element:IsA("TextButton") or element:IsA("TextBox") then
		element.TextSize = math.floor(baseTextSize * info.TextScale)
	end
end

-- Conectar callback cuando cambia el viewport
function ResponsiveUI.onViewportChanged(callback)
	local camera = workspace.CurrentCamera
	if camera then
		return camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			callback(ResponsiveUI.getViewportInfo())
		end)
	end
	return nil
end

-- Verificar si estamos en un dispositivo táctil
function ResponsiveUI.isTouchDevice()
	local UserInputService = game:GetService("UserInputService")
	return UserInputService.TouchEnabled
end

-- Obtener margen seguro (para notch, etc.)
function ResponsiveUI.getSafeAreaInsets()
	local GuiService = game:GetService("GuiService")
	local insets = GuiService:GetGuiInset()
	return {
		Top = insets.Y,
		Left = insets.X,
		Bottom = 0,
		Right = 0,
	}
end

return ResponsiveUI
