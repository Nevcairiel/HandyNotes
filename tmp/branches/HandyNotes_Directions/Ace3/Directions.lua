---------------------------------------------------------
-- Addon declaration
HandyNotes_Directions = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_Directions","AceEvent-3.0","AceHook-3.0")
local HD = HandyNotes_Directions
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local Astrolabe = DongleStub("Astrolabe-0.4")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_Directions", true)


---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local defaults = {
	global = {
		landmarks = {
			["*"] = {},  -- [mapFile] = {[coord] = "name", [coord] = "name"}
		},
	},
	profile = {
		icon_scale         = 1.0,
		icon_alpha         = 1.0,
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

local function setupLandmarkIcon(texture, left, right, top, bottom)
	return {
		icon = texture,
		tCoordLeft = left,
		tCoordRight = right,
		tCoordTop = top,
		tCoordBottom = bottom,
	}
end

local icon = setupLandmarkIcon([[Interface\Minimap\POIIcons]], WorldMap_GetPOITextureCoords(6)) -- the cute lil' flag

---------------------------------------------------------
-- Plugin Handlers to HandyNotes
local HDHandler = {}
local info = {}
local clickedLandmark = nil
local clickedLandmarkZone = nil
local lastGossip = nil

function HDHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if ( self:GetCenter() > UIParent:GetCenter() ) then -- compare X coordinate
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	tooltip:SetText(HD.db.global.landmarks[mapFile][coord])
	tooltip:Show()
	clickedLandmark = nil
	clickedLandmarkZone = nil
end

local function deletePin(mapFile,coord)
	HD.db.global.landmarks[mapFile][coord] = nil
	HD:SendMessage("HandyNotes_NotifyUpdate", "Directions")
end

local zonenames = {}
local function populateZoneNames(...)
	for ci=1,select('#', ...) do
		zonenames[ci] = {GetMapZones(ci)}
	end
end
populateZoneNames(GetMapContinents())
local function createWaypoint(mapFile,coord)
	ChatFrame1:AddMessage(mapFile..", "..coord)
	local c, z = HandyNotes:GetCZ(mapFile)
	local x, y = HandyNotes:getXY(coord)
	local name = HD.db.global.landmarks[mapFile][coord]
	if TomTom then
		TomTom:AddZWaypoint(c, z, x*100, y*100, name)
	elseif Cartographer_Waypoints then
		local zone = zonenames[c][z]
		Cartographer_Waypoints:AddWaypoint(NotePoint:new(zone, x, y, name))
	end
end

local function generateMenu(level)
	if (not level) then return end
	for k in pairs(info) do info[k] = nil end
	if (level == 1) then
		-- Create the title of the menu
		info.isTitle      = 1
		info.text         = "HandyNotes - Directions"
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level)

		if TomTom or Cartographer_Waypoints then
			-- Waypoint menu item
			info.disabled     = nil
			info.isTitle      = nil
			info.notCheckable = nil
			info.text = "Create waypoint"
			info.icon = nil
			info.func = createWaypoint
			info.arg1 = clickedLandmarkZone
			info.arg2 = clickedLandmark
			UIDropDownMenu_AddButton(info, level);
		end

		-- Delete menu item
		info.disabled     = nil
		info.isTitle      = nil
		info.notCheckable = nil
		info.text = "Delete landmark"
		info.icon = icon
		info.func = deletePin
		info.arg1 = clickedLandmarkZone
		info.arg2 = clickedLandmark
		UIDropDownMenu_AddButton(info, level);

		-- Close menu item
		info.text         = "Close"
		info.icon         = nil
		info.func         = CloseDropDownMenus
		info.arg1         = nil
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level);
	end
end
local HD_Dropdown = CreateFrame("Frame", "HandyNotes_DirectionsDropdownMenu")
HD_Dropdown.displayMode = "MENU"
HD_Dropdown.initialize = generateMenu

function HDHandler:OnClick(button, down, mapFile, coord)
	if button == "RightButton" and not down then
		clickedLandmarkZone = mapFile
		clickedLandmark = coord
		ToggleDropDownMenu(1, nil, HD_Dropdown, self, 0, 0)
	end
end

function HDHandler:OnLeave(mapFile, coord)
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
		while state do -- Have we reached the end of this zone?
			if value then
				return state, nil, icon, db.icon_scale, db.icon_alpha
			end
			state, value = next(t, state) -- Get next data
		end
		return nil, nil, nil, nil
	end
	function HDHandler:GetNodes(mapFile)
		return iter, HD.db.global.landmarks[mapFile], nil
	end
end


---------------------------------------------------------
-- Core functions

local alreadyAdded = {}
function HD:CheckForLandmarks()
	if not lastGossip then return end
	for mark = 1, GetNumMapLandmarks(), 1 do
		local name, _, tex, x, y = GetMapLandmarkInfo(mark)
		if tex == 6 and not alreadyAdded[name] then
			alreadyAdded[name] = true
			self:AddLandmark(x, y, lastGossip)
		end
	end
end

function HD:AddLandmark(x, y, name)
	local c,z = Astrolabe:GetCurrentPlayerPosition()
	if not c then return end
	local loc = HandyNotes:getCoord(x, y)
	local mapFile = HandyNotes:GetMapFile(c, z)
	if not mapFile then return end
	for coord,value in pairs(self.db.global.landmarks[mapFile]) do
		if value and value:match("^"..name) then
			return
		end
	end
	self.db.global.landmarks[mapFile][loc] = name
	self:SendMessage("HandyNotes_NotifyUpdate", "Directions")
end

local replacements = {
	[L["A profession trainer"]] = L["Trainer: "],
	[L["A class trainer"]] = L["Class: "],
}
function HD:SelectGossipOption(index)
	local selected = select((index * 2) - 1, GetGossipOptions())
	if replacements[selected] then selected = replacements[selected] end
	if lastGossip then
		lastGossip = lastGossip .. selected
	else
		lastGossip = selected
	end
end

function HD:GOSSIP_CLOSED()
	lastGossip = nil
end

---------------------------------------------------------
-- Options table
local options = {
	type = "group",
	name = "Directions",
	desc = "Directions",
	get = function(info) return db[info.arg] end,
	set = function(info, v)
		db[info.arg] = v
		HD:SendMessage("HandyNotes_NotifyUpdate", "Directions")
	end,
	args = {
		desc = {
			name = "These settings control the look and feel of the icon. Note that HandyNotes_Directions does not come with any precompiled data, when you ask a guard for directions, it will automatically add the data into your database.",
			type = "description",
			order = 0,
		},
		icon_scale = {
			type = "range",
			name = "Icon Scale",
			desc = "The scale of the icons",
			min = 0.25, max = 2, step = 0.01,
			arg = "icon_scale",
			order = 10,
		},
		icon_alpha = {
			type = "range",
			name = "Icon Alpha",
			desc = "The alpha transparency of the icons",
			min = 0, max = 1, step = 0.01,
			arg = "icon_alpha",
			order = 20,
		},
	},
}


---------------------------------------------------------
-- Addon initialization, enabling and disabling

function HD:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_DirectionsDB", defaults)
	db = self.db.profile
	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("Directions", HDHandler, options)
end

function HD:OnEnable()
	self:RegisterEvent("WORLD_MAP_UPDATE", "CheckForLandmarks")
	self:RegisterEvent("GOSSIP_CLOSED")
	self:Hook("SelectGossipOption", true)
end

