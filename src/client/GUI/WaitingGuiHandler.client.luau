local RS = game:GetService("ReplicatedStorage")
local player = game.Players.LocalPlayer
local PlayerGui = player.PlayerGui

local PairEvents = RS:WaitForChild("PairEvents")
local leaveEvent = PairEvents:WaitForChild("LeaveEvent")
local timerEvent = PairEvents:WaitForChild("TimerEvent")
local gui = RS:WaitForChild("WaitingGui")
local enableGuiEvent = PairEvents:WaitForChild("EnableGuiEvent")
local teleportEvent = PairEvents:WaitForChild("TeleportToLevelEvent")
local pairEvent = PairEvents:WaitForChild("PairEvent")

enableGuiEvent.OnClientEvent:Connect(function()
	local clone = gui:Clone()
	clone.Parent = PlayerGui
	clone.Enabled = true
	local textLabel = clone:WaitForChild("Frame"):WaitForChild("TextLabel")

	clone:WaitForChild("Frame"):WaitForChild("ImageButton").MouseButton1Click:Connect(function()
		leaveEvent:FireServer()
		clone:Destroy()
	end)

	local function timer(machineModel)
		local timernbr = 3

		for i = timernbr, 0, -1 do
			textLabel.Text = i
			task.wait(1)
			if i == 0 then
				-- Envoyer l'événement de pair avant le téléport pour que le serveur
				-- puisse établir l'appariement avant de potentiellement nettoyer l'état
				pairEvent:FireServer()
				task.wait(0.5)
				teleportEvent:FireServer()
				clone:Destroy()
			end
		end
	end

	timerEvent.OnClientEvent:Connect(function(machineModel)
		timer(machineModel)
	end)
end)
