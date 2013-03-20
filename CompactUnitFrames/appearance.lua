local _, ns = ...

function ns:ManagerSetup()
	-- see: http://wow.go-hero.net/framexml/14545/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua
	-- if InCombatLockdown() then return end
	-- unlink unit frames from manager
	CompactRaidFrameManager.container:SetParent(UIParent)

	-- ns:Manager_SetLeftBorder()
	-- ns:Manager_DisableCUF(ns.db.frames.disableCUF)

	ns:Manager_SetAlpha(ns.db.frames.pullout.passiveAlpha)
	hooksecurefunc("CompactRaidFrameManager_Expand", function(self)
		ns:Manager_SetAlpha(ns.db.frames.pullout.activeAlpha)
	end)
	hooksecurefunc("CompactRaidFrameManager_Collapse", function(self)
		ns:Manager_SetAlpha(ns.db.frames.pullout.passiveAlpha)
	end)

	-- ns:Manager_ShowSolo(ns.db.frames.showSolo)
	-- ns:MinifyPullout(ns.db.frames.pullout.minify)
end

function ns:ContainerSetup()
	local frame = CompactRaidFrameContainer
	FlowContainer_SetHorizontalSpacing(frame, ns.db.unitframe.spacingX or 0)
	FlowContainer_SetVerticalSpacing(frame, ns.db.unitframe.spacingY or 0)
	-- FlowContainer_SetMaxPerLine(frame, ns.db.unitframe.numPerLine or nil)
	-- FlowContainer_SetOrientation(frame, ns.db.unitframe.orientation or "vertical")
end

function ns:RegisterHooks()
	-- this eats little puppies. alive.
	-- hooksecurefunc("CompactRaidFrameContainer_TryUpdate", ns.UpdateAll)
	-- hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", ns.UpdateAll)
	hooksecurefunc("DefaultCompactUnitFrameSetup", ns.UnitFrameSetup) -- function(frame) frame.changed = true end)
	hooksecurefunc("DefaultCompactMiniFrameSetup", ns.UnitFrameSetup) -- function(frame) frame.changed = true end)

	-- we're too late to hook into frame creation DefaultCompactXXXXFrameSetup functions
	hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame)
		if frame and not frame.customized then
			ns.UnitFrameSetup(frame)
		end
	end)
	-- hooksecurefunc("CompactUnitFrame_SetUpClicks", ns.SetUpClicks)
	hooksecurefunc("CompactUnitFrame_SetUnit", function(frame, unit)
		if not frame then return end
		if not unit and frame:IsVisible() then
			print(frame:GetName(), unit, frame.unit, frame.displayedUnit)
		end
	end)

	-- hooksecurefunc("CompactUnitFrame_UpdateInVehicle", ns.UpdateInVehicle)
	-- hooksecurefunc("CompactUnitFrame_UpdateVisible", ns.UpdateVisible)
	-- hooksecurefunc("CompactUnitFrame_UpdateMaxHealth", ns.UpdateMaxHealth)
	-- hooksecurefunc("CompactUnitFrame_UpdateHealth", ns.UpdateHealth)
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ns.UpdateHealthColor)
	-- hooksecurefunc("CompactUnitFrame_UpdateMaxPower", ns.UpdateMaxPower)
	-- hooksecurefunc("CompactUnitFrame_UpdatePower", ns.UpdatePower)
	hooksecurefunc("CompactUnitFrame_UpdatePowerColor", ns.UpdatePowerColor)
	hooksecurefunc("CompactUnitFrame_UpdateName", ns.UpdateName)
	-- hooksecurefunc("CompactUnitFrame_UpdateSelectionHighlight", ns.UpdateSelectionHighlight)
	-- hooksecurefunc("CompactUnitFrame_UpdateAggroHighlight", ns.UpdateAggroHighlight)
	-- hooksecurefunc("CompactUnitFrame_UpdateInRange", ns.UpdateInRange)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", ns.UpdateStatus)
	-- hooksecurefunc("CompactUnitFrame_UpdateHealPrediction", ns.UpdateHealPrediction)
	-- hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", ns.UpdateRoleIcon)
	-- hooksecurefunc("CompactUnitFrame_UpdateReadyCheck", ns.UpdateReadyCheck)
	-- hooksecurefunc("CompactUnitFrame_UpdateAuras", ns.UpdateAuras)
	-- hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", ns.UpdateCenterStatusIcon)

	-- hooksecurefunc("CompactUnitFrame_UtilSetDispelDebuff", ns.DisplayDebuffType)
	-- hooksecurefunc("CompactUnitFrame_HideAllDispelDebuffs", ns.HideDisplayDebuffs)
	-- hooksecurefunc("CompactUnitFrame_UpdateDispellableDebuffs", ns.HideDisplayDebuffs)

	hooksecurefunc("CompactUnitFrame_OnUpdate", ns.OnUpdate)

	hooksecurefunc("CompactRaidFrameManager_ResizeFrame_UpdateContainerSize", function(manager)
		if CompactRaidFrameManager_GetSetting("KeepGroupsTogether") ~= "1" then
			local resizerHeight = manager.containerResizeFrame:GetHeight()
			local unitFrameHeight = DefaultCompactUnitFrameSetupOptions.height
			local spacing = (manager.container.flowVerticalSpacing or 0) + 1 -- TODO: is this correct?, account for flow direction!
			local newHeight = (unitFrameHeight + spacing) * floor(resizerHeight / unitFrameHeight)
			manager.container:SetHeight(newHeight)
		end
	end)
end

function ns.UnitFrameSetup(frame)
	local frame = frame or self

	--[[ Health Bar ]]--
	ns:CUF_SetHealthTexture(frame, ns.db.health.texture)
	ns:UpdateHealthColor(frame)
	ns:CUF_SetHealthBGTexture(frame, ns.db.health.bgtexture)
	ns:CUF_SetHealthBGColor(frame, ns:GetColorSetting( ns.db.health.bgcolor, frame.unit ))

	--[[ Power Bar ]]--
	ns:CUF_SetPowerTexture(frame, ns.db.power.texture)
	ns:UpdatePowerColor(frame)
	ns:CUF_SetPowerBGTexture(frame, ns.db.power.bgtexture)
	ns:CUF_SetPowerBGColor(frame, ns:GetColorSetting(ns.db.power.bgcolor, frame.unit))

	--[[ Bar Orientation ]]--
	-- ns:CUF_SetHealthBarVertical(frame, ns.db.health.vertical)
	-- ns:CUF_SetPowerBarVertical(frame, ns.db.power.vertical, ns.db.power.changePosition)
	-- ns:CUF_SetSeperatorVertical(frame, ns.db.power.vertical, ns.db.power.changePosition)

	--[[ Auras ]]--
	--[[frame.buffFrames[1]:ClearAllPoints()
	frame.buffFrames[1]:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", -1*(ns.db.buffs.posX or 3), (ns.db.buffs.posY or 0))
	frame.debuffFrames[1]:ClearAllPoints()
	frame.debuffFrames[1]:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", ns.db.debuffs.posX or 3, ns.db.debuffs.posY or 0)
	]]--

	--[[ Icons ]]--
	-- frame.optionTable.displayRaidRoleIcon = nil -- [TODO] ???
	-- frame.roleIcon:ClearAllPoints();
	-- frame.roleIcon:SetPoint("TOPLEFT", frame.healthBar, 3, -2);
	-- frame.dispelDebuffFrames[1]:SetPoint("TOPRIGHT", frame.healthBar, -3, -2);

	--[[ Texts ]]--
	local defaultFont, defaultSize, defaultStyle
	if ns.db.name.font or ns.db.name.fontSize or ns.db.name.fontStyle then
		defaultFont, defaultSize, defaultStyle = frame.name:GetFont()
		frame.name:SetFont(ns.db.name.font or defaultFont, ns.db.name.fontSize or defaultSize, ns.db.name.fontStyle or defaultStyle)
		frame.name:SetJustifyH(ns.db.name.justifyH or 'LEFT')
	end

	if ns.db.status.font or ns.db.status.fontSize or ns.db.status.fontStyle then
		defaultFont, defaultSize, defaultStyle = frame.statusText:GetFont()
		frame.statusText:SetFont(ns.db.status.font or defaultFont, ns.db.status.fontSize or defaultSize, ns.db.status.fontStyle or defaultStyle)
	end

	--[[ Misc Changes ]]--
	-- frame.roleIcon:SetSize(8, 8)
	frame.totalAbsorbOverlay:SetTexture(nil)
	frame.overAbsorbGlow:SetWidth(4)
	frame.overAbsorbGlow:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMRIGHT", -2, 0)
	frame.overAbsorbGlow:SetPoint("TOPLEFT", frame.healthBar, "TOPRIGHT", -2, 0)

	frame.customized = true
end

function ns:UpdateHealthColor(frame)
	local frame = frame or self
	if not frame or not frame.unit then return end

	local r, g, b
	if not UnitIsPVP("player") and UnitIsPVP(frame.unit) then
		r, g, b = ns:GetColorSetting(ns.db.health.flagsAsPvPColor, frame.unit)
	elseif not UnitIsFriend("player", frame.unit) then
		r, g, b = ns:GetColorSetting(ns.db.health.flagsAsPvPColor, frame.unit)
	else
		r, g, b = ns:GetColorSetting(ns.db.health.color, frame.unit)
	end

	if r and r ~= frame.healthBar.r or g ~= frame.healthBar.g or b ~= frame.healthBar.b then
		frame.healthBar:SetStatusBarColor(r, g, b)
		frame.healthBar.r, frame.healthBar.g, frame.healthBar.b = r, g, b
	end
end
function ns:UpdatePowerColor(frame)
	local frame = frame or self
	local unit = frame.unit or frame.displayedUnit
	if not unit then return end

	local displayPowerBar = ns:ShouldDisplayPowerBar(frame)
	ns:CUF_SetPowerBarShown(frame, displayPowerBar)

	local r, g, b = ns:GetColorSetting( ns.db.power.color, frame.unit )
	if UnitIsConnected(unit) and r then
		frame.powerBar:SetStatusBarColor(r, g, b)
	end
end
function ns:UpdateNameColor(frame)
	local r, g, b = ns:GetColorSetting(ns.db.name.color, frame.unit)
	ns:CUF_SetNameColor(frame, r, g, b)
end
function ns:UpdateName(frame)
	local frame = frame or self
	ns:CUF_SetNameText(frame, ns.db.name.size)
	ns:UpdateNameColor(frame)
end
function ns:UpdateStatusColor(frame)
	local r, g, b = ns:GetColorSetting(ns.db.status.color, frame.unit)
	ns:CUF_SetStatusColor(frame, r, g, b)
end
function ns:UpdateStatus(frame)
	local frame = frame or self
	ns:CUF_SetStatusText(frame)
	ns:UpdateStatusColor(frame)
end

function ns.UpdateAuras(frame)
	local frame = frame or self
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
	frame:SetAttribute("*type2", "togglemenu")
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
