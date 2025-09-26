-- ===================================================================
-- MODULE UiEffects UNIVERSEL
-- Auteur: Gemini
-- Description:
-- Ce module applique une animation de bouton adaptée à sa configuration.
-- - Si le bouton a un enfant "ButtonScaler", il anime l'échelle (pour les UIGridLayout).
-- - Sinon, il anime la taille et la couleur (pour les boutons standards).
-- ===================================================================

-- Services
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
-- AJOUTS NÉCESSAIRES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") -- Le service correct pour la fonction

local module = {}

function module.AnimateButtonPress(button: GuiButton)
	local tweenInfoFast = TweenInfo.new(0.08)
	local tweenInfoSlow = TweenInfo.new(0.12)

	-- On vérifie si le bouton a un scaler (pour vos boutons de soundboard)
	local scaler = button:FindFirstChild("ButtonScaler")

	if scaler then
		-- CAS 1 : Le bouton a un "ButtonScaler".
		-- On anime uniquement l'échelle interne. C'est parfait pour les boutons dans un UIGridLayout.

		button.MouseEnter:Connect(function()
			TweenService:Create(scaler, tweenInfoSlow, { Scale = 1.05 }):Play()
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(scaler, tweenInfoSlow, { Scale = 1 }):Play()
		end)

		button.MouseButton1Down:Connect(function()
			TweenService:Create(scaler, tweenInfoFast, { Scale = 0.95 }):Play()
		end)

		button.MouseButton1Up:Connect(function()
			-- On vérifie si la souris est toujours sur le bouton pour décider de la taille de retour
			local mousePos = UserInputService:GetMouseLocation()
			-- CORRECTION : On utilise PlayerGui, pas GuiService
			local guiObjects = PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
			local isHovering = table.find(guiObjects, button)

			local targetScale = isHovering and 1.05 or 1
			TweenService:Create(scaler, tweenInfoSlow, { Scale = targetScale }):Play()
		end)
	else
		-- CAS 2 : Le bouton est standard (pas de scaler).
		-- On anime sa taille ET sa couleur. Fonctionne pour tous les autres boutons.

		local originalSize = button.Size
		local originalColor = button.BackgroundColor3
		-- On calcule une couleur légèrement plus sombre pour l'effet de pression
		local pressedColor = originalColor:Lerp(Color3.new(0, 0, 0), 0.2)

		-- Sécurité : si le bouton est transparent, on n'animera pas la couleur.
		local shouldAnimateColor = button.BackgroundTransparency < 1

		button.MouseEnter:Connect(function()
			TweenService:Create(button, tweenInfoSlow, {
				Size = UDim2.new(
					originalSize.X.Scale * 1.06,
					originalSize.X.Offset,
					originalSize.Y.Scale * 1.06,
					originalSize.Y.Offset
				),
			}):Play()
		end)

		button.MouseLeave:Connect(function()
			TweenService:Create(button, tweenInfoSlow, { Size = originalSize }):Play()
			if shouldAnimateColor then
				TweenService:Create(button, tweenInfoFast, { BackgroundColor3 = originalColor }):Play()
			end
		end)

		button.MouseButton1Down:Connect(function()
			local props = {
				Size = UDim2.new(
					originalSize.X.Scale * 0.9,
					originalSize.X.Offset,
					originalSize.Y.Scale * 0.9,
					originalSize.Y.Offset
				),
			}
			if shouldAnimateColor then
				props.BackgroundColor3 = pressedColor
			end
			TweenService:Create(button, tweenInfoFast, props):Play()
		end)

		button.MouseButton1Up:Connect(function()
			-- Au relâchement, on retourne à la taille de survol
			local props = {
				Size = UDim2.new(
					originalSize.X.Scale * 1.06,
					originalSize.X.Offset,
					originalSize.Y.Scale * 1.06,
					originalSize.Y.Offset
				),
			}
			if shouldAnimateColor then
				props.BackgroundColor3 = originalColor
			end
			TweenService:Create(button, tweenInfoSlow, props):Play()
		end)
	end
end

-- --- Application dynamique des effets ---
-- Cette partie est cruciale et ne change pas.
-- Elle applique l'effet à tous les boutons avec le tag "PressButton".

local function applyEffectToTaggedButtons()
	-- Appliquer aux boutons qui ont déjà le tag au démarrage
	local existingButtons = CollectionService:GetTagged("PressButton")
	for _, button in pairs(existingButtons) do
		pcall(module.AnimateButtonPress, button) -- pcall pour éviter qu'une erreur sur un bouton ne bloque les autres
	end

	-- Écouter les nouveaux boutons qui recevront le tag dans le futur
	CollectionService:GetInstanceAddedSignal("PressButton"):Connect(function(button)
		pcall(module.AnimateButtonPress, button)
	end)
end

-- On lance la fonction
applyEffectToTaggedButtons()

return module
