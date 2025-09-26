local rs = game:GetService("ReplicatedStorage")
local event = rs:WaitForChild("SliderEvents").SizeChange

local ShapeShiftEvents = rs:WaitForChild("ShapeShiftEvents")
local HumanEvents = ShapeShiftEvents:WaitForChild("HumanEvents")
local HumanCameraEvent = HumanEvents:WaitForChild("Camera")

local originalSize = {}

event.OnServerEvent:Connect(function(player, size)
	local character = player.Character
	if not character then
		return
	end

	local sizeMultiplier = ((size * 100) / 100) * 2

	local function charSize()
		print("Multiplicateur de taille:", sizeMultiplier)
		local Width = sizeMultiplier
		local Height = sizeMultiplier
		local Depth = sizeMultiplier
		local Vector = Vector3.new(Width, Height, Depth)

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid or humanoid.RigType ~= Enum.HumanoidRigType.R6 then
			return
		end

		-- Sauvegarder les tailles d'origine si ce n'est pas encore fait
		if not originalSize[character] then
			originalSize[character] = { parts = {}, motors = {}, accessories = {} }
			-- Sauvegarder les tailles des parties du corps
			for _, part in pairs(character:GetChildren()) do
				if part:IsA("BasePart") then
					originalSize[character].parts[part.Name] = part.Size
				end
			end

			-- Sauvegarder les valeurs des joints
			local Motors = {}
			table.insert(Motors, character.HumanoidRootPart.RootJoint)
			for _, motor in pairs(character.Torso:GetChildren()) do
				if motor:IsA("Motor6D") then
					table.insert(Motors, motor)
				end
			end
			for _, motor in pairs(Motors) do
				originalSize[character].motors[motor] = {
					C0 = motor.C0,
					C1 = motor.C1,
				}
			end

			-- Sauvegarder les accessoires
			for _, accessory in pairs(character:GetChildren()) do
				if accessory:IsA("Accessory") then
					local weld = accessory.Handle.AccessoryWeld
					originalSize[character].accessories[accessory] = {
						C0 = weld.C0,
						C1 = weld.C1,
						meshScale = accessory.Handle:FindFirstChildOfClass("SpecialMesh")
							and accessory.Handle:FindFirstChildOfClass("SpecialMesh").Scale,
					}
				end
			end
		end

		-- Redimensionner les parties du corps
		for _, part in pairs(character:GetChildren()) do
			if part:IsA("BasePart") and originalSize[character].parts[part.Name] then
				part.Size = originalSize[character].parts[part.Name] * Vector
			end
		end

		-- Redimensionner les joints (Motors)
		for motor, original in pairs(originalSize[character].motors) do
			motor.C0 = CFrame.new((original.C0.Position * Vector)) * (original.C0 - original.C0.Position)
			motor.C1 = CFrame.new((original.C1.Position * Vector)) * (original.C1 - original.C1.Position)
		end

		-- Redimensionner les Meshes de la tête
		if character.Head.Mesh and character.Head.Mesh.MeshId ~= "" then
			character.Head.Mesh.Scale = originalSize[character].parts["Head"] * Vector
		end

		-- Redimensionner les accessoires
		for accessory, original in pairs(originalSize[character].accessories) do
			local weld = accessory.Handle.AccessoryWeld
			weld.C0 = CFrame.new((original.C0.Position * Vector)) * (original.C0 - original.C0.Position)
			weld.C1 = CFrame.new((original.C1.Position * Vector)) * (original.C1 - original.C1.Position)
			local mesh = accessory.Handle:FindFirstChildOfClass("SpecialMesh")
			if mesh and original.meshScale then
				mesh.Scale = original.meshScale * Vector
			end
		end
	end

	if character:FindFirstChild("Marble") then
		local marble = character.Marble

		if not originalSize[marble] then
			originalSize[marble] = Vector3.new(8, 8, 8)
		end

		charSize()

		-- Multiplier la taille de chaque dimension individuellement
		local marbleBaseSize = originalSize[marble]
		marble.Size = Vector3.new(
			marbleBaseSize.X * sizeMultiplier,
			marbleBaseSize.Y * sizeMultiplier,
			marbleBaseSize.Z * sizeMultiplier
		)
	elseif character:FindFirstChild("Square") then
		local square = character.Square

		if not originalSize[square] then
			originalSize[square] = Vector3.new(7, 7, 7)
		end

		charSize()

		-- Multiplier la taille de chaque dimension individuellement
		local squareBaseSize = originalSize[square]
		square.Size = Vector3.new(
			squareBaseSize.X * sizeMultiplier,
			squareBaseSize.Y * sizeMultiplier,
			squareBaseSize.Z * sizeMultiplier
		)
	elseif character:FindFirstChild("Wedge") then
		local wedge = character.Wedge

		if not originalSize[wedge] then
			originalSize[wedge] = Vector3.new(7, 7, 7)
		end

		charSize()

		-- Multiplier la taille de chaque dimension individuellement
		local squareBaseSize = originalSize[wedge]
		wedge.Size = Vector3.new(
			squareBaseSize.X * sizeMultiplier,
			squareBaseSize.Y * sizeMultiplier,
			squareBaseSize.Z * sizeMultiplier
		)
	else
		charSize()
		HumanCameraEvent:FireClient(player)
	end
end)

-- Calculer le multiplicateur de taille
