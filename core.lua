local addonName, ns = ...
local db = CUF_GlobalDB
ns.name = addonName
ns.color = "22EE55"

function ns:Print(message, ...)
	DEFAULT_CHAT_FRAME:AddMessage("|cff"..(ns.color)..(ns.name).."|r "..message
		..' '..string.join(", ", tostringall(...) ))
end
function ns:Debug(...)
  if db.debug then
	ns.Print("!", (string.join(", ", tostringall(...))))
  end
end

local eventFrame = CreateFrame("Frame", "CompactUnitFrames_EventHandler", UIParent)
local function eventHandler(self, event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == ns.name then
		ns:ManagerSetup( CompactRaidFrameManager )
		ns:UpdateAllFrames( CompactUnitFrame_UpdateAll )
		self:UnregisterEvent("ADDON_LOADED")
	end
end
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", eventHandler)
ns.eventFrame = eventFrame

function ns:UpdateAllFrames(afterFunction, ...)
	local i, j, frame
	for i = 1, 80 do 	-- [TODO] maybe MAX_RAID_MEMBERS
		frame = _G["CompactRaidFrame"..i]
		if frame then
			ns:UnitFrameSetup(frame)
			if afterFunction then
				afterFunction(frame, ...)
			end
		end
	end

	for i = 1, 8 do
		for j = 1, 5 do
			frame = _G["CompactRaidGroup"..i.."Member"..j]
			if frame then
				ns:UnitFrameSetup(frame)
				if afterFunction then
					afterFunction(frame, ...)
				end
			end
		end
	end
end

-- == Misc Utility ==============================================
function ns:HideTooltip() GameTooltip:Hide() end
function ns:ShowTooltip(self)
	if self.tiptext then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end
end

function ns:ShortValue(value)
	if(value >= 1e6) then
		return ("%.2f"):format(value / 1e6):gsub("%.?0+$", "") .. "m"
	elseif(value >= 1e4) then
		return ("%.1f"):format(value / 1e3):gsub("%.?0+$", "") .. "k"
	else
		return value
	end
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
		-- r, g, b = string.match(data, "(%w):(%w):(%w)") -- [TODO] doesn't work :(
		r, g, b = tonumber(r or ''), tonumber(g or ''), tonumber(b or '')

		if not (r and g and b) then	return nil end
	end
	return r, g, b
end

-- provides class or reaction color for a given unit
function ns:GetClassColor(unit) -- [TODO] exclude pets?
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
	if frame.displayedUnit == "player" and ns.config.power.types.showSelf then
		return true
	end
	if not frame.displayedUnit then return end

	local powerType = UnitPowerType(frame.displayedUnit)
	local settings = ns.config.power.types[powerType]
	if settings then
		return not settings.hide
	else
		return ns.config.power.types.showUnknown
	end
end


--[[ == Shared Media insertions ==============================
local sharedMedia = LibStub("LibSharedMedia-3.0", true) or LibStub("LibSharedMedia-2.0", true)
if sharedMedia then
    sharedMedia:Register("font", "Paralucent", "Interface\\Addons\\Midget\\media\\Paralucent.ttf")
    sharedMedia:Register("font", "Andika", "Interface\\Addons\\Midget\\media\\Andika.ttf")
    sharedMedia:Register("statusbar", "TukTex", "Interface\\Addons\\Midget\\media\\TukTexture.tga")
    sharedMedia:Register("statusbar", "Smooth", "Interface\\Addons\\Midget\\media\\Smooth.tga")
end]]

CompactUnitFrames = ns -- external reference