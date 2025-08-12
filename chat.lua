local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local SendChatMessage = ReplicatedStorage:WaitForChild("SendChatMessage")
local ReceiveChatMessage = ReplicatedStorage:WaitForChild("ReceiveChatMessage")
local MAX_LEN = 200

local function onSend(sender, raw)
	if typeof(raw) ~= "string" then return end
	raw = raw:sub(1, MAX_LEN)

	-- Step 1: Filter string
	local success, filterResult = pcall(function()
		return TextService:FilterStringAsync(raw, sender.UserId, Enum.TextFilterContext.PublicChat)
	end)

	if not success then
		warn("[ChatFilter] FilterStringAsync failed for", sender.Name, filterResult)
		return
	end

	-- Step 2: Show filtered version per player
	for _, recipient in ipairs(Players:GetPlayers()) do
		local ok, filteredText = pcall(function()
			return filterResult:GetNonChatStringForUserAsync(recipient.UserId)
		end)

		if ok and filteredText and filteredText ~= "" then
			ReceiveChatMessage:FireClient(recipient, sender.Name, filteredText)
		else
			warn(("[ChatFilter] %s -> %s blocked/failed: %s")
				:format(sender.Name, recipient.Name, tostring(filteredText)))
		end
	end
end

SendChatMessage.OnServerEvent:Connect(onSend)
