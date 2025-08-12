local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

-- === Config === --
local maxStamina = 100
local staminaDrainRate = 20 -- per second
local staminaRegenRate = 15 -- per second
local regenDelay = 1.5 -- seconds before regen starts
local walkSpeed = 13
local sprintSpeed = 26
local normalFOV = 70
local sprintFOV = 85
local tweenTime = 0.5

-- === Variables === --
local currentStamina = maxStamina
local sprinting = false
local regenCooldown = 0
local fovTween = nil
local Anim = Instance.new('Animation')
Anim.AnimationId = 'rbxassetid://110594574820304'
local PlayAnim = character.Humanoid:LoadAnimation(Anim)

-- === Find Existing UI Elements === --
local function findCurrentStaminaBar()
	local playerGui = player:WaitForChild("PlayerGui")
	
	-- Wait a moment for GUIs to load from StarterGui
	wait(1)
	
	-- Look for HotbarGui specifically
	local hotbarGui = playerGui:WaitForChild("HotbarGui", 10)
	if hotbarGui then
		local playerStats = hotbarGui:WaitForChild("PlayerStats", 5)
		if playerStats then
			local currentStaminaBar = playerStats:WaitForChild("CurrentStaminaBar", 5)
			if currentStaminaBar then
				return currentStaminaBar
			end
		end
	end
	
	return nil
end

-- === Functions === --
local function updateStaminaUI()
	local currentStaminaBar = findCurrentStaminaBar()
	
	if currentStaminaBar then
		-- Update the bar height based on current stamina (vertical bar)
		local staminaPercentage = currentStamina / maxStamina
		currentStaminaBar.Size = UDim2.new(currentStaminaBar.Size.X.Scale, currentStaminaBar.Size.X.Offset, staminaPercentage, 0)
	end
end

local function tweenFOV(toFOV)
	if fovTween then
		fovTween:Cancel()
	end
	local goal = { FieldOfView = toFOV }
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	fovTween = TweenService:Create(camera, tweenInfo, goal)
	fovTween:Play()
end

-- === Input === --
UserInputService.InputBegan:Connect(function(input, processed)
	if input.KeyCode == Enum.KeyCode.LeftShift and not processed then
		if currentStamina > 0 then
			sprinting = true
			PlayAnim:Play()
			tweenFOV(sprintFOV)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input, _)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		sprinting = false
		PlayAnim:Stop()
		regenCooldown = regenDelay
		tweenFOV(normalFOV)
	end
end)

-- === Main Loop === --
RunService.RenderStepped:Connect(function(deltaTime)
	if not character or not character.Parent then
		character = player.Character or player.CharacterAdded:Wait()
		humanoid = character:WaitForChild("Humanoid")
		return
	end

	if sprinting and currentStamina > 0 then
		currentStamina -= staminaDrainRate * deltaTime
		humanoid.WalkSpeed = sprintSpeed
		regenCooldown = regenDelay

		if currentStamina <= 0 then
			currentStamina = 0
			PlayAnim:Stop()
			sprinting = false
			tweenFOV(normalFOV)
		end
	else
		humanoid.WalkSpeed = walkSpeed
	end

	if regenCooldown > 0 then
		regenCooldown -= deltaTime
	else
		if currentStamina < maxStamina then
			currentStamina += staminaRegenRate * deltaTime
			if currentStamina > maxStamina then
				currentStamina = maxStamina
			end
		end
	end

	-- Update the existing CurrentStaminaBar
	updateStaminaUI()
end)
