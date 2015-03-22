local addonName, addon, _ = ...

local function GetRoleLabel(key, label)
	if key == 'NONE' then
		return key, _G['NO_ROLE']
	else
		local icon = _G['INLINE_'..key..'_ICON'] or '|TInterface\\Icons\\Inv_misc_questionmark:16:16|t'
		return key, icon .. ' ' .. _G[key]
	end
end

local powerTypes = {
	[SPELL_POWER_MANA] = _G.MANA,
	[SPELL_POWER_RAGE] = _G.RAGE,
	[SPELL_POWER_FOCUS] = _G.FOCUS,
	[SPELL_POWER_ENERGY] = _G.ENERGY,
	[SPELL_POWER_RUNES] = _G.RUNES,
	[SPELL_POWER_RUNIC_POWER] = _G.RUNIC_POWER,
	[SPELL_POWER_SOUL_SHARDS] = _G.SOUL_SHARDS,
	[SPELL_POWER_ECLIPSE] = _G.ECLIPSE,
	[SPELL_POWER_HOLY_POWER] = _G.HOLY_POWER,
}
local function GetTypeLabel(key, value)
	return key, powerTypes[key] or key
end

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

	local types = {
		format = {
			cut = 'Cut',
			shorten = 'Shorten',
		},
		serverFormat = {
			full = 'Full: Player - Realm',
			short = 'Short: Player (*)',
		},
		texture = 'statusbar',
		color = 'text', -- default, class, role, custom + r.r:g.g:b.b
		hide = 'values',
		show = 'values',
		roles = 'multiselect',
		types = 'multiselect',
	}
	types.bgtexture = types.texture
	types.bgcolor = types.color

	local L = {
		rolesValues = GetRoleLabel,
		typesValues = GetTypeLabel,
		textureName = 'Statusbar Texture',
		bgtextureName = 'Background Texture',
		verticalName = 'Position: Vertical',
		verticalDesc = 'Display Bottom > Top instead of Left > Right',
		changePositionName = 'Position: Alternate',
		changePositionDesc = 'Display Top > Bottom (vertical) or Right > Left (horizontal)',
	}

	LibStub('LibDualSpec-1.0'):EnhanceDatabase(addon.db, addonName)
	LibStub('AceConfig-3.0'):RegisterOptionsTable(addonName, {
		type = 'group',
		args = {
			general  = LibStub('LibOptionsGenerate-1.0'):GetOptionsTable(addon.db, types, L),
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
