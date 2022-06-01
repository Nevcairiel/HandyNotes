std = "lua51"
max_line_length = false
exclude_files = {
    ".luacheckrc"
}

ignore = {
    "211/_.*", -- Unused local variable starting with _
    "212", -- Unused argument
    "542", -- empty if branch
}

globals = {
    "HandyNotes",
    "HandyNotesWorldMapPinMixin",
    "HNData",
}

read_globals = {
    "geterrorhandler",
    "floor", "ceil",
    "strtrim",
    "tinsert",
    "wipe",

    -- Third Party addons/libraries
    "LibStub",
    "TomTom",

    -- API functions
    "C_Map",
    "CreateFrame",
    "GetBuildInfo",
    "IsAltKeyDown",
    "IsControlKeyDown",
    "IsShiftKeyDown",
    "MouseIsOver",

    -- FrameXML API
    "BackdropTemplateMixin",
    "CreateFromMixins",
    "CloseDropDownMenus",
    "MapCanvasDataProviderMixin",
    "MapCanvasPinMixin",
    "ToggleDropDownMenu",
    "UIDropDownMenu_AddButton",
    "UIDropDownMenu_EnableDropDown",
    "UIDropDownMenu_SetWidth",

    -- FrameXML Frames
    "GameTooltip",
    "Minimap",
    "RAID_TARGET_1",
    "RAID_TARGET_2",
    "RAID_TARGET_3",
    "RAID_TARGET_4",
    "RAID_TARGET_5",
    "RAID_TARGET_6",
    "RAID_TARGET_7",
    "RAID_TARGET_8",
    "UIParent",
    "UISpecialFrames",
    "WorldMapFrame",

    -- FrameXML Constants
    "Enum",
    "ARENA",
    "CANCEL",
    "CLOSE",
    "FACTION_ALLIANCE",
    "FACTION_HORDE",
    "FACTION_STANDING_LABEL4",
    "MINIMAP_TRACKING_AUCTIONEER",
    "MINIMAP_TRACKING_BANKER",
    "MINIMAP_TRACKING_BATTLEMASTER",
    "MINIMAP_TRACKING_FLIGHTMASTER",
    "MINIMAP_TRACKING_INNKEEPER",
    "MINIMAP_TRACKING_MAILBOX",
    "MINIMAP_TRACKING_REPAIR",
    "MINIMAP_TRACKING_STABLEMASTER",
    "MINIMAP_TRACKING_TRAINER_CLASS",
    "MINIMAP_TRACKING_TRAINER_PROFESSION",
    "MINIMAP_TRACKING_TRIVIAL_QUESTS",
    "MINIMAP_TRACKING_VENDOR_AMMO",
    "MINIMAP_TRACKING_VENDOR_FOOD",
    "MINIMAP_TRACKING_VENDOR_POISON",
    "MINIMAP_TRACKING_VENDOR_REAGENT",
    "OKAY",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_MAINLINE",
}
