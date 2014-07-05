local _, ns = ...

-- GLOBALS: UIParent. CompactRaidFrameManager, CompactRaidFrameContainer, DefaultCompactUnitFrameSetupOptions
-- GLOBALS: UnitBuff, UnitIsPVP, UnitIsConnected, UnitIsFriend, DebuffTypeColor, CompactUnitFrame_UpdateSelectionHighlight, CompactUnitFrame_UtilShouldDisplayBuff, CompactUnitFrame_UtilSetBuff, CompactUnitFrame_HideAllBuffs, FlowContainer_SetHorizontalSpacing, FlowContainer_SetVerticalSpacing, CompactRaidFrameManager_GetSetting
-- GLOBALS: hooksecurefunc, pairs, type, floor

-- @see: http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua
function ns.ManagerSetup()
	local manager = CompactRaidFrameManager
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
	-- @see http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua#86
	-- @see http://www.townlong-yak.com/framexml/18291/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua#510
	hooksecurefunc('CompactRaidFrameManager_UpdateShown', function(self)
		print('update shown')
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

function ns.ContainerSetup()
	local frame = CompactRaidFrameContainer
	FlowContainer_SetHorizontalSpacing(frame, ns.db.unitframe.spacingX or 0)
	FlowContainer_SetVerticalSpacing(frame, ns.db.unitframe.spacingY or 0)
	FlowContainer_SetMaxPerLine(frame, ns.db.unitframe.numPerLine or nil)
	FlowContainer_SetOrientation(frame, ns.db.unitframe.orientation or "vertical")

	--[[
	CompactRaidFrameContainer_SetDisplayPets(CompactRaidFrameContainer, false)
	hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", function(self)
		FlowContainer_AddLineBreak(self)
		CompactRaidFrameContainer_AddPets(self)
	end) --]]
end

function ns.RegisterHooks()
	-- find more functions here: http://wow.go-hero.net/framexml/16992/CompactUnitFrame.lua#238
	-- hooksecurefunc("CompactUnitFrame_SetUpClicks", ns.SetUpClicks)

	hooksecurefunc("CompactUnitFrame_UpdateVisible", ns.UpdateVisible)
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ns.UpdateHealthColor) -- taint, prevents positioning
	hooksecurefunc("CompactUnitFrame_UpdatePowerColor", ns.UpdatePowerColor)   -- major taint, prevents creation
	hooksecurefunc("CompactUnitFrame_UpdateName", ns.UpdateName)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", ns.CUF_SetStatusText)
	hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", ns.UpdateCenterStatusIcon)


	hooksecurefunc('CompactUnitFrame_SetUpFrame', function(frame, func)
		print(time(), 'CompactUnitFrame_SetUpFrame on', frame:GetName(), 'with setUpFunc', func)
	end)
	hooksecurefunc('DefaultCompactUnitFrameSetup', function(frame)
		print(time(), 'DefaultCompactUnitFrameSetup on', frame:GetName())
	end)

	-- add new units macro:
	-- /stopmacro [@mouseover,noexists]
	-- /script CompactRaidFrameContainer_AddUnitFrame(CompactRaidFrameContainer, 'mouseover', 'raid')

	-- local unitFrame = CompactRaidFrameContainer_AddUnitFrame(self, 'mouseover', 'raid') -- raid, pet, flagged, target
	-- FlowContainer_AddObject(CompactRaidFrameContainer, unitFrame)
	hooksecurefunc('FlowContainer_AddObject', function(container, frame)
		if container ~= CompactRaidFrameContainer then return end
		print('adding', frame:GetName(), 'to', container:GetName())
		ns.UpdateVisible(frame)
	end)
end

local defaultFont, defaultSize, defaultStyle
function ns.UpdateVisible(frame)
	if not frame:IsVisible() then return end

	-- fixes fuzzy edges
	frame.background:SetTexture(0, 0, 0, 1)

	--[[ Health Bar ]]--
	ns.CUF_SetHealthTexture(frame, ns.db.health.texture)
	ns.CUF_SetHealthBGTexture(frame, ns.db.health.bgtexture)
	ns.CUF_SetHealthBGColor(frame, ns:GetColorSetting( ns.db.health.bgcolor, frame.unit ))

	--[[ Power Bar ]]--
	ns.CUF_SetPowerTexture(frame, ns.db.power.texture)
	ns.CUF_SetPowerBGTexture(frame, ns.db.power.bgtexture)
	ns.CUF_SetPowerBGColor(frame, ns:GetColorSetting(ns.db.power.bgcolor, frame.unit))

	--[[ Texts ]]--
	if ns.db.name.font or ns.db.name.fontSize or ns.db.name.fontStyle then
		defaultFont, defaultSize, defaultStyle = frame.name:GetFont()
		frame.name:SetFont(ns.db.name.font or defaultFont, ns.db.name.fontSize or defaultSize, ns.db.name.fontStyle or defaultStyle)
		frame.name:SetJustifyH(ns.db.name.justifyH or 'LEFT')
	end

	ns.CUF_SetStatusColor(frame, ns:GetColorSetting(ns.db.status.color, frame.unit))
	if ns.db.status.font or ns.db.status.fontSize or ns.db.status.fontStyle then
		defaultFont, defaultSize, defaultStyle = frame.statusText:GetFont()
		frame.statusText:SetFont(ns.db.status.font or defaultFont, ns.db.status.fontSize or defaultSize, ns.db.status.fontStyle or defaultStyle)
	end

	--[[ Bar Orientation ]]--
	-- ns.CUF_SetHealthBarVertical(frame, ns.db.health.vertical)
	-- ns.CUF_SetPowerBarVertical(frame, ns.db.power.vertical, ns.db.power.changePosition)
	-- ns.CUF_SetSeperatorVertical(frame, ns.db.power.vertical, ns.db.power.changePosition)

	--[[ Auras ]]--
	--[[frame.buffFrames[1]:ClearAllPoints()
	frame.buffFrames[1]:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", -1*(ns.db.buffs.posX or 3), (ns.db.buffs.posY or 0))
	frame.debuffFrames[1]:ClearAllPoints()
	frame.debuffFrames[1]:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", ns.db.debuffs.posX or 3, ns.db.debuffs.posY or 0)
	]]--

	--[[ Icons ]]--
	-- frame.roleIcon:ClearAllPoints()
	-- frame.roleIcon:SetPoint("TOPLEFT", frame.healthBar, 3, -2)
	-- frame.dispelDebuffFrames[1]:SetPoint("TOPRIGHT", frame.healthBar, -3, -2)

	--[[ Misc Changes ]]--
	-- frame.roleIcon:SetSize(8, 8)
	-- frame.roleIcon:SetSize(0.000001, 0.000001)
	frame.totalAbsorbOverlay:SetTexture(nil)
	frame.overAbsorbGlow:SetWidth(4)
	frame.overAbsorbGlow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -2, 0)
	frame.overAbsorbGlow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -2, 0)

	-- plugins
	if ns.db.unitframe.enableGPS and not frame.GPS then -- and frame.unit and not frame.unit:find('pet') then
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

	if ns.db.unitframe.enableOverlay and not frame.Overlay and frame.unit and not frame.unit:find('pet') then
		local overlay = CreateFrame("Button", "$parentCUFOverlay", frame, "CompactAuraTemplate")
		      overlay:SetPoint('CENTER', ns.db.indicators.center.posX or 0, ns.db.indicators.center.posY or 0)
		      overlay:SetSize(20, 20)
		      overlay:EnableMouse(false)
		      overlay:EnableMouseWheel(false)
		      overlay:Hide()
		frame.Overlay = overlay
		ns.EnableOverlay(frame)
	end

	if not frame:IsEventRegistered("UNIT_FACTION") then
		frame:RegisterEvent("UNIT_FACTION")
		-- frame:RegisterEvent("UNIT_FLAGS")
		-- frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		frame:RegisterEvent("PLAYER_CONTROL_LOST")
		frame:RegisterEvent("PLAYER_CONTROL_GAINED")

		frame:HookScript("OnEvent", function(self, event, unit)
			-- ns.Print('event', event, unit, self:GetName())
			if not unit or unit == self.unit and (event == "UNIT_FACTION" or event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED") then
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
	-- fix sticky incoming ressurect icon
	if ns.DelayInCombat(frame, ns.UpdateCenterStatusIcon) or not frame.unit then return end
	if frame.centerStatusIcon:IsShown() and not frame.centerStatusIcon.tooltip then
		-- currently displaying ressurect icon
		if not UnitIsDead(frame.unit) then
			frame.centerStatusIcon:Hide()
		end
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

-- causes taint too easily, use Clique or similar if you really need the feature
function ns.SetUpClicks(frame)
	if ns.DelayInCombat(frame, ns.SetUpClicks) then return end
	-- frame:SetAttribute("*type2", 'togglemenu')
	-- works with either menu or togglemenu. blizz uses menu, so stick to that
	local combatMenu = ns.db.unitframe.noMenuClickInCombat and "" or "menu"
	RegisterAttributeDriver(frame, "*type2", "[nocombat] menu; "..combatMenu)--]]
end

function ns.DisplayDebuffType(dispellDebuffFrame, debuffType, index)
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

local debuffTypes = { Magic = true, Curse = true, Disease = true, Poison = true}
function ns.HideDisplayDebuffs(frame)
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
