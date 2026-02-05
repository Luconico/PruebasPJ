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

return UIComponentsManager
