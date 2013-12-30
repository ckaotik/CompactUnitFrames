local _, ns = ...

-- GLOBALS: UIParent. CompactRaidFrameManager, CompactRaidFrameContainer, DefaultCompactUnitFrameSetupOptions
-- GLOBALS: UnitBuff, UnitIsPVP, UnitIsConnected, UnitIsFriend, DebuffTypeColor, CompactUnitFrame_UpdateSelectionHighlight, CompactUnitFrame_UtilShouldDisplayBuff, CompactUnitFrame_UtilSetBuff, CompactUnitFrame_HideAllBuffs, FlowContainer_SetHorizontalSpacing, FlowContainer_SetVerticalSpacing, CompactRaidFrameManager_GetSetting
-- GLOBALS: hooksecurefunc, pairs, type, floor

function ns.ManagerSetup()
	-- see: http://wow.go-hero.net/framexml/14545/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua
	-- if InCombatLockdown() then return end
	-- unlink unit frames from manager
	-- CompactRaidFrameManager.container:SetParent(UIParent)

	-- ns:Manager_SetLeftBorder()
	-- ns:Manager_DisableCUF(ns.db.frames.disableCUF)

	--[[ ns:Manager_SetAlpha(ns.db.frames.pullout.passiveAlpha)
	hooksecurefunc("CompactRaidFrameManager_Expand", function(self)
		ns:Manager_SetAlpha(ns.db.frames.pullout.activeAlpha)
	end)
	hooksecurefunc("CompactRaidFrameManager_Collapse", function(self)
		ns:Manager_SetAlpha(ns.db.frames.pullout.passiveAlpha)
	end)
	ns:MinifyPullout(ns.db.frames.pullout.minify) --]]

	-- restore manager settings if <show solo>
	hooksecurefunc("CompactRaidFrameManager_UpdateContainerLockVisibility", function(self)
		if ns.db.frames.showSolo and CompactRaidFrameManagerDisplayFrameLockedModeToggle.lockMode then
			CompactRaidFrameManager_UnlockContainer(self)
		end
	end)
	hooksecurefunc("CompactRaidFrameManager_UpdateOptionsFlowContainer", function(self)
		if not ns.db.frames.showSolo or GetDisplayedAllyFrames() then return end
		-- settings: profile selector, filter options, raid markers, leader options, convert to raid, lock/unlock, all assist
		local container = self.displayFrame.optionsFlowContainer
		FlowContainer_PauseUpdates(container)

		-- profile selector
		FlowContainer_AddLineBreak(container)
		FlowContainer_AddObject(container, self.displayFrame.profileSelector)
    	self.displayFrame.profileSelector:Show()

    	-- lock / unlock
		FlowContainer_AddLineBreak(container)
		FlowContainer_AddSpacer(container, 20)
		FlowContainer_AddObject(container, self.displayFrame.lockedModeToggle)
		FlowContainer_AddObject(container, self.displayFrame.hiddenModeToggle)
		self.displayFrame.lockedModeToggle:Show()
		self.displayFrame.hiddenModeToggle:Show()

		FlowContainer_ResumeUpdates(container)

		-- fix size
		local usedX, usedY = FlowContainer_GetUsedBounds(container)
  		self:SetHeight(usedY + 40)
	end)

	-- update actual container size so we can anchor differently
	--[[
	hooksecurefunc("CompactRaidFrameContainer_UpdateBorder", function(self)
		local usedX, usedY = FlowContainer_GetUsedBounds(self)
		self:SetSize(usedX, usedY)
	end)
	--]]

	-- show solo functionality
	hooksecurefunc("CompactRaidFrameManager_UpdateShown", function(self)
		if ns.db.frames.showSolo then
			self:Show()
		end
	end)
	hooksecurefunc("CompactRaidFrameManager_UpdateContainerVisibility", function()
		local container = CompactRaidFrameContainer
		if ns.db.frames.showSolo and container.enabled then
			container:Show()
		end
	end)
	CompactRaidFrameManager_UpdateShown(CompactRaidFrameManager)

	-- fix container snapping to weird sizes (hint: actual CRF1:GetHeight() ~= DefaultCompactUnitFrameSetupOptions.height)
	hooksecurefunc("CompactRaidFrameManager_ResizeFrame_UpdateContainerSize", function(manager)
		if CompactRaidFrameManager_GetSetting("KeepGroupsTogether") == "1" then return end

		local resizerHeight = manager.containerResizeFrame:GetHeight()
		local unitFrameHeight = DefaultCompactUnitFrameSetupOptions.height
		local spacing = manager.container.flowVerticalSpacing or 0

		-- add 1px dummy to offset rounding errors
		local newHeight = (unitFrameHeight + spacing) * floor(resizerHeight / unitFrameHeight) + 1
		manager.container:SetHeight(newHeight)
	end)
	CompactRaidFrameManager_ResizeFrame_UpdateContainerSize(CompactRaidFrameManager)

	-- we can help with ConfigMode!
	CONFIGMODE_CALLBACKS = CONFIGMODE_CALLBACKS or {}
	local containerWasLocked
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

function ns.ContainerSetup()
	local frame = CompactRaidFrameContainer
	-- FlowContainer_SetHorizontalSpacing(frame, ns.db.unitframe.spacingX or 0)
	-- FlowContainer_SetVerticalSpacing(frame, ns.db.unitframe.spacingY or 0)
	-- FlowContainer_SetMaxPerLine(frame, ns.db.unitframe.numPerLine or nil)
	-- FlowContainer_SetOrientation(frame, ns.db.unitframe.orientation or "vertical")

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
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", ns.UpdateStatus)
	hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", ns.UpdateCenterStatusIcon)
end

local defaultFont, defaultSize, defaultStyle
function ns.UpdateVisible(frame)
	if not frame:IsVisible() then return end

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
		frame:RegisterEvent("UNIT_FLAGS")
		frame:RegisterEvent("PLAYER_FLAGS_CHANGED")

		frame:HookScript("OnEvent", function(self, event, unit)
			-- ns.Print('event', event, unit, self:GetName())
			if unit == self.unit and (event == "UNIT_FACTION" or event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED") then
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
function ns.UpdateStatusColor(frame)
	local r, g, b = ns:GetColorSetting(ns.db.status.color, frame.unit)
	ns.CUF_SetStatusColor(frame, r, g, b)
end
function ns.UpdateStatus(frame)
	if not frame or type(frame) ~= "table" then return end

	ns.CUF_SetStatusText(frame)
	ns.UpdateStatusColor(frame)
end
function ns.UpdateCenterStatusIcon(frame)
	-- fix sticky incoming ressurect icon
	if ns.DelayInCombat(frame, ns.UpdateCenterStatusIcon) then return end
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
