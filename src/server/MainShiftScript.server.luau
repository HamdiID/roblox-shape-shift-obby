local rs = game:GetService("ReplicatedStorage")

local ShapeShiftEvents = rs:WaitForChild("ShapeShiftEvents")

local BallEvents = ShapeShiftEvents:WaitForChild("BallEvents")
local TransformBallEvent = BallEvents:WaitForChild("Transform")
local BallCameraEvent = BallEvents:WaitForChild("Camera")

local SquareEvents = ShapeShiftEvents:WaitForChild("SquareEvents")
local TransformSquareEvent = SquareEvents:WaitForChild("Transform")
local SquareCameraEvent = BallEvents:WaitForChild("Camera")

local WedgeEvents = ShapeShiftEvents:WaitForChild("WedgeEvents")
local TransformWedgeEvent = WedgeEvents:WaitForChild("Transform")
local WedgeCameraEvent = BallEvents:WaitForChild("Camera")

local HumanEvents = ShapeShiftEvents:WaitForChild("HumanEvents")
local TransformHumanEvent = HumanEvents:WaitForChild("Transform")
local HumanCameraEvent = HumanEvents:WaitForChild("Camera")

local eventSize = rs:WaitForChild("SliderEvents").SizeChange

local playerSizeMultipliers = {}

-- Taille de base des formes
local baseSizes = {
	Ball = Vector3.new(8, 8, 8),
	Square = Vector3.new(7, 7, 7),
	Wedge = Vector3.new(7, 7, 7),
}

eventSize.OnServerEvent:Connect(function(player, size)
	-- Calculer et stocker le multiplicateur pour ce joueur
	local sizeMultiplier = ((size * 100) / 100) * 2
	playerSizeMultipliers[player.UserId] = sizeMultiplier
end)

-- Appliquer le multiplicateur à une taille de base
local function applyMultiplier(baseSize, multiplier)
	return baseSize * multiplier
end

local function MakeCharacterInvisibleAndNonCollidable(char)
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 1
			part.CanCollide = false
		end
	end
end

-- Fonction pour le mouvement de la boule
TransformBallEvent.OnServerEvent:Connect(function(player)
	local char = player.Character or player.CharacterAdded:Wait()

	if char:FindFirstChild("Marble") then
		return
	elseif char:FindFirstChild("Square") then
		char.Square:Destroy()
	elseif char:FindFirstChild("Wedge") then
		char.Wedge:Destroy()
	end

	local HRP = char:FindFirstChild("HumanoidRootPart")
	if not HRP then
		warn("HumanoidRootPart introuvable pour " .. player.Name)
		return
	end

	-- Réinitialise l'orientation
	HRP.CFrame = CFrame.new(HRP.Position) * CFrame.Angles(0, math.rad(HRP.Orientation.Y), 0)

	MakeCharacterInvisibleAndNonCollidable(char)

	local marble = Instance.new("Part")
	local baseSize = baseSizes.Ball
	local multiplier = playerSizeMultipliers[player.UserId] or 1
	marble.Size = applyMultiplier(baseSize, multiplier)
	marble.Color = Color3.new(0.529412, 0.529412, 0.529412)
	marble.Transparency = 0
	marble.Name = "Marble"
	marble.Shape = Enum.PartType.Ball
	marble.Material = Enum.Material.Plastic
	marble.BackSurface = "Studs"
	marble.BottomSurface = "Studs"
	marble.FrontSurface = "Studs"
	marble.LeftSurface = "Studs"
	marble.RightSurface = "Studs"
	marble.TopSurface = "Studs"
	marble.Position = HRP.Position
	marble.Parent = char

	BallCameraEvent:FireClient(player)

	local Velocity = Instance.new("BodyAngularVelocity")
	Velocity.Parent = marble

	local Hum = char:FindFirstChild("Humanoid")
	if not Hum then
		warn("Humanoid introuvable pour " .. player.Name)
		return
	end

	Hum.PlatformStand = true

	local Weld = Instance.new("Weld")
	Weld.Part0 = HRP
	Weld.Part1 = marble
	Weld.C0 = CFrame.new() -- Position initiale droite
	Weld.Parent = marble

	local head = char:FindFirstChild("Head")
	if head and head:FindFirstChild("face") then
		head.CanCollide = false
		local face = head:FindFirstChild("face")
		local faceClone = face:Clone()
		faceClone.Parent = marble
		faceClone.Transparency = 0
	else
		warn("Face introuvable pour " .. player.Name)
	end

	while true do
		wait()
		if marble and marble:FindFirstChild("BodyAngularVelocity") then
			local moveDirection = char.Humanoid.MoveDirection
			Velocity.AngularVelocity = Vector3.new(moveDirection.z * 32, 0, moveDirection.x * -32)

			if moveDirection == Vector3.zero then
				Velocity.MaxTorque = Vector3.new(0, 0, 0)
			else
				Velocity.MaxTorque = Vector3.new(40000, 40000, 40000)
			end
		else
			break
		end
	end

	print(player.Name .. " s'est transformé en boule")
end)

-- Fonction pour le mouvement du carré
TransformSquareEvent.OnServerEvent:Connect(function(player)
	local char = player.Character or player.CharacterAdded:Wait()

	if char:FindFirstChild("Marble") then
		char.Marble:Destroy()
	elseif char:FindFirstChild("Square") then
		return
	elseif char:FindFirstChild("Wedge") then
		char.Wedge:Destroy()
	end

	local HRP = char:FindFirstChild("HumanoidRootPart")
	if not HRP then
		warn("HumanoidRootPart introuvable pour " .. player.Name)
		return
	end

	-- Redresser le joueur (garder les pieds au sol)
	local rootPosition = HRP.Position
	local rootOrientationY = HRP.Orientation.Y -- Garder uniquement l'orientation Y (rotation horizontale)
	HRP.CFrame = CFrame.new(rootPosition) * CFrame.Angles(0, math.rad(rootOrientationY), 0)

	-- Obtenir la direction dans laquelle le joueur regarde (après redressement)
	local lookDirection = HRP.CFrame.LookVector

	MakeCharacterInvisibleAndNonCollidable(char)

	-- Création du cube
	local square = Instance.new("Part")
	local baseSize = baseSizes.Square
	local multiplier = playerSizeMultipliers[player.UserId] or 1
	square.Size = applyMultiplier(baseSize, multiplier)
	square.Color = Color3.new(0.529412, 0.529412, 0.529412)
	square.Transparency = 0
	square.Name = "Square"
	square.Shape = Enum.PartType.Block
	square.Material = Enum.Material.Plastic
	square.BackSurface = "Studs"
	square.BottomSurface = "Studs"
	square.FrontSurface = "Studs"
	square.LeftSurface = "Studs"
	square.RightSurface = "Studs"
	square.TopSurface = "Studs"
	square.Anchored = false -- Permettre les déplacements

	SquareCameraEvent:FireClient(player)

	-- Position et orientation du cube
	square.CFrame = CFrame.new(rootPosition, rootPosition + lookDirection)
	square.Parent = char

	local Hum = char:FindFirstChild("Humanoid")
	if not Hum then
		warn("Humanoid introuvable pour " .. player.Name)
		return
	end

	Hum.PlatformStand = false

	-- Lier le cube au personnage
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = HRP
	Weld.Part1 = square
	Weld.Parent = square

	-- Ajouter le visage sur la face avant du cube
	local head = char:FindFirstChild("Head")
	if head and head:FindFirstChild("face") then
		local face = head:FindFirstChild("face"):Clone()
		face.Parent = square
		face.Face = Enum.NormalId.Front -- Associer le visage à la face avant du cube
		face.Transparency = 0
	end
end)

TransformWedgeEvent.OnServerEvent:Connect(function(player)
	local char = player.Character or player.CharacterAdded:Wait()

	if char:FindFirstChild("Marble") then
		char.Marble:Destroy()
	elseif char:FindFirstChild("Square") then
		char.Square:Destroy()
	elseif char:FindFirstChild("Wedge") then
		return
	end

	local HRP = char:FindFirstChild("HumanoidRootPart")
	if not HRP then
		warn("HumanoidRootPart introuvable pour " .. player.Name)
		return
	end

	-- Redresser le joueur (garder les pieds au sol)
	local rootPosition = HRP.Position
	local rootOrientationY = HRP.Orientation.Y -- Garder uniquement l'orientation Y (rotation horizontale)
	HRP.CFrame = CFrame.new(rootPosition) * CFrame.Angles(0, math.rad(rootOrientationY), 0)

	-- Obtenir la direction dans laquelle le joueur regarde (après redressement)
	local lookDirection = HRP.CFrame.LookVector

	MakeCharacterInvisibleAndNonCollidable(char)

	-- Rendre la face du personnage invisible
	local head = char:FindFirstChild("Head")
	if head and head:FindFirstChild("face") then
		local face = head:FindFirstChild("face")
		face.Transparency = 1 -- Rendre invisible
	end

	-- Création du wedge
	local wedge = Instance.new("Part")
	local baseSize = baseSizes.Wedge
	local multiplier = playerSizeMultipliers[player.UserId] or 1
	wedge.Size = applyMultiplier(baseSize, multiplier)
	wedge.Color = Color3.new(0.529412, 0.529412, 0.529412)
	wedge.Transparency = 0
	wedge.Name = "Wedge"
	wedge.Shape = Enum.PartType.Wedge
	wedge.Material = Enum.Material.Plastic
	wedge.BackSurface = "Studs"
	wedge.BottomSurface = "Studs"
	wedge.FrontSurface = "Studs"
	wedge.LeftSurface = "Studs"
	wedge.RightSurface = "Studs"
	wedge.TopSurface = "Studs"
	wedge.Anchored = false -- Permettre les déplacements

	WedgeCameraEvent:FireClient(player)

	-- Position et orientation du wedge
	wedge.CFrame = CFrame.new(rootPosition, rootPosition + lookDirection)
	wedge.Parent = char

	local Hum = char:FindFirstChild("Humanoid")
	if not Hum then
		warn("Humanoid introuvable pour " .. player.Name)
		return
	end

	Hum.PlatformStand = false

	-- Lier le wedge au personnage
	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = HRP
	Weld.Part1 = wedge
	Weld.Parent = wedge

	-- Ajouter le visage sur la face avant du wedge
	if head and head:FindFirstChild("face") then
		local faceClone = head:FindFirstChild("face"):Clone()
		faceClone.Parent = wedge
		faceClone.Face = Enum.NormalId.Front -- Associer le visage à la face avant du wedge
		faceClone.Transparency = 0
	end
end)

TransformHumanEvent.OnServerEvent:Connect(function(player)
	local char = player.Character or player.CharacterAdded:Wait()

	if char:FindFirstChild("Marble") or char:FindFirstChild("Square") or char:FindFirstChild("Wedge") then
		print("Dans transformHuman")

		if char:FindFirstChild("Marble") then
			char.Marble:Destroy()
		elseif char:FindFirstChild("Square") then
			char.Square:Destroy()
		elseif char:FindFirstChild("Wedge") then
			char.Wedge:Destroy()
		end

		for _, part in pairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				part.Transparency = 0
				part.CanCollide = true
			end
		end

		HumanCameraEvent:FireClient(player)

		local HRP = char:FindFirstChild("HumanoidRootPart")
		if not HRP then
			warn("HumanoidRootPart introuvable pour " .. player.Name)
			return
		end

		local Hum = char:FindFirstChild("Humanoid")
		if not Hum then
			warn("Humanoid introuvable pour " .. player.Name)
			return
		end

		Hum.PlatformStand = false

		-- Stopper les vitesses du personnage
		char.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		char.PrimaryPart.AssemblyAngularVelocity = Vector3.new(0, 0, 0)

		-- Réinitialiser l'orientation et la position pour éviter tout mouvement
		while HRP.CFrame ~= CFrame.new(HRP.Position) * CFrame.Angles(0, math.rad(HRP.Orientation.Y), 0) do
			task.wait()
			HRP.CFrame = CFrame.new(HRP.Position) * CFrame.Angles(0, math.rad(HRP.Orientation.Y), 0)
		end

		local head = char:FindFirstChild("Head")
		if head and head:FindFirstChild("face") then
			local face = head:FindFirstChild("face")
			face.Transparency = 0 -- Rendre invisible
		end
	else
		print("Le joueur est déjà un humain!")
	end
end)
