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
	end) --]]

	-- ns:MinifyPullout(ns.db.frames.pullout.minify)
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
end

--[[ function ns:ContainerSetup()
	local frame = CompactRaidFrameContainer
	FlowContainer_SetHorizontalSpacing(frame, ns.db.unitframe.spacingX or 0)
	FlowContainer_SetVerticalSpacing(frame, ns.db.unitframe.spacingY or 0)
	FlowContainer_SetMaxPerLine(frame, ns.db.unitframe.numPerLine or nil)
	FlowContainer_SetOrientation(frame, ns.db.unitframe.orientation or "vertical")
end
--]]

function ns.RegisterHooks()
	-- find more functions here: http://wow.go-hero.net/framexml/16992/CompactUnitFrame.lua#238
	hooksecurefunc("CompactUnitFrame_UpdateVisible", ns.UpdateVisible)
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ns.UpdateHealthColor)
	hooksecurefunc("CompactUnitFrame_UpdatePowerColor", ns.UpdatePowerColor)
	hooksecurefunc("CompactUnitFrame_UpdateName", ns.UpdateName)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", ns.UpdateStatus)

	hooksecurefunc("CompactUnitFrame_SetUpClicks", ns.SetUpClicks)
	hooksecurefunc("CompactUnitFrame_OnUpdate", ns.OnUpdate)

	--[[
	CompactRaidFrameContainer_SetDisplayPets(CompactRaidFrameContainer, false)
	hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", function(self)
		FlowContainer_AddLineBreak(self)
		CompactRaidFrameContainer_AddPets(self)
	end) --]]

	hooksecurefunc("CompactRaidFrameManager_ResizeFrame_UpdateContainerSize", function(manager)
		if CompactRaidFrameManager_GetSetting("KeepGroupsTogether") == "1" then return end

		local resizerHeight = manager.containerResizeFrame:GetHeight()
		local unitFrameHeight = DefaultCompactUnitFrameSetupOptions.height
		local spacing = 1 +
			(  (manager.container.flowOrientation == 'vertical' and manager.container.flowVerticalSpacing)
			or (manager.container.flowOrientation == 'horizontal' and manager.container.flowHorizontalSpacing)
			or 0)
		local newHeight = (unitFrameHeight + spacing) * floor(resizerHeight / unitFrameHeight)

		--[[local blizz_unitFrameHeight = DefaultCompactUnitFrameSetupOptions.height;
		local blizz_resizerHeight = manager.containerResizeFrame:GetHeight() - RESIZE_VERTICAL_OUTSETS * 2;
		local blizz_newHeight = blizz_unitFrameHeight * math.floor(resizerHeight / blizz_unitFrameHeight)
		print("Resizing", newHeight, blizz_newHeight, blizz_unitFrameHeight, blizz_resizerHeight)--]]

		manager.container:SetHeight(newHeight)
	end)
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
	if ns.db.unitframe.enableGPS and not frame.GPS then
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

function ns.UpdateHealthColor(frame)
	if not frame or type(frame) ~= "table" then return end

	local r, g, b
	if not frame.unit then
		r, g, b = ns:GetColorSetting(ns.db.health.bgcolor, frame.unit)
	elseif (not UnitIsPVP("player") and UnitIsPVP(frame.unit))
		or not UnitIsFriend("player", frame.unit) then
		r, g, b = ns:GetColorSetting(ns.db.health.flagsAsPvPColor, frame.unit)
	else
		r, g, b = ns:GetColorSetting(ns.db.health.color, frame.unit)
	end

	if r and r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b then
		frame.healthBar:SetStatusBarColor(r, g, b)
		frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b
	end
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

function ns.OnUpdate(frame, elapsed)
	ns.UpdateHealthColor(frame)
end

function ns.SetUpClicks(frame)
	if ns.DelayInCombat(frame, ns.SetUpClicks) then return end
	local combatMenu = ns.db.unitframe.noMenuClickInCombat and "" or "menu"
	RegisterAttributeDriver(frame, "*type2", "[nocombat] menu; "..combatMenu)
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
