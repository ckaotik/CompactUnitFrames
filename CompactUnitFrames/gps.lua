local _, ns = ...

-- code from the amazing oUF_GPS plugin by Elv, Omega1970
-- https://github.com/Blazeflack/ElvUI/tree/master/ElvUI/libs/oUF_Plugins/oUF_GPS

-- GLOBALS: UnitIsPlayer, UnitExists, UnitInRange, UnitIsConnected, UnitIsUnit, UnitInParty, UnitInRaid, GetPlayerMapPosition, GetPlayerFacing, GetMouseFocus, CreateFrame
-- GLOBALS: math, ipairs

local atan2, sqrt, max = math.atan2, math.sqrt, math.max
local tinsert, tremove = table.insert, table.remove
local _FRAMES, OnUpdateFrame = {}, nil

local function GetDistance(unit1, unit2)
	if not unit1 or not UnitExists(unit1) or not UnitIsPlayer(unit1) or UnitIsUnit(unit1, unit2)
		or not unit2 or not UnitExists(unit2) or not UnitIsPlayer(unit2) then
		return nil
	end

	local x1, y1 = GetPlayerMapPosition(unit1)
	local x2, y2 = GetPlayerMapPosition(unit2)
	local dx, dy = x2 - x1, y2 - y1

	local distance = sqrt(dx^2 + dy^2)
		  distance = math.floor(distance * 1000 + 0.5)
	local angle = atan2(dx, dy) + math.pi

	return distance, angle
end

local minThrottle = 0.02
local numArrows, inRange, unit, angle, GPS, distance
local Update = function(self, elapsed)
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

local Enable = function(self)
	local GPS = self.GPS
	if GPS then
		tinsert(_FRAMES, self)

		if not OnUpdateFrame then
			OnUpdateFrame = CreateFrame("Frame")
			OnUpdateFrame:SetScript("OnUpdate", Update)
		end

		OnUpdateFrame:Show()
		return true
	end
end

local Disable = function(self)
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

ns.EnableGPS, ns.DisableGPS = Enable, Disable
