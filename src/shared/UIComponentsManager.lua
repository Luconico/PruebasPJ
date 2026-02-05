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

return UIComponentsManager
