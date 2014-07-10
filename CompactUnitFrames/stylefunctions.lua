local addonName, ns = ...
-- GLOBALS: _G, UIParent, CompactRaidFrameManager, RAID_BORDERS_SHOWN
-- GLOBALS: HidePartyFrame, GetUnitName, UnitIsDeadOrGhost, UnitIsConnected, GetNumGroupMembers
-- GLOBALS: hooksecurefunc, pairs, ipairs, string

local hiddenSize = 0.000001

function ns.CUF_SetFrameBGTexture(frame, texture)
	frame.background:SetTexture(texture or 'Interface\\RaidFrame\\Raid-Bar-Hp-Bg')
end

function ns.CUF_SetFrameBGColor(frame, r, g, b)
	frame.background:SetVertexColor(r or 1, g or 1, b or 1)
end

function ns.CUF_SetRoleIconSize(frame, size)
	if size == 0 then size = hiddenSize end
	frame.roleIcon:SetSize(size, size)
end

-- ==== [Health Bar] ========================================
function ns.CUF_SetHealthBarVertical(frame, enable)
	local width, height = frame:GetSize()

	if enable then
		frame.healthBar:SetOrientation('vertical')
		frame.healthBar:SetRotatesTexture(true)

		--[[ frame.myHealPrediction:SetOrientation('vertical')
		frame.myHealPrediction:ClearAllPoints()
		frame.myHealPrediction:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
		frame.myHealPrediction:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		frame.myHealPrediction:SetHeight(height)

		-- frame.otherHealPrediction:SetOrientation('vertical')
		frame.otherHealPrediction:ClearAllPoints()
		frame.otherHealPrediction:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
		frame.otherHealPrediction:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		frame.otherHealPrediction:SetHeight(height) --]]
	else
		frame.healthBar:SetOrientation("horizontal")

		--[[ frame.myHealPrediction:SetOrientation("horizontal")
		frame.myHealPrediction:ClearAllPoints()
		frame.myHealPrediction:SetPoint("TOPLEFT", frame.healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		frame.myHealPrediction:SetPoint("BOTTOMLEFT", frame.healthBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
		frame.myHealPrediction:SetWidth(width)

		frame.otherHealPrediction:SetOrientation("horizontal")
		frame.otherHealPrediction:ClearAllPoints()
		frame.otherHealPrediction:SetPoint("TOPLEFT", frame.myHealPrediction:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		frame.otherHealPrediction:SetPoint("BOTTOMLEFT", frame.myHealPrediction:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
		frame.otherHealPrediction:SetWidth(width) --]]
	end
end

function ns.CUF_SetHealthTexture(frame, texture)
	frame.healthBar:SetStatusBarTexture(texture or 'Interface\\RaidFrame\\Raid-Bar-Hp-Fill', 'BORDER')
end

function ns.CUF_SetHealthBGTexture(frame, texture)
	frame.healthBar.background:SetTexture(texture or 'Interface\\RaidFrame\\Raid-Bar-Hp-Bg')
end

function ns.CUF_SetHealthBGColor(frame, r, g, b)
	frame.healthBar.background:SetVertexColor(r or 1, g or 1, b or 1)
end

-- ==== [Power Bar] ========================================
function ns.CUF_SetPowerTexture(frame, texture)
	frame.powerBar:SetStatusBarTexture(texture or 'Interface\\RaidFrame\\Raid-Bar-Resource-Fill', 'BORDER')
end

function ns.CUF_SetPowerBGTexture(frame, texture)
	frame.powerBar.background:SetTexture(texture or 'Interface\\RaidFrame\\Raid-Bar-Resource-Background', 'BORDER')
end

function ns.CUF_SetPowerBGColor(frame, r, g, b)
	frame.powerBar.background:SetVertexColor(r or 1, g or 1, b or 1)
end

function ns.CUF_SetPowerSize(frame, size)
	local padding = ns.db.unitframe.innerPadding
	if size == 0 then size = hiddenSize end
	--if frame.powerBar.vertical then
	--	frame.powerBar:SetWidth(size)
	--else
		frame.powerBar:SetHeight(size)
		frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1*padding, 1*padding + size)
	--end
end

-- db.powerBar.vertical, db.unitframe.hidePowerSeperator, db.power.size
function ns.CUF_SetPowerBarShown(frame, enable)
	if enable then
		ns.CUF_SetPowerSize(frame, ns.db.power.size)
		-- ns.CUF_SetSeperatorShown(frame, not ns.db.unitframe.hideSeperator)
	else
		ns.CUF_SetPowerSize(frame, 0)
		-- ns.CUF_SetSeperatorShown(frame, false)
	end
end

function ns.CUF_SetPowerBarVertical(frame, enable, togglePosition)
	frame.powerBar.vertical = enable

	frame.powerBar:ClearAllPoints()
	frame.healthBar:ClearAllPoints()

	local padding = ns.db.unitframe.innerPadding -- anchors to <frame> might have some padding
	if enable then
		frame.powerBar:SetOrientation("vertical")
		frame.powerBar:SetRotatesTexture(true)

		if togglePosition then -- left
			frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
			frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", padding, padding)

			frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "TOPRIGHT", 0, 0)
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)
		else -- right
			frame.powerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padding, -padding)
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)

			frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding);
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMLEFT", 0, 0)
		end
	else
		frame.powerBar:SetOrientation("horizontal")

		if togglePosition then -- top
			frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
			frame.powerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padding, -padding)

			frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "BOTTOMLEFT", 0, 0)
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame, -padding, padding)
		else -- bottom [DEFAULT]
			frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", padding, padding)
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)

			frame.healthBar:SetPoint("TOPLEFT", frame, padding, -padding)
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "TOPRIGHT", 0, 0)
		end
	end
end

function ns.CUF_SetSeperatorShown(frame, enable)
	-- FIXME: major taint
	local seperatorSize = 1

	if not RAID_BORDERS_SHOWN then
		frame.horizDivider:Hide()
	elseif enable then
		frame.horizDivider:Show()

		if frame.powerBar.vertical then
			frame.powerBar:SetWidth(frame.powerBar:GetWidth() + seperatorSize)
		else
			frame.powerBar:SetHeight(frame.powerBar:GetHeight() + seperatorSize)
		end
	else
		frame.horizDivider:Hide()

		if frame.powerBar.vertical then
			if frame.powerBar:GetWidth() > seperatorSize then
				frame.powerBar:SetWidth(frame.powerBar:GetWidth() - seperatorSize)
			else
				frame.powerBar:SetWidth(hiddenSize)
			end
		else
			if frame.powerBar:GetHeight() > seperatorSize then
				frame.powerBar:SetHeight(frame.powerBar:GetHeight() - seperatorSize)
			else
				frame.powerBar:SetHeight(hiddenSize)
			end
		end
	end
end

function ns.CUF_SetSeperatorVertical(frame, enable, togglePosition)
	frame.horizDivider:ClearAllPoints()
	frame.horizDivider:SetParent(frame.powerBar)
	frame.horizDivider:SetDrawLayer("BORDER", 5)

	if enable then
		frame.horizDivider:SetTexture("Interface\\RaidFrame\\Raid-VSeparator")
		frame.horizDivider:SetTexCoord(0, 0.25, 0, 1)
		frame.horizDivider:SetWidth(1)

		if togglePosition then -- left
			frame.horizDivider:SetPoint("TOPRIGHT")
			frame.horizDivider:SetPoint("BOTTOMRIGHT")
		else -- right
			frame.horizDivider:SetPoint("TOPLEFT")
			frame.horizDivider:SetPoint("BOTTOMLEFT")
		end
	else
		frame.horizDivider:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
		frame.horizDivider:SetTexCoord(0, 1, 0, 0.25)
		frame.horizDivider:SetHeight(2)

		if togglePosition then -- top
			frame.horizDivider:SetPoint("BOTTOMLEFT")
			frame.horizDivider:SetPoint("BOTTOMRIGHT")
		else -- bottom
			frame.horizDivider:SetPoint("TOPLEFT")
			frame.horizDivider:SetPoint("TOPRIGHT")
		end
	end
end

-- ==== [Texts] ========================================
function ns.CUF_SetNameColor(frame, r, g, b)
	frame.name:SetVertexColor(r or 1, g or 1, b or 1, 1)
end

function ns.CUF_SetNameText(frame, size) -- FIXME: use GetTextWidth()
	local unitName, server = string.split(" - ", GetUnitName(frame.unit, true))

	if ns.db.name.format == 'shorten' then
		unitName = ns:ShortenString(unitName, size or 10)
	elseif ns.db.name.format == 'cut' then
		unitName = ns.utf8sub(unitName, 1, size or 10)
	end

	if ns.db.name.serverFormat == 'full' and server then
		unitName = unitName .. " - " .. server
	elseif ns.db.name.serverFormat == 'short' and server then
		unitName = ns.db.name.serverPrefix .. unitName .. ns.db.name.serverSuffix
	else -- 'none'
		-- use only name part
	end

	frame.name:SetText(unitName)
end

function ns.CUF_SetNameJustifyH(frame, justify)
	frame.name:SetJustifyH(justify or "LEFT")
end

function ns.CUF_SetNameFont(frame, font)
	ns:Util_UpdateFont(frame.name, font, ns.db.name.fontSize, ns.db.name.fontStyle)
end
function ns.CUF_SetNameFontSize(frame, size)
	ns:Util_UpdateFont(frame.name, ns.db.name.font, size, ns.db.name.fontStyle)
end
function ns.CUF_SetNameFontStyle(frame, style)
	style = style ~= "NONE" and style or nil
	ns:Util_UpdateFont(frame.name, ns.db.name.font, ns.db.name.fontSize, style)
end

function ns.CUF_SetStatusColor(frame, r, g, b)
	frame.statusText:SetVertexColor(r or 0.5, g or 0.5, b or 0.5, 1)
end

function ns.CUF_SetStatusText(frame)
	local setting = frame.optionTable.healthText
	if (setting == 'losthealth' or setting == 'health') and ns.db.status.format == 'shorten'
		and UnitIsConnected(frame.unit) and not UnitIsDeadOrGhost(frame.displayedUnit) then
		local value = frame.statusText:GetText()
		frame.statusText:SetText( ns:ShortenNumber(value) )
	end
end

function ns.CUF_SetStatusJustifyH(frame, justify)
	frame.name:SetJustifyH(justify or "LEFT")
end

function ns.CUF_SetStatusFont(frame, font)
	ns:Util_UpdateFont(frame.name, font, ns.db.name.fontSize, ns.db.name.fontStyle)
end
function ns.CUF_SetStatusFontSize(frame, size)
	ns:Util_UpdateFont(frame.name, ns.db.name.font, size, ns.db.name.fontStyle)
end
function ns.CUF_SetStatusFontStyle(frame, style)
	style = style ~= "NONE" and style or nil
	ns:Util_UpdateFont(frame.name, ns.db.name.font, ns.db.name.fontSize, style)
end

function ns:Util_UpdateFont(fontInstance, font, fontSize, fontStyle)
	fontInstance:SetFont(font or "Fonts\\FRIZQT__.TTF", fontSize or 10, fontStyle)
end
