local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cargar módulos
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local TextureManager = require(Shared:WaitForChild("TextureManager"))

-- Esperar a la carpeta Remotes que ya existe
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotesFolder then
	warn("[ZonasClient] No se encontró la carpeta Remotes")
	return
end

print("[ZonasClient] Esperando RemoteEvents del servidor...")

-- Intentar encontrar los RemoteEvents con reintentos
local showZoneUIRemote = nil
local unlockZoneRemote = nil
local maxAttempts = 20
local attempt = 0

while attempt < maxAttempts do
	attempt = attempt + 1

	showZoneUIRemote = remotesFolder:FindFirstChild("ShowUnlockZoneUI")
	unlockZoneRemote = remotesFolder:FindFirstChild("UnlockZoneRemote")

	if showZoneUIRemote and unlockZoneRemote then
		print("[ZonasClient] RemoteEvents encontrados (intento " .. attempt .. ")")
		break
	end

	task.wait(0.5)
end

if not showZoneUIRemote or not unlockZoneRemote then
	warn("[ZonasClient] No se encontraron los RemoteEvents de zonas después de " .. maxAttempts .. " intentos.")
	warn("[ZonasClient] Verifica que DesbloqueoZonasServer esté en ServerScriptService y se esté ejecutando.")
	return
end

-- Variable para guardar la UI actual
local currentZoneUI = nil
local currentZoneName = nil

-- Función para formatear números con separadores
local function formatNumber(num)
	local formatted = tostring(num)
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

-- Función para mostrar notificación
local function showNotification(success, message)
	-- Sonidos según resultado
	if success then
		SoundManager.play("PurchaseSuccess", 0.5, 1.0)
		task.delay(0.1, function()
			SoundManager.play("CashRegister", 0.4, 1.1)
		end)
	else
		SoundManager.play("Error", 0.5, 0.8)
	end

	local notification = Instance.new("ScreenGui")
	notification.Name = "ZoneNotification"
	notification.ResetOnSpawn = false
	notification.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	notification.DisplayOrder = 100
	notification.Parent = playerGui

	local notifFrame = Instance.new("Frame")
	notifFrame.Size = UDim2.new(0, 400, 0, 60)
	notifFrame.Position = UDim2.new(0.5, 0, 0, -80)
	notifFrame.AnchorPoint = Vector2.new(0.5, 0)
	notifFrame.BackgroundColor3 = success and Color3.fromRGB(80, 200, 80) or Color3.fromRGB(200, 80, 80)
	notifFrame.BorderSizePixel = 0
	notifFrame.Parent = notification

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = notifFrame

	local notifText = Instance.new("TextLabel")
	notifText.Size = UDim2.new(1, -20, 1, 0)
	notifText.Position = UDim2.new(0, 10, 0, 0)
	notifText.BackgroundTransparency = 1
	notifText.Text = (success and "✓ " or "✗ ") .. message
	notifText.TextColor3 = Color3.new(1, 1, 1)
	notifText.TextSize = 24
	notifText.Font = Enum.Font.FredokaOne
	notifText.Parent = notifFrame

	-- Animación de entrada
	TweenService:Create(notifFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 20)
	}):Play()

	-- Esperar y salir
	task.delay(2.5, function()
		TweenService:Create(notifFrame, TweenInfo.new(0.3), {
			Position = UDim2.new(0.5, 0, 0, -80)
		}):Play()
		task.wait(0.3)
		notification:Destroy()
	end)
end

-- Función para crear la UI de desbloqueo
-- vipOnly: si es true, solo muestra el botón de Robux (para zonas VIP)
-- trophyCost: ahora las zonas normales usan trofeos en lugar de monedas
local function createZoneUI(zoneName, trophyCost, robuxCost, vipOnly)
	print("[ZonasClient] Creando UI para zona: " .. zoneName .. (vipOnly and " (VIP)" or ""))

	-- Si ya existe una UI, destruirla
	if currentZoneUI then
		currentZoneUI:Destroy()
		print("[ZonasClient] UI anterior destruida")
	end

	-- Tamaños según el tipo de zona
	local frameHeight = vipOnly and 220 or 300
	local robuxButtonY = vipOnly and 130 or 200

	-- Crear ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ZoneUnlockUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- Fondo oscuro semitransparente
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Position = UDim2.new(0, 0, 0, 0)
	background.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	background.BackgroundTransparency = 0.5
	background.BorderSizePixel = 0
	background.Parent = screenGui

	-- Frame principal
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, frameHeight)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = vipOnly and Color3.fromRGB(50, 35, 60) or Color3.fromRGB(40, 40, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = background

	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	-- Borde dorado para VIP
	if vipOnly then
		local vipStroke = Instance.new("UIStroke")
		vipStroke.Color = Color3.fromRGB(255, 200, 50)
		vipStroke.Thickness = 3
		vipStroke.Parent = mainFrame
	end

	-- Título (con corona para VIP)
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = vipOnly and ("👑 " .. zoneName .. " 👑") or ("🔒 " .. zoneName)
	title.TextColor3 = vipOnly and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 255, 255)
	title.TextSize = 28
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = mainFrame

	-- Subtítulo
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -40, 0, 40)
	subtitle.Position = UDim2.new(0, 20, 0, 75)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = vipOnly and "VIP Exclusive Zone" or "Pay to unlock?"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 18
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Parent = mainFrame

	local hoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Botón de trofeos (solo si NO es VIP)
	local trophiesButton = nil
	if not vipOnly then
		trophiesButton = Instance.new("TextButton")
		trophiesButton.Name = "TrophiesButton"
		trophiesButton.Size = UDim2.new(1, -40, 0, 60)
		trophiesButton.Position = UDim2.new(0, 20, 0, 130)
		trophiesButton.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
		trophiesButton.BorderSizePixel = 0
		trophiesButton.Text = "🏆 " .. formatNumber(trophyCost) .. " Trophies"
		trophiesButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		trophiesButton.TextSize = 24
		trophiesButton.Font = Enum.Font.GothamBold
		trophiesButton.AutoButtonColor = false
		trophiesButton.Parent = mainFrame

		local trophiesCorner = Instance.new("UICorner")
		trophiesCorner.CornerRadius = UDim.new(0, 10)
		trophiesCorner.Parent = trophiesButton

		-- Efecto hover para botón de trofeos
		trophiesButton.MouseEnter:Connect(function()
			SoundManager.play("ButtonHover", 0.2, 1.1)
			TweenService:Create(trophiesButton, hoverTweenInfo, {
				BackgroundColor3 = Color3.fromRGB(255, 200, 100)
			}):Play()
		end)

		trophiesButton.MouseLeave:Connect(function()
			TweenService:Create(trophiesButton, hoverTweenInfo, {
				BackgroundColor3 = Color3.fromRGB(255, 180, 50)
			}):Play()
		end)

		trophiesButton.MouseButton1Click:Connect(function()
			SoundManager.play("ButtonClick", 0.5, 1.0)
			unlockZoneRemote:FireServer(currentZoneName, "trophies")
			screenGui:Destroy()
			currentZoneUI = nil
		end)
	end

	-- Botón de Robux
	local robuxButton = Instance.new("TextButton")
	robuxButton.Name = "RobuxButton"
	robuxButton.Size = UDim2.new(1, -40, 0, 60)
	robuxButton.Position = UDim2.new(0, 20, 0, robuxButtonY)
	robuxButton.BackgroundColor3 = Color3.fromRGB(0, 230, 118)
	robuxButton.BorderSizePixel = 0
	robuxButton.Text = ""
	robuxButton.AutoButtonColor = false
	robuxButton.Parent = mainFrame

	local robuxCorner = Instance.new("UICorner")
	robuxCorner.CornerRadius = UDim.new(0, 10)
	robuxCorner.Parent = robuxButton

	-- Contenido del botón de Robux (icono + texto)
	local robuxContent = Instance.new("Frame")
	robuxContent.Name = "Content"
	robuxContent.Size = UDim2.new(1, 0, 1, 0)
	robuxContent.BackgroundTransparency = 1
	robuxContent.Parent = robuxButton

	local robuxLayout = Instance.new("UIListLayout")
	robuxLayout.FillDirection = Enum.FillDirection.Horizontal
	robuxLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	robuxLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	robuxLayout.Padding = UDim.new(0, 8)
	robuxLayout.Parent = robuxContent

	local robuxIcon = Instance.new("ImageLabel")
	robuxIcon.Name = "RobuxIcon"
	robuxIcon.Size = UDim2.new(0, 28, 0, 28)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Image = TextureManager.Icons.Robux
	robuxIcon.ScaleType = Enum.ScaleType.Fit
	robuxIcon.Parent = robuxContent

	local robuxText = Instance.new("TextLabel")
	robuxText.Name = "PriceText"
	robuxText.Size = UDim2.new(0, 120, 0, 40)
	robuxText.BackgroundTransparency = 1
	robuxText.Text = formatNumber(robuxCost) .. " R$"
	robuxText.TextColor3 = Color3.fromRGB(255, 255, 255)
	robuxText.TextSize = 24
	robuxText.Font = Enum.Font.GothamBold
	robuxText.TextXAlignment = Enum.TextXAlignment.Left
	robuxText.Parent = robuxContent

	-- Efecto hover para botón de Robux
	robuxButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.2, 1.1)
		TweenService:Create(robuxButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(50, 255, 150)
		}):Play()
	end)

	robuxButton.MouseLeave:Connect(function()
		TweenService:Create(robuxButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(0, 230, 118)
		}):Play()
	end)

	robuxButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.5, 1.0)
		unlockZoneRemote:FireServer(currentZoneName, "robux")
		SoundManager.play("PopupClose", 0.3, 1.3)
		screenGui:Destroy()
		currentZoneUI = nil
	end)

	-- Botón de cerrar (estilo igual que la tienda)
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 45, 0, 45)
	closeButton.Position = UDim2.new(1, -55, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 28
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeButton

	local closeStroke = Instance.new("UIStroke")
	closeStroke.Color = Color3.fromRGB(200, 50, 50)
	closeStroke.Thickness = 3
	closeStroke.Parent = closeButton

	closeButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.2, 1.2)
	end)

	closeButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.4, 1.1)
		SoundManager.play("PopupClose", 0.3, 1.3)
		screenGui:Destroy()
		currentZoneUI = nil
	end)

	-- Cerrar al hacer click en el fondo
	background.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			SoundManager.play("PopupClose", 0.3, 1.3)
			screenGui:Destroy()
			currentZoneUI = nil
		end
	end)

	-- Sonido de apertura del popup
	SoundManager.play("PopupOpen", 0.4, 0.9)
	task.delay(0.15, function()
		SoundManager.play("Sparkle", 0.3, 1.2)
	end)

	-- Animación de entrada
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, frameHeight)
	})
	openTween:Play()

	currentZoneUI = screenGui
end

-- Escuchar evento del servidor para mostrar UI
-- Parámetros: zoneName, coinsCost, robuxCost, vipOnly, displayName (opcional)
showZoneUIRemote.OnClientEvent:Connect(function(zoneName, coinsCost, robuxCost, vipOnly, displayName)
	print("[ZonasClient] Recibida petición de UI para: " .. zoneName .. (vipOnly and " (VIP)" or ""))

	-- Si ya hay una UI abierta, no crear otra
	if currentZoneUI then
		print("[ZonasClient] Ya hay una UI abierta, ignorando petición")
		return
	end

	print("[ZonasClient] Coins: " .. tostring(coinsCost) .. ", Robux: " .. robuxCost .. ", VIP: " .. tostring(vipOnly))
	currentZoneName = zoneName
	-- Usar displayName si existe, sino usar zoneName
	local uiDisplayName = displayName or zoneName
	createZoneUI(uiDisplayName, coinsCost, robuxCost, vipOnly)
	print("[ZonasClient] UI creada")
end)

-- Escuchar evento para hacer zona invisible
local makeInvisibleRemote = remotesFolder:FindFirstChild("MakeZoneInvisible")
if not makeInvisibleRemote then
	makeInvisibleRemote = remotesFolder:WaitForChild("MakeZoneInvisible", 5)
end

if makeInvisibleRemote then
	makeInvisibleRemote.OnClientEvent:Connect(function(zoneName)
		-- Sonidos de celebración al desbloquear zona
		SoundManager.play("PurchaseSuccess", 0.6, 1.0)
		task.delay(0.1, function()
			SoundManager.play("CashRegister", 0.5, 1.1)
		end)
		task.delay(0.3, function()
			SoundManager.play("Sparkle", 0.5, 0.9)
		end)
		task.delay(0.6, function()
			SoundManager.play("Sparkle", 0.4, 1.3)
		end)
		print("[ZonasClient] Haciendo " .. zoneName .. " invisible localmente")

		-- Primero buscar en carpeta Zonas
		local zonesFolder = workspace:FindFirstChild("Zonas")
		if zonesFolder then
			local zone = zonesFolder:FindFirstChild(zoneName)
			if zone then
				for _, part in ipairs(zone:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanCollide = false
					end
				end
				print("[ZonasClient] Zona " .. zoneName .. " ahora invisible")
				return
			end
		end

		-- Si no está en Zonas, buscar directamente en Workspace (para bases/bloqueos)
		local directPart = workspace:FindFirstChild(zoneName)
		if directPart and directPart:IsA("BasePart") then
			directPart.Transparency = 1
			directPart.CanCollide = false
			print("[ZonasClient] Bloqueo " .. zoneName .. " ahora invisible")
		end
	end)
end

-- Escuchar evento de error de monedas insuficientes
local insufficientFundsRemote = remotesFolder:FindFirstChild("ZoneInsufficientFunds")
if not insufficientFundsRemote then
	-- Esperar un poco por si el servidor lo crea después
	insufficientFundsRemote = remotesFolder:WaitForChild("ZoneInsufficientFunds", 5)
end

if insufficientFundsRemote then
	insufficientFundsRemote.OnClientEvent:Connect(function(zoneName, required, current, currencyType)
		if currencyType == "trophies" then
			showNotification(false, "Insufficient Trophies! You need " .. formatNumber(required) .. " 🏆")
		else
			showNotification(false, "Insufficient Coins! You need " .. formatNumber(required) .. "$")
		end
	end)
end

print("[ZonasClient] Cliente de zonas desbloqueables inicializado")
