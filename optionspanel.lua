local addonName, ns = ...

-- see: http://wow.go-hero.net/framexml/14545/Blizzard_CUFProfiles/Blizzard_CompactUnitFrameProfiles.lua

local frame = CompactUnitFrameProfilesGeneralOptionsFrame
local initializeMe = true

frame:HookScript("OnShow", function(self)
	if initializeMe then
		if ns.config.health.color then
			local classColors = _G[self:GetName() .. "UseClassColors"]
			classColors:Disable()
			classColors.tiptext = "Overridden by CompactUnitFrames addon settings"
			classColors:HookScript("OnEnter", ns.ShowTooltip)
			classColors:HookScript("OnLeave", ns.HideTooltip)
		end

		local slider = _G[self:GetName() .. "HeightSlider"]
		slider:SetMinMaxValues(0, 200) -- default: 36, 72

		local slider = _G[self:GetName() .. "WidthSlider"]
		slider:SetMinMaxValues(0, 200) -- default: 72, 144
	end
end)

-- /run CompactRaidFrame1.powerBar:SetPoint("BOTTOMRIGHT", CompactRaidFrame1, "TOPRIGHT", -1, -1-20)

-- reuse previous settings
-- CreateNewRaidProfile("CompactUnitFrames", CompactUnitFrameProfiles.newProfileDialog.baseProfile)
-- CompactUnitFrameProfiles_ActivateRaidProfile("CompactUnitFrames")