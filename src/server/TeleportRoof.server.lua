--[[
    TeleportRoof.server.lua
    Sistema de teleportación por proximidad para el techo del juego

    Detecta cuando un jugador entra en el área de un "BloqueoTecho" y lo teleporta al "TP" correspondiente
    - BloqueoTecho → TP1
    - BloqueoTecho1 → TP2
    - BloqueoTecho2 → TP3
    - etc.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local workspace = game:GetService("Workspace")

-- Cooldown para evitar spam de teleports (2 segundos por jugador por zona)
local TELEPORT_COOLDOWN = 2
local playerCooldowns = {} -- {[player] = {[zoneName] = timestamp}}

-- Tabla para mapear parts de bloqueo a sus destinos de teleport
local teleportPairs = {}

--[[
    Extrae el número del nombre de un part
    "BloqueoTecho" → 1
    "BloqueoTecho1" → 2
    "BloqueoTecho2" → 3
]]
local function getTPNumber(bloqueoName)
    if bloqueoName == "BloqueoTecho" then
        return 1
    end

    local number = bloqueoName:match("BloqueoTecho(%d+)")
    if number then
        return tonumber(number) + 1
    end

    return nil
end

--[[
    Busca el part de destino correspondiente en el workspace
]]
local function findTPDestination(tpNumber)
    local tpName = "TP" .. tostring(tpNumber)

    -- Primero intentar en workspace.Teleports
    local teleportsFolder = workspace:FindFirstChild("Teleports")
    if teleportsFolder then
        local tpPart = teleportsFolder:FindFirstChild(tpName)
        if tpPart then
            return tpPart
        end
    end

    -- Si no se encontró, buscar en todo el workspace
    return workspace:FindFirstChild(tpName, true)
end

--[[
    Verifica si un jugador está dentro de un part usando GetPartBoundsInBox
    Este método funciona con parts rotados Y con CanCollide = false
]]
local function isPlayerInPart(character, part)
    if not character or not part then return false end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end

    -- Verificar primero si está cerca (optimización)
    local distance = (humanoidRootPart.Position - part.Position).Magnitude
    local maxDistance = (part.Size.Magnitude / 2) + 10 -- Radio máximo + margen

    if distance > maxDistance then
        return false
    end

    -- Usar GetPartBoundsInBox para detección precisa (funciona con parts rotados)
    local overlapParams = OverlapParams.new()
    overlapParams.FilterType = Enum.RaycastFilterType.Whitelist
    overlapParams.FilterDescendantsInstances = {character}

    local partsInRegion = workspace:GetPartBoundsInBox(part.CFrame, part.Size, overlapParams)

    -- Si encontramos alguna parte del personaje, está dentro
    return #partsInRegion > 0
end

--[[
    Teleporta un jugador a una posición específica
]]
local function teleportPlayer(player, destinationPart, zoneName)
    local character = player.Character
    if not character then return false end

    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return false end

    -- Verificar cooldown para esta zona específica
    local now = os.clock()
    if not playerCooldowns[player] then
        playerCooldowns[player] = {}
    end

    if playerCooldowns[player][zoneName] and (now - playerCooldowns[player][zoneName]) < TELEPORT_COOLDOWN then
        return false
    end

    -- Teleportar
    humanoidRootPart.CFrame = destinationPart.CFrame + Vector3.new(0, 3, 0)

    -- Actualizar cooldown
    playerCooldowns[player][zoneName] = now

    return true
end

--[[
    Registra un par de bloqueo-destino para detección continua
]]
local function setupBloqueoTecho(bloqueoTechoPart, tpNumber)
    -- Hacer el part no colisionable para que no bloquee físicamente
    bloqueoTechoPart.CanCollide = false

    -- Agregar a la tabla de pares
    table.insert(teleportPairs, {
        bloqueo = bloqueoTechoPart,
        tpNumber = tpNumber,
        nombre = bloqueoTechoPart.Name
    })
end

--[[
    Inicializa el sistema de teleportación
    Busca todos los BloqueoTecho y los empareja con sus TPs
]]
local function initializeTeleportSystem()
    local setupCount = 0

    -- Buscar todos los parts que empiecen con "BloqueoTecho"
    local function searchForBloqueoTecho(parent)
        for _, child in ipairs(parent:GetChildren()) do
            -- Verificar si es un BloqueoTecho
            if child:IsA("BasePart") and child.Name:match("^BloqueoTecho") then
                -- Obtener el número de TP correspondiente
                local tpNumber = getTPNumber(child.Name)
                if tpNumber then
                    -- Verificar que el TP existe
                    local tpDestination = findTPDestination(tpNumber)
                    if tpDestination and tpDestination:IsA("BasePart") then
                        -- Configurar el teleport
                        setupBloqueoTecho(child, tpNumber)
                        setupCount = setupCount + 1
                    else
                        warn("[TeleportRoof] No se encontró TP" .. tpNumber .. " para " .. child.Name)
                    end
                end
            end

            -- Búsqueda recursiva
            searchForBloqueoTecho(child)
        end
    end

    -- Comenzar búsqueda desde workspace
    searchForBloqueoTecho(workspace)

    print("[TeleportRoof] Sistema inicializado con " .. setupCount .. " zona(s) de teleportación")
end

--[[
    Limpieza cuando un jugador sale del juego
]]
Players.PlayerRemoving:Connect(function(player)
    playerCooldowns[player] = nil
end)

-- Inicializar el sistema
initializeTeleportSystem()

--[[
    Loop de detección continua
    Verifica cada frame si algún jugador está dentro de un BloqueoTecho
]]
RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character then
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            if humanoidRootPart then
                -- Verificar cada par de bloqueo-destino
                for _, pair in ipairs(teleportPairs) do
                    -- Buscar el TP dinámicamente cada vez
                    local tpDestination = findTPDestination(pair.tpNumber)

                    -- Verificar que tanto el bloqueo como el destino existen
                    if pair.bloqueo and pair.bloqueo.Parent and tpDestination then
                        -- Verificar si el jugador está dentro del BloqueoTecho
                        if isPlayerInPart(character, pair.bloqueo) then
                            -- Teleportar al jugador
                            teleportPlayer(player, tpDestination, pair.nombre)
                        end
                    end
                end
            end
        end
    end
end)
