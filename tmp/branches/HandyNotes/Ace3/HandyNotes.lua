--[[
HandyNotes
]]

---------------------------------------------------------
-- Addon declaration
HandyNotes = LibStub("AceAddon-3.0"):NewAddon("HandyNotes", "AceConsole-3.0", "AceEvent-3.0")
local HandyNotes = HandyNotes
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes", false)
local Astrolabe = DongleStub("Astrolabe-0.4")


---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local options
local defaults = {
	profile = {
		enabled       = true,
		icon_scale    = 1.0,
		icon_alpha    = 1.0,
	}
}


---------------------------------------------------------
-- Localize some globals
local floor = floor
local WorldMapButton = WorldMapButton


---------------------------------------------------------
-- Our frames recycling code
local pinCache = {}
local minimapPins = {}
local worldmapPins = {}
local pinCount = 0

local function recyclePin(pin)
	pin:Hide()
	pinCache[pin] = true
end

local function clearAllPins(t)
	for coord, pin in pairs(t) do
		recyclePin(pin)
		t[coord] = nil
	end
end

local function getNewPin()
	local pin = next(pinCache)
	if pin then
		pinCache[pin] = nil -- remove it from the cache
		return pin
	end
	-- create a new pin
	pinCount = pinCount + 1
	pin = CreateFrame("Button", "HandyNotesPin"..pinCount, WorldMapButton)
	pin:SetFrameLevel(5)
	pin:EnableMouse(true)
	pin:SetWidth(12)
	pin:SetHeight(12)
	pin:SetPoint("CENTER", WorldMapButton, "CENTER")
	local texture = pin:CreateTexture(nil, "OVERLAY")
	pin.texture = texture
	texture:SetAllPoints(pin)
	pin:RegisterForClicks("LeftButtonDown", "LeftButtonUp", "RightButtonDown", "RightButtonUp")
	pin:SetMovable(true)
	pin:Hide()
	return pin
end


---------------------------------------------------------
-- Plugin handling
HandyNotes.plugins = {}

--[[ Documentation:
HandyNotes.plugins table contains every plugin which we will use to iterate over.
In this table, the format is:
	["Name of plugin"] = {table containing a set of standard functions, which we'll call pluginHandler}

Standard functions we require for every plugin:
	:GetNodes(mapFile)
		This function should return an iterator function. The iterator will loop over and return 4 values
			(coord, mapFile, iconpath, scale, alpha)
		for every node in the requested zone. If the mapFile return value is nil, we assume it is the
		same mapFile as the argument passed in. Mainly used for continent mapFile where the map passed
		in is a continent, and the return values are coords of subzone maps.

Standard functions you can provide optionally:
	:OnEnter(self)
		Function we will call when the mouse enters a HandyNote, you will generally produce a tooltip here.
	:OnLeave(self)
		Function we will call when the mouse leaves a HandyNote, you will generally hide the tooltip here.
	:OnClick(self, button)
		Function we will call when the user clicks on a HandyNote, you will generally produce a menu here on right-click.
]]

function HandyNotes:RegisterPluginDB(pluginName, pluginHandler, optionsTable)
	if self.plugins[pluginName] ~= nil then
		error(pluginName.." is already registered by another plugin.")
	else
		self.plugins[pluginName] = pluginHandler
	end
	worldmapPins[pluginName] = {}
	minimapPins[pluginName] = {}
	options.args.plugins.args[pluginName] = optionsTable
end


local pinsHandler = {}
function pinsHandler:OnEnter(motion)
	local func = HandyNotes.plugins[self.pluginName].OnEnter
	if type(func) == "function" then func(self, self.mapFile, self.coord) end
end
function pinsHandler:OnLeave(motion)
	local func = HandyNotes.plugins[self.pluginName].OnLeave
	if type(func) == "function" then func(self, self.mapFile, self.coord) end
end
function pinsHandler:OnClick(button, down)
	local func = HandyNotes.plugins[self.pluginName].OnClick
	if type(func) == "function" then func(self, button, down, self.mapFile, self.coord) end
end


---------------------------------------------------------
-- Public functions

-- Public functions for plugins to convert between MapFile <-> C,Z
local continentMapFile = {
	[1] = "Kalimdor",
	[2] = "Azeroth",
	[3] = "Expansion01",
}
local reverseMapFileC = {}
local reverseMapFileZ = {}
for C = 1, #Astrolabe.ContinentList do
	for Z = 1, #Astrolabe.ContinentList[C] do
		local mapFile = Astrolabe.ContinentList[C][Z]
		reverseMapFileC[mapFile] = C
		reverseMapFileZ[mapFile] = Z
	end
end
for C = 1, #continentMapFile do
	local mapFile = continentMapFile[C]
	reverseMapFileC[mapFile] = C
	reverseMapFileZ[mapFile] = 0
end

function HandyNotes:GetMapFile(C, Z)
	if C > 0 then
		if Z == 0 then
			return continentMapFile[C]
		else
			return Astrolabe.ContinentList[C][Z]
		end
	end
end
function HandyNotes:GetCZ(mapFile)
	return reverseMapFileC[mapFile], reverseMapFileZ[mapFile]
end

-- Public functions for plugins to convert between coords <--> x,y
function HandyNotes:getCoord(x, y)
	return floor(x * 10000 + 0.5) * 10000 + floor(y * 10000 + 0.5)
end
function HandyNotes:getXY(id)
	return floor(id / 10000) / 10000, (id % 10000) / 10000
end


---------------------------------------------------------
-- Core functions

-- This function updates all the icons of one plugin on the world map
function HandyNotes:UpdateWorldMapPlugin(pluginName)
	if not WorldMapButton:IsVisible() then return end

	clearAllPins(worldmapPins[pluginName])

	local ourScale, ourAlpha = db.icon_scale, db.icon_alpha
	local continent, zone = GetCurrentMapContinent(), GetCurrentMapZone()
	if continent == 0 or continent == -1 then return end
	local mapFile = GetMapInfo() --self:GetMapFile(continent, zone)
	local pluginHandler = self.plugins[pluginName]

	for coord, mapFile2, iconpath, scale, alpha in pluginHandler:GetNodes(mapFile) do
		local icon = getNewPin()
		icon:SetHeight(12 * ourScale * scale) -- Can't use :SetScale as that changes our positioning scaling as well
		icon:SetWidth(12 * ourScale * scale)
		icon:SetAlpha(ourAlpha * alpha)
		if type(iconpath) == "table" then
			icon.texture:SetTexture(iconpath.icon)
			icon.texture:SetTexCoord(iconpath.tCoordLeft, iconpath.tCoordRight, iconpath.tCoordTop, iconpath.tCoordBottom)
		else
			icon.texture:SetTexture(iconpath)
			icon.texture:SetTexCoord(0, 1, 0, 1)
		end
		icon:SetScript("OnClick", pinsHandler.OnClick)
		icon:SetScript("OnEnter", pinsHandler.OnEnter)
		icon:SetScript("OnLeave", pinsHandler.OnLeave)
		local C, Z
		if mapFile2 then
			C, Z = self:GetCZ(mapFile2)
		else
			C, Z = continent, zone
		end
		local x, y = floor(coord / 10000) / 10000, (coord % 10000) / 10000
		Astrolabe:PlaceIconOnWorldMap(WorldMapButton, icon, C, Z, x, y)
		worldmapPins[pluginName][C*1e10 + Z*1e8 + coord] = icon
		icon.pluginName = pluginName
		icon.coord = coord
		icon.mapFile = mapFile2 or mapFile
	end
end

-- This function updates all the icons on the world map for every plugin
function HandyNotes:UpdateWorldMap()
	if not WorldMapButton:IsVisible() then return end

	for pluginName in pairs(self.plugins) do
		-- TODO: Wrap this with a safecall()
		self:UpdateWorldMapPlugin(pluginName)
	end
end

-- This function runs when we receive a "HandyNotes_NotifyUpdate"
-- notification from a plugin that its icons needs to be updated
function HandyNotes:UpdatePluginMap(message, pluginName)
	if self.plugins[pluginName] then
		self:UpdateWorldMapPlugin(pluginName)
	end
end


---------------------------------------------------------
-- Our options table

options = {
	type = "group",
	name = L["HandyNotes"],
	desc = L["HandyNotes"],
	get = function(info) return db[info.arg] end,
	set = function(info, v)
		db[info.arg] = v
		HandyNotes:UpdateWorldMap()
	end,
	args = {
		enabled = {
			type = "toggle",
			name = "Enable HandyNotes",
			desc = "Enable or disable HandyNotes",
			arg = "enabled",
			order = 1,
			set = function(info, v)
				db.enabled = v
				if v then HandyNotes:Enable() else HandyNotes:Disable() end
			end,
			disabled = false,
		},
		overall_settings = {
			type = "group",
			name = "Overall settings",
			desc = "Overall settings that affect every database",
			order = 10,
			disabled = function() return not db.enabled end,
			args = {
				desc = {
					name = "These settings control the look and feel of every database globally.",
					type = "description",
					order = 0,
				},
				icon_scale = {
					type = "range",
					name = "Overall Icon Scale",
					desc = "The overall scale of the icons",
					min = 0.25, max = 2, step = 0.01,
					arg = "icon_scale",
					order = 10,
				},
				icon_alpha = {
					type = "range",
					name = "Overall Icon Alpha",
					desc = "The overall alpha transparency of the icons",
					min = 0, max = 1, step = 0.01,
					arg = "icon_alpha",
					order = 20,
				},
			},
		},
		plugins = {
			type = "group",
			name = "Plugins",
			desc = "Plugin databases",
			order = 20,
			args = {
				desc = {
					name = "Configuration for each plugin databases.",
					type = "description",
					order = 0,
				},
			},
		},
	},
}


---------------------------------------------------------
-- Addon initialization, enabling and disabling

function HandyNotes:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotesDB", defaults)
	db = self.db.profile

	-- Register options table and slash command
	LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("HandyNotes", options)
	self:RegisterChatCommand("handynotes", function() LibStub("AceConfigDialog-3.0"):Open("HandyNotes") end)
end

function HandyNotes:OnEnable()
	if not db.enabled then
		self:Disable()
		return
	end
	SetMapToCurrentZone()
	self:RegisterEvent("WORLD_MAP_UPDATE", "UpdateWorldMap")
	self:RegisterMessage("HandyNotes_NotifyUpdate", "UpdatePluginMap")
end

function HandyNotes:OnDisable()
	-- Remove all the world map pins
	for pluginName, pluginPinTable in pairs(worldmapPins) do
		clearAllPins(pluginPinTable)
	end
end

-- vim: ts=4 noexpandtab
