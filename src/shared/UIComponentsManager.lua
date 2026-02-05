--[[
	UIComponentsManager.lua
	Módulo centralizado para componentes de UI reutilizables
	Mantiene consistencia visual en todas las interfaces del juego
]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))

local UIComponentsManager = {}

-- ============================================
-- BOTÓN DE CERRAR (X)
-- ============================================

--[[
	Crea un botón de cerrar estilizado con textura, efectos y animaciones
	@param parent Instance - El padre donde se colocará el botón
	@param options table? - Opciones de personalización {
		size: number (default: 52) - Tamaño del botón
		position: UDim2 (default: esquina superior derecha)
		color: Color3 (default: rojo)
		onClose: function - Callback cuando se hace click
	}
	@return ImageButton - El botón creado
]]
function UIComponentsManager.createCloseButton(parent, options)
	options = options or {}

	local size = options.size or 52
	-- Por defecto, sobresale por la esquina superior derecha
	local position = options.position or UDim2.new(1, -size * 0.75, 0, -size * 0.25)
	local color = options.color or Color3.fromRGB(200, 60, 60)
	local colorHover = options.colorHover or Color3.fromRGB(255, 80, 80)
	local strokeColor = options.strokeColor or Color3.fromRGB(80, 20, 20)
	local strokeColorHover = options.strokeColorHover or Color3.fromRGB(255, 120, 120)
	local onClose = options.onClose

	-- Botón principal con textura
	local closeButton = Instance.new("ImageButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, size, 0, size)
	closeButton.Position = position
	closeButton.BackgroundTransparency = 1
	closeButton.Image = TextureManager.Backgrounds.StudGray
	closeButton.ImageColor3 = color
	closeButton.ImageTransparency = 0.15
	closeButton.ScaleType = Enum.ScaleType.Tile
	closeButton.TileSize = UDim2.new(0, 32, 0, 32)
	closeButton.Parent = parent

	-- Esquinas redondeadas
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeButton

	-- Outline/Stroke grueso del botón
	local closeStroke = Instance.new("UIStroke")
	closeStroke.Name = "Stroke"
	closeStroke.Color = strokeColor
	closeStroke.Thickness = 5
	closeStroke.Transparency = 0
	closeStroke.Parent = closeButton

	-- Texto X
	local closeX = Instance.new("TextLabel")
	closeX.Name = "X"
	closeX.Size = UDim2.new(1, 0, 1, 0)
	closeX.BackgroundTransparency = 1
	closeX.Text = "X"
	closeX.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeX.TextSize = math.floor(size * 0.58)
	closeX.Font = Enum.Font.GothamBlack
	closeX.Parent = closeButton

	-- Stroke del texto estilo cartoon (negro grueso)
	local textStroke = Instance.new("UIStroke")
	textStroke.Name = "TextStroke"
	textStroke.Color = Color3.fromRGB(0, 0, 0)
	textStroke.Thickness = 4
	textStroke.Parent = closeX

	-- Variables para animaciones
	local isHovering = false
	local pulseConnection = nil
	local baseTextSize = math.floor(size * 0.58)
	local hoverTextSize = math.floor(size * 0.65)

	-- Efecto pulse sutil cuando no hay hover
	local function startPulse()
		if pulseConnection then return end

		local pulseUp = true
		pulseConnection = task.spawn(function()
			while not isHovering do
				local targetTransparency = pulseUp and 0.08 or 0.2
				local targetThickness = pulseUp and 5.5 or 4.5

				TweenService:Create(closeButton, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					ImageTransparency = targetTransparency
				}):Play()

				TweenService:Create(closeStroke, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
					Thickness = targetThickness
				}):Play()

				pulseUp = not pulseUp
				task.wait(0.8)
			end
		end)
	end

	local function stopPulse()
		if pulseConnection then
			task.cancel(pulseConnection)
			pulseConnection = nil
		end
	end

	-- Iniciar pulse
	startPulse()

	-- Hover effects
	closeButton.MouseEnter:Connect(function()
		isHovering = true
		stopPulse()
		SoundManager.playHover()

		-- Rotación 15 grados + cambio de color
		TweenService:Create(closeButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Rotation = 15,
			ImageColor3 = colorHover,
			ImageTransparency = 0.05
		}):Play()

		-- Stroke del botón más brillante
		TweenService:Create(closeStroke, TweenInfo.new(0.15), {
			Color = strokeColorHover,
			Thickness = 6
		}):Play()

		TweenService:Create(closeX, TweenInfo.new(0.1), {
			TextSize = hoverTextSize
		}):Play()
	end)

	closeButton.MouseLeave:Connect(function()
		isHovering = false

		-- Reiniciar pulse
		task.delay(0.3, function()
			if not isHovering then
				startPulse()
			end
		end)

		-- Volver al estado original
		TweenService:Create(closeButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = 0,
			ImageColor3 = color,
			ImageTransparency = 0.15
		}):Play()

		-- Stroke del botón vuelve a oscuro
		TweenService:Create(closeStroke, TweenInfo.new(0.2), {
			Color = strokeColor,
			Thickness = 5
		}):Play()

		TweenService:Create(closeX, TweenInfo.new(0.15), {
			TextSize = baseTextSize
		}):Play()
	end)

	-- Click
	closeButton.MouseButton1Click:Connect(function()
		SoundManager.playClick()
		if onClose then
			onClose()
		end
	end)

	-- Detener animaciones cuando el botón se destruye
	closeButton.Destroying:Connect(function()
		stopPulse()
	end)

	return closeButton
end

-- ============================================
-- NAVBAR / HEADER
-- ============================================

--[[
	Crea una barra de navegación/header estilizada con textura de stud
	@param parent Instance - El padre donde se colocará el navbar
	@param options table? - Opciones de personalización {
		height: number (default: 80) - Altura del navbar
		color: Color3 (default: azul claro) - Color del fondo
		strokeColor: Color3 (default: más oscuro que color) - Color del borde
		strokeThickness: number (default: 4) - Grosor del borde
		cornerRadius: number (default: 16) - Radio de esquinas
		title: string - Texto del título (izquierda)
		titleSize: number (default: 28) - Tamaño del título
		titleFont: Enum.Font (default: FredokaOne)
		rightText: string? - Texto opcional a la derecha
		rightTextSize: number (default: 16) - Tamaño del texto derecho
		rightTextFont: Enum.Font (default: GothamBold)
		padding: number (default: 20) - Padding horizontal
	}
	@return Frame, TextLabel, TextLabel? - El navbar, título, y texto derecho (si existe)
]]
function UIComponentsManager.createNavbar(parent, options)
	options = options or {}

	local height = options.height or 80
	local color = options.color or Color3.fromRGB(100, 180, 255)
	local strokeColor = options.strokeColor or Color3.fromRGB(
		math.max(0, color.R * 255 - 40),
		math.max(0, color.G * 255 - 40),
		math.max(0, color.B * 255 - 40)
	)
	if type(strokeColor) == "table" then
		strokeColor = Color3.fromRGB(strokeColor[1] or 60, strokeColor[2] or 140, strokeColor[3] or 215)
	end
	local strokeThickness = options.strokeThickness or 4
	local cornerRadius = options.cornerRadius or 16
	local title = options.title or "TITLE"
	local titleSize = options.titleSize or 28
	local titleFont = options.titleFont or Enum.Font.FredokaOne
	local rightText = options.rightText
	local rightTextSize = options.rightTextSize or 16
	local rightTextFont = options.rightTextFont or Enum.Font.GothamBold
	local padding = options.padding or 20

	-- Frame principal del navbar con textura
	local navbar = Instance.new("ImageLabel")
	navbar.Name = "Navbar"
	navbar.Size = UDim2.new(1, 0, 0, height)
	navbar.Position = UDim2.new(0, 0, 0, 0)
	navbar.BackgroundTransparency = 1
	navbar.Image = TextureManager.Backgrounds.StudGray
	navbar.ImageColor3 = color
	navbar.ImageTransparency = 0.1
	navbar.ScaleType = Enum.ScaleType.Tile
	navbar.TileSize = UDim2.new(0, 64, 0, 64)
	navbar.Parent = parent

	-- Esquinas redondeadas (solo arriba)
	local navCorner = Instance.new("UICorner")
	navCorner.CornerRadius = UDim.new(0, cornerRadius)
	navCorner.Parent = navbar

	-- Stroke/borde
	local navStroke = Instance.new("UIStroke")
	navStroke.Name = "Stroke"
	navStroke.Color = strokeColor
	navStroke.Thickness = strokeThickness
	navStroke.Transparency = 0
	navStroke.Parent = navbar

	-- Título (izquierda)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(0.7, -padding, 1, 0)
	titleLabel.Position = UDim2.new(0, padding, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextSize = titleSize
	titleLabel.Font = titleFont
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextYAlignment = Enum.TextYAlignment.Center
	titleLabel.Parent = navbar

	-- Stroke del título (estilo cartoon)
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Name = "TitleStroke"
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 3
	titleStroke.Parent = titleLabel

	-- Texto derecho (opcional)
	local rightLabel = nil
	if rightText then
		rightLabel = Instance.new("TextLabel")
		rightLabel.Name = "RightText"
		rightLabel.Size = UDim2.new(0.3, -padding - 60, 1, 0) -- 60 es espacio para el botón cerrar
		rightLabel.Position = UDim2.new(0.7, 0, 0, 0)
		rightLabel.BackgroundTransparency = 1
		rightLabel.Text = rightText
		rightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		rightLabel.TextSize = rightTextSize
		rightLabel.Font = rightTextFont
		rightLabel.TextXAlignment = Enum.TextXAlignment.Right
		rightLabel.TextYAlignment = Enum.TextYAlignment.Center
		rightLabel.Parent = navbar

		-- Stroke del texto derecho
		local rightStroke = Instance.new("UIStroke")
		rightStroke.Name = "RightStroke"
		rightStroke.Color = Color3.fromRGB(0, 0, 0)
		rightStroke.Thickness = 2
		rightStroke.Parent = rightLabel
	end

	return navbar, titleLabel, rightLabel
end

-- ============================================
-- STYLED CARD (Cartoon Style)
-- ============================================

--[[
	Crea una card estilizada con fondo de studs, gradiente, stroke grueso y barra de acento
	@param parent Instance - El padre donde se colocará la card
	@param options table - Opciones de personalización {
		size: UDim2 - Tamaño de la card
		position: UDim2? - Posición (opcional)
		anchorPoint: Vector2? - AnchorPoint (opcional)
		layoutOrder: number? - LayoutOrder (opcional)
		color: Color3 - Color principal (accent bar + stroke)
		backgroundColor: Color3? - Color base del fondo (default: 55,55,85)
		cornerRadius: number? - Radio esquinas (default: 16)
		strokeThickness: number? - Grosor stroke (default: 5)
		accentBarWidth: number? - Ancho barra lateral (default: 8)
		withShine: boolean? - Efecto shine (default: true)
	}
	@return Frame - La card creada
]]
function UIComponentsManager.createStyledCard(parent, options)
	options = options or {}

	local size = options.size or UDim2.new(1, 0, 0, 100)
	local position = options.position
	local anchorPoint = options.anchorPoint
	local layoutOrder = options.layoutOrder
	local color = options.color or Color3.fromRGB(100, 180, 255)
	local backgroundColor = options.backgroundColor or Color3.fromRGB(55, 55, 85)
	local cornerRadius = options.cornerRadius or 16
	local strokeThickness = options.strokeThickness or 5
	local accentBarWidth = options.accentBarWidth or 8
	local withShine = options.withShine ~= false -- default true

	-- Frame contenedor principal
	local card = Instance.new("Frame")
	card.Name = "StyledCard"
	card.Size = size
	card.BackgroundTransparency = 1
	card.ClipsDescendants = true
	card.Parent = parent

	if position then card.Position = position end
	if anchorPoint then card.AnchorPoint = anchorPoint end
	if layoutOrder then card.LayoutOrder = layoutOrder end

	-- Esquinas redondeadas del contenedor
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, cornerRadius)
	cardCorner.Parent = card

	-- Fondo con textura de studs
	local background = Instance.new("ImageLabel")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundTransparency = 1
	background.Image = TextureManager.Backgrounds.StudGray
	background.ImageColor3 = backgroundColor
	background.ImageTransparency = 0.05
	background.ScaleType = Enum.ScaleType.Tile
	background.TileSize = UDim2.new(0, 48, 0, 48)
	background.ZIndex = 1
	background.Parent = card

	-- Corner del fondo
	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, cornerRadius)
	bgCorner.Parent = background

	-- Gradiente sutil (más claro arriba, más oscuro abajo)
	local bgGradient = Instance.new("UIGradient")
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180))
	})
	bgGradient.Rotation = 90
	bgGradient.Parent = background

	-- Stroke grueso con color de acento
	local cardStroke = Instance.new("UIStroke")
	cardStroke.Name = "Stroke"
	cardStroke.Color = color
	cardStroke.Thickness = strokeThickness
	cardStroke.Transparency = 0.1
	cardStroke.Parent = card

	-- Barra de acento vertical izquierda
	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, accentBarWidth, 1, -cornerRadius * 2)
	accentBar.Position = UDim2.new(0, cornerRadius / 2, 0.5, 0)
	accentBar.AnchorPoint = Vector2.new(0, 0.5)
	accentBar.BackgroundColor3 = color
	accentBar.BorderSizePixel = 0
	accentBar.ZIndex = 2
	accentBar.Parent = card

	-- Corner de la barra de acento
	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(0, accentBarWidth / 2)
	accentCorner.Parent = accentBar

	-- Gradiente en la barra de acento (brillo arriba)
	local accentGradient = Instance.new("UIGradient")
	accentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	})
	accentGradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(1, 0.2)
	})
	accentGradient.Rotation = 90
	accentGradient.Parent = accentBar

	-- Efecto shine que barre de izquierda a derecha
	if withShine then
		local shine = Instance.new("Frame")
		shine.Name = "Shine"
		shine.Size = UDim2.new(0.15, 0, 1, 0)
		shine.Position = UDim2.new(-0.2, 0, 0, 0)
		shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		shine.BackgroundTransparency = 0.85
		shine.BorderSizePixel = 0
		shine.ZIndex = 3
		shine.Parent = card

		-- Corner del shine
		local shineCorner = Instance.new("UICorner")
		shineCorner.CornerRadius = UDim.new(0, cornerRadius)
		shineCorner.Parent = shine

		-- Gradiente para que el shine se desvanezca en los bordes
		local shineGradient = Instance.new("UIGradient")
		shineGradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, 0.7),
			NumberSequenceKeypoint.new(0.7, 0.7),
			NumberSequenceKeypoint.new(1, 1)
		})
		shineGradient.Parent = shine

		-- Animación del shine
		task.spawn(function()
			-- Delay aleatorio inicial para que no todos brillen al mismo tiempo
			task.wait(math.random() * 3)

			while shine and shine.Parent do
				-- Mover shine de izquierda a derecha
				shine.Position = UDim2.new(-0.2, 0, 0, 0)
				local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
				local tween = TweenService:Create(shine, tweenInfo, {
					Position = UDim2.new(1.1, 0, 0, 0)
				})
				tween:Play()
				tween.Completed:Wait()

				-- Esperar antes del próximo shine
				task.wait(4 + math.random() * 2)
			end
		end)
	end

	-- Frame de contenido (para que el usuario ponga sus elementos)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -(accentBarWidth + cornerRadius + 10), 1, 0)
	content.Position = UDim2.new(0, accentBarWidth + cornerRadius + 5, 0, 0)
	content.BackgroundTransparency = 1
	content.ZIndex = 4
	content.Parent = card

	return card, content
end

-- ============================================
-- CARTOON BUTTON
-- ============================================

--[[
	Crea un botón cartoon con outline grueso, gradiente, sombra y efectos hover/click
	@param parent Instance - El padre donde se colocará el botón
	@param options table - Opciones de personalización {
		size: UDim2 - Tamaño
		position: UDim2? - Posición
		anchorPoint: Vector2? - AnchorPoint
		layoutOrder: number? - LayoutOrder
		text: string? - Texto del botón
		textSize: number? - Tamaño texto (default: 20)
		font: Enum.Font? - Fuente (default: FredokaOne)
		color: Color3 - Color principal
		textColor: Color3? - Color texto (default: blanco)
		cornerRadius: number? - Radio esquinas (default: 12)
		strokeThickness: number? - Grosor stroke (default: 4)
		withShadow: boolean? - Sombra (default: true)
		shadowOffset: number? - Offset sombra (default: 4)
		icon: string? - Emoji icono
		iconImage: string? - Asset ID imagen (para Robux)
		iconSize: number? - Tamaño icono (default: 24)
		onClick: function? - Callback click
	}
	@return TextButton, Frame - El botón y el frame de contenido
]]
function UIComponentsManager.createCartoonButton(parent, options)
	options = options or {}

	local size = options.size or UDim2.new(0, 120, 0, 45)
	local position = options.position
	local anchorPoint = options.anchorPoint
	local layoutOrder = options.layoutOrder
	local text = options.text or ""
	local textSize = options.textSize or 20
	local font = options.font or Enum.Font.FredokaOne
	local color = options.color or Color3.fromRGB(100, 200, 100)
	local textColor = options.textColor or Color3.fromRGB(255, 255, 255)
	local cornerRadius = options.cornerRadius or 12
	local strokeThickness = options.strokeThickness or 4
	local withShadow = options.withShadow ~= false -- default true
	local shadowOffset = options.shadowOffset or 4
	local icon = options.icon
	local iconImage = options.iconImage
	local iconSize = options.iconSize or 24
	local onClick = options.onClick

	-- Calcular color más brillante para hover
	local function brightenColor(c, amount)
		return Color3.fromRGB(
			math.min(255, c.R * 255 + amount),
			math.min(255, c.G * 255 + amount),
			math.min(255, c.B * 255 + amount)
		)
	end
	local hoverColor = brightenColor(color, 30)

	-- Calcular color del stroke (más oscuro)
	local strokeColor = Color3.fromRGB(
		math.max(0, color.R * 255 - 60),
		math.max(0, color.G * 255 - 60),
		math.max(0, color.B * 255 - 60)
	)

	-- Frame contenedor (para la sombra)
	local container = Instance.new("Frame")
	container.Name = "CartoonButtonContainer"
	container.Size = size
	container.BackgroundTransparency = 1
	container.Parent = parent

	if position then container.Position = position end
	if anchorPoint then container.AnchorPoint = anchorPoint end
	if layoutOrder then container.LayoutOrder = layoutOrder end

	-- Sombra
	local shadow = nil
	if withShadow then
		shadow = Instance.new("Frame")
		shadow.Name = "Shadow"
		shadow.Size = UDim2.new(1, 0, 1, 0)
		shadow.Position = UDim2.new(0, shadowOffset, 0, shadowOffset)
		shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		shadow.BackgroundTransparency = 0.5
		shadow.ZIndex = 1
		shadow.Parent = container

		local shadowCorner = Instance.new("UICorner")
		shadowCorner.CornerRadius = UDim.new(0, cornerRadius)
		shadowCorner.Parent = shadow
	end

	-- Botón principal con textura de studs
	local button = Instance.new("ImageButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.Position = UDim2.new(0, 0, 0, 0)
	button.BackgroundTransparency = 1
	button.Image = TextureManager.Backgrounds.StudGray
	button.ImageColor3 = color
	button.ImageTransparency = 0.1
	button.ScaleType = Enum.ScaleType.Tile
	button.TileSize = UDim2.new(0, 32, 0, 32)
	button.ZIndex = 2
	button.Parent = container

	-- Corner del botón
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, cornerRadius)
	buttonCorner.Parent = button

	-- Stroke grueso
	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Name = "Stroke"
	buttonStroke.Color = strokeColor
	buttonStroke.Thickness = strokeThickness
	buttonStroke.Transparency = 0
	buttonStroke.Parent = button

	-- Gradiente (más claro arriba)
	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200))
	})
	buttonGradient.Rotation = 90
	buttonGradient.Parent = button

	-- Frame de contenido (icono + texto)
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -16, 1, 0)
	content.Position = UDim2.new(0.5, 0, 0.5, 0)
	content.AnchorPoint = Vector2.new(0.5, 0.5)
	content.BackgroundTransparency = 1
	content.ZIndex = 3
	content.Parent = button

	-- Layout horizontal para contenido
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.FillDirection = Enum.FillDirection.Horizontal
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	contentLayout.Padding = UDim.new(0, 6)
	contentLayout.Parent = content

	-- Icono (si hay)
	if iconImage then
		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, iconSize, 0, iconSize)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Image = iconImage
		iconLabel.ScaleType = Enum.ScaleType.Fit
		iconLabel.ZIndex = 4
		iconLabel.LayoutOrder = 1
		iconLabel.Parent = content
	elseif icon then
		local iconLabel = Instance.new("TextLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(0, iconSize, 0, iconSize)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Text = icon
		iconLabel.TextSize = iconSize
		iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		iconLabel.Font = Enum.Font.GothamBold
		iconLabel.ZIndex = 4
		iconLabel.LayoutOrder = 1
		iconLabel.Parent = content
	end

	-- Texto
	if text and text ~= "" then
		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Text"
		textLabel.Size = UDim2.new(0, 0, 1, 0)
		textLabel.AutomaticSize = Enum.AutomaticSize.X
		textLabel.BackgroundTransparency = 1
		textLabel.Text = text
		textLabel.TextColor3 = textColor
		textLabel.TextSize = textSize
		textLabel.Font = font
		textLabel.ZIndex = 4
		textLabel.LayoutOrder = 2
		textLabel.Parent = content

		-- Stroke del texto (estilo cartoon)
		local textStroke = Instance.new("UIStroke")
		textStroke.Name = "TextStroke"
		textStroke.Color = Color3.fromRGB(0, 0, 0)
		textStroke.Thickness = 2
		textStroke.Parent = textLabel
	end

	-- Efectos hover
	button.MouseEnter:Connect(function()
		SoundManager.playHover()

		-- Color más brillante + scale
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageColor3 = hoverColor
		}):Play()

		TweenService:Create(container, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(size.X.Scale * 1.03, size.X.Offset * 1.03, size.Y.Scale * 1.03, size.Y.Offset * 1.03)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		-- Volver al estado original
		TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			ImageColor3 = color
		}):Play()

		TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = size
		}):Play()
	end)

	-- Efecto click
	button.MouseButton1Down:Connect(function()
		TweenService:Create(container, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(size.X.Scale * 0.95, size.X.Offset * 0.95, size.Y.Scale * 0.95, size.Y.Offset * 0.95)
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		-- Bounce back
		TweenService:Create(container, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = size
		}):Play()
	end)

	button.MouseButton1Click:Connect(function()
		SoundManager.playClick()
		if onClick then
			onClick()
		end
	end)

	return container, button, content
end

return UIComponentsManager
