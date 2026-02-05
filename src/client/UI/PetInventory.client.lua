--[[
	PetInventory.client.lua
	UI de inventario de mascotas
	Gestión de mascotas: equipar, desequipar, bloquear, eliminar
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
local Config = require(Shared:WaitForChild("Config"))
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))
local SoundManager = require(Shared:WaitForChild("SoundManager"))
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))

-- Tamaños responsive
local function getResponsiveSizes()
	local info = ResponsiveUI.getViewportInfo()
	local scale = info.Scale
	local isMobile = info.IsMobile

	return {
		ContainerWidth = isMobile and 0.95 or 0.8,
		ContainerHeight = isMobile and 0.9 or 0.8,
		HeaderHeight = isMobile and 80 or math.floor(100 * scale),
		TitleSize = isMobile and 28 or math.floor(42 * scale),
		CardSize = isMobile and 140 or math.floor(180 * scale),
		CardPadding = isMobile and 10 or math.floor(14 * scale),
		IconSize = isMobile and 60 or math.floor(80 * scale),
		ButtonHeight = isMobile and 35 or math.floor(42 * scale),
		ButtonTextSize = isMobile and 14 or math.floor(18 * scale),
		TextSize = isMobile and 14 or math.floor(18 * scale),
		CornerRadius = isMobile and 12 or math.floor(18 * scale),
		IsMobile = isMobile,
	}
end

local sizes = getResponsiveSizes()

-- Estilos
local Styles = {
	Colors = {
		Background = Color3.fromRGB(25, 25, 45),
		Header = Color3.fromRGB(100, 180, 255),
		Card = Color3.fromRGB(45, 45, 75),
		CardEquipped = Color3.fromRGB(60, 120, 60),
		ButtonEquip = Color3.fromRGB(100, 200, 100),
		ButtonUnequip = Color3.fromRGB(255, 150, 80),
		ButtonLock = Color3.fromRGB(255, 200, 50),
		ButtonDelete = Color3.fromRGB(255, 80, 80),
		Text = Color3.fromRGB(255, 255, 255),
		TextDark = Color3.fromRGB(40, 40, 60),
		TextMuted = Color3.fromRGB(180, 180, 200),
	},
	Fonts = {
		Title = Enum.Font.FredokaOne,
		Body = Enum.Font.GothamBold,
	},
}

-- Estado
local pets = {}
local inventoryOpen = false

-- ============================================
-- CREAR UI
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "PetInventory"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

-- Backdrop
local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.Size = UDim2.new(1, 0, 1, 0)
backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
backdrop.BackgroundTransparency = 0.5
backdrop.BorderSizePixel = 0
backdrop.Visible = false
backdrop.Parent = screenGui

-- Main container
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.AnchorPoint = Vector2.new(0.5, 0.5)
mainContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
mainContainer.Size = UDim2.new(sizes.ContainerWidth, 0, sizes.ContainerHeight, 0)
mainContainer.BackgroundColor3 = Styles.Colors.Background
mainContainer.BorderSizePixel = 0
mainContainer.Parent = backdrop

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
mainCorner.Parent = mainContainer

-- Header (usando UIComponentsManager)
local navbar, titleLabel, statsLabel = UIComponentsManager.createNavbar(mainContainer, {
	height = sizes.HeaderHeight,
	color = Styles.Colors.Header,
	cornerRadius = sizes.CornerRadius,
	title = "🐾 PET INVENTORY 🐾",
	titleSize = sizes.TitleSize,
	titleFont = Styles.Fonts.Title,
	rightText = "0/50 | 0/3 equipped",
	rightTextSize = sizes.TextSize,
	rightTextFont = Styles.Fonts.Body,
})

-- Close button (usando UIComponentsManager)
local closeButton = UIComponentsManager.createCloseButton(mainContainer, {
	size = 52,
	onClose = function()
		SoundManager.playClose()
		backdrop.Visible = false
		inventoryOpen = false
	end
})
closeButton.ZIndex = 10

-- Content container
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Name = "ContentContainer"
contentContainer.Position = UDim2.new(0, 0, 0, sizes.HeaderHeight)
contentContainer.Size = UDim2.new(1, 0, 1, -sizes.HeaderHeight)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.ScrollBarThickness = 8
contentContainer.Parent = mainContainer

local contentPadding = Instance.new("UIPadding")
contentPadding.PaddingTop = UDim.new(0, 20)
contentPadding.PaddingBottom = UDim.new(0, 20)
contentPadding.PaddingLeft = UDim.new(0, 20)
contentPadding.PaddingRight = UDim.new(0, 20)
contentPadding.Parent = contentContainer

local contentLayout = Instance.new("UIGridLayout")
contentLayout.CellSize = UDim2.new(0, sizes.CardSize, 0, sizes.CardSize + 60)
contentLayout.CellPadding = UDim2.new(0, sizes.CardPadding, 0, sizes.CardPadding)
contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
contentLayout.SortOrder = Enum.SortOrder.LayoutOrder
contentLayout.Parent = contentContainer

-- ============================================
-- CREAR TARJETA DE MASCOTA
-- ============================================

local function createPetCard(pet)
	local petConfig = Config.Pets[pet.PetName]
	if not petConfig then return end

	local card = Instance.new("Frame")
	card.Name = pet.UUID
	card.BackgroundColor3 = pet.Equiped and Styles.Colors.CardEquipped or Styles.Colors.Card
	card.BorderSizePixel = 0
	card.Parent = contentContainer

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, sizes.CornerRadius)
	cardCorner.Parent = card

	-- Icono
	local icon = Instance.new("TextLabel")
	icon.Size = UDim2.new(0, sizes.IconSize, 0, sizes.IconSize)
	icon.Position = UDim2.new(0.5, 0, 0, 10)
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.BackgroundTransparency = 1
	icon.Text = petConfig.Icon
	icon.Font = Enum.Font.SourceSans
	icon.TextSize = sizes.IconSize * 0.8
	icon.Parent = card

	-- Nombre
	local name = Instance.new("TextLabel")
	name.Size = UDim2.new(1, -10, 0, 25)
	name.Position = UDim2.new(0.5, 0, 0, sizes.IconSize + 15)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.BackgroundTransparency = 1
	name.Text = petConfig.Name
	name.Font = Styles.Fonts.Body
	name.TextSize = sizes.TextSize
	name.TextColor3 = Styles.Colors.Text
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Parent = card

	-- Boost
	local boost = Instance.new("TextLabel")
	boost.Size = UDim2.new(1, -10, 0, 20)
	boost.Position = UDim2.new(0.5, 0, 0, sizes.IconSize + 40)
	boost.AnchorPoint = Vector2.new(0.5, 0)
	boost.BackgroundTransparency = 1
	boost.Text = "+" .. math.floor(petConfig.Boost * 100) .. "% 💰"
	boost.Font = Styles.Fonts.Body
	boost.TextSize = sizes.TextSize - 4
	boost.TextColor3 = Color3.fromRGB(100, 255, 100)
	boost.Parent = card

	-- Botones container
	local buttonsContainer = Instance.new("Frame")
	buttonsContainer.Size = UDim2.new(1, -20, 0, sizes.ButtonHeight)
	buttonsContainer.Position = UDim2.new(0.5, 0, 1, -sizes.ButtonHeight - 10)
	buttonsContainer.AnchorPoint = Vector2.new(0.5, 0)
	buttonsContainer.BackgroundTransparency = 1
	buttonsContainer.Parent = card

	local buttonLayout = Instance.new("UIListLayout")
	buttonLayout.FillDirection = Enum.FillDirection.Horizontal
	buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	buttonLayout.Padding = UDim.new(0, 5)
	buttonLayout.Parent = buttonsContainer

	-- Botón Equip/Unequip
	local equipButton = Instance.new("TextButton")
	equipButton.Size = UDim2.new(0.55, 0, 1, 0)
	equipButton.BackgroundColor3 = pet.Equiped and Styles.Colors.ButtonUnequip or Styles.Colors.ButtonEquip
	equipButton.Text = pet.Equiped and "Unequip" or "Equip"
	equipButton.Font = Styles.Fonts.Body
	equipButton.TextSize = sizes.ButtonTextSize
	equipButton.TextColor3 = Styles.Colors.Text
	equipButton.Parent = buttonsContainer

	local equipCorner = Instance.new("UICorner")
	equipCorner.CornerRadius = UDim.new(0, sizes.CornerRadius * 0.7)
	equipCorner.Parent = equipButton

	equipButton.MouseButton1Click:Connect(function()
		local remoteName = pet.Equiped and "UnequipPet" or "EquipPet"
		local success, result = pcall(function()
			return Remotes[remoteName]:InvokeServer(pet.UUID)
		end)

		if not success then
			warn("[PetInventory] Error:", result)
		end
		-- La UI se actualiza automáticamente via OnDataUpdated
	end)

	-- Botón Lock
	local lockButton = Instance.new("TextButton")
	lockButton.Size = UDim2.new(0.20, 0, 1, 0)
	lockButton.BackgroundColor3 = pet.Locked and Styles.Colors.ButtonLock or Color3.fromRGB(100, 100, 120)
	lockButton.Text = pet.Locked and "🔒" or "🔓"
	lockButton.Font = Styles.Fonts.Body
	lockButton.TextSize = sizes.ButtonTextSize
	lockButton.Parent = buttonsContainer

	local lockCorner = Instance.new("UICorner")
	lockCorner.CornerRadius = UDim.new(0, sizes.CornerRadius * 0.7)
	lockCorner.Parent = lockButton

	lockButton.MouseButton1Click:Connect(function()
		local success = pcall(function()
			return Remotes.LockPet:InvokeServer(pet.UUID)
		end)
		-- La UI se actualiza automáticamente via OnDataUpdated
	end)

	-- Botón Delete
	local deleteButton = Instance.new("TextButton")
	deleteButton.Size = UDim2.new(0.20, 0, 1, 0)
	deleteButton.BackgroundColor3 = Styles.Colors.ButtonDelete
	deleteButton.Text = "🗑️"
	deleteButton.Font = Styles.Fonts.Body
	deleteButton.TextSize = sizes.ButtonTextSize
	deleteButton.Parent = buttonsContainer

	local deleteCorner = Instance.new("UICorner")
	deleteCorner.CornerRadius = UDim.new(0, sizes.CornerRadius * 0.7)
	deleteCorner.Parent = deleteButton

	deleteButton.MouseButton1Click:Connect(function()
		if pet.Locked then
			warn("[PetInventory] Mascota bloqueada")
			return
		end

		local success = pcall(function()
			return Remotes.DeletePet:InvokeServer(pet.UUID)
		end)
		-- La UI se actualiza automáticamente via OnDataUpdated
	end)
end

-- ============================================
-- ACTUALIZAR INVENTARIO
-- ============================================

function updateInventory()
	-- Limpiar tarjetas existentes (ignorar UIPadding y UIGridLayout)
	for _, child in ipairs(contentContainer:GetChildren()) do
		if child:IsA("Frame") and child.Name ~= "UIPadding" and child.Name ~= "UIGridLayout" then
			child:Destroy()
		end
	end

	-- Obtener mascotas del servidor
	local success, result = pcall(function()
		return Remotes.GetPets:InvokeServer()
	end)

	if success then
		pets = result or {}
	end

	-- Obtener stats
	local statsSuccess, stats = pcall(function()
		return Remotes.GetPetStats:InvokeServer()
	end)

	if statsSuccess then
		statsLabel.Text = stats.TotalPets .. "/" .. stats.InventorySlots .. " | " .. stats.EquippedPets .. "/" .. stats.EquipSlots .. " equipped"
	end

	-- Crear tarjetas
	for _, pet in ipairs(pets) do
		createPetCard(pet)
	end

	-- Actualizar CanvasSize
	contentContainer.CanvasSize = UDim2.new(0, 0, 0, contentLayout.AbsoluteContentSize.Y + 40)
end

-- ============================================
-- ABRIR/CERRAR INVENTARIO
-- ============================================

local function openInventory()
	if inventoryOpen then return end
	inventoryOpen = true
	backdrop.Visible = true
	updateInventory()
end

local function closeInventory()
	inventoryOpen = false
	backdrop.Visible = false
end

-- Toggle con tecla P
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.P then
		if inventoryOpen then
			closeInventory()
		else
			openInventory()
		end
	end
end)

-- Actualizar cuando cambien los datos
Remotes.OnDataUpdated.OnClientEvent:Connect(function(newData)
	if inventoryOpen then
		updateInventory()
	end
end)

print("[PetInventory] Inicializado - Presiona P para abrir")
