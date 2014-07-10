local addonName, addon, _ = ...

-- GLOBALS: _G, UIParent, DebuffTypeColor
-- GLOBALS: UnitIsPVP, UnitIsConnected, CompactUnitFrame_UpdateAll, CompactUnitFrame_UpdateSelectionHighlight, CompactUnitFrame_UtilSetBuff, CompactUnitFrame_UtilSetDebuff, UnitIsEnemy, UnitCanAttack, UnitIsDead, UnitHasIncomingResurrection, CompactRaidFrameContainer_ApplyToFrames
-- GLOBALS: hooksecurefunc, pairs, type, floor, ipairs, math

function addon.SetupUnitFrameHooks()
	-- @see http://www.townlong-yak.com/framexml/18291/CompactUnitFrame.lua#241
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", addon.UpdateHealthColor)
	hooksecurefunc("CompactUnitFrame_UpdatePowerColor", addon.UpdatePowerColor)
	hooksecurefunc("CompactUnitFrame_UpdateName", addon.UpdateName)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", addon.CUF_SetStatusText)
	hooksecurefunc("CompactUnitFrame_UpdateBuffs", addon.UpdateBuffs)
	hooksecurefunc("CompactUnitFrame_UpdateDebuffs", addon.UpdateDebuffs)
	hooksecurefunc("CompactUnitFrame_UpdateDispellableDebuffs", addon.UpdateDispellableDebuffs)
	hooksecurefunc("CompactUnitFrame_UpdateCenterStatusIcon", addon.UpdateCenterStatusIcon)
	-- hooksecurefunc("CompactUnitFrame_UpdateRoleIcon", addon.UpdateRoleIcon)
	-- hooksecurefunc("CompactUnitFrame_UpdateVisible", addon.SetupCompactUnitFrame)
	-- hooksecurefunc("CompactUnitFrame_SetUpClicks", addon.SetUpClicks)
end

local debuffTypes = { Magic = true, Curse = true, Disease = true, Poison = true}
function addon.UpdateHealthColor(frame)
	if not frame or type(frame) ~= "table" then return end
	if addon.db.indicators.showDispellHealth then
		if frame.hasDispelMagic or frame.hasDispelCurse or frame.hasDispelDisease or frame.hasDispelPoison then
			return
		end
	end

	local r, g, b
	if not frame.unit then
		r, g, b = addon:GetColorSetting(addon.db.health.bgcolor, frame.unit)
	elseif UnitCanAttack("player", frame.unit) or UnitIsEnemy("player", frame.unit) then
		r, g, b = addon:GetColorSetting(addon.db.health.isEnemyColor, frame.unit)
	elseif not UnitIsPVP("player") and UnitIsPVP(frame.unit) then
		r, g, b = addon:GetColorSetting(addon.db.health.flagsAsPvPColor, frame.unit)
	else
		r, g, b = addon:GetColorSetting(addon.db.health.color, frame.unit)
	end
	frame.healthBar:SetStatusBarColor(r, g, b)
end
function addon.UpdatePowerColor(frame)
	if not frame or type(frame) ~= "table" then return end
	local unit = frame.unit or frame.displayedUnit

	local displayPowerBar = addon:ShouldDisplayPowerBar(frame)
	addon.CUF_SetPowerBarShown(frame, displayPowerBar)

	local r, g, b = addon:GetColorSetting( addon.db.power.color, frame.unit )
	if r and (not unit or UnitIsConnected(unit)) then
		frame.powerBar:SetStatusBarColor(r, g, b)
	end
end
function addon.UpdateNameColor(frame)
	local r, g, b = addon:GetColorSetting(addon.db.name.color, frame.unit)
	addon.CUF_SetNameColor(frame, r, g, b)
end
function addon.UpdateName(frame)
	if not frame or type(frame) ~= "table" then return end

	addon.CUF_SetNameText(frame, addon.db.name.size)
	addon.UpdateNameColor(frame)
end
function addon.UpdateCenterStatusIcon(frame)
	-- try to fix sticky incoming ressurect icon
	if not frame.centerStatusIcon:IsShown() or not frame.optionTable.displayIncomingResurrect then return end
	if UnitHasIncomingResurrection(frame.unit) and not UnitIsDead(frame.unit) then
		frame.centerStatusIcon:Hide()
	end
end

local isDisplayingBossBuff
function addon.UpdateBuffs(frame)
	if not frame.optionTable.displayBuffs then return end
	local unit = frame.displayedUnit or frame.unit

	isDisplayingBossBuff = false
	local index, frameNum, filter = 1, 1, nil
	while frameNum <= frame.maxBuffs do
		local displayAura, isBossAura = addon:ShouldDisplayAura(unit, index, filter)
		isDisplayingBossBuff = isDisplayingBossBuff or isBossAura
		if displayAura == nil then
			break
		elseif displayAura then
			CompactUnitFrame_UtilSetBuff(frame.buffFrames[frameNum], unit, index, filter)
			frameNum = frameNum + 1
		end
		index = index + 1
	end
	for i = frameNum, frame.maxBuffs do
		frame.buffFrames[i]:Hide()
	end
end
function addon.UpdateDebuffs(frame)
	if not frame.optionTable.displayDebuffs then return end
	local unit = frame.displayedUnit or frame.unit

	-- TODO: less debuff slots available when big auras are shown!
	local index, frameNum, filter = 1, 1, nil
	while frameNum <= frame.maxDebuffs - (isDisplayingBossBuff and 1 or 0) do
		local displayAura, isBossAura = addon:ShouldDisplayAura(unit, index, filter, true)
		if displayAura == nil then
			break
		elseif displayAura then
			CompactUnitFrame_UtilSetDebuff(frame.debuffFrames[frameNum], unit, index, filter, isBossAura, isDisplayingBossBuff)
			frameNum = frameNum + 1
		end
		index = index + 1
	end
	for i = frameNum, frame.maxBuffs do
		frame.debuffFrames[i]:Hide()
	end
end
function addon.UpdateDispellableDebuffs(frame)
	if not frame.optionTable.displayDispelDebuffs then return end
	-- since border/health can only display in one color
	local dispelType = (frame.hasDispelMagic and 'Magic') or (frame.hasDispelCurse and 'Curse') or (frame.hasDispelDisease and 'Disease') or (frame.hasDispelPoison and 'Poison')

	if addon.db.indicators.showDispellHealth then
		if dispelType then
			local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
			frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
		else
			addon.UpdateHealthColor(frame)
		end
	end
	if addon.db.indicators.showDispellBorder then
		if dispelType then
			local color = DebuffTypeColor[dispelType or 'none']
			frame.selectionHighlight:SetVertexColor(color.r, color.g, color.b)
			frame.selectionHighlight:Show()
		else
			frame.selectionHighlight:SetVertexColor(1, 1, 1)
			CompactUnitFrame_UpdateSelectionHighlight(frame)
		end
	end
end

--[[function addon.SetUpClicks(frame)
	-- FIXME: causes taint too easily, use Clique or similar if you really need the feature
	if addon.DelayInCombat(frame, addon.SetUpClicks) then return end
	-- frame:SetAttribute("*type2", 'togglemenu')
	-- works with either menu or togglemenu. blizz uses menu, so stick to that
	local combatMenu = addon.db.unitframe.noMenuClickInCombat and "" or "menu"
	RegisterAttributeDriver(frame, "*type2", "[nocombat] menu; "..combatMenu)
end --]]
