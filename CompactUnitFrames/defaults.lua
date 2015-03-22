local addonName, addon, _ = ...
-- local L = addon.L

local statusFont, statusSize = GameFontNormal:GetFont()
local nameFont, nameSize = GameFontHighlightSmall:GetFont()

addon.defaults = {
	profile = {
		frames = {
			disableCUF = false,
			showSolo = false,
			taintUpdate = true,
			pullout = {
				posX = false,
				posY = false,
				minify = false,
				passiveAlpha = 0.3,
				activeAlpha = 1,
			},
			-- horizontal = false,
			-- numRows = false,
			-- numColumns = false,
			-- maxWidth = false,
			-- maxHeight = false,
		},
		unitframe = {
			-- width = false,
			-- height = false,
			-- anchor = 'TOPLEFT',

			innerPadding = 1,
			spacingX = 0,
			spacingY = 0,

			bgtexture = 'Interface\\RaidFrame\\Raid-Bar-Hp-Bg',
			bgcolor = {0, 0, 0, 1},
			bgcolorType = 'custom',
			roleIconSize = 12,
			-- tooltip = true,
			-- tooltipInCombat = false,
			noMenuClickInCombat = false,
			showSeparator = true,

			enableAFKTimers = true,
			enableGPS = true,
			gpsOnHover = true,
			gpsOutOfRange = true,
			enableOverlay = true, -- CC icon etc.
		},
		health = {
			vertical = false,
			texture = 'Interface\\RaidFrame\\Raid-Bar-Hp-Fill',
			bgtexture = 'Interface\\RaidFrame\\Raid-Bar-Hp-Bg',
			color = {.16, .19, .23},
			colorType = 'custom',
			bgcolor = {.74, .75, .77},
			bgcolorType = 'custom',
			flagsAsPvPColor = {0, .6, .1},
			isEnemyColor = {.8, .3, .22}, -- was {.64, .07, .07}
		},
		power = {
			vertical = false,
			changePosition = false,	-- [vertical] true:left, false:right; [horizontal] true:top, false:bottom
			texture = 'Interface\\RaidFrame\\Raid-Bar-Resource-Fill',
			bgtexture = 'Interface\\RaidFrame\\Raid-Bar-Resource-Background',
			color = {1, 1, 1, 1},
			colorType = 'default',
			bgcolor = {0, 0, 0},
			bgcolorType = 'custom',
			size = 6,
			showSelf = true,
			-- showPets = false,
			roles = {
				["NONE"] = true,
				["DAMAGER"] = true,
				["HEALER"] = true,
				["TANK"] = true,
			},
			types = {
				[-1] = true,
				[SPELL_POWER_MANA] = true,
				[SPELL_POWER_RAGE] = false,
				[SPELL_POWER_FOCUS] = false,
				[SPELL_POWER_ENERGY] = false,
				[SPELL_POWER_RUNES] = true,
				[SPELL_POWER_RUNIC_POWER] = false,
				[SPELL_POWER_SOUL_SHARDS] = true,
				[SPELL_POWER_ECLIPSE] = true,
				[SPELL_POWER_HOLY_POWER] = true,
			},
		},
		name = {
			size = 10,
			color = {1, 1, 1, 1},
			colorType = 'class', -- [TODO] what about pets?
			format = 'cut',
			serverFormat = 'short',
			serverPrefix = '',
			serverSuffix = '*',	-- only applies when serverFormat is set to 'short'

			font = nameFont,
			fontSize = nameSize,
			fontStyle = 'NONE',
			justifyH = 'LEFT',
		},
		status = {
			size = 7,
			color = {1, 1, 1, 1},
			colorType = 'default',
			format = 'shorten',
			afkFormat = '|TInterface\\FriendsFrame\\StatusIcon-Away:0|t%d:%02d', -- vertical ellipsis: ⋮

			font = statusFont,
			fontSize = statusSize,
			fontStyle = 'NONE',
			justifyH = 'LEFT',
		},
		buffs = {
			-- filter = false,
			hide = { 93825, 94462, 93827 },
			show = {},
			hidePermanent = true,
			showBoss = true,
			posX = 1,
			posY = 1,
		},
		debuffs = {
			-- filter = false,
			hide = { 57724, 80354, 57723, 90355, 36032, 96328 }, -- heroism x4, arcane blast, toxic torment
			show = {},
			hidePermanent = true,
			showBoss = true,
			offsetX = 1,
			offsetY = 1,
		},
		indicators = {
			showDispellIcons = true,
			showDispellBorder = false,
			showDispellHealth = true,

			center = {
				size = 10,
				posX = 0,
				posY = 0,
				-- alpha = 1,
				-- borderColor = false,
			},
			-- top, right, bottom, left, topleft, topright, bottomright, bottomleft
		},
	},
}
