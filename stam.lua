-- LocalScript (e.g., StarterPlayerScripts)
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

-- Animation (optional)
local Anim = Instance.new("Animation")
Anim.AnimationId = "rbxassetid://110594574820304"
local PlayAnim = humanoid:LoadAnimation(Anim)

-- Cache for the stamina bar
local cachedBar = nil

-- === UI Helpers === --
local function findCurrentStaminaBar()
	if cachedBar and cachedBar.Parent then
		return cachedBar
	end

	local playerGui = player:WaitForChild("PlayerGui")

	-- give StarterGui a moment to replicate on spawn
	task.wait(1)

	local hotbarGui = playerGui:FindFirstChild("HotbarGui")
	if not hotbarGui then
		hotbarGui = playerGui:WaitForChild("HotbarGui", 5)
	end
	if not hotbarGui then return nil end

	local playerStats = hotbarGui:FindFirstChild("PlayerStats")
	if not playerStats then
		playerStats = hotbarGui:WaitForChild("PlayerStats", 5)
	end
	if not playerStats then return nil end

	local currentStaminaBar = playerStats:FindFirstChild("CurrentStaminaBar")
	if not currentStaminaBar then
		currentStaminaBar = playerStats:WaitForChild("CurrentStaminaBar", 5)
	end

	cachedBar = currentStaminaBar
	return cachedBar
end

-- Ensure the bar drains TOP -> DOWN (anchor the top once, then only resize height)
local function anchorBarToTopOnce(bar)
	if not bar or bar:GetAttribute("TopAnchored") then return end

	local parent = bar.Parent
	if not parent then return end

	-- Preserve current top edge in pixels relative to parent
	local topY = bar.AbsolutePosition.Y - parent.AbsolutePosition.Y

	-- Flip to top anchoring
	bar.AnchorPoint = Vector2.new(bar.AnchorPoint.X, 0)
	-- Lock Y to the preserved top edge; keep X the same
	bar.Position = UDim2.new(bar.Position.X.Scale, bar.Position.X.Offset, 0, topY)

	bar:SetAttribute("TopAnchored", true)
end

local function updateStaminaUI()
	local bar = findCurrentStaminaBar()
	if not bar then return end

	anchorBarToTopOnce(bar)

	local staminaPercentage = math.clamp(currentStamina / maxStamina, 0, 1)
	bar.Size = UDim2.new(
		bar.Size.X.Scale,
		bar.Size.X.Offset,
		staminaPercentage,
		0
	)
end

-- === Camera FOV Tween === --
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
	-- Reattach to character if it respawns
	if not character or not character.Parent then
		character = player.Character or player.CharacterAdded:Wait()
		humanoid = character:WaitForChild("Humanoid")
		PlayAnim = humanoid:LoadAnimation(Anim)
		return
	end

	-- Drain while sprinting
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

	-- Regen after delay
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

	updateStaminaUI()
end)
