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


---------------------------------------------------------
-- Plugin Handlers to HandyNotes

local HNHandler = {}

function HNHandler:OnEnter(mapFile, coord)
	if ( self:GetCenter() > self:GetParent():GetCenter() ) then -- compare X coordinate
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	--WorldMapTooltip:SetText(HFM_DataType[ HFM_Data[mapFile][coord] ])
	WorldMapTooltip:Show()
end

function HNHandler:OnLeave(mapFile, coord)
	WorldMapTooltip:Hide()
end

do
	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		local state, value = next(t, prestate)
		if value then
			return state, icons[value.icon], db.icon_scale, db.icon_alpha
		end
	end
	function HNHandler:GetNodes(mapFile)
		return iter, dbdata[mapFile], nil
	end
end

--[[do
	-- This is a funky custom iterator we use to iterate over every zone's nodes in a given continent
	local emptyTbl = {}
	local tablepool = setmetatable({}, {__mode = 'k'})
	local continentMapFile = {
		["Kalimdor"] = 1,
		["Azeroth"] = 2,
		["Expansion01"] = 3,
	}
	local function iter(t, prestate)
		if not t then return nil end
		local zone = t.Z
		local mapFile = t.C[zone]
		local data = HFM_Data[mapFile]
		local state, value
		while mapFile do
			if data then -- Only if there is data for this zone
				state, value = next(data, prestate)
				while state do -- Have we reached the end of this zone?
					if value == playerFaction then
						-- Same faction flightpoint
						return state, zone, icons[1], db.icon_scale, db.icon_alpha
					elseif db.show_both_factions and value + playerFaction == 3 then
						-- Enemy faction flightpoint
						return state, zone, icons[2], db.icon_scale, db.icon_alpha
					elseif value >= 3 then
						-- Both factions flightpoint
						return state, zone, icons[3], db.icon_scale, db.icon_alpha
					end
					state, value = next(data, state) -- Get next data
				end
			end
			-- Get next zone
			t.Z = t.Z + 1
			zone = zone + 1
			mapFile = t.C[zone]
			data = HFM_Data[mapFile]
			prestate = nil
		end
		tablepool[t] = true
		return nil, nil, nil, nil, nil
	end
	function HNHandler:GetNodesForContinent(mapFile)
		if db.show_on_continent then -- Show on continent maps, so we iterate
			local tbl = next(tablepool) or {}
			tablepool[tbl] = nil

			tbl.C = Astrolabe.ContinentList[ continentMapFile[mapFile] ]
			tbl.Z = 1
			return iter, tbl, nil
		else -- Don't show, so we return the simplest null iterator
			return next, emptyTbl, nil
		end
	end
end]]


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
end

function HN:OnDisable()
end

