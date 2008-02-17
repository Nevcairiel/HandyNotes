---------------------------------------------------------
-- Module declaration
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local HN = HandyNotes:NewModule("HandyNotes", "AceEvent-3.0", "AceHook-3.0")
local Astrolabe = DongleStub("Astrolabe-0.4")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes", false)


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
	if ( self:GetCenter() > self:GetParent():GetCenter() ) then -- compare X coordinate
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	WorldMapTooltip:SetText(dbdata[mapFile][coord].title)
	WorldMapTooltip:AddLine(dbdata[mapFile][coord].desc)
	WorldMapTooltip:Show()
end

function HNHandler:OnLeave(mapFile, coord)
	WorldMapTooltip:Hide()
end

local function deletePin(mapFile, coord)
	local HNEditFrame = HN.HNEditFrame
	if HNEditFrame.coord == coord and HNEditFrame.mapFile == mapFile then
		HNEditFrame:Hide()
	end
	dbdata[mapFile][coord] = nil
	HN:SendMessage("HandyNotes_NotifyUpdate", "HandyNotes")
end

local function editPin(mapFile, coord)
	local HNEditFrame = HN.HNEditFrame
	HNEditFrame.x, HNEditFrame.y = HandyNotes:getXY(coord)
	HNEditFrame.coord = coord
	HNEditFrame.mapFile = mapFile 
	HNEditFrame:Hide() -- Hide first to trigger the OnShow handler
	HNEditFrame:Show()
end

do
	local isMoving = false
	local info = {}
	local clickedMapFile = nil
	local clickedZone = nil
	local function generateMenu(level)
		if (not level) then return end
		for k in pairs(info) do info[k] = nil end
		if (level == 1) then
			-- Create the title of the menu
			info.isTitle      = 1
			info.text         = "HandyNotes"
			info.notCheckable = 1
			UIDropDownMenu_AddButton(info, level)

			-- Edit menu item
			info.disabled     = nil
			info.isTitle      = nil
			info.notCheckable = nil
			info.text = "Edit Handy Note"
			info.icon = icon
			info.func = editPin
			info.arg1 = clickedMapFile
			info.arg2 = clickedCoord
			UIDropDownMenu_AddButton(info, level)

			-- Delete menu item
			info.text = "Delete Handy Note"
			info.icon = icon
			info.func = deletePin
			info.arg1 = clickedMapFile
			info.arg2 = clickedCoord
			UIDropDownMenu_AddButton(info, level)

			-- Close menu item
			info.text         = "Close"
			info.icon         = nil
			info.func         = CloseDropDownMenus
			info.arg1         = nil
			info.notCheckable = 1
			UIDropDownMenu_AddButton(info, level)

			-- Add the dragging hint
			info.isTitle      = 1
			info.text         = "|cFF00FF00Hint: |cffeda55fCtrl+Shift+LeftDrag|cFF00FF00 to move a note"
			info.notCheckable = 1
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
			if mapFile == GetMapInfo() then
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
		["Kalimdor"] = 1,
		["Azeroth"] = 2,
		["Expansion01"] = 3,
	}

	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		local state, value = next(t, prestate)
		if value then
			return state, nil, icons[value.icon], db.icon_scale, db.icon_alpha
		end
	end

	-- This is a funky custom iterator we use to iterate over every zone's nodes
	-- in a given continent + the continent itself
	local function iterCont(t, prestate)
		if not t then return nil end
		local zone = t.Z
		local mapFile
		if type(zone) == "string" then -- Handle continent case
			mapFile = zone
			t.Z = 0
			zone = 0
		else
			mapFile = t.C[zone]
		end
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
			t.Z = t.Z + 1
			zone = zone + 1
			mapFile = t.C[zone]
			data = dbdata[mapFile]
			prestate = nil
		end
		tablepool[t] = true
		return nil, nil, nil, nil, nil
	end

	function HNHandler:GetNodes(mapFile)
		local C = continentMapFile[mapFile] -- Is this a continent?
		if C then
			local tbl = next(tablepool) or {}
			tablepool[tbl] = nil

			tbl.C = Astrolabe.ContinentList[C]
			tbl.Z = mapFile
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
	if mouseButton == "RightButton" and IsControlKeyDown() and not IsAltKeyDown() and not IsShiftKeyDown() then
		local mapFile = GetMapInfo()
		if not mapFile then return end

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
			name = "These settings control the look and feel of the HandyNotes icons.",
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

function HN:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_HandyNotesDB", defaults)
	db = self.db.profile
	dbdata = self.db.global

	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("HandyNotes", HNHandler, options)
end

function HN:OnEnable()
	self:RawHook("WorldMapButton_OnClick", true)
end

function HN:OnDisable()
end

