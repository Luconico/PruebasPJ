-- Gray rbxassetid://17336706814 Common #b1bcbf
-- Green rbxassetid://17336708149 Uncommon #5ec233
-- Blue rbxassetid://17336709544 Semi-Rare #47CCFF
-- Purple rbxassetid://17336710202 Rare #d116f6
-- Red rbxassetid://17336710759 Epik #e3090d
-- Yellow rbxassetid://17336711281 Legendary #f3c10a

local module = {
	
	["Pet1"] = {
		
		Price = 2500,
		RobuxPrice = 1,
		RobuxPet = false,
		DevID = 0000000,
		
		EggName = "Basic Egg",
		EggModelName = "Egg9",
		EggImage = "rbxassetid://16178297800",
		
		Pets = {
			
			[1] = {
				
				Chance = 50,
				PetName = "Dog",
				PetBackgroundImage = "rbxassetid://17336706814",
				Rainbow = false,
				
			},

			[2] = {

				Chance = 35,
				PetName = "Cat",
				PetBackgroundImage = "rbxassetid://17336708149",
				Rainbow = false,

			},

			[3] = {

				Chance = 15,
				PetName = "GoldenCat",
				PetBackgroundImage = "rbxassetid://17336706814",
				Rainbow = false,

			},

			[4] = {

				Chance = 5,
				PetName = "Dragon",
				PetBackgroundImage = "rbxassetid://17336710202",
				Rainbow = false,

			},

			[5] = {

				Chance = 1,
				PetName = "RainbowGoldenDog",
				PetBackgroundImage = "rbxassetid://17336710759",
				Rainbow = false,

			},

			[6] = {

				Chance = 0.01,
				PetName = "RainbowGoldenDragon",
				PetBackgroundImage = "rbxassetid://17336711281",
				Rainbow = false,

			},
			
		},
		
	},
	
	["Pet2"] = {

		Price = 1,
		RobuxPrice = 1,
		RobuxPet = true,
		DevID = 1750131364,

		EggName = "Robux Egg",
		EggModelName = "Egg6",
		EggImage = "rbxassetid://16178297800",

		Pets = {

			[1] = {

				Chance = 50,
				PetName = "Lamp",
				PetBackgroundImage = "rbxassetid://17336708149",
				Rainbow = false,

			},

			[2] = {

				Chance = 30,
				PetName = "Lion",
				PetBackgroundImage = "rbxassetid://17336709544",
				Rainbow = false,

			},

			[3] = {

				Chance = 20,
				PetName = "Monkey",
				PetBackgroundImage = "rbxassetid://17336710202",
				Rainbow = false,

			},

			[4] = {

				Chance = 5,
				PetName = "Parrot",
				PetBackgroundImage = "rbxassetid://17336710759",
				Rainbow = true,

			},

		},

	},
	
}

return module
