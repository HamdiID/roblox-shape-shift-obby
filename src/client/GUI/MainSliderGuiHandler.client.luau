local Mouse = game.Players.LocalPlayer:GetMouse()
local PlayerGui = game.Players.LocalPlayer.PlayerGui
local gui = PlayerGui:WaitForChild("MainSliderGui")
local Slider = gui:WaitForChild("CanvasGroup")
local Fill = Slider.Fill
local Trigger = Slider.Trigger
local OutputValue = Slider.OutputValue
local OutputLabel = Slider.Parent.Slider.Label

local rs = game:GetService("ReplicatedStorage")
local event = rs:WaitForChild("SliderEvents").SizeChange

Fill.Size = UDim2.fromScale(1, OutputValue.Value)
OutputLabel.Text = ("X " .. tostring(math.round(OutputValue.Value * 100) / 100) * 2)

function UpdateSlider()
	-- Calculer la position du curseur par rapport au Slider uniquement sur l'axe Y
	local relativeY = (Mouse.Y - Slider.AbsolutePosition.Y) / Slider.AbsoluteSize.Y

	-- Limiter la valeur entre 0 et 1
	relativeY = math.clamp(relativeY, 0, 1)

	-- Inverser la valeur (1 = haut, 0 = bas)
	relativeY = 1 - relativeY

	-- Appliquer la limite minimale à 0.5
	relativeY = math.max(relativeY, 0.1)

	OutputLabel.Text = ("X " .. tostring(math.round(relativeY * 100) / 100) * 2)
	OutputValue.Value = relativeY

	Fill.Size = UDim2.fromScale(1, relativeY)

	event:FireServer(relativeY)
end

local sliderActive = false

function ActivateSlider()
	sliderActive = true
	while sliderActive do
		UpdateSlider()
		task.wait()
	end
end

Trigger.MouseButton1Down:Connect(ActivateSlider)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		sliderActive = false
	end
end)
