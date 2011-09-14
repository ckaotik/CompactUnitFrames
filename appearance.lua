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

	-- CompactRaidFrameManager_ResizeFrame_Reanchor
	-- CompactRaidFrameManager_Collapse

	if ns.config.frames.disableCUF then
		frame:UnregisterAllEvents()
		frame:Hide()

		frame.container:UnregisterAllEvents()
		frame.container:Hide()
		
		HidePartyFrame()
		-- UIErrorsFrame:Hide()

		return
	end

	-- recreate left border (commented by Blizzard)
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
		local borderParts = { 'BorderTop', 'BorderBottom', --[['BorderLeft', 'BorderRight',]] 'BorderTopLeft', 'BorderBottomLeft', --[['BorderTopRight', 'BorderBottomRight' ]] }

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

	if ns.config.frames.showSolo then -- when in a group it will be shown anyhow
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
	hooksecurefunc("CompactRaidFrameContainer_TryUpdate", ns.UpdateAllFrames)

	hooksecurefunc("CompactRaidFrameManager_UpdateShown", function(frame)
		CompactRaidFrameManager_Collapse( CompactRaidFrameManager )	-- [TODO] FIXME
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
	-- hooksecurefunc("DefaultCompactUnitFrameSetup", ns.UnitFrameSetup)	-- players
	-- hooksecurefunc("DefaultCompactMiniFrameSetup", ns.UnitFrameSetup)	-- pets
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
		frame.healthBar:SetOrientation('vertical')
		frame.healthBar:SetRotatesTexture(true)

		frame.myHealPredictionBar:SetOrientation('vertical')
		frame.myHealPredictionBar:ClearAllPoints()
		frame.myHealPredictionBar:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
		frame.myHealPredictionBar:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		frame.myHealPredictionBar:SetHeight(DefaultCompactUnitFrameSetupOptions.height)
		frame.myHealPredictionBar:SetRotatesTexture(true)

		frame.otherHealPredictionBar:SetOrientation('vertical')
		frame.otherHealPredictionBar:ClearAllPoints()
		frame.otherHealPredictionBar:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
		frame.otherHealPredictionBar:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		frame.otherHealPredictionBar:SetHeight(DefaultCompactUnitFrameSetupOptions.height)
		frame.otherHealPredictionBar:SetRotatesTexture(true)
	end
	frame.healthBar:SetStatusBarTexture( ns.config.health.texture or 'Interface\\RaidFrame\\Raid-Bar-Hp-Fill', 'BORDER');
	frame.healthBar.background:SetTexture( ns.config.health.bgtexture or 'Interface\\RaidFrame\\Raid-Bar-Hp-Bg' )

	r, g, b = ns:GetColorSetting( ns.config.health.bgcolor, frame.unit )
	if r then
		frame.healthBar.background:SetVertexColor(r, g, b)
	end

	--[[ Power Bar ]]--
	local powerSize = ns.config.power.size or 8
		  powerSize = DefaultCompactUnitFrameSetupOptions.displayPowerBar and powerSize or 0
		  powerSize = ns:ShouldDisplayPowerBar(frame) and powerSize or 0
	local powerSpacing = DefaultCompactUnitFrameSetupOptions.displayBorder and 2 or 0

	frame.powerBar:ClearAllPoints()
	frame.healthBar:ClearAllPoints()
	if powerSize > 0 and ns.config.power.vertical then
		frame.powerBar:SetOrientation('vertical')
		frame.powerBar:SetRotatesTexture(true)

		if ns.config.power.changePosition then
			-- left
			frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMLEFT", 1 + powerSize, 1)

			frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "TOPRIGHT", powerSpacing, 0);
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

			frame.horizDivider:Hide()
		else
			-- right
			frame.powerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -1)
			frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -1 - powerSize, 0)

			frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1);
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMLEFT", -1*powerSpacing, 0)

			frame.horizDivider:Hide()
		end
	elseif powerSize > 0 then
		if ns.config.power.changePosition then
			-- top
			frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, 1)
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -1, -1 - powerSize)
		
			frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "BOTTOMLEFT", 0, -1*powerSpacing);
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

			frame.horizDivider:Hide()
		else
			-- bottom [DEFAULT]
			frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1 + powerSize)

			frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, -1 * powerSpacing)
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

			frame.horizDivider:SetHeight(powerSize)
			frame.horizDivider:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 1 + powerSize)
			frame.horizDivider:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 1 + powerSize)
		end
	else
		frame.healthBar:ClearAllPoints()
		frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -1)
  		frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

  		-- when hiding unwanted power types, tell the client, too
		frame.powerBar:Hide()
		frame.horizDivider:Hide()
	end 
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

	local overlay = CreateFrame("Button", frame:GetName() .. "CUFOverlay", frame, "CompactAuraTemplate")
	overlay:SetPoint("CENTER", ns.config.indicators.center.posX or 0, ns.config.indicators.center.posY or 0)
	overlay:EnableMouse(false); overlay:EnableMouseWheel(false)
	frame.overlay = overlay
end

function ns:UpdateHealthColor()
	local r, g, b = ns:GetColorSetting( ns.config.health.color, self.unit )
	if r then
		self.healthBar:SetStatusBarColor(r, g, b)
	end
end
function ns:UpdatePowerColor()
	local r, g, b = ns:GetColorSetting( ns.config.power.color, self.unit )
	if UnitIsConnected(self.unit) and r then
		self.powerBar:SetStatusBarColor(r, g, b)
	end
end
function ns:UpdateName()
	local name = GetUnitName(self.unit, true)
	if ns.config.name.format == 'shorten' then
		-- self.name:SetText()
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
			self.statusText:SetText( ns:ShortValue(value) )
		end
	end
end

--[[ function ns:UpdateBuffs(frame)
	if ( not frame.optionTable.displayBuffs ) then
		CompactUnitFrame_HideAllBuffs(frame);
		return;
	end

	local index, frameNum, filter = 1, 1, nil
	while frameNum <= frame.maxBuffs do
		local buffName = UnitBuff(frame.displayedUnit, index, filter)
		if buffName then
			if ns:ShouldDisplayBuff(frame.displayedUnit, index, filter) then
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
end ]]--

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
end

function ns:DisplayDebuffType(dispellDebuffFrame, debuffType, index)
	-- ns:Print('Display debuff type', dispellDebuffFrame:GetName(), debuffType, index)
end