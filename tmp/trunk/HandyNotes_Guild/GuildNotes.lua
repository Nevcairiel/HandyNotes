--[[ $Id$ ]]
local Guild = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_Guild", "AceEvent-3.0", "AceBucket-3.0", "AceHook-3.0")

local HandyNotes = HandyNotes
local LGP = LibStub("LibGuildPositions-1.0")

local fmt = string.format
local next, pairs, rawget = next, pairs, rawget

local IsInGuild, GuildRoster = IsInGuild, GuildRoster
local GetGuildRosterInfo, GetNumGuildMembers = GetGuildRosterInfo, GetNumGuildMembers
local RAID_CLASS_COLORS = RAID_CLASS_COLORS

local defaults = nil
local options = nil
local icon = "Interface\\AddOns\\HandyNotes_Guild\\Normal"

--[[
	------------------------------
	database related stuff
	------------------------------
]]

--[[ player data - class and color tables ]]
local playerClass, playerClassLocalized, playerColor, playerLevel
do
	local greyTbl = { r = 0.8, g = 0.8, b = 0.8 }
	playerClass = {}
	playerClassLocalized = {}
	playerLevel = {}
	playerColor = setmetatable({}, {
		__index = function(t, name)
			local class = playerClass[name]
			if class then
				t[name] = RAID_CLASS_COLORS[class]
				return t[name]
			else
				return greyTbl
			end
		end
	})
end

--[[ player storage database - position, icon, zone ]]
local database, nameLookup, recycle
do
	local cache = setmetatable({}, {__mode = 'k'})
	function recycle(tbl)
		cache[tbl] = true
	end
	
	database = setmetatable({}, {
		__index = function(t, k)
			local new = next(cache)
			if new then
				cache[new] = nil 
			else 
				new = { icon = { icon = icon } }
			end
			
			new.name = k
			
			local c = playerColor[k]
			new.icon.r, new.icon.g, new.icon.b, new.icon.a = c.r, c.g, c.b, 1
			
			t[k] = new
			return new
		end
	})
end

local function findPlayer(zone, coord)
	for k,v in pairs(database) do
		if v.zone == zone and v.coord == coord then
			return v
		end
	end
	return nil
end


--[[
	------------------------------
	HandyNotes Plugin Handler
	------------------------------
]]
local GuildHandler = {}

function GuildHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if ( self:GetCenter() > UIParent:GetCenter() ) then -- compare X coordinate
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	local player = findPlayer(mapFile, coord)
	if not player then return end
	local name = player.name
	tooltip:AddLine("|cffe0e0e0" .. name .. "|r")
	tooltip:AddLine(fmt("L%d - |cff%02x%02x%02x%s|r", playerLevel[name] or 0, player.icon.r * 255, player.icon.g * 255, player.icon.b * 255, playerClassLocalized[name] or UNKNOWN))
	tooltip:Show()
end

function GuildHandler:OnLeave(mapFile, coord)
	if self:GetParent() == WorldMapButton then
		WorldMapTooltip:Hide()
	else
		GameTooltip:Hide()
	end
end

do
	local scale, alpha = 1.2, 1
	local prestate = nil
	local emptyTbl = {}
	-- This is a custom iterator we use to iterate over every node
	local function iter(t)
		if not t then return end
		local state, value = next(t, prestate)
		prestate = state
		if state then
			return value.coord, value.zone, value.icon, scale, alpha
		end
	end

	function GuildHandler:GetNodes(mapFile, minimap)
		prestate = nil
		if minimap then
			return iter, emptyTbl, nil
		else
			return iter, database, nil
		end
	end
end

---------------------------------------------------------
-- Addon initialization, enabling and disabling

function Guild:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_GuildDB", defaults)
	
	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("Guild", GuildHandler, options)
end

function Guild:OnEnable()
	LGP.RegisterCallback(self, "Clear", "UpdateMember")
	LGP.RegisterCallback(self, "Position", "UpdateMember")
	
	self:RegisterBucketEvent("GUILD_ROSTER_UPDATE", 1)
	if IsInGuild() then
		GuildRoster()
	end
	
	self:UpdateAllMembers()
end

function Guild:OnDisable()
	LGP.UnregisterAllCallbacks(self)
	for k,v in pairs(database) do
		recycle(v)
		database[k] = nil
	end
end

-- Event Handler to update the guild roster
function Guild:GUILD_ROSTER_UPDATE()
	local updateNeeded = false
	if IsInGuild() then
		local numPlayersTotal = GetNumGuildMembers(true)
		local name, _, level, class, classFile
		for i = 1, numPlayersTotal do
			name, _, _, level, class, _, _, _, _, _, classFile = GetGuildRosterInfo(i)
			if name then
				if not playerClass[name] then
					playerClass[name] = classFile
					
					-- if we already have a entry in our database table, update its color
					if rawget(database, name) then
						local i, c = database[name].icon, playerColor[name]
						i.r, i.g, i.b = c.r, c.g, c.b
						-- and directly update the icon
						updateNeeded = true
					end
				end
				playerLevel[name] = level or 0
				playerClassLocalized[name] = class or UNKNOWN
			end
		end
	end
	if updateNeeded then
		self:SendMessage("HandyNotes_NotifyUpdate", "Guild")
	end
end

-- LGP Callback for updating member positions
function Guild:UpdateMember(event, sender, x, y, zone)
	if event == "Clear" then
		recycle(database[sender])
		database[sender] = nil
	elseif event == "Position" then
		database[sender].coord = HandyNotes:getCoord(x,y)
		database[sender].zone = zone
	end
	self:SendMessage("HandyNotes_NotifyUpdate", "Guild")
end

-- Poll LGP for all members in its database (right now only called once on initialization)
function Guild:UpdateAllMembers()
	for name, x, y, zone in LGP:IterateGuildMembers() do
		database[name].coord = HandyNotes:getCoord(x,y)
		database[name].zone = zone
		database[name].keep = true
	end
	
	for k,v in pairs(database) do
		if not v.keep then
			recycle(v)
			database[k] = nil
		else
			v.keep = nil
		end
	end
	self:SendMessage("HandyNotes_NotifyUpdate", "Guild")
end
