------------------------------------------------------------
--  Health Bar (resizes both green + red fill frames)     --
------------------------------------------------------------
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local player     = Players.LocalPlayer

------------------------------------------------------------
-- Locate every vertical bar (green + red) on each spawn  --
------------------------------------------------------------
local function getBars()
	local pg = player:WaitForChild("PlayerGui")
	task.wait(0.5)  -- let the GUI build

	local hotbar = pg:FindFirstChild("HotbarGui")
	if not hotbar then return {} end

	local stats = hotbar:FindFirstChild("PlayerStats")
	if not stats then return {} end

	-- We know CurrentHealthBar exists; gather *all* siblings that are Frames
	local bars = {}
	for _,child in ipairs(stats:GetChildren()) do
		if child:IsA("Frame") and child.Name:lower():find("healthbar") then
			table.insert(bars, child)
		end
	end
	return bars
end

------------------------------------------------------------
-- Wire character once per respawn                        --
------------------------------------------------------------
local function onCharacter(char)
	local hum  = char:WaitForChild("Humanoid")
	local bars = getBars()
	if #bars == 0 then return end

	-- cache each bar’s original X-size so we don’t stretch them
	local widths = {}
	for i,bar in ipairs(bars) do
		widths[i] = { bar.Size.X.Scale, bar.Size.X.Offset }
	end

	-- Re-scale every bar the same amount
	local function update()
		local max = math.max(1, hum.MaxHealth)
		local hp  = math.clamp(hum.Health, 0, max)
		local pct = (max - hp <= 0.001 * max) and 1 or (hp / max)

		for i,bar in ipairs(bars) do
			local xScale, xOffset = table.unpack(widths[i])
			bar.Size = UDim2.new(xScale, xOffset, pct, 0)
		end
	end

	update()  -- initial fill

	hum.HealthChanged:Connect(update)
	hum:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	RunService.RenderStepped:Connect(update)
end

player.CharacterAdded:Connect(onCharacter)
if player.Character then onCharacter(player.Character) end
