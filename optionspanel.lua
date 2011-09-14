local addonName, ns = ...

-- see: http://wow.go-hero.net/framexml/14545/Blizzard_CUFProfiles/Blizzard_CompactUnitFrameProfiles.lua
-- Blizzard_CUFProfiles/Blizzard_CompactUnitFrameProfiles.lua

-- parentHeightSlider minValue="36" maxValue="72"
-- parentWidthSlider minValue="72" maxValue="144"

local frame = CompactUnitFrameProfilesGeneralOptionsFrame
local initializeMe = true

frame:HookScript("OnShow", function(self)
	if initializeMe then
		ns:Print("Showing")

		local slider = _G[self:GetName() .. "HeightSlider"]
		slider:SetMinMaxValues(0, 200)

		local slider = _G[self:GetName() .. "WidthSlider"]
		slider:SetMinMaxValues(0, 200)
	end
end)

-- reuse previous settings
-- CreateNewRaidProfile("CompactUnitFrames", CompactUnitFrameProfiles.newProfileDialog.baseProfile)
-- CompactUnitFrameProfiles_ActivateRaidProfile("CompactUnitFrames")