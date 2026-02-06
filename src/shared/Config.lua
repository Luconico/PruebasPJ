--[[
	Config.lua
	Shared configuration for Fart Tycoon game
	Used by both client and server
]]

local Config = {}

-- ============================================
-- FATNESS AND PROPULSION
-- ============================================
Config.Fatness = {
	-- Size multipliers
	ThinMultiplier = 0.5,      -- Minimum size (thin)
	DefaultMaxFatness = 1.5,   -- Initial max fatness (without upgrades)

	-- Base speeds (modifiable by upgrades)
	BaseGrowSpeed = 0.08,      -- Base fattening speed
	BaseShrinkSpeed = 0.04,    -- Fat loss speed when propelling

	-- Propulsion
	BasePropulsionForce = 50,  -- Base propulsion force
}

-- ============================================
-- UPGRADES (100 LEVELS - Robux: 10 R$ per level, independent of coin scaling)
-- ============================================

-- Helper function to generate exponential coin costs
local function generateCoinCosts(startCost, endCost, levels)
	local costs = {}
	local ratio = (endCost / startCost) ^ (1 / (levels - 1))
	for i = 1, levels do
		costs[i] = math.floor(startCost * (ratio ^ (i - 1)))
	end
	return costs
end

-- Helper function to interpolate exponential values
local function interpolateValues(baseValue, targetValues, levels)
	-- targetValues has 10 values, we need to interpolate to 100
	local values = {}
	for i = 1, levels do
		-- Map level 1-100 to index 0.1-10 in original array
		local originalIndex = (i / 10)
		local lowerIndex = math.floor(originalIndex)
		local upperIndex = math.ceil(originalIndex)

		if lowerIndex < 1 then
			-- Interpolate between baseValue and first target
			local t = originalIndex
			values[i] = baseValue + (targetValues[1] - baseValue) * t
		elseif upperIndex > #targetValues or lowerIndex == upperIndex then
			values[i] = targetValues[math.min(lowerIndex, #targetValues)]
		else
			-- Linear interpolation between two target values
			local t = originalIndex - lowerIndex
			values[i] = targetValues[lowerIndex] + (targetValues[upperIndex] - targetValues[lowerIndex]) * t
		end
	end
	return values
end

Config.Upgrades = {
	-- Maximum fatness (LINEAR - 100 levels)
	MaxFatness = {
		Name = "Max Fatness",
		Description = "Increase your fat storage capacity",
		MaxLevel = 100,
		BaseValue = 1.5,
		IncrementPerLevel = 0.025, -- +0.025 per level (0.25/10) → max 4.0 at level 100
		-- Coin costs: 100 levels, exponential growth from 10 to 50000
		CostCoins = generateCoinCosts(10, 50000, 100),
		-- Robux: fixed 10 R$ per level (independent of coin scaling)
		CostRobux = 10,
	},

	-- Eating speed (LINEAR - 100 levels)
	EatSpeed = {
		Name = "Eating Speed",
		Description = "Eat faster",
		MaxLevel = 100,
		BaseValue = 0.08,
		IncrementPerLevel = 0.002, -- +0.002 per level (0.02/10)
		CostCoins = generateCoinCosts(8, 40000, 100),
		CostRobux = 10,
	},

	-- Propulsion force (EXPONENTIAL - 100 levels)
	PropulsionForce = {
		Name = "Fart Power",
		Description = "More powerful farts push you higher",
		MaxLevel = 100,
		BaseValue = 50,
		-- Interpolated from original 10 values to 100 values
		ValuesPerLevel = interpolateValues(50, { 58, 68, 80, 95, 115, 140, 170, 210, 260, 320 }, 100),
		CostCoins = generateCoinCosts(15, 75000, 100),
		CostRobux = 10,
	},

	-- Fuel efficiency (EXPONENTIAL - 100 levels)
	FuelEfficiency = {
		Name = "Gas Efficiency",
		Description = "Lose less fat when propelling",
		MaxLevel = 100,
		BaseValue = 0.04,
		-- Interpolated from original 10 values to 100 values
		ValuesPerLevel = interpolateValues(0.04, { 0.032, 0.025, 0.019, 0.014, 0.010, 0.0075, 0.0055, 0.0045, 0.0038, 0.0032 }, 100),
		CostCoins = generateCoinCosts(20, 100000, 100),
		CostRobux = 10,
	},
}

-- ============================================
-- FOOD
-- ============================================
Config.Food = {
	-- Basic food (free) - x1 speed
	Salad = {
		Name = "Salad",
		FatnessPerSecond = 0.00125,
		SpeedMultiplier = 1,
		RequiresUnlock = false,
		CostRobux = 0,
		Color = Color3.fromRGB(120, 200, 80), -- Verde
		Icon = "🥗",
	},

	-- x3 speed
	Burger = {
		Name = "Burger",
		FatnessPerSecond = 0.00375,
		SpeedMultiplier = 3,
		RequiresUnlock = true,
		CostRobux = 15,
		Color = Color3.fromRGB(210, 140, 60), -- Naranja/marrón
		Icon = "🍔",
	},

	-- x6 speed
	Pizza = {
		Name = "Pizza",
		FatnessPerSecond = 0.0075,
		SpeedMultiplier = 6,
		RequiresUnlock = true,
		CostRobux = 35,
		Color = Color3.fromRGB(230, 180, 80), -- Amarillo/queso
		Icon = "🍕",
	},

	-- x10 speed
	HotDog = {
		Name = "Hot Dog",
		FatnessPerSecond = 0.0125,
		SpeedMultiplier = 10,
		RequiresUnlock = true,
		CostRobux = 65,
		Color = Color3.fromRGB(200, 100, 80), -- Rojo/salchicha
		Icon = "🌭",
	},

	-- x16 speed (premium)
	GoldenBurger = {
		Name = "Golden Burger",
		FatnessPerSecond = 0.02,
		SpeedMultiplier = 16,
		RequiresUnlock = true,
		CostRobux = 99,
		Color = Color3.fromRGB(130, 80, 180), -- Morado royal (corona dorada visible)
		Icon = "👑",
	},
}

-- ============================================
-- FOOD PARCELS (Minijuego de recoleccion)
-- ============================================
Config.FoodParcels = {
	-- Configuracion global
	GlobalSettings = {
		RespawnTime = 5,           -- Segundos para que reaparezca un item
		CollectionRadius = 4,      -- Distancia para recoger (studs)
		ItemFloatHeight = 2,       -- Altura sobre el suelo
		ItemBobSpeed = 2,          -- Velocidad de animacion de flotacion
		ItemBobAmount = 0.5,       -- Amplitud de flotacion
		SpawnInterval = 3,         -- Segundos entre spawns de nuevos items
	},

	-- Tipos de parcelas
	ParcelTypes = {
		Lettuce = {
			Name = "Lettuce Patch",
			Icon = "🥬",
			GasBonus = 0.017,      -- +1.7% del max fatness
			CoinsBonus = 1,        -- +1 moneda
			MaxItems = 40,          -- Maximo items simultaneos
			RespawnTime = 0.5,       -- Segundos para respawn
			Color = Color3.fromRGB(120, 200, 80),   -- Verde lechuga
			Rarity = "common",
		},

		Burger = {
			Name = "Burger Field",
			Icon = "🍔",
			GasBonus = 0.033,      -- +3.3% del max fatness
			CoinsBonus = 2,        -- +2 monedas
			MaxItems = 30,
			RespawnTime = 1,       -- Segundos para respawn
			Color = Color3.fromRGB(210, 140, 60),   -- Naranja burger
			Rarity = "uncommon",
		},

		Pizza = {
			Name = "Pizza Paradise",
			Icon = "🍕",
			GasBonus = 0.05,       -- +5% del max fatness
			CoinsBonus = 3,        -- +3 monedas
			MaxItems = 30,
			RespawnTime = 1,       -- Segundos para respawn
			Color = Color3.fromRGB(230, 180, 80),   -- Amarillo queso
			Rarity = "rare",
		},

		HotDog = {
			Name = "Hot Dog Haven",
			Icon = "🌭",
			GasBonus = 0.067,      -- +6.7% del max fatness
			CoinsBonus = 4,        -- +4 monedas
			MaxItems = 30,
			RespawnTime = 1,       -- Segundos para respawn
			Color = Color3.fromRGB(200, 100, 80),   -- Rojo salchicha
			Rarity = "epic",
		},

		GoldenBurger = {
			Name = "Golden Feast",
			Icon = "👑",
			GasBonus = 0.12,       -- +12% del max fatness
			CoinsBonus = 8,        -- +8 monedas
			MaxItems = 30,
			RespawnTime = 1,      -- Segundos para respawn (más lento por ser legendario)
			Color = Color3.fromRGB(255, 215, 0),    -- Dorado
			Rarity = "legendary",
		},

		-- Variantes Slow (menos items, respawn más lento)
		BurgerSlow = {
			Name = "Burger Field (Slow)",
			Icon = "🍔",
			GasBonus = 0.033,
			CoinsBonus = 2,
			MaxItems = 3,
			RespawnTime = 5,
			Color = Color3.fromRGB(210, 140, 60),   -- Naranja burger
			Rarity = "uncommon",
		},

		PizzaSlow = {
			Name = "Pizza Paradise (Slow)",
			Icon = "🍕",
			GasBonus = 0.05,
			CoinsBonus = 3,
			MaxItems = 2,
			RespawnTime = 10,
			Color = Color3.fromRGB(230, 180, 80),   -- Amarillo queso
			Rarity = "rare",
		},

		HotDogSlow = {
			Name = "Hot Dog Haven (Slow)",
			Icon = "🌭",
			GasBonus = 0.067,
			CoinsBonus = 4,
			MaxItems = 1,
			RespawnTime = 15,
			Color = Color3.fromRGB(200, 100, 80),   -- Rojo salchicha
			Rarity = "epic",
		},
	},

	-- Efectos visuales por rareza
	RarityEffects = {
		common = {
			ParticleColor = Color3.fromRGB(255, 255, 255),
			GlowIntensity = 0,
		},
		uncommon = {
			ParticleColor = Color3.fromRGB(100, 255, 100),
			GlowIntensity = 0.3,
		},
		rare = {
			ParticleColor = Color3.fromRGB(100, 150, 255),
			GlowIntensity = 0.5,
		},
		epic = {
			ParticleColor = Color3.fromRGB(200, 100, 255),
			GlowIntensity = 0.7,
		},
		legendary = {
			ParticleColor = Color3.fromRGB(255, 200, 50),
			GlowIntensity = 1.0,
		},
	},
}

-- ============================================
-- COINS AND REWARDS
-- ============================================
Config.Rewards = {
	-- Coins in the air
	CoinValue = 10,           -- Base value of each coin

	-- Height milestone bonuses (small intervals for early engagement)
	HeightMilestones = {
		-- Initial intervals (frequent, small rewards)
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
		{ Height = 1000, Bonus = 250,   Message = "1 KILOMETER!!!!", Tier = "legendary" },
		{ Height = 1500, Bonus = 400,   Message = "1.5 KM!!!!", Tier = "legendary" },
		{ Height = 2000, Bonus = 600,   Message = "2 KILOMETERS!!!!!", Tier = "mythic" },
		{ Height = 3000, Bonus = 1000,  Message = "3 KM!!!!!", Tier = "mythic" },
		{ Height = 5000, Bonus = 2000,  Message = "5 KILOMETERS!!!!!!", Tier = "mythic" },

		-- Extended milestones (5km - 30km / SPACE)
		{ Height = 6000,  Bonus = 2500,   Message = "6 KM!!!!!", Tier = "mythic" },
		{ Height = 7000,  Bonus = 3000,   Message = "7 KM!!!!!", Tier = "mythic" },
		{ Height = 8000,  Bonus = 4000,   Message = "8 KM!!!!!", Tier = "mythic" },
		{ Height = 10000, Bonus = 5000,   Message = "10 KILOMETERS!!!!!", Tier = "mythic" },
		{ Height = 12000, Bonus = 7000,   Message = "12 KM!!!!!", Tier = "mythic" },
		{ Height = 15000, Bonus = 10000,  Message = "15 KILOMETERS!!!!!", Tier = "mythic" },
		{ Height = 18000, Bonus = 12000,  Message = "18 KM!!!!!", Tier = "mythic" },
		{ Height = 20000, Bonus = 15000,  Message = "20 KILOMETERS!!!!!", Tier = "mythic" },
		{ Height = 25000, Bonus = 20000,  Message = "25 KM!!!!!", Tier = "mythic" },
		{ Height = 30000, Bonus = 30000,  Message = "🚀 SPACE REACHED!!! 🚀", Tier = "mythic" },
	},

	-- Colors and effects per reward tier
	TierEffects = {
		common =    { Color = Color3.fromRGB(255, 255, 255), Scale = 1.0, Duration = 0.8 },
		uncommon =  { Color = Color3.fromRGB(100, 255, 100), Scale = 1.2, Duration = 1.0 },
		rare =      { Color = Color3.fromRGB(100, 150, 255), Scale = 1.4, Duration = 1.2 },
		epic =      { Color = Color3.fromRGB(200, 100, 255), Scale = 1.6, Duration = 1.5 },
		legendary = { Color = Color3.fromRGB(255, 200, 50),  Scale = 2.0, Duration = 2.0 },
		mythic =    { Color = Color3.fromRGB(255, 100, 100), Scale = 2.5, Duration = 2.5 },
	},

	-- Airtime bonus
	AirTimeBonus = 1, -- Extra coins per second in the air
}

-- ============================================
-- FART COSMETICS
-- ============================================
Config.FartCosmetics = {
	-- ==========================================
	-- TIER: COMMON (Cheap, simple colors)
	-- ==========================================
	Default = {
		Name = "Natural Gas",
		Description = "The classic green fart",
		Tier = "common",
		Icon = "💨",
		CostRobux = 0, -- Free, comes by default
		Colors = {
			Color3.fromRGB(140, 160, 80),
			Color3.fromRGB(100, 120, 50),
			Color3.fromRGB(80, 100, 40),
		},
		ParticleSize = {Min = 0.5, Max = 2},
		Animated = false,
	},

	Blue = {
		Name = "Blue Breeze",
		Description = "A fresh and refreshing fart",
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
		Name = "Pink Cloud",
		Description = "Adorable and stinky",
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
		Name = "Mystic Vapor",
		Description = "Mysterious and smelly",
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
	-- TIER: RARE (More eye-catching effects)
	-- ==========================================
	Toxic = {
		Name = "Radioactive Toxic",
		Description = "Warning! Radiation level: EXTREME",
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
		Name = "Fire Fart",
		Description = "Spicy going in, explosive going out",
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
		Name = "Frozen Blizzard",
		Description = "So cold it freezes the air",
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
		Name = "Dark Shadow",
		Description = "From the depths of the abyss",
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
	-- TIER: EPIC (Animated and special)
	-- ==========================================
	Lava = {
		Name = "Volcanic Magma",
		Description = "Straight from the Earth's core",
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
		Name = "Electric Storm",
		Description = "10,000 volts of pure power",
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
		Name = "Galactic Nebula",
		Description = "A fart of cosmic proportions",
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
		Name = "Cyberpunk Neon",
		Description = "Welcome to the future of gas",
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
	-- TIER: LEGENDARY (The most premium)
	-- ==========================================
	Rainbow = {
		Name = "Magic Rainbow",
		Description = "All the colors, all the smell",
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
		Name = "Golden Fart",
		Description = "The most valuable gas in the world",
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
		Name = "Brilliant Diamond",
		Description = "Pure crystallized luxury",
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
	-- TIER: MYTHIC (Ultra exclusive)
	-- ==========================================
	Void = {
		Name = "Dimensional Void",
		Description = "Opens portals to other dimensions",
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
		Name = "Infinite Chromatic",
		Description = "Constantly changing, never repeats",
		Tier = "mythic",
		Icon = "✨",
		CostRobux = 1299,
		Colors = {}, -- Dynamically generated
		ParticleSize = {Min = 1, Max = 4},
		Animated = true,
		AnimationType = "chromatic",
		Glow = true,
		Sparkles = true,
		Trail = true,
		AllEffects = true, -- Combines all effects
	},

	Legendary_Phoenix = {
		Name = "Reborn Phoenix",
		Description = "From the ashes rises the most powerful smell",
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

-- Tier colors for UI
Config.CosmeticTiers = {
	common = {
		Name = "Common",
		Color = Color3.fromRGB(180, 180, 180),
		GlowColor = Color3.fromRGB(150, 150, 150),
	},
	rare = {
		Name = "Rare",
		Color = Color3.fromRGB(100, 180, 255),
		GlowColor = Color3.fromRGB(50, 150, 255),
	},
	epic = {
		Name = "Epic",
		Color = Color3.fromRGB(200, 100, 255),
		GlowColor = Color3.fromRGB(180, 50, 255),
	},
	legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(255, 200, 50),
		GlowColor = Color3.fromRGB(255, 180, 0),
	},
	mythic = {
		Name = "Mythic",
		Color = Color3.fromRGB(255, 100, 100),
		GlowColor = Color3.fromRGB(255, 50, 50),
	},
}

-- Display order (from cheapest to most expensive)
Config.CosmeticOrder = {
	"Default", "Blue", "Pink", "Purple",           -- Common
	"Toxic", "Fire", "Ice", "Shadow",              -- Rare
	"Lava", "Electric", "Galaxy", "Neon",          -- Epic
	"Rainbow", "Golden", "Diamond",                 -- Legendary
	"Void", "Chromatic", "Legendary_Phoenix",      -- Mythic
}

-- ============================================
-- PET SYSTEM
-- ============================================

-- Rarities
Config.PetRarities = {
	Common = {
		Name = "Common",
		Color = Color3.fromRGB(177, 188, 191),
		BackgroundId = "rbxassetid://17336706814",
	},
	Uncommon = {
		Name = "Uncommon",
		Color = Color3.fromRGB(94, 194, 51),
		BackgroundId = "rbxassetid://17336708149",
	},
	Rare = {
		Name = "Rare",
		Color = Color3.fromRGB(71, 204, 255),
		BackgroundId = "rbxassetid://17336709544",
	},
	Epic = {
		Name = "Epic",
		Color = Color3.fromRGB(227, 9, 13),
		BackgroundId = "rbxassetid://17336710759",
	},
	Legendary = {
		Name = "Legendary",
		Color = Color3.fromRGB(243, 193, 10),
		BackgroundId = "rbxassetid://17336711281",
	},
}

-- Boost types for pets
Config.PetBoostTypes = {
	CoinBoost = { Name = "Coins", Icon = "💰", Color = Color3.fromRGB(255, 220, 50) },
	TrophyBoost = { Name = "Trophies", Icon = "🏆", Color = Color3.fromRGB(255, 180, 50) },
	FatnessBoost = { Name = "Max Size", Icon = "📦", Color = Color3.fromRGB(255, 150, 100) },
	EatBoost = { Name = "Eat Speed", Icon = "🍔", Color = Color3.fromRGB(255, 200, 100) },
	PropulsionBoost = { Name = "Fart Power", Icon = "💨", Color = Color3.fromRGB(100, 200, 255) },
	EfficiencyBoost = { Name = "Efficiency", Icon = "⚡", Color = Color3.fromRGB(150, 255, 150) },
}

-- Pet definitions with varied boosts
Config.Pets = {
	-- ============================================
	-- COMMON PETS (BasicEgg) - Single boost 15-18%
	-- ============================================
	Dog = {
		Name = "Dog",
		Rarity = "Common",
		Icon = "🐕",
		Boosts = { CoinBoost = 0.15 },
	},
	Bunny = {
		Name = "Bunny",
		Rarity = "Common",
		Icon = "🐰",
		Boosts = { EatBoost = 0.15 },
	},
	Duck = {
		Name = "Duck",
		Rarity = "Common",
		Icon = "🦆",
		Boosts = { EfficiencyBoost = 0.15 },
	},
	Axolotl = {
		Name = "Axolotl",
		Rarity = "Common",
		Icon = "🦎",
		Boosts = { FatnessBoost = 0.15 },
	},
	Lion = {
		Name = "Lion",
		Rarity = "Common",
		Icon = "🦁",
		Boosts = { PropulsionBoost = 0.15 },
	},
	Lamp = {
		Name = "Lamp",
		Rarity = "Common",
		Icon = "🪔",
		Boosts = { TrophyBoost = 0.15 },
	},
	Bee = {
		Name = "Bee",
		Rarity = "Common",
		Icon = "🐝",
		Boosts = { CoinBoost = 0.18 },
	},
	Cow = {
		Name = "Cow",
		Rarity = "Common",
		Icon = "🐄",
		Boosts = { FatnessBoost = 0.18 },
	},
	Chicken = {
		Name = "Chicken",
		Rarity = "Common",
		Icon = "🐔",
		Boosts = { EatBoost = 0.18 },
	},
	Pig = {
		Name = "Pig",
		Rarity = "Common",
		Icon = "🐷",
		Boosts = { EfficiencyBoost = 0.18 },
	},

	-- ============================================
	-- UNCOMMON PETS (PremiumEgg) - 35-38%
	-- ============================================
	Cat = {
		Name = "Cat",
		Rarity = "Uncommon",
		Icon = "🐈",
		Boosts = { EatBoost = 0.35 },
	},
	Elephant = {
		Name = "Elephant",
		Rarity = "Uncommon",
		Icon = "🐘",
		Boosts = { FatnessBoost = 0.38 },
	},
	Parrot = {
		Name = "Parrot",
		Rarity = "Uncommon",
		Icon = "🦜",
		Boosts = { TrophyBoost = 0.35 },
	},
	Monkey = {
		Name = "Monkey",
		Rarity = "Uncommon",
		Icon = "🐵",
		Boosts = { CoinBoost = 0.20, EatBoost = 0.15 },
	},

	-- ============================================
	-- RARE PETS (PremiumEgg) - ~40-60%
	-- ============================================
	Dragon = {
		Name = "Dragon",
		Rarity = "Rare",
		Icon = "🐉",
		Boosts = { PropulsionBoost = 0.40, CoinBoost = 0.20 },
	},

	-- ============================================
	-- GOLDEN PETS (RobuxEgg) - ~60-100%
	-- ============================================
	GoldenDog = {
		Name = "Golden Dog",
		Rarity = "Rare",
		Icon = "✨",
		Boosts = { CoinBoost = 0.40, EatBoost = 0.30 },
	},
	GoldenAxolotl = {
		Name = "Golden Axolotl",
		Rarity = "Rare",
		Icon = "✨",
		Boosts = { FatnessBoost = 0.35, EfficiencyBoost = 0.30 },
	},
	GoldenLion = {
		Name = "Golden Lion",
		Rarity = "Rare",
		Icon = "✨",
		Boosts = { PropulsionBoost = 0.40, CoinBoost = 0.25 },
	},
	-- ============================================
	-- EPIC PETS (RobuxEgg) - 95-115%
	-- ============================================
	GoldenCat = {
		Name = "Golden Cat",
		Rarity = "Epic",
		Icon = "✨",
		Boosts = { EatBoost = 0.45, TrophyBoost = 0.30, CoinBoost = 0.20 },  -- 95%
	},
	RainbowAxolotl = {
		Name = "Rainbow Axolotl",
		Rarity = "Epic",
		Icon = "🌈",
		Boosts = {
			FatnessBoost = 0.45,
			EfficiencyBoost = 0.35,
			CoinBoost = 0.25,
		},  -- 105%
	},
	RainbowDog = {
		Name = "Rainbow Dog",
		Rarity = "Epic",
		Icon = "🌈",
		Boosts = {
			CoinBoost = 0.45,
			EatBoost = 0.35,
			TrophyBoost = 0.25,
		},  -- 105%
	},
	RainbowCat = {
		Name = "Rainbow Cat",
		Rarity = "Epic",
		Icon = "🌈",
		Boosts = {
			EatBoost = 0.50,
			TrophyBoost = 0.35,
			CoinBoost = 0.30,
		},  -- 115%
	},

	-- ============================================
	-- LEGENDARY PETS (RobuxEgg) - 160-240%
	-- ============================================
	GoldenDragon = {
		Name = "Golden Dragon",
		Rarity = "Legendary",
		Icon = "✨",
		Boosts = {
			CoinBoost = 0.55,
			PropulsionBoost = 0.45,
			TrophyBoost = 0.35,
			FatnessBoost = 0.25,
		},  -- 160%
	},
	RainbowDragon = {
		Name = "Rainbow Dragon",
		Rarity = "Legendary",
		Icon = "🌈",
		Boosts = {
			CoinBoost = 0.55,
			TrophyBoost = 0.45,
			PropulsionBoost = 0.45,
			EfficiencyBoost = 0.35,
			FatnessBoost = 0.30,
			EatBoost = 0.30,
		},  -- 240%
	},
}

-- Eggs
Config.Eggs = {
	BasicEgg = {
		Name = "Basic Egg",
		TrophyCost = 2,
		Icon = "🥚",
		Description = "Common pets with rare Uncommon chance!",
		Pets = {
			-- Common (97% total)
			Dog = 0.18,
			Bunny = 0.15,
			Duck = 0.12,
			Axolotl = 0.12,
			Lion = 0.10,
			Bee = 0.08,
			Cow = 0.07,
			Chicken = 0.06,
			Pig = 0.05,
			Lamp = 0.04,
			-- Uncommon (3%)
			Cat = 0.03,
		},
	},

	PremiumEgg = {
		Name = "Premium Egg",
		TrophyCost = 20,
		Icon = "🥇",
		Description = "Uncommon pets with rare Dragon!",
		Pets = {
			-- Uncommon (90%)
			Cat = 0.28,
			Elephant = 0.25,
			Parrot = 0.22,
			Monkey = 0.15,
			-- Rare (10%)
			Dragon = 0.10,
		},
	},

	RobuxEgg = {
		Name = "Golden Egg",
		CostRobux = 99,
		Icon = "💎",
		DevProductId = 0,
		Description = "Exclusive Golden & Rainbow pets!",
		Pets = {
			-- Rare Golden (65%)
			GoldenDog = 0.25,
			GoldenAxolotl = 0.22,
			GoldenLion = 0.18,
			-- Epic (30%)
			GoldenCat = 0.12,
			RainbowAxolotl = 0.08,
			RainbowDog = 0.06,
			RainbowCat = 0.04,
			-- Legendary (5%)
			GoldenDragon = 0.03,
			RainbowDragon = 0.02,
		},
	},
}

-- Pet System Settings
Config.PetSystem = {
	DefaultEquipSlots = 3,
	DefaultInventorySlots = 50,
	Spacing = 5,
	MaxClimbHeight = 13,
	WalkAnimationSpeed = 10,
	IdleAnimationSpeed = 10,
	WalkAmplitude = 0.5,
	IdleAmplitude = 0.05,
	FlyingHeightOffset = 2,
}

-- ============================================
-- GAME ZONES
-- ============================================
Config.Zones = {
	-- Base ground height of the game zone
	GameZoneBaseHeight = 0,

	-- Lobby bounds (to detect when player enters game zone)
	LobbyBounds = {
		MinX = -50,
		MaxX = 50,
		MinZ = -50,
		MaxZ = 50,
	},
}

-- ============================================
-- DEFAULT PLAYER DATA
-- ============================================
Config.DefaultPlayerData = {
	Coins = 0,
	Trophies = 0,

	-- Upgrade levels (0 = not purchased, uses base value)
	Upgrades = {
		MaxFatness = 0,
		EatSpeed = 0,
		PropulsionForce = 0,
		FuelEfficiency = 0,
	},

	-- Unlocked food
	UnlockedFood = {
		Salad = true, -- Always unlocked
	},

	-- Unlocked zones
	UnlockedZones = {},

	-- Fart cosmetics
	OwnedCosmetics = {
		Default = true, -- Basic fart is always unlocked
	},
	EquippedCosmetic = "Default", -- Currently equipped cosmetic

	-- Personal records
	Records = {
		MaxHeight = 0,
		TotalCoinsEarned = 0,
		TotalFlights = 0,
	},

	-- Pet system data
	PetSystem = {
		Pets = {}, -- {PetName, UUID, Equiped, Locked}
		EquipSlots = 3,
		InventorySlots = 50,
		PetIndex = {}, -- Mascotas descubiertas
	},
}

return Config
