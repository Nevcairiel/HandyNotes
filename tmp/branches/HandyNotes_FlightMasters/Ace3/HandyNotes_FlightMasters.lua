---------------------------------------------------------
-- Addon declaration
HandyNotes_FlightMasters = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_FlightMasters","AceEvent-3.0")
local HFM = HandyNotes_FlightMasters
local Astrolabe = DongleStub("Astrolabe-0.4")
--local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_FlightMasters", false)


---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local defaults = {
	profile = {
		icon_scale         = 1.0,
		icon_alpha         = 1.0,
		show_both_factions = true,
		show_on_continent  = true,
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
	"Interface\\TaxiFrame\\UI-Taxi-Icon-Green",  -- Your faction  [1]
	"Interface\\TaxiFrame\\UI-Taxi-Icon-Red",    -- Enemy faction [2]
	"Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow", -- Both factions [3]
}

local HFM_DataType = {
	[1] = "Alliance FlightMaster",
	[2] = "Horde FlightMaster",
	[3] = "Neutral FlightMaster",
	[4] = "Druid FlightMaster",
	[5] = "PvP FlightMaster",
	[6] = "Aldor FlightMaster",
	[7] = "Scryer FlightMaster",
}

local HFM_Data = {
	["LochModan"] = {[33905080] = 1,},
	["BurningSteppes"] = {[65602410] = 2, [84406830] = 1,},
	["Moonglade"] = {[44004500] = 4, [32206630] = 2, [48006730] = 1,},
	["Barrens"] = {[44005900] = 2, [51503040] = 2, [63003700] = 1,},
	["Winterspring"] = {[60503630] = 2, [62303660] = 1,},
	["Hinterlands"] = {[81708180] = 2, [11104610] = 1,},
	["Westfall"] = {[56605270] = 1,},
	["Badlands"] = {[4104490] = 2,},
	["Darkshore"] = {[36404560] = 1,},
	["Undercity"] = {[63404850] = 2,},
	["Desolace"] = {[21607400] = 2, [64701040] = 1,},
	["Tanaris"] = {[51602550] = 2, [51002930] = 1,},
	["BladesEdgeMountains"] = {[61703960] = 2, [37796138] = 1, [76406590] = 2, [61137039] = 1, [61633961] = 1, [52105420] = 2,},
	["Silithus"] = {[48703670] = 2, [50603440] = 1,},
	["SwampOfSorrows"] = {[46105470] = 2,},
	["StonetalonMountains"] = {[45105990] = 2, [36500720] = 1,},
	["ShadowmoonValley"] = {[63333040] = 6, [30302920] = 2, [37635552] = 1, [56315782] = 7,},
	["Ogrimmar"] = {[45306400] = 2,},
	["SearingGorge"] = {[34803080] = 2, [37903070] = 1,},
	["WesternPlaguelands"] = {[42908490] = 1,},
	["Hilsbrad"] = {[60201870] = 2, [49405220] = 1,},
	["BlastedLands"] = {[65502440] = 1,},
	["EasternPlaguelands"] = {[22003200] = 5, [80205710] = 2, [81605930] = 1,},
	["ThousandNeedles"] = {[45104920] = 2,},
	["Duskwood"] = {[77504430] = 1,},
	["Ashenvale"] = {[34404800] = 1, [73206152] = 2, [12203380] = 2, [85094345] = 1,},
	["Ghostlands"] = {[45423052] = 2,},
	["TerokkarForest"] = {[49214346] = 2, [59475536] = 1,},
	["Redridge"] = {[30705930] = 1,},
	["Teldrassil"] = {[58409390] = 1,},
	["Ironforge"] = {[55704770] = 1,},
	["Felwood"] = {[51538222] = 1, [34405380] = 2, [62502420] = 1,},
	["Silverpine"] = {[45504250] = 2,},
	["Aszhara"] = {[22004970] = 2, [11907760] = 1,},
	["Stormwind"] = {[66406220] = 1,},
	["BloodmystIsle"] = {[57695387] = 1,},
	["Arathi"] = {[73103260] = 2, [45804610] = 1,},
	["ThunderBluff"] = {[46905000] = 2,},
	["Wetlands"] = {[9505970] = 1,},
	["Hellfire"] = {[56303630] = 2, [61608120] = 2, [78263442] = 1, [87425240] = 1, [78473499] = 1, [87374822] = 2, [54636245] = 1, [71386255] = 1, [68722823] = 1, [25133722] = 1, [27866003] = 2,},
	["Netherstorm"] = {[65106670] = 2, [45293485] = 1, [45303490] = 2, [33796403] = 1, [33806400] = 2, [65256679] = 1,},
	["TheExodar"] = {[68456371] = 1,},
	["ShattrathCity"] = {[64044097] = 1,},
	["UngoroCrater"] = {[45000600] = 3,},
	["Zangarmarsh"] = {[41232895] = 1, [84745502] = 2, [33015110] = 2, [67865140] = 1,},
	["Feralas"] = {[30004300] = 1, [75404430] = 2, [89504590] = 1,},
	["EversongWoods"] = {[54355073] = 2,},
	["Dustwallow"] = {[35603180] = 2, [67505120] = 1,},
	["Stranglethorn"] = {[32502930] = 2, [26867709] = 2, [27507780] = 1,},
	["Nagrand"] = {[57203530] = 2, [54187511] = 1,},
}

---------------------------------------------------------
-- Plugin Handlers to HandyNotes

local playerFaction = UnitFactionGroup("player") == "Alliance" and 1 or 2
local HFMHandler = {}

function HFMHandler:OnEnter(mapFile, coord)
	if ( self:GetCenter() > self:GetParent():GetCenter() ) then -- compare X coordinate
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	WorldMapTooltip:SetText(HFM_DataType[ HFM_Data[mapFile][coord] ])
	WorldMapTooltip:Show()
end

function HFMHandler:OnLeave(mapFile, coord)
	WorldMapTooltip:Hide()
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
		while state do -- Have we reached the end of this zone?
			if value == playerFaction then
				-- Same faction flightpoint
				return state, nil, icons[1], db.icon_scale, db.icon_alpha
			elseif db.show_both_factions and value + playerFaction == 3 then
				-- Enemy faction flightpoint
				return state, nil, icons[2], db.icon_scale, db.icon_alpha
			elseif value >= 3 then
				-- Both factions flightpoint
				return state, nil, icons[3], db.icon_scale, db.icon_alpha
			end
			state, value = next(t, state) -- Get next data
		end
		return nil, nil, nil, nil
	end

	-- This is a funky custom iterator we use to iterate over every zone's nodes in a given continent
	local function iterCont(t, prestate)
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
						return state, mapFile, icons[1], db.icon_scale, db.icon_alpha
					elseif db.show_both_factions and value + playerFaction == 3 then
						-- Enemy faction flightpoint
						return state, mapFile, icons[2], db.icon_scale, db.icon_alpha
					elseif value >= 3 then
						-- Both factions flightpoint
						return state, mapFile, icons[3], db.icon_scale, db.icon_alpha
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

	function HFMHandler:GetNodes(mapFile)
		local C = continentMapFile[mapFile] -- Is this a continent?
		if C then
			if db.show_on_continent then -- Show on continent maps, so we iterate
				local tbl = next(tablepool) or {}
				tablepool[tbl] = nil

				tbl.C = Astrolabe.ContinentList[C]
				tbl.Z = 1
				return iterCont, tbl, nil
			else -- Don't show, so we return the simplest null iterator
				return next, emptyTbl, nil
			end
		else -- It is a zone
			return iter, HFM_Data[mapFile], nil
		end
	end
end


---------------------------------------------------------
-- Options table
local options = {
	type = "group",
	name = "FlightMasters",
	desc = "FlightMasters",
	get = function(info) return db[info.arg] end,
	set = function(info, v)
		db[info.arg] = v
		HFM:SendMessage("HandyNotes_NotifyUpdate", "FlightMasters")
	end,
	args = {
		desc = {
			name = "These settings control the look and feel of the FlightMaster icons.",
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
		show_both_factions = {
			type = "toggle",
			name = "Show both factions",
			desc = "Show all flightmasters instead of only those that you can use",
			arg = "show_both_factions",
			order = 30,
		},
		show_on_continent = {
			type = "toggle",
			name = "Show on continent maps",
			desc = "Show flightmasters on continent level maps as well",
			arg = "show_on_continent",
			order = 40,
		},
	},
}


---------------------------------------------------------
-- Addon initialization, enabling and disabling

function HFM:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_FlightMastersDB", defaults)
	db = self.db.profile

	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("FlightMasters", HFMHandler, options)
end

function HFM:OnEnable()
end

function HFM:OnDisable()
end

