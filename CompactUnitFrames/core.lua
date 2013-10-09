local addonName, ns, _ = ...
CompactUnitFrames = ns -- external reference

-- GLOBALS: CompactUnitFrames, CUF_GlobalDB, RAID_CLASS_COLORS, GameTooltip, DEFAULT_CHAT_FRAME, CompactRaidFrameManager, CompactRaidFrameContainer, CompactUnitFrameProfiles
-- GLOBALS: UnitIsConnected, UnitPowerType, UnitClass, UnitIsFriend, GetSpellInfo, UnitBuff, UnitDebuff, UnitGroupRolesAssigned, AbbreviateLargeNumbers, InCombatLockdown, GetNumGroupMembers, GetActiveSpecGroup, GetRaidProfileOption, GetRaidProfileName, GetNumRaidProfiles, GetActiveRaidProfile
-- GLOBALS: select, type, pairs, ipairs, math.floor, tonumber, tostringall, hooksecurefunc, loadstring
-- GLOBALS: CompactUnitFrame_UtilShouldDisplayBuff, CompactUnitFrameProfiles_ApplyCurrentSettings, CompactUnitFrameProfiles_SetLastActivationType, CompactRaidFrameManager_ResizeFrame_UpdateContainerSize, CompactUnitFrameProfiles_GetAutoActivationState, CompactUnitFrameProfiles_GetLastActivationType, CompactUnitFrameProfiles_ProfileMatchesAutoActivation, CompactUnitFrameProfiles_ActivateRaidProfile, CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether
local strlen, strfind, strmatch, strjoin, strgsub = string.len, string.find, string.match, string.join, string.gsub

function ns.RunAutoActivation()
	local success, _, activationType, enemyType = CompactUnitFrameProfiles_GetAutoActivationState()
	-- returns: true, 40, "world", "PvE"
	if not success then return end

	-- group sizes: 2, 3, 5, 10, 15, 25, 40
	local numPlayers = GetNumGroupMembers()
	numPlayers = (numPlayers <= 2 and 2) or (numPlayers <= 3 and 3) or (numPlayers <= 5 and 5)
			or (numPlayers <= 10 and 10) or (numPlayers <= 15 and 15) or (numPlayers <= 25 and 25) or 40

	local lastActivationType, lastNumPlayers, lastSpec, lastEnemyType = CompactUnitFrameProfiles_GetLastActivationType()
	local spec = GetActiveSpecGroup()

	if lastSpec == spec and lastEnemyType == enemyType and lastNumPlayers == numPlayers
		or CompactUnitFrameProfiles_ProfileMatchesAutoActivation(GetActiveRaidProfile(), numPlayers, spec, enemyType) then
		return
	end

	local changed
	for i=1, GetNumRaidProfiles() do
		local profile = GetRaidProfileName(i)
		if CompactUnitFrameProfiles_ProfileMatchesAutoActivation(profile, numPlayers, spec, enemyType) then
			CompactUnitFrameProfiles_ActivateRaidProfile(profile)
			CompactUnitFrameProfiles_SetLastActivationType(activationType, numPlayers, spec, enemyType)
			changed = true
			break
		end
	end
	-- print('should display profile for', numPlayers, changed)
end

function ns.SetDefaultSettings(db, defaults)
    for key, value in pairs(defaults) do
        if db[key] == nil then
            if type(value) == 'table' then
                db[key] = {}
                ns.SetDefaultSettings(db[key], value)
            else
                db[key] = value
            end
        else
            if type(value) == 'table' then
                ns.SetDefaultSettings(db[key], value)
            end
        end
    end
end

local eventFrame = CreateFrame("Frame")
local function eventHandler(self, event, arg1)
	local showPets = GetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "displayPets")

	if event == "ADDON_LOADED" and arg1 == addonName then
		if not CUF_GlobalDB then CUF_GlobalDB = {} end
		ns.db = CUF_GlobalDB
		ns.SetDefaultSettings(ns.db, ns.defaults)

		ns.ManagerSetup()
		ns.ContainerSetup()
		ns.RegisterHooks()
		ns.RunAutoActivation()

		-- update any existing frames
		ns.UpdateAll(function(frame)
			ns.SetUpClicks(frame)
			ns.UpdateHealthColor(frame)
			ns.UpdatePowerColor(frame)
			ns.UpdateName(frame)
			ns.UpdateStatus(frame)
		end)

		eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
		eventFrame:RegisterEvent("GROUP_JOINED")
		eventFrame:RegisterEvent("UNIT_PET")
		eventFrame:UnregisterEvent("ADDON_LOADED")

	elseif event == "GROUP_JOINED" or event == "GROUP_ROSTER_UPDATE" then
		ns.RunAutoActivation()
	elseif event ==  (showPets and event == "UNIT_PET") then
		ns.UpdatePets(arg1)
	elseif event == "PLAYER_REGEN_ENABLED" then
		ns.RunAfterCombat()
		eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
	end
end
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", eventHandler)
ns.eventFrame = eventFrame

function ns.UpdateAll(func)
	for i, unitFrame in ipairs(CompactRaidFrameContainer.flowFrames) do
		if unitFrame and unitFrame.IsVisible then
			ns.UpdateVisible(unitFrame)
			if func then func(unitFrame) end
		end
	end
end

function ns.UpdatePets(unit, func)
	for i, unitFrame in ipairs(CompactRaidFrameContainer.flowFrames) do
		if (unit and unitFrame.unit == unit..'pet') or (not unit and unitFrame.unit:find('pet')) then
			CompactUnitFrame_UpdateHealth(unitFrame)
			CompactUnitFrame_UpdateName(unitFrame)
			if func then func(unitFrame) end
		end
	end
end

local afterCombat = {}
function ns.RunAfterCombat()
	for frame, tasks in pairs(afterCombat) do
		for _, func in pairs(tasks) do
			func(frame)
		end
		wipe(tasks)
	end

	if ns.db.frames.taintUpdate then
		CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether:Click()
		CompactUnitFrameProfilesGeneralOptionsFrameKeepGroupsTogether:Click()
	end
end
function ns.DelayInCombat(frame, func)
	local delay = nil
	if InCombatLockdown() then
		if not afterCombat[frame] then afterCombat[frame] = {} end
		tinsert(afterCombat[frame], func)
		eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		delay = true
	end
	return delay
end

-- == Misc Utility ==============================================
function ns.Print(message, ...)
	DEFAULT_CHAT_FRAME:AddMessage("|cff22EE55CompactUnitFrames|r "..message
		..' '..strjoin(", ", tostringall(...) ))
end
function ns.Debug(...)
	if ns.db.debug then
		ns.Print("!", (strjoin(", ", tostringall(...))))
	end
end

function ns:Find(table, value)
	if not table then return end
	for k, v in pairs(table) do
		if (v and value and v == value) then return true end
	end
	return nil
end

function ns:HideTooltip() GameTooltip:Hide() end
function ns:ShowTooltip()
	if self.tiptext then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end
end

function ns:ShortenNumber(value)
	value = value and tonumber(value) or nil
	return value and AbbreviateLargeNumbers(value)
end

function ns:ShortenString(string, size)
	if not string then return "" end
	return (strlenutf8(string) > size) and strgsub(string, "%s?(.[\128-\191]*)%S+%s", "%1. ") or string
end

-- checks config.lua for correct color
function ns:GetColorSetting(data, unit)
	local r, g, b
	if not data or data == '' or data == 'default' then
		return nil
	elseif data ~= 'class' then
		_, _, r, g, b = strfind(data, "(.-):(.-):(.+)")
		r, g, b = tonumber(r or ''), tonumber(g or ''), tonumber(b or '')
	elseif unit then
		r, g, b = ns:GetClassColor(unit)
	end
	return r, g, b
end

-- provides class or reaction color for a given unit
function ns:GetClassColor(unit)
	local matchUnit, unitNum = strmatch(unit, "^(.+)pet(%d*)$")
	if matchUnit then
		unit = matchUnit .. unitNum
	end

	local r, g, b = 0.5, 0.0, 0.0
	if UnitIsFriend("player", unit) then
		local classColor = RAID_CLASS_COLORS[ select(2, UnitClass(unit)) ]
		if classColor then
			r, g, b = classColor.r, classColor.g, classColor.b;
		else
			r, g, b = 0.8, 1.0, 0.8;
		end
	end
	return r, g, b
end

function ns:ShouldDisplayPowerBar(frame)
	local displayBlizzard = GetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, "displayPowerBar")
	if not displayBlizzard then	return end
	if not frame.displayedUnit and not frame.unit then return end
	if not UnitIsConnected(frame.displayedUnit) or not UnitIsConnected(frame.unit) then return end

	if ns.db.power.types.showSelf and (frame.unit == "player" or frame.displayedUnit == "player") then
		return true
	elseif strfind(frame.unit, "pet") then
		return ns.db.power.types.showPets
	end

	local powerType = UnitPowerType(frame.displayedUnit or frame.unit)	-- show data of the actual displayed unit
	local settingsType = ns.db.power.types[powerType]
	local showType = ns.db.power.types.showUnknown
	if settingsType then
		showType = not settingsType.hide
	end

	local unitRole = UnitGroupRolesAssigned(frame.unit)
	local showRole = ns.db.power.roles[unitRole]

	return showType and showRole
end

function ns:ShouldDisplayAura(isBuff, unit, index, filter)
	local dataTable, func
	if isBuff then
		dataTable = ns.db.buffs
		func = UnitBuff
	else
		dataTable = ns.db.debuffs
		func = UnitDebuff
	end
	local auraName, _, _, _, _, auraDuration, _, _, _, _, _, _, auraIsBoss = func(unit, index, filter)


	if dataTable.hidePermanent and auraDuration == 0 then return nil end
	if dataTable.showBoss and auraIsBoss then return true end

	local spell
	for _, dataSpell in pairs(dataTable.hide) do
		if type(dataSpell) == "number" then
			spell = ( GetSpellInfo(dataSpell) )
		else
			spell = dataSpell
		end

		if spell == auraName then
			return nil
		end
	end
	for _, dataSpell in pairs(dataTable.show) do
		if type(dataSpell) == "number" then
			spell = GetSpellInfo(dataSpell)
		else
			spell = dataSpell
		end

		if spell == auraName then
			return true
		end
	end
	-- fallback
	return CompactUnitFrame_UtilShouldDisplayBuff(unit, index, filter)
end
