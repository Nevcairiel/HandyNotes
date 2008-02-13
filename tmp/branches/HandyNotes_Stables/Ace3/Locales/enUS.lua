if select(2, UnitClass("player")) ~= "HUNTER" then return end

local L = LibStub("AceLocale-3.0"):NewLocale("HandyNotes_Stables", "enUS", true)
if L then
    L["Stable Master"] = true
	L["These settings control the look and feel of the Stables icons."] = true
	L["Icon Scale"] = true
	L["The scale of the icons"] = true
	L["Icon Alpha"] = true
	L["The alpha transparency of the icons"] = true
end
