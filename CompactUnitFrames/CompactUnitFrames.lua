local addonName, addon, _ = ...
   _G[addonName] = addon -- external reference
LibStub('AceAddon-3.0'):NewAddon(addon, addonName, 'AceEvent-3.0', 'AceTimer-3.0')

-- GLOBALS: _G, CUF_GlobalDB, CONFIGMODE_CALLBACKS, CompactRaidFrameManager, CompactRaidFrameContainer, DefaultCompactUnitFrameSetup, DefaultCompactMiniFrameSetup, CompactRaidFrameContainer_ApplyToFrames, CompactUnitFrame_UpdateAll
-- GLOBALS: CompactRaidFrameManagerDisplayFrameLockedModeToggle, CompactRaidFrameManager_UnlockContainer, CompactRaidFrameManager_LockContainer, CompactRaidFrameManager_SetSetting, CompactRaidFrameManager_UpdateShown
-- GLOBALS: select, type, pairs, ipairs, math.floor, tonumber, tostringall, hooksecurefunc, loadstring

-- CompactUnitFrameProfiles_ApplyCurrentSettings()

function addon:OnInitialize()
	self.db = LibStub('AceDB-3.0'):New(addonName..'DB', addon.defaults, true)

	-- /sigh
	-- _G.CompactUnitFrame_SetUpClicks = function(...) end
end

function addon:OnEnable()
	addon.playerName, addon.playerRealm = UnitFullName('player')

	-- this function gets called once per unit frame
	hooksecurefunc('CompactUnitFrame_SetUpFrame', function(frame, func)
		local style = (func == DefaultCompactUnitFrameSetup and 'normal') or (func == DefaultCompactMiniFrameSetup and 'mini')
		if not style then return end
		addon.SetupCompactUnitFrame(frame, style, true)
	end)
	-- this function gets called multiple times per session, e.g. when settings change
	hooksecurefunc('CompactRaidFrameContainer_ApplyToFrames', function(container, updateSpecifier, func, ...)
		local style = (func == DefaultCompactUnitFrameSetup and 'normal') or (func == DefaultCompactMiniFrameSetup and 'mini')
		if not style then return end

		for specifier, frames in pairs(container.frameUpdateList) do
			if updateSpecifier == 'all' or specifier == updateSpecifier then
				-- these are the frames that were reset to defaults just now
				for index, frame in ipairs(frames) do
					if frame:IsObjectType('Button') then
						-- simple unit frames
						addon.SetupCompactUnitFrame(frame, style)
					else
						-- group frames, containing unit frames
						for index = 1, _G.MEMBERS_PER_RAID_GROUP do
							addon.SetupCompactUnitFrame(_G[frame:GetName()..'Member'..index], 'normal')
						end
					end
				end
			end
		end
	end)

	-- @see http://www.townlong-yak.com/framexml/18291/CompactUnitFrame.lua#241
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", addon.UpdateHealthColor)
	hooksecurefunc("CompactUnitFrame_UpdatePowerColor", addon.UpdatePowerColor)
	hooksecurefunc("CompactUnitFrame_UpdateName", addon.UpdateName)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", addon.UpdateStatusText)
	hooksecurefunc("CompactUnitFrame_UpdateBuffs", addon.UpdateBuffs)
	-- hooksecurefunc("CompactUnitFrame_UpdateDebuffs", addon.UpdateDebuffs)
	-- hooksecurefunc("CompactUnitFrame_UpdateDispellableDebuffs", addon.UpdateDispellableDebuffs)
	hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", addon.UpdateCenterStatusIcon)
	hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", addon.UpdateRoleIcon)
	-- hooksecurefunc("CompactUnitFrame_SetUpClicks", addon.SetUpClicks)

	-- @see: http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua
	local manager = CompactRaidFrameManager
	addon:SetupManager(manager)
	-- unlink container from manager
	-- manager.container:SetParent(UIParent)

	-- @see http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameContainer.lua
	-- local container = CompactRaidFrameContainer
	-- these all cause taint ...
	--[[ FlowContainer_SetHorizontalSpacing(container, addon.db.profile.unitframe.spacingX or 0)
	FlowContainer_SetVerticalSpacing(container, addon.db.profile.unitframe.spacingY or 0)
	FlowContainer_SetMaxPerLine(container, addon.db.profile.unitframe.numPerLine or nil)
	FlowContainer_SetOrientation(container, addon.db.profile.unitframe.orientation or 'vertical')
	hooksecurefunc('CompactRaidFrameContainer_AddGroups', function(self)
		FlowContainer_SetOrientation(container, addon.db.profile.unitframe.orientation or 'vertical')
	end) --]]

	-- addon:SetupAutoActivate()
	-- self:RegisterEvent('GROUP_ROSTER_UPDATE', CompactUnitFrameProfiles_CheckAutoActivation)
	-- self:RegisterEvent('GROUP_JOINED', CompactUnitFrameProfiles_CheckAutoActivation)

	-- we need to update any already existing unit frames
	self:Update()

	-- register with ConfigMode
	local containerWasLocked
	CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}
	CONFIGMODE_CALLBACKS["Blizzard - CompactRaidFrame"] = function(action)
		if action == "ON" then
			containerWasLocked = not CompactRaidFrameManagerDisplayFrameLockedModeToggle.lockMode
			if containerWasLocked then
				CompactRaidFrameManager:Show()
				CompactRaidFrameContainer:Show()
				CompactRaidFrameManager_UnlockContainer(CompactRaidFrameManager)
			end
		elseif action == "OFF" and containerWasLocked then
			CompactRaidFrameManager_SetSetting("Locked", 1)
			CompactRaidFrameManager_LockContainer(CompactRaidFrameManager)
			CompactRaidFrameManager_UpdateShown(CompactRaidFrameManager)
			containerWasLocked = nil
		end
	end
end

function addon:Update()
	local container = _G.CompactRaidFrameContainer
	CompactRaidFrameContainer_ApplyToFrames(container, 'normal', function(unitFrame)
		addon.SetupCompactUnitFrame(unitFrame, 'normal', true)
		CompactUnitFrame_UpdateAll(unitFrame)
	end)
	CompactRaidFrameContainer_ApplyToFrames(container, 'mini', function(unitFrame)
		addon.SetupCompactUnitFrame(unitFrame, 'mini', true)
		CompactUnitFrame_UpdateAll(unitFrame)
	end)
end

function addon:OnDisable()
	-- TODO
	self:UnregisterEvent('GROUP_ROSTER_UPDATE')
	self:UnregisterEvent('GROUP_JOINED')
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

-- --------------------------------------------------------
--  LoadWith
-- --------------------------------------------------------
local loadWith = {}
function addon:LoadWith(otherAddon, handler, remove)
	if remove then
		if loadWith[otherAddon] then
			for index, callback in pairs(loadWith[otherAddon]) do
				if callback == handler then
					loadWith[otherAddon][index] = nil
					if not next(loadWith[otherAddon]) then
						loadWith[otherAddon] = nil
					end
					if not next(loadWith) then
						self:UnregisterEvent('ADDON_LOADED')
					end
					return true
				end
			end
		end
		return
	end

	if IsAddOnLoaded(otherAddon) then
		-- addon is available, directly run handler code
		return handler(self, nil, otherAddon)
	else
		if loadWith[otherAddon] then
			for _, callback in pairs(loadWith[otherAddon]) do
				if callback == handler then
					return
				end
			end
		end
		-- handler is not yet registered
		if not loadWith[otherAddon] then loadWith[otherAddon] = {} end
		tinsert(loadWith[otherAddon], handler)
		self:RegisterEvent('ADDON_LOADED')
	end
end
function addon:ADDON_LOADED(event, arg1)
	if loadWith[arg1] then
		for key, callback in pairs(loadWith[arg1]) do
			if callback(self, event, arg1) then
				-- handler succeeded, remove from task list
				loadWith[arg1][key] = nil
				if not next(loadWith[arg1]) then
					loadWith[arg1] = nil
				end
			end
		end
	end
	if not next(loadWith) then
		self:UnregisterEvent('ADDON_LOADED')
	end
end
addon:RegisterEvent('ADDON_LOADED')
