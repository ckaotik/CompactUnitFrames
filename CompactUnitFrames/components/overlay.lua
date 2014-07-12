local addonName, addon, _ = ...

-- GLOBALS: UnitDebuff, GetTime
-- GLOBALS: tinsert, hooksecurefunc, ipairs, tremove

local DRData = LibStub('DRData-1.0')
local hideDRType = {
	["ctrlroot"] = true,
	["shortroot"] = true,
	["disarm"] = true,
	["taunt"] = true,
	["knockback"] = true,
}

local isDisabled = nil
local _FRAMES = {}

local function UpdateOverlay(self)
	if not self.Overlay then return end
	local display, drType = nil, nil
	local icon, count, dispelType, expires, caster, spellID, canApplyAura, isBoss
	for i = 1, 40 do
		_, _, icon, count, dispelType, _, expires, caster, _, _, spellID, canApplyAura, isBoss = UnitDebuff(self.displayedUnit or self.unit, i)
		drType = DRData:GetSpellCategory(spellID)
		if drType and not hideDRType[drType] then
			display = true
			break
		end
	end

	if display then
		self.Overlay.icon:SetTexture(icon)
		self.Overlay.icon:SetDesaturated( caster == "player" )
		self.Overlay.count:SetText(count == 1 and '' or count)
		local now = GetTime()
		self.Overlay.cooldown:SetCooldown(now, expires - now)

		self.Overlay:Show()
	else
		self.Overlay:Hide()
	end
end

local isHooked = nil
local Disable = function(self)
	local overlay = self.Overlay
	if overlay then
		for k, frame in ipairs(_FRAMES) do
			if frame == self then
				tremove(_FRAMES, k)
				overlay:Hide()
				break
			end
		end

		if #_FRAMES == 0 and isHooked then
			isDisabled = true
		end
	end
end

local Enable = function(self)
	local overlay = self.Overlay
	if overlay then
		tinsert(_FRAMES, self)
		isDisabled = nil

		if not isHooked then
			hooksecurefunc("CompactUnitFrame_UpdateDebuffs", UpdateOverlay)
			isHooked = true
		end
		-- hooksecurefunc(self, "unusedFunc", Disable)

		return true
	end
end

addon.EnableOverlay, addon.DisableOverlay = Enable, Disable
