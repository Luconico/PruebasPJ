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
	DefaultMaxFatness = 3.0,   -- Gordura máxima inicial

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
		BaseValue = 3.0,
		IncrementPerLevel = 0.5, -- +0.5 por nivel
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

	-- Fuerza de propulsión
	PropulsionForce = {
		Name = "Potencia de Pedo",
		Description = "Pedos más potentes te impulsan más alto",
		MaxLevel = 10,
		BaseValue = 50,
		IncrementPerLevel = 10, -- +10 por nivel
		CostCoins = { 150, 350, 700, 1400, 2800, 5500, 11000, 22000, 45000, 75000 },
		CostRobux = { 15, 25, 40, 60, 90, 130, 180, 250, 350, 600 },
	},

	-- Eficiencia de combustible
	FuelEfficiency = {
		Name = "Eficiencia de Gas",
		Description = "Pierdes menos grasa al propulsarte",
		MaxLevel = 10,
		BaseValue = 0.04,
		IncrementPerLevel = -0.003, -- Reduce la pérdida
		CostCoins = { 200, 500, 1000, 2000, 4000, 8000, 16000, 32000, 60000, 100000 },
		CostRobux = { 20, 35, 55, 80, 120, 170, 230, 320, 450, 750 },
	},
}

-- ============================================
-- COMIDA
-- ============================================
Config.Food = {
	-- Comida básica (gratis)
	Salad = {
		Name = "Ensalada",
		FatnessPerSecond = 0.02,
		RequiresUnlock = false,
		CostCoins = 0,
		CostRobux = 0,
	},

	-- Comida normal (monedas)
	Burger = {
		Name = "Hamburguesa",
		FatnessPerSecond = 0.05,
		RequiresUnlock = true,
		CostCoins = 500,
		CostRobux = 25,
	},

	Pizza = {
		Name = "Pizza",
		FatnessPerSecond = 0.08,
		RequiresUnlock = true,
		CostCoins = 1500,
		CostRobux = 50,
	},

	-- Comida premium (robux o muy caro)
	HotDog = {
		Name = "Hot Dog Especial",
		FatnessPerSecond = 0.12,
		RequiresUnlock = true,
		CostCoins = 10000,
		CostRobux = 100,
	},

	GoldenBurger = {
		Name = "Hamburguesa Dorada",
		FatnessPerSecond = 0.20,
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

	-- Bonus por hitos de altura
	HeightMilestones = {
		{ Height = 50,   Bonus = 25,   Message = "50 METROS!" },
		{ Height = 100,  Bonus = 50,   Message = "100 METROS!" },
		{ Height = 200,  Bonus = 100,  Message = "200 METROS!" },
		{ Height = 500,  Bonus = 300,  Message = "500 METROS!" },
		{ Height = 1000, Bonus = 750,  Message = "1000 METROS!" },
		{ Height = 2000, Bonus = 2000, Message = "2 KILOMETROS!" },
		{ Height = 5000, Bonus = 5000, Message = "5 KILOMETROS!" },
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
