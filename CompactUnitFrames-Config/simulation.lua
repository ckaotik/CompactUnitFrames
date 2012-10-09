local addonName, ns = ...

function ns:Simulate_Buffs(frame, count)
	for index = 1, count do
		if UnitAura("player", 1, "HELPFUL") then
			CompactUnitFrame_UtilSetBuff(frame.buffFrames[1], frame.displayedUnit, index, "HELPFUL")
		end
	end
end

function ns:Simulate_Debuffs(frame, count)
	--[[local origUnitDebuff = UnitDebuff
	UnitDebuff = function(unit, index, filter)
		--     name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, shouldConsolidate, spellId
		return "TestDebuff", 1, "Interface\\Icons\\ability_warrior_rampage", 1, index, 20, 10, "Chuck Norris", false, false, 70304
	end ]]--

	for index = 1, count do
		if UnitAura("player", 1, "HARMFUL") then
			CompactUnitFrame_UtilSetDebuff(frame.debuffFrames[1], frame.displayedUnit, count, "HARMFUL")
			print("Set debuff "..index)
		end
	end

	-- UnitDebuff = origUnitDebuff
end

function ns:Simulate_BossDebuff(frame, index)
	--[[if frame.debuffFrames[index] then
		CompactUnitFrame_UtilSetDebuffBossDebuff(frame.debuffFrames[index], true)
	end--]]
end

function ns:Simulate_DebuffIcon(frame, debuffType, enable)
	frame["hasDispel"..debuffType] = enable
	ns:UpdateDispellDebuffDisplay(frame)
end

--[[ function ns:Simulate_DebuffBorder(frame, debuffType)
	CompactUnitFrame_UtilSetDispelDebuff(frame.dispelDebuffFrames[1], debuffType, 1)
end ]]

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

	if nextIndex == 1 or not CompactUnitFrames.db.indicators.showDispellBorder then
		frame.selectionHighlight:Hide()
		frame.selectionHighlight:SetVertexColor(1, 1, 1)
		CompactUnitFrame_UpdateSelectionHighlight(frame)
	end
end


-- ===== Create frames on demand! =======================================
--[[ Create frames (small or normal) via ...
	CompactUnitFrames:CreateTestFrame("dummy", "player")
	CompactUnitFrames:CreateTestFrame("dummy_small", "pet")

	Reset all frames via ...
	CompactRaidFrameContainer_TryUpdate(CompactRaidFrameContainer)
]]

local unsetFunc = function(frame) CompactUnitFrame_SetUnit(frame, nil) end
CompactRaidFrameContainer.frameReservations["dummy"] = CompactRaidFrameReservation_NewManager( unsetFunc )
CompactRaidFrameContainer.frameReservations["dummy_small"] = CompactRaidFrameReservation_NewManager( unsetFunc )

-- create new frame
local unitFramesCreated = 0
function ns:CreateTestFrame(type, unit)
    local frame = CompactRaidFrameReservation_GetFrame(CompactRaidFrameContainer.frameReservations[type], unit);

    local info
    if type == "dummy" then
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
    FlowContainer_AddObject(CompactRaidFrameContainer, frame)
end
