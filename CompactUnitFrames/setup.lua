local _, ns = ...

-- GLOBALS: UIParent. CompactRaidFrameManager, CompactRaidFrameContainer, DefaultCompactUnitFrameSetupOptions
-- GLOBALS: UnitBuff, UnitIsPVP, UnitIsConnected, UnitIsFriend, DebuffTypeColor, CompactUnitFrame_UpdateSelectionHighlight, CompactUnitFrame_UtilShouldDisplayBuff, CompactUnitFrame_UtilSetBuff, CompactUnitFrame_HideAllBuffs, FlowContainer_SetHorizontalSpacing, FlowContainer_SetVerticalSpacing, CompactRaidFrameManager_GetSetting
-- GLOBALS: hooksecurefunc, pairs, type, floor

-- @see: http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua
function ns.SetupManager(manager)
	--[[
	-- unlink container from manager
	CompactRaidFrameManager.container:SetParent(UIParent)

	ns:Manager_SetLeftBorder()
	ns:Manager_DisableCUF(ns.db.frames.disableCUF)

	ns:Manager_SetAlpha(ns.db.frames.pullout.passiveAlpha)
	hooksecurefunc("CompactRaidFrameManager_Expand", function(self)
		ns:Manager_SetAlpha(ns.db.frames.pullout.activeAlpha)
	end)
	hooksecurefunc("CompactRaidFrameManager_Collapse", function(self)
		ns:Manager_SetAlpha(ns.db.frames.pullout.passiveAlpha)
	end)
	ns:MinifyPullout(ns.db.frames.pullout.minify)
	--]]

	-- "show solo" functionality
	hooksecurefunc('CompactRaidFrameManager_UpdateShown', function(self)
		if not ns.db.frames.showSolo or GetDisplayedAllyFrames() then return end
		-- show manager & container
		self:Show()
		if self.container.enabled then self.container:Show() end
	end)
	hooksecurefunc('CompactRaidFrameManager_UpdateContainerLockVisibility', function(self)
		if not ns.db.frames.showSolo or GetDisplayedAllyFrames() then return end
		-- restore manager settings if <show solo>
		if CompactRaidFrameManagerDisplayFrameLockedModeToggle.lockMode then
			CompactRaidFrameManager_UnlockContainer(self)
		end
	end)
	hooksecurefunc('CompactRaidFrameManager_UpdateOptionsFlowContainer', function(self)
		if not ns.db.frames.showSolo or GetDisplayedAllyFrames() then return end
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
		CompactRaidFrameManager_UpdateShown(manager)
	end)

	-- fix container snapping to weird sizes (hint: actual CRF1:GetHeight() ~= DefaultCompactUnitFrameSetupOptions.height)
	local RESIZE_VERTICAL_OUTSETS = 7
	hooksecurefunc('CompactRaidFrameManager_ResizeFrame_UpdateContainerSize', function(self)
		if CompactRaidFrameManager_GetSetting('KeepGroupsTogether') == '1' then return end
		local resizerHeight   = self.containerResizeFrame:GetHeight() - RESIZE_VERTICAL_OUTSETS * 2
		local unitFrameHeight = DefaultCompactUnitFrameSetupOptions.height
		      unitFrameHeight = math.ceil(unitFrameHeight + (self.container.flowVerticalSpacing or 0))
		local newHeight = unitFrameHeight * floor(resizerHeight / unitFrameHeight)
		self.container:SetHeight(newHeight)
	end)

	-- trigger manager updates
	CompactRaidFrameManager_OnEvent(manager, 'GROUP_ROSTER_UPDATE')
	CompactRaidFrameManager_ResizeFrame_UpdateContainerSize(manager)
end

-- @see http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameContainer.lua
function ns.SetupContainer(container)
	--[[ these all cause taint ...
	FlowContainer_SetHorizontalSpacing(container, ns.db.unitframe.spacingX or 0)
	FlowContainer_SetVerticalSpacing(container, ns.db.unitframe.spacingY or 0)
	FlowContainer_SetMaxPerLine(container, ns.db.unitframe.numPerLine or nil)
	FlowContainer_SetOrientation(container, ns.db.unitframe.orientation or 'vertical')
	hooksecurefunc('CompactRaidFrameContainer_AddGroups', function(self)
		FlowContainer_SetOrientation(container, ns.db.unitframe.orientation or 'vertical')
	end) --]]

	-- we need to update any already existing unit frames
	CompactRaidFrameContainer_ApplyToFrames(container, 'normal', function(unitFrame)
		ns.SetupCompactUnitFrame(unitFrame, 'normal', true)
		CompactUnitFrame_UpdateAll(unitFrame)
	end)
	CompactRaidFrameContainer_ApplyToFrames(container, 'mini', function(unitFrame)
		ns.SetupCompactUnitFrame(unitFrame, 'mini', true)
		CompactUnitFrame_UpdateAll(unitFrame)
	end)
end

function ns.SetupUnitFrameHooks()
	-- this function gets called once per unit frame
	hooksecurefunc('CompactUnitFrame_SetUpFrame', function(frame, func)
		local style = (func == DefaultCompactUnitFrameSetup and 'normal') or (func == DefaultCompactMiniFrameSetup and 'mini')
		if not style then return end
		ns.SetupCompactUnitFrame(frame, style, true)
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
						ns.SetupCompactUnitFrame(frame, style)
					else
						-- group frames, containing unit frames
						for index = 1, MEMBERS_PER_RAID_GROUP do
							ns.SetupCompactUnitFrame(_G[frame:GetName()..'Member'..index], 'normal')
						end
					end
				end
			end
		end
	end)

	-- find more functions here: http://wow.go-hero.net/framexml/16992/CompactUnitFrame.lua#238
	-- hooksecurefunc("CompactUnitFrame_UpdateVisible", ns.SetupCompactUnitFrame)
	-- hooksecurefunc("CompactUnitFrame_SetUpClicks", ns.SetUpClicks)
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ns.UpdateHealthColor) -- taint, prevents positioning
	hooksecurefunc("CompactUnitFrame_UpdatePowerColor", ns.UpdatePowerColor)   -- major taint, prevents creation
	hooksecurefunc("CompactUnitFrame_UpdateName", ns.UpdateName)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", ns.CUF_SetStatusText)
	hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", ns.UpdateCenterStatusIcon)
end

function ns.SetupCompactUnitFrame(frame, style, isFirstSetup)
	if not style or (style ~= 'normal' and style ~= 'mini') then return end
	-- bar orientation
	-- ns.CUF_SetHealthBarVertical(frame, ns.db.health.vertical)
	-- ns.CUF_SetPowerBarVertical(frame, ns.db.power.vertical, ns.db.power.changePosition)
	-- ns.CUF_SetSeperatorVertical(frame, ns.db.power.vertical, ns.db.power.changePosition)

	-- selectionHighlight + aggroHighlight (texture, coords, position)
	-- borders (horizTopBorder, horizBottomBorder, verLeftBorder, vertRightBorder, horizDivider: texture, height/width, position)

	-- frame size, background (texture, coords)
	ns.CUF_SetFrameBGTexture(frame, ns.db.unitframe.bgtexture)
	ns.CUF_SetFrameBGColor(frame, ns:GetColorSetting( ns.db.unitframe.bgcolor, frame.unit ))

	-- healthBar (position, statusbartexture)
	ns.CUF_SetHealthTexture(frame, ns.db.health.texture)
	if isFirstSetup then
		ns.CUF_SetHealthBGTexture(frame, ns.db.health.bgtexture)
		ns.CUF_SetHealthBGColor(frame, ns:GetColorSetting( ns.db.health.bgcolor, frame.unit ))
	end

	-- name (position, justifyH)
	frame.name:SetJustifyH(ns.db.name.justifyH or 'LEFT')
	if isFirstSetup and (ns.db.name.font or ns.db.name.fontSize or ns.db.name.fontStyle) then
		local defaultFont, defaultSize, defaultStyle = frame.name:GetFont()
		frame.name:SetFont(ns.db.name.font or defaultFont, ns.db.name.fontSize or defaultSize, ns.db.name.fontStyle or defaultStyle)
	end

	-- overAbsorbGlow (texture, blendMode, position, width)
	frame.overAbsorbGlow:SetWidth(4)
	frame.overAbsorbGlow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -2, 0)
	frame.overAbsorbGlow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -2, 0)
	-- totalAbsorbOverlay (texture, .tileSize)
	frame.totalAbsorbOverlay:SetTexture(nil)
	-- overHealAbsorbGlow (texture, blendMode, position, width)
	-- myAbsorb + totalAbsorb (texture), myHealPrediction + otherHealPrediction (texture, gradient)

	if style == 'normal' then
		-- powerBar (position, statusbartexture, backgroundTex, show/hide)
		ns.CUF_SetPowerTexture(frame, ns.db.power.texture)
		if isFirstSetup then
			ns.CUF_SetPowerBGTexture(frame, ns.db.power.bgtexture)
			ns.CUF_SetPowerBGColor(frame, ns:GetColorSetting(ns.db.power.bgcolor, frame.unit))
		end

		-- roleIcon (position, size)
		ns.CUF_SetRoleIconSize(frame, ns.db.unitframe.roleIconSize)
		-- frame.roleIcon:ClearAllPoints()
		-- frame.roleIcon:SetPoint("TOPLEFT", frame.healthBar, 3, -2)

		-- statusText (fontSize, position, height)
		ns.CUF_SetStatusColor(frame, ns:GetColorSetting(ns.db.status.color, frame.unit))
		if ns.db.status.font or ns.db.status.fontSize or ns.db.status.fontStyle then
			local defaultFont, defaultSize, defaultStyle = frame.statusText:GetFont()
			frame.statusText:SetFont(ns.db.status.font or defaultFont, ns.db.status.fontSize or defaultSize, ns.db.status.fontStyle or defaultStyle)
		end

		-- CompactUnitFrame_SetMaxBuffs, CompactUnitFrame_SetMaxDebuffs, CompactUnitFrame_SetMaxDispelDebuffs(frame, 3)
		-- buffFrames (position, size)
		-- debuffFrames (position, size copied from buffFrames)
		-- dispelDebuffFrames (position, size)
		-- frame.buffFrames[1]:ClearAllPoints()
		-- frame.buffFrames[1]:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", -1*(ns.db.buffs.posX or 3), (ns.db.buffs.posY or 0))
		-- frame.debuffFrames[1]:ClearAllPoints()
		-- frame.debuffFrames[1]:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", ns.db.debuffs.posX or 3, ns.db.debuffs.posY or 0)
		-- frame.dispelDebuffFrames[1]:SetPoint("TOPRIGHT", frame.healthBar, -3, -2)

		-- readyCheckIcon (position, size)
		-- centerStatusIcon (position, size (2*buffSize))

		if isFirstSetup and ns.db.unitframe.enableOverlay then -- and not frame.Overlay then
			local overlay = CreateFrame("Button", "$parentCUFOverlay", frame, "CompactAuraTemplate")
			      overlay:SetPoint('CENTER', ns.db.indicators.center.posX or 0, ns.db.indicators.center.posY or 0)
			      overlay:SetSize(20, 20)
			      overlay:EnableMouse(false)
			      overlay:EnableMouseWheel(false)
			      overlay:Hide()
			frame.Overlay = overlay
			ns.EnableOverlay(frame)
		end

		if isFirstSetup and ns.db.unitframe.enableGPS then -- and not frame.GPS then
			local gps = CreateFrame("Frame", nil, frame.healthBar)
			      gps:SetPoint('CENTER')
			      gps:SetSize(40, 40)
			      gps:Hide()
			local tex = gps:CreateTexture("OVERLAY")
			      tex:SetTexture("Interface\\Minimap\\Minimap-QuestArrow") -- DeadArrow
			      tex:SetAllPoints()
			gps.outOfRange = ns.db.unitframe.gpsOutOfRange
			gps.onMouseOver = ns.db.unitframe.gpsOnHover
			frame.GPS = gps
			frame.GPS.Texture = tex -- .Text is also possible
			ns.EnableGPS(frame)
		end
	end

	if isFirstSetup and not frame:IsEventRegistered("UNIT_FACTION") then
		frame:RegisterEvent("UNIT_FACTION")
		-- frame:RegisterEvent("UNIT_FLAGS")
		-- frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		frame:RegisterEvent("PLAYER_CONTROL_LOST")
		frame:RegisterEvent("PLAYER_CONTROL_GAINED")

		frame:HookScript("OnEvent", function(self, event, unit)
			-- ns.Print('event', event, unit, self:GetName())
			if not unit or unit == self.unit and event == 'UNIT_FACTION' then
				-- (event == "UNIT_FACTION" or event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED") then
				-- ns.Print("Updating PVP/Faction of", unit, UnitName(unit), UnitFactionGroup(unit), UnitIsPVP(unit), UnitIsPVPFreeForAll(unit))
				ns.UpdateHealthColor(self)
			end
		end)
	end
end

function ns.UpdateHealthColor(frame)
	if not frame or type(frame) ~= "table" then return end

	local r, g, b
	if not frame.unit then
		r, g, b = ns:GetColorSetting(ns.db.health.bgcolor, frame.unit)
	elseif UnitCanAttack("player", frame.unit) or UnitIsEnemy("player", frame.unit) then
		r, g, b = ns:GetColorSetting(ns.db.health.isEnemyColor, frame.unit)
	elseif not UnitIsPVP("player") and UnitIsPVP(frame.unit) then
		r, g, b = ns:GetColorSetting(ns.db.health.flagsAsPvPColor, frame.unit)
	else
		r, g, b = ns:GetColorSetting(ns.db.health.color, frame.unit)
	end
	frame.healthBar:SetStatusBarColor(r, g, b)
end
function ns.UpdatePowerColor(frame)
	if not frame or type(frame) ~= "table" then return end
	local unit = frame.unit or frame.displayedUnit

	local displayPowerBar = ns:ShouldDisplayPowerBar(frame)
	ns.CUF_SetPowerBarShown(frame, displayPowerBar)

	local r, g, b = ns:GetColorSetting( ns.db.power.color, frame.unit )
	if r and (not unit or UnitIsConnected(unit)) then
		frame.powerBar:SetStatusBarColor(r, g, b)
	end
end
function ns.UpdateNameColor(frame)
	local r, g, b = ns:GetColorSetting(ns.db.name.color, frame.unit)
	ns.CUF_SetNameColor(frame, r, g, b)
end
function ns.UpdateName(frame)
	if not frame or type(frame) ~= "table" then return end

	ns.CUF_SetNameText(frame, ns.db.name.size)
	ns.UpdateNameColor(frame)
end
function ns.UpdateCenterStatusIcon(frame)
	-- try to fix sticky incoming ressurect icon
	if not frame.centerStatusIcon:IsShown() or not frame.optionTable.displayIncomingResurrect then return end
	if UnitHasIncomingResurrection(frame.unit) and not UnitIsDead(frame.unit) then
		frame.centerStatusIcon:Hide()
	end
end
function ns.UpdateAuras(frame)
	if ( not frame.optionTable.displayBuffs ) then
		CompactUnitFrame_HideAllBuffs(frame);
		return;
	end

	local index, frameNum, filter = 1, 1, nil
	while frameNum <= frame.maxBuffs do
		local buffName = UnitBuff(frame.displayedUnit, index, filter)
		if buffName then
			if CompactUnitFrame_UtilShouldDisplayBuff(frame.displayedUnit, index, filter)
				and ns:ShouldDisplayAura(true, frame.displayedUnit, buffName, filter) then

				local buffFrame = frame.buffFrames[frameNum]
				CompactUnitFrame_UtilSetBuff(buffFrame, frame.displayedUnit, index, filter)
				frameNum = frameNum + 1
			end
		else
			break
		end
		index = index + 1
	end
	for i=frameNum, frame.maxBuffs do
		local buffFrame = frame.buffFrames[i]
		buffFrame:Hide()
	end
end

function ns.SetUpClicks(frame)
	-- FIXME: causes taint too easily, use Clique or similar if you really need the feature
	if ns.DelayInCombat(frame, ns.SetUpClicks) then return end
	-- frame:SetAttribute("*type2", 'togglemenu')
	-- works with either menu or togglemenu. blizz uses menu, so stick to that
	local combatMenu = ns.db.unitframe.noMenuClickInCombat and "" or "menu"
	RegisterAttributeDriver(frame, "*type2", "[nocombat] menu; "..combatMenu)--]]
end
local debuffTypes = { Magic = true, Curse = true, Disease = true, Poison = true}
function ns.ShowDebuffBorders(dispellDebuffFrame, debuffType, index)
	local frame = dispellDebuffFrame:GetParent()

	if ns.db.indicators.showDispellBorder then
		local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]

		frame.selectionHighlight:SetVertexColor(color.r, color.g, color.b)
		frame.selectionHighlight:Show()
	end
	if ns.db.indicators.hideDispellIcons then
		dispellDebuffFrame:Hide()
	end
end
function ns.HideDebuffBorders(frame)
	local hasDebuff
	for debuffType,_ in pairs(debuffTypes) do
		if frame["hasDispel"..debuffType] then
			hasDebuff = debuffType
		end
	end
	if not hasDebuff then
		frame.selectionHighlight:Hide()
		frame.selectionHighlight:SetVertexColor(1, 1, 1)
		CompactUnitFrame_UpdateSelectionHighlight(frame)
	end
end
