---------------------------------------------------------
-- Addon declaration
HandyNotes_Mailboxes = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_Mailboxes","AceEvent-3.0")
local HMB = HandyNotes_Mailboxes
--local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes_Mailboxes", false)


---------------------------------------------------------
-- Our db upvalue and db defaults
local db
local defaults = {
	global = {
		mailboxes = {
			["*"] = {},  -- [mapFile] = {[coord] = true, [coord] = true}
		},
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
local icon = "Interface\\Icons\\INV_Letter_15"


---------------------------------------------------------
-- Plugin Handlers to HandyNotes
local HMBHandler = {}
function HMBHandler:OnEnter(mapFile, coord)
	if ( self:GetCenter() > self:GetParent():GetCenter() ) then -- compare X coordinate
		WorldMapTooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		WorldMapTooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	WorldMapTooltip:SetText("Mailbox")
	WorldMapTooltip:Show()
end

function HMBHandler:OnLeave(mapFile, coord)
	WorldMapTooltip:Hide()
end

do
	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		local state, value = next(t, prestate)
		while state do -- Have we reached the end of this zone?
			if value then
				return state, icon, db.icon_scale, db.icon_alpha
			end
			state, value = next(t, state) -- Get next data
		end
		return nil, nil, nil, nil
	end
	function HMBHandler:GetNodes(mapFile)
		return iter, HMB.db.global.mailboxes[mapFile], nil
	end
end

-- TODO: Add right click menu to delete a mailbox


---------------------------------------------------------
-- Core functions

function HMB:AddMailBox()
	SetMapToCurrentZone()
	local x, y = GetPlayerMapPosition("player")
	local coord = HandyNotes:getCoord(x, y)
	local mapFile = GetMapInfo()
	-- TODO: Add code to remove nearby mailboxes within about 15 yards
	self.db.global.mailboxes[mapFile][coord] = true
	HMB:SendMessage("HandyNotes_NotifyUpdate", "Mailboxes")
end


---------------------------------------------------------
-- Options table
local options = {
	type = "group",
	name = "Mailboxes",
	desc = "Mailboxes",
	get = function(info) return db[info.arg] end,
	set = function(info, v)
		db[info.arg] = v
		HMB:SendMessage("HandyNotes_NotifyUpdate", "Mailboxes")
	end,
	args = {
		desc = {
			name = "These settings control the look and feel of the Mailbox icon. Note that HandyNotes_MailBoxes does not come with any precompiled data, when you visit mailboxes, it will automatically add the data into your database.",
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

function HMB:OnInitialize()
	-- Set up our database
	self.db = LibStub("AceDB-3.0"):New("HandyNotes_MailboxesDB", defaults)
	db = self.db.profile
	-- Initialize our database with HandyNotes
	HandyNotes:RegisterPluginDB("Mailboxes", HMBHandler, options)
end

function HMB:OnEnable()
	self:RegisterEvent("MAIL_SHOW", "AddMailBox")
end

function HMB:OnDisable()
end
