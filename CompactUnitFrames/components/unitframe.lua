local addonName, addon, _ = ...

-- GLOBALS: CreateFrame, UnitIsConnected, UnitBuff, UnitDebuff, UnitPowerType, UnitGroupRolesAssigned
-- GLOBALS: CompactUnitFrameProfiles, GetRaidProfileOption, CompactUnitFrame_UtilShouldDisplayDebuff, CompactUnitFrame_UtilShouldDisplayBuff
-- GLOBALS: pairs, type

local hiddenSize = 0.000001
local healthTex   = 'Interface\\RaidFrame\\Raid-Bar-Hp-Fill'
local healthBgTex = 'Interface\\RaidFrame\\Raid-Bar-Hp-Bg'
local powerTex    = 'Interface\\RaidFrame\\Raid-Bar-Resource-Fill'
local powerBgTex  = 'Interface\\RaidFrame\\Raid-Bar-Resource-Background'

function addon.SetupCompactUnitFrame(frame, style, isFirstSetup)
	if not style or (style ~= 'normal' and style ~= 'mini') then return end
	local options = frame.optionTable
	local displayBorder = GetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, 'displayBorder')

	-- bar orientation
	-- addon.CUF_SetHealthBarVertical(frame, addon.db.profile.health.vertical)
	-- addon.CUF_SetPowerBarVertical(frame, addon.db.profile.power.vertical, addon.db.profile.power.changePosition)
	-- addon.CUF_SetSeperatorVertical(frame, addon.db.profile.power.vertical, addon.db.profile.power.changePosition)

	-- selectionHighlight + aggroHighlight (texture, coords, position)
	-- borders (horizTopBorder, horizBottomBorder, verLeftBorder, vertRightBorder, horizDivider: texture, height/width, position)

	-- frame size, background (texture, coords)
	local r, g, b = addon:GetColorSetting(addon.db.profile.unitframe.bgcolor, frame.unit)
	frame.background:SetVertexColor(r or 1, g or 1, b or 1)
	frame.background:SetTexture(addon.db.profile.unitframe.bgtexture or healthBgTex)

	-- healthBar (position, statusbartexture)
	frame.healthBar:SetStatusBarTexture(addon.db.profile.health.texture or healthTex, 'BORDER')
	if isFirstSetup then
		local r, g, b = addon:GetColorSetting(addon.db.profile.health.bgcolor, frame.unit)
		frame.healthBar.background:SetVertexColor(r or 1, g or 1, b or 1)
		frame.healthBar.background:SetTexture(addon.db.profile.health.bgtexture or healthBgTex)
	end

	-- name (position, justifyH)
	frame.name:SetJustifyH(addon.db.profile.name.justifyH or 'LEFT')
	if isFirstSetup and (addon.db.profile.name.font or addon.db.profile.name.fontSize or addon.db.profile.name.fontStyle) then
		-- "Fonts\\FRIZQT__.TTF", 10
		local defaultFont, defaultSize, defaultStyle = frame.name:GetFont()
		frame.name:SetFont(addon.db.profile.name.font or defaultFont, addon.db.profile.name.fontSize or defaultSize, addon.db.profile.name.fontStyle or defaultStyle)
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
		frame.powerBar:SetStatusBarTexture(addon.db.profile.power.texture or powerTex, 'BORDER')
		frame.powerBar.background:SetTexture(addon.db.profile.power.bgtexture or powerBgTex, 'BORDER')
		if isFirstSetup then
			local r, g, b = addon:GetColorSetting(addon.db.profile.power.bgcolor, frame.unit)
			frame.powerBar.background:SetVertexColor(r or 1, g or 1, b or 1)
		end

		if true then -- not InCombatLockdown() then
			-- local inset = addon.db.profile.unitframe.innerPadding
			frame.powerBar:SetHeight(addon.db.profile.power.size)
			frame.powerBar:SetPoint('BOTTOMRIGHT', -1, 1)
			if not displayBorder and addon.db.profile.unitframe.showSeparator then
				-- show 1px separator
				frame.powerBar:SetPoint('TOPLEFT', frame.healthBar, 'BOTTOMLEFT', 0, -1)
			end

			-- anchor separator to power bar
			frame.horizDivider:SetPoint('TOPLEFT', frame.powerBar, 'TOPLEFT', 0, 1)
			frame.horizDivider:SetPoint('TOPRIGHT', frame.powerBar, 'TOPRIGHT', 0, 1)
		end

		-- roleIcon (position, size)
		local size = addon.db.profile.unitframe.roleIconSize
		if size == 0 then size = hiddenSize end
		frame.roleIcon:SetSize(size, size)
		-- frame.roleIcon:ClearAllPoints()
		-- frame.roleIcon:SetPoint("TOPLEFT", frame.healthBar, 3, -2)

		-- statusText (fontSize, position, height)
		local r, g, b = addon:GetColorSetting(addon.db.profile.status.color, frame.unit)
		frame.statusText:SetVertexColor(r or 0.5, g or 0.5, b or 0.5, 1)
		if addon.db.profile.status.font or addon.db.profile.status.fontSize or addon.db.profile.status.fontStyle then
			local defaultFont, defaultSize, defaultStyle = frame.statusText:GetFont()
			frame.statusText:SetFont(
				addon.db.profile.status.font or defaultFont,
				addon.db.profile.status.fontSize or defaultSize,
				addon.db.profile.status.fontStyle or defaultStyle
			)
		end

		-- CompactUnitFrame_SetMaxBuffs, CompactUnitFrame_SetMaxDebuffs, CompactUnitFrame_SetMaxDispelDebuffs(frame, 3)
		-- buffFrames (position, size)
		-- debuffFrames (position, size copied from buffFrames)
		-- dispelDebuffFrames (position, size)
		-- frame.buffFrames[1]:ClearAllPoints()
		-- frame.buffFrames[1]:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", -1*(addon.db.profile.buffs.posX or 3), (addon.db.profile.buffs.posY or 0))
		-- frame.debuffFrames[1]:ClearAllPoints()
		-- frame.debuffFrames[1]:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", addon.db.profile.debuffs.posX or 3, addon.db.profile.debuffs.posY or 0)
		-- frame.dispelDebuffFrames[1]:SetPoint("TOPRIGHT", frame.healthBar, -3, -2)

		-- readyCheckIcon (position, size)
		-- centerStatusIcon (position, size (2*buffSize))
	end

	if isFirstSetup and style == 'normal' and addon.db.profile.unitframe.enableOverlay then
		local xOffset, yOffset = addon.db.profile.indicators.center.posX or 0, addon.db.profile.indicators.center.posY or 0
		local overlay = addon.Overlay.Enable(frame)
		      overlay:SetSize(20, 20)
		      overlay:SetPoint('CENTER', frame, 'CENTER', xOffset, yOffset)
	end

	if isFirstSetup and style == 'normal' and addon.db.profile.unitframe.enableGPS then -- and not frame.GPS then
		local gps = addon.GPS.Enable(frame)
		      gps:SetSize(40, 40)
		      gps:SetPoint('CENTER', frame.healthBar, 'CENTER')
		      gps:Hide()
		gps.outOfRange = addon.db.profile.unitframe.gpsOutOfRange
		gps.onMouseOver = addon.db.profile.unitframe.gpsOnHover
		--[[ local gps = CreateFrame("Frame", nil, frame.healthBar)
		      gps:SetPoint('CENTER')
		      gps:SetSize(40, 40)
		      gps:Hide() --]]
		local tex = gps:CreateTexture("OVERLAY")
		      tex:SetTexture("Interface\\Minimap\\Minimap-QuestArrow") -- DeadArrow
		      tex:SetAllPoints()
		gps.Texture = tex
		--[[frame.GPS = gps
		frame.GPS.Texture = tex -- .Text is also possible
		addon.EnableGPS(frame)--]]
	end

	if isFirstSetup and style == 'normal' then
		local afkEvent = (frame.unit and UnitIsUnit(frame.unit, 'player')) and 'PLAYER_FLAGS_CHANGED' or 'UNIT_FLAGS'
		frame:RegisterEvent(afkEvent)
		frame:HookScript('OnEvent', function(self, event)
			-- update status text for afk timer
			if event == afkEvent then addon.UpdateStatusText(frame) end
		end)
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
	if not displayBlizzard then	return nil end
	local unit = frame.displayedUnit or frame.unit
	if not unit or not UnitIsConnected(unit) or not UnitIsConnected(unit) then return false end

	if addon.db.profile.power.showSelf and UnitIsUnit(unit, 'player') then
		return true
	elseif unit:find('pet') then
		return addon.db.profile.power.showPets
	end

	local powerType = UnitPowerType(unit)
	local showType = addon.db.profile.power.types[powerType]
	if showType == nil then
		showType = addon.db.profile.power.showUnknown
	end

	local unitRole = UnitGroupRolesAssigned(unit)
	local showRole = addon.db.profile.power.roles[unitRole]

	return showType and showRole
end

function addon:ShouldDisplayAura(unit, index, filter, isDebuff)
	local dataTable = isDebuff and addon.db.profile.debuffs or addon.db.profile.buffs
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
