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
	task.wait(1) -- give StarterGui time to replicate

	local hotbarGui = playerGui:FindFirstChild("HotbarGui") or playerGui:WaitForChild("HotbarGui", 5)
	if not hotbarGui then return nil end

	local playerStats = hotbarGui:FindFirstChild("PlayerStats") or hotbarGui:WaitForChild("PlayerStats", 5)
	if not playerStats then return nil end

	local currentStaminaBar = playerStats:FindFirstChild("CurrentStaminaBar") or playerStats:WaitForChild("CurrentStaminaBar", 5)
	cachedBar = currentStaminaBar
	return cachedBar
end

-- Ensure the bar drains TOP -> DOWN by anchoring its bottom once
local function anchorBarToBottomOnce(bar)
	if not bar or bar:GetAttribute("BottomAnchored") then return end
	local parent = bar.Parent
	if not parent then return end

	-- Compute current bottom (as a scale) so we preserve on-screen placement
	local parentTop = parent.AbsolutePosition.Y
	local barTop = bar.AbsolutePosition.Y
	local barBottomAbs = (barTop - parentTop) + bar.AbsoluteSize.Y
	local parentH = math.max(parent.AbsoluteSize.Y, 1)
	local bottomScale = barBottomAbs / parentH

	-- Flip to bottom anchoring and keep the same bottom position
	bar.AnchorPoint = Vector2.new(bar.AnchorPoint.X, 1)
	bar.Position = UDim2.new(bar.Position.X.Scale, bar.Position.X.Offset, bottomScale, 0)

	bar:SetAttribute("BottomAnchored", true)
end

local function updateStaminaUI()
	local bar = findCurrentStaminaBar()
	if not bar then return end

	-- Make sure the bar is bottom-anchored so it empties from the TOP downward
	anchorBarToBottomOnce(bar)

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
