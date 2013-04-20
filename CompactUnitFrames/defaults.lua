local addonName, ns = ...

--[[ Attribute		Possible Values
	-----------		----------------
	colors			class, default, r.r:g.g:b.b
	orientations	true:vertical, false/false:horizontal
	text formats	shorten, cut
	font style 		'MONOCHROME', 'OUTLINE', 'THICKOUTLINE'
	justifyH		'LEFT', 'CENTER', 'RIGHT'
	justifyV		'TOP', 'MIDDLE', 'BOTTOM'
]]--
ns.defaults = {
	frames = {
		disableCUF = false,
		showSolo = false,
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
		width = false,
		height = false,
		-- anchor = 'TOPLEFT',

		innerPadding = 1,
		spacingX = 0,
		spacingY = 0,

		-- tooltip = true,
		-- tooltipInCombat = false,
		noMenuClickInCombat = false,
		hidePowerSeperator = false,

		enableGPS = true,
		gpsOnHover = true,
		gpsOutOfRange = true,
	},
	health = {
		vertical = false,
		texture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		bgtexture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		color = '0.16:0.19:0.23',
		bgcolor = '0.74:0.75:0.77',
		flagsAsPvPColor = '0.64:0.07:0.07',
	},
	power = {
		vertical = false,
		changePosition = false,	-- [vertical] true:left, false:right; [horizontal] true:top, false:bottom
		texture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		bgtexture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		color = 'default',
		bgcolor = '0:0:0',
		size = 6,
		types = {
			showSelf = true,
			showPets = false,
			showUnknown = true,

			[SPELL_POWER_MANA] = { --[[color = false,]] hide = false },
			[SPELL_POWER_RAGE] = { --[[color = false,]] hide = true },
			[SPELL_POWER_FOCUS] = { --[[color = false,]] hide = true },
			[SPELL_POWER_ENERGY] = { --[[color = false,]] hide = true },
			[SPELL_POWER_RUNES] = { --[[color = false,]] hide = false },
			[SPELL_POWER_RUNIC_POWER] = { --[[color = false,]] hide = true },
			[SPELL_POWER_SOUL_SHARDS] = { --[[color = false,]] hide = false },
			[SPELL_POWER_ECLIPSE] = { --[[color = false,]] hide = false },
			[SPELL_POWER_HOLY_POWER] = { --[[color = false,]] hide = false },
			-- /dump PowerBarColor > ALTERNATE_POWER_INDEX, FUEL, UNUSED
		},
		roles = {
			["NONE"] = true,
			["DAMAGER"] = true,
			["HEALER"] = true,
			["TANK"] = true,
		}
	},
	name = {
		size = 10,
		color = 'class', -- [TODO] what about pets?
		format = 'cut',
		serverFormat = 'short', 	-- [TODO] new! 'full':"player - realm", 'short':"player (*)", 'none':"player"
		serverPrefix = '',
		serverSuffix = '*',			-- only applies when serverFormat is set to 'short'

		font = false,
		fontSize = false,
		fontStyle = false,
		justifyH = false,
	},
	status = {
		size = 7,
		color = false,
		format = 'shorten',

		font = false,
		fontSize = false,
		fontStyle = false,
		justifyH = false,
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
		showDispellBorder = false,
		hideDispellIcons = false,

		center = {
			size = 10,
			posX = false,
			posY = false,
			-- alpha = 1,
			-- borderColor = false,
		},
		-- top, right, bottom, left, topleft, topright, bottomright, bottomleft
	},
}

function ns:SaveConfig()
	CUF_GlobalDB = ns.db
end
function ns:ResetConfig()
	-- ?
end
