if true then return end -- CUF does not yet use AceDB
local addonName, addon, _ = ...

local function OpenConfiguration(self, args)
	-- remove placeholder configuration panel
	for i, panel in ipairs(_G.INTERFACEOPTIONS_ADDONCATEGORIES) do
		if panel == self then
			tremove(INTERFACEOPTIONS_ADDONCATEGORIES, i)
			break
		end
	end
	self:SetScript('OnShow', nil)
	self:Hide()

	LibStub('LibDualSpec-1.0'):EnhanceDatabase(addon.db, addonName)
	LibStub('AceConfig-3.0'):RegisterOptionsTable(addonName, {
		type = 'group',
		args = {
			general  = LibStub('LibOptionsGenerate-1.0'):GetOptionsTable(addon.db),
			profiles = LibStub('AceDBOptions-3.0'):GetOptionsTable(addon.db)
		},
	})
	local AceConfigDialog = LibStub('AceConfigDialog-3.0')
	AceConfigDialog:AddToBlizOptions(addonName, nil, nil, 'general')
	AceConfigDialog:AddToBlizOptions(addonName, 'Profiles', addonName, 'profiles')

	OpenConfiguration = function(panel, args)
		InterfaceOptionsFrame_OpenToCategory(addonName)
	end
	OpenConfiguration(self, args)
end

-- create a fake configuration panel
local panel = CreateFrame('Frame')
      panel.name = addonName
      panel:Hide()
      panel:SetScript('OnShow', OpenConfiguration)
InterfaceOptions_AddCategory(panel)

-- use slash command to toggle config
_G['SLASH_'..addonName] = '/'..addonName
_G.SlashCmdList[addonName] = function(args) OpenConfiguration(panel, args) end

-- --------------------------------------------------------

addon:LoadWith('Blizzard_CUFProfiles', function(...)
	hooksecurefunc('CompactUnitFrameProfiles_UpdateCurrentPanel', function(self)
		local panelName = 'CompactUnitFrameProfilesGeneralOptionsFrame'
		if CompactUnitFrames.db.profile.health.color then
			local classColors = _G[panelName .. 'UseClassColors']
			      classColors:Disable()
			-- classColors.tiptext = "Overridden by CompactUnitFrames addon settings"
			-- classColors:HookScript("OnEnter", ns.ShowTooltip)
			-- classColors:HookScript("OnLeave", ns.HideTooltip)
		end

		local slider = _G[panelName .. 'HeightSlider']
		local min, max = slider:GetMinMaxValues()
		slider:SetMinMaxValues(math.min(0, min), math.max(max, 200)) -- default: 36, 72

		local slider = _G[panelName .. 'WidthSlider']
		local min, max = slider:GetMinMaxValues()
		slider:SetMinMaxValues(math.min(0, min), math.max(max, 200)) -- default: 72, 144
	end)
end)
