---------------------------------------------------------
-- Addon declaration
HandyNotes_Mailboxes = LibStub("AceAddon-3.0"):NewAddon("HandyNotes_Mailboxes","AceEvent-3.0")
local HMB = HandyNotes_Mailboxes
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local Astrolabe = DongleStub("Astrolabe-0.4-NC")
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
local HandyNotes = HandyNotes


---------------------------------------------------------
-- Constants
local icon = "Interface\\AddOns\\HandyNotes_Mailboxes\\Mail.tga"


---------------------------------------------------------
-- Plugin Handlers to HandyNotes
local HMBHandler = {}
local info = {}
local clickedMailbox = nil
local clickedMailboxZone = nil

function HMBHandler:OnEnter(mapFile, coord)
	local tooltip = self:GetParent() == WorldMapButton and WorldMapTooltip or GameTooltip
	if ( self:GetCenter() > UIParent:GetCenter() ) then -- compare X coordinate
		tooltip:SetOwner(self, "ANCHOR_LEFT")
	else
		tooltip:SetOwner(self, "ANCHOR_RIGHT")
	end
	tooltip:SetText("Mailbox")
	tooltip:Show()
	clickedMailbox = nil
	clickedMailboxZone = nil
end

local function deletePin(mapFile,coord)
	HMB.db.global.mailboxes[mapFile][coord] = nil
	HMB:SendMessage("HandyNotes_NotifyUpdate", "Mailboxes")
end

local function createWaypoint(mapFile,coord)
	local c, z = HandyNotes:GetCZ(mapFile)
	local x, y = HandyNotes:getXY(coord)
	if TomTom then
		TomTom:AddZWaypoint(c, z, x*100, y*100, "Mailbox")
	elseif Cartographer_Waypoints then
		Cartographer_Waypoints:AddWaypoint(NotePoint:new(HandyNotes:GetCZToZone(c, z), x, y, "Mailbox"))
	end
end

local function generateMenu(level)
	if (not level) then return end
	for k in pairs(info) do info[k] = nil end
	if (level == 1) then
		-- Create the title of the menu
		info.isTitle      = 1
		info.text         = "HandyNotes - Mailboxes"
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level)

		-- Delete menu item
		info.disabled     = nil
		info.isTitle      = nil
		info.notCheckable = nil
		info.text = "Delete mailbox"
		info.icon = icon
		info.func = deletePin
		info.arg1 = clickedMailboxZone
		info.arg2 = clickedMailbox
		UIDropDownMenu_AddButton(info, level);

		if TomTom or Cartographer_Waypoints then
			-- Waypoint menu item
			info.disabled     = nil
			info.isTitle      = nil
			info.notCheckable = nil
			info.text = "Create waypoint"
			info.icon = nil
			info.func = createWaypoint
			info.arg1 = clickedMailboxZone
			info.arg2 = clickedMailbox
			UIDropDownMenu_AddButton(info, level);
		end

		-- Close menu item
		info.text         = "Close"
		info.icon         = nil
		info.func         = CloseDropDownMenus
		info.arg1         = nil
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, level);
	end
end
local HMB_Dropdown = CreateFrame("Frame", "HandyNotes_MailboxesDropdownMenu")
HMB_Dropdown.displayMode = "MENU"
HMB_Dropdown.initialize = generateMenu

function HMBHandler:OnClick(button, down, mapFile, coord)
	if button == "RightButton" and not down then
		clickedMailboxZone = mapFile
		clickedMailbox = coord
		ToggleDropDownMenu(1, nil, HMB_Dropdown, self, 0, 0)
	end
end

function HMBHandler:OnLeave(mapFile, coord)
	if self:GetParent() == WorldMapButton then
		WorldMapTooltip:Hide()
	else
		GameTooltip:Hide()
	end
end

do
	-- This is a custom iterator we use to iterate over every node in a given zone
	local function iter(t, prestate)
		if not t then return nil end
		local state, value = next(t, prestate)
		while state do -- Have we reached the end of this zone?
			if value then
				return state, nil, icon, db.icon_scale, db.icon_alpha
			end
			state, value = next(t, state) -- Get next data
		end
		return nil, nil, nil, nil
	end
	function HMBHandler:GetNodes(mapFile)
		return iter, HMB.db.global.mailboxes[mapFile], nil
	end
end


---------------------------------------------------------
-- Core functions

function HMB:AddMailBox()
	local c,z,x,y = Astrolabe:GetCurrentPlayerPosition()
	if not c then return end
	local loc = HandyNotes:getCoord(x, y)
	local mapFile = HandyNotes:GetMapFile(c, z)
	if not mapFile then return end
	for coord,value in pairs(self.db.global.mailboxes[mapFile]) do
		if value then
			local x2,y2 = HandyNotes:getXY(coord)
			if Astrolabe:ComputeDistance(c,z,x,y,c,z,x2,y2) < 15 then
				self.db.global.mailboxes[mapFile][coord] = nil
			end
		end
	end
	self.db.global.mailboxes[mapFile][loc] = true
	self:SendMessage("HandyNotes_NotifyUpdate", "Mailboxes")
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
