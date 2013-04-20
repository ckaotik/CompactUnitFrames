local addonName, ns = ...

do
	local SharedMedia = LibStub("LibSharedMedia-3.0")
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")

	function ns:LSM_GetMediaKey(mediaType, value)
		local keyList = SharedMedia:List(mediaType)
		for _, key in pairs(keyList) do
			if SharedMedia:Fetch(mediaType, key) == value then
				return key
			end
		end
	end
	function ns:GetListFromTable(dataTable, seperator)
		local output = ""
		for _, value in pairs(dataTable) do
			if output ~= "" then
				output = output .. seperator .. value
			else
				output = value
			end
		end
		return output
	end
	function ns:GetTableFromList(dataString, seperator)
		return { strsplit(seperator, dataString) }
	end

	local testFrame = CreateFrame("Button", "CompactUnitFramesTestFrame", UIParent, "CompactUnitFrameTemplate")
	do
		testFrame.unitFrameUnusedFunc = function(frame) end
		testFrame.inUse = true
		testFrame.unit, testFrame.displayedUnit = "player", "player"
		testFrame:SetAttribute("unit", "player")

		CompactUnitFrame_SetUpFrame(testFrame, DefaultCompactUnitFrameSetup);
		CompactUnitFrame_UpdateAll(testFrame)

		testFrame.healthBar:SetValue(0.4 * UnitHealthMax(testFrame.displayedUnit))
		testFrame.powerBar:SetValue (0.55 * UnitPowerMax(testFrame.displayedUnit))

		-- TODO: update
		-- testFrame.myHealPredictionBar:SetValue(0.05 * UnitHealthMax(testFrame.displayedUnit))
		-- testFrame.otherHealPredictionBar:SetValue(0.1 * UnitHealthMax(testFrame.displayedUnit))

		ns:Simulate_Buffs(testFrame, 1)
		ns:Simulate_Debuffs(testFrame, 2)
		ns:Simulate_BossDebuff(testFrame, 2)

		ns:Simulate_DebuffIcon(testFrame, "Disease", true)
		-- ns:Simulate_DebuffBorder(testFrame, "Disease", true)
	end

	local optionsTable = {
		type = "group",
		name = "CompactUnitFrames Configuration",
		childGroups = "tab",
		args = {
			enable = {
				type = "toggle",
				name = "Enable",
				desc = "Enables / disables the addon",

				get = function(info) return not CompactUnitFrames.db.frames.disableCUF end,
				set = function(info, enable)
					CompactUnitFrames:Manager_DisableCUF(not enable)
					CompactUnitFrames.db.frames.disableCUF = not enable
				end,
			},
			refresh = {
				type = "execute",
				name = "Refresh",
				desc = "Click to update the live CompactUnitFrames",
				width = "half",
				func = function() CompactRaidFrameContainer_TryUpdate(CompactRaidFrameContainer) end,
			},
			general = {
				type = "group",
				name = "General Settings",
				order = 1,
				args = {
					--[[ group1 = {
						type = "group",
						name = "Interface Settings",
						inline = true,
						order = 1,
						args = { --]]
							pullout = {
								type = "group",
								name = "Side Pullout",
								inline = true,
								order = 2,
								args = {
									minifyPullout = {
										type = "toggle",
										name = "Minify Pullout",
										desc = "Check to minify the side panel/pullout",
										order = 1,

										get = function(info) return CompactUnitFrames.db.frames.pullout.minify end,
										set = function(info, enable)
											CompactUnitFrames:MinifyPullout(enable)
											CompactUnitFrames.db.frames.pullout.minify = enable
										end,
									},
									alpha = {
										type = "range",
										name = "Opacity (active)",
										order = 2,

										get = function(info) return CompactUnitFrames.db.frames.pullout.activeAlpha * 100 end,
										set = function(info, alpha)
											alpha = alpha / 100
											CompactUnitFrames:MinifyPullout(alpha)
											CompactUnitFrames.db.frames.pullout.activeAlpha = alpha
										end,
										step = 1,
										min = 0,
										max = 100,
									},
									alpha2 = {
										type = "range",
										name = "Opacity (passive)",
										order = 3,

										get = function(info) return CompactUnitFrames.db.frames.pullout.passiveAlpha * 100 end,
										set = function(info, alpha)
											alpha = alpha / 100
											CompactUnitFrames:MinifyPullout(alpha)
											CompactUnitFrames.db.frames.pullout.passiveAlpha = alpha
										end,
										step = 1,
										min = 0,
										max = 100,
									},
									posX = {
										type = "range",
										name = "Horizontal Position",
										order = 4,

										get = function(info) return CompactUnitFrames.db.frames.pullout.posX end,
										set = function(info, position)
											CompactUnitFrames:MinifyPullout(position)
											CompactUnitFrames.db.frames.pullout.posX = position
										end,
										min = -500,
										max = 500,
									},
									posY = {
										type = "range",
										name = "Vertical Position",
										order = 5,

										get = function(info) return CompactUnitFrames.db.frames.pullout.posY end,
										set = function(info, position)
											CompactUnitFrames:MinifyPullout(position)
											CompactUnitFrames.db.frames.pullout.posY = position
										end,
										step = 1,
										min = -500,
										max = 500,
									},
								},
							-- },
					--	},
					},
					group2 = {
						type = "group",
						name = "Unit Frame settings",
						inline = true,
						order = 2,
						args = {
							showSolo = {
								type = "toggle",
								name = "Show frames when solo",
								order = 1,
								desc = "Check to display the compact unit frames even when not in a group",

								get = function(info) return CompactUnitFrames.db.frames.showSolo end,
								set = function(info, enable)
									CompactUnitFrames:Manager_ShowSolo(enable)
									CompactUnitFrames.db.frames.showSolo = enable
								end,
							},
							noMenu = {
								type = "toggle",
								name = "No menu in combat",
								desc = "Check to disable menu popups in combat",
								order = 2,

								set = function(info, val) CompactUnitFrames.db.unitframe.noMenuClickInCombat = val end,
								get = function(info) return CompactUnitFrames.db.unitframe.noMenuClickInCombat end,
							},
							noSeperator = {
								type = "toggle",
								name = "Hide power seperator",
								desc = "Check to hide the power seperator when using borders",
								order = 3,

								get = function(info) return CompactUnitFrames.db.unitframe.hideSeperator end,
								set = function(info, hide)
									CompactUnitFrames:CUF_SetSeperatorShown(testFrame, not hide)
									CompactUnitFrames.db.unitframe.hideSeperator = hide
								end,
							},
							spacingX = {
								type = "range",
								name = "Horizontal Spacing",
								order = 6,

								get = function(info) return CompactUnitFrames.db.unitframe.spacingX or 0 end,
								set = function(info, value)
									CompactUnitFrames.db.unitframe.spacingX = value
									CompactUnitFrames:ContainerSetup(CompactRaidFrameContainer)
								end,
								step = 1,
								min = -10,
								max = 10,
							},
							spacingY = {
								type = "range",
								name = "Vertical Spacing",
								order = 7,

								get = function(info) return CompactUnitFrames.db.unitframe.spacingY or 0 end,
								set = function(info, value)
									CompactUnitFrames.db.unitframe.spacingY = value
									CompactUnitFrames:ContainerSetup(CompactRaidFrameContainer)
								end,
								step = 1,
								min = -10,
								max = 10,
							},
							innerPadding = {
								type = "range",
								name = "Inner padding",
								order = 8,

								get = function(info) return CompactUnitFrames.db.unitframe.innerPadding or 0 end,
								set = function(info, value)
									CompactUnitFrames.db.unitframe.innerPadding = value
									CompactUnitFrames:CUF_SetPowerBarVertical(testFrame, CompactUnitFrames.db.power.vertical, CompactUnitFrames.db.power.changePosition)
								end,
								step = 1,
								min = 0,
								max = 10,
							},
							numPerLine = {
								type = "range",
								name = "Frames per line",
								desc = "Set after how many unit frames a line/row break happens. If the container has no more room before this number is reached, a break will happen anyway.",
								order = 9,

								get = function(info) return CompactUnitFrames.db.unitframe.numPerLine end,
								set = function(info, value)
									if value == 0 then value = nil end
									CompactUnitFrames.db.unitframe.numPerLine = value
									CompactUnitFrames:ContainerSetup(CompactRaidFrameContainer)
								end,
								step = 1,
								min = 0,
								max = 10,
							},
							orientation = {
								type = "select",
								name = "Orientation",
								order = 10,

								get = function(info) return CompactUnitFrames.db.unitframe.orientation end,
								set = function(info, value)
									CompactUnitFrames.db.unitframe.orientation = value
									CompactUnitFrames:ContainerSetup(CompactRaidFrameContainer)
								end,
								values = {["horizontal"] = "horizontal", ["vertical"] = "vertical"},
							},
							-- [TODO] width = nil, height = nil,
						},
					},
					indicators = {
						type = "group",
						name = "Indicators",
						inline = true,
						order = 3,
						args = {
							showDispellBorder = {
								type = "toggle",
								name = "Show dispell borders",
								desc = "Check to display a colored border when a debuff is applied.",
								order = 1,

								get = function(info) return CompactUnitFrames.db.indicators.showDispellBorder end,
								set = function(info, enable)
									CompactUnitFrames.db.indicators.showDispellBorder = enable
									ns:UpdateDispellDebuffDisplay(testFrame)
								end,
							},
							hideDispellIcons = {
								type = "toggle",
								name = "Hide dispell icons",
								desc = "Check to hide the icons shown when a debuff is applied.",
								order = 2,

								get = function(info) return CompactUnitFrames.db.indicators.hideDispellIcons end,
								set = function(info, hide)
									CompactUnitFrames.db.indicators.hideDispellIcons = hide
									ns:UpdateDispellDebuffDisplay(testFrame)
								end,
							},
							-- [TODO] center = { size = 10, posX = nil, posY = nil,
						},
					},
					buffs = {
						type = "group",
						name = "Buffs",
						inline = true,
						order = 10,
						args = {
							hidePermanent = {
								type = "toggle",
								name = "Hide permanent buffs",
								desc = "Check to hide buffs without a duration",
								order = 1,

								get = function(info) return CompactUnitFrames.db.buffs.hidePermanent end,
								set = function(info, enable)
									CompactUnitFrames.db.buffs.hidePermanent = enable
									-- [TODO] do something
								end,
							},
							showBoss = {
								type = "toggle",
								name = "Show boss effects",
								desc = "Check to always show auras applied by bosses",
								order = 2,

								get = function(info) return CompactUnitFrames.db.buffs.showBoss end,
								set = function(info, enable)
									CompactUnitFrames.db.buffs.showBoss = enable
									-- [TODO] do something
								end,
							},
							posX = {
								type = "range",
								name = "Horizontal position",
								order = 5,

								get = function(info) return CompactUnitFrames.db.buffs.offsetX end,
								set = function(info, value)
									CompactUnitFrames.db.buffs.offsetX = value
									-- [TODO] do something
								end,
								step = 1,
								min = -100,
								max = 100,
							},
							posY = {
								type = "range",
								name = "Vertical position",
								order = 6,

								get = function(info) return CompactUnitFrames.db.buffs.offsetY end,
								set = function(info, value)
									CompactUnitFrames.db.buffs.offsetY = value
									-- [TODO] do something
								end,
								step = 1,
								min = -100,
								max = 100,
							},
							showList = {
								type = "input",
								name = "Always show these",
								order = 10,

								get = function(info) return ns:GetListFromTable(CompactUnitFrames.db.buffs.show, "\n") end,
								set = function(info, input)
									CompactUnitFrames.db.buffs.show = ns:GetTableFromList(input, "\n")
								end,
								multiline = true,
								usage = "List spell IDs or spell names, each on a new line", -- [TODO]
							},
							hideList = {
								type = "input",
								name = "Never show these",
								order = 11,

								get = function(info) return ns:GetListFromTable(CompactUnitFrames.db.buffs.hide, "\n") end,
								set = function(info, input)
									CompactUnitFrames.db.buffs.hide = ns:GetTableFromList(input, "\n")
								end,
								multiline = true,
								usage = "List spell IDs or spell names, each on a new line", -- [TODO]
							},
						},
					},
					debuffs = {
						type = "group",
						name = "Debuffs",
						inline = true,
						order = 20,
						args = {
							hidePermanent = {
								type = "toggle",
								name = "Hide permanent debuffs",
								desc = "Check to hide debuffs without a duration",
								order = 1,

								get = function(info) return CompactUnitFrames.db.debuffs.hidePermanent end,
								set = function(info, enable)
									CompactUnitFrames.db.debuffs.hidePermanent = enable
									-- [TODO] do something
								end,
							},
							showBoss = {
								type = "toggle",
								name = "Show boss effects",
								desc = "Check to always show auras applied by bosses",
								order = 2,

								get = function(info) return CompactUnitFrames.db.debuffs.showBoss end,
								set = function(info, enable)
									CompactUnitFrames.db.debuffs.showBoss = enable
									-- [TODO] do something
								end,
							},
							posX = {
								type = "range",
								name = "Horizontal position",
								order = 5,

								get = function(info) return CompactUnitFrames.db.debuffs.offsetX end,
								set = function(info, value)
									CompactUnitFrames.db.debuffs.offsetX = value
									-- [TODO] do something
								end,
								step = 1,
								min = -100,
								max = 100,
							},
							posY = {
								type = "range",
								name = "Vertical position",
								order = 6,

								get = function(info) return CompactUnitFrames.db.debuffs.offsetY end,
								set = function(info, value)
									CompactUnitFrames.db.debuffs.offsetY = value
									-- [TODO] do something
								end,
								step = 1,
								min = -100,
								max = 100,
							},
							showList = {
								type = "input",
								name = "Always show these",
								order = 10,

								get = function(info) return ns:GetListFromTable(CompactUnitFrames.db.debuffs.show, "\n") end,
								set = function(info, input)
									CompactUnitFrames.db.debuffs.show = ns:GetTableFromList(input, "\n")
								end,
								multiline = true,
								usage = "List spell IDs or spell names, each on a new line", -- [TODO]
							},
							hideList = {
								type = "input",
								name = "Never show these",
								order = 11,

								get = function(info) return ns:GetListFromTable(CompactUnitFrames.db.debuffs.hide, "\n") end,
								set = function(info, input)
									CompactUnitFrames.db.debuffs.hide = ns:GetTableFromList(input, "\n")
								end,
								multiline = true,
								usage = "List spell IDs or spell names, each on a new line", -- [TODO]
							},
						},
					},
				},
			},
			appearance = {
				type = "group",
				name = "Appearance",
				order = 2,
				args = {
					healthBar = {
						type = "group",
						name = "Health Bar",
						inline = true,
						order = 1,
						args = {
							healthColor = {
								type = "color",
								name = "Status Bar Color",
								desc = "Color of health bar",
								order = 1,

								get = function(info)
									return CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.health.color, testFrame.displayedUnit)
								end,
								set = function(info, r, g, b)
									CompactUnitFrames.db.health.color = r..":"..g..":"..b
									CompactUnitFrame_UpdateHealthColor(testFrame)
								end,
							},
							healthColorClass = {
								type = "toggle",
								name = "Class Color",
								desc = "Check to use class colors for health bars",
								order = 2,

								get = function(info) return CompactUnitFrames.db.health.color == 'class' end,
								set = function(info, enable)
									CompactUnitFrames.db.health.color = enable and 'class' or CompactUnitFrames.db.health.color
									CompactUnitFrame_UpdateHealthColor(testFrame)
								end,
							},
							healthTexture = {
								type = "select",
								dialogControl = "LSM30_Statusbar",
								name = "Texture",
								desc = "Set the statusbar texture.",
								order = 3,

								values = SharedMedia:HashTable("statusbar"),
								get = function() return ns:LSM_GetMediaKey("statusbar", CompactUnitFrames.db.health.texture) end,
								set = function(self, texture)
									texture = SharedMedia:Fetch("statusbar", texture)
									CompactUnitFrames:CUF_SetHealthTexture(testFrame, texture)
									CompactUnitFrames.db.health.texture = texture
								end,
							},
							healthBGColor = {
								type = "color",
								name = "Background Color",
								desc = "Color of health bar background",
								order = 4,

								get = function(info)
									return CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.health.bgcolor, testFrame.displayedUnit)
								end,
								set = function(info, r, g, b)
									CompactUnitFrames.db.health.bgcolor = r..":"..g..":"..b
									CompactUnitFrames:CUF_SetHealthBGColor(testFrame, r, g, b)
								end,
							},
							healthBGColorClass = {
								type = "toggle",
								name = "Background as Class",
								desc = "Check to use class colors for health bar backgrounds",
								order = 5,

								get = function(info) return CompactUnitFrames.db.health.bgcolor == 'class' end,
								set = function(info, enable)
									CompactUnitFrames.db.health.bgcolor = enable and 'class' or CompactUnitFrames.db.health.bgcolor
									CompactUnitFrames:CUF_SetHealthBGColor(testFrame,
										CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.health.bgcolor, testFrame.displayedUnit)
									)
								end,
							},
							healthBGTexture = {
								type = "select",
								dialogControl = "LSM30_Statusbar",
								name = "Background Texture",
								desc = "Set the statusbar background texture.",
								order = 6,

								values = SharedMedia:HashTable("statusbar"),
								get = function() return ns:LSM_GetMediaKey("statusbar", CompactUnitFrames.db.health.bgtexture) end,
								set = function(self, texture)
									texture = SharedMedia:Fetch("statusbar", texture)
									CompactUnitFrames:CUF_SetHealthBGTexture(testFrame, texture)
									CompactUnitFrames.db.health.bgtexture = texture
								end,
							},
							healthVertical = {
								type = "toggle",
								name = "Vertical",
								desc = "Check to display the health bar vertically",
								order = 7,

								get = function(info) return CompactUnitFrames.db.health.vertical end,
								set = function(info, enable)
									CompactUnitFrames:CUF_SetHealthBarVertical(testFrame, enable)
									CompactUnitFrames.db.health.vertical = enable
								end,
							},
						},
					},
					powerBar = {
						type = "group",
						name = "Power Bar",
						inline = true,
						order = 2,
						args = {
							powerColor = {
								type = "color",
								name = "Status Bar Color",
								desc = "Color of power bar",
								order = 1,

								get = function(info)
									return CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.power.color, testFrame.displayedUnit)
								end,
								set = function(info, r, g, b)
									CompactUnitFrames.db.power.color = r..":"..g..":"..b
									CompactUnitFrame_UpdatePowerColor(testFrame)
								end,
							},
							powerColorClass = {
								type = "toggle",
								name = "Class Color",
								desc = "Check to use class colors for power bars",
								order = 2,

								get = function(info) return CompactUnitFrames.db.power.color == 'class' end,
								set = function(info, enable)
									CompactUnitFrames.db.power.color = enable and 'class' or CompactUnitFrames.db.power.color
									CompactUnitFrame_UpdatePowerColor(testFrame)
								end,
							},
							powerTexture = {
								type = "select",
								name = "Texture",
								desc = "Set the statusbar texture.",
								order = 3,

								dialogControl = "LSM30_Statusbar",
								values = SharedMedia:HashTable("statusbar"),
								get = function() return ns:LSM_GetMediaKey("statusbar", CompactUnitFrames.db.power.texture) end,
								set = function(self, texture)
									texture = SharedMedia:Fetch("statusbar", texture)
									CompactUnitFrames.db.power.texture = texture
									CompactUnitFrames:CUF_SetPowerTexture(testFrame, texture)
								end,
							},
							powerBGColor = {
								type = "color",
								name = "Background Color",
								desc = "Color of power bar background",
								order = 4,

								get = function(info)
									return CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.power.bgcolor, testFrame.displayedUnit)
								end,
								set = function(info, r, g, b)
									CompactUnitFrames.db.power.bgcolor = r..":"..g..":"..b
									CompactUnitFrames:CUF_SetPowerBGColor(testFrame, r, g, b)
								end,
							},
							powerBGColorClass = {
								type = "toggle",
								name = "Background as Class",
								desc = "Check to use class colors for power bar backgrounds",
								order = 5,

								get = function(info) return CompactUnitFrames.db.power.bgcolor == 'class' end,
								set = function(info, enable)
									CompactUnitFrames.db.power.bgcolor = enable and 'class' or CompactUnitFrames.db.power.bgcolor
									CompactUnitFrames:CUF_SetPowerBGColor(testFrame,
										CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.power.bgcolor, testFrame.displayedUnit)
									)
								end,
							},
							powerBGTexture = {
								type = "select",
								name = "Background Texture",
								desc = "Set the statusbar background texture.",
								order = 6,

								dialogControl = "LSM30_Statusbar",
								values = SharedMedia:HashTable("statusbar"),
								get = function() return ns:LSM_GetMediaKey("statusbar", CompactUnitFrames.db.power.bgtexture) end,
								set = function(self, texture)
									texture = SharedMedia:Fetch("statusbar", texture)
									CompactUnitFrames:CUF_SetPowerBGTexture(testFrame, texture)
									CompactUnitFrames.db.power.bgtexture = texture
								end,
							},
							powerVertical = {
								type = "toggle",
								name = "Vertical",
								desc = "Check to display the power bar vertically",
								order = 7,

								get = function(info) return CompactUnitFrames.db.power.vertical end,
								set = function(info, enable)
									CompactUnitFrames:CUF_SetPowerBarVertical(testFrame, enable, CompactUnitFrames.db.power.changePosition)
									CompactUnitFrames:CUF_SetSeperatorVertical(testFrame, enable, CompactUnitFrames.db.power.changePosition)
									CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
									CompactUnitFrames.db.power.vertical = enable
								end,
							},
							togglePosition = {
								type = "toggle",
								name = "Change bar position",
								desc = "Check to display the power bar right/on top depending on its orientation",
								order = 8,

								set = function(info, togglePosition)
									CompactUnitFrames:CUF_SetPowerBarVertical(testFrame, CompactUnitFrames.db.power.vertical, togglePosition)
									CompactUnitFrames:CUF_SetSeperatorVertical(testFrame, CompactUnitFrames.db.power.vertical, togglePosition)
									CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
									CompactUnitFrames.db.power.changePosition = togglePosition
								end,
								get = function(info) return CompactUnitFrames.db.power.changePosition end,
							},
							powerSize = {
								type = "range",
								name = "Size",
								desc = "Select the size of the power bar",
								order = 9,

								get = function(info) return CompactUnitFrames.db.power.size end,
								set = function(info, size)
									CompactUnitFrames.db.power.size = size
									CompactUnitFrames:CUF_SetPowerSize(testFrame, size)
								end,
								step = 1,
								min = 1,
								max = 100, -- [TODO] limit to frame height
							},
							powerBarDisplay = {
								type = "group",
								name = "Display Power Bar",
								inline = true,
								order = 10,
								args = {
									showSelf = {
										type = "toggle",
										name = "Show your own",
										desc = "Check to always display your own power bar, not depending on other settings",
										order = 1,

										get = function(info) return CompactUnitFrames.db.power.types.showSelf end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types.showSelf = enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showPets = {
										type = "toggle",
										name = "Show pet's power",
										desc = "Check to always display pets' power bars, not depending on other settings",
										order = 2,

										get = function(info) return CompactUnitFrames.db.power.types.showPets end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types.showPets = enable
										end,
									},
								}
							},
							powerBarDisplay2 = {
								type = "group",
								name = "Display Power Bar: By Type",
								inline = true,
								order = 10,
								args = {
									showUnknown = {
										type = "toggle",
										name = "Show unknown types",
										desc = "Check to allow power bars for types not listed here",
										order = 3,

										get = function(info) return CompactUnitFrames.db.power.types.showUnknown end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types.showUnknown = enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},

									showMana = {
										type = "toggle",
										name = "Show type: Mana",
										desc = "Check to allow power bars for mana users",
										order = 4,

										get = function(info) return not CompactUnitFrames.db.power.types[SPELL_POWER_MANA].hide end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types[SPELL_POWER_MANA].hide = not enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showRage = {
										type = "toggle",
										name = "Show type: Rage",
										desc = "Check to allow power bars for rage users",
										order = 5,

										get = function(info) return not CompactUnitFrames.db.power.types[SPELL_POWER_RAGE].hide end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types[SPELL_POWER_RAGE].hide = not enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showFocus = {
										type = "toggle",
										name = "Show type: Focus",
										desc = "Check to allow power bars for focus users",
										order = 6,

										get = function(info) return not CompactUnitFrames.db.power.types[SPELL_POWER_FOCUS].hide end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types[SPELL_POWER_FOCUS].hide = not enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showEnergy = {
										type = "toggle",
										name = "Show type: Energy",
										desc = "Check to allow power bars for energy users",
										order = 7,

										get = function(info) return not CompactUnitFrames.db.power.types[SPELL_POWER_ENERGY].hide end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types[SPELL_POWER_ENERGY].hide = not enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showRunicPower = {
										type = "toggle",
										name = "Show type: Runic Power",
										desc = "Check to allow power bars for runic power users",
										order = 8,

										get = function(info) return not CompactUnitFrames.db.power.types[SPELL_POWER_RUNIC_POWER].hide end,
										set = function(info, enable)
											CompactUnitFrames.db.power.types[SPELL_POWER_RUNIC_POWER].hide = not enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									--[[showRunes = {
										type = "toggle",
										name = "Show type: Runes",
										desc = "Check to always display power bars for rune users",
										order = 9,
									},
									showSoulShards = {
										type = "toggle",
										name = "Show type: Soul Shards",
										desc = "Check to always display power bars for soul shards users",
										order = 10,
									},
									showEclipse = {
										type = "toggle",
										name = "Show type: Eclipse",
										desc = "Check to always display power bars for eclipse users",
										order = 11,
									},
									showHolyPower = {
										type = "toggle",
										name = "Show type: Holy Power",
										desc = "Check to always display power bars for holy power users",
										order = 12,
									},]]--
								}
							},
							powerBarDisplay3 = {
								type = "group",
								name = "Display Power Bar: By Role",
								inline = true,
								order = 11,
								args = {
									showNone = {
										type = "toggle",
										name = NONE,
										desc = "Check to allow power bars for units without chosen roles.",
										order = 10,

										get = function(info) return CompactUnitFrames.db.power.roles["NONE"] end,
										set = function(info, enable)
											CompactUnitFrames.db.power.roles["NONE"] = enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showDamage = {
										type = "toggle",
										name = INLINE_DAMAGER_ICON.." "..DAMAGER,
										desc = "Check to allow power bars for damage dealers.",
										order = 2,

										get = function(info) return CompactUnitFrames.db.power.roles["DAMAGER"] end,
										set = function(info, enable)
											CompactUnitFrames.db.power.roles["DAMAGER"] = enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showTank = {
										type = "toggle",
										name = INLINE_TANK_ICON.." "..TANK,
										desc = "Check to allow power bars for tanks.",
										order = 3,

										get = function(info) return CompactUnitFrames.db.power.roles["TANK"] end,
										set = function(info, enable)
											CompactUnitFrames.db.power.roles["TANK"] = enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
									showHeal = {
										type = "toggle",
										name = INLINE_HEALER_ICON.." "..HEALER,
										desc = "Check to allow power bars for healers.",
										order = 4,

										get = function(info) return CompactUnitFrames.db.power.roles["HEALER"] end,
										set = function(info, enable)
											CompactUnitFrames.db.power.roles["HEALER"] = enable
											CompactUnitFrames:CUF_SetPowerBarShown(testFrame, CompactUnitFrames:ShouldDisplayPowerBar(testFrame))
										end,
									},
								}
							}
						},
					},
					nameText = {
						type = "group",
						name = "Unit Name Text",
						inline = true,
						order = 3,
						args = {
							nameFontColor = {
								type = "color",
								name = "Name Color",
								desc = "Choose a color to display unit names with",
								order = 1,

								get = function(info)
									return CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.name.color, testFrame.displayedUnit)
								end,
								set = function(info, r, g, b)
									CompactUnitFrames.db.name.color = r..":"..g..":"..b
									CompactUnitFrames:UpdateNameColor(testFrame)
								end,
							},
							nameFontColorClass = {
								type = "toggle",
								name = "Class Color",
								desc = "Check to use class colors for names",
								order = 2,

								get = function(info) return CompactUnitFrames.db.name.color == 'class' end,
								set = function(info, enable)
									CompactUnitFrames.db.name.color = enable and 'class' or CompactUnitFrames.db.name.color
									CompactUnitFrames:UpdateNameColor(testFrame)
								end,
							},
							nameFontJustifyH = {
								type = "select",
								name = "Justification",
								desc = "Select a font justification for the unit name",
								order = 3,

								values = {["LEFT"] = "LEFT", ["CENTER"] = "CENTER", ["RIGHT"] = "RIGHT"},
								get = function() return CompactUnitFrames.db.name.justifyH or testFrame.name:GetJustifyH() end,
								set = function(self, justify)
									CompactUnitFrames:CUF_SetNameJustifyH(testFrame, justify)
									CompactUnitFrames.db.name.justifyH = justify
								end,
							},
							nameFontSize = {
								type = "range",
								name = "Font Size",
								desc = "Select the font size of the unit name",
								order = 4,

								get = function(info) return CompactUnitFrames.db.name.fontSize or 10 end,
								set = function(info, size)
									CompactUnitFrames:CUF_SetNameFontSize(testFrame, size)
									CompactUnitFrames.db.name.fontSize = size
								end,
								step = 1,
								min = 5,
								max = 24,
							},
							nameFont = {
								type = "select",
								dialogControl = "LSM30_Font",
								name = "Name font",
								desc = "Select a font to display the unit name",
								order = 5,

								values = SharedMedia:HashTable("font"),
								get = function(info) return ns:LSM_GetMediaKey("font", CompactUnitFrames.db.name.font) end,
								set = function(info, font)
									font = SharedMedia:Fetch("font", font)
									CompactUnitFrames:CUF_SetNameFont(testFrame, font)
									CompactUnitFrames.db.name.font = font
								end,
							},
							nameFontStyle = {
								type = "select",
								name = "Font Style",
								desc = "Select a font style to display the unit name",
								order = 6,

								values = {["NONE"] = "NONE", ["OUTLINE"] = "OUTLINE", ["THICKOUTLINE"] = "THICKOUTLINE", ["MONOCHROME"] = "MONOCHROME"},
								get = function() return CompactUnitFrames.db.name.fontStyle or "NONE" end,
								set = function(self, outline)
									CompactUnitFrames:CUF_SetNameFontStyle(testFrame, outline)
									CompactUnitFrames.db.name.fontStyle = outline
								end,
							},
							nameSize = {
								type = "range",
								name = "Text Length",
								desc = "Select the number of characters for the unit name",
								order = 7,

								get = function(info) return CompactUnitFrames.db.name.size or 10 end,
								set = function(info, size)
									CompactUnitFrames:CUF_SetNameText(testFrame, size)
									CompactUnitFrames.db.name.size = size
								end,
								step = 1,
								min = 0,
								max = 20,
							},
							nameShortening = {
								type = "select",
								name = "Name Shortening",
								desc = "Select how to shorten the unit name if neccessary",
								order = 8,

								values = {["shorten"] = "Abbreviate", ["cut"] = "Cut", ["ellipsis"] = "Ellipsis"},
								get = function(info) return CompactUnitFrames.db.name.format or "ellipsis" end,
								set = function(info, shorten)
									CompactUnitFrames.db.name.format = shorten
									CompactUnitFrames:CUF_SetNameText(testFrame, CompactUnitFrames.db.name.size)
								end,
							},
							serverHeading = {
								type = "header",
								name = "Characters from different servers",
								order = 9,
							},
							serverFormat = {
								type = "select",
								name = "Display Server",
								desc = "If you choose short, you can further decide on a prefix and/or suffix.",
								order = 10,

								values = {["full"] = "Player - Realm", ["short"] = "<P>Player<S>", ["none"] = "Player"},
								get = function(info) return CompactUnitFrames.db.name.serverFormat or "full" end,
								set = function(info, format)
									CompactUnitFrames.db.name.serverFormat = format
									CompactUnitFrames:CUF_SetNameText(testFrame, CompactUnitFrames.db.name.size)
								end,
							},
							serverPrefix = {
								type = "input",
								name = "Prefix",
								desc = "If you chose short, you can further decide on a prefix and/or suffix.",
								order = 11,
								width = "half",

								get = function(info) return CompactUnitFrames.db.name.serverPrefix or "full" end,
								set = function(info, format)
									CompactUnitFrames.db.name.serverPrefix = format
									CompactUnitFrames:CUF_SetNameText(testFrame, CompactUnitFrames.db.name.size)
								end,
							},
							serverSuffix = {
								type = "input",
								name = "Suffix",
								desc = "If you chose short, you can further decide on a prefix and/or suffix.",
								order = 12,
								width = "half",

								get = function(info) return CompactUnitFrames.db.name.serverSuffix or "full" end,
								set = function(info, format)
									CompactUnitFrames.db.name.serverSuffix = format
									CompactUnitFrames:CUF_SetNameText(testFrame, CompactUnitFrames.db.name.size)
								end,
							},
						},
					},
					statusText = {
						type = "group",
						name = "Status Text",
						inline = true,
						order = 4,
						args = {
							statusFontColor = {
								type = "color",
								name = "Status Color",
								desc = "Choose a color to display status texts with",
								order = 14,

								get = function(info)
									return CompactUnitFrames:GetColorSetting(CompactUnitFrames.db.status.color, testFrame.displayedUnit)
								end,
								set = function(info, r, g, b)
									CompactUnitFrames.db.status.color = r..":"..g..":"..b
									CompactUnitFrames:UpdateStatusColor(testFrame)
								end,
							},
							statusFontColorClass = {
								type = "toggle",
								name = "Class Color",
								desc = "Check to use class colors for names",
								order = 15,

								get = function(info) return CompactUnitFrames.db.status.color == 'class' end,
								set = function(info, enable)
									CompactUnitFrames.db.status.color = enable and 'class' or CompactUnitFrames.db.status.color
									CompactUnitFrames:UpdateStatusColor(testFrame)
								end,
							},
							statusFontJustifyH = {
								type = "select",
								name = "Font Justification",
								desc = "Select a font justification for the status text",
								order = 16,

								values = {["LEFT"] = "LEFT", ["CENTER"] = "CENTER", ["RIGHT"] = "RIGHT"},
								get = function() return CompactUnitFrames.db.status.justifyH or testFrame.statusText:GetJustifyH() end,
								set = function(self, justify)
									CompactUnitFrames:CUF_SetStatusJustifyH(testFrame, justify)
									CompactUnitFrames.db.status.justifyH = justify
								end,
							},
							statusFontSize = {
								type = "range",
								name = "Font Size",
								desc = "Select the font size of the status text",
								order = 17,

								get = function(info) return CompactUnitFrames.db.status.fontSize or 10 end,
								set = function(info, size)
									CompactUnitFrames:CUF_SetStatusFontSize(frame, size)
									CompactUnitFrames.db.status.fontSize = size
								end,
								step = 1,
								min = 4,
								max = 24,
							},
							statusFont = {
								type = "select",
								dialogControl = "LSM30_Font",
								name = "Status text font",
								desc = "Select a font to display status texts",
								order = 18,

								values = SharedMedia:HashTable("font"),
								get = function(info) return ns:LSM_GetMediaKey("font", CompactUnitFrames.db.status.font) end,
								set = function(info, font)
									font = SharedMedia:Fetch("font", font)
									CompactUnitFrames:CUF_SetStatusFont(testFrame, font)
									CompactUnitFrames.db.status.font = font
								end,
							},
							statusFontStyle = {
								type = "select",
								name = "Font Style",
								desc = "Select a font style to display the status text",
								order = 19,

								values = {["NONE"] = "NONE", ["OUTLINE"] = "OUTLINE", ["THICKOUTLINE"] = "THICKOUTLINE", ["MONOCHROME"] = "MONOCHROME"},
								get = function() return CompactUnitFrames.db.status.fontStyle or "NONE" end,
								set = function(self, outline)
									CompactUnitFrames:CUF_SetStatusFontStyle(testFrame, outline)
									CompactUnitFrames.db.status.fontStyle = outline
								end,
							},
							statusSize = {
								type = "range",
								name = "Text Length",
								desc = "Select the number of characters for the status text",
								order = 20,

								get = function(info) return CompactUnitFrames.db.status.size or 10 end,
								set = function(info, size)
									CompactUnitFrames:CUF_SetStatusText(testFrame, size)
									CompactUnitFrames.db.status.size = size
								end,
								step = 1,
								min = 0,
								max = 20,
							},
							statusShortening = {
								type = "select",
								name = "Status Shortening",
								desc = "Select how to shorten the status text if neccessary",
								order = 21,

								values = {["shorten"] = "Abbreviate", ["cut"] = "Cut", ["ellipsis"] = "Ellipsis"},
								get = function(info) return CompactUnitFrames.db.status.format or "ellipsis" end,
								set = function(info, shorten)
									CompactUnitFrames.db.status.format = shorten
									CompactUnitFrames:CUF_SetStatusText(testFrame, CompactUnitFrames.db.status.size)
								end,
							},
						},
					},
				}
			},
			preview = {
				type = "group",
				name = "Preview State",
				order = 3,
				args = {
					livePreview = {
						type = "group",
						inline = true,
						name = "Live Preview",
						args = {
							addPlayer = {
								type = "execute",
								name = "Add player preview",
								func = function() ns:CreateTestFrame("dummy", "player") end,
							},
							addPet = {
								type = "execute",
								name = "Add pet preview",
								func = function() ns:CreateTestFrame("dummy_small", "pet") end,
							},
						},
					},
					previewState = {
						type = "group",
						inline = true,
						name = "Test Frame State",
						args = {
							health = {
								type = "range",
								name = "Health",
								min = 0,
								max = 1,
								isPercent = true,
								order = 1,

								get = function() return testFrame.healthBar:GetValue() / UnitHealthMax(testFrame.displayedUnit) end,
								set = function(info, value) testFrame.healthBar:SetValue(value * UnitHealthMax(testFrame.displayedUnit)) end,
							},
							power = {
								type = "range",
								name = "Power",
								min = 0,
								max = 1,
								isPercent = true,
								order = 2,

								get = function() return testFrame.powerBar:GetValue() / UnitPowerMax(testFrame.displayedUnit) end,
								set = function(info, value) testFrame.powerBar:SetValue(value * UnitPowerMax(testFrame.displayedUnit)) end,
							},
							--[[ healPredict = {
								type = "range",
								name = "Heal Prediction",
								min = 0,
								max = 1,
								isPercent = true,
								order = 4,

								get = function() return testFrame.otherHealPredictionBar:GetValue() / UnitHealthMax(testFrame.displayedUnit) end,
								set = function(info, value) testFrame.otherHealPredictionBar:SetValue(value * UnitHealthMax(testFrame.displayedUnit)) end,
							},
							myHealPredict = {
								type = "range",
								name = "Heal Prediction (yours)",
								min = 0,
								max = 1,
								isPercent = true,
								order = 5,

								get = function() return testFrame.myHealPredictionBar:GetValue() / UnitHealthMax(testFrame.displayedUnit) end,
								set = function(info, value) testFrame.myHealPredictionBar:SetValue(value * UnitHealthMax(testFrame.displayedUnit)) end,
							}, --]]
						},
					},
					debuffs = {
						type = "group",
						name = "Debuffs",
						inline = true,
						order = 3,
						args = {
							hasMagic = {
								type = "toggle",
								name = "Has magic",
								order = 1,

								get = function(info) return testFrame["hasDispelMagic"] end,
								set = function(info, enable)
									ns:Simulate_DebuffIcon(testFrame, "Magic", enable)
								end,
							},
							hasDisease = {
								type = "toggle",
								name = "Has disease",
								order = 1,

								get = function(info) return testFrame["hasDispelDisease"] end,
								set = function(info, enable)
									ns:Simulate_DebuffIcon(testFrame, "Disease", enable)
								end,
							},
							hasCurse = {
								type = "toggle",
								name = "Has curse",
								order = 1,

								get = function(info) return testFrame["hasDispelCurse"] end,
								set = function(info, enable)
									ns:Simulate_DebuffIcon(testFrame, "Curse", enable)
								end,
							},
							hasPoison = {
								type = "toggle",
								name = "Has poison",
								order = 1,

								get = function(info) return testFrame["hasDispelPoison"] end,
								set = function(info, enable)
									ns:Simulate_DebuffIcon(testFrame, "Poison", enable)
								end,
							},
						},
					}
				},
			}
		}
	}

	local optionsName = "CompactUnitFrames"
	-- In case the addon is loaded from another condition, always call the remove interface options
	if AddonLoader and AddonLoader.RemoveInterfaceOptions then
		AddonLoader:RemoveInterfaceOptions(optionsName)
	end

	AceConfig:RegisterOptionsTable(addonName, optionsTable, {"cuf_ace"})
	local optionsPanel = AceConfigDialog:AddToBlizOptions(addonName, optionsName)
	optionsPanel.okay = function() CompactUnitFrames:SaveConfig() end
	optionsPanel.cancel = function() CompactUnitFrames:ResetConfig() end

	testFrame:SetParent(optionsPanel)
	testFrame:SetPoint("TOPRIGHT", -14, -14)
end
