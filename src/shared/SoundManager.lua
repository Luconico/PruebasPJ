--[[
	SoundManager.lua
	Módulo centralizado para todos los sonidos de UI del juego
	Todos los IDs verificados y públicos de Roblox
]]

local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- ============================================
-- IDs DE SONIDOS VERIFICADOS
-- ============================================
SoundManager.Sounds = {
	-- UI General
	PopupOpen = "rbxassetid://2235655773",      -- Swoosh Sound Effect
	PopupClose = "rbxassetid://231731980",      -- Whoosh

	-- Botones
	ButtonHover = "rbxassetid://6324801967",    -- Button hover (cartoony)
	ButtonClick = "rbxassetid://4307186075",    -- Click sound (cartoony/bubble)

	-- Compras y Éxito
	PurchaseSuccess = "rbxassetid://1837507072", -- Victory sound
	CashRegister = "rbxassetid://7112275565",   -- Cash Register (Kaching)
	Sparkle = "rbxassetid://3292075199",        -- Sparkle Noise

	-- Acciones
	Equip = "rbxassetid://6042053626",          -- Equip/Action sound
	Error = "rbxassetid://5852470908",          -- Error/Blocked sound

	-- Ruleta
	SpinStart = "rbxassetid://6042053626",      -- Spin start sound
	SpinTick = "rbxassetid://9119713951",       -- Tick sound for spinning

	-- Recompensas por tier
	RewardSmall = "rbxassetid://7112275565",    -- Cash Register - pequeño
	RewardMedium = "rbxassetid://4307186075",   -- Click cartoony - medio
	RewardBig = "rbxassetid://1837507072",      -- Victory - grande
}

-- Alias para compatibilidad
SoundManager.Sounds.ShopOpen = SoundManager.Sounds.PopupOpen
SoundManager.Sounds.ShopClose = SoundManager.Sounds.PopupClose
SoundManager.Sounds.WheelOpen = SoundManager.Sounds.PopupOpen
SoundManager.Sounds.WheelClose = SoundManager.Sounds.PopupClose
SoundManager.Sounds.WinSmall = SoundManager.Sounds.RewardSmall
SoundManager.Sounds.WinBig = SoundManager.Sounds.RewardBig
SoundManager.Sounds.UnlockZone = SoundManager.Sounds.Equip

-- ============================================
-- FUNCIÓN PARA REPRODUCIR SONIDOS
-- ============================================

--[[
	Reproduce un sonido
	@param soundId string - ID del sonido (puede ser key de Sounds o rbxassetid completo)
	@param volume number? - Volumen (0-1), default 0.5
	@param pitch number? - Velocidad/pitch, default 1.0
	@return Sound - La instancia del sonido creado
]]
function SoundManager.play(soundId, volume, pitch)
	-- Si es una key del diccionario, obtener el ID real
	if SoundManager.Sounds[soundId] then
		soundId = SoundManager.Sounds[soundId]
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.PlaybackSpeed = pitch or 1
	sound.Parent = SoundService
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	return sound
end

-- ============================================
-- FUNCIONES DE CONVENIENCIA
-- ============================================

-- Reproduce sonido de hover de botón
function SoundManager.playHover()
	return SoundManager.play("ButtonHover", 0.2, 1.1)
end

-- Reproduce sonido de click de botón
function SoundManager.playClick()
	return SoundManager.play("ButtonClick", 0.5, 1.0)
end

-- Reproduce sonido de apertura de popup/tienda
function SoundManager.playOpen()
	SoundManager.play("PopupOpen", 0.4, 0.9)
	task.delay(0.15, function()
		SoundManager.play("Sparkle", 0.3, 1.2)
	end)
end

-- Reproduce sonido de cierre de popup/tienda
function SoundManager.playClose()
	return SoundManager.play("PopupClose", 0.3, 1.3)
end

-- Reproduce sonido de error
function SoundManager.playError()
	return SoundManager.play("Error", 0.5, 0.8)
end

-- Reproduce celebración de compra exitosa
function SoundManager.playCelebration()
	SoundManager.play("PurchaseSuccess", 0.6, 1.0)
	task.delay(0.1, function()
		SoundManager.play("CashRegister", 0.5, 1.1)
	end)
	task.delay(0.3, function()
		SoundManager.play("Sparkle", 0.5, 0.9)
	end)
	task.delay(0.6, function()
		SoundManager.play("Sparkle", 0.4, 1.3)
	end)
end

-- Reproduce sonido de compra (click + cash register)
function SoundManager.playPurchase()
	SoundManager.play("ButtonClick", 0.5, 1.0)
	SoundManager.play("CashRegister", 0.3, 1.1)
end

-- Reproduce sonido de equipar
function SoundManager.playEquip()
	SoundManager.play("Equip", 0.5, 1.0)
	SoundManager.play("Sparkle", 0.3, 1.1)
end

-- Reproduce sonido de recompensa según tier
function SoundManager.playReward(tier)
	local soundName = "RewardSmall"
	local volume = 0.2

	if tier == "rare" or tier == "epic" then
		soundName = "RewardMedium"
		volume = 0.3
	elseif tier == "legendary" or tier == "mythic" then
		soundName = "RewardBig"
		volume = 0.5
	end

	SoundManager.play(soundName, volume, 0.9 + math.random() * 0.25)

	-- Sparkle para tiers altos
	if tier == "epic" or tier == "legendary" or tier == "mythic" then
		task.delay(0.2, function()
			SoundManager.play("Sparkle", volume, 0.9 + math.random() * 0.3)
		end)
	end

	-- Doble sparkle para mítico
	if tier == "mythic" then
		task.delay(0.5, function()
			SoundManager.play("Sparkle", 0.4, 1.2 + math.random() * 0.2)
		end)
	end
end

-- Reproduce sonido de victoria (ruleta)
function SoundManager.playWin(isBigPrize)
	if isBigPrize then
		SoundManager.play("WinBig", 0.6, 1.0)
		task.delay(0.2, function()
			SoundManager.play("WinSmall", 0.5, 1.1)
		end)
		task.delay(0.4, function()
			SoundManager.play("Sparkle", 0.5, 0.9)
		end)
		task.delay(0.7, function()
			SoundManager.play("Sparkle", 0.4, 1.3)
		end)
	else
		SoundManager.play("WinSmall", 0.5, 1.0)
		task.delay(0.2, function()
			SoundManager.play("Sparkle", 0.4, 1.1)
		end)
	end
end

return SoundManager
