local addonName, addon, _ = ...

-- GLOBALS: CompactUnitFrameProfiles, CompactUnitFrameProfiles_CheckAutoActivation, CompactUnitFrameProfiles_GetAutoActivationState, CompactUnitFrameProfiles_ProfileMatchesAutoActivation, CompactUnitFrameProfiles_GetLastActivationType, CompactUnitFrameProfiles_SetLastActivationType, CompactUnitFrameProfiles_ApplyProfile
-- GLOBALS: GetNumGroupMembers, GetActiveSpecGroup, GetNumRaidProfiles, GetActiveRaidProfile, GetRaidProfileName,, SetActiveRaidProfile
-- GLOBALS: print, issecurevariable

local function RunAutoActivation()
	-- ty, Blizzard. The only wrapper I could use taints CUF_HORIZONTAL_GROUPS. Immediately.
	-- if true then return end

	local success, _, activationType, enemyType = CompactUnitFrameProfiles_GetAutoActivationState()
	-- returns: true, 40, "world", "PvE"
	if not success then return end

	-- group sizes: 2, 3, 5, 10, 15, 25, 40
	local numPlayers = GetNumGroupMembers()
	numPlayers = (numPlayers <= 2 and 2) or (numPlayers <= 3 and 3) or (numPlayers <= 5 and 5)
			or (numPlayers <= 10 and 10) or (numPlayers <= 15 and 15) or (numPlayers <= 25 and 25) or 40

	local lastActivationType, lastNumPlayers, lastSpec, lastEnemyType = CompactUnitFrameProfiles_GetLastActivationType()
	local spec = GetActiveSpecGroup()

	if lastSpec == spec and lastEnemyType == enemyType and lastNumPlayers == numPlayers
		or CompactUnitFrameProfiles_ProfileMatchesAutoActivation(GetActiveRaidProfile(), numPlayers, spec, enemyType) then
		return
	end

	for i = 1, GetNumRaidProfiles() do
		local profile = GetRaidProfileName(i)
		if CompactUnitFrameProfiles_ProfileMatchesAutoActivation(profile, numPlayers, spec, enemyType) then
			-- CompactUnitFrameProfiles_ActivateRaidProfile(profile) -- causes taint as this updates dropdown values
			CompactUnitFrameProfiles.selectedProfile = profile
			SetActiveRaidProfile(profile)
			CompactUnitFrameProfiles_ApplyProfile(profile) -- TAINTS!
			print('activate', i, profile, issecurevariable("CUF_HORIZONTAL_GROUPS"))

			-- UIDropDownMenu_SetSelectedValue(CompactUnitFrameProfilesProfileSelector, profile)
			-- UIDropDownMenu_SetText(CompactUnitFrameProfilesProfileSelector, profile)
			-- UIDropDownMenu_SetSelectedValue(CompactRaidFrameManagerDisplayFrameProfileSelector, profile)
			-- UIDropDownMenu_SetText(CompactRaidFrameManagerDisplayFrameProfileSelector, profile)

			CompactUnitFrameProfiles_SetLastActivationType(activationType, numPlayers, spec, enemyType)
			break
		end
	end
end

function addon:SetupAutoActivate()
	RunAutoActivation()
	self:RegisterEvent('GROUP_ROSTER_UPDATE', CompactUnitFrameProfiles_CheckAutoActivation)
	self:RegisterEvent('GROUP_ROSTER_UPDATE', RunAutoActivation)
	self:RegisterEvent('GROUP_JOINED', RunAutoActivation)
end
