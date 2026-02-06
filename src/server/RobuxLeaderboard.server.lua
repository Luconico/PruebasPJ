--[[
	RobuxLeaderboard.server.lua

	Sistema de leaderboard para mostrar los jugadores que más
	Robux han gastado en el juego.

	Configuración:
	- Coloca un Model llamado "RobuxLeaderboard" en Workspace
	- Dentro del Model, debe haber una Part con SurfaceGui llamado "LeaderboardDisplay"
	- El SurfaceGui debe contener un Frame con los elementos del leaderboard

	Estructura esperada del GUI:
	- RobuxLeaderboard (Model)
	  - Display (Part)
	    - SurfaceGui
	      - Background (Frame)
	        - Title (TextLabel)
	        - ScrollingFrame o Frame con los slots
	          - Slot1, Slot2, ..., Slot10 (cada uno con: Rank, Avatar, Name, Amount)
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

	-- Debug mode
	DEBUG = true,
}

-- ============================================
-- VARIABLES
-- ============================================
local robuxLeaderboardStore = DataStoreService:GetOrderedDataStore(CONFIG.DATA_STORE_NAME)
local leaderboardModel = nil
local leaderboardGui = nil

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
-- BUSCAR EL LEADERBOARD EN WORKSPACE
-- ============================================

local function findLeaderboardGui()
	-- Buscar el modelo del leaderboard
	leaderboardModel = workspace:FindFirstChild(CONFIG.LEADERBOARD_MODEL_NAME)

	if not leaderboardModel then
		debugPrint("No se encontró el Model '" .. CONFIG.LEADERBOARD_MODEL_NAME .. "' en Workspace")
		debugPrint("Creando leaderboard de ejemplo...")
		return false
	end

	-- Buscar el SurfaceGui
	for _, child in pairs(leaderboardModel:GetDescendants()) do
		if child:IsA("SurfaceGui") then
			leaderboardGui = child
			debugPrint("SurfaceGui encontrado")
			return true
		end
	end

	debugPrint("No se encontró SurfaceGui dentro del leaderboard")
	return false
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
-- ACTUALIZAR EL GUI
-- ============================================

local function updateLeaderboardGui(data)
	if not leaderboardGui then
		debugPrint("No hay GUI para actualizar")
		return
	end

	-- Buscar el contenedor de slots (puede ser ScrollingFrame o Frame)
	local slotsContainer = leaderboardGui:FindFirstChild("SlotsContainer")
		or leaderboardGui:FindFirstChild("Slots")
		or leaderboardGui:FindFirstChild("Background")

	if not slotsContainer then
		debugPrint("No se encontró contenedor de slots")
		return
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
						rankLabel.TextColor3 = Color3.fromRGB(255, 215, 0)  -- Oro
					elseif playerData.Rank == 2 then
						rankLabel.TextColor3 = Color3.fromRGB(192, 192, 192)  -- Plata
					elseif playerData.Rank == 3 then
						rankLabel.TextColor3 = Color3.fromRGB(205, 127, 50)  -- Bronce
					else
						rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					end
				end

				-- Actualizar Avatar
				local avatarImage = slot:FindFirstChild("Avatar") or slot:FindFirstChild("Photo")
				if avatarImage then
					avatarImage.Image = playerData.Avatar
				end

				-- Actualizar Nombre
				local nameLabel = slot:FindFirstChild("Name") or slot:FindFirstChild("Username")
				if nameLabel then
					nameLabel.Text = playerData.Name
				end

				-- Actualizar Cantidad de Robux
				local amountLabel = slot:FindFirstChild("Amount") or slot:FindFirstChild("Score") or slot:FindFirstChild("Robux")
				if amountLabel then
					amountLabel.Text = formatRobux(playerData.RobuxSpent)
				end
			else
				-- Ocultar slot vacío
				slot.Visible = false
			end
		end
	end

	debugPrint("GUI actualizado")
end

-- ============================================
-- CREAR GUI DE EJEMPLO (si no existe)
-- ============================================

local function createExampleLeaderboard()
	-- Crear el modelo
	local model = Instance.new("Model")
	model.Name = CONFIG.LEADERBOARD_MODEL_NAME

	-- Crear la Part
	local part = Instance.new("Part")
	part.Name = "Display"
	part.Size = Vector3.new(12, 8, 0.5)
	part.Position = Vector3.new(0, 10, -50)
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.Color = Color3.fromRGB(30, 30, 40)
	part.Parent = model

	-- Crear SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "LeaderboardGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50
	surfaceGui.Parent = part

	-- Crear Background
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
	background.BorderSizePixel = 0
	background.Parent = surfaceGui

	-- Crear Título
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0.12, 0)
	title.Position = UDim2.new(0, 0, 0.02, 0)
	title.BackgroundTransparency = 1
	title.Text = "TOP ROBUX GASTADOS"
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.TextScaled = true
	title.Font = Enum.Font.GothamBold
	title.Parent = background

	-- Crear contenedor de slots
	local slotsContainer = Instance.new("Frame")
	slotsContainer.Name = "SlotsContainer"
	slotsContainer.Size = UDim2.new(0.95, 0, 0.82, 0)
	slotsContainer.Position = UDim2.new(0.025, 0, 0.15, 0)
	slotsContainer.BackgroundTransparency = 1
	slotsContainer.Parent = background

	-- Layout para los slots
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0.01, 0)
	listLayout.Parent = slotsContainer

	-- Crear 10 slots
	for i = 1, 10 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(1, 0, 0.09, 0)
		slot.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
		slot.BorderSizePixel = 0
		slot.LayoutOrder = i
		slot.Visible = false
		slot.Parent = slotsContainer

		-- Esquinas redondeadas
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.3, 0)
		corner.Parent = slot

		-- Rank
		local rank = Instance.new("TextLabel")
		rank.Name = "Rank"
		rank.Size = UDim2.new(0.1, 0, 1, 0)
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
		avatar.Size = UDim2.new(0.08, 0, 0.8, 0)
		avatar.Position = UDim2.new(0.13, 0, 0.1, 0)
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
		name.Size = UDim2.new(0.45, 0, 1, 0)
		name.Position = UDim2.new(0.23, 0, 0, 0)
		name.BackgroundTransparency = 1
		name.Text = "Loading..."
		name.TextColor3 = Color3.fromRGB(255, 255, 255)
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Font = Enum.Font.Gotham
		name.Parent = slot

		-- Cantidad
		local amount = Instance.new("TextLabel")
		amount.Name = "Amount"
		amount.Size = UDim2.new(0.25, 0, 1, 0)
		amount.Position = UDim2.new(0.72, 0, 0, 0)
		amount.BackgroundTransparency = 1
		amount.Text = "0 R$"
		amount.TextColor3 = Color3.fromRGB(0, 255, 127)
		amount.TextScaled = true
		amount.TextXAlignment = Enum.TextXAlignment.Right
		amount.Font = Enum.Font.GothamBold
		amount.Parent = slot
	end

	model.Parent = workspace
	leaderboardModel = model
	leaderboardGui = surfaceGui

	debugPrint("Leaderboard de ejemplo creado en Workspace")
	return true
end

-- ============================================
-- LOOP DE ACTUALIZACIÓN
-- ============================================

local function startUpdateLoop()
	-- Primera actualización inmediata
	task.spawn(function()
		task.wait(2) -- Esperar a que el DataStore esté listo
		local data = getLeaderboardData()
		updateLeaderboardGui(data)
	end)

	-- Loop de actualización
	while true do
		task.wait(CONFIG.UPDATE_INTERVAL)
		local data = getLeaderboardData()
		updateLeaderboardGui(data)
	end
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

local function init()
	debugPrint("Inicializando sistema de RobuxLeaderboard...")

	-- Solo ejecutar en el servidor
	if RunService:IsClient() then
		debugPrint("Este script debe ejecutarse en el servidor")
		return
	end

	-- Buscar o crear el leaderboard
	if not findLeaderboardGui() then
		-- Si no existe, crear uno de ejemplo
		createExampleLeaderboard()
	end

	-- Iniciar loop de actualización
	startUpdateLoop()
end

-- Iniciar
init()

print("[RobuxLeaderboard] Sistema inicializado correctamente")
