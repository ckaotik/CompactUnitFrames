local addonName, addon, _ = ...
local plugin = {}
addon.Overlay = plugin

-- GLOBALS: CreateFrame, UnitDebuff, GetTime
-- GLOBALS: tinsert, hooksecurefunc, ipairs, tremove

local DRData = LibStub('DRData-1.0')
local hideDRType = {
	["ctrlroot"] = true,
	["shortroot"] = true,
	["disarm"] = true,
	["taunt"] = true,
	["knockback"] = true,
}

-- thanks, Torhal! http://www.wowinterface.com/forums/showpost.php?p=166983&postcount=14
local AcquireFrame, ReleaseFrame, GetFrameOverlay, GetNumCreatedFrames
do
	local frame_cache, frame_assignments, createdFrames = {}, {}, 0
	function GetFrameOverlay(unitframe)
		return frame_assignments[unitframe]
	end
	function AcquireFrame(unitframe)
		local overlay = tremove(frame_cache)
		if not overlay then
			overlay = CreateFrame('Button', nil, UIParent, 'CompactAuraTemplate')
			overlay:EnableMouse(false)
			overlay:EnableMouseWheel(false)
			overlay:Hide()
			createdFrames = createdFrames + 1
		end
		-- overlay:SetParent(unitframe)
		frame_assignments[unitframe] = overlay
		return overlay
	end
	function ReleaseFrame(unitframe)
		local overlay = GetFrameOverlay(unitframe)
		if not overlay then return end
		overlay:Hide()
		overlay:SetParent(nil)
		overlay:ClearAllPoints()
		tinsert(frame_cache, overlay)
		frame_assignments[unitframe] = nil
	end
	function GetNumCreatedFrames() return createdFrames end
end

function plugin.Enable(unitframe)
	if GetNumCreatedFrames() == 0 then
		-- first time using the plugin
		hooksecurefunc('CompactUnitFrame_UpdateDebuffs', plugin.Update)
		hooksecurefunc(CompactRaidFrameContainer, 'unitFrameUnusedFunc', plugin.Disable)
		-- hooksecurefunc(unitframe, 'unusedFunc', plugin.Disable)
	end
	local overlay = GetFrameOverlay(unitframe) or AcquireFrame(unitframe)
	return overlay
end

function plugin.Disable(unitframe)
	ReleaseFrame(unitframe)
end

function plugin.Update(unitframe)
	local overlay = GetFrameOverlay(unitframe)
	local unit = unitframe.displayedUnit or unitframe.unit
	if not overlay or not unit then return end

	local displayIcon, icon, count, caster, expires
	for i = 1, 40 do
		local dispelType, spellID, canApplyAura, isBoss, _
		_, _, icon, count, dispelType, _, expires, caster, _, _, spellID, canApplyAura, isBoss = UnitDebuff(unit, i)
		local drType = DRData:GetSpellCategory(spellID)
		if drType and not hideDRType[drType] then
			displayIcon = true
			break
		end
	end

	if displayIcon then
		local now = GetTime()
		overlay.icon:SetTexture(icon)
		overlay.icon:SetDesaturated(caster == 'player')
		overlay.count:SetText(count == 1 and '' or count)
		overlay.cooldown:SetCooldown(now, expires - now)
		overlay:Show()
	else
		overlay:Hide()
	end
end
