local DataStoreService = game:GetService("DataStoreService")
local PetStats = DataStoreService:GetDataStore("PetExits")

local module = {}

type Data = {
	[string]: number
}

local petCountData: Data = {} -- Bellekteki geçici veri
local loadedData: Data = {} -- Yüklenen eski veri

-- Bu fonksiyon, sunucu açıldığında eski verileri yükler
function module.LoadPetCounts()
	local data
	local success, err = pcall(function()
		data = PetStats:GetAsync("PetCount")
	end)
	if success and data then
		loadedData = data
	else
		loadedData = {}
	end
end

function module.CountPet(PetName)
	if not petCountData[PetName] then
		petCountData[PetName] = 0
	end
	petCountData[PetName] += 1
end

function module.GetPetCounts()
	local totalPetCounts: Data = {}

	-- Eski veriler
	for PetName, count in pairs(loadedData) do
		totalPetCounts[PetName] = count
	end

	-- Yeni eklenen veriler
	for PetName, count in pairs(petCountData) do
		if not totalPetCounts[PetName] then
			totalPetCounts[PetName] = 0
		end
		totalPetCounts[PetName] += count
	end

	return totalPetCounts
end

function module.SavePetCounts()
	PetStats:UpdateAsync("PetCount", function(data: Data?)
		if not data then
			data = {}
		end
		for PetName, count in pairs(petCountData) do
			if not data[PetName] then
				data[PetName] = 0
			end
			data[PetName] += count
		end
		petCountData = {} -- Bellekteki geçici veriyi sıfırla
		return data
	end)
end

-- Sunucu açıldığında eski verileri yükle
module.LoadPetCounts()

-- SavePetCounts fonksiyonunu belirli aralıklarla veya tetikleyici üzerinden çağır
game:BindToClose(module.SavePetCounts)

return module
