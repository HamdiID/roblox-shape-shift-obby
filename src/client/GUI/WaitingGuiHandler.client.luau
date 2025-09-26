local RS = game:GetService("ReplicatedStorage")
local leaveEvent = RS:WaitForChild("PairEvents"):WaitForChild("LeaveEvent")
local timerEvent = RS:WaitForChild("PairEvents"):WaitForChild("TimerEvent")
local player = game.Players.LocalPlayer
local PlayerGui = player.PlayerGui
local gui = RS:WaitForChild("WaitingGui")
local enableGuiEvent = RS:WaitForChild("PairEvents"):WaitForChild("EnableGuiEvent")

enableGuiEvent.OnClientEvent:Connect(function()
	local clone = gui:Clone()
	clone.Parent = PlayerGui
	clone.Enabled = true
	local textLabel = clone:WaitForChild("Frame"):WaitForChild("TextLabel")

	clone:WaitForChild("Frame"):WaitForChild("ImageButton").MouseButton1Click:Connect(function()
		leaveEvent:FireServer()
		clone:Destroy()
	end)

	function timer()
		local timernbr = 3

		for i = timernbr, 0, -1 do
			textLabel.Text = i
			task.wait(1)
			if i == 0 then
				gui:Destroy()
			end
		end
	end

	timerEvent.OnClientEvent:Connect(function()
		timer()
	end)
end)
