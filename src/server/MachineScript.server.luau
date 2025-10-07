--// Server Script
local machinesFolder = workspace:WaitForChild("Folder"):WaitForChild("Machines")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local PairEvents = RS:WaitForChild("PairEvents")

local disableControlsEvent = PairEvents:WaitForChild("DisableControlsEvent")
local enableControlsEvent = PairEvents:WaitForChild("EnableControlsEvent")
local leaveEvent = PairEvents:WaitForChild("LeaveEvent")
local enableGuiEvent = PairEvents:WaitForChild("EnableGuiEvent")
local timerEvent = PairEvents:WaitForChild("TimerEvent")
local teleportEvent = PairEvents:WaitForChild("TeleportToLevelEvent")
local mainGuiEvent = PairEvents:WaitForChild("MainGuiEvent")
local pairEvent = PairEvents:WaitForChild("PairEvent")
local HightlightEvent = PairEvents:WaitForChild("PairHighlightEvent")

-- Récupère la vraie part tactile d’un pad (Pad1/Pad2 peuvent être un Model ou directement une Part)
local function getTouchPart(container)
	if not container then
		return nil
	end
	if container:IsA("BasePart") then
		return container
	end
	return container:FindFirstChild("TouchPart") or container:FindFirstChildWhichIsA("BasePart")
end

local function getPlayerName(padContainer)
	if not padContainer then
		return nil
	end
	return padContainer:GetAttribute("Player")
end

local function setPlayerName(padContainer, player)
	padContainer:SetAttribute("Player", player)
end

local function getColor(padContainer)
	if not padContainer then
		return nil
	end
	return padContainer:GetAttribute("Color")
end

-- Trouve la Part de destination à partir de l'attribut Teleport du pad
local function getTeleportPart(machineModel, padContainer)
	local targetName = padContainer:GetAttribute("Teleport")
	if not targetName then
		local touch = getTouchPart(padContainer)
		if touch then
			targetName = touch:GetAttribute("Teleport")
		end
	end
	if type(targetName) ~= "string" or targetName == "" then
		return nil, "Attribut 'Teleport' manquant ou vide sur " .. padContainer.Name
	end

	local target = machineModel:FindFirstChild(targetName)
	if not target or not target:IsA("BasePart") then
		return nil,
			("Destination '%s' introuvable ou invalide dans la machine %s"):format(targetName, machineModel.Name)
	end
	return target
end

local function unpair(player)
	local otherPlayer = player:GetAttribute("IsPairedWith")
	player:SetAttribute("IsPairedWith", "")
	otherPlayer:SetAttribute("IsPairedWith", "")
end

local function getTeleportOutPart(machineModel, padContainer)
	local targetName = padContainer:GetAttribute("TeleportOut")
	if not targetName then
		local touch = getTouchPart(padContainer)
		if touch then
			targetName = touch:GetAttribute("TeleportOut")
		end
	end

	local target = machineModel:FindFirstChild(targetName)
	if not target or not target:IsA("BasePart") then
		return nil,
			("Destination '%s' introuvable ou invalide dans la machine %s"):format(targetName, machineModel.Name)
	end
	return target
end

local function getDoor(machineModel, padContainer)
	local targetName = padContainer:GetAttribute("Door")
	if not targetName or targetName == "" then
		return nil
	end

	local target = machineModel:FindFirstChild(targetName)
	if not target or not target:IsA("BasePart") then
		warn(("Porte '%s' introuvable ou invalide dans la machine %s"):format(tostring(targetName), machineModel.Name))
		return nil
	end
	return target
end

local function getScreen(machineModel, padContainer)
	local targetName = padContainer:GetAttribute("Screen")
	if not targetName or targetName == "" then
		return nil
	end

	local target = machineModel:FindFirstChild(targetName)
	if not target or not target:IsA("Model") then
		warn(("Porte '%s' introuvable ou invalide dans la machine %s"):format(tostring(targetName), machineModel.Name))
		return nil
	end
	return target
end

local function isBusy(padContainer)
	return padContainer and padContainer:GetAttribute("IsBusy") == true
end

local function setBusy(padContainer, value)
	padContainer:SetAttribute("IsBusy", value and true or false)
end

function setScreen(machineModel, padContainer, value)
	local screen = getScreen(machineModel, padContainer)
	if not screen then
		return nil
	end

	local tick = screen:WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild("Frame"):WaitForChild("Tick")
	local character =
		screen:WaitForChild("Screen"):WaitForChild("SurfaceGui"):WaitForChild("Frame"):WaitForChild("Char")

	if value then
		character.Visible = false
		tick.Visible = true
	else
		tick.Visible = false
		character.Visible = true
	end
end

local function closeDoor(machineModel, padContainer)
	local door = getDoor(machineModel, padContainer)
	if not door then
		return nil
	end

	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)
	local newSize = door.Size + Vector3.new(0, 6.744, 0)
	local newPosition = door.Position - Vector3.new(0, 3.332, 0)
	local tween = TS:Create(door, info, { Size = newSize, Position = newPosition })
	tween:Play()
	return tween
end

local function openDoor(machineModel, padContainer)
	local door = getDoor(machineModel, padContainer)
	if not door then
		return nil
	end

	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false)
	local newSize = door.Size - Vector3.new(0, 6.744, 0)
	local newPosition = door.Position + Vector3.new(0, 3.332, 0)
	local tween = TS:Create(door, info, { Size = newSize, Position = newPosition })
	tween:Play()
	return tween
end

-- Debounce par joueur et par machine
local busy = {} -- busy[player.UserId][machineModel] = true
local activePad = {}

local function safeFreezeServer(char, frozen)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then
		return
	end

	if frozen then
		hum.AutoRotate = false
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.Anchored = true
	else
		hrp.Anchored = false
		hum.AutoRotate = true
	end
end

local function onPadTouched(padContainer, machineModel, hit)
	local character = hit and hit.Parent
	if not character then
		return
	end
	if not character:FindFirstChildOfClass("Humanoid") then
		return
	end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return
	end

	busy[player.UserId] = busy[player.UserId] or {}
	if busy[player.UserId][machineModel] then
		return
	end
	busy[player.UserId][machineModel] = true

	if isBusy(padContainer) then
		-- Ce pad est déjà en cours d'utilisation par quelqu'un
		busy[player.UserId][machineModel] = nil
		return
	end

	-- Cherche la destination
	local dest, err = getTeleportPart(machineModel, padContainer)
	if not dest then
		warn(err)
		busy[player.UserId][machineModel] = nil
		return
	end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum then
		busy[player.UserId][machineModel] = nil
		return
	end

	-- Marque le pad occupé
	setBusy(padContainer, true)
	setPlayerName(padContainer, player.Name)
	setScreen(machineModel, padContainer, true)

	-- Demande au client de se figer (désactive contrôles, shift-lock, etc.)
	-- Je passe la CFrame cible pour que le client se cale visuellement aussi s’il faut.
	disableControlsEvent:FireClient(player, dest.CFrame)

	-- Sécurité serveur : fige aussi côté serveur pour éviter tout fling/désync
	safeFreezeServer(character, true)

	enableGuiEvent:FireClient(player)

	-- Téléport serveur (autorité réseau)
	hrp.CFrame = dest.CFrame

	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	activePad[player.UserId] = { pad = padContainer, machine = machineModel }

	-- Ferme la porte si configurée
	local tweenClose = closeDoor(machineModel, padContainer)

	print(
		("%s téléporté à '%s' depuis %s de la machine %s"):format(
			player.Name,
			dest.Name,
			padContainer.Name,
			machineModel.Name
		)
	)

	-- Attends la fin de l’anim de porte (si présente) ou un petit délai de sûreté
	if tweenClose then
		tweenClose.Completed:Wait()
	else
		task.wait(0.3)
	end

	-- (Ici tu peux lancer une cinématique / machine / séquence, etc.)
	-- ...

	-- petit cooldown de contact pour éviter le retrigger instantané
	task.delay(0.5, function()
		if busy[player.UserId] then
			busy[player.UserId][machineModel] = nil
			if next(busy[player.UserId]) == nil then
				busy[player.UserId] = nil
			end
		end
	end)
end

leaveEvent.OnServerEvent:Connect(function(player)
	local data = activePad[player.UserId]
	if not data then
		return
	end

	local padContainer = data.pad
	local machineModel = data.machine

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local destOut, err = getTeleportOutPart(machineModel, padContainer)
	if not destOut then
		warn(err)
		-- Libère quand même le pad pour éviter les locks
		setBusy(padContainer, false)
		setPlayerName(padContainer, nil)
		activePad[player.UserId] = nil
		return
	end

	-- Défige + rend les contrôles
	safeFreezeServer(character, false)
	enableControlsEvent:FireClient(player)

	-- TP sortie
	hrp.CFrame = destOut.CFrame
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Ouvre la porte associée à CE pad uniquement
	local tweenOpen = openDoor(machineModel, padContainer)
	if tweenOpen then
		tweenOpen.Completed:Wait()
	else
		task.wait(0.3)
	end

	-- Libère le pad et nettoie l’état
	setBusy(padContainer, false)
	setPlayerName(padContainer, "")
	setScreen(machineModel, padContainer, false)
	activePad[player.UserId] = nil
end)

teleportEvent.OnServerEvent:Connect(function(player)
	local teleportFolder = workspace:FindFirstChild("Folder"):FindFirstChild("Teleports")
	if not teleportFolder then
		warn("Dossier 'Teleports' introuvable dans le dossier 'Folder' de Workspace")
		return
	end
	local dest = teleportFolder:FindFirstChild("LevelStart")

	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	-- TP serveur (autorité réseau)
	hrp.CFrame = dest.CFrame

	-- Défige + rend les contrôles
	safeFreezeServer(character, false)
	enableControlsEvent:FireClient(player)

	-- TP sortie
	hrp.CFrame = dest.CFrame
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- Récupère le pad et la machine associés à ce joueur, si existants
	local data = activePad[player.UserId]
	local padContainer = data and data.pad or nil
	local machineModel = data and data.machine or nil

	mainGuiEvent:FireClient(player, true)

	-- Ouvre la porte associée à CE pad uniquement si machineModel et padContainer existent
	if machineModel and padContainer then
		local tweenOpen = openDoor(machineModel, padContainer)
		if tweenOpen then
			tweenOpen.Completed:Wait()
		else
			task.wait(0.3)
		end

		-- Libère le pad et nettoie l’état
		setBusy(padContainer, false)
		setPlayerName(padContainer, "")
		setScreen(machineModel, padContainer, false)
		activePad[player.UserId] = nil
	end
end)

pairEvent.OnServerEvent:Connect(function(player)
	local otherPad
	local data = activePad[player.UserId]
	local padContainer = data and data.pad or nil
	local machineModel = data and data.machine or nil

	if padContainer.Name == "Pad1" then
		otherPad = machineModel:FindFirstChild("Pad2")
	else
		otherPad = machineModel:FindFirstChild("Pad1")
	end

	-- Evite d'assigner nil (SetAttribute(name, nil) supprime l'attribut).
	-- On met une chaîne vide quand il n'y a pas de joueur pairé.
	player:SetAttribute("IsPairedWith", getPlayerName(otherPad) or "")
	player:SetAttribute("Color", getColor(padContainer) or "")
	HightlightEvent:FireClient(player, getPlayerName(otherPad), getColor(otherPad) or "")
end)

local function attachBothBusyWatcher(machineModel, padContainer)
	local pad1 = machineModel:FindFirstChild("Pad1")
	local pad2 = machineModel:FindFirstChild("Pad2")
	local player = game:GetService("Players"):FindFirstChild(getPlayerName(padContainer))
	if not pad1 or not pad2 then
		return
	end

	-- Flag pour éviter le spam
	machineModel:SetAttribute("BothBusyAnnounced", false)

	local function evaluate()
		local both = isBusy(pad1) and isBusy(pad2)
		local announced = machineModel:GetAttribute("BothBusyAnnounced")

		if both and not announced then
			print("Deux pads occupés")
			machineModel:SetAttribute("BothBusyAnnounced", true)
			timerEvent:FireClient(player, padContainer)
		elseif not both and announced then
			-- on se réarme pour un prochain “both busy”
			machineModel:SetAttribute("BothBusyAnnounced", false)
		end
	end

	-- Évalue l’état actuel
	evaluate()

	-- Réagit uniquement quand l’attribut change
	pad1:GetAttributeChangedSignal("IsBusy"):Connect(evaluate)
	pad2:GetAttributeChangedSignal("IsBusy"):Connect(evaluate)
end

local function connectPad(padContainer, machineModel)
	local touchPart = getTouchPart(padContainer)
	if not touchPart then
		warn("Part tactile introuvable pour : ", padContainer:GetFullName())
		return
	end
	touchPart.CanTouch = true
	touchPart.Touched:Connect(function(hit)
		if isBusy(padContainer) then
			return
		end
		onPadTouched(padContainer, machineModel, hit)
		attachBothBusyWatcher(machineModel, padContainer)
	end)
end

local function connectMachine(machineModel)
	if not machineModel:IsA("Model") then
		return
	end
	local pad1 = machineModel:FindFirstChild("Pad1")
	local pad2 = machineModel:FindFirstChild("Pad2")
	if pad1 then
		connectPad(pad1, machineModel)
	end
	if pad2 then
		connectPad(pad2, machineModel)
	end
end

-- Connecte les machines existantes
for _, machine in ipairs(machinesFolder:GetChildren()) do
	connectMachine(machine)
end

-- Et celles ajoutées plus tard
machinesFolder.ChildAdded:Connect(function(child)
	task.defer(connectMachine, child)
end)

-- Lorsque le joueur quitte le jeu, s'il était actif sur une machine on libère proprement le pad
Players.PlayerRemoving:Connect(function(player)
	local data = activePad[player.UserId]
	if not data then
		return
	end

	local padContainer = data.pad
	local machineModel = data.machine

	-- Ouvre la porte associée à CE pad uniquement si configurée
	if machineModel and padContainer then
		local ok, tweenOpen = pcall(function()
			return openDoor(machineModel, padContainer)
		end)
		if ok and tweenOpen then
			-- protected wait car le tween peut parfois être nil ou l'objet détruit
			pcall(function()
				tweenOpen.Completed:Wait()
			end)
		else
			task.wait(0.3)
		end
	end

	-- Libère le pad et nettoie l'état
	if padContainer then
		pcall(function()
			setBusy(padContainer, false)
			setPlayerName(padContainer, "")
		end)
	end
	if machineModel and padContainer then
		pcall(function()
			setScreen(machineModel, padContainer, false)
		end)
	end

	activePad[player.UserId] = nil

	-- Nettoie la table de debounce "busy"
	if busy[player.UserId] then
		busy[player.UserId][machineModel] = nil
		if next(busy[player.UserId]) == nil then
			busy[player.UserId] = nil
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	-- Initialisation explicite : utiliser une valeur non-nil pour créer
	-- l'attribut côté serveur (SetAttribute(..., nil) le supprime).
	player:SetAttribute("IsPairedWith", "")
	player:SetAttribute("Color", "")
end)
