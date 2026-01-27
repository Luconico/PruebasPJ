--[[
	Config.lua
	Configuración compartida del juego Fart Tycoon
	Usado tanto por cliente como servidor
]]

local Config = {}

-- ============================================
-- GORDURA Y PROPULSION
-- ============================================
Config.Fatness = {
	-- Multiplicadores de tamaño
	ThinMultiplier = 0.5,      -- Tamaño mínimo (delgado)
	DefaultMaxFatness = 1.5,   -- Gordura máxima inicial (sin upgrades)

	-- Velocidades base (modificables por upgrades)
	BaseGrowSpeed = 0.08,      -- Velocidad de engorde base
	BaseShrinkSpeed = 0.04,    -- Velocidad de pérdida de grasa al propulsarse

	-- Propulsión
	BasePropulsionForce = 50,  -- Fuerza base de propulsión
}

-- ============================================
-- UPGRADES
-- ============================================
Config.Upgrades = {
	-- Gordura máxima
	MaxFatness = {
		Name = "Gordura Máxima",
		Description = "Aumenta tu capacidad de almacenar grasa",
		MaxLevel = 10,
		BaseValue = 1.5,
		IncrementPerLevel = 0.25, -- +0.25 por nivel (máximo 4.0 a nivel 10)
		CostCoins = { 100, 250, 500, 1000, 2000, 4000, 8000, 15000, 30000, 50000 },
		CostRobux = { 10, 20, 35, 50, 75, 100, 150, 200, 300, 500 },
	},

	-- Velocidad de engorde
	EatSpeed = {
		Name = "Velocidad de Engorde",
		Description = "Come más rápido",
		MaxLevel = 10,
		BaseValue = 0.08,
		IncrementPerLevel = 0.02, -- +0.02 por nivel
		CostCoins = { 75, 200, 400, 800, 1500, 3000, 6000, 12000, 25000, 40000 },
		CostRobux = { 10, 15, 25, 40, 60, 80, 120, 175, 250, 400 },
	},

	-- Fuerza de propulsión (EXPONENCIAL)
	PropulsionForce = {
		Name = "Potencia de Pedo",
		Description = "Pedos más potentes te impulsan más alto",
		MaxLevel = 10,
		BaseValue = 50,
		-- Progresión exponencial: 50 -> 275 (5.5x más potente a nivel 10)
		ValuesPerLevel = { 58, 68, 80, 95, 115, 140, 170, 210, 260, 320 },
		CostCoins = { 150, 350, 700, 1400, 2800, 5500, 11000, 22000, 45000, 75000 },
		CostRobux = { 15, 25, 40, 60, 90, 130, 180, 250, 350, 600 },
	},

	-- Eficiencia de combustible (EXPONENCIAL)
	FuelEfficiency = {
		Name = "Eficiencia de Gas",
		Description = "Pierdes menos grasa al propulsarte",
		MaxLevel = 10,
		BaseValue = 0.04,
		-- Progresión exponencial: 0.04 -> 0.004 (10x más eficiente a nivel 10)
		ValuesPerLevel = { 0.032, 0.025, 0.019, 0.014, 0.010, 0.0075, 0.0055, 0.0045, 0.0038, 0.0032 },
		CostCoins = { 200, 500, 1000, 2000, 4000, 8000, 16000, 32000, 60000, 100000 },
		CostRobux = { 20, 35, 55, 80, 120, 170, 230, 320, 450, 750 },
	},
}

-- ============================================
-- COMIDA
-- ============================================
Config.Food = {
	-- Comida básica (gratis) - muy lenta
	Salad = {
		Name = "Ensalada",
		FatnessPerSecond = 0.00125,
		RequiresUnlock = false,
		CostCoins = 0,
		CostRobux = 0,
	},

	-- Comida normal (monedas)
	Burger = {
		Name = "Hamburguesa",
		FatnessPerSecond = 0.00375,
		RequiresUnlock = true,
		CostCoins = 500,
		CostRobux = 25,
	},

	Pizza = {
		Name = "Pizza",
		FatnessPerSecond = 0.0075,
		RequiresUnlock = true,
		CostCoins = 1500,
		CostRobux = 50,
	},

	-- Comida premium (robux o muy caro)
	HotDog = {
		Name = "Hot Dog Especial",
		FatnessPerSecond = 0.0125,
		RequiresUnlock = true,
		CostCoins = 10000,
		CostRobux = 100,
	},

	GoldenBurger = {
		Name = "Hamburguesa Dorada",
		FatnessPerSecond = 0.02,
		RequiresUnlock = true,
		CostCoins = 0, -- Solo robux
		CostRobux = 250,
		RobuxOnly = true,
	},
}

-- ============================================
-- MONEDAS Y RECOMPENSAS
-- ============================================
Config.Rewards = {
	-- Monedas en el aire
	CoinValue = 10,           -- Valor base de cada moneda

	-- Bonus por hitos de altura (tramos pequeños para engagement temprano)
	HeightMilestones = {
		-- Tramos iniciales (frecuentes, pequeñas recompensas)
		{ Height = 5,    Bonus = 2,     Message = "5m", Tier = "common" },
		{ Height = 10,   Bonus = 5,     Message = "10m", Tier = "common" },
		{ Height = 15,   Bonus = 5,     Message = "15m", Tier = "common" },
		{ Height = 20,   Bonus = 8,     Message = "20m", Tier = "common" },
		{ Height = 25,   Bonus = 8,     Message = "25m", Tier = "common" },
		{ Height = 30,   Bonus = 10,    Message = "30m", Tier = "common" },
		{ Height = 40,   Bonus = 12,    Message = "40m", Tier = "common" },
		{ Height = 50,   Bonus = 15,    Message = "50m!", Tier = "uncommon" },
		{ Height = 60,   Bonus = 15,    Message = "60m", Tier = "common" },
		{ Height = 75,   Bonus = 20,    Message = "75m!", Tier = "uncommon" },
		{ Height = 100,  Bonus = 30,    Message = "100m!!", Tier = "rare" },
		{ Height = 125,  Bonus = 25,    Message = "125m", Tier = "uncommon" },
		{ Height = 150,  Bonus = 35,    Message = "150m!", Tier = "uncommon" },
		{ Height = 200,  Bonus = 50,    Message = "200m!!", Tier = "rare" },
		{ Height = 250,  Bonus = 40,    Message = "250m", Tier = "uncommon" },
		{ Height = 300,  Bonus = 60,    Message = "300m!!", Tier = "rare" },
		{ Height = 400,  Bonus = 80,    Message = "400m!!", Tier = "rare" },
		{ Height = 500,  Bonus = 100,   Message = "500m!!!", Tier = "epic" },
		{ Height = 750,  Bonus = 150,   Message = "750m!!!", Tier = "epic" },
		{ Height = 1000, Bonus = 250,   Message = "1 KILOMETRO!!!!", Tier = "legendary" },
		{ Height = 1500, Bonus = 400,   Message = "1.5 KM!!!!", Tier = "legendary" },
		{ Height = 2000, Bonus = 600,   Message = "2 KILOMETROS!!!!!", Tier = "mythic" },
		{ Height = 3000, Bonus = 1000,  Message = "3 KM!!!!!", Tier = "mythic" },
		{ Height = 5000, Bonus = 2000,  Message = "5 KILOMETROS!!!!!!", Tier = "mythic" },
	},

	-- Colores y efectos por tier de recompensa
	TierEffects = {
		common =    { Color = Color3.fromRGB(255, 255, 255), Scale = 1.0, Duration = 0.8 },
		uncommon =  { Color = Color3.fromRGB(100, 255, 100), Scale = 1.2, Duration = 1.0 },
		rare =      { Color = Color3.fromRGB(100, 150, 255), Scale = 1.4, Duration = 1.2 },
		epic =      { Color = Color3.fromRGB(200, 100, 255), Scale = 1.6, Duration = 1.5 },
		legendary = { Color = Color3.fromRGB(255, 200, 50),  Scale = 2.0, Duration = 2.0 },
		mythic =    { Color = Color3.fromRGB(255, 100, 100), Scale = 2.5, Duration = 2.5 },
	},

	-- Bonus por tiempo en el aire
	AirTimeBonus = 1, -- Monedas extra por segundo en el aire
}

-- ============================================
-- EFECTOS VISUALES
-- ============================================
Config.Effects = {
	-- Colores de pedo disponibles
	FartColors = {
		Default = {
			Name = "Gas Natural",
			Colors = {
				Color3.fromRGB(140, 160, 80),
				Color3.fromRGB(100, 120, 50),
				Color3.fromRGB(80, 100, 40),
			},
			CostCoins = 0,
			CostRobux = 0,
		},
		Toxic = {
			Name = "Tóxico",
			Colors = {
				Color3.fromRGB(0, 255, 0),
				Color3.fromRGB(0, 200, 50),
				Color3.fromRGB(0, 150, 0),
			},
			CostCoins = 5000,
			CostRobux = 75,
		},
		Fire = {
			Name = "Fuego",
			Colors = {
				Color3.fromRGB(255, 150, 0),
				Color3.fromRGB(255, 100, 0),
				Color3.fromRGB(200, 50, 0),
			},
			CostCoins = 10000,
			CostRobux = 150,
		},
		Rainbow = {
			Name = "Arcoíris",
			Colors = {
				Color3.fromRGB(255, 0, 0),
				Color3.fromRGB(0, 255, 0),
				Color3.fromRGB(0, 0, 255),
			},
			CostCoins = 0,
			CostRobux = 500,
			RobuxOnly = true,
		},
	},
}

-- ============================================
-- ZONAS DEL JUEGO
-- ============================================
Config.Zones = {
	-- Altura base del suelo de la zona de juego
	GameZoneBaseHeight = 0,

	-- Límites del lobby (para detectar cuándo el jugador entra a la zona de juego)
	LobbyBounds = {
		MinX = -50,
		MaxX = 50,
		MinZ = -50,
		MaxZ = 50,
	},
}

-- ============================================
-- DATOS INICIALES DEL JUGADOR
-- ============================================
Config.DefaultPlayerData = {
	Coins = 0,

	-- Niveles de upgrades (0 = no comprado, usa valor base)
	Upgrades = {
		MaxFatness = 0,
		EatSpeed = 0,
		PropulsionForce = 0,
		FuelEfficiency = 0,
	},

	-- Comidas desbloqueadas
	UnlockedFood = {
		Salad = true, -- Siempre desbloqueada
	},

	-- Efectos desbloqueados
	UnlockedEffects = {
		FartColor = "Default",
	},

	-- Récords personales
	Records = {
		MaxHeight = 0,
		TotalCoinsEarned = 0,
		TotalFlights = 0,
	},
}

return Config
