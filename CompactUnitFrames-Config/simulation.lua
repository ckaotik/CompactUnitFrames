local addonName, ns = ...

--[[
local UnitDebuff, UnitBuff
do
	local fakeDebuffs = {
		{ "Allergies", false, "Ability_Creature_Disease_04", 0, false, 180, false, false, 31427, false, true, false },
		{ "Amplify Damage", false, "Spell_Shadow_Shadowfury", 99, false, 10, false, false, 39095, false, true, false },
		{ "Brood Affliction: Black", false, "INV_Misc_Head_Dragon_Black", 0, "Curse", 600, false, false, 23154, false, true, false },
		{ "Corruption", false, "Spell_Shadow_AbominationExplosion", 0, "Magic", 18, false, false, 172, false, false, true },
		{ "Enhance Magic", false, "Spell_Arcane_ArcanePotency", 0, "Magic", 8, true, false, 91624, false, false, false },
		{ "Enrage", false, "Ability_Druid_Enrage", 0, "", 10, false, false, 5229, false, false, true },
		{ "Furious Poison", false, "Spell_Yorsahj_Bloodboil_Green", 4, "Poison", 10, false, false, 115087, false, false, false },
		{ "Ghoul Rot", false, "Spell_Shadow_CreepingPlague", 0, "Disease", 20, false, false, 12541, false, false, false },
	}
	function UnitDebuff(unit, index, ...)
		if type(index) == "number" then
			local name, rank, icon, count, debuffType, duration, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer = unpack(fakeDebuffs[random(#fakeDebuffs)])
			local expirationTime = GetTime() + duration - random(1, duration - 1)
			local unitCaster = "boss1" -- "player"
			icon = "Interface\\Icons\\"..icon
			return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer
		else
			return _G.UnitDebuff(unit, index, ...)
		end
	end
	function UnitBuff(unit, index, ...)
		if type(index) == "number" then
			local name, rank, icon, count, debuffType, duration, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer = unpack(fakeDebuffs[random(#fakeDebuffs)])
			local expirationTime = GetTime() + duration - random(1, duration - 1)
			local unitCaster = "boss1" -- "player"
			icon = "Interface\\Icons\\"..icon
			return name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId, canApplyAura, isBossDebuff, isCastByPlayer
		else
			return _G.UnitBuff(unit, index, ...)
		end
	end
end --]]

function ns:Simulate_Buffs(frame, count)
	local origUnitBuff = _G.UnitBuff
	_G.UnitBuff = UnitBuff

	for index = 1, count do
		CompactUnitFrame_UtilSetBuff(frame.buffFrames[index], frame.displayedUnit, index, "HELPFUL", false, false)
	end

	_G.UnitBuff = origUnitBuff
end

function ns:Simulate_Debuffs(frame, count)
	local origUnitDebuff = _G.UnitDebuff
	_G.UnitDebuff = UnitDebuff

	for index = 1, count do
		CompactUnitFrame_UtilSetDebuff(frame.debuffFrames[index], frame.displayedUnit, index, "HARMFUL", false, false)
	end

	_G.UnitDebuff = origUnitDebuff
end

function ns:Simulate_BossDebuff(frame, index)
	local origUnitDebuff = _G.UnitDebuff
	_G.UnitDebuff = UnitDebuff

	if frame.debuffFrames[index] then
		CompactUnitFrame_UtilSetDebuff(frame.debuffFrames[index], frame.displayedUnit, index, "HARMFUL", true, false)
	end

	_G.UnitDebuff = origUnitDebuff
end

function ns:Simulate_DebuffIcon(frame, debuffType, enable)
	frame["hasDispel"..debuffType] = enable
	ns:UpdateDispellDebuffDisplay(frame)
end

function ns:Simulate_DebuffBorder(frame, debuffType)
	CompactUnitFrame_UtilSetDispelDebuff(frame.dispelDebuffFrames[1], debuffType, 1)
end

function ns:UpdateDispellDebuffDisplay(frame)
	local i = 1
	while (frame.dispelDebuffFrames[i]) do
		frame.dispelDebuffFrames[i]:Hide()
		i = i+1
	end

	local debuffTypes = { "Magic", "Disease", "Curse", "Poison" }
	local nextIndex = 1
	for _, debuffType in pairs(debuffTypes) do
		if frame["hasDispel"..debuffType] and frame.dispelDebuffFrames[nextIndex] then
			CompactUnitFrame_UtilSetDispelDebuff(frame.dispelDebuffFrames[nextIndex], debuffType, nextIndex)
			nextIndex = nextIndex + 1
		end
	end

	if nextIndex == 1 or not CompactUnitFrames.db.profile.indicators.showDispellBorder then
		frame.selectionHighlight:Hide()
		frame.selectionHighlight:SetVertexColor(1, 1, 1)
		CompactUnitFrame_UpdateSelectionHighlight(frame)
	end
end


-- ===== Create frames on demand! =======================================
--[[ Create frames (small or normal) via ...
	CompactUnitFrames:CreateTestFrame("player")
	CompactUnitFrames:CreateTestFrame("pet")

	Reset all frames via ...
	CompactRaidFrameContainer_TryUpdate(CompactRaidFrameContainer)


	-- add new units macro, use 'pet' instead of 'raid' for small frames
	-- /stopmacro [@mouseover,noexists]
	-- /script CompactRaidFrameContainer_AddUnitFrame(CompactRaidFrameContainer, 'mouseover', 'raid')
	-- /script CompactRaidFrameContainer_UpdateBorder(CompactRaidFrameContainer)
]]

--[[ local unsetFunc = function(frame) CompactUnitFrame_SetUnit(frame, nil) end
CompactRaidFrameContainer.frameReservations["dummy"] = CompactRaidFrameReservation_NewManager( unsetFunc )
CompactRaidFrameContainer.frameReservations["dummy_small"] = CompactRaidFrameReservation_NewManager( unsetFunc ) --]]

-- create new frame
local unitFramesCreated = 0
function ns:CreateTestFrame(type, unit)
	if UnitExists('mouseover') then
		CompactRaidFrameContainer_AddUnitFrame(CompactRaidFrameContainer, 'mouseover', 'raid')
		CompactRaidFrameContainer_UpdateBorder(CompactRaidFrameContainer)
	end
    --[[ local frame = CompactRaidFrameReservation_GetFrame(CompactRaidFrameContainer.frameReservations[type], unit);

    local info
    if unit == "player" then
        info = { mapping = unit, setUpFunc = DefaultCompactUnitFrameSetup, updateList = "normal"}
    else
        info = { mapping = unit, setUpFunc = DefaultCompactMiniFrameSetup, updateList = "mini"}
    end

    if ( not frame ) then
        unitFramesCreated = unitFramesCreated + 1
        frame = CreateFrame("Button", "CompactRaidFrame"..unitFramesCreated, CompactRaidFrameContainer, "CompactUnitFrameTemplate")
        frame.applyFunc = applyFunc
        CompactUnitFrame_SetUpFrame(frame, info.setUpFunc)
        CompactUnitFrame_SetUpdateAllEvent(frame, "RAID_ROSTER_UPDATE")
        frame.unusedFunc = function(frame) CompactUnitFrame_SetUnit(frame, nil) end
        tinsert(CompactRaidFrameContainer.frameUpdateList[info.updateList], frame)
        CompactRaidFrameReservation_RegisterReservation(CompactRaidFrameContainer.frameReservations[type], frame, info.mapping)
    end
    frame.inUse = true

    -- insert new frame into container
    CompactUnitFrame_SetUnit(frame, unit)
    FlowContainer_AddObject(CompactRaidFrameContainer, frame) --]]
end
