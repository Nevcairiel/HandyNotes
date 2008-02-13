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
local HandyNotes = HandyNotes


---------------------------------------------------------
-- Constants
local icon = "Interface\\Icons\\Ability_Hunter_BeastTaming"

---------------------------------------------------------
-- Plugin Handlers to HandyNotes

local HSHandler = {}
function HSHandler:OnEnter(mapFile, coord)
	if ( self:GetCenter() > self:GetParent():GetCenter() ) then -- compare X coordinate
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	GameTooltip:AddLine(db.factionrealm.nodes[mapFile][coord])
	GameTooltip:AddLine(L["Stable Master"])
	GameTooltip:Show()
end

function HSHandler:OnLeave(mapFile, coord)
	GameTooltip:Hide()
end

do
	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		local state, value = next(t, prestate)
		return state, icon, db.profile.icon_scale, db.profile.icon_alpha
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

local thres = 5 -- in yards
function HS:OnEnable()
	self:RegisterEvent("PET_STABLE_SHOW", function()
		local stableName = UnitName("target")
		local continent, zone, x, y = Astrolabe:GetCurrentPlayerPosition()
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
	end)
end
