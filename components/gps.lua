local addonName, addon, _ = ...
local plugin = {}
addon.GPS = plugin

-- GLOBALS: CreateFrame, UnitIsPlayer, UnitExists, UnitInRange, UnitIsConnected, UnitIsUnit, UnitInParty, UnitInRaid, GetPlayerMapPosition, GetPlayerFacing, GetMouseFocus
local tinsert, tremove = table.insert, table.remove

-- thanks, Torhal! http://www.wowinterface.com/forums/showpost.php?p=166983&postcount=14
local AcquireFrame, ReleaseFrame, GetFrameGPS
do
	local OnUpdateFrame, lastUpdate = nil, 0
	local frame_cache, frame_assignments, createdFrames = {}, {}, 0
	function GetFrameGPS(unitframe)
		return frame_assignments[unitframe]
	end
	local function UpdateAll(self, elapsed)
		lastUpdate = lastUpdate + elapsed
		if lastUpdate and lastUpdate < 0.1 then return end
		lastUpdate = 0
		for unitframe, gps in pairs(frame_assignments) do
			plugin.Update(unitframe)
		end
	end
	function AcquireFrame(unitframe)
		if createdFrames == 0 then
			OnUpdateFrame = CreateFrame('Frame')
			OnUpdateFrame:SetScript('OnUpdate', UpdateAll)
		end
		OnUpdateFrame:Show()

		local gps = tremove(frame_cache)
		if not gps then
			gps = CreateFrame('Frame', nil, UIParent)
			gps:EnableMouse(false)
			gps:EnableMouseWheel(false)
			gps:Hide()
			createdFrames = createdFrames + 1
		end
		frame_assignments[unitframe] = gps
		return gps
	end
	function ReleaseFrame(unitframe)
		local gps = GetFrameGPS(unitframe)
		if not gps then return end
		gps:Hide()
		gps:SetParent(nil)
		gps:ClearAllPoints()
		tinsert(frame_cache, gps)
		frame_assignments[unitframe] = nil
		-- disabled the last active GPS
		if next(frame_assignments) == nil then
			OnUpdateFrame:Hide()
		end
	end
end

local atan2, sqrt, floor = math.atan2, math.sqrt, math.floor
local function GetDistance(unit1, unit2)
	if not unit1 or not UnitExists(unit1) or not UnitIsPlayer(unit1)
		or not unit2 or not UnitExists(unit2) or not UnitIsPlayer(unit2)
		or UnitIsUnit(unit1, unit2) then
		return nil
	end

	local x1, y1 = GetPlayerMapPosition(unit1)
	local x2, y2 = GetPlayerMapPosition(unit2)
	if not x2 then
		-- Patch 7.1 removed this API in instances.
		-- TODO: Create a workaround using WorldMap?
		return nil
	end

	if (x1 == 0 and y1 == 0) or (x2 == 0 and y2 == 0) then return nil end
	local dx, dy = x2 - x1, y2 - y1

	local distance = sqrt(dx^2 + dy^2)
		  distance = floor(distance * 1000 + 0.5)
	local angle = atan2(dx, dy) + math.pi

	return distance, angle
end

function plugin.Update(unitframe)
	local gps = GetFrameGPS(unitframe)
	local unit = unitframe.unit
	if not gps or not unit or UnitIsUnit(unit, 'player') then return end

	local onlyOutOfRange  = not gps.outOfRange or not UnitInRange(unit)
	local onlyOnMouseOver = not gps.onMouseOver or GetMouseFocus() == unitframe
	if (UnitInRaid(unit) or UnitInParty(unit)) and UnitIsConnected(unit) and onlyOutOfRange and onlyOnMouseOver then
		local distance, angle = GetDistance('player', unit)
		if distance and angle then
			if gps.Texture then
				gps.Texture:SetRotation(angle - GetPlayerFacing())
			end
			if gps.Text then
				gps.Text:SetText(distance)
			end
			gps:Show()
		else
			gps:Hide()
		end
	else
		gps:Hide()
	end
end

function plugin.Enable(unitframe)
	-- hooksecurefunc(CompactRaidFrameContainer, 'unitFrameUnusedFunc', plugin.Disable)
	local gps = GetFrameGPS(unitframe) or AcquireFrame(unitframe)
	return gps
end
function plugin.Disable(unitframe)
	ReleaseFrame(unitframe)
end

-- code from the amazing oUF_GPS plugin by Elv, Omega1970
-- https://github.com/Blazeflack/ElvUI/tree/master/ElvUI/libs/oUF_Plugins/oUF_GPS
local _FRAMES, OnUpdateFrame, max = {}, nil, math.max
local minThrottle = 0.02
local numArrows, inRange, unit, angle, GPS, distance
local function Update(self, elapsed)
	if self.elapsed and self.elapsed > (self.throttle or minThrottle) then
		numArrows = 0
		for _, object in ipairs(_FRAMES) do
			if object:IsShown() then
				GPS = object.GPS
				unit = object.unit
				if unit then
					if (GPS.PreUpdate) then GPS:PreUpdate(self) end

					if unit and GPS.outOfRange then
						inRange = UnitInRange(unit)
					end

					if not unit or not UnitIsConnected(unit)
						or not (UnitIsUnit(unit, "player") or UnitInParty(unit) or UnitInRaid(unit))
						or (GPS.onMouseOver and (GetMouseFocus() ~= object))
						or (GPS.outOfRange and inRange) then
						GPS:Hide()
					else
						distance, angle = GetDistance("player", unit)
						if not angle then
							GPS:Hide()
						else
							GPS:Show()

							if GPS.Texture then
								GPS.Texture:SetRotation(angle - GetPlayerFacing())
							end
							if GPS.Text then
								GPS.Text:SetText(distance)
							end

							if GPS.PostUpdate then GPS:PostUpdate(self, distance, angle) end
							numArrows = numArrows + 1
						end
					end
				else
					GPS:Hide()
				end
			end
		end

		self.elapsed = 0
		self.throttle = max(minThrottle, 0.005 * numArrows)
	else
		self.elapsed = (self.elapsed or 0) + elapsed
	end
end

local function Disable(self)
	local GPS = self.GPS
	if GPS then
		for k, frame in ipairs(_FRAMES) do
			if(frame == self) then
				tremove(_FRAMES, k)
				GPS:Hide()
				break
			end
		end

		if #_FRAMES == 0 and OnUpdateFrame then
			OnUpdateFrame:Hide()
		end
	end
end

local function Enable(self)
	local GPS = self.GPS
	if GPS then
		tinsert(_FRAMES, self)

		if not OnUpdateFrame then
			OnUpdateFrame = CreateFrame("Frame")
			OnUpdateFrame:SetScript("OnUpdate", Update)
		end
		-- hooksecurefunc(self, "unusedFunc", Disable)

		OnUpdateFrame:Show()
		return true
	end
end

addon.EnableGPS, addon.DisableGPS = Enable, Disable
