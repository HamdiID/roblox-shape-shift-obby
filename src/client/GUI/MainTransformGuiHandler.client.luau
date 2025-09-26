local rs = game:GetService("ReplicatedStorage")

-- Références générales
local sound = rs.ShapeShiftEvents.Effects:WaitForChild("Magic Poofs Short Breathy Bursts Wheezy Exha (SFX)")
local PlayerGui = game.Players.LocalPlayer.PlayerGui
local gui = PlayerGui:WaitForChild("MainTransfromGui")
local frame = gui:WaitForChild("Frame")

local UserInputService = game:GetService("UserInputService")

-- Dictionnaire des événements associés aux types
local events = {
	Ball = rs:WaitForChild("ShapeShiftEvents"):WaitForChild("BallEvents"):WaitForChild("Transform"),
	Human = rs:WaitForChild("ShapeShiftEvents"):WaitForChild("HumanEvents"):WaitForChild("Transform"),
	Square = rs:WaitForChild("ShapeShiftEvents"):WaitForChild("SquareEvents"):WaitForChild("Transform"),
	Wedge = rs:WaitForChild("ShapeShiftEvents"):WaitForChild("WedgeEvents"):WaitForChild("Transform"),
}

-- Mapping des touches aux types d'événements
local keyToEventType = {
	[Enum.KeyCode.One] = "Ball",
	[Enum.KeyCode.Two] = "Square",
	[Enum.KeyCode.Three] = "Wedge",
	[Enum.KeyCode.Four] = "Human",
}

-- Parcourir tous les boutons enfants
for _, button in ipairs(frame:GetChildren()) do
	-- Vérifier que l'objet est un bouton TextButton/ImageButton
	if button:IsA("ImageButton") then
		-- Vérifier le type d'événement via l'attribut "EventType"
		local buttonType = button:GetAttribute("EventType")

		if buttonType and events[buttonType] then
			local event = events[buttonType]

			-- Connecter le clic du bouton à l'événement
			button.MouseButton1Click:Connect(function()
				event:FireServer() -- Déclencher l'événement
				sound:Play() -- Jouer le son
			end)
		else
			warn(button.Name .. " n'a pas de type d'événement valide ! Vérifie l'attribut 'EventType'.")
		end
	end
end

UserInputService.InputBegan:Connect(function(inputObject, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end -- Ignorer les entrées déjà utilisées par le jeu

	local eventType = keyToEventType[inputObject.KeyCode] -- Trouver le type d'événement via la touche
	if eventType and events[eventType] then
		local event = events[eventType]

		event:FireServer() -- Déclencher l'événement
		sound:Play() -- Jouer le son
		print("Événement déclenché :", eventType)
	end
end)
