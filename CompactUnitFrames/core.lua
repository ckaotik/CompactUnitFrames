local _, ns = ...
ns.db = CUF_GlobalDB
ns.name = "CompactUnitFrames"
ns.color = "22EE55"

function ns:Enable()
	ns.requiresUpdate = nil

	ns:ManagerSetup( CompactRaidFrameManager )
	ns:ContainerSetup( CompactRaidFrameContainer )
	ns:UpdateAllFrames( CompactUnitFrame_UpdateAll )
end
function ns:Disable()
	-- [TODO]
end

local eventFrame = CreateFrame("Frame", "CompactUnitFrames_EventHandler", UIParent)
local function eventHandler(self, event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == ns.name then
		if CUF_GlobalDB then
			ns.db = CUF_GlobalDB
		else
			ns.db = ns.config
		end

		ns:Enable()

		hooksecurefunc("CreateFrame", function (frameType, frameName)
			if ns.notSecure then return end

			if frameName and frameName:match("Compact.-Frame") then
				local secure, addon = issecurevariable(_G, frameName);
				if (not secure) then
					self:RegisterEvent("GROUP_ROSTER_UPDATE")
					self:RegisterEvent("UNIT_PET")
					print('non-secure compactunitframe created:', frameName)
					ns.notSecure = true
				end
			end
		end)

		self:UnregisterEvent("ADDON_LOADED")

	elseif event == "PLAYER_REGEN_ENABLED" then
		if ns.requiresUpdate then
			-- CompactUnitFrameProfiles_ApplyCurrentSettings()
			ns.requiresUpdate = nil

			eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
		end
		ns:AfterCombatUpdate()

	elseif event == "GROUP_ROSTER_UPDATE" or event == "UNIT_PET" then
		-- ns.requiresUpdate = true
		-- eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	end
end
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", eventHandler)
ns.eventFrame = eventFrame

function ns:Call(func, frame, ...)
	if false and InCombatLockdown() then -- [TODO] register for later update
		-- eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	else
		func(frame, ...)
	end
end

function ns:AfterCombatUpdate()
	for i, frame in ipairs(CompactRaidFrameContainer.units) do
		if frame.updateRequired then
			ns.UnitFrameSetup(frame)
		end
	end
	eventFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
end

function ns:UpdateAllFrames(afterFunction, ...)
	local group, member, frame
	for member = 1, MAX_RAID_MEMBERS do
		frame = _G["CompactRaidFrame"..member]
		if frame then
			ns.UnitFrameSetup(frame)
			if afterFunction then
				afterFunction(frame, ...)
			end
		end
	end

	for group = 1, MAX_RAID_GROUPS do
		for member = 1, MEMBERS_PER_RAID_GROUP do
			frame = _G["CompactRaidGroup"..group.."Member"..member]
			if frame then
				ns.UnitFrameSetup(frame)
				if afterFunction then
					afterFunction(frame, ...)
				end
			end
		end
	end

	for member = 1, MEMBERS_PER_RAID_GROUP do
    	local frame = _G["CompactPartyFrameMember"..member]
    	if frame then
			ns.UnitFrameSetup(frame)
			if afterFunction then
				afterFunction(frame, ...)
			end
		end
	end
end

-- == Misc Utility ==============================================
function ns:Print(message, ...)
	DEFAULT_CHAT_FRAME:AddMessage("|cff"..(ns.color)..(ns.name).."|r "..message
		..' '..string.join(", ", tostringall(...) ))
end
function ns:Debug(...)
	if ns.db.debug then
		ns.Print("!", (string.join(", ", tostringall(...))))
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
	return (string.len(string) > size) and string.gsub(string, "%s?(.[\128-\191]*)%S+%s", "%1. ") or string
end

-- checks config.lua for correct color
function ns:GetColorSetting(data, unit)
	local r, g, b
	if not data or data == '' or data == 'default' then
		return nil
	elseif data == 'class' then
		r, g, b = ns:GetClassColor(unit)
	else
		_, _, r, g, b = string.find(data, "(.-):(.-):(.+)")
		r, g, b = tonumber(r or ''), tonumber(g or ''), tonumber(b or '')

		if not (r and g and b) then	return nil end
	end
	return r, g, b
end

-- provides class or reaction color for a given unit
function ns:GetClassColor(unit)
	local matchUnit, unitNum = string.match(unit, "^(.+)pet(%d*)$")
	if matchUnit then
		unit = matchUnit .. unitNum
	end

	local r, g, b
	local classColor = RAID_CLASS_COLORS[ select(2, UnitClass(unit)) ]
	if classColor then
		r, g, b = classColor.r, classColor.g, classColor.b;
	else
		if ( UnitIsFriend("player", unit) ) then
			r, g, b = 0.8, 1.0, 0.8;
		else
			r, g, b = 0.5, 0.0, 0.0;
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
	elseif string.find(frame.unit, "pet") then
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
			spell = ( GetSpellInfo(dataSpell) )
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

CompactUnitFrames = ns -- external reference
