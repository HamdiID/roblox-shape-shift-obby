local controls = require(game:GetService("Players").LocalPlayer.PlayerScripts.PlayerModule):GetControls()
local RS = game:GetService("ReplicatedStorage")

local disableControlsEvent = RS:WaitForChild("PairEvents"):WaitForChild("DisableControlsEvent")
local enableControlsEvent = RS:WaitForChild("PairEvents"):WaitForChild("EnableControlsEvent")

disableControlsEvent.OnClientEvent:Connect(function()
	controls:Disable()
end)

enableControlsEvent.OnClientEvent:Connect(function()
	controls:Enable()
end)
