local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================
-- SISTEMA DE SONIDOS (IDs verificados de Roblox)
-- ============================================
local SOUNDS = {
	PopupOpen = "rbxassetid://2235655773",      -- Swoosh Sound Effect
	PopupClose = "rbxassetid://231731980",      -- Whoosh
	ButtonHover = "rbxassetid://6324801967",    -- Button hover (cartoony)
	ButtonClick = "rbxassetid://4307186075",    -- Click sound (cartoony/bubble)
	PurchaseSuccess = "rbxassetid://1837507072", -- Final Fantasy VII - Victory Fanfare
	CashRegister = "rbxassetid://7112275565",   -- Cash Register (Kaching)
	Sparkle = "rbxassetid://3292075199",        -- Sparkle Noise
	UnlockZone = "rbxassetid://6042053626",     -- Button Click (unlock sound)
}

local function playSound(soundId, volume, pitch)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	return sound
end

-- Esperar a la carpeta Remotes que ya existe
local remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 30)
if not remotesFolder then
	warn("❌ No se encontró la carpeta Remotes")
	return
end

print("🔄 Esperando RemoteEvents del servidor...")

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
		print("✅ Cliente de zonas: RemoteEvents encontrados (intento " .. attempt .. ")")
		break
	end

	task.wait(0.5)
end

if not showZoneUIRemote or not unlockZoneRemote then
	warn("❌ No se encontraron los RemoteEvents de zonas después de " .. maxAttempts .. " intentos.")
	warn("❌ Verifica que DesbloqueoZonasServer esté en ServerScriptService y se esté ejecutando.")
	return
end

-- Variable para guardar la UI actual
local currentZoneUI = nil
local currentZoneName = nil

-- Función para crear la UI de desbloqueo
local function createZoneUI(zoneName, coinsCost, robuxCost)
	print("🎨 Creando UI para zona: " .. zoneName)

	-- Si ya existe una UI, destruirla
	if currentZoneUI then
		currentZoneUI:Destroy()
		print("🗑️ UI anterior destruida")
	end

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
	mainFrame.Size = UDim2.new(0, 400, 0, 300)
	mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = background

	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 15)
	corner.Parent = mainFrame

	-- Título
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -40, 0, 50)
	title.Position = UDim2.new(0, 20, 0, 20)
	title.BackgroundTransparency = 1
	title.Text = "🔒 " .. zoneName
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
	subtitle.Text = "¿Pagar para desbloquear?"
	subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
	subtitle.TextSize = 18
	subtitle.Font = Enum.Font.Gotham
	subtitle.TextXAlignment = Enum.TextXAlignment.Center
	subtitle.Parent = mainFrame

	-- Botón de monedas
	local coinsButton = Instance.new("TextButton")
	coinsButton.Name = "CoinsButton"
	coinsButton.Size = UDim2.new(1, -40, 0, 60)
	coinsButton.Position = UDim2.new(0, 20, 0, 130)
	coinsButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Amarillo oro
	coinsButton.BorderSizePixel = 0
	coinsButton.Text = "💰 " .. coinsCost .. "$"
	coinsButton.TextColor3 = Color3.fromRGB(0, 0, 0)
	coinsButton.TextSize = 24
	coinsButton.Font = Enum.Font.GothamBold
	coinsButton.AutoButtonColor = false
	coinsButton.Parent = mainFrame

	local coinsCorner = Instance.new("UICorner")
	coinsCorner.CornerRadius = UDim.new(0, 10)
	coinsCorner.Parent = coinsButton

	-- Botón de Robux
	local robuxButton = Instance.new("TextButton")
	robuxButton.Name = "RobuxButton"
	robuxButton.Size = UDim2.new(1, -40, 0, 60)
	robuxButton.Position = UDim2.new(0, 20, 0, 200)
	robuxButton.BackgroundColor3 = Color3.fromRGB(0, 230, 118) -- Verde infantil
	robuxButton.BorderSizePixel = 0
	robuxButton.Text = "💎 " .. robuxCost .. " Robux"
	robuxButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	robuxButton.TextSize = 24
	robuxButton.Font = Enum.Font.GothamBold
	robuxButton.AutoButtonColor = false
	robuxButton.Parent = mainFrame

	local robuxCorner = Instance.new("UICorner")
	robuxCorner.CornerRadius = UDim.new(0, 10)
	robuxCorner.Parent = robuxButton

	-- Botón de cerrar
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 40, 0, 40)
	closeButton.Position = UDim2.new(1, -50, 0, 10)
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Text = "✕"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextSize = 24
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeButton

	-- Efecto hover para botón de monedas (plateado)
	local hoverTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	coinsButton.MouseEnter:Connect(function()
		playSound(SOUNDS.ButtonHover, 0.2, 1.1)
		local tween = TweenService:Create(coinsButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(192, 192, 192) -- Plateado
		})
		tween:Play()
	end)

	coinsButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(coinsButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(255, 215, 0) -- Amarillo oro
		})
		tween:Play()
	end)

	-- Efecto hover para botón de Robux (mismo plateado)
	robuxButton.MouseEnter:Connect(function()
		playSound(SOUNDS.ButtonHover, 0.2, 1.1)
		local tween = TweenService:Create(robuxButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(192, 192, 192) -- Plateado
		})
		tween:Play()
	end)

	robuxButton.MouseLeave:Connect(function()
		local tween = TweenService:Create(robuxButton, hoverTweenInfo, {
			BackgroundColor3 = Color3.fromRGB(0, 230, 118) -- Verde infantil
		})
		tween:Play()
	end)

	-- Eventos de click
	coinsButton.MouseButton1Click:Connect(function()
		playSound(SOUNDS.ButtonClick, 0.5, 1.0)
		playSound(SOUNDS.CashRegister, 0.4, 1.1)
		-- Enviar al servidor para desbloquear con monedas
		unlockZoneRemote:FireServer(currentZoneName, "coins")
		playSound(SOUNDS.PopupClose, 0.3, 1.3)
		screenGui:Destroy()
		currentZoneUI = nil
	end)

	robuxButton.MouseButton1Click:Connect(function()
		playSound(SOUNDS.ButtonClick, 0.5, 1.0)
		playSound(SOUNDS.CashRegister, 0.4, 1.1)
		-- Enviar al servidor para desbloquear con Robux
		unlockZoneRemote:FireServer(currentZoneName, "robux")
		playSound(SOUNDS.PopupClose, 0.3, 1.3)
		screenGui:Destroy()
		currentZoneUI = nil
	end)

	closeButton.MouseEnter:Connect(function()
		playSound(SOUNDS.ButtonHover, 0.2, 1.2)
	end)

	closeButton.MouseButton1Click:Connect(function()
		playSound(SOUNDS.ButtonClick, 0.4, 1.1)
		playSound(SOUNDS.PopupClose, 0.3, 1.3)
		screenGui:Destroy()
		currentZoneUI = nil
	end)

	-- Cerrar al hacer click en el fondo
	background.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			screenGui:Destroy()
			currentZoneUI = nil
		end
	end)

	-- 🔊 Sonido de apertura del popup
	playSound(SOUNDS.PopupOpen, 0.4, 0.9)
	task.delay(0.15, function()
		playSound(SOUNDS.Sparkle, 0.3, 1.2)
	end)

	-- Animación de entrada
	mainFrame.Size = UDim2.new(0, 0, 0, 0)
	local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 300)
	})
	openTween:Play()

	currentZoneUI = screenGui
end

-- Escuchar evento del servidor para mostrar UI
showZoneUIRemote.OnClientEvent:Connect(function(zoneName, coinsCost, robuxCost)
	print("📥 Cliente recibió petición de UI para: " .. zoneName)

	-- Si ya hay una UI abierta, no crear otra
	if currentZoneUI then
		print("⚠️ Ya hay una UI abierta, ignorando petición")
		return
	end

	print("   Coins: " .. coinsCost .. ", Robux: " .. robuxCost)
	currentZoneName = zoneName
	createZoneUI(zoneName, coinsCost, robuxCost)
	print("✅ UI creada")
end)

-- Escuchar evento para hacer zona invisible
local makeInvisibleRemote = remotesFolder:FindFirstChild("MakeZoneInvisible")
if not makeInvisibleRemote then
	makeInvisibleRemote = remotesFolder:WaitForChild("MakeZoneInvisible", 5)
end

if makeInvisibleRemote then
	makeInvisibleRemote.OnClientEvent:Connect(function(zoneName)
		-- 🔊 Sonidos de celebración al desbloquear zona
		playSound(SOUNDS.PurchaseSuccess, 0.6, 1.0)
		task.delay(0.1, function()
			playSound(SOUNDS.CashRegister, 0.5, 1.1)
		end)
		task.delay(0.3, function()
			playSound(SOUNDS.Sparkle, 0.5, 0.9)
		end)
		task.delay(0.6, function()
			playSound(SOUNDS.Sparkle, 0.4, 1.3)
		end)
		print("👻 Haciendo " .. zoneName .. " invisible localmente")

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
				print("✅ Zona " .. zoneName .. " ahora invisible")
			end
		end
	end)
end

print("✅ Cliente de zonas desbloqueables inicializado")
