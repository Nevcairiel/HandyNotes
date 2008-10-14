---------------------------------------------------------
-- Module declaration
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local HN = HandyNotes:NewModule("HandyNotes", "AceEvent-3.0", "AceHook-3.0")
local Astrolabe = DongleStub("Astrolabe-0.4")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes", false)
local GameVersion = select(4, GetBuildInfo())

---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local dbdata
local defaults = {
	global = {
		["*"] = {},  -- ["mapFile"] = {[coord] = {note data}, [coord] = {note data}}
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


---------------------------------------------------------
-- Constants
local icons = {
	[1] = UnitPopupButtons.RAID_TARGET_1,
	[2] = UnitPopupButtons.RAID_TARGET_2,
	[3] = UnitPopupButtons.RAID_TARGET_3,
	[4] = UnitPopupButtons.RAID_TARGET_4,
	[5] = UnitPopupButtons.RAID_TARGET_5,
	[6] = UnitPopupButtons.RAID_TARGET_6,
	[7] = UnitPopupButtons.RAID_TARGET_7,
	[8] = UnitPopupButtons.RAID_TARGET_8,
}
HN.icons = icons


---------------------------------------------------------
-- Plugin Handlers to HandyNotes

local HNHandler = {}

function HNHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if ( self:GetCenter() > UIParent:GetCenter() ) then -- compare X coordinate
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	tooltip:SetText(dbdata[mapFile][coord].title)
	tooltip:AddLine(dbdata[mapFile][coord].desc)
	tooltip:Show()
end

function HNHandler:OnLeave(mapFile, coord)
	if self:GetParent() == WorldMapButton then
		WorldMapTooltip:Hide()
	else
		GameTooltip:Hide()
	end
end

local function deletePin(button, mapFile, coord)
	if GameVersion < 30000 then
		coord = mapFile
		mapFile = button
	end
	local HNEditFrame = HN.HNEditFrame
	if HNEditFrame.coord == coord and HNEditFrame.mapFile == mapFile then
		HNEditFrame:Hide()
	end
	dbdata[mapFile][coord] = nil
	HN:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes")
end

local function editPin(button, mapFile, coord)
	if GameVersion < 30000 then
		coord = mapFile
		mapFile = button
	end
	local HNEditFrame = HN.HNEditFrame
	HNEditFrame.x, HNEditFrame.y = HandyNotes:getXY(coord)
	HNEditFrame.coord = coord
	HNEditFrame.mapFile = mapFile 
	HNEditFrame:Hide() -- Hide first to trigger the OnShow handler
	HNEditFrame:Show()
end

local function addCartWaypoint(button, mapFile, coord)
	if GameVersion < 30000 then
		coord = mapFile
		mapFile = button
	end
	if Cartographer and Cartographer:HasModule("Waypoints") and Cartographer:IsModuleActive("Waypoints") then
		local x, y = HandyNotes:getXY(coord)
		local cartCoordID = floor(x*10000 + 0.5) + floor(y*10000 + 0.5)*10001
		local BZR = LibStub("LibBabble-Zone-3.0"):GetReverseLookupTable()
		local zone = HandyNotes:GetCZToZone(HandyNotes:GetCZ(mapFile))
		if zone then
			Cartographer_Waypoints:AddRoutesWaypoint(BZR[zone], cartCoordID, dbdata[mapFile][coord].title)
		end
	end
end

local function addTomTomWaypoint(button, mapFile, coord)
	if GameVersion < 30000 then
		coord = mapFile
		mapFile = button
	end
	if TomTom then
		local c, z = HandyNotes:GetCZ(mapFile)
		local x, y = HandyNotes:getXY(coord)
		TomTom:AddZWaypoint(c, z, x*100, y*100, dbdata[mapFile][coord].title, nil, true, true)
	end
end

do
	local isMoving = false
	local info = {}
	local clickedMapFile = nil
	local clickedZone = nil
	local function generateMenu(button, level)
		if GameVersion < 30000 then
			level = button
		end
		if (not level) then return end
		for k in pairs(info) do info[k] = nil end
		if (level == 1) then
			-- Create the title of the menu
			info.isTitle      = 1
			info.text         = L["HandyNotes"]
			info.notCheckable = 1
			local t = icons[dbdata[clickedMapFile][clickedCoord].icon]
			info.icon         = t.icon
			info.tCoordLeft   = t.tCoordLeft
			info.tCoordRight  = t.tCoordRight
			info.tCoordTop    = t.tCoordTop
			info.tCoordBottom = t.tCoordBottom
			UIDropDownMenu_AddButton(info, level)

			-- Edit menu item
			info.disabled     = nil
			info.isTitle      = nil
			info.notCheckable = nil
			info.icon         = nil
			info.tCoordLeft   = nil
			info.tCoordRight  = nil
			info.tCoordTop    = nil
			info.tCoordBottom = nil
			info.text = L["Edit Handy Note"]
			info.icon = icon
			info.func = editPin
			info.arg1 = clickedMapFile
			info.arg2 = clickedCoord
			UIDropDownMenu_AddButton(info, level)

			-- Delete menu item
			info.text = L["Delete Handy Note"]
			info.icon = icon
			info.func = deletePin
			info.arg1 = clickedMapFile
			info.arg2 = clickedCoord
			UIDropDownMenu_AddButton(info, level)

			-- Cartographer_Waypoints menu item
			if Cartographer and Cartographer:HasModule("Waypoints") and Cartographer:IsModuleActive("Waypoints") then
				if HandyNotes:GetCZToZone(HandyNotes:GetCZ(clickedMapFile)) then -- Only if this is in a mapzone
					info.text = L["Add this location to Cartographer_Waypoints"]
					info.icon = nil
					info.func = addCartWaypoint
					info.arg1 = clickedMapFile
					info.arg2 = clickedCoord
					UIDropDownMenu_AddButton(info, level)
				end
			end

			if TomTom then
				info.text = L["Add this location to TomTom waypoints"]
				info.icon = nil
				info.func = addTomTomWaypoint
				info.arg1 = clickedMapFile
				info.arg2 = clickedCoord
				UIDropDownMenu_AddButton(info, level)
			end

			-- Close menu item
			info.text         = CLOSE
			info.icon         = nil
			info.func         = CloseDropDownMenus
			info.arg1         = nil
			info.arg2         = nil
			info.notCheckable = 1
			UIDropDownMenu_AddButton(info, level)

			-- Add the dragging hint
			info.isTitle      = 1
			info.func         = nil
			info.text         = L["|cFF00FF00Hint: |cffeda55fCtrl+Shift+LeftDrag|cFF00FF00 to move a note"]
			UIDropDownMenu_AddButton(info, level)
		end
	end
	local HandyNotes_HandyNotesDropdownMenu = CreateFrame("Frame", "HandyNotes_HandyNotesDropdownMenu")
	HandyNotes_HandyNotesDropdownMenu.displayMode = "MENU"
	HandyNotes_HandyNotesDropdownMenu.initialize = generateMenu

	function HNHandler:OnClick(button, down, mapFile, coord)
		if button == "RightButton" and not down then
			clickedMapFile = mapFile
			clickedCoord = coord
			ToggleDropDownMenu(1, nil, HandyNotes_HandyNotesDropdownMenu, self, 0, 0)
		elseif button == "LeftButton" and down and IsControlKeyDown() and IsShiftKeyDown() then
			-- Only move if we're viewing the same map as the icon's map
			if mapFile == GetMapInfo() or mapFile == "World" or mapFile == "Cosmic" then
				isMoving = true
				self:StartMoving()
			end
		elseif isMoving and not down then
			isMoving = false
			self:StopMovingOrSizing()
			-- Get the new coordinate
			local x, y = self:GetCenter()
			x = (x - WorldMapButton:GetLeft()) / WorldMapButton:GetWidth()
			y = (WorldMapButton:GetTop() - y) / WorldMapButton:GetHeight()
			-- Move the button back into the map if it was dragged outside
			if x < 0.001 then x = 0.001 end
			if x > 0.999 then x = 0.999 end
			if y < 0.001 then y = 0.001 end
			if y > 0.999 then y = 0.999 end
			local newCoord = HandyNotes:getCoord(x, y)
			-- Search in 4 directions till we find an unused coord
			local count = 0
			local zoneData = dbdata[mapFile]
			while true do
				if not zoneData[newCoord + count] then
					zoneData[newCoord + count] = zoneData[coord]
					break
				elseif not zoneData[newCoord - count] then
					zoneData[newCoord - count] = zoneData[coord]
					break
				elseif not zoneData[newCoord + count * 10000] then
					zoneData[newCoord + count*10000] = zoneData[coord]
					break
				elseif not zoneData[newCoord - count * 10000] then
					zoneData[newCoord - count*10000] = zoneData[coord]
					break
				end
				count = count + 1
			end
			dbdata[mapFile][coord] = nil
			HN:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes")
		end
	end
end

do
	local emptyTbl = {}
	local tablepool = setmetatable({}, {__mode = 'k'})
	local continentMapFile = {
		["Kalimdor"]    = {[0] = "Kalimdor",    __index = Astrolabe.ContinentList[1]},
		["Azeroth"]     = {[0] = "Azeroth",     __index = Astrolabe.ContinentList[2]},
		["Expansion01"] = {[0] = "Expansion01", __index = Astrolabe.ContinentList[3]},
	}
	for k, v in pairs(continentMapFile) do
		setmetatable(v, v)
	end

	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return end
		local state, value = next(t, prestate)
		if value then
			return state, nil, icons[value.icon], db.icon_scale, db.icon_alpha
		end
	end

	-- This is a funky custom iterator we use to iterate over every zone's nodes
	-- in a given continent + the continent itself
	local function iterCont(t, prestate)
		if not t then return end
		local zone = t.Z
		local mapFile = t.C[zone]
		local data = dbdata[mapFile]
		local state, value
		while mapFile do
			if data then -- Only if there is data for this zone
				state, value = next(data, prestate)
				while state do -- Have we reached the end of this zone?
					if value.cont or zone == 0 then -- Show on continent?
						return state, mapFile, icons[value.icon], db.icon_scale, db.icon_alpha
					end
					state, value = next(data, state) -- Get next data
				end
			end
			-- Get next zone
			zone = zone + 1
			t.Z = zone
			mapFile = t.C[zone]
			data = dbdata[mapFile]
			prestate = nil
		end
		tablepool[t] = true
	end

	function HNHandler:GetNodes(mapFile)
		local C = continentMapFile[mapFile] -- Is this a continent?
		if C then
			local tbl = next(tablepool) or {}
			tablepool[tbl] = nil
			tbl.C = C
			tbl.Z = 0
			return iterCont, tbl, nil
		else -- It is a zone
			return iter, dbdata[mapFile], nil
		end
	end
end


---------------------------------------------------------
-- HandyNotes core

-- Hooked function on clicking the world map
function HN:WorldMapButton_OnClick(mouseButton, button, ...)
	if GameVersion >= 30000 then
		mouseButton, button = button, mouseButton
	end
	if mouseButton == "RightButton" and IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown() then
		local C, Z = GetCurrentMapContinent(), GetCurrentMapZone()
		local mapFile = GetMapInfo() or HandyNotes:GetMapFile(C, Z) -- Fallback for "Cosmic" and "World"

		-- Get the coordinate clicked on
		button = button or this
		local x, y = GetCursorPosition()
		local scale = button:GetEffectiveScale()
		x = (x/scale - button:GetLeft()) / button:GetWidth()
		y = (button:GetTop() - y/scale) / button:GetHeight()
		local coord = HandyNotes:getCoord(x, y)
		x, y = HandyNotes:getXY(coord)

		-- Pass the data to the edit note frame
		local HNEditFrame = self.HNEditFrame
		HNEditFrame.x = x
		HNEditFrame.y = y
		HNEditFrame.coord = coord
		HNEditFrame.mapFile = mapFile
		HNEditFrame:Hide() -- Hide first to trigger the OnShow handler
		HNEditFrame:Show()
	else
		if GameVersion >= 30000 then
			mouseButton, button = button, mouseButton
		end
		return self.hooks.WorldMapButton_OnClick(mouseButton, button, ...)
	end
end

---------------------------------------------------------
-- Options table
local options = {
	type = "group",
	name = L["HandyNotes"],
	desc = L["HandyNotes"],
	get = function(info) return db[info.arg] end,
	set = function(info, v)
		db[info.arg] = v
		HN:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes")
	end,
	args = {
		desc = {
			name = L["These settings control the look and feel of the HandyNotes icons."],
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

function HN:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_HandyNotesDB", defaults)
	db = self.db.profile
	dbdata = self.db.global

	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("HandyNotes", HNHandler, options)

	WorldMapMagnifyingGlassButton:SetText(WorldMapMagnifyingGlassButton:GetText() .. L["\nAlt+Right Click To Add a HandyNote"])
end

function HN:OnEnable()
	self:RawHook("WorldMapButton_OnClick", true)
end

function HN:OnDisable()
end

