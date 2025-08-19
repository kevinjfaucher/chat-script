------------------------------------------------------------
--  Split-bar Health UI  •  bottom-right placement         --
------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- how far in from the bottom-right corner, in pixels
local PAD_X =  30   -- distance from right edge  (positive → inward)
local PAD_Y = 120   -- distance from bottom edge (positive → upward)

----------------------------------------------------------------
-- Find the green and red frames, then move their container    --
----------------------------------------------------------------
local function getBars()
	local pg = player:WaitForChild("PlayerGui")
	task.wait(0.5)

	local hotbar = pg:FindFirstChild("HotbarGui")
	if not hotbar then return nil end

	local stats = hotbar:FindFirstChild("PlayerStats")
	if not stats then return nil end

	----------------------------------------------------------------
	-- Move PlayerStats to bottom-right and lift it PAD_Y pixels  --
	----------------------------------------------------------------
	stats.AnchorPoint = Vector2.new(1, 1)                          -- anchor = bottom-right
	stats.Position    = UDim2.new(1, -PAD_X, 1, -PAD_Y)            -- X,Y offsets inward/upward

	-- Grab the two bar frames
	local green = stats:FindFirstChild("CurrentHealthBar")
	local red   = stats:FindFirstChild("MissingHealthBar")
	return green, red
end

----------------------------------------------------------------
-- Attach bar logic to each character respawn                 --
----------------------------------------------------------------
local function onCharacter(char)
	local hum        = char:WaitForChild("Humanoid")
	local green, red = getBars()
	if not (green and red) then return end

	-- cache original bar width
	local wx, wo = green.Size.X.Scale, green.Size.X.Offset

	-- set anchors so they grow opposite ways
	green.AnchorPoint = Vector2.new(0,1)  -- bottom-left
	green.Position    = UDim2.new(wx, 0, 1, 0)

	red.AnchorPoint   = Vector2.new(0,0)  -- top-left
	red.Position      = UDim2.new(wx, 0, 0, 0)

	local function sync()
		local max = math.max(1, hum.MaxHealth)
		local hp  = math.clamp(hum.Health, 0, max)
		local pct = hp / max
		if max - hp <= 0.001 * max then pct = 1 end  -- close rounding gap

		green.Size = UDim2.new(wx, wo, pct,     0)
		red.Size   = UDim2.new(wx, wo, 1 - pct, 0)
	end

	sync()
	hum.HealthChanged:Connect(sync)
	hum:GetPropertyChangedSignal("MaxHealth"):Connect(sync)
	RunService.RenderStepped:Connect(sync)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end
