local addonName, addon, _ = ...

-- GLOBALS: GameTooltip, DEFAULT_CHAT_FRAME, RAID_CLASS_COLORS
-- GLOBALS: UnitGroupRolesAssigned, UnitClass, UnitIsFriend, AbbreviateLargeNumbers, InCombatLockdown, CompactUnitFrameProfiles_ApplyCurrentSettings
-- GLOBALS: select, wipe, pairs, tonumber, tostringall, strlenutf8, string, table
local strlen, strfind, strmatch, strjoin, strgsub = string.len, string.find, string.match, string.join, string.gsub

-- --------------------------------------------------------
--  Generic Utils
-- --------------------------------------------------------
function addon.Print(message, ...)
	DEFAULT_CHAT_FRAME:AddMessage("|cff22EE55CompactUnitFrames|r "..message
		..' '..strjoin(", ", tostringall(...) ))
end
function addon.Debug(...)
	if addon.db.profile.debug then
		addon.Print("!", (strjoin(", ", tostringall(...))))
	end
end

function addon:HideTooltip() GameTooltip:Hide() end
function addon:ShowTooltip()
	if self.tiptext then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end
end

function addon:Find(table, value)
	if not table then return end
	for k, v in pairs(table) do
		if (v and value and v == value) then return true end
	end
	return nil
end

function addon:ShortenNumber(value)
	value = value and tonumber(value) or nil
	return value and AbbreviateLargeNumbers(value)
end

function addon:ShortenString(string, size)
	if not string then return "" end
	return (strlenutf8(string) > size) and strgsub(string, "%s?(.[\128-\191]*)%S+%s", "%1. ") or string
end

local afterCombat = {}
function addon.RunAfterCombat()
	for frame, tasks in pairs(afterCombat) do
		for _, func in pairs(tasks) do
			func(frame)
		end
		wipe(tasks)
	end
	if addon.db.profile.frames.taintUpdate then
		CompactUnitFrameProfiles_ApplyCurrentSettings()
	end
	addon:UnregisterEvent('PLAYER_REGEN_ENABLED')
end
function addon.DelayInCombat(frame, func)
	local delay = nil
	if InCombatLockdown() then
		if not afterCombat[frame] then afterCombat[frame] = {} end
		table.insert(afterCombat[frame], func)
		addon:RegisterEvent('PLAYER_REGEN_ENABLED', addon.RunAfterCombat)
		delay = true
	end
	return delay
end

-- --------------------------------------------------------
--  Color Utils
-- --------------------------------------------------------
-- checks config.lua for correct color
local roleColors = {
	TANK    = {  0/255, 20/255, 71/255},
	DAMAGER = {123/255, 10/255, 16/255},
	HEALER  = { 26/255, 73/255, 53/255},
}
function addon:GetColorSetting(scope, option, unit)
	local r, g, b, a
	local colorType, color = scope[option..'Type'], scope[option]

	if not colorType or colorType == '' or colorType == 'default' then
		return nil
	elseif colorType == 'custom' then
		r, g, b, a = unpack(color)
	elseif colorType == 'role' and unit then
		local role = UnitGroupRolesAssigned(unit) -- select(10, GetRaidRosterInfo(UnitInRaid(unit)))
		r, g, b, a = unpack(roleColors[role])
	elseif colorType == 'class' and unit then
		r, g, b = addon:GetClassColor(unit)
	end
	return r, g, b, a
end

-- provides class or reaction color for a given unit
function addon:GetClassColor(unit)
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

-- --------------------------------------------------------
--  UTF-8 is hard
-- --------------------------------------------------------
-- @see http://wowprogramming.com/snippets/UTF-8_aware_stringsub_7
local function chsize(char)
	if not char then return 0
	elseif char > 240 then return 4
	elseif char > 225 then return 3
	elseif char > 192 then return 2
	else return 1
	end
end

function addon.utf8sub(str, startChar, numChars)
	local startIndex = 1
	while startChar > 1 do
		local char = string.byte(str, startIndex)
		startIndex = startIndex + chsize(char)
		startChar = startChar - 1
	end

	local currentIndex = startIndex
	while numChars > 0 and currentIndex <= #str do
		local char = string.byte(str, currentIndex)
		currentIndex = currentIndex + chsize(char)
		numChars = numChars -1
	end
	return str:sub(startIndex, currentIndex - 1)
end
