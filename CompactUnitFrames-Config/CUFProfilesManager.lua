local addonName, ns = ...

SLASH_CUFADDON1, SLASH_CUFADDON2, SLASH_CUFADDON3 = '/cufprofile', '/cufpm', '/cuf';
local function handler(msg, editbox)
	local command, arg = msg:match("^(%S*)%s*(.-)$");
	
	if command == "list" then
		local first = true
		local output = "Saved profile snapshots: "
		for profile, data in pairs(CUFC_GlobalDB.profiles) do
			output = output .. (first and "" or ", ") .. profile
			first = nil
		end
		ns:Print(output)

	elseif command == "save" and arg ~= "" then
		if RaidProfileExists(arg) then
			local profileName, profileOffset = arg, 0
			while CUFC_GlobalDB.profiles[profileName] do
				profileOffset = profileOffset + 1
				profileName = arg .. profileOffset
			end
			CUFC_GlobalDB.profiles[profileName] = GetRaidProfileFlattenedOptions(arg)

			ns:Print("Saved profile:", arg, "as", profileName)
		else
			ns:Print("Not a valid profile:", arg)
		end

	elseif command == "restore" and arg ~= "" then
		if CUFC_GlobalDB.profiles[arg] then
			if GetNumRaidProfiles() >= GetMaxNumCUFProfiles() then
				ns:Print("Error: Too many raid profiles, cannot create a new one")
				return
			end

			if not RaidProfileExists(arg) then
				ns:Print("Can restore profile:", arg)
				CompactUnitFrameProfiles_CreateProfile(strtrim(arg))
				
				for option, value in pairs(CUFC_GlobalDB.profiles[arg]) do
					SetRaidProfileOption(CompactUnitFrameProfiles.selectedProfile, option, value)
				end
				CompactUnitFrameProfiles_UpdateCurrentPanel()
				CompactUnitFrameProfiles_ApplyCurrentSettings()
				CompactUnitFrameProfiles_ConfirmUnsavedChanges(arg) -- or "new"
			else
				ns:Print("Profile already exists:", arg)
			end
		else
			ns:Print("Saved profile data is not available:", arg)
		end

	else
		-- If not handled above, display some sort of help message
		print("Syntax: /cuf (save||restore) raidProfileName")
	end
end
SlashCmdList["CUFADDON"] = handler