---------------------------------------------------------
-- Module declaration
local HandyNotes = LibStub("AceAddon-3.0"):GetAddon("HandyNotes")
local HN = HandyNotes:GetModule("HandyNotes")
local L = LibStub("AceLocale-3.0"):GetLocale("HandyNotes", false)

local backdrop2 = {
	bgFile = nil,
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile = true, tileSize = 16, edgeSize = 16,
	insets = { left = 0, right = 0, top = 0, bottom = 0 },
}

-- Create the main frame
local HNEditFrame = CreateFrame("Frame", "HNEditFrame", UIParent) -- global the frame until i finish testing it.
HN.HNEditFrame = HNEditFrame
HNEditFrame:Hide()
HNEditFrame:SetWidth(350)
HNEditFrame:SetHeight(300)
HNEditFrame:SetPoint("BOTTOM", 0, 90)
HNEditFrame:SetBackdrop({ 
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
 	insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
--HNEditFrame:SetBackdropColor(0, 0, 0, 0.75)
HNEditFrame:SetBackdropColor(0,0,0,1)
HNEditFrame:EnableMouse(true)
HNEditFrame:SetToplevel(true)
HNEditFrame:SetClampedToScreen(true)
HNEditFrame:SetMovable(true)
HNEditFrame:SetFrameStrata("TOOLTIP")
HNEditFrame.titleTexture = HNEditFrame:CreateTexture(nil, "ARTWORK")
HNEditFrame.titleTexture:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
HNEditFrame.titleTexture:SetWidth(300)
HNEditFrame.titleTexture:SetHeight(64)
HNEditFrame.titleTexture:SetPoint("TOP", 0, 12)
HNEditFrame.titleTexture = temp
HNEditFrame.title = HNEditFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
HNEditFrame.title:SetPoint("TOP", 0, -3)
HNEditFrame.title:SetText("Add Handy Note")

-- This creates a transparent textureless draggable frame to move HNEditFrame
-- It overlaps the above title text and texture (more or less) exactly.
temp = CreateFrame("Frame", nil, HNEditFrame)
temp:SetWidth(150)
temp:SetHeight(30)
temp:SetPoint("TOP", 0, 8)
temp:EnableMouse(true)
temp:RegisterForDrag("LeftButton")
temp:SetScript("OnDragStart", function(self)
	self:GetParent():StartMoving()
end)
temp:SetScript("OnDragStop", function(self)
	self:GetParent():StopMovingOrSizing()
end)

-- Create the Close button
HNEditFrame.CloseButton = CreateFrame("Button", nil, HNEditFrame, "UIPanelCloseButton")
HNEditFrame.CloseButton:SetPoint("TOPRIGHT", -2, -1)
HNEditFrame.CloseButton:SetHitRectInsets(5, 5, 5, 5)

-- Create and position the Title text string
HNEditFrame.titletext = HNEditFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
HNEditFrame.titletext:SetPoint("TOPLEFT", 25, -28)
HNEditFrame.titletext:SetText("Title")

-- Create the Title Input Box and position it below the text
HNEditFrame.titleinputframe = CreateFrame("Frame", nil, HNEditFrame)
HNEditFrame.titleinputframe:SetWidth(300)
HNEditFrame.titleinputframe:SetHeight(24)
HNEditFrame.titleinputframe:SetBackdrop(backdrop2)
HNEditFrame.titleinputframe:SetPoint("TOPLEFT", HNEditFrame.titletext, "BOTTOMLEFT", 0, 0)
HNEditFrame.titleinputbox = CreateFrame("EditBox", nil, HNEditFrame.titleinputframe)
HNEditFrame.titleinputbox:SetWidth(290)
HNEditFrame.titleinputbox:SetHeight(24)
HNEditFrame.titleinputbox:SetMaxLetters(100)
HNEditFrame.titleinputbox:SetNumeric(false)
HNEditFrame.titleinputbox:SetAutoFocus(false)
HNEditFrame.titleinputbox:SetFontObject("GameFontHighlightSmall")
HNEditFrame.titleinputbox:SetPoint("TOPLEFT", 5, 1)
HNEditFrame.titleinputbox:SetScript("OnShow", HNEditFrame.titleinputbox.SetFocus)
HNEditFrame.titleinputbox:SetScript("OnEscapePressed", HNEditFrame.titleinputbox.ClearFocus)

-- Create and position the Description text string
HNEditFrame.desctext = HNEditFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
HNEditFrame.desctext:SetPoint("TOPLEFT", HNEditFrame.titleinputframe, "BOTTOMLEFT", 0, 0)
HNEditFrame.desctext:SetText("Description/Notes:")

-- Create the ScrollFrame for the Description Edit Box
HNEditFrame.descframe = CreateFrame("Frame", nil, HNEditFrame)
HNEditFrame.descframe:SetWidth(300)
HNEditFrame.descframe:SetHeight(60)
HNEditFrame.descframe:SetBackdrop(backdrop2)
HNEditFrame.descframe:SetPoint("TOPLEFT", HNEditFrame.desctext, "BOTTOMLEFT", 0, 0)
HNEditFrame.descscrollframe = CreateFrame("ScrollFrame", "HandyNotes_EditScrollFrame", HNEditFrame.descframe, "UIPanelScrollFrameTemplate")
HNEditFrame.descscrollframe:SetWidth(269)
HNEditFrame.descscrollframe:SetHeight(52)
HNEditFrame.descscrollframe:SetPoint("TOPLEFT", 5, -4)
-- Create the Description Input Box and position it below the text
HNEditFrame.descinputbox = CreateFrame("EditBox", nil, HNEditFrame)
HNEditFrame.descinputbox:SetWidth(269)
HNEditFrame.descinputbox:SetHeight(52)
HNEditFrame.descinputbox:SetMaxLetters(512)
HNEditFrame.descinputbox:SetNumeric(false)
HNEditFrame.descinputbox:SetAutoFocus(false)
HNEditFrame.descinputbox:SetFontObject("GameFontHighlightSmall")
HNEditFrame.descinputbox:SetMultiLine(true)
-- Attach the ScrollChild to the ScrollFrame
HNEditFrame.descscrollframe:SetScrollChild(HNEditFrame.descinputbox)

