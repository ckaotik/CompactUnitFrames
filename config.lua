local addonName, ns = ...

--[[ Attribute		Possible Values
	-----------		----------------
	colors			class, default, r.r:g.g:b.b
	orientations	true:vertical, false/nil:horizontal
	text formats	shorten
]]--
ns.config = {
	frames = {
		disableCUF = nil,
		pullout = {
			posX = nil,
			posY = nil,
			minify = true,
		},

		-- horizontal = nil,
		-- numRows = nil,
		-- numColumns = nil,
		-- maxWidth = nil,
		-- maxHeight = nil,

		showSolo = true,
		-- showGroup = true,
		-- showRaid = true,
		-- showGroupInRaid = nil,
	},
	unitframe = {
		width = nil,
		height = nil,
		-- anchor = 'TOPLEFT',

		-- tooltip = true,
		-- tooltipInCombat = nil,
		menuClickInCombat = nil,
		hidePowerSeperator = nil,
	},
	health = {
		vertical = nil,
		texture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		bgtexture = 'Interface\\Addons\\Midget\\media\\TukTexture.tga',
		color = '0.16:0.19:0.23',
		bgcolor = '0.74:0.75:0.77',
	},
	power = {
		vertical = nil,
		changePosition = nil,	-- [vertical] true:left, false:right; [horizontal] true:top, false:bottom
		texture = nil,
		bgtexture = nil,
		color = 'default',
		bgcolor = nil,
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
			-- UnitPowerType(frame.displayedUnit) :: powerType, powerToken, power type (string), altR, altG, altB
		},
	},
	name = {
		size = 7,
		color = 'class', -- [TODO] what about pets?
		format = 'shorten',
		-- font = nil,
		-- fontSize = nil,
	},
	status = {
		size = 7,
		color = nil,
		format = 'shorten',
		-- font = nil,
		-- fontSize = nil,
	},
	buffs = {
		-- filter = nil,
		show = {},
		hide = { "Champion von Orgrimmar", "Champion von Unterstadt", "Champion der Dunkelspeertrolle" },
		posX = 1,
		posY = 1,
	},
	debuffs = {
		-- filter = nil,
		-- alwaysShow = {},
		-- alwaysHide = {},
		offsetX = 1,
		offsetY = 1,
	},
	indicators = {
		center = {
			size = 10,
			posX = nil,
			posY = nil,
			-- alpha = 1,
			-- borderColor = nil,
		},
		-- top = {},
		-- right = {},
		-- bottom = {},
		-- left = {},

		-- topleft = {},
		-- topright = {},
		-- bottomright = {},
		-- bottomleft = {},
	},
}