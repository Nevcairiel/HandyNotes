if select(2, UnitClass("player")) ~= "HUNTER" then return end

---------------------------------------------------------
-- Addon declaration
HandyNotes_Stables = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_Stables","AceEvent-3.0")
local HS = HandyNotes_Stables
local Astrolabe = DongleStub("Astrolabe-0.4")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_Stables")

---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local defaults = {
	profile = {
		icon_scale = 0.8,
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
local icon = "Interface\\Icons\\Ability_Hunter_BeastTaming"


---------------------------------------------------------
-- Plugin Handlers to HandyNotes

local HSHandler = {}

local function deletePin(mapFile,coord)
	local x, y = HandyNotes:getXY(coord)
	db.factionrealm.nodes[mapFile][coord] = nil
	HMB:SendMessage("HandyNotes_NotifyUpdate", "Stables")
end
local zonenames = {}
local function populateZoneNames(...)
	for ci=1,select('#', ...) do
		zonenames[ci] = {GetMapZones(ci)}
	end
end
populateZoneNames(GetMapContinents())
local function createWaypoint(mapFile,coord)
	local c, z = HandyNotes:GetCZ(mapFile)
	local x, y = HandyNotes:getXY(coord)
	if TomTom then
		TomTom:AddZWaypoint(c, z, x*100, y*100, L["Stable Master"])
	elseif Cartographer_Waypoints then
		local zone = zonenames[c][z]
		Cartographer_Waypoints:AddWaypoint(NotePoint:new(zone, x, y, L["Stable Master"]))
	end
end
local clickedStables, clickedStablesZone
local function generateMenu(level)
	if (not level) then return end
	for k in pairs(info) do info[k] = nil end
	if (level == 1) then
		-- Create the title of the menu
		info.isTitle      = 1
		info.text         = L["Stable Master"]
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
			info.arg1 = clickedStablesZone
			info.arg2 = clickedStables
			UIDropDownMenu_AddButton(info, level);
		end

		-- Delete menu item
		info.disabled     = nil
		info.isTitle      = nil
		info.notCheckable = nil
		info.text = L["Delete stables"]
		info.icon = icon
		info.func = deletePin
		info.arg1 = clickedStablesZone
		info.arg2 = clickedStables
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
local HS_Dropdown = CreateFrame("Frame", "HandyNotes_StablesDropdownMenu")
HS_Dropdown.displayMode = "MENU"
HS_Dropdown.initialize = generateMenu

function HSHandler:OnClick(button, down, mapFile, coord)
	if button == "RightButton" and not down then
		clickedStablesZone = mapFile
		clickedStables = coord
		ToggleDropDownMenu(1, nil, HS_Dropdown, self, 0, 0)
	end
end

function HSHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if ( self:GetCenter() > UIParent:GetCenter() ) then -- compare X coordinate
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	tooltip:AddLine("|cffe0e0e0"..db.factionrealm.nodes[mapFile][coord].."|r")
	tooltip:AddLine(L["Stable Master"])
	tooltip:Show()
end

function HSHandler:OnLeave(mapFile, coord)
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
		return state, nil, icon, db.profile.icon_scale, db.profile.icon_alpha
	end
	function HSHandler:GetNodes(mapFile)
		return iter, db.factionrealm.nodes[mapFile], nil
	end
end


---------------------------------------------------------
-- Options table
local options = {
	type = "group",
	name = "Stables",
	desc = "Stables",
	get = function(info) return db.profile[info.arg] end,
	set = function(info, v)
		db.profile[info.arg] = v
		HS:SendMessage("HandyNotes_NotifyUpdate", "Stables")
	end,
	args = {
		desc = {
			name = L["These settings control the look and feel of the Stables icons."],
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
-- Addon initialization, enabling and disabling

function HS:OnInitialize()
	-- Set up our database
	db = LibStub("AceDB-3.0"):New("HandyNotes_StablesDB", defaults)
	self.db = db

	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("Stables", HSHandler, options)
end

function HS:OnEnable()
	self:RegisterEvent("PET_STABLE_SHOW")
end

local thres = 5 -- in yards
function HS:PET_STABLE_SHOW()
	local stableName = UnitName("target")
	local continent, zone, x, y = Astrolabe:GetCurrentPlayerPosition()
	if not stableName or not continent then
		return
	end

	local coord = HandyNotes:getCoord(x, y)
	local map = HandyNotes:GetMapFile(continent, zone)
	if map then
		for coords, name in pairs(db.factionrealm.nodes[map]) do
			local cx, cy = HandyNotes:getXY(coords)
			local dist = Astrolabe:ComputeDistance(continent, zone, x, y, continent, zone, cx, cy)
			if dist <= thres then -- Node already exists here
				return
			end
		end
		db.factionrealm.nodes[map][coord] = stableName
		self:SendMessage("HandyNotes_NotifyUpdate", "Stables")
	end
end
