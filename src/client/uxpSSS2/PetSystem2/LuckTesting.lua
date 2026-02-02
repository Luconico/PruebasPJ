local PrizeList = {}

local PrizeTable = {
	["Dog"] = 1000,
	["Cat"] = 100,
	["Cow"] = 10,
}

local GeneralLuckBoost = 0.05

local InvertedPrizeTable = {}
local totalInvertedChance = 0

for prize, chance in pairs(PrizeTable) do
	InvertedPrizeTable[prize] = 1 / chance
	totalInvertedChance += InvertedPrizeTable[prize]
end

for prize, chance in pairs(InvertedPrizeTable) do
	InvertedPrizeTable[prize] = chance + GeneralLuckBoost
end

for i = 0, 1000, 1 do
	local Weight = 0

	for prize, chance in pairs(InvertedPrizeTable) do
		Weight += (chance * 1000)
	end

	local ranNumber = math.random(1, Weight)

	Weight = 0

	for prize, chance in pairs(InvertedPrizeTable) do
		Weight += (chance * 1000)

		if Weight >= ranNumber then
			if PrizeList[prize] == nil then
				PrizeList[prize] = 0
			end

			PrizeList[prize] += 1
			break
		end
	end
end

print(PrizeList)
