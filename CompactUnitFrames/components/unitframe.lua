local addonName, addon, _ = ...

-- GLOBALS: CreateFrame, UnitIsConnected, UnitBuff, UnitDebuff, UnitPowerType, UnitGroupRolesAssigned
-- GLOBALS: CompactUnitFrameProfiles, GetRaidProfileOption, CompactUnitFrame_UtilShouldDisplayDebuff, CompactUnitFrame_UtilShouldDisplayBuff
-- GLOBALS: pairs, type

function addon.SetupCompactUnitFrame(frame, style, isFirstSetup)
	if not style or (style ~= 'normal' and style ~= 'mini') then return end
	-- bar orientation
	-- addon.CUF_SetHealthBarVertical(frame, addon.db.health.vertical)
	-- addon.CUF_SetPowerBarVertical(frame, addon.db.power.vertical, addon.db.power.changePosition)
	-- addon.CUF_SetSeperatorVertical(frame, addon.db.power.vertical, addon.db.power.changePosition)

	-- selectionHighlight + aggroHighlight (texture, coords, position)
	-- borders (horizTopBorder, horizBottomBorder, verLeftBorder, vertRightBorder, horizDivider: texture, height/width, position)

	-- frame size, background (texture, coords)
	addon.CUF_SetFrameBGTexture(frame, addon.db.unitframe.bgtexture)
	addon.CUF_SetFrameBGColor(frame, addon:GetColorSetting( addon.db.unitframe.bgcolor, frame.unit ))

	-- healthBar (position, statusbartexture)
	addon.CUF_SetHealthTexture(frame, addon.db.health.texture)
	if isFirstSetup then
		addon.CUF_SetHealthBGTexture(frame, addon.db.health.bgtexture)
		addon.CUF_SetHealthBGColor(frame, addon:GetColorSetting( addon.db.health.bgcolor, frame.unit ))
	end

	-- name (position, justifyH)
	frame.name:SetJustifyH(addon.db.name.justifyH or 'LEFT')
	if isFirstSetup and (addon.db.name.font or addon.db.name.fontSize or addon.db.name.fontStyle) then
		local defaultFont, defaultSize, defaultStyle = frame.name:GetFont()
		frame.name:SetFont(addon.db.name.font or defaultFont, addon.db.name.fontSize or defaultSize, addon.db.name.fontStyle or defaultStyle)
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
		addon.CUF_SetPowerTexture(frame, addon.db.power.texture)
		if isFirstSetup then
			addon.CUF_SetPowerBGTexture(frame, addon.db.power.bgtexture)
			addon.CUF_SetPowerBGColor(frame, addon:GetColorSetting(addon.db.power.bgcolor, frame.unit))
		end

		-- roleIcon (position, size)
		addon.CUF_SetRoleIconSize(frame, addon.db.unitframe.roleIconSize)
		-- frame.roleIcon:ClearAllPoints()
		-- frame.roleIcon:SetPoint("TOPLEFT", frame.healthBar, 3, -2)

		-- statusText (fontSize, position, height)
		addon.CUF_SetStatusColor(frame, addon:GetColorSetting(addon.db.status.color, frame.unit))
		if addon.db.status.font or addon.db.status.fontSize or addon.db.status.fontStyle then
			local defaultFont, defaultSize, defaultStyle = frame.statusText:GetFont()
			frame.statusText:SetFont(addon.db.status.font or defaultFont, addon.db.status.fontSize or defaultSize, addon.db.status.fontStyle or defaultStyle)
		end

		-- CompactUnitFrame_SetMaxBuffs, CompactUnitFrame_SetMaxDebuffs, CompactUnitFrame_SetMaxDispelDebuffs(frame, 3)
		-- buffFrames (position, size)
		-- debuffFrames (position, size copied from buffFrames)
		-- dispelDebuffFrames (position, size)
		-- frame.buffFrames[1]:ClearAllPoints()
		-- frame.buffFrames[1]:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", -1*(addon.db.buffs.posX or 3), (addon.db.buffs.posY or 0))
		-- frame.debuffFrames[1]:ClearAllPoints()
		-- frame.debuffFrames[1]:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", addon.db.debuffs.posX or 3, addon.db.debuffs.posY or 0)
		-- frame.dispelDebuffFrames[1]:SetPoint("TOPRIGHT", frame.healthBar, -3, -2)

		-- readyCheckIcon (position, size)
		-- centerStatusIcon (position, size (2*buffSize))

		if isFirstSetup and addon.db.unitframe.enableOverlay then -- and not frame.Overlay then
			local overlay = CreateFrame("Button", "$parentCUFOverlay", frame, "CompactAuraTemplate")
			      overlay:SetPoint('CENTER', addon.db.indicators.center.posX or 0, addon.db.indicators.center.posY or 0)
			      overlay:SetSize(20, 20)
			      overlay:EnableMouse(false)
			      overlay:EnableMouseWheel(false)
			      overlay:Hide()
			frame.Overlay = overlay
			addon.EnableOverlay(frame)
		end

		if isFirstSetup and addon.db.unitframe.enableGPS then -- and not frame.GPS then
			local gps = CreateFrame("Frame", nil, frame.healthBar)
			      gps:SetPoint('CENTER')
			      gps:SetSize(40, 40)
			      gps:Hide()
			local tex = gps:CreateTexture("OVERLAY")
			      tex:SetTexture("Interface\\Minimap\\Minimap-QuestArrow") -- DeadArrow
			      tex:SetAllPoints()
			gps.outOfRange = addon.db.unitframe.gpsOutOfRange
			gps.onMouseOver = addon.db.unitframe.gpsOnHover
			frame.GPS = gps
			frame.GPS.Texture = tex -- .Text is also possible
			addon.EnableGPS(frame)
		end
	end

	if isFirstSetup and not frame:IsEventRegistered("UNIT_FACTION") then
		frame:RegisterEvent("UNIT_FACTION")
		frame:RegisterEvent("UNIT_FLAGS")
		-- frame:RegisterEvent("PLAYER_FLAGS_CHANGED")
		frame:RegisterEvent("PLAYER_CONTROL_LOST")
		frame:RegisterEvent("PLAYER_CONTROL_GAINED")

		frame:HookScript("OnEvent", function(self, event, unit)
			-- addon.Print('event', event, unit, self:GetName())
			if not unit or unit == self.unit and (event == 'UNIT_FACTION' or event == 'UNIT_FLAGS') then
				-- (event == "UNIT_FACTION" or event == "UNIT_FLAGS" or event == "PLAYER_FLAGS_CHANGED") then
				-- addon.Print("Updating PVP/Faction of", unit, UnitName(unit), UnitFactionGroup(unit), UnitIsPVP(unit), UnitIsPVPFreeForAll(unit))
				addon.UpdateHealthColor(self)
			end
		end)
	end
end

function addon:ShouldDisplayPowerBar(frame)
	local displayBlizzard = GetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, 'displayPowerBar')
	if not displayBlizzard then	return end
	local unit = frame.displayedUnit or frame.unit
	if not unit or not UnitIsConnected(unit) or not UnitIsConnected(unit) then return end

	if addon.db.power.types.showSelf and unit == 'player' then
		return true
	elseif unit:find('pet') then
		return addon.db.power.types.showPets
	end

	local powerType = UnitPowerType(unit)
	local showType = addon.db.power.types.showUnknown
	local settingsType = addon.db.power.types[powerType]
	if settingsType then
		showType = not settingsType.hide
	end

	local unitRole = UnitGroupRolesAssigned(unit)
	local showRole = addon.db.power.roles[unitRole]

	return showType and showRole
end

function addon:ShouldDisplayAura(unit, index, filter, isDebuff)
	local dataTable = isDebuff and addon.db.debuffs or addon.db.buffs
	local auraName, _, _, _, debuffType, auraDuration, _, caster, canStealOrPurge, _, spellID, canApply, auraIsBoss = (isDebuff and UnitDebuff or UnitBuff)(unit, index, filter)
	if not auraName then return nil end

	if dataTable.hidePermanent and auraDuration == 0 then return false end
	if dataTable.showBoss and auraIsBoss then return true, auraIsBoss end

	for _, dataSpell in pairs(dataTable.hide) do
		if (type(dataSpell) == 'number' and dataSpell == spellID) or dataSpell == auraName then
			return false, auraIsBoss
		end
	end
	for _, dataSpell in pairs(dataTable.show) do
		if (type(dataSpell) == 'number' and dataSpell == spellID) or dataSpell == auraName then
			return true, auraIsBoss
		end
	end

	-- fallback to blizz defaults
	if isDebuff then
		return CompactUnitFrame_UtilShouldDisplayDebuff(unit, index, filter)
	else
		return CompactUnitFrame_UtilShouldDisplayBuff(unit, index, filter)
	end
end
