---------------------------------------------------------
-- Addon declaration
HandyNotes_Mailboxes = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_Mailboxes","AceEvent-3.0")
local MB = HandyNotes_Mailboxes
local Astrolabe = DongleStub("Astrolabe-0.4")
--local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_FlightMasters", false)


---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local defaults = {
	global = {
		mailboxes = {
			["*"] = ["*"],
		}
	}
	profile = {
		icon_scale         = 1.0,
		icon_alpha         = 1.0,
	},
}
---------------------------------------------------------
-- Localize some globals
local next = next
local GameTooltip = GameTooltip


---------------------------------------------------------
-- Constants
local icon = "Interface\\Icons\\INV_Letter_15"
local MBHandler = {}
function MBHandler:OnEnter(mapFile, coord)
	-- no tooltip needed for a mailbox
end
function HMBHandler:OnLeave(mapFile, coord)
end

do
	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		local state, value = next(t, prestate)
		while state do -- Have we reached the end of this zone?
			if value then
				return state, icon, db.icon_scale,db.icon_alpha
			end
			state, value = next(t, state) -- Get next data
		end
		return nil, nil, nil, nil
	end
	function HMBHandler:GetNodes(mapFile)
		return iter, self.db.global.mailboxes[mapFile], nil
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
			name = "These settings control the look and feel of the Mailbox icon.",
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
function HMB:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_MailboxesDB", defaults)
	db = self.db.profile
	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("Mailboxes", MBHandler, options)
end

function HMB:OnEnable()
	self:RegisterEvent("MAIL_SHOW", function() 
		local x, y = GetPlayerMapPosition("player")	
		local coord = HandyNotes:getCoord(x,y)
		local continent = GetCurrentMapContinent()
		local map = HandyNotes:GetMapFile(continent)
		if map then
			self.db.global.mailboxes[map][coord]=true
			HFM:SendMessage("HandyNotes_NotifyUpdate", "Mailboxes")
		end
	end)
end

function HMB:OnDisable()
end
