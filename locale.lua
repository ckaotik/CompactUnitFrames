local addonName, addon, _ = ...

-- TODO: might check out AceLocale
local L = setmetatable({}, {
	__index = function(self, key)
		-- localization not found, return key as-is
		return key
	end,
})
addon.L = L

--
-- L["source string"] = true

local locale = GetLocale()
if locale == 'deDE' then
	-- L["source string"] = "localized string"
end
