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
-- COSMÉTICOS DE PEDO
-- ============================================
Config.FartCosmetics = {
	-- ==========================================
	-- TIER: COMÚN (Baratos, colores simples)
	-- ==========================================
	Default = {
		Name = "Gas Natural",
		Description = "El clásico pedo verde",
		Tier = "common",
		Icon = "💨",
		CostRobux = 0, -- Gratis, viene por defecto
		Colors = {
			Color3.fromRGB(140, 160, 80),
			Color3.fromRGB(100, 120, 50),
			Color3.fromRGB(80, 100, 40),
		},
		ParticleSize = {Min = 0.5, Max = 2},
		Animated = false,
	},

	Blue = {
		Name = "Brisa Azul",
		Description = "Un pedo fresco y refrescante",
		Tier = "common",
		Icon = "🌀",
		CostRobux = 25,
		Colors = {
			Color3.fromRGB(100, 150, 255),
			Color3.fromRGB(50, 100, 200),
			Color3.fromRGB(30, 80, 180),
		},
		ParticleSize = {Min = 0.5, Max = 2},
		Animated = false,
	},

	Pink = {
		Name = "Nube Rosa",
		Description = "Adorable y apestoso",
		Tier = "common",
		Icon = "🌸",
		CostRobux = 25,
		Colors = {
			Color3.fromRGB(255, 150, 200),
			Color3.fromRGB(255, 100, 180),
			Color3.fromRGB(220, 80, 150),
		},
		ParticleSize = {Min = 0.5, Max = 2},
		Animated = false,
	},

	Purple = {
		Name = "Vapor Místico",
		Description = "Misterioso y maloliente",
		Tier = "common",
		Icon = "🔮",
		CostRobux = 35,
		Colors = {
			Color3.fromRGB(180, 100, 255),
			Color3.fromRGB(150, 50, 220),
			Color3.fromRGB(120, 30, 180),
		},
		ParticleSize = {Min = 0.5, Max = 2},
		Animated = false,
	},

	-- ==========================================
	-- TIER: RARO (Efectos más llamativos)
	-- ==========================================
	Toxic = {
		Name = "Tóxico Radioactivo",
		Description = "¡Cuidado! Nivel de radiación: EXTREMO",
		Tier = "rare",
		Icon = "☢️",
		CostRobux = 75,
		Colors = {
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(100, 255, 50),
			Color3.fromRGB(0, 200, 0),
		},
		ParticleSize = {Min = 0.6, Max = 2.5},
		Animated = false,
		Glow = true,
	},

	Fire = {
		Name = "Pedo de Fuego",
		Description = "Picante en la entrada, explosivo en la salida",
		Tier = "rare",
		Icon = "🔥",
		CostRobux = 99,
		Colors = {
			Color3.fromRGB(255, 200, 0),
			Color3.fromRGB(255, 100, 0),
			Color3.fromRGB(200, 50, 0),
		},
		ParticleSize = {Min = 0.6, Max = 2.5},
		Animated = false,
		Glow = true,
	},

	Ice = {
		Name = "Ventisca Helada",
		Description = "Tan frío que congela el aire",
		Tier = "rare",
		Icon = "❄️",
		CostRobux = 99,
		Colors = {
			Color3.fromRGB(200, 240, 255),
			Color3.fromRGB(150, 220, 255),
			Color3.fromRGB(100, 200, 255),
		},
		ParticleSize = {Min = 0.6, Max = 2.5},
		Animated = false,
		Glow = true,
		Sparkles = true,
	},

	Shadow = {
		Name = "Sombra Oscura",
		Description = "De las profundidades del abismo",
		Tier = "rare",
		Icon = "🖤",
		CostRobux = 99,
		Colors = {
			Color3.fromRGB(50, 30, 60),
			Color3.fromRGB(30, 20, 40),
			Color3.fromRGB(20, 10, 30),
		},
		ParticleSize = {Min = 0.7, Max = 3},
		Animated = false,
		InvertedGlow = true,
	},

	-- ==========================================
	-- TIER: ÉPICO (Animados y especiales)
	-- ==========================================
	Lava = {
		Name = "Magma Volcánico",
		Description = "Directamente del centro de la Tierra",
		Tier = "epic",
		Icon = "🌋",
		CostRobux = 199,
		Colors = {
			Color3.fromRGB(255, 100, 0),
			Color3.fromRGB(255, 50, 0),
			Color3.fromRGB(200, 0, 0),
		},
		ParticleSize = {Min = 0.8, Max = 3},
		Animated = true,
		AnimationType = "pulse",
		Glow = true,
		Trail = true,
	},

	Electric = {
		Name = "Tormenta Eléctrica",
		Description = "10,000 voltios de pura potencia",
		Tier = "epic",
		Icon = "⚡",
		CostRobux = 199,
		Colors = {
			Color3.fromRGB(255, 255, 100),
			Color3.fromRGB(200, 200, 255),
			Color3.fromRGB(100, 100, 255),
		},
		ParticleSize = {Min = 0.5, Max = 2.5},
		Animated = true,
		AnimationType = "flash",
		Glow = true,
		Sparkles = true,
	},

	Galaxy = {
		Name = "Nebulosa Galáctica",
		Description = "Un pedo de proporciones cósmicas",
		Tier = "epic",
		Icon = "🌌",
		CostRobux = 249,
		Colors = {
			Color3.fromRGB(100, 50, 200),
			Color3.fromRGB(200, 100, 255),
			Color3.fromRGB(50, 100, 200),
		},
		ParticleSize = {Min = 0.8, Max = 3.5},
		Animated = true,
		AnimationType = "swirl",
		Glow = true,
		Sparkles = true,
		Stars = true,
	},

	Neon = {
		Name = "Neón Cyberpunk",
		Description = "Bienvenido al futuro del gas",
		Tier = "epic",
		Icon = "💜",
		CostRobux = 249,
		Colors = {
			Color3.fromRGB(255, 0, 255),
			Color3.fromRGB(0, 255, 255),
			Color3.fromRGB(255, 0, 100),
		},
		ParticleSize = {Min = 0.6, Max = 2.5},
		Animated = true,
		AnimationType = "colorCycle",
		Glow = true,
	},

	-- ==========================================
	-- TIER: LEGENDARIO (Los más premium)
	-- ==========================================
	Rainbow = {
		Name = "Arcoíris Mágico",
		Description = "Todos los colores, todo el olor",
		Tier = "legendary",
		Icon = "🌈",
		CostRobux = 499,
		Colors = {
			Color3.fromRGB(255, 0, 0),
			Color3.fromRGB(255, 127, 0),
			Color3.fromRGB(255, 255, 0),
			Color3.fromRGB(0, 255, 0),
			Color3.fromRGB(0, 0, 255),
			Color3.fromRGB(139, 0, 255),
		},
		ParticleSize = {Min = 0.8, Max = 3},
		Animated = true,
		AnimationType = "rainbow",
		Glow = true,
		Trail = true,
	},

	Golden = {
		Name = "Pedo de Oro",
		Description = "El gas más valioso del mundo",
		Tier = "legendary",
		Icon = "👑",
		CostRobux = 599,
		Colors = {
			Color3.fromRGB(255, 215, 0),
			Color3.fromRGB(255, 200, 50),
			Color3.fromRGB(200, 150, 0),
		},
		ParticleSize = {Min = 1, Max = 3.5},
		Animated = true,
		AnimationType = "shimmer",
		Glow = true,
		Sparkles = true,
		Trail = true,
	},

	Diamond = {
		Name = "Diamante Brillante",
		Description = "Puro lujo cristalizado",
		Tier = "legendary",
		Icon = "💎",
		CostRobux = 699,
		Colors = {
			Color3.fromRGB(185, 242, 255),
			Color3.fromRGB(200, 255, 255),
			Color3.fromRGB(150, 200, 255),
		},
		ParticleSize = {Min = 0.8, Max = 3},
		Animated = true,
		AnimationType = "sparkle",
		Glow = true,
		Sparkles = true,
		Reflective = true,
	},

	-- ==========================================
	-- TIER: MÍTICO (Ultra exclusivos)
	-- ==========================================
	Void = {
		Name = "Vacío Dimensional",
		Description = "Abre portales a otras dimensiones",
		Tier = "mythic",
		Icon = "🕳️",
		CostRobux = 999,
		Colors = {
			Color3.fromRGB(20, 0, 40),
			Color3.fromRGB(50, 0, 100),
			Color3.fromRGB(100, 0, 150),
		},
		ParticleSize = {Min = 1, Max = 4},
		Animated = true,
		AnimationType = "vortex",
		Glow = true,
		InvertedGlow = true,
		DistortionEffect = true,
	},

	Chromatic = {
		Name = "Cromático Infinito",
		Description = "Cambia constantemente, nunca se repite",
		Tier = "mythic",
		Icon = "✨",
		CostRobux = 1299,
		Colors = {}, -- Generado dinámicamente
		ParticleSize = {Min = 1, Max = 4},
		Animated = true,
		AnimationType = "chromatic",
		Glow = true,
		Sparkles = true,
		Trail = true,
		AllEffects = true, -- Combina todos los efectos
	},

	Legendary_Phoenix = {
		Name = "Fénix Renacido",
		Description = "De las cenizas surge el olor más poderoso",
		Tier = "mythic",
		Icon = "🦅",
		CostRobux = 1499,
		Colors = {
			Color3.fromRGB(255, 100, 0),
			Color3.fromRGB(255, 200, 50),
			Color3.fromRGB(255, 50, 50),
		},
		ParticleSize = {Min = 1.2, Max = 5},
		Animated = true,
		AnimationType = "phoenix",
		Glow = true,
		Trail = true,
		FireParticles = true,
		WingEffect = true,
	},
}

-- Colores de tier para UI
Config.CosmeticTiers = {
	common = {
		Name = "Común",
		Color = Color3.fromRGB(180, 180, 180),
		GlowColor = Color3.fromRGB(150, 150, 150),
	},
	rare = {
		Name = "Raro",
		Color = Color3.fromRGB(100, 180, 255),
		GlowColor = Color3.fromRGB(50, 150, 255),
	},
	epic = {
		Name = "Épico",
		Color = Color3.fromRGB(200, 100, 255),
		GlowColor = Color3.fromRGB(180, 50, 255),
	},
	legendary = {
		Name = "Legendario",
		Color = Color3.fromRGB(255, 200, 50),
		GlowColor = Color3.fromRGB(255, 180, 0),
	},
	mythic = {
		Name = "Mítico",
		Color = Color3.fromRGB(255, 100, 100),
		GlowColor = Color3.fromRGB(255, 50, 50),
	},
}

-- Orden de visualización (de más barato a más caro)
Config.CosmeticOrder = {
	"Default", "Blue", "Pink", "Purple",           -- Común
	"Toxic", "Fire", "Ice", "Shadow",              -- Raro
	"Lava", "Electric", "Galaxy", "Neon",          -- Épico
	"Rainbow", "Golden", "Diamond",                 -- Legendario
	"Void", "Chromatic", "Legendary_Phoenix",      -- Mítico
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

	-- Cosméticos de pedo
	OwnedCosmetics = {
		Default = true, -- El pedo básico siempre está desbloqueado
	},
	EquippedCosmetic = "Default", -- Cosmético actualmente equipado

	-- Récords personales
	Records = {
		MaxHeight = 0,
		TotalCoinsEarned = 0,
		TotalFlights = 0,
	},
}

return Config
