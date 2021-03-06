local addonName, addon, _ = ...

function addon.CUF_SetHealthBarVertical(frame, enable)
	local width, height = frame:GetSize()

	if enable then
		frame.healthBar:SetOrientation('vertical')
		frame.healthBar:SetRotatesTexture(true)

		--[[ frame.myHealPrediction:SetOrientation('vertical')
		frame.myHealPrediction:ClearAllPoints()
		frame.myHealPrediction:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
		frame.myHealPrediction:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		frame.myHealPrediction:SetHeight(height)

		-- frame.otherHealPrediction:SetOrientation('vertical')
		frame.otherHealPrediction:ClearAllPoints()
		frame.otherHealPrediction:SetPoint('BOTTOMLEFT', frame.healthBar:GetStatusBarTexture(), 'TOPLEFT', 0, 0)
		frame.otherHealPrediction:SetPoint('BOTTOMRIGHT', frame.healthBar:GetStatusBarTexture(), 'TOPRIGHT', 0, 0)
		frame.otherHealPrediction:SetHeight(height) --]]
	else
		frame.healthBar:SetOrientation("horizontal")

		--[[ frame.myHealPrediction:SetOrientation("horizontal")
		frame.myHealPrediction:ClearAllPoints()
		frame.myHealPrediction:SetPoint("TOPLEFT", frame.healthBar:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		frame.myHealPrediction:SetPoint("BOTTOMLEFT", frame.healthBar:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
		frame.myHealPrediction:SetWidth(width)

		frame.otherHealPrediction:SetOrientation("horizontal")
		frame.otherHealPrediction:ClearAllPoints()
		frame.otherHealPrediction:SetPoint("TOPLEFT", frame.myHealPrediction:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
		frame.otherHealPrediction:SetPoint("BOTTOMLEFT", frame.myHealPrediction:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
		frame.otherHealPrediction:SetWidth(width) --]]
	end
end

function addon.CUF_SetPowerBarVertical(frame, enable, togglePosition)
	frame.powerBar.vertical = enable

	frame.powerBar:ClearAllPoints()
	frame.healthBar:ClearAllPoints()

	local padding = addon.db.profile.unitframe.innerPadding -- anchors to <frame> might have some padding
	if enable then
		frame.powerBar:SetOrientation("vertical")
		frame.powerBar:SetRotatesTexture(true)

		if togglePosition then -- left
			frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
			frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", padding, padding)

			frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "TOPRIGHT", 0, 0)
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)
		else -- right
			frame.powerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padding, -padding)
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)

			frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding);
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "BOTTOMLEFT", 0, 0)
		end
	else
		frame.powerBar:SetOrientation("horizontal")

		if togglePosition then -- top
			frame.powerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", padding, -padding)
			frame.powerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -padding, -padding)

			frame.healthBar:SetPoint("TOPLEFT", frame.powerBar, "BOTTOMLEFT", 0, 0)
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame, -padding, padding)
		else -- bottom [DEFAULT]
			frame.powerBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", padding, padding)
			frame.powerBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -padding, padding)

			frame.healthBar:SetPoint("TOPLEFT", frame, padding, -padding)
			frame.healthBar:SetPoint("BOTTOMRIGHT", frame.powerBar, "TOPRIGHT", 0, 0)
		end
	end
end

function addon.CUF_SetSeperatorVertical(frame, enable, togglePosition)
	frame.horizDivider:ClearAllPoints()
	frame.horizDivider:SetParent(frame.powerBar)
	frame.horizDivider:SetDrawLayer("BORDER", 5)

	if enable then
		frame.horizDivider:SetTexture("Interface\\RaidFrame\\Raid-VSeparator")
		frame.horizDivider:SetTexCoord(0, 0.25, 0, 1)
		frame.horizDivider:SetWidth(1)

		if togglePosition then -- left
			frame.horizDivider:SetPoint("TOPRIGHT")
			frame.horizDivider:SetPoint("BOTTOMRIGHT")
		else -- right
			frame.horizDivider:SetPoint("TOPLEFT")
			frame.horizDivider:SetPoint("BOTTOMLEFT")
		end
	else
		frame.horizDivider:SetTexture("Interface\\RaidFrame\\Raid-HSeparator")
		frame.horizDivider:SetTexCoord(0, 1, 0, 0.25)
		frame.horizDivider:SetHeight(2)

		if togglePosition then -- top
			frame.horizDivider:SetPoint("BOTTOMLEFT")
			frame.horizDivider:SetPoint("BOTTOMRIGHT")
		else -- bottom
			frame.horizDivider:SetPoint("TOPLEFT")
			frame.horizDivider:SetPoint("TOPRIGHT")
		end
	end
end
