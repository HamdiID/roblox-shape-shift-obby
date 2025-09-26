-- Script UiHelper

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Modules
local UiEffects = require(ReplicatedStorage.Shared.Modules.Client.UiEffects)

-- ✅ On crée les sons UNE SEULE FOIS au début du script.
local hoverSound = Instance.new("Sound")
hoverSound.SoundId = "rbxassetid://7218169592"
hoverSound.Parent = script -- On peut le parenter au script, c'est propre.

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://876939830"
clickSound.Parent = script

-- ===================================================================
-- ✅ Une seule fonction qui configure TOUT pour un bouton
-- ===================================================================
local function setupButton(button)
	if not button:IsA("GuiButton") then
		return
	end

	-- 1. Appliquer les effets visuels du module
	UiEffects.AnimateButtonPress(button)

	-- 2. Connecter les événements sonores
	button.MouseEnter:Connect(function()
		hoverSound:Play()
	end)

	button.MouseButton1Click:Connect(function()
		clickSound:Play()
	end)
end

-- ===================================================================
-- Application de la configuration
-- ===================================================================

task.wait(0.1)

-- 1. Appliquer la configuration complète aux boutons qui ont DÉJÀ le tag
for _, button in pairs(CollectionService:GetTagged("PressButton")) do
	setupButton(button)
end

-- 2. Appliquer la configuration complète aux NOUVEAUX boutons qui recevront le tag
CollectionService:GetInstanceAddedSignal("PressButton"):Connect(setupButton)
