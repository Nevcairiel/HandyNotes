if select(2, UnitClass("player")) ~= "HUNTER" then return end

local L = LibStub("AceLocale-3.0"):NewLocale("HandyNotes_Stables", "zhCN")
if L then
	L["Stable Master"] = "兽栏管理员"
	L["These settings control the look and feel of the Stables icons."] = "这些设置控制着兽栏管理员图标的外观与样式。"
	L["Icon Scale"] = "图标缩放"
	L["The scale of the icons"] = "图标的缩放值"
	L["Icon Alpha"] = "图标透明度"
	L["The alpha transparency of the icons"] = "图标的透明度值"
	L["Create waypoint"] = "创建路径节点"
	L["Delete stables"] = "删除兽栏"
	L["Close"] = "关闭"
end
