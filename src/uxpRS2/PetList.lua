local ReplicatedStorage = game:GetService("ReplicatedStorage")
local uxpRS = ReplicatedStorage.uxpRS
local PetSystem = uxpRS.PetSystem
local PetModels = PetSystem.Pets

-- Gray rbxassetid://17336706814 Common #b1bcbf
-- Green rbxassetid://17336708149 Uncommon #5ec233
-- Blue rbxassetid://17336709544 Semi-Rare #47CCFF
-- Purple rbxassetid://17336710202 Rare #d116f6
-- Red rbxassetid://17336710759 Epic #e3090d
-- Yellow rbxassetid://17336711281 Legendary #f3c10a

local module = {

	[1] = {

		PetName = "Axolotl",
		PetDisplayName = "Axolotl",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[2] = {

		PetName = "GoldenAxolotl",
		PetDisplayName = "Golden Axolotl",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[3] = {

		PetName = "RainbowGoldenAxolotl",
		PetDisplayName = "Rainbow Axolotl",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[4] = {

		PetName = "Lion",
		PetDisplayName = "Lion",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[5] = {

		PetName = "GoldenLion",
		PetDisplayName = "Golden Lion",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[6] = {

		PetName = "RainbowGoldenLion",
		PetDisplayName = "Rainbow Lion",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[7] = {

		PetName = "Dragon",
		PetDisplayName = "Dragon",
		Boost = 0.9,
		Type = "Normal",
		Rarity = "Rare",
		RarityColor = "#d116f6",
		RarityBackground = "rbxassetid://17336710202",

	},

	[8] = {

		PetName = "GoldenDragon",
		PetDisplayName = "Golden Dragon",
		Boost = 1.3,
		Type = "Golden",
		Rarity = "Rare",
		RarityColor = "#d116f6",
		RarityBackground = "rbxassetid://17336710202",

	},

	[9] = {

		PetName = "RainbowGoldenDragon",
		PetDisplayName = "Rainbow Dragon",
		Boost = 1.9,
		Type = "Rainbow",
		Rarity = "Legendary",
		RarityColor = "#f3c10a",
		RarityBackground = "rbxassetid://17336711281",

	},

	[10] = {

		PetName = "Dog",
		PetDisplayName = "Dog",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[11] = {

		PetName = "GoldenDog",
		PetDisplayName = "Golden Dog",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[12] = {

		PetName = "RainbowGoldenDog",
		PetDisplayName = "Rainbow Dog",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Epic",
		RarityColor = "#e3090d",
		RarityBackground = "rbxassetid://17336710759",

	},

	[13] = {

		PetName = "Cat",
		PetDisplayName = "Cat",
		Boost = 0.5,
		Type = "Normal",
		Rarity = "Uncommon",
		RarityColor = "#5ec233",
		RarityBackground = "rbxassetid://17336708149",

	},

	[14] = {

		PetName = "GoldenCat",
		PetDisplayName = "Golden Cat",
		Boost = 0.6,
		Type = "Golden",
		Rarity = "Uncommon",
		RarityColor = "#5ec233",
		RarityBackground = "rbxassetid://17336708149",

	},

	[15] = {

		PetName = "RainbowGoldenCat",
		PetDisplayName = "Rainbow Cat",
		Boost = 0.7,
		Type = "Rainbow",
		Rarity = "Uncommon",
		RarityColor = "#5ec233",
		RarityBackground = "rbxassetid://17336708149",

	},

	[16] = {

		PetName = "Bunny",
		PetDisplayName = "Bunny",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[17] = {

		PetName = "GoldenBunny",
		PetDisplayName = "Golden Bunny",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[18] = {

		PetName = "RainbowGoldenBunny",
		PetDisplayName = "Rainbow Bunny",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[19] = {

		PetName = "Duck",
		PetDisplayName = "Duck",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[20] = {

		PetName = "GoldenDuck",
		PetDisplayName = "Golden Duck",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[21] = {

		PetName = "RainbowGoldenDuck",
		PetDisplayName = "Rainbow Duck",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[22] = {

		PetName = "Monkey",
		PetDisplayName = "Monkey",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[23] = {

		PetName = "GoldenMonkey",
		PetDisplayName = "Golden Monkey",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[24] = {

		PetName = "RainbowGoldenMonkey",
		PetDisplayName = "Rainbow Monkey",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[25] = {

		PetName = "Bee",
		PetDisplayName = "Bee",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[26] = {

		PetName = "GoldenBee",
		PetDisplayName = "Golden Bee",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[27] = {

		PetName = "RainbowGoldenBee",
		PetDisplayName = "Rainbow Bee",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[28] = {

		PetName = "Parrot",
		PetDisplayName = "Parrot",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[29] = {

		PetName = "GoldenParrot",
		PetDisplayName = "Golden Parrot",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[30] = {

		PetName = "RainbowGoldenParrot",
		PetDisplayName = "Rainbow Parrot",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[31] = {

		PetName = "Cow",
		PetDisplayName = "Cow",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[32] = {

		PetName = "GoldenCow",
		PetDisplayName = "Golden Cow",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[33] = {

		PetName = "RainbowGoldenCow",
		PetDisplayName = "Rainbow Cow",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[34] = {

		PetName = "Chicken",
		PetDisplayName = "Chicken",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[35] = {

		PetName = "GoldenChicken",
		PetDisplayName = "Golden Chicken",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[36] = {

		PetName = "RainbowGoldenChicken",
		PetDisplayName = "Rainbow Chicken",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[37] = {

		PetName = "Pig",
		PetDisplayName = "Pig",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[38] = {

		PetName = "GoldenPig",
		PetDisplayName = "Golden Pig",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[39] = {

		PetName = "RainbowGoldenPig",
		PetDisplayName = "Rainbow Pig",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[40] = {

		PetName = "Lamp",
		PetDisplayName = "Lamp",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[41] = {

		PetName = "GoldenLamp",
		PetDisplayName = "Golden Lamp",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[42] = {

		PetName = "RainbowGoldenLamp",
		PetDisplayName = "Rainbow Lamp",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[43] = {

		PetName = "Elephant",
		PetDisplayName = "Elephant",
		Boost = 0.4,
		Type = "Normal",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[44] = {

		PetName = "GoldenElephant",
		PetDisplayName = "Golden Elephant",
		Boost = 0.4,
		Type = "Golden",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},

	[45] = {

		PetName = "RainbowGoldenElephant",
		PetDisplayName = "Rainbow Elephant",
		Boost = 0.4,
		Type = "Rainbow",
		Rarity = "Common",
		RarityColor = "#b1bcbf",
		RarityBackground = "rbxassetid://17336706814",

	},
	
	
}

return module
