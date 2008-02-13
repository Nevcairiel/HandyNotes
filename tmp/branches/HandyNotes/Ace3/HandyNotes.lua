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
	pin:SetWidth(16)
	pin:SetHeight(16)
	pin:SetPoint("CENTER", WorldMapButton, "CENTER")
	local texture = pin:CreateTexture(nil, "OVERLAY")
	pin.texture = texture
	texture:SetAllPoints(pin)
	pin:RegisterForClicks("LeftButtonUp", "RightButtonUp");
	pin:Hide()
	return pin
end


---------------------------------------------------------
-- Plugin handling
HandyNotes.plugins = {}

--[[ Documentation:
HandyNotes.plugins table contains every plugin which we will use to iterate over.
In this table, the format is:
	Key   = "Name of plugin"
	Value = {table containing a set of standard functions, which we'll call pluginHandler}

Standard functions we require for every plugin:
	:GetNodes(mapFile)      = This function should return an iterator function. The iterator will loop over and return 4 values
	                             (coord, iconpath, scale, alpha)
                              for every node in the requested zone.
Standard functions you can provide optionally:
	:OnEnter(self)          = Function we will call when the mouse enters a HandyNote, you will generally produce a tooltip here.
	:OnLeave(self)          = Function we will call when the mouse leaves a HandyNote, you will generally hide the tooltip here.
	:OnClick(self, button)  = Function we will call when the user clicks on a HandyNote, you will generally produce a menu here on right-click.
	:GetNodesForContinent(mapFile) = This function should return an iterator function. The iterator should return
                                         (coord, zone, iconpath, scale, alpha)
                                     for every node in the requested continent.
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
function pinsHandler:OnEnter()
	local func = HandyNotes.plugins[self.pluginName].OnEnter
	if type(func) == "function" then func(self, self.mapFile, self.coord) end
end
function pinsHandler:OnLeave()
	local func = HandyNotes.plugins[self.pluginName].OnLeave
	if type(func) == "function" then func(self, self.mapFile, self.coord) end
end
function pinsHandler:OnClick()
	local func = HandyNotes.plugins[self.pluginName].OnClick
	if type(func) == "function" then func(self, self.mapFile, self.coord) end
end


---------------------------------------------------------
-- Core functions

local continentMapFile = {
	[1] = "Kalimdor",
	[2] = "Azeroth",
	[3] = "Expansion01",
}
function HandyNotes:GetMapFile(C, Z)
	if C > 0 then
		if Z == 0 then
			return continentMapFile[C]
		else
			return Astrolabe.ContinentList[C][Z]
		end
	end
end

-- This function updates all the icons on the world map
function HandyNotes:UpdateWorldMap()
	if not WorldMapButton:IsVisible() then return end

	for pluginName, pluginPinTable in pairs(worldmapPins) do
		clearAllPins(pluginPinTable)
	end

	local ourScale, ourAlpha = db.icon_scale, db.icon_alpha

	local continent, zone = GetCurrentMapContinent(), GetCurrentMapZone()
	local mapFile = self:GetMapFile(continent, zone)
	for pluginName, pluginHandler in pairs(self.plugins) do
		if continent > 0 and zone == 0 then
			-- We are viewing a continent map
			if pluginHandler.GetNodesForContinent then
				for coord, zone, iconpath, scale, alpha in pluginHandler:GetNodesForContinent(mapFile) do
					local icon = getNewPin()
					icon:SetHeight(16 * ourScale * scale) -- Can't use :SetScale as that changes our positioning scaling as well
					icon:SetWidth(16 * ourScale * scale)
					icon:SetAlpha(ourAlpha * alpha)
					icon.texture:SetTexture(iconpath)
					icon:SetScript("OnClick", pinsHandler.OnClick)
					icon:SetScript("OnEnter", pinsHandler.OnEnter)
					icon:SetScript("OnLeave", pinsHandler.OnLeave)
					local xPos, yPos = floor(coord / 10000) / 10000, (coord % 10000) / 10000
					Astrolabe:PlaceIconOnWorldMap(WorldMapButton, icon, continent, zone, xPos, yPos)
					worldmapPins[pluginName][coord] = icon
					icon.pluginName = pluginName
					icon.coord = coord
					icon.mapFile = self:GetMapFile(continent, zone)
				end
			end
		elseif continent > 0 and zone > 0 then
			-- We are viewing a zone map inside a continent
			for coord, iconpath, scale, alpha in pluginHandler:GetNodes(mapFile) do
				local icon = getNewPin()
				icon:SetHeight(16 * ourScale * scale) -- Can't use :SetScale as that changes our positioning scaling as well
				icon:SetWidth(16 * ourScale * scale)
				icon:SetAlpha(ourAlpha * alpha)
				icon.texture:SetTexture(iconpath)
				icon:SetScript("OnClick", pinsHandler.OnClick)
				icon:SetScript("OnEnter", pinsHandler.OnEnter)
				icon:SetScript("OnLeave", pinsHandler.OnLeave)
				local xPos, yPos = floor(coord / 10000) / 10000, (coord % 10000) / 10000
				Astrolabe:PlaceIconOnWorldMap(WorldMapButton, icon, continent, zone, xPos, yPos)
				worldmapPins[pluginName][coord] = icon
				icon.pluginName = pluginName
				icon.coord = coord
				icon.mapFile = mapFile
			end
		end
	end
end

function HandyNotes:UpdateMaps(sourcePlugin)
	self:UpdateWorldMap()
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
		HandyNotes:UpdateMaps()
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
	self:RegisterMessage("HandyNotes_NotifyUpdate", "UpdateMaps")
end

function HandyNotes:OnDisable()
	-- Remove all the world map pins
	for pluginName, pluginPinTable in pairs(worldmapPins) do
		clearAllPins(pluginPinTable)
	end
end

-- vim: ts=4 noexpandtab
