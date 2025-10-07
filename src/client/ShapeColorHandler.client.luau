local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Optional RemoteEvent (not required)
local PairEvents = ReplicatedStorage:FindFirstChild("PairEvents")
local ShapeColorEvent = PairEvents and PairEvents:FindFirstChild("ShapeColorEvent")

local COLORS = {
	Blue = Color3.fromRGB(77, 166, 255), -- #4DA6FF
	Red = Color3.fromRGB(255, 94, 94), -- #FF5E5E
	Default = Color3.fromRGB(135, 135, 135),
}

local SHAPE_NAMES = { "Marble", "Square", "Wedge" }

local connections = {}

local function safeSetColor(part, color)
	if not part or not part:IsA("BasePart") then
		return
	end
	pcall(function()
		part.Color = color
	end)
end

local function recolorCharacterShapes(character, color)
	if not character then
		return
	end
	for _, name in ipairs(SHAPE_NAMES) do
		local shape = character:FindFirstChild(name)
		if shape and shape:IsA("BasePart") then
			safeSetColor(shape, color)
		end
	end
end

local function watchPlayer(playerObj, colorProvider)
	-- colorProvider(player) -> Color3 or nil
	if not playerObj then
		return
	end
	-- cleanup previous connections for this player
	if connections[playerObj] then
		for _, c in ipairs(connections[playerObj]) do
			pcall(function()
				c:Disconnect()
			end)
		end
	end
	connections[playerObj] = {}

	local function applyToChar(char)
		local c = colorProvider(playerObj)
		if c then
			recolorCharacterShapes(char, c)
		end
		local dconn = char.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") and (desc.Name == "Marble" or desc.Name == "Square" or desc.Name == "Wedge") then
				local cc = colorProvider(playerObj)
				if cc then
					safeSetColor(desc, cc)
				end
			end
		end)
		table.insert(connections[playerObj], dconn)
	end

	table.insert(connections[playerObj], playerObj.CharacterAdded:Connect(applyToChar))
	if playerObj.Character then
		applyToChar(playerObj.Character)
	end
end

local function clearAllOtherBindings()
	for p, conns in pairs(connections) do
		if p ~= LocalPlayer then
			for _, c in ipairs(conns) do
				pcall(function()
					c:Disconnect()
				end)
			end
			connections[p] = nil
		end
	end
end

local function updateShapeColors()
	local myColorName = LocalPlayer:GetAttribute("Color") or ""
	local myColor = COLORS[myColorName] or COLORS.Default
	-- recolor my shapes
	if LocalPlayer.Character then
		recolorCharacterShapes(LocalPlayer.Character, myColor)
	end
	watchPlayer(LocalPlayer, function()
		return myColor
	end)

	local pairName = LocalPlayer:GetAttribute("IsPairedWith") or ""
	if pairName ~= "" then
		local other = Players:FindFirstChild(pairName)
		if other then
			-- inverse color locally
			local invName
			if myColorName == "Red" then
				invName = "Blue"
			elseif myColorName == "Blue" then
				invName = "Red"
			end
			local otherColor = COLORS[invName] or COLORS.Default
			watchPlayer(other, function()
				return otherColor
			end)
		else
			-- if other not present yet, wait for them
			local conn
			conn = Players.PlayerAdded:Connect(function(p)
				if p.Name == pairName then
					conn:Disconnect()
					local invName
					if myColorName == "Red" then
						invName = "Blue"
					elseif myColorName == "Blue" then
						invName = "Red"
					end
					local otherColor = COLORS[invName] or COLORS.Default
					watchPlayer(p, function()
						return otherColor
					end)
				end
			end)
			-- store under LocalPlayer connections so it can be cleared later
			if not connections[LocalPlayer] then
				connections[LocalPlayer] = {}
			end
			table.insert(connections[LocalPlayer], conn)
		end
	else
		clearAllOtherBindings()
	end
end

-- React to attribute changes
LocalPlayer:GetAttributeChangedSignal("Color"):Connect(updateShapeColors)
LocalPlayer:GetAttributeChangedSignal("IsPairedWith"):Connect(updateShapeColors)

-- initial
updateShapeColors()

-- If server uses a ShapeColorEvent we also support direct server pushes
if ShapeColorEvent and ShapeColorEvent.OnClientEvent then
	ShapeColorEvent.OnClientEvent:Connect(function(otherPlayerName, colorName)
		-- server can explicitly ask to recolor a given other player locally
		LocalPlayer:SetAttribute("IsPairedWith", otherPlayerName or "")
		if colorName then
			LocalPlayer:SetAttribute("Color", colorName)
		end
	end)
end
