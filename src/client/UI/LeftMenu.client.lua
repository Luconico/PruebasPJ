--[[
	LeftMenu.client.lua
	Menú lateral izquierdo con botones de acceso rápido
	- PETS: Abre inventario de mascotas
	- ROULETTE: Abre la ruleta
	- VIP FART: Abre tienda de pedos premium
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Esperar módulos
local Shared = ReplicatedStorage:WaitForChild("Shared")
local UIComponentsManager = require(Shared:WaitForChild("UIComponentsManager"))
local ResponsiveUI = require(Shared:WaitForChild("ResponsiveUI"))

-- ============================================
-- CREAR BINDABLE EVENTS PARA COMUNICACIÓN
-- ============================================

local UIEvents = playerGui:FindFirstChild("UIEvents")
if not UIEvents then
	UIEvents = Instance.new("Folder")
	UIEvents.Name = "UIEvents"
	UIEvents.Parent = playerGui
end

-- Evento para abrir/cerrar inventario de pets
local TogglePetInventory = UIEvents:FindFirstChild("TogglePetInventory")
if not TogglePetInventory then
	TogglePetInventory = Instance.new("BindableEvent")
	TogglePetInventory.Name = "TogglePetInventory"
	TogglePetInventory.Parent = UIEvents
end

-- Evento para abrir/cerrar ruleta
local ToggleSpinWheel = UIEvents:FindFirstChild("ToggleSpinWheel")
if not ToggleSpinWheel then
	ToggleSpinWheel = Instance.new("BindableEvent")
	ToggleSpinWheel.Name = "ToggleSpinWheel"
	ToggleSpinWheel.Parent = UIEvents
end

-- Evento para abrir/cerrar VIP Fart
local ToggleVIPFart = UIEvents:FindFirstChild("ToggleVIPFart")
if not ToggleVIPFart then
	ToggleVIPFart = Instance.new("BindableEvent")
	ToggleVIPFart.Name = "ToggleVIPFart"
	ToggleVIPFart.Parent = UIEvents
end

-- ============================================
-- CONFIGURACIÓN DE BOTONES
-- ============================================

local MENU_BUTTONS = {
	{
		text = "PETS",
		event = TogglePetInventory,
	},
	{
		text = "ROULETTE",
		event = ToggleSpinWheel,
	},
	{
		text = "VIP FART",
		event = ToggleVIPFart,
	},
}

-- ============================================
-- CREAR UI DEL MENÚ
-- ============================================

local function createLeftMenu()
	local info = ResponsiveUI.getViewportInfo()
	local isMobile = info.IsMobile

	-- Tamaños responsive
	local buttonSize = isMobile and 65 or 80
	local buttonSpacing = isMobile and 8 or 12
	local menuPadding = isMobile and 10 or 20
	local textSize = isMobile and 11 or 14

	-- ScreenGui principal
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LeftMenuUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 5
	screenGui.Parent = playerGui

	-- Contenedor del menú (izquierda centrado verticalmente)
	local menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.Size = UDim2.new(0, buttonSize + menuPadding * 2, 0, (#MENU_BUTTONS * buttonSize) + ((#MENU_BUTTONS - 1) * buttonSpacing) + menuPadding * 2)
	menuContainer.Position = UDim2.new(0, menuPadding, 0.5, 0)
	menuContainer.AnchorPoint = Vector2.new(0, 0.5)
	menuContainer.BackgroundTransparency = 1
	menuContainer.Parent = screenGui

	-- Layout vertical para los botones
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, buttonSpacing)
	layout.Parent = menuContainer

	-- Crear cada botón
	for i, buttonConfig in ipairs(MENU_BUTTONS) do
		UIComponentsManager.createSideMenuButton(menuContainer, {
			size = UDim2.new(0, buttonSize, 0, buttonSize),
			layoutOrder = i,
			text = buttonConfig.text,
			textSize = textSize,
			hoverRotation = 10,
			hoverScale = 1.15,
			onClick = function()
				buttonConfig.event:Fire()
			end
		})
	end

	return screenGui
end

-- ============================================
-- INICIALIZACIÓN
-- ============================================

local menuUI = createLeftMenu()

-- Responsive: recrear UI cuando cambie el viewport
ResponsiveUI.onViewportChanged(function()
	if menuUI then
		menuUI:Destroy()
	end
	menuUI = createLeftMenu()
end)

print("[LeftMenu] Menú lateral inicializado")
