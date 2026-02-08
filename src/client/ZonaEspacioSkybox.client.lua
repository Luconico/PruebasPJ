--[[
	ZonaEspacioSkybox.client.lua

	Este LocalScript cambia el cielo a un skybox espacial con estrellas
	cuando el jugador entra en una zona específica.

	CONFIGURACIÓN REQUERIDA:
	1. Crear un Part en Workspace llamado "ZonaEspacio" (invisible, sin colisión)
	2. El Part define el área donde se activa el cielo espacial
]]

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ═══════════════════════════════════════════════════════════════════
-- CONFIGURACIÓN DEL SKYBOX ESPACIAL
-- ═══════════════════════════════════════════════════════════════════

-- IDs de skybox espacial oscuro con estrellas (puedes cambiarlos por otros)
local SKYBOX_ESPACIO = {
	SkyboxBk = "rbxassetid://159454286",  -- Espacio negro con estrellas
	SkyboxDn = "rbxassetid://159454286",
	SkyboxFt = "rbxassetid://159454286",
	SkyboxLf = "rbxassetid://159454286",
	SkyboxRt = "rbxassetid://159454286",
	SkyboxUp = "rbxassetid://159454286",
	StarCount = 5000,  -- Muchas estrellas visibles
	SunAngularSize = 0,  -- Sin sol visible
	MoonAngularSize = 5,  -- Luna pequeña o invisible (0 para quitarla)
}

-- Configuración de Lighting para efecto espacial (mapa iluminado, cielo oscuro)
local LIGHTING_ESPACIO = {
	Ambient = Color3.fromRGB(170, 170, 180),      -- Iluminación base alta para ver los parts
	OutdoorAmbient = Color3.fromRGB(160, 160, 170), -- Iluminación exterior alta
	Brightness = 2,
	ClockTime = 14,  -- Hora de día para mantener iluminación en el mapa
	GeographicLatitude = 0,
	ExposureCompensation = 0.3,
}

-- ═══════════════════════════════════════════════════════════════════
-- VARIABLES DE ESTADO
-- ═══════════════════════════════════════════════════════════════════

local zonasEspacio = {} -- Tabla con todos los Parts "ZonaEspacio"
local dentroDeZona = false

-- Guardar configuración original
local skyOriginal = nil
local lightingOriginal = {}

-- ═══════════════════════════════════════════════════════════════════
-- FUNCIONES
-- ═══════════════════════════════════════════════════════════════════

-- Guarda la configuración original del cielo y lighting
local function guardarConfiguracionOriginal()
	-- Guardar Sky original
	local skyActual = Lighting:FindFirstChildOfClass("Sky")
	if skyActual then
		skyOriginal = {
			SkyboxBk = skyActual.SkyboxBk,
			SkyboxDn = skyActual.SkyboxDn,
			SkyboxFt = skyActual.SkyboxFt,
			SkyboxLf = skyActual.SkyboxLf,
			SkyboxRt = skyActual.SkyboxRt,
			SkyboxUp = skyActual.SkyboxUp,
			StarCount = skyActual.StarCount,
			SunAngularSize = skyActual.SunAngularSize,
			MoonAngularSize = skyActual.MoonAngularSize,
		}
	end

	-- Guardar Lighting original
	lightingOriginal = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		GeographicLatitude = Lighting.GeographicLatitude,
		ExposureCompensation = Lighting.ExposureCompensation,
	}
end

-- Verifica si el jugador está dentro de alguna zona
local function estaEnZona(personaje)
	if #zonasEspacio == 0 or not personaje then
		return false
	end

	local hrp = personaje:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	-- Comprobar si está dentro de CUALQUIERA de las zonas
	for _, zona in ipairs(zonasEspacio) do
		if zona and zona.Parent then -- Verificar que el Part siga existiendo
			local zonaCF = zona.CFrame
			local zonaSize = zona.Size

			local posRelativa = zonaCF:PointToObjectSpace(hrp.Position)

			if math.abs(posRelativa.X) <= zonaSize.X / 2
				and math.abs(posRelativa.Y) <= zonaSize.Y / 2
				and math.abs(posRelativa.Z) <= zonaSize.Z / 2 then
				return true
			end
		end
	end

	return false
end

-- Interpola suavemente entre dos valores
local function lerp(a, b, t)
	return a + (b - a) * t
end

-- Interpola Color3
local function lerpColor3(c1, c2, t)
	return Color3.new(
		lerp(c1.R, c2.R, t),
		lerp(c1.G, c2.G, t),
		lerp(c1.B, c2.B, t)
	)
end

-- Aplica el cielo espacial con transición suave
local function aplicarCieloEspacial()
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end

	-- Aplicar texturas del skybox espacial
	sky.SkyboxBk = SKYBOX_ESPACIO.SkyboxBk
	sky.SkyboxDn = SKYBOX_ESPACIO.SkyboxDn
	sky.SkyboxFt = SKYBOX_ESPACIO.SkyboxFt
	sky.SkyboxLf = SKYBOX_ESPACIO.SkyboxLf
	sky.SkyboxRt = SKYBOX_ESPACIO.SkyboxRt
	sky.SkyboxUp = SKYBOX_ESPACIO.SkyboxUp
	sky.StarCount = SKYBOX_ESPACIO.StarCount
	sky.SunAngularSize = SKYBOX_ESPACIO.SunAngularSize
	sky.MoonAngularSize = SKYBOX_ESPACIO.MoonAngularSize

	-- Transición suave del Lighting
	local duracion = 1.5  -- segundos
	local tiempoInicio = tick()

	local lightingInicial = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		ExposureCompensation = Lighting.ExposureCompensation,
	}

	local conexion
	conexion = RunService.RenderStepped:Connect(function()
		local transcurrido = tick() - tiempoInicio
		local t = math.min(transcurrido / duracion, 1)

		-- Easing suave
		t = t * t * (3 - 2 * t)

		Lighting.Ambient = lerpColor3(lightingInicial.Ambient, LIGHTING_ESPACIO.Ambient, t)
		Lighting.OutdoorAmbient = lerpColor3(lightingInicial.OutdoorAmbient, LIGHTING_ESPACIO.OutdoorAmbient, t)
		Lighting.Brightness = lerp(lightingInicial.Brightness, LIGHTING_ESPACIO.Brightness, t)
		Lighting.ClockTime = lerp(lightingInicial.ClockTime, LIGHTING_ESPACIO.ClockTime, t)
		Lighting.ExposureCompensation = lerp(lightingInicial.ExposureCompensation, LIGHTING_ESPACIO.ExposureCompensation, t)

		if t >= 1 then
			conexion:Disconnect()
		end
	end)
end

-- Restaura el cielo original con transición suave
local function restaurarCieloOriginal()
	if not skyOriginal then
		return
	end

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end

	-- Restaurar texturas del skybox
	sky.SkyboxBk = skyOriginal.SkyboxBk
	sky.SkyboxDn = skyOriginal.SkyboxDn
	sky.SkyboxFt = skyOriginal.SkyboxFt
	sky.SkyboxLf = skyOriginal.SkyboxLf
	sky.SkyboxRt = skyOriginal.SkyboxRt
	sky.SkyboxUp = skyOriginal.SkyboxUp
	sky.StarCount = skyOriginal.StarCount
	sky.SunAngularSize = skyOriginal.SunAngularSize
	sky.MoonAngularSize = skyOriginal.MoonAngularSize

	-- Transición suave del Lighting de vuelta
	local duracion = 1.5
	local tiempoInicio = tick()

	local lightingInicial = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		ExposureCompensation = Lighting.ExposureCompensation,
	}

	local conexion
	conexion = RunService.RenderStepped:Connect(function()
		local transcurrido = tick() - tiempoInicio
		local t = math.min(transcurrido / duracion, 1)

		t = t * t * (3 - 2 * t)

		Lighting.Ambient = lerpColor3(lightingInicial.Ambient, lightingOriginal.Ambient, t)
		Lighting.OutdoorAmbient = lerpColor3(lightingInicial.OutdoorAmbient, lightingOriginal.OutdoorAmbient, t)
		Lighting.Brightness = lerp(lightingInicial.Brightness, lightingOriginal.Brightness, t)
		Lighting.ClockTime = lerp(lightingInicial.ClockTime, lightingOriginal.ClockTime, t)
		Lighting.ExposureCompensation = lerp(lightingInicial.ExposureCompensation, lightingOriginal.ExposureCompensation, t)

		if t >= 1 then
			conexion:Disconnect()
		end
	end)
end

-- ═══════════════════════════════════════════════════════════════════
-- INICIALIZACIÓN
-- ═══════════════════════════════════════════════════════════════════

-- Buscar TODOS los Parts llamados "ZonaEspacio" en todo el Workspace
local function buscarZonasEspacio()
	zonasEspacio = {}
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant.Name == "ZonaEspacio" and descendant:IsA("BasePart") then
			table.insert(zonasEspacio, descendant)
		end
	end
end

buscarZonasEspacio()

-- Detectar si se añaden nuevas zonas en tiempo de ejecución
workspace.DescendantAdded:Connect(function(descendant)
	if descendant.Name == "ZonaEspacio" and descendant:IsA("BasePart") then
		table.insert(zonasEspacio, descendant)
		print("[ZonaEspacioSkybox] Nueva zona detectada, total: " .. #zonasEspacio)
	end
end)

if #zonasEspacio == 0 then
	warn("[ZonaEspacioSkybox] No se encontró ningún 'ZonaEspacio' en Workspace")
	return
end

-- Guardar configuración original al iniciar
guardarConfiguracionOriginal()

print("[ZonaEspacioSkybox] Script inicializado - " .. #zonasEspacio .. " zona(s) encontrada(s)")

-- ═══════════════════════════════════════════════════════════════════
-- LOOP PRINCIPAL DE DETECCIÓN
-- ═══════════════════════════════════════════════════════════════════

while true do
	local personaje = player.Character
	local enZona = estaEnZona(personaje)

	if enZona and not dentroDeZona then
		-- Entró a la zona
		dentroDeZona = true
		print("[ZonaEspacioSkybox] Entrando al espacio...")
		aplicarCieloEspacial()

	elseif not enZona and dentroDeZona then
		-- Salió de la zona
		dentroDeZona = false
		print("[ZonaEspacioSkybox] Saliendo del espacio...")
		restaurarCieloOriginal()
	end

	task.wait(0.1)  -- Verificar cada 0.1 segundos
end
