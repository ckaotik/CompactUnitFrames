local addonName, ns = ...
ns.name = addonName
ns.color = "22EE55"

function ns.Print(message, ...)
	DEFAULT_CHAT_FRAME:AddMessage("|cff"..(ns.color)..(ns.name).."|r "..message
		..' '..string.join(", ", tostringall(...) ))
end
function ns.Debug(...)
	if CUFC_GlobalDB.debug then
		ns.Print("!", (string.join(", ", tostringall(...))))
	end
end

-- CompactRaidFrameContainer_AddUnitFrame / CompactRaidFrameContainer_GetUnitFrame(CompactRaidFrameContainer, "player", "raid")
local eventFrame = CreateFrame("Frame", "CompactUnitFrames_EventHandler", UIParent)
local function eventHandler(self, event, arg1, arg2)
	if event == "ADDON_LOADED" and arg1 == ns.name then
		if not CUFC_GlobalDB then
			ns.Print("Reset database", ns.debug, ns.profiles)
			CUFC_GlobalDB = {
				debug = nil,
				profiles = {},
			}
		end

		ns.initialized = true
		self:UnregisterEvent("ADDON_LOADED")
	end
end
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", eventHandler)
ns.eventFrame = eventFrame

-- == Adjust Blizzard Options ===================================
-- see: http://wow.go-hero.net/framexml/14545/Blizzard_CUFProfiles/Blizzard_CompactUnitFrameProfiles.lua
local initializeMe = true

CompactUnitFrameProfilesGeneralOptionsFrame:HookScript("OnShow", function(self)
	if initializeMe then
		if CompactUnitFrames.db.health.color then
			local classColors = _G[self:GetName() .. "UseClassColors"]
			classColors:Disable()
			classColors.tiptext = "Overridden by CompactUnitFrames addon settings"
			classColors:HookScript("OnEnter", ns.ShowTooltip)
			classColors:HookScript("OnLeave", ns.HideTooltip)
		end

		local slider = _G[self:GetName() .. "HeightSlider"]
		slider:SetMinMaxValues(0, 200) -- default: 36, 72

		local slider = _G[self:GetName() .. "WidthSlider"]
		slider:SetMinMaxValues(0, 200) -- default: 72, 144

		initializeMe = nil
	end
end)

-- [TODO] reuse previous settings
-- CreateNewRaidProfile("CompactUnitFrames", CompactUnitFrameProfiles.newProfileDialog.baseProfile)
-- CompactUnitFrameProfiles_ActivateRaidProfile("CompactUnitFrames")

-- == Misc Utility ==============================================
function ns:HideTooltip() GameTooltip:Hide() end
function ns:ShowTooltip()
	if self.tiptext then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.tiptext, nil, nil, nil, nil, true)
	end
end

function ns:Find(table, value)
	if not table then return end
	for k, v in pairs(table) do
		if (v and value and v == value) then return true end
	end
	return nil
end

function ns:ShortenNumber(value)
	value = value and tonumber(value) or nil
	if not value then return value end

	if (value >= 1e6 or value <= -1e6) then
		return ("%.2f"):format(value / 1e6):gsub("%.?0+$", "") .. "m"
	elseif (value >= 1e3 or value <= -1e3) then
		return ("%.1f"):format(value / 1e3):gsub("%.?0+$", "") .. "k"
	else
		return value
	end
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
