local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Cargar módulo de sonidos
local Shared = ReplicatedStorage:WaitForChild("Shared")
local SoundManager = require(Shared:WaitForChild("SoundManager"))

-- Esperar a la carpeta Remotes que ya existe
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotesFolder then
	warn("[BasesClient] No se encontró la carpeta Remotes")
	return
end

print("[BasesClient] Esperando RemoteEvents del servidor...")

-- Intentar encontrar los RemoteEvents con reintentos
local showBaseUIRemote = nil
local unlockBaseRemote = nil
local maxAttempts = 20
local attempt = 0

while attempt < maxAttempts do
	attempt = attempt + 1

	showBaseUIRemote = remotesFolder:FindFirstChild("ShowUnlockBaseUI")
	unlockBaseRemote = remotesFolder:FindFirstChild("UnlockBaseRemote")

	if showBaseUIRemote and unlockBaseRemote then
		print("[BasesClient] RemoteEvents encontrados (intento " .. attempt .. ")")
		break
	end

	task.wait(0.5)
end

if not showBaseUIRemote or not unlockBaseRemote then
	warn("[BasesClient] No se encontraron los RemoteEvents de bases después de " .. maxAttempts .. " intentos.")
	warn("[BasesClient] Verifica que DesbloqueoBaseServer esté en ServerScriptService y se esté ejecutando.")
	return
end

-- Variable para guardar la UI actual
local currentBaseUI = nil
local currentBaseName = nil
local currentBlockName = nil

-- Función para formatear números con separadores de miles
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
	notification.Name = "BaseNotification"
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
local function createBaseUI(baseName, coinsCost, robuxCost, displayName, blockName)
	print("[BasesClient] Creando UI para base: " .. baseName)

	-- Si ya existe una UI, destruirla
	if currentBaseUI then
		currentBaseUI:Destroy()
		print("[BasesClient] UI anterior destruida")
	end

	-- Crear ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BaseUnlockUI"
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
	mainFrame.Size = UDim2.new(0, 450, 0, 350)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = background

	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	-- Borde con gradiente
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 80, 200)
	stroke.Thickness = 2
	stroke.Parent = mainFrame

	-- Icono de candado
	local lockIcon = Instance.new("TextLabel")
	lockIcon.Name = "LockIcon"
	lockIcon.Size = UDim2.new(0, 60, 0, 60)
	lockIcon.Position = UDim2.new(0.5, 0, 0, 20)
	lockIcon.AnchorPoint = Vector2.new(0.5, 0)
	lockIcon.BackgroundTransparency = 1
	lockIcon.Text = "🔒"
	lockIcon.TextSize = 50
	lockIcon.Font = Enum.Font.GothamBold
	lockIcon.Parent = mainFrame

	-- Título
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 40)
	title.Position = UDim2.new(0, 20, 0, 85)
	title.BackgroundTransparency = 1
	title.Text = displayName or baseName
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextSize = 26
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Center
	title.Parent = mainFrame

	-- Subtítulo
	local subtitle = Instance.new("TextLabel")
	subtitle.Name = "Subtitle"
	subtitle.Size = UDim2.new(1, -40, 0, 30)
	subtitle.Position = UDim2.new(0, 20, 0, 125)
	subtitle.BackgroundTransparency = 1
	subtitle.Text = "Desbloquea el acceso a esta zona"
	subtitle.TextColor3 = Color3.fromRGB(180, 180, 180)
	subtitle.TextSize = 16
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Parent = mainFrame

	-- Botón de monedas (100,000$)
	local coinsButton = Instance.new("TextButton")
	coinsButton.Name = "CoinsButton"
	coinsButton.Size = UDim2.new(1, -40, 0, 65)
	coinsButton.Position = UDim2.new(0, 20, 0, 170)
	coinsButton.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	coinsButton.BorderSizePixel = 0
	coinsButton.Text = ""
	coinsButton.AutoButtonColor = false
	coinsButton.Parent = mainFrame

	local coinsCorner = Instance.new("UICorner")
	coinsCorner.CornerRadius = UDim.new(0, 12)
	coinsCorner.Parent = coinsButton

	-- Contenido del botón de monedas
	local coinsIcon = Instance.new("TextLabel")
	coinsIcon.Size = UDim2.new(0, 40, 1, 0)
	coinsIcon.Position = UDim2.new(0, 15, 0, 0)
	coinsIcon.BackgroundTransparency = 1
	coinsIcon.Text = "💰"
	coinsIcon.TextSize = 32
	coinsIcon.Font = Enum.Font.GothamBold
	coinsIcon.Parent = coinsButton

	local coinsText = Instance.new("TextLabel")
	coinsText.Size = UDim2.new(1, -70, 1, 0)
	coinsText.Position = UDim2.new(0, 60, 0, 0)
	coinsText.BackgroundTransparency = 1
	coinsText.Text = formatNumber(coinsCost) .. "$"
	coinsText.TextColor3 = Color3.fromRGB(50, 50, 50)
	coinsText.TextSize = 28
	coinsText.Font = Enum.Font.GothamBold
	coinsText.TextXAlignment = Enum.TextXAlignment.Center
	coinsText.Parent = coinsButton

	-- Botón de Robux (500 R$)
	local robuxButton = Instance.new("TextButton")
	robuxButton.Name = "RobuxButton"
	robuxButton.Size = UDim2.new(1, -40, 0, 65)
	robuxButton.Position = UDim2.new(0, 20, 0, 245)
	robuxButton.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
	robuxButton.BorderSizePixel = 0
	robuxButton.Text = ""
	robuxButton.AutoButtonColor = false
	robuxButton.Parent = mainFrame

	local robuxCorner = Instance.new("UICorner")
	robuxCorner.CornerRadius = UDim.new(0, 12)
	robuxCorner.Parent = robuxButton

	-- Contenido del botón de Robux
	local robuxIcon = Instance.new("TextLabel")
	robuxIcon.Size = UDim2.new(0, 40, 1, 0)
	robuxIcon.Position = UDim2.new(0, 15, 0, 0)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Text = "💎"
	robuxIcon.TextSize = 32
	robuxIcon.Font = Enum.Font.GothamBold
	robuxIcon.Parent = robuxButton

	local robuxText = Instance.new("TextLabel")
	robuxText.Size = UDim2.new(1, -70, 1, 0)
	robuxText.Position = UDim2.new(0, 60, 0, 0)
	robuxText.BackgroundTransparency = 1
	robuxText.Text = formatNumber(robuxCost) .. " R$"
	robuxText.TextColor3 = Color3.fromRGB(255, 255, 255)
	robuxText.TextSize = 28
	robuxText.Font = Enum.Font.GothamBold
	robuxText.TextXAlignment = Enum.TextXAlignment.Center
	robuxText.Parent = robuxButton

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

	-- Efecto hover para botón de monedas
	local hoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	coinsButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.2, 1.1)
		TweenService:Create(coinsButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(255, 230, 100)
		}):Play()
	end)

	coinsButton.MouseLeave:Connect(function()
		TweenService:Create(coinsButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(255, 200, 0)
		}):Play()
	end)

	-- Efecto hover para botón de Robux
	robuxButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.2, 1.1)
		TweenService:Create(robuxButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(50, 220, 130)
		}):Play()
	end)

	robuxButton.MouseLeave:Connect(function()
		TweenService:Create(robuxButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(0, 180, 100)
		}):Play()
	end)

	-- Eventos de click
	coinsButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.5, 1.0)
		-- Enviar al servidor para desbloquear con monedas
		unlockBaseRemote:FireServer(currentBaseName, "coins")
		screenGui:Destroy()
		currentBaseUI = nil
	end)

	robuxButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.5, 1.0)
		-- Enviar al servidor para desbloquear con Robux
		unlockBaseRemote:FireServer(currentBaseName, "robux")
		SoundManager.play("PopupClose", 0.3, 1.3)
		screenGui:Destroy()
		currentBaseUI = nil
	end)

	closeButton.MouseEnter:Connect(function()
		SoundManager.play("ButtonHover", 0.2, 1.2)
	end)

	closeButton.MouseButton1Click:Connect(function()
		SoundManager.play("ButtonClick", 0.4, 1.1)
		SoundManager.play("PopupClose", 0.3, 1.3)
		screenGui:Destroy()
		currentBaseUI = nil
	end)

	-- Cerrar al hacer click en el fondo
	background.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			SoundManager.play("PopupClose", 0.3, 1.3)
			screenGui:Destroy()
			currentBaseUI = nil
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
		Size = UDim2.new(0, 450, 0, 350)
	})
	openTween:Play()

	currentBaseUI = screenGui
end

-- Escuchar evento del servidor para mostrar UI
showBaseUIRemote.OnClientEvent:Connect(function(baseName, coinsCost, robuxCost, displayName, blockName)
	print("[BasesClient] Recibida petición de UI para: " .. baseName)

	-- Si ya hay una UI abierta, no crear otra
	if currentBaseUI then
		print("[BasesClient] Ya hay una UI abierta, ignorando petición")
		return
	end

	print("[BasesClient] Coins: " .. coinsCost .. ", Robux: " .. robuxCost)
	currentBaseName = baseName
	currentBlockName = blockName
	createBaseUI(baseName, coinsCost, robuxCost, displayName, blockName)
	print("[BasesClient] UI creada")
end)

-- Escuchar evento para hacer bloqueo invisible
local makeBaseInvisibleRemote = remotesFolder:FindFirstChild("MakeBaseInvisible")
if not makeBaseInvisibleRemote then
	makeBaseInvisibleRemote = remotesFolder:WaitForChild("MakeBaseInvisible", 5)
end

if makeBaseInvisibleRemote then
	makeBaseInvisibleRemote.OnClientEvent:Connect(function(baseName, blockName)
		-- Sonidos de celebración al desbloquear base
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
		print("[BasesClient] Haciendo " .. blockName .. " invisible localmente")

		-- Buscar el bloqueo en Workspace
		local blockPart = workspace:FindFirstChild(blockName)
		if blockPart then
			-- Si es un Model, hacer invisibles todos los parts
			if blockPart:IsA("Model") then
				for _, part in ipairs(blockPart:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 1
						part.CanCollide = false
					end
					if part:IsA("Decal") or part:IsA("Texture") then
						part.Transparency = 1
					end
					if part:IsA("SurfaceGui") or part:IsA("BillboardGui") then
						part.Enabled = false
					end
				end
			elseif blockPart:IsA("BasePart") then
				blockPart.Transparency = 1
				blockPart.CanCollide = false
				-- También los hijos (decals, guis, etc.)
				for _, child in ipairs(blockPart:GetDescendants()) do
					if child:IsA("Decal") or child:IsA("Texture") then
						child.Transparency = 1
					end
					if child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
						child.Enabled = false
					end
				end
			end
			print("[BasesClient] Bloqueo " .. blockName .. " ahora invisible")
		else
			warn("[BasesClient] No se encontró el bloqueo: " .. blockName)
		end
	end)
end

-- Escuchar evento de error de monedas insuficientes
local insufficientFundsRemote = remotesFolder:FindFirstChild("BaseInsufficientFunds")
if not insufficientFundsRemote then
	insufficientFundsRemote = remotesFolder:WaitForChild("BaseInsufficientFunds", 5)
end

if insufficientFundsRemote then
	insufficientFundsRemote.OnClientEvent:Connect(function(baseName, required, current)
		showNotification(false, "Monedas insuficientes! Necesitas " .. formatNumber(required) .. "$")
	end)
end

print("[BasesClient] Cliente de bases desbloqueables inicializado")
