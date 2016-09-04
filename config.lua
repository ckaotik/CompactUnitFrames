local addonName, addon, _ = ...
local AceConfigDialog = LibStub('AceConfigDialog-3.0')

local function GetConfigurationVariables()
	local powerTypes = {
		[-1] = _G.UNKNOWN,
		[SPELL_POWER_MANA] = _G.MANA,
		[SPELL_POWER_RAGE] = _G.RAGE,
		[SPELL_POWER_FOCUS] = _G.FOCUS,
		[SPELL_POWER_ENERGY] = _G.ENERGY,
		[SPELL_POWER_RUNES] = _G.RUNES,
		[SPELL_POWER_RUNIC_POWER] = _G.RUNIC_POWER,
		[SPELL_POWER_SOUL_SHARDS] = _G.SOUL_SHARDS,
		[SPELL_POWER_HOLY_POWER] = _G.HOLY_POWER,
		[SPELL_POWER_MAELSTROM] = _G.MAELSTROM,
	}
	local function GetTypeLabel(key, value)
		local color = _G.HIGHLIGHT_FONT_COLOR -- addon.db.profile.power.colors[key]
		if PowerBarColor[key] then
			color = PowerBarColor[key].r and PowerBarColor[key] or select(2, next(PowerBarColor[key]))
			if not color.r then color = _G.HIGHLIGHT_FONT_COLOR end
		end
		local label = ('\124cFF%02x%02x%02x%s\124r'):format(color.r * 255, color.g * 255, color.b * 255, powerTypes[key] or key)
		return key, label
	end

	local function GetRoleLabel(key, label)
		if key == 'NONE' then
			return key, _G['NO_ROLE']
		else
			local icon = _G['INLINE_'..key..'_ICON'] or '|TInterface\\Icons\\Inv_misc_questionmark:16:16|t'
			return key, icon .. ' ' .. _G[key]
		end
	end

	local types = {
		format = {
			cut     = 'Cut',
			shorten = 'Shorten',
		},
		serverFormat = {
			full    = 'Full: Player - Realm',
			short   = 'Short: Player (*)',
			none    = 'None: Player',
		},
		colorType = {
			default = 'Default',
			class   = 'Class',
			role    = 'Role',
			custom  = 'Custom',
		},
		texture = 'statusbar',
		hide = 'values',
		show = 'values',
		roles = 'multiselect',
		types = 'multiselect',
		length = 'unsigned',
	}
	types.bgtexture = types.texture
	types.bgcolorType = types.colorType
	types.bgcolor = types.color

	local locale = {
		rolesValues = GetRoleLabel,
		typesValues = GetTypeLabel,
		textureName = 'Statusbar Texture',
		bgtextureName = 'Background Texture',
		verticalName = 'Position: Vertical',
		verticalDesc = 'Display Bottom > Top instead of Left > Right',
		changePositionName = 'Position: Alternate',
		changePositionDesc = 'Display Top > Bottom (vertical) or Right > Left (horizontal)',
		colorName = 'Color ',
		colorTypeName = 'Color',
		bgcolorName = 'Background Color ',
		bgcolorTypeName = 'Background Color',
		nameName = _G.CALENDAR_EVENT_NAME,
		statusName = _G.STATUSTEXT_LABEL,
		framesName = _G.GENERAL,
		buffsName = _G.SHOW_BUFFS,
		indicatorsName = _G.SHOW_TARGET_EFFECTS,
		debuffsName = _G.SHOW_DEBUFFS,
		unitframeName = _G.UNITFRAME_LABEL,
		healthName = _G.HEALTH,
			flagsAsPvPColorName = 'Unit is in PvP',
			flagsAsPvPColorDesc = 'Color units that require you to turn on PvP to interact with them.',
			isEnemyColorName = 'Unit is enemy',
			isEnemyColorDesc = 'Color units that are enemies, e.g. mind-controlled.',
		powerName = 'Power',
	}

	-- variable, typeMappings, L, includeNamespaces, callback
	return addon.db, types, locale, false, nil
end

local function InitializeConfiguration(self, args)
	local AceConfig = LibStub('AceConfig-3.0')

	LibStub('LibDualSpec-1.0'):EnhanceDatabase(addon.db, addonName)

	-- Initialize main panel.
	local optionsTable = LibStub('LibOptionsGenerate-1.0'):GetOptionsTable(GetConfigurationVariables())
	      optionsTable.name = addonName
	if AddConfigurationExtras then AddConfigurationExtras(optionsTable) end
	AceConfig:RegisterOptionsTable(addonName, optionsTable)

	-- Add panels for submodules.
	local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
	for name, subModule in addon:IterateModules() do
		if AceConfigRegistry.tables[subModule.name] then
			AceConfigDialog:AddToBlizOptions(subModule.name, name, addonName)
		end
	end

	if addon.db.defaults and addon.db.defaults.profile and next(addon.db.defaults.profile) then
		-- Add panel for profile settings.
		local profileOptions = LibStub('AceDBOptions-3.0'):GetOptionsTable(addon.db)
		profileOptions.name = addonName .. ' - ' .. profileOptions.name
		AceConfig:RegisterOptionsTable(addonName..'_profiles', profileOptions)
		AceConfigDialog:AddToBlizOptions(addonName..'_profiles', 'Profiles', addonName)
	end

	-- Restore original OnShow handler.
	self:SetScript('OnShow', self.origOnShow)
	self.origOnShow = nil

	InterfaceAddOnsList_Update()
	InterfaceOptionsList_DisplayPanel(self)
end

-- Create a placeholder configuration panel.
local panel = AceConfigDialog:AddToBlizOptions(addonName)
panel.origOnShow = panel:GetScript('OnShow')
panel:SetScript('OnShow', InitializeConfiguration)

-- use slash command to toggle config
_G['SLASH_'..addonName..'1'] = '/'..addonName
_G['SLASH_'..addonName..'2'] = '/cuf'
_G.SlashCmdList[addonName] = function(args) InterfaceOptionsFrame_OpenToCategory(addonName) end

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
