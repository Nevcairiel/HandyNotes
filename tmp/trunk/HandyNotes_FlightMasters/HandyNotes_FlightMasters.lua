---------------------------------------------------------
-- Addon declaration
HandyNotes_FlightMasters = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_FlightMasters", "AceEvent-3.0")
local HFM = HandyNotes_FlightMasters
local Astrolabe = DongleStub("Astrolabe-0.4-NC")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_FlightMasters", false)
local G = {}


---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local defaults = {
	profile = {
		icon_scale         = 1.0,
		icon_alpha         = 1.0,
		show_both_factions = true,
		show_on_continent  = true,
		show_lines         = true,
		show_lines_zone    = true,
	},
}


---------------------------------------------------------
-- Localize some globals
local next = next
local GameTooltip = GameTooltip
local WorldMapTooltip = WorldMapTooltip


---------------------------------------------------------
-- Constants

local playerFaction = UnitFactionGroup("player") == "Alliance" and 1 or 2

local icons = {
	"Interface\\TaxiFrame\\UI-Taxi-Icon-Green",  -- Your faction  [1] Green
	"Interface\\TaxiFrame\\UI-Taxi-Icon-Red",    -- Enemy faction [2] Red
	"Interface\\TaxiFrame\\UI-Taxi-Icon-Yellow", -- Both factions [3] Orange
}

local colors = {
	{0, 1, 0, 1},     -- Your faction       [1] Green
	{1, 0, 0, 1},     -- Enemy faction      [2] Red
	{1, 0.5, 0, 1},   -- Both factions      [3] Orange
	{1, 1, 0, 1},     -- Special, Alliance  [4] Yellow
}
colors[5] = colors[4] -- Special, Horde     [5] Yellow
colors[6] = colors[5] -- Special, Neutral   [6] Yellow

local HFM_DataType = {
	[1] = L["Alliance FlightMaster"],
	[2] = L["Horde FlightMaster"],
	[3] = L["Neutral FlightMaster"],
	[4] = L["Druid FlightMaster"],
	[5] = L["PvP FlightMaster"],
	[6] = L["Aldor FlightMaster"],
	[7] = L["Scryer FlightMaster"],
	[8] = L["Skyguard FlightMaster"],
}

-- Packed data in strings, which we unpack on demand. Format as follows:
-- [mapFile] = {
--      [coord] = "type|mapFile,coord,type|mapFile,coord,type" -- Flight path links
--      [coord] = "type|mapFile,coord,type|mapFile,coord,type"
-- }
local HFM_Data = {
	-- Eastern Kingdoms
	["Arathi"] = {
		[73103260] = "2|Undercity,63404850,2|Hilsbrad,60201870,2|Hinterlands,81708180,2|Badlands,4104490,2",
		[45804610] = "1|Hinterlands,11104610,1|Hilsbrad,49405220,1|Wetlands,9505970,1|Ironforge,55704770,1|LochModan,33945096,1",},
	["Badlands"] = {[4104490] = "2|Undercity,63404850,2|Arathi,73103260,2|SearingGorge,34803080,2|BurningSteppes,65602410,2|SwampOfSorrows,46105470,2|Stranglethorn,32502930,2|Stranglethorn,26867709,2",},
	["BlastedLands"] = {[65502440] = "1|BurningSteppes,84406830,1|Stormwind,66406220,1|Duskwood,77504430,1",},
	["BurningSteppes"] = {
		[65602410] = "2|SearingGorge,34803080,2|Badlands,4104490,2|SwampOfSorrows,46105470,2",
		[84406830] = "1|SearingGorge,37903070,1|Stormwind,66406220,1|BlastedLands,65502440,1|Redridge,30705930,1",},
	["Duskwood"] = {[77504430] = "1|Stormwind,66406220,1|Redridge,30705930,1|BlastedLands,65502440,1|Stranglethorn,27507780,1|Stranglethorn,38230404,1|Westfall,56605270,1",},
	["EasternPlaguelands"] = {
		[22323146] = "5|EasternPlaguelands,66075039,6|EasternPlaguelands,54242676,6|EasternPlaguelands,38067525,6",
		[80225700] = "2|Ghostlands,45413053,2|Undercity,63404850,2|Hinterlands,81708180,2",
		[81605930] = "1|Ironforge,55704770,1|WesternPlaguelands,42908490,1|Hinterlands,11104610,1|Ghostlands,74766715,1|Sunwell,48452514,1",},
	["EversongWoods"] = {[54365071] = "2|Ghostlands,45413053,2|Sunwell,48452514,2",},
	["Ghostlands"] = {
		[45413053] = "2|EversongWoods,54365071,2|EasternPlaguelands,80225700,2|Ghostlands,74766715,2",
		[74766715] = "3|EasternPlaguelands,81605930,1|Ghostlands,45413053,2|Sunwell,48452514,3",},
	["Hilsbrad"] = {
		[60201870] = "2|Undercity,63404850,2|Hinterlands,81708180,2|Arathi,73103260,2|Silverpine,45504250,2",
		[49405220] = "1|WesternPlaguelands,42908490,1|Hinterlands,11104610,1|Arathi,45804610,1|Wetlands,9505970,1|Ironforge,55704770,1",},
	["Hinterlands"] = {
		[81708180] = "2|EasternPlaguelands,80225700,2|Undercity,63404850,2|Hilsbrad,60201870,2|Arathi,73103260,2",
		[11104610] = "1|WesternPlaguelands,42908490,1|EasternPlaguelands,81605930,1|Ironforge,55704770,1|Arathi,45804610,1|Hilsbrad,49405220,1",},
	["Ironforge"] = {[55704770] = "1|EasternPlaguelands,81605930,1|WesternPlaguelands,42908490,1|Hinterlands,11104610,1|Hilsbrad,49405220,1|Arathi,45804610,1|Wetlands,9505970,1|LochModan,33945096,1|SearingGorge,37903070,1|Stormwind,66406220,1|Sunwell,48452514,1",},
	["LochModan"] = {[33945096] = "1|Arathi,45804610,1|Wetlands,9505970,1|Ironforge,55704770,1|SearingGorge,37903070,1",},
	["Redridge"] = {[30705930] = "1|Stormwind,66406220,1|Westfall,56605270,1|Duskwood,77504430,1|BurningSteppes,84406830,1",},
	["SearingGorge"] = {
		[34803080] = "2|Badlands,4104490,2|BurningSteppes,65602410,2",
		[37903070] = "1|Ironforge,55704770,1|BurningSteppes,84406830,1|LochModan,33945096,1",},
	["Silverpine"] = {[45504250] = "2|Undercity,63404850,2|Hilsbrad,60201870,2",},
	["Stormwind"] = {[66406220] = "1|Ironforge,55704770,1|BurningSteppes,84406830,1|Redridge,30705930,1|BlastedLands,65502440,1|Stranglethorn,27507780,1|Stranglethorn,38230404,1|Westfall,56605270,1|Duskwood,77504430,1",},
	["Stranglethorn"] = {
		[32502930] = "2|Stranglethorn,26867709,2|Badlands,4104490,2|SwampOfSorrows,46105470,2",
		[26867709] = "2|Stranglethorn,32502930,2|Badlands,4104490,2|SwampOfSorrows,46105470,2",
		[27507780] = "1|Stormwind,66406220,1|Westfall,56605270,1|Duskwood,77504430,1|Stranglethorn,38230404,1",
		[38230404] = "1|Stormwind,66406220,1|Westfall,56605270,1|Duskwood,77504430,1|Stranglethorn,27507780,1",},
	["Sunwell"] = {
		[48452514] = "3|Ghostlands,74766715,3|EversongWoods,54365071,2|EasternPlaguelands,81605930,1",},
	["SwampOfSorrows"] = {[46105470] = "2|Badlands,4104490,2|BurningSteppes,65602410,2|Stranglethorn,32502930,2|Stranglethorn,26867709,2",},
	["Undercity"] = {[63404850] = "2|Hinterlands,81708180,2|Arathi,73103260,2|Silverpine,45504250,2|EasternPlaguelands,80225700,2|Hilsbrad,60201870,2|Badlands,4104490,2",},
	["WesternPlaguelands"] = {[42908490] = "1|Hinterlands,11104610,1|EasternPlaguelands,81605930,1|Ironforge,55704770,1|Hilsbrad,49405220,1",},
	["Westfall"] = {[56605270] = "1|Stormwind,66406220,1|Redridge,30705930,1|Duskwood,77504430,1|Stranglethorn,27507780,1|Stranglethorn,38230404,1",},
	["Wetlands"] = {[9505970] = "1|Arathi,45804610,1|Hilsbrad,49405220,1|LochModan,33945096,1|Ironforge,55704770,1",},
	-- Kalimdor
	["Ashenvale"] = {
		[34404800] = "1|Darkshore,36404560,1|Felwood,51538222,1|Ashenvale,85094345,1|Aszhara,11907760,1|Dustwallow,67505120,1|Barrens,63003700,1|StonetalonMountains,36500720,1",
		[73206152] = "2|Ashenvale,12203380,2|Felwood,51538222,2|Aszhara,22004970,2|Barrens,51503040,2|Ogrimmar,45306400,2",
		[12203380] = "2|Ashenvale,73206152,2|Felwood,51538222,2|Felwood,34405380,2|StonetalonMountains,45105990,2|Barrens,51503040,2",
		[85094345] = "1|Aszhara,11907760,1|Felwood,51538222,1|Ashenvale,34404800,1",},
	["Aszhara"] = {
		[22004970] = "2|Winterspring,60503630,2|Felwood,34405380,2|Ashenvale,73206152,2|ThunderBluff,46905000,2|Barrens,51503040,2|Ogrimmar,45306400,2",
		[11907760] = "1|Darkshore,36404560,1|Felwood,62502420,1|Winterspring,62303660,1|Dustwallow,67505120,1|Barrens,63003700,1|Ashenvale,34404800,1|Ashenvale,85094345,1",},
	["Barrens"] = {
		[44005900] = "2|Barrens,51503040,2|ThousandNeedles,45104920,2|ThunderBluff,46905000,2",
		[51503040] = "2|Barrens,44005900,2|StonetalonMountains,45105990,2|Ashenvale,73206152,2|Ashenvale,12203380,2|Felwood,34405380,2|Aszhara,22004970,2|Ogrimmar,45306400,2|Barrens,63003700,2|Dustwallow,35603180,2|Tanaris,51602550,2|ThousandNeedles,45104920,2|ThunderBluff,46905000,2|Feralas,75404430,2",
		[63003700] = "3|Aszhara,11907760,1|Ashenvale,34404800,1|Dustwallow,67505120,1|Tanaris,51002930,1|Barrens,51503040,2",},
	["BloodmystIsle"] = {
		[57685388] = "1|TheExodar,68446370,1",},
	["Darkshore"] = {
		[36404560] = "1|Teldrassil,58409390,1|Moonglade,48006730,1|Felwood,62502420,1|Aszhara,11907760,1|Dustwallow,67505120,1|Ashenvale,34404800,1|Desolace,64701040,1|StonetalonMountains,36500720,1|Feralas,30244324,1",},
	["Desolace"] = {
		[21607400] = "2|StonetalonMountains,45105990,2|ThunderBluff,46905000,2|Feralas,75404430,2",
		[64701040] = "1|StonetalonMountains,36500720,1|Feralas,30244324,1|Darkshore,36404560,1|Dustwallow,67505120,1",},
	["Dustwallow"] = {
		[35603180] = "2|ThunderBluff,46905000,2|Ogrimmar,45306400,2|Barrens,51503040,2|Tanaris,51602550,2",
		[67505120] = "1|Aszhara,11907760,1|Darkshore,36404560,1|Ashenvale,34404800,1|Barrens,63003700,1|Desolace,64701040,1|Feralas,89504590,1|Tanaris,51002930,1",},
	["Felwood"] = {
		[51538222] = "3|Felwood,62502420,1|Ashenvale,34404800,1|Ashenvale,85094345,1|Felwood,34405380,2|Ashenvale,12203380,2|Ashenvale,73206152,2",
		[34405380] = "2|Moonglade,32206630,2|Winterspring,60503630,2|Aszhara,22004970,2|Ogrimmar,45306400,2|Barrens,51503040,2|Ashenvale,12203380,2|Felwood,51538222,2",
		[62502420] = "1|Darkshore,36404560,1|Moonglade,48006730,1|Winterspring,62303660,1|Felwood,51538222,1|Aszhara,11907760,1",},
	["Feralas"] = {
		[30244324] = "1|Darkshore,36404560,1|Desolace,64701040,1|Feralas,89504590,1|Silithus,50603440,1",
		[75404430] = "2|Desolace,21607400,2|ThunderBluff,46905000,2|Barrens,51503040,2|Tanaris,51602550,2|ThousandNeedles,45104920,2|Silithus,48703670,2",
		[89504590] = "1|Dustwallow,67505120,1|Feralas,30244324,1|Tanaris,51002930,1",},
	["Moonglade"] = {
		[44004500] = "4|Teldrassil,58409390,4|ThunderBluff,46905000,5",
		[32206630] = "2|Felwood,34405380,2|Winterspring,60503630,2",
		[48006730] = "1|Darkshore,36404560,1|Felwood,62502420,1|Winterspring,62303660,1",},
	["Ogrimmar"] = {[45306400] = "2|Felwood,34405380,2|Winterspring,60503630,2|Aszhara,22004970,2|Ashenvale,73206152,2|ThunderBluff,46905000,2|Barrens,51503040,2|Dustwallow,35603180,2|Tanaris,51602550,2",},
	["Silithus"] = {
		[48703670] = "2|Feralas,75404430,2|UngoroCrater,45000600,2|Tanaris,51602550,2",
		[50603440] = "1|Feralas,30244324,1|UngoroCrater,45000600,1|Tanaris,51002930,1",},
	["StonetalonMountains"] = {
		[45105990] = "2|Ashenvale,12203380,2|Barrens,51503040,2|ThunderBluff,46905000,2|Desolace,21607400,2",
		[36500720] = "1|Darkshore,36404560,1|Ashenvale,34404800,1|Desolace,64701040,1",},
	["Tanaris"] = {
		[51602550] = "2|Silithus,48703670,2|UngoroCrater,45000600,2|Feralas,75404430,2|ThousandNeedles,45104920,2|ThunderBluff,46905000,2|Ogrimmar,45306400,2|Barrens,51503040,2|Dustwallow,35603180,2",
		[51002930] = "1|Silithus,50603440,1|UngoroCrater,45000600,1|Feralas,89504590,1|Dustwallow,67505120,1|Barrens,51503040,1",},
	["Teldrassil"] = {[58409390] = "1|Darkshore,36404560,1|Moonglade,44004500,4",},
	["TheExodar"] = {[68446370] = "1|BloodmystIsle,57685388,1",},
	["ThousandNeedles"] = {[45104920] = "2|Tanaris,51602550,2|Feralas,75404430,2|ThunderBluff,46905000,2|Barrens,51503040,2|Barrens,44005900,2",},
	["ThunderBluff"] = {[46905000] = "2|Desolace,21607400,2|StonetalonMountains,45105990,2|Aszhara,22004970,2|Ogrimmar,45306400,2|Barrens,51503040,2|Barrens,44005900,2|Dustwallow,35603180,2|Tanaris,51602550,2|ThousandNeedles,45104920,2|Feralas,75404430,2|Moonglade,44004500,5",},
	["UngoroCrater"] = {[45000600] = "3|Tanaris,51002930,1|Silithus,50603440,1|Silithus,48703670,2|Tanaris,51602550,2",},
	["Winterspring"] = {
		[60503630] = "2|Moonglade,32206630,2|Felwood,34405380,2|Aszhara,22004970,2|Ogrimmar,45306400,2",
		[62303660] = "1|Moonglade,48006730,1|Felwood,62502420,1|Aszhara,11907760,1",},
	-- Outlands
	["BladesEdgeMountains"] = {
		[37826140] = "1|Zangarmarsh,41292899,1|Zangarmarsh,67835146,1|BladesEdgeMountains,61157044,1|BladesEdgeMountains,61683962,1|Netherstorm,33746399,1|Netherstorm,45313487,1",
		[76376593] = "2|Zangarmarsh,84765511,2|BladesEdgeMountains,52055412,2|Netherstorm,33746399,2",
		[61157044] = "1|Zangarmarsh,67835146,1|BladesEdgeMountains,37826140,1|BladesEdgeMountains,61683962,1|Netherstorm,33746399,1",
		[61683962] = "3|BladesEdgeMountains,37826140,1|BladesEdgeMountains,61157044,1|Netherstorm,33746399,3|BladesEdgeMountains,52055412,2",
		[52055412] = "2|Zangarmarsh,84765511,2|Zangarmarsh,33075107,2|BladesEdgeMountains,76376593,2|BladesEdgeMountains,61683962,2|Netherstorm,45313487,2|Netherstorm,33746399,2",
		[28285210] = "8|TerokkarForest,63506582,6",},
	["Hellfire"] = {
		[56293624] = "2|Hellfire,87354813,2|Hellfire,61668119,2|Hellfire,27795997,2|TerokkarForest,49194342,2",
		[61668119] = "2|Hellfire,56293624,2",
		[78263445] = "1|Hellfire,68662823,1",
		[87365241] = "1|Hellfire,54686235,1|Hellfire,78413490,1|Hellfire,25193723,1",
		[78413490] = "1|Hellfire,54686235,1|Hellfire,87365241,1",
		[87354813] = "2|Hellfire,56293624,2|Hellfire,27795997,2",
		[54686235] = "1|TerokkarForest,59455543,1|ShattrathCity,64064111,1|Hellfire,87365241,1|Hellfire,78413490,1|Hellfire,25193723,1",
		[71416248] = "1|Hellfire,78413490,1",
		[68662823] = "1|Hellfire,78263445,1",
		[25193723] = "1|Hellfire,54686235,1|Zangarmarsh,67835146,1",
		[27795997] = "2|Hellfire,56293624,2|Zangarmarsh,84765511,2|Zangarmarsh,33075107,2|ShattrathCity,64064111,2|Nagrand,57193524,2",},
	["Nagrand"] = {
		[57193524] = "2|Zangarmarsh,33075107,2|ShattrathCity,64064111,2|Hellfire,27795997,2",
		[54177506] = "1|ShattrathCity,64064111,1|Zangarmarsh,67835146,1|TerokkarForest,59455543,1",},
	["Netherstorm"] = {
		[45313487] = "3|Netherstorm,33746399,3|Netherstorm,65206681,3|BladesEdgeMountains,37826140,1|BladesEdgeMountains,52055412,2",
		[33746399] = "3|Netherstorm,45313487,3|Netherstorm,65206681,3|BladesEdgeMountains,37826140,1|BladesEdgeMountains,61157044,1|BladesEdgeMountains,61683962,3|BladesEdgeMountains,52055412,2|BladesEdgeMountains,76376593,2",
		[65206681] = "3|Netherstorm,45313487,3|Netherstorm,33746399,3",},
	["ShadowmoonValley"] = {
		[63333039] = "6|ShadowmoonValley,37615545,4|ShadowmoonValley,30342919,5",
		[30342919] = "2|TerokkarForest,49194342,2|ShadowmoonValley,56325781,5|ShadowmoonValley,63333039,5",
		[37615545] = "1|TerokkarForest,59455543,1|ShadowmoonValley,56325781,4|ShadowmoonValley,63333039,4",
		[56325781] = "7|ShadowmoonValley,37615545,4|ShadowmoonValley,30342919,5",},
	["ShattrathCity"] = {[64064111] = "3|Zangarmarsh,67835146,1|Nagrand,54177506,1|TerokkarForest,59455543,1|Hellfire,54686235,1|TerokkarForest,49194342,2|Nagrand,57193524,2|Zangarmarsh,84765511,2|Zangarmarsh,33075107,2|Hellfire,27795997,2",},
	["TerokkarForest"] = {
		[49194342] = "2|ShattrathCity,64064111,2|ShadowmoonValley,30342919,2|Hellfire,56293624,2",
		[59455543] = "1|ShattrathCity,64064111,1|Hellfire,54686235,1|ShadowmoonValley,37615545,1|Nagrand,54177506,1",
		[63506582] = "8|BladesEdgeMountains,28285210,6",},
	["Zangarmarsh"] = {
		[41292899] = "1|Zangarmarsh,67835146,1|BladesEdgeMountains,37826140,1",
		[84765511] = "2|Zangarmarsh,33075107,2|ShattrathCity,64064111,2|Hellfire,27795997,2|BladesEdgeMountains,52055412,2|BladesEdgeMountains,76376593,2",
		[33075107] = "2|Zangarmarsh,84765511,2|ShattrathCity,64064111,2|Nagrand,57193524,2|Hellfire,27795997,2|BladesEdgeMountains,52055412,2",
		[67835146] = "1|Hellfire,25193723,1|ShattrathCity,64064111,1|Nagrand,54177506,1|Zangarmarsh,41292899,1|BladesEdgeMountains,37826140,1|BladesEdgeMountains,61157044,1",},
}

-- This table will contain a list of every zone in Kalimdor and Eastern Kingdom for the World Map of Azeroth
local AzerothZoneList = {}
do
	local t = Astrolabe.ContinentList
	for i = 1, #t[1] do -- Kalimdor
		tinsert(AzerothZoneList, t[1][i])
	end
	for i = 1, #t[2] do -- Azeroth
		tinsert(AzerothZoneList, t[2][i])
	end
end


---------------------------------------------------------
-- Line drawing helper functions

-- Function to get the intersection point of 2 lines (x1,y1)-(x2,y2) and (sx,sy)-(ex,ey)
-- If there is no intersection point, it returns (x2, y2)
local function GetIntersection(x1, y1, x2, y2, sx, sy, ex, ey)
	local dx = x2-x1
	local dy = y2-y1
	local numer = dx*(sy-y1) - dy*(sx-x1)
	local demon = dx*(sy-ey) + dy*(ex-sx)
	if demon ~= 0 and dx ~= 0 then
		local u = numer / demon
		local t = (sx + (ex-sx)*u - x1)/dx
		if u >= 0 and u <= 1 and t >= 0 and t <= 1 then
			return sx + (ex-sx)*u, sy + (ey-sy)*u --return true
		end
	end
	return x2, y2 --return false
end

-- Function to draw a line between 2 coordinates on map (C,Z)
-- (x1,y1) is already translated to map (C,Z)
local function drawline(C, Z, x1, y1, mapFile2, coord2, color)
	color = tonumber(color)
	if color == playerFaction then -- Same faction
		color = 1
	elseif color + playerFaction == 3 then -- Different faction
		if not db.show_both_factions then return end
		color = 2
	elseif color + playerFaction == 6 then -- Different faction, but special
		if not db.show_both_factions then return end
		color = 4
	end
	local C2, Z2 = HandyNotes:GetCZ(mapFile2)
	local x2, y2 = HandyNotes:getXY(coord2)
	x2, y2 = Astrolabe:TranslateWorldMapPosition(C2, Z2, x2, y2, C, Z)
	x2, y2 = GetIntersection(x1, y1, x2, y2, 0, 0, 0, 1)
	x2, y2 = GetIntersection(x1, y1, x2, y2, 0, 0, 1, 0)
	x2, y2 = GetIntersection(x1, y1, x2, y2, 0, 1, 1, 1)
	x2, y2 = GetIntersection(x1, y1, x2, y2, 1, 0, 1, 1)
	local w, h = WorldMapButton:GetWidth(), WorldMapButton:GetHeight()
	G:DrawLine(WorldMapButton, x1*w, (1-y1)*h, x2*w, (1-y2)*h, 25, colors[color], "OVERLAY")
end

-- Function to draw all lines from the given flightmaster
local function drawlines(mapFile, coord, fpType, ...)
	if db.show_lines then
		local C, Z = GetCurrentMapContinent(), GetCurrentMapZone()
		if Z > 0 and not db.show_lines_zone then return end
		local C1, Z1 = HandyNotes:GetCZ(mapFile)
		local x1, y1 = HandyNotes:getXY(coord)
		x1, y1 = Astrolabe:TranslateWorldMapPosition(C1, Z1, x1, y1, C, Z)
		for i = 1, select("#", ...) do
			drawline(C, Z, x1, y1, strsplit(",", (select(i, ...))))
		end
	end
	return fpType
end


---------------------------------------------------------
-- Plugin Handlers to HandyNotes

local HFMHandler = {}

function HFMHandler:OnEnter(mapFile, coord)
	local tooltip, fpType
	if self:GetParent() == WorldMapButton then
		tooltip = WorldMapTooltip
		fpType = tonumber(drawlines(mapFile, coord, strsplit("|", HFM_Data[mapFile][coord])))
		tooltip:SetOwner(self, "ANCHOR_NONE")
		tooltip:SetPoint("BOTTOMRIGHT", WorldMapButton)
	else
		tooltip = GameTooltip
		fpType = tonumber((strsplit("|", HFM_Data[mapFile][coord])))
		-- compare X coordinate
		tooltip:SetOwner(self, self:GetCenter() > UIParent:GetCenter() and "ANCHOR_LEFT" or "ANCHOR_RIGHT")
	end
	tooltip:SetText(HFM_DataType[fpType])
	tooltip:Show()
end

function HFMHandler:OnLeave(mapFile, coord)
	if self:GetParent() == WorldMapButton then
		WorldMapTooltip:Hide()
		G:HideLines(WorldMapButton)
	else
		GameTooltip:Hide()
	end
end

do
	local emptyTbl = {}
	local tablepool = setmetatable({}, {__mode = 'k'})

	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return end
		local state, value = next(t, prestate)
		while state do -- Have we reached the end of this zone?
			value = tonumber((strsplit("|", value)))
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
	end

	-- This is a funky custom iterator we use to iterate over every zone's nodes in a given continent
	local function iterCont(t, prestate)
		if not t then return end
		local C, Z = t.mapC, t.mapZ
		local zone = t.Z
		local mapFile = t.C[zone]
		local data = HFM_Data[mapFile]
		local state, value
		while mapFile do
			if data then -- Only if there is data for this zone
				state, value = next(data, prestate)
				while state do -- Have we reached the end of this zone?
					value = tonumber((strsplit("|", value)))
					local x, y = HandyNotes:getXY(state)
					local c1, z1 = HandyNotes:GetCZ(mapFile)
					local x, y = Astrolabe:TranslateWorldMapPosition(c1, z1, x, y, C, Z)
					if x > 0 and x < 1 and y > 0 and y < 1 then
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
	end

	function HFMHandler:GetNodes(mapFile, minimap)
		local C, Z = HandyNotes:GetCZ(mapFile)
		if minimap then -- Return only the requested zone's data for the minimap
			return iter, HFM_Data[mapFile], nil
		elseif C and Z and C >= 0 then
			-- Not minimap, so whatever map it is, we return the entire continent of nodes
			-- C and Z can be nil if we're in a battleground
			if Z > 0 or (Z == 0 and db.show_on_continent) then
				local tbl = next(tablepool) or {}
				tablepool[tbl] = nil
				tbl.C = C == 0 and AzerothZoneList or Astrolabe.ContinentList[C]
				tbl.Z = 1
				tbl.mapC = C
				tbl.mapZ = Z
				return iterCont, tbl, nil
			end
		end
		return next, emptyTbl, nil
	end
end


---------------------------------------------------------
-- Options table
local options = {
	type = "group",
	name = L["FlightMasters"],
	desc = L["FlightMasters"],
	get = function(info) return db[info.arg] end,
	set = function(info, v)
		db[info.arg] = v
		HFM:SendMessage("HandyNotes_NotifyUpdate", "FlightMasters")
	end,
	args = {
		desc = {
			name = L["These settings control the look and feel of the FlightMaster icons."],
			type = "description",
			order = 0,
		},
		flight_icons = {
			type = "group",
			name = L["FlightMaster Icons"],
			desc = L["FlightMaster Icons"],
			order = 20,
			inline = true,
			args = {
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
				show_both_factions = {
					type = "toggle",
					name = L["Show both factions"],
					desc = L["Show all flightmasters instead of only those that you can use"],
					arg = "show_both_factions",
					order = 30,
				},
				show_on_continent = {
					type = "toggle",
					name = L["Show on continent maps"],
					desc = L["Show flightmasters on continent level maps as well"],
					arg = "show_on_continent",
					order = 40,
				},
			},
		},
		flight_lines = {
			type = "group",
			name = L["Flight path lines"],
			desc = L["Flight path lines"],
			order = 50,
			inline = true,
			args = {
				show_lines = {
					type = "toggle",
					name = L["Show flight path lines"],
					desc = L["Show flight path lines on the world map"],
					arg = "show_lines",
					order = 50,
				},
				show_lines_zone = {
					type = "toggle",
					name = L["Show in zones"],
					desc = L["Show flight path lines on the zone maps as well"],
					arg = "show_lines_zone",
					order = 50,
					disabled = function() return not db.show_lines end,
				},
			},
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
	G:HideLines(WorldMapButton)
end


------------------------------------------------------------------------------------------------------
-- The following function is used with permission from Daniel Stephens <iriel@vigilance-committee.org>
-- with reference to TaxiFrame.lua in Blizzard's UI and Graph-1.0 Ace2 library (by Cryect) which I now
-- maintain after porting it to LibGraph-2.0 LibStub library -- Xinhuan
local TAXIROUTE_LINEFACTOR = 128/126; -- Multiplying factor for texture coordinates
local TAXIROUTE_LINEFACTOR_2 = TAXIROUTE_LINEFACTOR / 2; -- Half of that

-- T        - Texture
-- C        - Canvas Frame (for anchoring)
-- sx,sy    - Coordinate of start of line
-- ex,ey    - Coordinate of end of line
-- w        - Width of line
-- relPoint - Relative point on canvas to interpret coords (Default BOTTOMLEFT)
function G:DrawLine(C, sx, sy, ex, ey, w, color, layer)
	local relPoint = "BOTTOMLEFT"
	
	if not C.HandyNotesFM_Lines then
		C.HandyNotesFM_Lines = {}
		C.HandyNotesFM_Lines_Used = {}
	end

	local T = tremove(C.HandyNotesFM_Lines) or C:CreateTexture(nil, "ARTWORK")
	T:SetTexture("Interface\\AddOns\\HandyNotes_FlightMasters\\line")
	tinsert(C.HandyNotesFM_Lines_Used,T)

	T:SetDrawLayer(layer or "ARTWORK")

	T:SetVertexColor(color[1],color[2],color[3],color[4]);
	-- Determine dimensions and center point of line
	local dx,dy = ex - sx, ey - sy;
	local cx,cy = (sx + ex) / 2, (sy + ey) / 2;

	-- Normalize direction if necessary
	if (dx < 0) then
		dx,dy = -dx,-dy;
	end

	-- Calculate actual length of line
	local l = ((dx * dx) + (dy * dy)) ^ 0.5;

	-- Sin and Cosine of rotation, and combination (for later)
	local s,c = -dy / l, dx / l;
	local sc = s * c;

	-- Calculate bounding box size and texture coordinates
	local Bwid, Bhgt, BLx, BLy, TLx, TLy, TRx, TRy, BRx, BRy;
	if (dy >= 0) then
		Bwid = ((l * c) - (w * s)) * TAXIROUTE_LINEFACTOR_2;
		Bhgt = ((w * c) - (l * s)) * TAXIROUTE_LINEFACTOR_2;
		BLx, BLy, BRy = (w / l) * sc, s * s, (l / w) * sc;
		BRx, TLx, TLy, TRx = 1 - BLy, BLy, 1 - BRy, 1 - BLx; 
		TRy = BRx;
	else
		Bwid = ((l * c) + (w * s)) * TAXIROUTE_LINEFACTOR_2;
		Bhgt = ((w * c) + (l * s)) * TAXIROUTE_LINEFACTOR_2;
		BLx, BLy, BRx = s * s, -(l / w) * sc, 1 + (w / l) * sc;
		BRy, TLx, TLy, TRy = BLx, 1 - BRx, 1 - BLx, 1 - BLy;
		TRx = TLy;
	end

	-- Set texture coordinates and anchors
	T:ClearAllPoints();
	T:SetTexCoord(TLx, TLy, BLx, BLy, TRx, TRy, BRx, BRy);
	T:SetPoint("BOTTOMLEFT", C, relPoint, cx - Bwid, cy - Bhgt);
	T:SetPoint("TOPRIGHT",   C, relPoint, cx + Bwid, cy + Bhgt);
	T:Show()
	return T
end

function G:HideLines(C)
	if C.HandyNotesFM_Lines then
		for i = #C.HandyNotesFM_Lines_Used, 1, -1 do
			C.HandyNotesFM_Lines_Used[i]:Hide()
			tinsert(C.HandyNotesFM_Lines, tremove(C.HandyNotesFM_Lines_Used))
		end
	end
end
