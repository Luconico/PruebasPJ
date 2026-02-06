--[[
	RobuxLeaderboard.server.lua

	Sistema de leaderboard para mostrar los jugadores que más
	Robux han gastado en el juego.

	INSTRUCCIONES:
	1. El script crea automáticamente un tablero si no existe "RobuxLeaderboard" en Workspace
	2. O puedes crear manualmente un Model llamado "RobuxLeaderboard" con un Part y SurfaceGui
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

-- ============================================
-- CONFIGURACIÓN
-- ============================================
local CONFIG = {
	-- Nombre del OrderedDataStore (debe coincidir con PlayerData)
	DATA_STORE_NAME = "RobuxLeaderboard_v1",

	-- Cantidad de jugadores a mostrar
	TOP_PLAYERS = 10,

	-- Intervalo de actualización del leaderboard (en segundos)
	UPDATE_INTERVAL = 60,

	-- Nombre del Model en Workspace
	LEADERBOARD_MODEL_NAME = "RobuxLeaderboard",

	-- Posición del leaderboard si se crea automáticamente
	AUTO_POSITION = Vector3.new(0, 10, -50),

	-- Debug mode
	DEBUG = true,
}

-- ============================================
-- VARIABLES
-- ============================================
local robuxLeaderboardStore = DataStoreService:GetOrderedDataStore(CONFIG.DATA_STORE_NAME)
local leaderboardModel = nil
local leaderboardGui = nil
local timerLabel = nil
local nextUpdateTime = 0

-- Cache para nombres y avatares
local usernameCache = {}
local avatarCache = {}

-- ============================================
-- FUNCIONES AUXILIARES
-- ============================================

local function debugPrint(...)
	if CONFIG.DEBUG then
		print("[RobuxLeaderboard]", ...)
	end
end

local function getUsernameAsync(userId)
	if usernameCache[userId] then
		return usernameCache[userId]
	end

	local success, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)

	if success then
		usernameCache[userId] = name
		return name
	else
		debugPrint("Error obteniendo nombre para userId:", userId)
		return "Unknown"
	end
end

local function getAvatarAsync(userId)
	if avatarCache[userId] then
		return avatarCache[userId]
	end

	local success, thumbnail = pcall(function()
		return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)

	if success then
		avatarCache[userId] = thumbnail
		return thumbnail
	else
		debugPrint("Error obteniendo avatar para userId:", userId)
		return "rbxassetid://5107154082" -- Default avatar
	end
end

local function formatRobux(amount)
	if amount >= 1000000 then
		return string.format("%.1fM R$", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK R$", amount / 1000)
	else
		return string.format("%d R$", amount)
	end
end

-- ============================================
-- OBTENER DATOS DEL LEADERBOARD
-- ============================================

local function getLeaderboardData()
	local success, pages = pcall(function()
		return robuxLeaderboardStore:GetSortedAsync(false, CONFIG.TOP_PLAYERS, 1)
	end)

	if not success then
		debugPrint("Error obteniendo datos del leaderboard:", pages)
		return {}
	end

	local topPlayers = {}
	local currentPage = pages:GetCurrentPage()

	for rank, data in ipairs(currentPage) do
		local userId = tonumber(data.key)
		local robuxSpent = data.value

		if userId and userId > 0 then
			table.insert(topPlayers, {
				Rank = rank,
				UserId = userId,
				Name = getUsernameAsync(userId),
				Avatar = getAvatarAsync(userId),
				RobuxSpent = robuxSpent,
			})
		end
	end

	debugPrint("Datos obtenidos:", #topPlayers, "jugadores")
	return topPlayers
end

-- ============================================
-- CREAR GUI DEL LEADERBOARD
-- ============================================

local function createLeaderboardGui()
	debugPrint("Creando leaderboard en Workspace...")

	-- Crear el modelo
	local model = Instance.new("Model")
	model.Name = CONFIG.LEADERBOARD_MODEL_NAME

	-- Crear la Part principal
	local part = Instance.new("Part")
	part.Name = "Display"
	part.Size = Vector3.new(14, 10, 0.5)
	part.Position = CONFIG.AUTO_POSITION
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(20, 20, 30)
	part.Parent = model

	-- Crear SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = part

	-- Crear Background principal
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
	background.BorderSizePixel = 0
	background.Parent = surfaceGui

	-- Gradiente de fondo
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 25, 40)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20)),
	})
	gradient.Rotation = 90
	gradient.Parent = background

	-- Header con icono
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0.12, 0)
	header.Position = UDim2.new(0, 0, 0.01, 0)
	header.BackgroundTransparency = 1
	header.Parent = background

	local robuxIcon = Instance.new("TextLabel")
	robuxIcon.Name = "Icon"
	robuxIcon.Size = UDim2.new(0.1, 0, 1, 0)
	robuxIcon.Position = UDim2.new(0.02, 0, 0, 0)
	robuxIcon.BackgroundTransparency = 1
	robuxIcon.Text = "R$"
	robuxIcon.TextColor3 = Color3.fromRGB(0, 255, 127)
	robuxIcon.TextScaled = true
	robuxIcon.Font = Enum.Font.GothamBold
	robuxIcon.Parent = header

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.75, 0, 1, 0)
	title.Position = UDim2.new(0.12, 0, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "TOP ROBUX GASTADOS"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	-- Timer de actualización
	local timer = Instance.new("TextLabel")
	timer.Name = "Timer"
	timer.Size = UDim2.new(0.25, 0, 0.6, 0)
	timer.Position = UDim2.new(0.73, 0, 0.2, 0)
	timer.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	timer.BorderSizePixel = 0
	timer.Text = "Actualiza en: 60s"
	timer.TextColor3 = Color3.fromRGB(150, 150, 180)
	timer.TextScaled = true
	timer.Font = Enum.Font.Gotham
	timer.Parent = header
	timerLabel = timer

	local timerCorner = Instance.new("UICorner")
	timerCorner.CornerRadius = UDim.new(0.3, 0)
	timerCorner.Parent = timer

	-- Línea separadora
	local separator = Instance.new("Frame")
	separator.Name = "Separator"
	separator.Size = UDim2.new(0.96, 0, 0.003, 0)
	separator.Position = UDim2.new(0.02, 0, 0.13, 0)
	separator.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	separator.BorderSizePixel = 0
	separator.Parent = background

	-- Contenedor de slots
	local slotsContainer = Instance.new("Frame")
	slotsContainer.Name = "SlotsContainer"
	slotsContainer.Size = UDim2.new(0.96, 0, 0.82, 0)
	slotsContainer.Position = UDim2.new(0.02, 0, 0.15, 0)
	slotsContainer.BackgroundTransparency = 1
	slotsContainer.Parent = background

	-- Layout para los slots
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0.008, 0)
	listLayout.Parent = slotsContainer

	-- Crear 10 slots
	for i = 1, 10 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(1, 0, 0.092, 0)
		slot.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
		slot.BorderSizePixel = 0
		slot.LayoutOrder = i
		slot.Visible = false
		slot.Parent = slotsContainer

		-- Esquinas redondeadas
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.25, 0)
		corner.Parent = slot

		-- Borde para top 3
		if i <= 3 then
			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2
			if i == 1 then
				stroke.Color = Color3.fromRGB(255, 215, 0) -- Oro
			elseif i == 2 then
				stroke.Color = Color3.fromRGB(192, 192, 192) -- Plata
			else
				stroke.Color = Color3.fromRGB(205, 127, 50) -- Bronce
			end
			stroke.Parent = slot
		end

		-- Rank
		local rank = Instance.new("TextLabel")
		rank.Name = "Rank"
		rank.Size = UDim2.new(0.08, 0, 1, 0)
		rank.Position = UDim2.new(0.02, 0, 0, 0)
		rank.BackgroundTransparency = 1
		rank.Text = "#" .. i
		rank.TextColor3 = Color3.fromRGB(255, 255, 255)
		rank.TextScaled = true
		rank.Font = Enum.Font.GothamBold
		rank.Parent = slot

		-- Avatar
		local avatar = Instance.new("ImageLabel")
		avatar.Name = "Avatar"
		avatar.Size = UDim2.new(0.07, 0, 0.8, 0)
		avatar.Position = UDim2.new(0.11, 0, 0.1, 0)
		avatar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		avatar.BorderSizePixel = 0
		avatar.Image = ""
		avatar.Parent = slot

		local avatarCorner = Instance.new("UICorner")
		avatarCorner.CornerRadius = UDim.new(0.5, 0)
		avatarCorner.Parent = avatar

		-- Nombre
		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.Size = UDim2.new(0.48, 0, 1, 0)
		name.Position = UDim2.new(0.2, 0, 0, 0)
		name.BackgroundTransparency = 1
		name.Text = "Loading..."
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Font = Enum.Font.Gotham
		name.Parent = slot

		-- Cantidad con icono
		local amountFrame = Instance.new("Frame")
		amountFrame.Name = "AmountFrame"
		amountFrame.Size = UDim2.new(0.28, 0, 0.7, 0)
		amountFrame.Position = UDim2.new(0.7, 0, 0.15, 0)
		amountFrame.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
		amountFrame.BorderSizePixel = 0
		amountFrame.Parent = slot

		local amountCorner = Instance.new("UICorner")
		amountCorner.CornerRadius = UDim.new(0.3, 0)
		amountCorner.Parent = amountFrame

		local amount = Instance.new("TextLabel")
		amount.Name = "Amount"
		amount.Size = UDim2.new(1, 0, 1, 0)
		amount.BackgroundTransparency = 1
		amount.Text = "0 R$"
		amount.TextColor3 = Color3.fromRGB(255, 255, 255)
		amount.TextScaled = true
		amount.Font = Enum.Font.GothamBold
		amount.Parent = amountFrame
	end

	-- Mensaje cuando no hay datos
	local noDataLabel = Instance.new("TextLabel")
	noDataLabel.Name = "NoData"
	noDataLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
	noDataLabel.Position = UDim2.new(0.1, 0, 0.35, 0)
	noDataLabel.BackgroundTransparency = 1
	noDataLabel.Text = "No hay datos aun...\nGasta Robux para aparecer aqui!"
	noDataLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
	noDataLabel.TextScaled = true
	noDataLabel.Font = Enum.Font.Gotham
	noDataLabel.Visible = true
	noDataLabel.Parent = slotsContainer

	model.Parent = workspace
	leaderboardModel = model
	leaderboardGui = surfaceGui

	debugPrint("Leaderboard creado en:", CONFIG.AUTO_POSITION)
	return surfaceGui
end

-- ============================================
-- ACTUALIZAR EL GUI
-- ============================================

local function updateLeaderboardGui(data)
	if not leaderboardGui then
		debugPrint("No hay GUI para actualizar")
		return
	end

	local background = leaderboardGui:FindFirstChild("Background")
	if not background then return end

	local slotsContainer = background:FindFirstChild("SlotsContainer")
	if not slotsContainer then return end

	local noDataLabel = slotsContainer:FindFirstChild("NoData")

	-- Mostrar/ocultar mensaje de no datos
	if noDataLabel then
		noDataLabel.Visible = (#data == 0)
	end

	-- Actualizar cada slot
	for i = 1, CONFIG.TOP_PLAYERS do
		local slotName = "Slot" .. i
		local slot = slotsContainer:FindFirstChild(slotName)

		if slot then
			local playerData = data[i]

			if playerData then
				-- Mostrar datos del jugador
				slot.Visible = true

				-- Actualizar Rank
				local rankLabel = slot:FindFirstChild("Rank")
				if rankLabel then
					rankLabel.Text = "#" .. playerData.Rank
					-- Colores especiales para top 3
					if playerData.Rank == 1 then
						rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
					elseif playerData.Rank == 2 then
						rankLabel.TextColor3 = Color3.fromRGB(192, 192, 192)
					elseif playerData.Rank == 3 then
						rankLabel.TextColor3 = Color3.fromRGB(205, 127, 50)
					else
						rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					end
				end

				-- Actualizar Avatar
				local avatarImage = slot:FindFirstChild("Avatar")
				if avatarImage then
					avatarImage.Image = playerData.Avatar
				end

				-- Actualizar Nombre
				local nameLabel = slot:FindFirstChild("Name")
				if nameLabel then
					nameLabel.Text = playerData.Name
				end

				-- Actualizar Cantidad de Robux
				local amountFrame = slot:FindFirstChild("AmountFrame")
				if amountFrame then
					local amountLabel = amountFrame:FindFirstChild("Amount")
					if amountLabel then
						amountLabel.Text = formatRobux(playerData.RobuxSpent)
					end
				end
			else
				-- Ocultar slot vacío
				slot.Visible = false
			end
		end
	end

	debugPrint("GUI actualizado con", #data, "jugadores")
end

-- ============================================
-- LOOP PRINCIPAL
-- ============================================

local function mainLoop()
	-- Primera actualización
	debugPrint("Esperando 3 segundos antes de la primera actualización...")
	task.wait(3)

	while true do
		-- Obtener y mostrar datos
		debugPrint("Actualizando leaderboard...")
		local data = getLeaderboardData()
		updateLeaderboardGui(data)

		-- Establecer tiempo de próxima actualización
		nextUpdateTime = tick() + CONFIG.UPDATE_INTERVAL

		-- Loop del timer
		while tick() < nextUpdateTime do
			local remaining = math.ceil(nextUpdateTime - tick())
			if timerLabel then
				timerLabel.Text = "Actualiza: " .. remaining .. "s"
			end
			task.wait(1)
		end
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

local function init()
	debugPrint("Inicializando sistema de RobuxLeaderboard...")

	-- Solo ejecutar en el servidor
	if RunService:IsClient() then
		warn("[RobuxLeaderboard] Este script debe ejecutarse en el servidor")
		return
	end

	-- Buscar leaderboard existente o crear uno nuevo
	local existingModel = workspace:FindFirstChild(CONFIG.LEADERBOARD_MODEL_NAME)
	if existingModel then
		debugPrint("Leaderboard existente encontrado")
		leaderboardModel = existingModel

		-- Buscar el SurfaceGui
		for _, child in pairs(existingModel:GetDescendants()) do
			if child:IsA("SurfaceGui") then
				leaderboardGui = child
				-- Buscar timer existente
				local bg = leaderboardGui:FindFirstChild("Background")
				if bg then
					local header = bg:FindFirstChild("Header")
					if header then
						timerLabel = header:FindFirstChild("Timer")
					end
				end
				break
			end
		end

		if not leaderboardGui then
			debugPrint("SurfaceGui no encontrado, creando nuevo leaderboard...")
			existingModel:Destroy()
			createLeaderboardGui()
		end
	else
		createLeaderboardGui()
	end

	-- Iniciar loop principal
	task.spawn(mainLoop)
end

-- Iniciar
init()

print("[RobuxLeaderboard] Sistema inicializado - Actualiza cada", CONFIG.UPDATE_INTERVAL, "segundos")
