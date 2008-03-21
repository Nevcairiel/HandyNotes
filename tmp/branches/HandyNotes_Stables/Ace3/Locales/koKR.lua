if select(2, UnitClass("player")) ~= "HUNTER" then return end

local L = LibStub("AceLocale-3.0"):NewLocale("HandyNotes_Stables", "koKR")
if L then
	L["Stable Master"] = "야수 조련사"
	L["These settings control the look and feel of the Stables icons."] = "야수 조련사 아이콘에 대한 설정입니다."
	L["Icon Scale"] = "아이콘 크기"
	L["The scale of the icons"] = "아이콘의 크기를 변경합니다."
	L["Icon Alpha"] = "아이콘 투명도"
	L["The alpha transparency of the icons"] = "아이콘의 투명도를 변경합니다."
	L["Create waypoint"] = "웨이포인트 추가"
	L["Delete stables"] = "야수 삭제"
	L["Close"] = "닫기"
end
