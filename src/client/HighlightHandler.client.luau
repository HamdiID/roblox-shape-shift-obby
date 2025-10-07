local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HightlightEvent = ReplicatedStorage:WaitForChild("PairEvents"):WaitForChild("PairHighlightEvent")
local player = game.Players.LocalPlayer
local function setHighlight(otherPlayerName, color)
	local character = player.Character
	local otherPlayer = game.Players:FindFirstChild(otherPlayerName)
	local otherCharacter = otherPlayer and otherPlayer.Character

	local highlightBlue = ReplicatedStorage:WaitForChild("Blue"):Clone()
	local highlightRed = ReplicatedStorage:WaitForChild("Red"):Clone()

	if not character then
		return
	end
	if color == "Blue" then
		highlightBlue.Parent = character
		highlightBlue.Adornee = character

		highlightRed.Parent = otherCharacter
		highlightRed.Adornee = otherCharacter
	elseif color == "Red" then
		highlightRed.Parent = character
		highlightRed.Adornee = character

		highlightBlue.Parent = otherCharacter
		highlightBlue.Adornee = otherCharacter
	end
end
HightlightEvent.OnClientEvent:Connect(function(otherPlayerName, color)
	setHighlight(otherPlayerName, color)
end)
