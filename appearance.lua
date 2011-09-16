local _, ns = ...

--[[ TODO
-- http://wow.go-hero.net/framexml/14545/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameReservationManager.lua

- CompactUnitFrame_UpdateRoleIcon; also does vehicle icon
- frame.readyCheckIcon ?
- raid warnings
- aura filtering -> CompactUnitFrame_UpdateAuras, CompactUnitFrame_UtilShouldDisplayBuff, CompactUnitFrame_UtilShouldDisplayDebuff
- CompactUnitFrame_SetMaxBuffs, _SetMaxDebuffs, and _SetMaxDispelDebuffs. (If you're setting it to greater than the default, make sure to create new buff/debuff frames and position them.)
]]--

function ns:ManagerSetup(frame)
	-- see: http://wow.go-hero.net/framexml/14545/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameManager.lua
	if ns.config.frames.disableCUF then
		frame:UnregisterAllEvents()
		frame:Hide()

		frame.container:UnregisterAllEvents()
		frame.container:Hide()
		
		HidePartyFrame()
		-- UIErrorsFrame:Hide()

		return
	end

	-- recreate left border (commented out by Blizzard)
	local borderLeft = frame:CreateTexture("CompactRaidFrameManagerBorderLeft")
	borderLeft:SetSize(10, 0)
	borderLeft:SetPoint("TOPLEFT", _G["CompactRaidFrameManagerBorderTopLeft"], "BOTTOMLEFT", 1, 0)
	borderLeft:SetPoint("BOTTOMLEFT", _G["CompactRaidFrameManagerBorderBottomLeft"], "TOPLEFT", -1, 0)
	borderLeft:SetTexture("Interface\\RaidFrame\\RaidPanel-Left")
	borderLeft:SetVertTile(true)

	--[[ _G['CompactRaidFrameManagerBg']
		file="Interface\FrameGeneral\UI-Background-Rock" horizTile="true" vertTile="true"
		"TOPLEFT", , "$parentBorderTopLeft", 7, -6; "BOTTOMRIGHT", , "$parentBorderBottomRight", -7, 7 ]]

	if ns.config.frames.pullout.minify then
		local borderParts = { 'BorderTop', 'BorderBottom', --[['BorderLeft', 'BorderRight',]] 'BorderTopLeft', 'BorderBottomLeft', --[['BorderTopRight', 'BorderBottomRight' ]] } -- what's commented here will not be hidden later

		hooksecurefunc("CompactRaidFrameManager_Expand", function(self)
			local currentHeight = 84;
			if self.displayFrame.filterOptions:IsShown() then
				currentHeight = currentHeight + self.displayFrame.filterOptions:GetHeight()
			end
			if self.displayFrame.leaderOptions:IsShown() then
				currentHeight = currentHeight + self.displayFrame.leaderOptions:GetHeight()
			end

			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", (ns.config.frames.pullout.posX or 0) -7, ns.config.frames.pullout.posY or -140)
			self:SetSize(200, currentHeight)
			
			for _, region in ipairs( borderParts ) do
				_G['CompactRaidFrameManager'..region]:Show()
			end

			self.toggleButton:GetNormalTexture():SetTexCoord(0.5, 1, 0, 1)
			self.toggleButton:SetPoint("RIGHT", -9, 0)
			self.toggleButton:SetSize(16, 64)
		end)
		hooksecurefunc("CompactRaidFrameManager_Collapse", function(self)
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", ns.config.frames.pullout.posX or 0, ns.config.frames.pullout.posY or -140)
			self:SetSize(16, 44)

			for _, region in ipairs( borderParts ) do
				_G['CompactRaidFrameManager'..region]:Hide()
			end

			self.toggleButton:GetNormalTexture():SetTexCoord(0.1, 0.5, 0.3, 0.7) -- (0.2, 0.5, 0.25, 0.73)
			self.toggleButton:SetPoint("RIGHT", -6, 1)
			self.toggleButton:SetSize(16, 32)
		end)
		CompactRaidFrameManager_Collapse( CompactRaidFrameManager )
	end

	if ns.config.frames.showSolo then
		frame:Show()
	end

	ns:ContainerSetup(frame.container)
	ns:RegisterHooks()
end

function ns:ContainerSetup(frame)
	-- see: http://wow.go-hero.net/framexml/14545/Blizzard_CompactRaidFrames/Blizzard_CompactRaidFrameContainer.lua

	--[[
	FlowContainer_GetUsedBounds(container) :: size x, size y
	FlowContainer_SetOrientation(container, "horizontal") :: first fill direction
	FlowContainer_SetMaxPerLine(container, maxPerLine)
	container.flowFrames, self.frameUpdateList = { normal = {}, mini = {}, group = {} } -> table with unit frames
	container.units -> unit identifiers
	/run CompactRaidFrameContainer_AddUnitFrame(CompactRaidFrameContainer, "player", "raid");
	]]
end

function ns:RegisterHooks()
	-- container hooks
	hooksecurefunc("CompactRaidFrameContainer_OnLoad", ns.ContainerSetup)
	hooksecurefunc("CompactRaidFrameContainer_LayoutFrames", ns.UpdateAllFrames) -- CompactRaidFrameContainer_TryUpdate

	hooksecurefunc("CompactRaidFrameManager_UpdateShown", function(frame)
		if ns.config.frames.showSolo then
			CompactRaidFrameManager:Show()
		end
	end)

	--[[ 
		CompactUnitFrameProfiles_ApplyCurrentSettings, CompactUnitFrameProfiles_UpdateCurrentPanel, CompactUnitFrameProfilesCheckButton_Update
		FlowContainer_DoLayout, FlowContainer_ResumeUpdates, CompactRaidFrameContainer_UpdateBorder
		CompactRaidFrameContainer_UpdateDisplayedUnits, CompactUnitFrame_UpdateAll, CompactRaidFrameContainer_ApplyToFrames
		CompactUnitFrame_SetUpFrame, DefaultCompactMiniFrameSetup, DefaultCompactUnitFrameSetup
	]]

	-- unit frame hooks
	hooksecurefunc("CompactUnitFrame_SetUnit", ns.SetUnit)
	hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ns.UpdateHealthColor)
	hooksecurefunc("CompactUnitFrame_UpdatePowerColor", ns.UpdatePowerColor)
	hooksecurefunc("CompactUnitFrame_UpdateName", ns.UpdateName)
	hooksecurefunc("CompactUnitFrame_UpdateStatusText", ns.UpdateStatus)

	hooksecurefunc("CompactUnitFrame_UtilSetBuff", ns.UpdateBuff)
	hooksecurefunc("CompactUnitFrame_UtilSetDebuff", ns.UpdateDebuff)
	hooksecurefunc("CompactUnitFrame_UtilSetDispelDebuff", ns.DisplayDebuffType)

	-- hooksecurefunc("CompactUnitFrame_UpdateBuffs", ns.UpdateBuffs)

	-- hooksecurefunc("CompactUnitFrame_SetUpFrame", ns.UnitFrameSetup)
	hooksecurefunc("DefaultCompactUnitFrameSetup", ns.UnitFrameSetup)	-- players
	hooksecurefunc("DefaultCompactMiniFrameSetup", ns.UnitFrameSetup)	-- pets
end

function ns:UnitFrameSetup(frame)
	if not frame then return end
	local r, g, b

	frame.menu = function()
		if ns.config.unitframe.menuClickInCombat or not UnitAffectingCombat(frame.displayedUnit) then
			ToggleDropDownMenu(1, nil, frame.dropDown, frame:GetName(), 0, 0)
		end
	end

	--[[ Health Bar ]]--
	if ns.config.health.vertical then
		ns:SetHealthBarVertical(frame)
	end
	frame.healthBar:SetStatusBarTexture( ns.config.health.texture or 'Interface\\RaidFrame\\Raid-Bar-Hp-Fill', 'BORDER');
	frame.healthBar.background:SetTexture( ns.config.health.bgtexture or 'Interface\\RaidFrame\\Raid-Bar-Hp-Bg' )

	r, g, b = ns:GetColorSetting( ns.config.health.bgcolor, frame.unit )
	if r then
		frame.healthBar.background:SetVertexColor(r, g, b)
	end

	--[[ Power Bar ]]--
	ns:ShowHidePowerBar(frame)

	frame.powerBar:SetStatusBarTexture( ns.config.power.texture or 'Interface\\RaidFrame\\Raid-Bar-Resource-Fill', 'BORDER');
	frame.powerBar.background:SetTexture( ns.config.power.bgtexture or 'Interface\\RaidFrame\\Raid-Bar-Resource-Background' )

	r, g, b = ns:GetColorSetting( ns.config.power.bgcolor, frame.unit )
	if r then
		frame.powerBar.background:SetVertexColor(r, g, b)
	end

	--[[ Auras ]]--
	frame.buffFrames[1]:ClearAllPoints()
	frame.buffFrames[1]:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT", -1*(ns.config.buffs.posX or 3), (ns.config.buffs.posY or 0))
	frame.debuffFrames[1]:ClearAllPoints()
	frame.debuffFrames[1]:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", ns.config.debuffs.posX or 3, ns.config.debuffs.posY or 0)

	--[[ Icons ]]--
	-- frame.roleIcon:ClearAllPoints();
	frame.roleIcon:SetPoint("TOPLEFT", frame.healthBar, 3, -2);
	frame.dispelDebuffFrames[1]:SetPoint("TOPRIGHT", frame.healthBar, -3, -2);

	--[[ Texts ]]--
	-- frame.name:SetJustifyH("LEFT");
	-- frame.name:SetPoint("TOPLEFT", frame.roleIcon, "TOPRIGHT", 0, -1);
	-- frame.name:SetPoint("TOPRIGHT", frame.healthBar, -3, -3);
end

function ns:SetHealthBarVertical(frame)
	frame.healthBar:SetOrientation('vertical')
	frame.healthBar:SetRotatesTexture(true)

	frame.myHealPredictionBar:SetOrientation('vertical')
	frame.myHealPredictionBar:ClearAllPoints()
	frame.myHealPredictionBar:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
	frame.myHealPredictionBar:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	frame.myHealPredictionBar:SetHeight(frame.optionsTable.height)
	frame.myHealPredictionBar:SetRotatesTexture(true)

	frame.otherHealPredictionBar:SetOrientation('vertical')
	frame.otherHealPredictionBar:ClearAllPoints()
	frame.otherHealPredictionBar:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
	frame.otherHealPredictionBar:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
	frame.otherHealPredictionBar:SetHeight(frame.optionsTable.height)
	frame.otherHealPredictionBar:SetRotatesTexture(true)
end
function ns:ShowHidePowerBar(frame)
	if not frame.optionsTable then frame.optionsTable = DefaultCompactUnitFrameSetupOptions end
	local powerSize = ns.config.power.size or 8
		  powerSize = frame.optionsTable.displayPowerBar and powerSize or 0
		  powerSize = ns:ShouldDisplayPowerBar(frame) and powerSize or 0

	frame.powerBar:ClearAllPoints()
	frame.healthBar:ClearAllPoints()
	if powerSize > 0 then
		local powerSpacing = (frame.optionsTable.displayBorder and not ns.config.unitframe.hidePowerSeperator) and 2 or 0
		local togglePosition = ns.config.power.changePosition

		if ns.config.power.vertical then
			ns:SetPowerBarVertical(frame, powerSize, powerSpacing, togglePosition)
		else
			ns:SetPowerBarHorizontal(frame, powerSize, powerSpacing, togglePosition)
		end
	else
		ns:SetPowerBarHidden(frame)
	end
end
function ns:SetPowerBarVertical(frame, powerSize, powerSpacing, togglePosition)
	frame.horizDivider:SetTexture("Interface\\RaidFrame\\Raid-VSeparator")
	frame.horizDivider:ClearAllPoints()

	frame.powerBar:SetOrientation('vertical')
	frame.powerBar:SetRotatesTexture(true)

	if togglePosition then
		-- left
		frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 1+powerSize, 1)

		if powerSpacing > 0 then
			frame.horizDivider:SetPoint("TOPLEFT", frame.powerBar, "TOPRIGHT")
			frame.horizDivider:SetPoint("BOTTOMLEFT", frame.powerBar, "BOTTOMRIGHT")
		else
			frame.horizDivider:Hide()
		end

		frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "TOPRIGHT", powerSpacing, 0)
		frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
	else
		-- right
		frame.powerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
		frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -1-powerSize, 1)

		if powerSpacing > 0 then
			frame.horizDivider:SetPoint("TOPRIGHT", frame.powerBar, "TOPLEFT", 6, 0)
			frame.horizDivider:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMLEFT", 6, 0)
		else
			frame.horizDivider:Hide()
		end

		frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
		frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMLEFT", -powerSpacing, 0)
	end
end
function ns:SetPowerBarHorizontal(frame, powerSize, powerSpacing, togglePosition)
	frame.horizDivider:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
	frame.horizDivider:ClearAllPoints()

	if togglePosition then
		-- top
		frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
		frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -1, -1-powerSize)

		if powerSpacing > 0 then
			frame.horizDivider:SetPoint("TOPLEFT", frame.powerBar, "BOTTOMLEFT")
			frame.horizDivider:SetPoint("TOPRIGHT", frame.powerBar, "BOTTOMRIGHT")
		else
			frame.horizDivider:Hide()
		end

		frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "BOTTOMLEFT", 0, -powerSpacing)
		frame.healthBar:SetPoint("BOTTOMRIGHT", frame, -1, 1)
	else
		-- bottom [DEFAULT]
		frame.powerBar:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, powerSize)
		frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

		if powerSpacing > 0 then
			frame.horizDivider:SetPoint("BOTTOMLEFT", frame.powerBar, "TOPLEFT", 0, -6)
			frame.horizDivider:SetPoint("BOTTOMRIGHT", frame.powerBar, "TOPRIGHT", 0, -6)
		else
			frame.horizDivider:Hide()
		end

		frame.healthBar:SetPoint("TOPLEFT", frame, 1, -1)
		frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "TOPRIGHT", 0, powerSpacing)
	end
end
function ns:SetPowerBarHidden(frame)
	frame.healthBar:ClearAllPoints()
	frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
	frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

	-- when hiding unwanted power types, tell the client, too
	frame.powerBar:Hide()
	frame.horizDivider:Hide()
end

function ns:UpdateHealthColor()
	local r, g, b = ns:GetColorSetting( ns.config.health.color, self.unit )
	if r then
		self.healthBar:SetStatusBarColor(r, g, b)
	end
end
function ns:UpdatePowerColor()
	ns:ShowHidePowerBar(self)
	
	local r, g, b = ns:GetColorSetting( ns.config.power.color, self.unit )
	if UnitIsConnected(self.unit) and r then
		self.powerBar:SetStatusBarColor(r, g, b)
	end
end
function ns:UpdateName()
	local name = GetUnitName(self.unit, true)
	if ns.config.name.format == 'shorten' then
		self.name:SetText( ns:ShortenString(GetUnitName(self.unit), ns.config.name.size) )
	end

	local r, g, b = ns:GetColorSetting( ns.config.name.color, self.unit )
	if r then
		self.name:SetVertexColor(r, g, b, 1)
	end
end
function ns:UpdateStatus()
	local value = self.statusText:GetText()
	if UnitIsConnected(self.unit) and not UnitIsDeadOrGhost(self.displayedUnit) 
		and (self.optionTable.healthText == 'losthealth' or self.optionTable.healthText == 'health') then

		if ns.config.status.shorten then
			self.statusText:SetText( ns:ShortenNumber(value) )
		end
	end
end

function ns:UpdateBuffs(frame)
	local frame = frame or self
	if ( not frame.optionTable.displayBuffs ) then
		CompactUnitFrame_HideAllBuffs(frame);
		return;
	end

	local index, frameNum, filter = 1, 1, nil
	while frameNum <= frame.maxBuffs do
		local buffName = UnitBuff(frame.displayedUnit, index, filter)
		if buffName then
			if ns:ShouldDisplayAura(true, frame.displayedUnit, buffName, filter) then
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

function ns:UpdateBuff(buffFrame, unit, index, filter)
	-- ns:Print('Updating buff', buffFrame, unit, index, filter)
end
function ns:UpdateDebuff(debuffFrame, unit, index, filter)
	-- ns:Print('Updating debuff', buffFrame, unit, index, filter)

	-- local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"];
	-- debuffFrame.border:SetVertexColor(color.r, color.g, color.b);
end

function ns:SetUnit(frame, unit)
	-- ns:Print("CompactUnitFrame_SetUnit", frame, unit)
	if CompactRaidFrameManager.collapsed then 	-- [TODO] FIXME
        CompactRaidFrameManager_Collapse(CompactRaidFrameManager)
    else
        CompactRaidFrameManager_Expand(CompactRaidFrameManager)
    end
end

function ns:DisplayDebuffType(dispellDebuffFrame, debuffType, index)
	-- ns:Print('Display debuff type', dispellDebuffFrame:GetName(), debuffType, index)

	-- local color = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
	-- debuffFrame.border:SetVertexColor(color.r, color.g, color.b)
end