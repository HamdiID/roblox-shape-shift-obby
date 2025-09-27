local RS = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local PlayerGui = player.PlayerGui

local PairEvents = RS:WaitForChild("PairEvents")
local leaveEvent = PairEvents:WaitForChild("LeaveEvent")
local timerEvent = PairEvents:WaitForChild("TimerEvent")
local gui = RS:WaitForChild("WaitingGui")
local enableGuiEvent = PairEvents:WaitForChild("EnableGuiEvent")
local teleportEvent = PairEvents:WaitForChild("TeleportToLevelEvent")

enableGuiEvent.OnClientEvent:Connect(function()
	local clone = gui:Clone()
	clone.Parent = PlayerGui
	clone.Enabled = true
	local textLabel = clone:WaitForChild("Frame"):WaitForChild("TextLabel")

	clone:WaitForChild("Frame"):WaitForChild("ImageButton").MouseButton1Click:Connect(function()
		leaveEvent:FireServer()
		clone:Destroy()
	end)

	local function timer()
		local timernbr = 3

		for i = timernbr, 0, -1 do
			textLabel.Text = i
			task.wait(1)
			if i == 0 then
				teleportEvent:FireServer()
				clone:Destroy()
			end
		end
	end

	timerEvent.OnClientEvent:Connect(function()
		timer()
	end)
end)
