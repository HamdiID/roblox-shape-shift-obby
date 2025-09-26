game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Wait() -- Attendre que le personnage soit complètement ajouté
	local char = player.Character

	-- Modifier la densité de toutes les pièces du personnage
	for _, part in pairs(char:GetChildren()) do
		if part:IsA("BasePart") then
			-- Définir des propriétés physiques personnalisées
			part.CustomPhysicalProperties = PhysicalProperties.new(20, 0.3, 0.1) -- Exemple de propriétés : (Densité, Friction, Elasticité)
			print("La densité a changé pour " .. part.Name)
		end
	end
end)
