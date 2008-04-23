
---------------------------------------------------------
-- Addon declaration
HandyNotes_Vendors = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_Vendors","AceEvent-3.0")
local HV = HandyNotes_Vendors
local Astrolabe = DongleStub("Astrolabe-0.4-NC")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_Vendors")


---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local defaults = {
	profile = {
		icon_scale = 1.0,
		icon_alpha = 1.0,
	},
	factionrealm = {
		nodes = {
			["*"] = {},
		}
	},
}


---------------------------------------------------------
-- Localize some globals
local next = next
local GameTooltip = GameTooltip
local WorldMapTooltip = WorldMapTooltip
local HandyNotes = HandyNotes


---------------------------------------------------------
-- Constants
local iconN = "Interface\\Minimap\\Tracking\\Food"
local iconR = "Interface\\Minimap\\Tracking\\Repair"


---------------------------------------------------------
-- Plugin Handlers to HandyNotes

local HVHandler = {}

local function deletePin(mapFile,coord)
	local x, y = HandyNotes:getXY(coord)
	db.factionrealm.nodes[mapFile][coord] = nil
	HV:SendMessage("HandyNotes_NotifyUpdate", "Vendors")
end
local function createWaypoint(mapFile,coord)
	local c, z = HandyNotes:GetCZ(mapFile)
	local x, y = HandyNotes:getXY(coord)
	local vType, vName, vGuild = strsplit(":", db.factionrealm.nodes[mapFile][coord])
	if TomTom then
		TomTom:AddZWaypoint(c, z, x*100, y*100, vName)
	elseif Cartographer_Waypoints then
		Cartographer_Waypoints:AddWaypoint(NotePoint:new(HandyNotes:GetCZToZone(c, z), x, y, vName))
	end
end

local clickedVendors, clickedVendorsZone
local info = {}
local function generateMenu(level)
	if (not level) then return end
	for k in pairs(info) do info[k] = nil end
	if (level == 1) then
		-- Create the title of the menu
		info.isTitle      = 1
		info.text         = L["HandyNotes - Vendors"]
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level)

		if TomTom or Cartographer_Waypoints then
			-- Waypoint menu item
			info.disabled     = nil
			info.isTitle      = nil
			info.notCheckable = nil
			info.text = L["Create waypoint"]
			info.icon = nil
			info.func = createWaypoint
			info.arg1 = clickedVendorsZone
			info.arg2 = clickedVendors
			UIDropDownMenu_AddButton(info, level);
		end

		-- Delete menu item
		info.disabled     = nil
		info.isTitle      = nil
		info.notCheckable = nil
		info.text = L["Delete vendor"]
		info.icon = nil
		info.func = deletePin
		info.arg1 = clickedVendorsZone
		info.arg2 = clickedVendors
		UIDropDownMenu_AddButton(info, level);

		-- Close menu item
		info.text         = L["Close"]
		info.icon         = nil
		info.func         = CloseDropDownMenus
		info.arg1         = nil
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level);
	end
end
local HV_Dropdown = CreateFrame("Frame", "HandyNotes_VendorsDropdownMenu")
HV_Dropdown.displayMode = "MENU"
HV_Dropdown.initialize = generateMenu

function HVHandler:OnClick(button, down, mapFile, coord)
	if button == "RightButton" and not down then
		clickedVendorsZone = mapFile
		clickedVendors = coord
		ToggleDropDownMenu(1, nil, HV_Dropdown, self, 0, 0)
	end
end

function HVHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if ( self:GetCenter() > UIParent:GetCenter() ) then -- compare X coordinate
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	local vType, vName, vGuild = strsplit(":", db.factionrealm.nodes[mapFile][coord])
	tooltip:AddLine("|cffe0e0e0"..vName.."|r")
	if (vGuild ~= "") then tooltip:AddLine(vGuild) end
--	tooltip:AddLine(L["Vendor"])
	tooltip:Show()
end

function HVHandler:OnLeave(mapFile, coord)
	if self:GetParent() == WorldMapButton then
		WorldMapTooltip:Hide()
	else
		GameTooltip:Hide()
	end
end

do
	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		local state, value = next(t, prestate)
		while state do
			if value then
				local vType, vName, vGuild = strsplit(":", value)
				local icon = iconN
				if vType == "R" then icon = iconR end
				return state, nil, icon, db.profile.icon_scale, db.profile.icon_alpha
			end
			state, value = next(t, state)
		end
		return nil, nil, nil, nil
	end
	function HVHandler:GetNodes(mapFile)
		return iter, db.factionrealm.nodes[mapFile], nil
	end
end


---------------------------------------------------------
-- Options table

local options = {
	type = "group",
	name = "Vendors",
	desc = "Vendors",
	get = function(info) return db.profile[info.arg] end,
	set = function(info, v)
		db.profile[info.arg] = v
		HV:SendMessage("HandyNotes_NotifyUpdate", "Vendors")
	end,
	args = {
		desc = {
			name = L["These settings control the look and feel of the Vendors icons."],
			type = "description",
			order = 0,
		},
		icon_scale = {
			type = "range",
			name = L["Icon Scale"],
			desc = L["The scale of the icons"],
			min = 0.25, max = 2, step = 0.01,
			arg = "icon_scale",
			order = 10,
		},
		icon_alpha = {
			type = "range",
			name = L["Icon Alpha"],
			desc = L["The alpha transparency of the icons"],
			min = 0, max = 1, step = 0.01,
			arg = "icon_alpha",
			order = 20,
		},
	},
}


---------------------------------------------------------
-- NPC info tracking - TT handling

local tt = CreateFrame("GameTooltip")
tt:SetOwner(UIParent, "ANCHOR_NONE")
tt.left = {}
tt.right = {}

for i = 1, 30 do
	tt.left[i] = tt:CreateFontString()
	tt.left[i]:SetFontObject(GameFontNormal)
	tt.right[i] = tt:CreateFontString()
	tt.right[i]:SetFontObject(GameFontNormal)
	tt:AddFontStrings(tt.left[i], tt.right[i])
end


local LEVEL_start = "^" .. (type(LEVEL) == "string" and LEVEL or "Level")
local function FigureNPCGuild(unit)
	tt:ClearLines()
	tt:SetOwner(UIParent, "ANCHOR_NONE")
	tt:SetUnit(unit)

	local left_2 = tt.left[2]:GetText()
	if not left_2 or left_2:find(LEVEL_start) then
		return ""
	end

	return left_2
end


---------------------------------------------------------
-- Addon initialization, enabling and disabling

function HV:OnInitialize()
	-- Set up our database
	db = LibStub("AceDB-3.0"):New("HandyNotes_VendorsDB", defaults)
	self.db = db

	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("Vendors", HVHandler, options)
end

function HV:OnEnable()
	self:RegisterEvent("MERCHANT_SHOW")
end

local thres = 5 -- in yards
function HV:MERCHANT_SHOW()
	local vendorName = UnitName("target")
	local canRepair = CanMerchantRepair()
	local vGuild = FigureNPCGuild("target")
	local vInfo
	if canRepair then
		vInfo =  "R:" .. vendorName .. ":" .. vGuild
	else
		vInfo =  "N:" .. vendorName .. ":" .. vGuild
	end
	local continent, zone, x, y = Astrolabe:GetCurrentPlayerPosition()
	if not vendorName or not continent then
		return
	end

	local coord = HandyNotes:getCoord(x, y)
	local map = HandyNotes:GetMapFile(continent, zone)
	if map then
		for coords, name in pairs(db.factionrealm.nodes[map]) do
			if vInfo == name then
				local cx, cy = HandyNotes:getXY(coords)
				local dist = Astrolabe:ComputeDistance(continent, zone, x, y, continent, zone, cx, cy)
				if dist <= thres then -- Vendor already exists here
					return
				else -- Vendor exists on different location = has moved -> delete old info
					db.factionrealm.nodes[map][coords] = nil
				end
			end
		end
		
		db.factionrealm.nodes[map][coord] = vInfo
		self:SendMessage("HandyNotes_NotifyUpdate", "Vendors")
	end
end
