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
-- UPGRADES
-- ============================================
Config.Upgrades = {
	-- Maximum fatness
	MaxFatness = {
		Name = "Max Fatness",
		Description = "Increase your fat storage capacity",
		MaxLevel = 10,
		BaseValue = 1.5,
		IncrementPerLevel = 0.25, -- +0.25 per level (max 4.0 at level 10)
		CostCoins = { 100, 250, 500, 1000, 2000, 4000, 8000, 15000, 30000, 50000 },
		CostRobux = { 10, 20, 35, 50, 75, 100, 150, 200, 300, 500 },
	},

	-- Eating speed
	EatSpeed = {
		Name = "Eating Speed",
		Description = "Eat faster",
		MaxLevel = 10,
		BaseValue = 0.08,
		IncrementPerLevel = 0.02, -- +0.02 per level
		CostCoins = { 75, 200, 400, 800, 1500, 3000, 6000, 12000, 25000, 40000 },
		CostRobux = { 10, 15, 25, 40, 60, 80, 120, 175, 250, 400 },
	},

	-- Propulsion force (EXPONENTIAL)
	PropulsionForce = {
		Name = "Fart Power",
		Description = "More powerful farts push you higher",
		MaxLevel = 10,
		BaseValue = 50,
		-- Exponential progression: 50 -> 275 (5.5x more powerful at level 10)
		ValuesPerLevel = { 58, 68, 80, 95, 115, 140, 170, 210, 260, 320 },
		CostCoins = { 150, 350, 700, 1400, 2800, 5500, 11000, 22000, 45000, 75000 },
		CostRobux = { 15, 25, 40, 60, 90, 130, 180, 250, 350, 600 },
	},

	-- Fuel efficiency (EXPONENTIAL)
	FuelEfficiency = {
		Name = "Gas Efficiency",
		Description = "Lose less fat when propelling",
		MaxLevel = 10,
		BaseValue = 0.04,
		-- Exponential progression: 0.04 -> 0.004 (10x more efficient at level 10)
		ValuesPerLevel = { 0.032, 0.025, 0.019, 0.014, 0.010, 0.0075, 0.0055, 0.0045, 0.0038, 0.0032 },
		CostCoins = { 200, 500, 1000, 2000, 4000, 8000, 16000, 32000, 60000, 100000 },
		CostRobux = { 20, 35, 55, 80, 120, 170, 230, 320, 450, 750 },
	},
}

-- ============================================
-- FOOD
-- ============================================
Config.Food = {
	-- Basic food (free) - very slow
	Salad = {
		Name = "Salad",
		FatnessPerSecond = 0.00125,
		RequiresUnlock = false,
		CostCoins = 0,
		CostRobux = 0,
	},

	-- Normal food (coins)
	Burger = {
		Name = "Burger",
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

	-- Premium food (robux or very expensive)
	HotDog = {
		Name = "Special Hot Dog",
		FatnessPerSecond = 0.0125,
		RequiresUnlock = true,
		CostCoins = 10000,
		CostRobux = 100,
	},

	GoldenBurger = {
		Name = "Golden Burger",
		FatnessPerSecond = 0.02,
		RequiresUnlock = true,
		CostCoins = 0, -- Robux only
		CostRobux = 250,
		RobuxOnly = true,
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
}

return Config
