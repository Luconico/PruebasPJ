--[[
	PetLocalHandler.client.lua
	Lógica de seguimiento de mascotas
	Adaptado de UXR PetLocalHander.client.lua
]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local ServerPets = Workspace:WaitForChild("ServerPets")

local SPACING = Config.PetSystem.Spacing
local MAX_CLIMB_HEIGHT = Config.PetSystem.MaxClimbHeight
local WALK_SPEED = Config.PetSystem.WalkAnimationSpeed
local IDLE_SPEED = Config.PetSystem.IdleAnimationSpeed
local WALK_AMP = Config.PetSystem.WalkAmplitude
local IDLE_AMP = Config.PetSystem.IdleAmplitude
local FLY_OFFSET = Config.PetSystem.FlyingHeightOffset

local rayParams = RaycastParams.new()
local rayDirection = Vector3.new(0, -500, 0)

local function rearrangeTables(pets, rows, maxRowCapacity)
	table.clear(rows)
	local amountOfRows = math.ceil(#pets / maxRowCapacity)

	for i = 1, amountOfRows do
		table.insert(rows, {})
	end

	for i, pet in ipairs(pets) do
		local row = rows[math.ceil(i / maxRowCapacity)]
		table.insert(row, pet)
	end
end

local function getRowWidth(row, pet)
	if not pet or not pet.PrimaryPart then return 0 end
	if #row == 1 then return 0 end

	local spacing = SPACING - pet.PrimaryPart.Size.X
	local rowWidth = 0

	for i, v in ipairs(row) do
		if i ~= #row then
			rowWidth = rowWidth + pet.PrimaryPart.Size.X + spacing
		else
			rowWidth = rowWidth + pet.PrimaryPart.Size.X
		end
	end

	return rowWidth
end

local function movePets(hrp, pet, x, y, z, xOffset, hum)
	if not pet.PrimaryPart then return end

	local targetCFrame = CFrame.new(hrp.CFrame.X, 0, hrp.CFrame.Z)
		* hrp.CFrame.Rotation
		* CFrame.new(x - xOffset, y, z)

	-- Animación de caminar
	if hum.MoveDirection.Magnitude > 0 then
		local timeDelay = pet:FindFirstChild("TimeDelay") and pet.TimeDelay.Value or 0
		local isFlying = pet:FindFirstChild("Flying") and pet.Flying.Value or false

		if isFlying then
			local wave = math.sin((time() + timeDelay) * WALK_SPEED) * 0.1
			local cos = math.cos((time() + timeDelay) * WALK_SPEED) * 0.1
			targetCFrame = targetCFrame * CFrame.new(0, -wave, 0) * CFrame.Angles(cos, 0, 0)
		else
			local wave = math.sin((time() + timeDelay) * WALK_SPEED) * WALK_AMP
			local cos = math.cos((time() + timeDelay) * WALK_SPEED) * WALK_AMP
			targetCFrame = targetCFrame * CFrame.new(0, -wave, 0) * CFrame.Angles(cos, 0, 0)
		end
	end

	-- Animación idle
	local timeDelay = pet:FindFirstChild("TimeDelay") and pet.TimeDelay.Value or 0
	local idleWave = math.sin((time() + timeDelay) * IDLE_SPEED) * IDLE_AMP
	targetCFrame = targetCFrame * CFrame.new(0, idleWave, 0)

	-- Suavizar con Lerp
	pet.PrimaryPart.CFrame = pet.PrimaryPart.CFrame:Lerp(targetCFrame, 0.1)
end

RunService.Heartbeat:Connect(function()
	if not character or not character.Parent then
		character = player.Character
		if character then
			humanoidRootPart = character:WaitForChild("HumanoidRootPart")
			humanoid = character:WaitForChild("Humanoid")
		else
			return
		end
	end

	local playerPetFolder = ServerPets:FindFirstChild(player.Name)
	if not playerPetFolder then return end

	local pets = {}
	local rows = {}

	for _, pet in ipairs(playerPetFolder:GetChildren()) do
		if pet:IsA("Model") and pet.PrimaryPart then
			table.insert(pets, pet)
		end
	end

	if #pets == 0 then return end

	rayParams.FilterDescendantsInstances = {ServerPets, character}

	local maxRowCapacity = math.ceil(math.sqrt(#pets))
	rearrangeTables(pets, rows, maxRowCapacity)

	for i, pet in ipairs(pets) do
		local rowIndex = math.ceil(i / maxRowCapacity)
		local row = rows[rowIndex]
		local rowWidth = getRowWidth(row, pet)

		local xOffset = #row == 1 and 0 or rowWidth / 2 - pet.PrimaryPart.Size.X / 2

		local x = (table.find(row, pet) - 1) * SPACING
		local z = rowIndex * SPACING
		local y = 0

		local rayResult = Workspace:Blockcast(
			pet.PrimaryPart.CFrame + Vector3.new(0, MAX_CLIMB_HEIGHT, 0),
			pet.PrimaryPart.Size,
			rayDirection,
			rayParams
		)

		if rayResult then
			local isFlying = pet:FindFirstChild("Flying") and pet.Flying.Value or false
			y = rayResult.Position.Y + pet.PrimaryPart.Size.Y / 2
			if isFlying then
				y = y + FLY_OFFSET
			end
		end

		movePets(humanoidRootPart, pet, x, y, z, xOffset, humanoid)
	end
end)

print("[PetLocalHandler] Inicializado")
