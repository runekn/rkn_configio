RKN_Configio = {
    config = {
        textId = 1811143915,
        stationKey = "station",
        stationLoadoutKey = "station_loadout",
        shipKey = "ship",
        shipLoadoutKey = "ship_loadout",
        folderIdFormat = "rkn_configio.folder.%s.%s",
        settingsBlackboardId = "$RKN_ConfigioSettings",
        autoPresetsBlackboardId = "$RKN_ConfigioAutoPresets",
        loadWidthMultiplier = 0.85,
        maxFolders = 6,
        standardListColumnWidth = Helper.scaleY(Helper.standardTextHeight),
        shipNotOwnedColor = { r = 100, g = 100, b = 100, a = 100 }, -- dark grey
        stationLoadHeight = 0.5 * Helper.viewHeight,
        stationLoadoutLoadHeight = 0.35 * Helper.viewHeight,
        shipLoadHeight = 0.4 * Helper.viewHeight,
        loadSettingsWidth = Helper.scaleX(300),
        settingsBrowserSeparation = Helper.borderSize * 10,
        loadButtonTextProperties = {
            halign = "center",
            font = Helper.standardFont,
            fontsize = Helper.scaleFont(Helper.standardFont, Helper.standardFontSize),
        },
        browserHeaderTextProperties = {
            font = Helper.headerRow1Font,
            fontsize = Helper.headerRow1FontSize,
            x = Helper.headerRow1Offsetx,
            y = math.floor((Helper.headerRow1Height * 1.5 - Helper.headerRow1Height) / 2 + Helper.headerRow1Offsety),
            height = Helper.headerRow1Height * 1.5,
            halign = "center",
            cellBGColor = Color["row_background"],
            titleColor = Color["row_title"],
        },
        buttonRowTextProperties = {
            fontsize = Helper.standardFontSize * 1.2,
            halign = "center"
        },
        folderTextProperties = {
            font = Helper.titleFont,
            fontsize = Helper.standardFontSize,
            height = Helper.subHeaderHeight,
            cellBGColor = Color["row_background"],
            titleColor = { r = 128, g = 128, b = 128, a = 100 }
        },
        itemTextProperties = {
            height = math.floor(Helper.standardTextHeight + Helper.scaleY(1) * 2),
            y = math.floor(Helper.scaleY(1)),
        },
        inactiveColor = { r = 128, g = 128, b = 128, a = 100 }, -- dark gray
        autoPresetColor = { r = 225, g = 225, b = 0, a = 100 }, -- yellow
        partialPresetColor = { r = 255, g = 100, b = 0, a = 100 }, -- orange
        stationPlanMissingBlueprintsColor = { r = 255, g = 25, b = 25, a = 100 }, -- red
        settingSwitchActiveTextProperties = {
            font = Helper.standardFontBold,
            color = { r = 100, g = 225, b = 0, a = 100 }, -- green
            halign = "center"
        },
        settingSwitchInActiveTextProperties = {
            color = { r = 192, g = 192, b = 192, a = 100 }, -- light grey
            halign = "center"
        },
        shipSortOptions = {
            { id = "default", text = ReadText(1811143915, 92), displayremoveoption = false, icon = "" },
            { id = "name", text = ReadText(1811143915, 91), displayremoveoption = false, icon = "" },
            { id = "type", text = ReadText(1811143915, 105), displayremoveoption = false, icon = "" }
        },
        defaultSortOptions = {
            { id = "name", text = ReadText(1811143915, 91), displayremoveoption = false, icon = "" }
        },
        valueOptions = {
            { id = "low", text = ReadText(1811143915, 71), icon = "", displayremoveoption = false },
            { id = "medium", text = ReadText(1811143915, 72), icon = "", displayremoveoption = false },
            { id = "high", text = ReadText(1811143915, 73), icon = "", displayremoveoption = false }
        },
        dockingComputerOptions = {
            { id = "none", text = "None", icon = "", displayremoveoption = false },
            { id = "software_dockmk1", text = "Mk1", icon = "", displayremoveoption = false },
            { id = "software_dockmk2", text = "Mk2", icon = "", displayremoveoption = false }
        },
        longRangeScannerOptions = {
            { id = "software_scannerlongrangemk1", text = "Mk1", icon = "", displayremoveoption = false },
            { id = "software_scannerlongrangemk2", text = "Mk2", icon = "", displayremoveoption = false }
        },
        objectScannerOptions = {
            { id = "software_scannerobjectmk1", text = "Basic", icon = "", displayremoveoption = false },
            { id = "software_scannerobjectmk2", text = "Police", icon = "", displayremoveoption = false }
        },
        targetingComputerOptions = {
            { id = "none", text = "None", icon = "", displayremoveoption = false },
            { id = "software_targetmk1", text = "Mk1", icon = "", displayremoveoption = false }
        },
        tradingComputerOptions = {
            { id = "none", text = "None", icon = "", displayremoveoption = false },
            { id = "software_trademk1", text = "Mk1", icon = "", displayremoveoption = false }
        },
        shipSizeOrder = {
            ship_xl = 0,
            ship_l = 1,
            ship_m = 2,
            ship_s = 3,
            ship_xs = 4
        }
    }
}