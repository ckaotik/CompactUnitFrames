local addonName, addon, _ = ...

-- GLOBALS: _G, UIParent, DebuffTypeColor
-- GLOBALS: UnitIsPVP, UnitIsConnected, CompactUnitFrame_UpdateAll, CompactUnitFrame_UpdateSelectionHighlight, CompactUnitFrame_UtilSetBuff, CompactUnitFrame_UtilSetDebuff, UnitIsEnemy, UnitCanAttack, UnitIsDead, UnitHasIncomingResurrection, CompactRaidFrameContainer_ApplyToFrames
-- GLOBALS: hooksecurefunc, pairs, type, floor, ipairs, math

function addon.UpdateHealthColor(frame)
	if not frame or type(frame) ~= "table" then return end
	if addon.db.profile.indicators.showDispellHealth and (frame.hasDispelMagic or frame.hasDispelCurse or frame.hasDispelDisease or frame.hasDispelPoison) then
		return
	end

	local r, g, b
	if not frame.unit then
		r, g, b = addon:GetColorSetting(addon.db.profile.health, 'bgcolor', frame.unit)
	elseif UnitCanAttack('player', frame.unit) or UnitIsEnemy('player', frame.unit) then
		r, g, b = addon:GetColorSetting(addon.db.profile.health, 'isEnemyColor', frame.unit)
	elseif not UnitIsPVP('player') and UnitIsPVP(frame.unit) then
		r, g, b = addon:GetColorSetting(addon.db.profile.health, 'flagsAsPvPColor', frame.unit)
	else
		r, g, b = addon:GetColorSetting(addon.db.profile.health, 'color', frame.unit)
	end
	if r and g and b then
		frame.healthBar:SetStatusBarColor(r, g, b)
	end
end

function addon.UpdatePowerColor(frame)
	if not frame or type(frame) ~= "table" then return end
	local unit = frame.unit or frame.displayedUnit

	local displayPowerBar = addon:ShouldDisplayPowerBar(frame)
	local powerSize = displayPowerBar and addon.db.profile.power.size or 0
	local displayBorder = GetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, 'displayBorder')
	if powerSize > 0 and addon.db.profile.unitframe.showSeparator then
		if displayBorder then
			-- blizzard separator is 2px high
			powerSize = powerSize + 2
		else
			-- our separator is 1px high
			powerSize = powerSize + 1
		end
	elseif displayBorder and displayPowerBar == false then
		-- blizzard would display a bar, we need to hide its separator
		frame.horizDivider:Hide()
	else
		-- apply powerSize as-is
	end
	-- local padding = addon.db.profile.unitframe.innerPadding
	frame.healthBar:SetPoint('BOTTOMRIGHT', -1, 1 + powerSize) -- 1px padding to frame edge

	local r, g, b = addon:GetColorSetting(addon.db.profile.power, 'color', frame.unit)
	if frame.powerBar and r and (not unit or UnitIsConnected(unit)) then
		frame.powerBar:SetStatusBarColor(r, g, b)
		frame.powerBar:SetShown(displayPowerBar and true or false)
		-- if frame.powerBar.vertical then
		-- 	frame.healthBar:SetPoint('BOTTOMRIGHT', -1 - powerSize, 1)
		-- end
	end
end

function addon.UpdateName(frame)
	if not frame or type(frame) ~= "table" then return end

	local unitName, server = UnitFullName(frame.unit)
	if server and server ~= '' and server ~= addon.playerRealm then
		if addon.db.profile.name.serverFormat == 'full' then
			unitName = unitName .. "-" .. server
		elseif addon.db.profile.name.serverFormat == 'short' then
			unitName = addon.db.profile.name.serverPrefix .. unitName .. addon.db.profile.name.serverSuffix
		else -- 'none'
			-- use only name part
		end
	end
	frame.name:SetText(unitName)

	if frame.name:IsTruncated() then
		-- FIXME: use GetTextWidth() instead
		local nameLength = addon.db.profile.name.length
		if addon.db.profile.name.format == 'shorten' then
			unitName = addon:ShortenString(unitName, nameLength or 10)
		elseif addon.db.profile.name.format == 'cut' then
			unitName = addon.utf8sub(unitName, 1, nameLength or 10)
		end
		frame.name:SetText(unitName)
	end

	local r, g, b = addon:GetColorSetting(addon.db.profile.name, 'color', frame.unit)
	frame.name:SetVertexColor(r or 1, g or 1, b or 1, 1)
end

local afkTimes, afkTimers = {}, {}
function addon.UpdateStatusText(frame, arg1)
	frame = arg1 or frame -- AceTimer calls with addon as first argument
	if not addon.db.profile.unitframe.enableAFKTimers then return end

	local unit = frame.displayedUnit or frame.unit
	if unit and UnitIsAFK(unit) then
		if not afkTimes[frame] then
			afkTimes[frame]  = time()
			afkTimers[frame] = addon:ScheduleRepeatingTimer('UpdateStatusText', 1, frame)
		end
		-- update afk label
		local _, _, minutes, seconds = ChatFrame_TimeBreakDown(time() - afkTimes[frame])
		frame.statusText:SetText(string.format(addon.db.profile.status.afkFormat, minutes, seconds))
		frame.statusText:Show()
	elseif afkTimes[frame] then
		afkTimes[frame]  = nil
		afkTimers[frame] = addon:CancelTimer(afkTimers[frame])
		if unit then
			-- Restore non-afk text. This will again trigger UpdateStatusText().
			CompactUnitFrame_UpdateStatusText(frame)
		end
		return
	end

	local setting = frame.optionTable.healthText
	if frame.unit and (not UnitIsConnected(frame.unit) or UnitIsDeadOrGhost(unit)) then
		-- frame.statusText:SetText(nil)
	elseif (setting == 'losthealth' or setting == 'health') and addon.db.profile.status.format == 'shorten' then
		local value = frame.statusText:GetText()
		frame.statusText:SetText( addon:ShortenNumber(value) )
	end
end

function addon.UpdateCenterStatusIcon(frame)
	-- try to fix sticky incoming ressurect icon
	if frame.centerStatusIcon and not frame.centerStatusIcon:IsShown() or not frame.optionTable.displayIncomingResurrect then return end
	if UnitHasIncomingResurrection(frame.unit) and not UnitIsDead(frame.unit) then
		frame.centerStatusIcon:Hide()
	end
end
-- TODO: also update when corresponding raid event is triggered

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

	if addon.db.profile.indicators.showDispellHealth then
		if dispelType then
			local color = DebuffTypeColor[dispelType] or DebuffTypeColor["none"]
			frame.healthBar:SetStatusBarColor(color.r, color.g, color.b)
		else
			addon.UpdateHealthColor(frame)
		end
	end
	if addon.db.profile.indicators.showDispellBorder then
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

function addon.UpdateRoleIcon(frame)
	local raidID = UnitInRaid(frame.unit)
	local raidRole = frame.optionTable.displayRaidRoleIcon and raidID and select(10, GetRaidRosterInfo(raidID))
	local combatRole = UnitGroupRolesAssigned(frame.unit)
	local inVehicle = UnitInVehicle(frame.unit) and UnitHasVehicleUI(frame.unit)
	if not inVehicle and not raidRole and combatRole == 'DAMAGER' and frame.roleIcon then
		-- hide role icon
		frame.roleIcon:Hide()
		frame.roleIcon:SetWidth(1)
	end
end

function addon.SetUpClicks(frame)
	if addon.DelayInCombat(frame, addon.SetUpClicks) then return end
	frame:SetAttribute('*type1', 'target')
	frame:SetAttribute('*type2', 'togglemenu')
	frame:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
	-- FIXME: causes taint too easily, use Clique or similar if you really need the feature
	-- works with either menu or togglemenu. blizz uses menu, so stick to that
	-- local combatMenu = addon.db.profile.unitframe.noMenuClickInCombat and "" or "menu"
	-- RegisterAttributeDriver(frame, "*type2", "[nocombat] menu; "..combatMenu)
end
