--[[
	RobuxManager.lua
	Módulo centralizado para gestionar todos los productos de Robux del juego
	Define los Developer Product IDs y proporciona funciones helper para compras
]]

local RobuxManager = {}

-- ============================================
-- CATEGORÍAS DE PRODUCTOS
-- ============================================

--[[
	NOTA IMPORTANTE: Los DevProductId deben ser creados en Roblox Creator Dashboard
	https://create.roblox.com/dashboard/creations

	Pasos para configurar:
	1. Ir a Creator Dashboard > tu juego > Monetization > Developer Products
	2. Crear cada producto con el precio correspondiente
	3. Copiar el Product ID y actualizarlo aquí
]]

-- ============================================
-- UPGRADES (10 Robux por nivel)
-- ============================================
RobuxManager.Upgrades = {
	MaxFatness = {
		Name = "Max Fatness Upgrade",
		Description = "+1 Level Max Fatness",
		RobuxCost = 10,
		DevProductId = 3532847985, -- TODO: Configurar en Roblox
	},
	EatSpeed = {
		Name = "Eat Speed Upgrade",
		Description = "+1 Level Eat Speed",
		RobuxCost = 10,
		DevProductId = 3532848287, -- TODO: Configurar en Roblox
	},
	PropulsionForce = {
		Name = "Fart Power Upgrade",
		Description = "+1 Level Fart Power",
		RobuxCost = 10,
		DevProductId = 3532848724, -- TODO: Configurar en Roblox
	},
	FuelEfficiency = {
		Name = "Gas Efficiency Upgrade",
		Description = "+1 Level Gas Efficiency",
		RobuxCost = 10,
		DevProductId = 3532849024, -- TODO: Configurar en Roblox
	},
}

-- ============================================
-- FOODS
-- ============================================
RobuxManager.Foods = {
	Burger = {
		Name = "Burger Unlock",
		Description = "Unlock Burger (x3 speed)",
		RobuxCost = 15,
		DevProductId = 3532849366, -- TODO: Configurar en Roblox
	},
	Pizza = {
		Name = "Pizza Unlock",
		Description = "Unlock Pizza (x6 speed)",
		RobuxCost = 35,
		DevProductId = 3532849802, -- TODO: Configurar en Roblox
	},
	HotDog = {
		Name = "Hot Dog Unlock",
		Description = "Unlock Hot Dog (x10 speed)",
		RobuxCost = 65,
		DevProductId = 3532850579, -- TODO: Configurar en Roblox
	},
	GoldenBurger = {
		Name = "Golden Burger Unlock",
		Description = "Unlock Golden Burger (x16 speed)",
		RobuxCost = 99,
		DevProductId = 3532850810, -- TODO: Configurar en Roblox
	},
}

-- ============================================
-- COSMETICS (Fart Effects)
-- ============================================
RobuxManager.Cosmetics = {
	Blue = {
		Name = "Blue Breeze",
		Description = "Blue fart cosmetic",
		RobuxCost = 9,
		DevProductId = 3532851760,
	},
	Pink = {
		Name = "Pink Cloud",
		Description = "Pink fart cosmetic",
		RobuxCost = 15,
		DevProductId = 3532851947,
	},
	Purple = {
		Name = "Mystic Vapor",
		Description = "Purple fart cosmetic",
		RobuxCost = 19,
		DevProductId = 3532852188,
	},
	Toxic = {
		Name = "Radioactive Toxic",
		Description = "Toxic green fart",
		RobuxCost = 49,
		DevProductId = 3532852321,
	},
	Fire = {
		Name = "Fire Fart",
		Description = "Fiery fart cosmetic",
		RobuxCost = 99,
		DevProductId = 3532852441,
	},
	Ice = {
		Name = "Frozen Blizzard",
		Description = "Ice fart cosmetic",
		RobuxCost = 99,
		DevProductId = 3532852632,
	},
	Shadow = {
		Name = "Dark Shadow",
		Description = "Shadow fart cosmetic",
		RobuxCost = 99,
		DevProductId = 3532852781,
	},
	Lava = {
		Name = "Volcanic Magma",
		Description = "Lava fart cosmetic",
		RobuxCost = 149,
		DevProductId = 3532852899,
	},
	Electric = {
		Name = "Electric Storm",
		Description = "Electric fart cosmetic",
		RobuxCost = 149,
		DevProductId = 3532853064,
	},
	Galaxy = {
		Name = "Galactic Nebula",
		Description = "Galaxy fart cosmetic",
		RobuxCost = 199,
		DevProductId = 3532853172,
	},
	Neon = {
		Name = "Cyberpunk Neon",
		Description = "Neon fart cosmetic",
		RobuxCost = 199,
		DevProductId = 3532853323,
	},
	Rainbow = {
		Name = "Magic Rainbow",
		Description = "Rainbow fart cosmetic",
		RobuxCost = 249,
		DevProductId = 3532853505,
	},
	Golden = {
		Name = "Golden Fart",
		Description = "Golden fart cosmetic",
		RobuxCost = 299,
		DevProductId = 3532853639,
	},
	Diamond = {
		Name = "Brilliant Diamond",
		Description = "Diamond fart cosmetic",
		RobuxCost = 499,
		DevProductId = 3532853790,
	},
	Void = {
		Name = "Dimensional Void",
		Description = "Void fart cosmetic",
		RobuxCost = 799,
		DevProductId = 3532853958,
	},
	Chromatic = {
		Name = "Infinite Chromatic",
		Description = "Chromatic fart cosmetic",
		RobuxCost = 999,
		DevProductId = 3532854097,
	},
	Legendary_Phoenix = {
		Name = "Reborn Phoenix",
		Description = "Phoenix fart cosmetic",
		RobuxCost = 1499,
		DevProductId = 3532854250,
	},
}

-- ============================================
-- PETS
-- ============================================
RobuxManager.Pets = {
	RobuxEgg = {
		Name = "Golden Egg",
		Description = "Premium egg with exclusive pets",
		RobuxCost = 99,
		DevProductId = 3532854402, -- TODO: Configurar en Roblox
	},
	InventorySlots = {
		Name = "+10 Inventory Slots",
		Description = "Increase pet inventory capacity",
		RobuxCost = 49,
		SlotsPerPurchase = 10,
		DevProductId = 3532854616, -- TODO: Configurar en Roblox
	},
	EquipSlots = {
		Name = "+1 Pet Following Slot",
		Description = "Equip one more pet",
		RobuxCost = 99,
		SlotsPerPurchase = 1,
		DevProductId = 3532854871, -- TODO: Configurar en Roblox
	},
}

-- ============================================
-- ZONES (Zonas normales usan Trofeos, zonas VIP solo Robux)
-- ============================================
RobuxManager.Zones = {
	Zona1 = {
		Name = "Zone 1",
		Description = "Unlock Zone 1",
		RobuxCost = 19,
		TrophyCost = 250,
		DevProductId = 3532855197, -- TODO: Configurar en Roblox
	},
	Zona2 = {
		Name = "Zone 2",
		Description = "Unlock Zone 2",
		RobuxCost = 99,
		TrophyCost = 750,
		DevProductId = 3532855338,
	},
	Zona3 = {
		Name = "Zone 3",
		Description = "Unlock Zone 3",
		RobuxCost = 149,
		TrophyCost = 2500,
		DevProductId = 3532855438,
	},
	Zona4 = {
		Name = "Zone 4",
		Description = "Unlock Zone 4",
		RobuxCost = 399,
		TrophyCost = 5000,
		DevProductId = 3532855549,
	},
	Zona5 = {
		Name = "Zone 5",
		Description = "Unlock Zone 5",
		RobuxCost = 399,
		TrophyCost = 250,
		DevProductId = 3532855549,
	},
	VIP1 = {
		Name = "VIP Zone 1",
		Description = "Exclusive VIP Zone 1",
		RobuxCost = 49,
		VIPOnly = true,
		DevProductId = 3532855709,
	},
	VIP2 = {
		Name = "VIP Zone 2",
		Description = "Exclusive VIP Zone 2",
		RobuxCost = 99,
		VIPOnly = true,
		DevProductId = 3532855813,
	},
	VIP3 = {
		Name = "VIP Zone 3",
		Description = "Exclusive VIP Zone 3",
		RobuxCost = 149,
		VIPOnly = true,
		DevProductId = 3532855960,
	},
	VIP4 = {
		Name = "VIP Zone 4",
		Description = "Exclusive VIP Zone 4",
		RobuxCost = 199,
		VIPOnly = true,
		DevProductId = 3532856075,
	},
}

-- ============================================
-- BASES (usan Trofeos)
-- ============================================
RobuxManager.Bases = {
	Base1 = {
		Name = "Secret Base",
		Description = "Unlock Secret Base",
		RobuxCost = 500,
		TrophyCost = 500,
		DevProductId = 0, -- TODO: Configurar en Roblox
	},
}

-- ============================================
-- SPINS (Giros de la Ruleta)
-- ============================================
RobuxManager.Spins = {
	Spin1 = {
		Name = "+1 Spin",
		Description = "Get 1 extra spin",
		Amount = 1,
		RobuxCost = 25,
		Sale = false,
		DevProductId = 3532856603, -- TODO: Configurar en Roblox
	},
	Spin10 = {
		Name = "+10 Spins",
		Description = "Get 10 extra spins",
		Amount = 10,
		RobuxCost = 200,
		Sale = false,
		DevProductId = 3532856787, -- TODO: Configurar en Roblox
	},
	Spin100 = {
		Name = "+100 Spins",
		Description = "Get 100 extra spins (Best Value!)",
		Amount = 100,
		RobuxCost = 1500,
		Sale = true,
		DevProductId = 3532857012, -- TODO: Configurar en Roblox
	},
}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Obtener producto por categoría y ID
function RobuxManager.getProduct(category, productId)
	local categoryTable = RobuxManager[category]
	if not categoryTable then
		warn("[RobuxManager] Categoría no encontrada:", category)
		return nil
	end

	local product = categoryTable[productId]
	if not product then
		warn("[RobuxManager] Producto no encontrado:", productId, "en categoría", category)
		return nil
	end

	return product
end

-- Obtener todos los productos sin DevProductId configurado
function RobuxManager.getUnconfiguredProducts()
	local unconfigured = {}

	for categoryName, category in pairs(RobuxManager) do
		if type(category) == "table" and categoryName ~= "getProduct" and categoryName ~= "getUnconfiguredProducts" and categoryName ~= "getAllProducts" then
			for productId, product in pairs(category) do
				if type(product) == "table" and product.DevProductId == 0 then
					table.insert(unconfigured, {
						Category = categoryName,
						ProductId = productId,
						Name = product.Name,
						RobuxCost = product.RobuxCost,
					})
				end
			end
		end
	end

	return unconfigured
end

-- Obtener todos los productos (para debug)
function RobuxManager.getAllProducts()
	local allProducts = {}

	for categoryName, category in pairs(RobuxManager) do
		if type(category) == "table" and categoryName ~= "getProduct" and categoryName ~= "getUnconfiguredProducts" and categoryName ~= "getAllProducts" then
			allProducts[categoryName] = {}
			for productId, product in pairs(category) do
				if type(product) == "table" then
					allProducts[categoryName][productId] = product
				end
			end
		end
	end

	return allProducts
end

-- Validar que un DevProductId existe
function RobuxManager.isValidDevProductId(devProductId)
	if not devProductId or devProductId == 0 then
		return false
	end
	return true
end

-- ============================================
-- INTEGRACIÓN CON MARKETPLACESERVICE
-- ============================================

--[[
	EJEMPLO DE USO EN SERVIDOR:

	local RobuxManager = require(ReplicatedStorage.Shared.RobuxManager)
	local MarketplaceService = game:GetService("MarketplaceService")

	-- 1. Obtener el producto
	local product = RobuxManager.getProduct("Foods", "Burger")
	if not product then
		return false, "Producto no encontrado"
	end

	-- 2. Validar DevProductId
	if not RobuxManager.isValidDevProductId(product.DevProductId) then
		warn("[RobuxManager] DevProductId no configurado para:", product.Name)
		return false, "Producto no configurado"
	end

	-- 3. Procesar compra
	local success, result = pcall(function()
		return MarketplaceService:PromptProductPurchase(player, product.DevProductId)
	end)

	-- 4. Manejar callback de ProcessReceipt
	-- Ver ejemplo completo abajo
]]

--[[
	SETUP DE MARKETPLACESERVICE (Copiar esto al servidor principal):

	local MarketplaceService = game:GetService("MarketplaceService")
	local RobuxManager = require(ReplicatedStorage.Shared.RobuxManager)

	-- Función para procesar recibos de compras
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			-- Jugador no está en el juego, guardar para procesar después
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Buscar qué producto fue comprado
		local productCategory, productId = RobuxManager.findProductByDevId(receiptInfo.ProductId)

		if not productCategory then
			warn("[MarketplaceService] Producto desconocido:", receiptInfo.ProductId)
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		-- Procesar según categoría
		local success = false

		if productCategory == "Foods" then
			success = unlockFood(player, productId)
		elseif productCategory == "Cosmetics" then
			success = unlockCosmetic(player, productId)
		elseif productCategory == "Pets" then
			if productId == "RobuxEgg" then
				success = openEgg(player, "RobuxEgg")
			elseif productId == "InventorySlots" then
				success = addInventorySlots(player)
			elseif productId == "EquipSlots" then
				success = addEquipSlots(player)
			end
		elseif productCategory == "Zones" then
			success = unlockZone(player, productId)
		elseif productCategory == "Bases" then
			success = unlockBase(player, "Base1")
		elseif productCategory == "Upgrades" then
			success = purchaseUpgradeWithRobux(player, productId)
		end

		if success then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		else
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end
]]

-- Buscar producto por DevProductId (útil para ProcessReceipt)
function RobuxManager.findProductByDevId(devProductId)
	for categoryName, category in pairs(RobuxManager) do
		if type(category) == "table" and categoryName ~= "getProduct" and categoryName ~= "getUnconfiguredProducts" and categoryName ~= "getAllProducts" and categoryName ~= "isValidDevProductId" and categoryName ~= "findProductByDevId" then
			for productId, product in pairs(category) do
				if type(product) == "table" and product.DevProductId == devProductId then
					return categoryName, productId, product
				end
			end
		end
	end
	return nil, nil, nil
end

return RobuxManager

