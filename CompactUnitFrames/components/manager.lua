local addonName, addon, _ = ...

-- GLOBALS: _G, DefaultCompactUnitFrameSetupOptions, hooksecurefunc
-- GLOBALS: FlowContainer_ResumeUpdates, FlowContainer_PauseUpdates, FlowContainer_GetUsedBounds, FlowContainer_AddObject, FlowContainer_AddSpacer, FlowContainer_AddLineBreak
-- GLOBALS: CompactRaidFrameManager_OnEvent, CompactRaidFrameManager_OnLoad, CompactRaidFrameManager_UpdateShown, CompactRaidFrameManager_GetSetting, CompactRaidFrameManager_ResizeFrame_UpdateContainerSize, CompactRaidFrameManager_UnlockContainer, CompactRaidFrameManagerDisplayFrameLockedModeToggle, GetDisplayedAllyFrames
local manager = _G.CompactRaidFrameManager
local floor, ceil = math.floor, math.ceil

function addon:Manager_DisableCUF(disable)
	local isHooked = manager:IsEventRegistered("UNIT_FLAGS")

	if disable and isHooked then
		manager:UnregisterAllEvents()
		manager:Hide()
		manager.container:UnregisterAllEvents()
		manager.container:Hide()
		-- HidePartyFrame()
	elseif not disable then
		if not isHooked then
			CompactRaidFrameManager_OnLoad(manager)
		end
	end
end

-- @see: http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua
function addon:SetupManager(manager)
	--[[
	addon:Manager_SetLeftBorder()
	addon:Manager_DisableCUF(addon.db.profile.frames.disableCUF)

	addon:Manager_SetAlpha(addon.db.profile.frames.pullout.passiveAlpha)
	hooksecurefunc("CompactRaidFrameManager_Expand", function(self)
		addon:Manager_SetAlpha(addon.db.profile.frames.pullout.activeAlpha)
	end)
	hooksecurefunc("CompactRaidFrameManager_Collapse", function(self)
		addon:Manager_SetAlpha(addon.db.profile.frames.pullout.passiveAlpha)
	end)
	addon:MinifyPullout(addon.db.profile.frames.pullout.minify)
	--]]

	-- "show solo" functionality
	hooksecurefunc('CompactRaidFrameManager_UpdateShown', function(self)
		if not addon.db.profile.frames.showSolo or GetDisplayedAllyFrames() then return end
		-- show manager & container
		self:Show()
		if self.container.enabled then self.container:Show() end
	end)
	hooksecurefunc('CompactRaidFrameManager_UpdateOptionsFlowContainer', function(self)
		if not addon.db.profile.frames.showSolo or GetDisplayedAllyFrames() then return end
		-- show & update side panel
		local container = self.displayFrame.optionsFlowContainer
		FlowContainer_PauseUpdates(container)

		-- profile selector
		FlowContainer_AddLineBreak(container)
		FlowContainer_AddObject(container, self.displayFrame.profileSelector)
    	self.displayFrame.profileSelector:Show()

    	-- not shown: filter options, raid markers, leader options, convert to raid

    	-- lock / unlock
		FlowContainer_AddLineBreak(container)
		FlowContainer_AddSpacer(container, 20)
		FlowContainer_AddObject(container, self.displayFrame.lockedModeToggle)
		FlowContainer_AddObject(container, self.displayFrame.hiddenModeToggle)
		self.displayFrame.lockedModeToggle:Show()
		self.displayFrame.hiddenModeToggle:Show()
		-- not shown: all assist

		FlowContainer_ResumeUpdates(container)

		-- fix size
		local usedX, usedY = FlowContainer_GetUsedBounds(container)
  		self:SetHeight(usedY + 40)
	end)
	hooksecurefunc('CompactUnitFrameProfiles_ApplyCurrentSettings', function()
		if not addon.db.profile.frames.showSolo or GetDisplayedAllyFrames() then return end
		CompactRaidFrameManager_UpdateShown(manager)
	end)
	hooksecurefunc('CompactRaidFrameManager_UpdateContainerLockVisibility', function(self)
		if not addon.db.profile.frames.showSolo or GetDisplayedAllyFrames() then return end
		-- restore manager settings if <show solo>
		if CompactRaidFrameManagerDisplayFrameLockedModeToggle.lockMode then
			CompactRaidFrameManager_UnlockContainer(self)
		end
	end)

	-- fix container snapping to weird sizes (hint: actual CRF1:GetHeight() >= DefaultCompactUnitFrameSetupOptions.height)
	local RESIZE_VERTICAL_OUTSETS = 7
	local function FixHeight(self)
		if CompactRaidFrameManager_GetSetting('KeepGroupsTogether') == '1' or InCombatLockdown() then return end
		local resizerHeight   = self.containerResizeFrame:GetHeight() - RESIZE_VERTICAL_OUTSETS * 2
		local unitFrameHeight = DefaultCompactUnitFrameSetupOptions.height
		      unitFrameHeight = ceil(unitFrameHeight + (self.container.flowVerticalSpacing or 0))
		local newHeight = unitFrameHeight * floor(resizerHeight / unitFrameHeight) + 1
		self.container:SetHeight(newHeight)
	end
	hooksecurefunc('CompactRaidFrameManager_ResizeFrame_UpdateContainerSize', FixHeight)

	-- trigger manager updates
	FixHeight(CompactRaidFrameManager)
	-- CompactRaidFrameManager_OnEvent(manager, 'GROUP_ROSTER_UPDATE')
	-- CompactRaidFrameManager_ResizeFrame_UpdateContainerSize(manager)
end

function addon:Manager_SetAlpha(alpha)
	manager:SetAlpha(alpha or 1)
end

function addon:Manager_SetLeftBorder()
	-- recreate left border (commented out by Blizzard)
	if not _G['CompactRaidFrameManagerBorderLeft'] then
		local borderLeft = manager:CreateTexture("CompactRaidFrameManagerBorderLeft")
		borderLeft:SetSize(10, 0)
		borderLeft:SetPoint("TOPLEFT", _G["CompactRaidFrameManagerBorderTopLeft"], "BOTTOMLEFT", 1, 0)
		borderLeft:SetPoint("BOTTOMLEFT", _G["CompactRaidFrameManagerBorderBottomLeft"], "TOPLEFT", -1, 0)
		borderLeft:SetTexture("Interface\\RaidFrame\\RaidPanel-Left")
		borderLeft:SetVertTile(true)
	end
end

function addon:MinifyPullout(enable)
	local borderParts = { 'BorderTop', 'BorderBottom', --[['BorderLeft', 'BorderRight',]]
		'BorderTopLeft', 'BorderBottomLeft', --[['BorderTopRight', 'BorderBottomRight' ]]
	} -- what's commented here will *not* be hidden later

	if enable then
		local widthSmall, heightSmall, widthDefault = 16, 44, 200
		local function SetCRFManagerSize(self)
			if self.collapsed then
				self:SetWidth(widthSmall)
				self:SetHeight(heightSmall)
			else
				local currentHeight = 84
				if self.displayFrame.filterOptions:IsShown() then
					currentHeight = currentHeight + self.displayFrame.filterOptions:GetHeight()
				end
				if self.displayFrame.leaderOptions:IsShown() then
					currentHeight = currentHeight + self.displayFrame.leaderOptions:GetHeight()
				end
				self:SetSize(widthDefault, currentHeight)
			end
		end
		-- [TODO]
		--[[hooksecurefunc("CompactRaidFrameManager_Expand", function(self)
			self:SetAlpha(1)
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (addon.db.profile.frames.pullout.posX or 0) -7, addon.db.profile.frames.pullout.posY or -140)
			for _, region in ipairs( borderParts ) do
				_G['CompactRaidFrameManager'..region]:Show()
			end
			SetCRFManagerSize(self)

			self.toggleButton:GetNormalTexture():SetTexCoord(0.5, 1, 0, 1)
			self.toggleButton:SetPoint("RIGHT", -9, 0)
			self.toggleButton:SetSize(16, 64)
		end)
		hooksecurefunc("CompactRaidFrameManager_Collapse", function(self)
			self:SetAlpha(addon.db.profile.frames.pullout.alpha or 1)
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", addon.db.profile.frames.pullout.posX or 0, addon.db.profile.frames.pullout.posY or -140)
			SetCRFManagerSize(self)

			for _, region in ipairs( borderParts ) do
				_G['CompactRaidFrameManager'..region]:Hide()
			end

			self.toggleButton:GetNormalTexture():SetTexCoord(0.1, 0.5, 0.3, 0.7)
			self.toggleButton:SetPoint("RIGHT", -6, 1)
			self.toggleButton:SetSize(16, 32)
		end)--]]
		-- hooksecurefunc("CompactRaidFrameManager_UpdateLeaderButtonsShown", SetCRFManagerSize)
		-- CompactRaidFrameManager_Collapse( CompactRaidFrameManager )
	end
end
