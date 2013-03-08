local addonName, ns = ...

--[[ Attribute		Possible Values
	-----------		----------------
	colors			class, default, r.r:g.g:b.b
	orientations	true:vertical, false/nil:horizontal
	text formats	shorten, cut
	font style 		'MONOCHROME', 'OUTLINE', 'THICKOUTLINE'
	justifyH		'LEFT', 'CENTER', 'RIGHT'
	justifyV		'TOP', 'MIDDLE', 'BOTTOM'
]]--
ns.config = {
	frames = {
		disableCUF = nil,
		showSolo = nil,
		pullout = {
			posX = nil,
			posY = nil,
			minify = nil,
			passiveAlpha = 0.3,
			activeAlpha = 1,
		},
		-- horizontal = nil,
		-- numRows = nil,
		-- numColumns = nil,
		-- maxWidth = nil,
		-- maxHeight = nil,
	},
	unitframe = {
		width = nil,
		height = nil,
		-- anchor = 'TOPLEFT',

		innerPadding = 1,
		spacingX = 0,
		spacingY = 0,

		-- tooltip = true,
		-- tooltipInCombat = nil,
		noMenuClickInCombat = nil,
		hidePowerSeperator = nil,
	},
	health = {
		vertical = nil,
		texture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		bgtexture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		color = '0.16:0.19:0.23',
		bgcolor = '0.74:0.75:0.77',
		flagsAsPvPColor = '0.64:0.07:0.07',
	},
	power = {
		vertical = nil,
		changePosition = nil,	-- [vertical] true:left, false:right; [horizontal] true:top, false:bottom
		texture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		bgtexture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		color = 'default',
		bgcolor = '0:0:0',
		size = 6,
		types = {
			showSelf = true,
			showPets = nil,
			showUnknown = true,

			[SPELL_POWER_MANA] = { --[[color = nil,]] hide = nil },
			[SPELL_POWER_RAGE] = { --[[color = nil,]] hide = true },
			[SPELL_POWER_FOCUS] = { --[[color = nil,]] hide = true },
			[SPELL_POWER_ENERGY] = { --[[color = nil,]] hide = true },
			[SPELL_POWER_RUNES] = { --[[color = nil,]] hide = nil },
			[SPELL_POWER_RUNIC_POWER] = { --[[color = nil,]] hide = true },
			[SPELL_POWER_SOUL_SHARDS] = { --[[color = nil,]] hide = nil },
			[SPELL_POWER_ECLIPSE] = { --[[color = nil,]] hide = nil },
			[SPELL_POWER_HOLY_POWER] = { --[[color = nil,]] hide = nil },
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

		font = nil,
		fontSize = nil,
		fontStyle = nil,
		justifyH = nil,
	},
	status = {
		size = 7,
		color = nil,
		format = 'shorten',

		font = nil,
		fontSize = nil,
		fontStyle = nil,
		justifyH = nil,
	},
	buffs = {
		-- filter = nil,
		hide = { 93825, 94462, 93827 },
		show = {},
		hidePermanent = true,
		showBoss = true,
		posX = 1,
		posY = 1,
	},
	debuffs = {
		-- filter = nil,
		hide = { 57724, 80354, 57723, 90355, 36032, 96328 }, -- heroism x4, arcane blast, toxic torment
		show = {},
		hidePermanent = true,
		showBoss = true,
		offsetX = 1,
		offsetY = 1,
	},
	indicators = {
		showDispellBorder = nil,
		hideDispellIcons = nil,

		center = {
			size = 10,
			posX = nil,
			posY = nil,
			-- alpha = 1,
			-- borderColor = nil,
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
