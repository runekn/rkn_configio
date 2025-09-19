-- ffi setup 
local ffi = require("ffi")
local C = ffi.C

local function init()
	RegisterEvent("RKN_Configio.SetEnabled", function (_, key)
			RKN_Configio.setSetting("enabled", true, key)
		end
	)
	RegisterEvent("RKN_Configio.SetDisabled", function (_, key)
			RKN_Configio.setSetting("enabled", false, key)
		end
	)
	RegisterEvent("RKN_Configio.InitSettingsRequest", function ()
			AddUITriggeredEvent("RKN_Configio", "InitEnabledSettings", {
				[RKN_Configio.config.stationKey] = RKN_Configio.getSettings(RKN_Configio.config.stationKey).enabled,
				[RKN_Configio.config.stationLoadoutKey] = RKN_Configio.getSettings(RKN_Configio.config.stationLoadoutKey).enabled,
				[RKN_Configio.config.shipKey] = RKN_Configio.getSettings(RKN_Configio.config.shipKey).enabled,
				[RKN_Configio.config.shipLoadoutKey] = RKN_Configio.getSettings(RKN_Configio.config.shipLoadoutKey).enabled
			})
		end
	)
end

function RKN_Configio.createStationTitleBarButton(row, menu, sc_config, loadOptions)
	if RKN_Configio.isModEnabledForType(RKN_Configio.config.stationKey) then
		row[2]:createButton({ helpOverlayID = "open_constructionplan_browser", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height }):setText(ReadText(RKN_Configio.config.textId, 1), RKN_Configio.config.loadButtonTextProperties)
		row[2].handlers.onClick = function() RKN_Configio.buttonStationTitleLoad(menu, sc_config.contextLayer) end
	else
		row[2]:createDropDown(loadOptions, { textOverride = ReadText(1001, 7904), optionWidth = menu.titleData.dropdownWidth + menu.titleData.height + Helper.borderSize }):setTextProperties(sc_config.dropDownTextProperties)
		row[2].handlers.onDropDownActivated = function () menu.noupdate = true end
		row[2].handlers.onDropDownConfirmed = menu.dropdownLoad
		row[2].handlers.onDropDownRemoved = menu.dropdownRemovedCP
	end
end

function RKN_Configio.createRefreshStationTitleBarButton(menu, text, loadOptions)
	-- No need for refreshing if enabled --
	if not RKN_Configio.isModEnabledForType(RKN_Configio.config.stationKey) then
		local desc = Helper.createDropDown(loadOptions, "", text, nil, true, true, 0, 0, 0, 0, nil, nil, "", menu.titleData.dropdownWidth + menu.titleData.height + Helper.borderSize)
		Helper.setCellContent(menu, menu.titlebartable, desc, 1, 2, nil, "dropdown", nil, function () menu.noupdate = true end, menu.dropdownLoad, menu.dropdownRemovedCP)
	end
end

function RKN_Configio.createStationLoadoutTitleBarButton(row, menu, sc_config, loadoutOptions)
	if RKN_Configio.isModEnabledForType(RKN_Configio.config.stationLoadoutKey) then
		row[2]:setColSpan(6):createButton({ helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height }):setText(ReadText(RKN_Configio.config.textId, 22), RKN_Configio.config.loadButtonTextProperties)
		row[2].handlers.onClick = function() RKN_Configio.buttonStationLoadoutTitleLoad(menu, sc_config.contextLayer) end
	else
		row[2]:setColSpan(6):createDropDown(loadoutOptions, { textOverride = ReadText(1001, 7905), optionWidth = menu.titleData.dropdownWidth + 6 * (menu.titleData.height + Helper.borderSize) }):setTextProperties(sc_config.dropDownTextProperties)
		row[2].handlers.onDropDownConfirmed = menu.dropdownLoadout
		row[2].handlers.onDropDownRemoved = menu.dropdownRemovedLoadout
	end
end

function RKN_Configio.createRefreshStationLoadoutTitleBarButton(menu, text, loadoutOptions)
	-- No need for refreshing if enabled --
	if not RKN_Configio.isModEnabledForType(RKN_Configio.config.stationKey) then
		local desc = Helper.createDropDown(loadoutOptions, "", text, nil, true, next(menu.loadouts) ~= nil, 0, 0, 0, 0, nil, nil, "", menu.titleData.dropdownWidth + 4 * (menu.titleData.height + Helper.borderSize))
		Helper.setCellContent(menu, menu.titlebartable, desc, 1, 2, nil, "dropdown", nil, nil, menu.dropdownLoadout, menu.dropdownRemovedLoadout)
	end
end

function RKN_Configio.createShipTitleBarButton(row, menu, sc_config, classOptions, shipOptions, curShipOption)
	if RKN_Configio.isModEnabledForType(RKN_Configio.config.shipKey) and menu.mode ~= "upgrade" then
		local shipOptions = RKN_Configio.createShipOptions(menu)
		local dropdownDummy = { properties = { text = { }, icon = {} } }
		local text = ReadText(RKN_Configio.config.textId, 30)
		local mouseOverText = ""
		if menu.macro and menu.macro ~= "" then
			for _,o in ipairs(shipOptions) do
				if o.id == menu.macro then
					text = o.text
					mouseOverText = o.mouseovertext
					break
				end
			end
		end
		if (menu.mode == "purchase") and (menu.macro ~= "") and (not menu.validLicence) then
			local haslicence, icon, overridecolor, mouseovertext = menu.checkLicence(menu.macro, true)
			text = Helper.convertColorToText(overridecolor) .. text
		end
		row[1]:setColSpan(2):createButton({ active = not menu.isReadOnly, height = menu.titleData.height, mouseOverText = mouseOverText }):setText(text, RKN_Configio.config.loadButtonTextProperties)
		row[1].handlers.onClick = function() RKN_Configio.buttonShipTitleLoad(menu, classOptions, shipOptions, sc_config.contextLayer) end
		return dropdownDummy
	else
		-- class
		row[1]:createDropDown(classOptions, { startOption = menu.class, active = (not menu.isReadOnly) and (#classOptions > 0), helpOverlayID = "shipconfig_classoptions", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setTextProperties(sc_config.dropDownTextProperties)
		row[1].handlers.onDropDownConfirmed = menu.dropdownShipClass
		-- ships
		local dropDownIconProperties = {
			width = menu.titleData.height / 2,
			height = menu.titleData.height / 2,
			x = sc_config.dropdownRatios.ship * menu.titleData.dropdownWidth - 1.5 * menu.titleData.height,
			y = 0,
			scaling = false,
		}
		local dropdown = row[2]:createDropDown(shipOptions, { startOption = curShipOption, active = (not menu.isReadOnly) and (menu.class ~= ""), optionHeight = (menu.statsTableOffsetY or Helper.viewHeight) - menu.titleData.offsetY - Helper.frameBorder, helpOverlayID = "shipconfig_shipoptions", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setTextProperties(sc_config.dropDownTextProperties):setIconProperties(dropDownIconProperties)
		row[2].properties.text.halign = "left"
		row[2].handlers.onDropDownConfirmed = menu.dropdownShip
		return dropdown
	end
end

function RKN_Configio.createShipLoadoutTitleBarButton(row, menu, sc_config, active, loadoutOptions)
	if RKN_Configio.isModEnabledForType(RKN_Configio.config.shipLoadoutKey) then
		row[3]:createButton({ active = (not menu.isReadOnly) and active and ((menu.object ~= 0) or (menu.macro ~= "")) and (next(menu.loadouts) ~= nil), height = menu.titleData.height, width = menu.titleData.dropdownWidth + menu.titleData.height + Helper.borderSize, mouseOverText = (menu.mode == "customgamestart") and (ColorText["text_warning"] .. ReadText(1026, 8022)) or "" }):setText(ReadText(1001, 7905), RKN_Configio.config.loadButtonTextProperties)
		row[3].handlers.onClick = function() RKN_Configio.buttonShipLoadoutTitleLoad(menu, sc_config.contextLayer) end
	else
		row[3]:createDropDown(loadoutOptions, { textOverride = ReadText(1001, 7905), active = (not menu.isReadOnly) and active and ((menu.object ~= 0) or (menu.macro ~= "")) and (next(menu.loadouts) ~= nil), optionWidth = menu.titleData.dropdownWidth + menu.titleData.height + Helper.borderSize, optionHeight = (menu.statsTableOffsetY or Helper.viewHeight) - menu.titleData.offsetY - Helper.frameBorder, mouseOverText = (menu.mode == "customgamestart") and (ColorText["text_warning"] .. ReadText(1026, 8022)) or "" }):setTextProperties(sc_config.dropDownTextProperties)
		row[3].handlers.onDropDownConfirmed = menu.dropdownLoadout
		row[3].handlers.onDropDownRemoved = menu.dropdownLoadoutRemoved
	end
end

function RKN_Configio.isModEnabledForType(type)
	return RKN_Configio.getSettings(type).enabled
end

function RKN_Configio.buttonStationTitleLoad(menu, contextLayer)
	if menu.contextMode and (menu.contextMode.mode == "loadCP") then
		menu.closeContextMenu()
	else
		menu.displayContextFrame("loadCP", menu.titleData.width * RKN_Configio.config.loadWidthMultiplier, menu.titleData.offsetX + (menu.titleData.width * (1 - RKN_Configio.config.loadWidthMultiplier) / 2), menu.titleData.offsetY + menu.titleData.height + Helper.borderSize)
		RKN_Configio.params = {
			settingKey = RKN_Configio.config.stationKey,
			x = menu.contextMode.x,
			y = menu.contextMode.y,
			width = menu.contextMode.width,
			height = RKN_Configio.config.stationLoadHeight,
			itemsList = function() return RKN_Configio.addStationPlanMouseover(RKN_Configio_Utils.DeepCopy(menu.constructionplans)) end,
			header = ReadText(RKN_Configio.config.textId, 2),
			optionItemNameText = ReadText(RKN_Configio.config.textId, 9),
			onSelection = function(item) menu.dropdownLoad(nil, item.id) end,
			onDeletion = function(item)
				RKN_Configio.buttonDeleteCP(menu, item.id)
			end,
			listColumnWidth = RKN_Configio.config.standardListColumnWidth,
			listItemCreator = RKN_Configio.createCommonListItem,
			maxFolders = RKN_Configio.config.maxFolders,
			itemFilter = RKN_Configio.filterItemByModules,
			contextLayer = contextLayer,
			closeContextMenu = menu.closeContextMenu,
			contextMode = menu.contextMode,
			setContextFrame = function(f) menu.contextFrame = f end,
			menu = menu,
			isItemActive = function(item) return item.active end,
			frameModules = { RKN_Configio.createSettings, RKN_Configio.createSearchField, RKN_Configio.createCPModulesFilter },
			sortItems = RKN_Configio.compareItemNames,
			sortOptions = RKN_Configio.config.defaultSortOptions,
			sortDefault = "name",
			onSave = function(name, overwrite)
				menu.currentCPName = name
				menu.buttonSave(overwrite)
			end,
			isItemSavable = function(item) return true end
		}
		RKN_Configio.autoSelectSearch = true
		RKN_Configio.contextModule = nil
		RKN_Configio.createLoadContext()
	end
end

function RKN_Configio.buttonStationLoadoutTitleLoad(menu, contextLayer)
	if menu.contextMode and (menu.contextMode.mode == "loadCL") then
		menu.closeContextMenu()
	else
		menu.displayContextFrame("loadCL", menu.titleData.width * RKN_Configio.config.loadWidthMultiplier, menu.titleData.offsetX + (menu.titleData.width * (1 - RKN_Configio.config.loadWidthMultiplier) / 2), menu.titleData.offsetY + menu.titleData.height + Helper.borderSize)
		RKN_Configio.params = {
			settingKey = RKN_Configio.config.stationLoadoutKey,
			x = menu.contextMode.x,
			y = menu.contextMode.y,
			width = menu.contextMode.width,
			height = RKN_Configio.config.stationLoadoutLoadHeight,
			itemsList = function() return RKN_Configio.addPartialFlag(RKN_Configio.addCustomAutoPresets(RKN_Configio.config.stationLoadoutKey, RKN_Configio_Utils.DeepCopy(menu.loadouts))) end,
			header = ReadText(RKN_Configio.config.textId, 22),
			optionItemNameText = ReadText(RKN_Configio.config.textId, 24),
			onSelection = function(item)
				menu.closeContextMenu()
				RKN_Configio.onStationLoadoutLoad(menu, item)
			end,
			onDeletion = function(item)
				menu.closeContextMenu()
				RKN_Configio.onLoadoutRemoved(menu.dropdownRemovedLoadout, item)
			end,
			listColumnWidth = RKN_Configio.config.standardListColumnWidth,
			listItemCreator = RKN_Configio.createCommonListItem,
			maxFolders = RKN_Configio.config.maxFolders,
			contextLayer = contextLayer,
			closeContextMenu = menu.closeContextMenu,
			contextMode = menu.contextMode,
			setContextFrame = function(f) menu.contextFrame = f end,
			menu = menu,
			addToSettingsTable = nil,
			itemFilter = nil,
			isItemActive = function(item) return item.active or (item.preset and true or false) end,
			getItemColor = function(item)
				if item.item.preset or item.item.customPreset then
					return RKN_Configio.config.autoPresetColor
				elseif item.item.partial then
					return RKN_Configio.config.partialPresetColor
				end
				return nil
			end,
			onOpenPresetEditor = function() RKN_Configio.buttonStationLoadoutTitleAutoPresets(menu, contextLayer) end,
			frameModules = {
				RKN_Configio.createSettings,
				RKN_Configio.createSearchField,
				function(s) RKN_Configio.createAutoPresetEditorButtons(s) end
			},
			sortItems = RKN_Configio.compareItemNames,
			sortOptions = RKN_Configio.config.defaultSortOptions,
			sortDefault = "name",
			isItemRenamable = function(item) return not item.preset end,
			onRename = function(item, newName) RKN_Configio.renameStationLoadout(menu, item, newName) end,
			onSave = function(name, overwrite)
				menu.loadoutName = name
				menu.loadout = nil
				menu.checkLoadoutNameID() -- Will update menu.loadout
				menu.buttonSaveLoadout(overwrite)
			end,
			isItemSavable = function(item) return (not item.preset) and not item.customPreset end
		}
		RKN_Configio.autoSelectSearch = true
		RKN_Configio.contextModule = nil
		RKN_Configio.createLoadContext()
	end
end

function RKN_Configio.buttonShipTitleLoad(menu, classOptions, shipOptions, contextLayer)
	if menu.contextMode and (menu.contextMode.mode == "loadCS") then
		menu.closeContextMenu()
	else
		menu.displayContextFrame("loadCS", menu.titleData.width * RKN_Configio.config.loadWidthMultiplier, menu.titleData.offsetX + (menu.titleData.width * (1 - RKN_Configio.config.loadWidthMultiplier) / 2), menu.titleData.offsetY + menu.titleData.height + Helper.borderSize)
		local shipPurposeOptions = RKN_Configio.getShipPurposes(shipOptions)
		local shipRaceOptions = RKN_Configio.getShipRaces(shipOptions)
		RKN_Configio.params = {
			settingKey = RKN_Configio.config.shipKey,
			x = menu.contextMode.x,
			y = menu.contextMode.y,
			width = menu.contextMode.width,
			height = RKN_Configio.config.shipLoadHeight,
			itemsList = function() return shipOptions end,
			header = ReadText(RKN_Configio.config.textId, 30),
			onSelection = function(item)
				menu.closeContextMenu()
				menu.prepareModWares()
				menu.dropdownShip(nil, item.id)
			end,
			listColumnWidth = Helper.scaleY(Helper.standardTextHeight) * 1.5,
			listItemCreator = function(row, column, item) RKN_Configio.createShipListItem(row, column, item, menu.isplayerowned) end,
			contextLayer = contextLayer,
			closeContextMenu = menu.closeContextMenu,
			contextMode = menu.contextMode,
			setContextFrame = function(f) menu.contextFrame = f end,
			menu = menu,
			itemFilter = RKN_Configio.filterShip,
			isItemActive = function(_) return true end,
			getItemColor = function(item) return item.item.overridecolor end,
			frameModules = { RKN_Configio.createSearchField, function(stable) RKN_Configio.createShipFilters(stable, classOptions, shipPurposeOptions, shipRaceOptions) end },
			sortItems = RKN_Configio.sortShips,
			sortOptions = RKN_Configio.config.shipSortOptions,
			sortDefault = "default"
		}
		RKN_Configio.autoSelectSearch = true
		RKN_Configio.contextModule = nil
		RKN_Configio.clearFilterIfNotAvailable(RKN_Configio.getState().filter.sizes, classOptions)
		RKN_Configio.clearFilterIfNotAvailable(RKN_Configio.getState().filter.purposes, shipPurposeOptions)
		RKN_Configio.clearFilterIfNotAvailable(RKN_Configio.getState().filter.races, shipRaceOptions)
		RKN_Configio.createLoadContext()
	end
end

function RKN_Configio.buttonShipLoadoutTitleLoad(menu, contextLayer)
	if menu.contextMode and (menu.contextMode.mode == "loadCL") then
		menu.closeContextMenu()
	else
		menu.displayContextFrame("loadCL", menu.titleData.width * RKN_Configio.config.loadWidthMultiplier, menu.titleData.offsetX + (menu.titleData.width * (1 - RKN_Configio.config.loadWidthMultiplier) / 2), menu.titleData.offsetY + menu.titleData.height + Helper.borderSize)
		RKN_Configio.params = {
			settingKey = RKN_Configio.config.shipLoadoutKey,
			x = menu.contextMode.x,
			y = menu.contextMode.y,
			width = menu.contextMode.width,
			height = RKN_Configio.config.stationLoadoutLoadHeight,
			itemsList = function() return RKN_Configio.addPartialFlag(RKN_Configio.addCustomAutoPresets(RKN_Configio.config.shipLoadoutKey, RKN_Configio_Utils.DeepCopy(menu.loadouts))) end,
			header = ReadText(RKN_Configio.config.textId, 22),
			optionItemNameText = ReadText(RKN_Configio.config.textId, 24),
			onSelection = function(item)
				menu.closeContextMenu()
				RKN_Configio.onShipLoadoutLoad(menu, item)
			end,
			maxFolders = RKN_Configio.config.maxFolders,
			onDeletion = function(item)
				menu.closeContextMenu()
				RKN_Configio.onLoadoutRemoved(menu.dropdownLoadoutRemoved, item)
			end,
			listColumnWidth = RKN_Configio.config.standardListColumnWidth,
			listItemCreator = RKN_Configio.createCommonListItem,
			contextLayer = contextLayer,
			closeContextMenu = menu.closeContextMenu,
			contextMode = menu.contextMode,
			setContextFrame = function(f) menu.contextFrame = f end,
			menu = menu,
			isItemActive = function(item) return item.active or (item.preset and true or false) end,
			getItemColor = function(item)
				if item.item.preset or item.item.customPreset then
					return RKN_Configio.config.autoPresetColor
				elseif item.item.partial then
					return RKN_Configio.config.partialPresetColor
				end
				return nil
			end,
			onOpenPresetEditor = function() RKN_Configio.buttonShipLoadoutTitleAutoPresets(menu, contextLayer) end,
			frameModules = {
				RKN_Configio.createSettings,
				RKN_Configio.createSearchField,
				function(s) RKN_Configio.createAutoPresetEditorButtons(s) end
			},
			sortItems = RKN_Configio.compareItemNames,
			sortOptions = RKN_Configio.config.defaultSortOptions,
			sortDefault = "name",
			isItemRenamable = function(item) return not item.preset end,
			onRename = function(item, newName) RKN_Configio.renameShipLoadout(menu, item, newName) end,
			onSave = function(name, overwrite)
				menu.loadoutName = name
				menu.loadout = nil
				menu.checkLoadoutNameID() -- Will update menu.loadout
				menu.buttonSave(overwrite)
			end,
			isItemSavable = function(item) return (not item.preset) and not item.customPreset end
		}
		RKN_Configio.autoSelectSearch = true
		RKN_Configio.contextModule = nil
		RKN_Configio.createLoadContext()
	end
end

function RKN_Configio.buttonStationLoadoutTitleAutoPresets(menu, contextLayer)
	if menu.contextMode and (menu.contextMode.mode == "autoPreset") then
		menu.closeContextMenu()
	else
		menu.displayContextFrame("autoPreset", menu.titleData.width * RKN_Configio.config.loadWidthMultiplier, menu.titleData.offsetX + (menu.titleData.width * (1 - RKN_Configio.config.loadWidthMultiplier) / 2), menu.titleData.offsetY + menu.titleData.height + Helper.borderSize)
		local allMTurrets, allLTurrets = RKN_Configio.getAllTurrets()
		local allSShields, allMShields, allLShields, allXLShields = RKN_Configio.getAllShields()
		RKN_Configio.params = {
			settingKey = RKN_Configio.config.stationLoadoutKey,
			x = menu.contextMode.x,
			y = menu.contextMode.y,
			width = menu.contextMode.width,
			height = RKN_Configio.config.stationLoadoutLoadHeight,
			contextLayer = contextLayer,
			closeContextMenu = menu.closeContextMenu,
			contextMode = menu.contextMode,
			setContextFrame = function(f) menu.contextFrame = f end,
			menu = menu,
			editorShipLoadout = false,
			onSave = function() RKN_Configio.buttonStationLoadoutTitleLoad(menu, contextLayer) end,
			weaponsOptions = RKN_Configio.getAllWeapons(),
			mTurretOptions = allMTurrets,
			lTurretOptions = allLTurrets,
			sShieldsOptions = allSShields,
			mShieldOptions = allMShields,
			lShieldOptions = allLShields
		}
		RKN_Configio.createAutoPresetEditorContext()
	end
end

function RKN_Configio.buttonShipLoadoutTitleAutoPresets(menu, contextLayer)
	if menu.contextMode and (menu.contextMode.mode == "autoPreset") then
		menu.closeContextMenu()
	else
		menu.displayContextFrame("autoPreset", menu.titleData.width * RKN_Configio.config.loadWidthMultiplier, menu.titleData.offsetX + (menu.titleData.width * (1 - RKN_Configio.config.loadWidthMultiplier) / 2), menu.titleData.offsetY + menu.titleData.height + Helper.borderSize)
		local allMTurrets, allLTurrets = RKN_Configio.getAllTurrets()
		local allSShields, allMShields, allLShields, allXLShields = RKN_Configio.getAllShields()
		RKN_Configio.params = {
			settingKey = RKN_Configio.config.shipLoadoutKey,
			x = menu.contextMode.x,
			y = menu.contextMode.y,
			width = menu.contextMode.width,
			height = RKN_Configio.config.stationLoadHeight,
			contextLayer = contextLayer,
			closeContextMenu = menu.closeContextMenu,
			contextMode = menu.contextMode,
			setContextFrame = function(f) menu.contextFrame = f end,
			menu = menu,
			editorShipLoadout = true,
			onSave = function() RKN_Configio.buttonShipLoadoutTitleLoad(menu, contextLayer) end,
			mTurretOptions = allMTurrets,
			lTurretOptions = allLTurrets,
			sShieldsOptions = allSShields,
			mShieldOptions = allMShields,
			lShieldOptions = allLShields,
			xlShieldOptions = allXLShields,
			engineOptions = RKN_Configio.getAllEngines(),
			thrusterOptions = RKN_Configio.getAllThrusters(),
			weaponOptions = RKN_Configio.getAllWeapons()
		}
		RKN_Configio.createAutoPresetEditorContext()
	end
end

function RKN_Configio.createLoadContext()
	local listRoot = RKN_Configio.prepareBrowserStructure(RKN_Configio.params.itemsList())

	Helper.removeAllWidgetScripts(RKN_Configio.params.menu, RKN_Configio.params.contextLayer)

	local contextFrame = Helper.createFrameHandle(RKN_Configio.params.menu, {
		layer = RKN_Configio.params.contextLayer,
		standardButtons = {},
		width = RKN_Configio.params.width,
		x = RKN_Configio.params.x,
		y = RKN_Configio.params.y,
		autoFrameHeight = true,
	})
	RKN_Configio.params.setContextFrame(contextFrame)
	contextFrame:setBackground("solid", { color = Color["frame_background_semitransparent"] })

	local smallColWidth = Helper.scaleY(Helper.standardTextHeight)
	local settingsWidth = RKN_Configio.params.width * RKN_Configio.config.loadSettingsWidthMultipler
	local browserWidth = RKN_Configio.params.width - settingsWidth - Helper.borderSize * 2 - RKN_Configio.config.settingsBrowserSeparation
	local browserX = settingsWidth + Helper.borderSize + RKN_Configio.config.settingsBrowserSeparation
	local buttonRowHeight = Helper.standardButtonHeight * 1.2

	-- Create item list --
	RKN_Configio.getState().listColumns = math.min(math.floor((browserWidth - Helper.scrollbarWidth) / RKN_Configio.params.listColumnWidth), 12) -- max 13 columns allowed in a table...
	local ltable = contextFrame:addTable(RKN_Configio.getState().listColumns + 1, { wraparound = true, tabOrder = 6, reserveScrollBar = true, maxVisibleHeight = RKN_Configio.params.height - buttonRowHeight, x = browserX, width = browserWidth })
	for column = 1, RKN_Configio.getState().listColumns do
		ltable:setColWidth(column, RKN_Configio.params.listColumnWidth, false)
	end
	RKN_Configio.ltable = ltable
	ltable:addEmptyRow(RKN_Configio.config.browserHeaderTextProperties.height)
	local row = ltable:addRow(false, { fixed = true, bgColor = RKN_Configio.config.browserHeaderTextProperties.titleColor } )
	row[1]:setColSpan(2):createText("", { height = 3 } )
	RKN_Configio_Utils.AddFixedEmptyRow(ltable, Helper.standardTextHeight / 3)

	RKN_Configio.addFolderToList(ltable, listRoot, 1)

	-- Create list buttons --
	local btable = contextFrame:addTable(5, { tabOrder = 5, reserveScrollBar = false, highlightMode = "off", y = RKN_Configio.params.height - buttonRowHeight, x = browserX, width = browserWidth })
	RKN_Configio.btable = btable
	local row = btable:addRow(true, { fixed = true })
	RKN_Configio.setRowButtonText(row[1]:createButton({ active = RKN_Configio.isRowValidForLoad, height = buttonRowHeight }), "\27[menu_import] ", ReadText(RKN_Configio.config.textId, 3), RKN_Configio.config.buttonRowTextProperties)
	row[1].handlers.onClick = RKN_Configio.buttonLoadItem
	RKN_Configio.setRowButtonText(row[2]:createButton({ active = RKN_Configio.isRowValidForSave, height = buttonRowHeight }), "\27[menu_save]", ReadText(RKN_Configio.config.textId, 97), RKN_Configio.config.buttonRowTextProperties)
	row[2].handlers.onClick = RKN_Configio.buttonSaveItem
	RKN_Configio.setRowButtonText(row[3]:createButton({ active = RKN_Configio.isRowValidForRename, height = buttonRowHeight }), "\27[menu_edit] ", ReadText(RKN_Configio.config.textId, 98), RKN_Configio.config.buttonRowTextProperties)
	row[3].handlers.onClick = RKN_Configio.buttonRenameItem
	if RKN_Configio.params.settingKey == RKN_Configio.config.stationKey then
		row[3].properties.mouseOverText = ReadText(RKN_Configio.config.textId, 99)
	end
	RKN_Configio.setRowButtonText(row[4]:createButton({ active = RKN_Configio.isRowValidForDeletion, height = buttonRowHeight }), "\27[menu_dismiss] ", ReadText(RKN_Configio.config.textId, 4), RKN_Configio.config.buttonRowTextProperties)
	row[4].handlers.onClick = RKN_Configio.buttonDeleteItem
	RKN_Configio.setRowButtonText(row[5]:createButton({ height = buttonRowHeight }), "\27[widget_cross_01] ", ReadText(RKN_Configio.config.textId, 5), RKN_Configio.config.buttonRowTextProperties)
	row[5].handlers.onClick = RKN_Configio.params.closeContextMenu

	-- Create expand/collapse all buttons --
	local etable = contextFrame:addTable(4, { tabOrder = 5, x = browserX, y = RKN_Configio.config.browserHeaderTextProperties.y, width = browserWidth })
	etable:setColWidth(1, smallColWidth, false)
	etable:setColWidth(2, smallColWidth, false)
	etable:setColWidth(3, smallColWidth * 7, false)
	local row = etable:addRow(true, { })
	row[1]:createButton({ mouseOverText = ReadText(RKN_Configio.config.textId, 20), active = foldersActive }):setText("+", { halign = "center" })
	row[1].handlers.onClick = function() RKN_Configio.buttonExpandAll(listRoot) end
	row[2]:createButton({ mouseOverText = ReadText(RKN_Configio.config.textId, 21), active = foldersActive }):setText("-", { halign = "center" })
	row[2].handlers.onClick = RKN_Configio.buttonCollapseAll
	-- Create sorting dropdown
	row[3]:createDropDown(RKN_Configio.params.sortOptions, { startOption = RKN_Configio.getState().sort or RKN_Configio.params.sortDefault, mouseOverText = ReadText(RKN_Configio.config.textId, 93), active = #RKN_Configio.params.sortOptions > 1 })
	row[3].handlers.onDropDownConfirmed = RKN_Configio.dropdownSort
	row[4]:createText(RKN_Configio.params.header, { font = RKN_Configio.config.browserHeaderTextProperties.font, fontsize = RKN_Configio.config.browserHeaderTextProperties.fontSize })

	-- Create settings list --
	local stable = contextFrame:addTable(2, { tabOrder = 6, maxVisibleHeight = RKN_Configio.params.height, x = Helper.borderSize, width = settingsWidth - Helper.borderSize * 2 })
	stable:setColWidth(1, settingsWidth * 0.7, false)

	for _, frameModule in ipairs(RKN_Configio.params.frameModules) do
		frameModule(stable)
	end

	if RKN_Configio.contextModule ~= nil then
		RKN_Configio.contextModule(contextFrame, RKN_Configio.params.height + Helper.standardButtonHeight)
	end

	if RKN_Configio.getState().topRow then
		ltable:setTopRow(RKN_Configio.getState().topRow.listTable)
		stable:setTopRow(RKN_Configio.getState().topRow.settingsTable)
	end
	ltable:setSelectedRow(RKN_Configio.getState().selectedRow)

	contextFrame:display()
end

function RKN_Configio.addFolderToList(ltable, root, column)
	for _, folder in ipairs(root.folders_arr) do
		local row = ltable:addRow(folder, {  })
		local isextended = RKN_Configio.getState().expandedFolders[RKN_Configio.config.folderIdFormat:format(RKN_Configio.params.settingKey, folder.fullname)]
		row[column]:createButton({ helpOverlayID = folder.fullname, helpOverlayText = " ",  helpOverlayHighlightOnly = true }):setText(isextended and "-" or "+", { halign = "center" })
		row[column].handlers.onClick = function () return RKN_Configio.buttonExtendListEntry(folder.fullname, row.index) end
		local text = RKN_Configio.getSettings().folder_fullname and folder.fullname or folder.name
		row[column + 1]:setColSpan(RKN_Configio.getState().listColumns - column + 1):createText(text, RKN_Configio.config.folderTextProperties)
		if isextended then
			RKN_Configio.addFolderToList(ltable, folder, column + 1)
		end
	end

	for _, item in ipairs(root.items) do
		local row = ltable:addRow(item, {  })
		RKN_Configio.params.listItemCreator(row, column, item)
	end
end

function RKN_Configio.createCommonListItem(row, column, item)
	local text = RKN_Configio.getSettings().item_fullname and item.item.name or item.name
	local color
	if not item.active then
		color = RKN_Configio.config.inactiveColor
	elseif RKN_Configio.params.getItemColor then
		color = RKN_Configio.params.getItemColor(item)
	end
	if color then
		text = Helper.convertColorToText(color) .. text
	end
	row[column]:setColSpan(RKN_Configio.getState().listColumns - column + 2):createText(text, RKN_Configio.config.itemTextProperties)
	row[column].properties.mouseOverText = item.item.mouseovertext
end

function RKN_Configio.createShipListItem(row, column, item, isplayershipyard)
	local text = RKN_Configio.getSettings().item_fullname and item.item.name or item.name
	local color
	if RKN_Configio.params.getItemColor then
		color = RKN_Configio.params.getItemColor(item)
	end
	if color then
		text = Helper.convertColorToText(color) .. text
	end
	if not isplayershipyard then
		local blueprintIcon = item.item.hasBlueprint and "\27[rkn_configio_blueprint]" or Helper.convertColorToText(RKN_Configio.config.shipNotOwnedColor) .. "\27[rkn_configio_no_blueprint]"
		row[column]:createText(blueprintIcon, RKN_Configio.config.itemTextProperties)
		row[column].properties.mouseOverText = item.item.hasBlueprint and ReadText(RKN_Configio.config.textId, 102) or ReadText(RKN_Configio.config.textId, 103)
		column = column + 1
	end
	if RKN_Configio.getState().listColumns > 11 then
		row[11]:setColSpan(3):createText(item.item.shiptypename, RKN_Configio.config.itemTextProperties)
	else
		text = text .. " (" .. item.item.shiptypename .. ")"
	end
	row[column]:createText("\27[" .. item.item.shipicon .. "]", RKN_Configio.config.itemTextProperties)
	row[column + 1]:setColSpan(11 - (column + 1)):createText(text, RKN_Configio.config.itemTextProperties)
	row[column + 1].properties.mouseOverText = item.item.mouseovertext
end

function RKN_Configio.createSettings(stable)
	local row = stable:addRow(false, { fixed = true })
	row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 6), RKN_Configio.config.browserHeaderTextProperties)

	local row = RKN_Configio.createSettingsSwitch(stable, ReadText(RKN_Configio.config.textId, 7), "folder_enabled", true)
	row[1].properties.mouseOverText = ReadText(RKN_Configio.config.textId, 13)

	stable:addEmptyRow(Helper.standardTextHeight / 4)

	local foldersActive = RKN_Configio.getSettings().folder_enabled
	local row = stable:addRow(true, { fixed = true })
	row[1]:createText(ReadText(RKN_Configio.config.textId, 8), { color = (not foldersActive) and Color["text_inactive"] or nil })
	row[1].properties.mouseOverText = ReadText(RKN_Configio.config.textId, 12)
	local delimiterEditBoxText = RKN_Configio.getSettings().folder_delimiter:gsub(" ", "(space)") -- Replace spaces with '(space)' so that it is easier to read
	row[2]:createEditBox({ scaling = true, height = Helper.standardButtonHeight }):setText(delimiterEditBoxText, { })
	row[2].handlers.onEditBoxDeactivated = function(_, text, textchanged)
		if textchanged then
			text = text:gsub("(space)", " ")
			if text:len() > 1 then
				text = text:sub(1, 1)
			end
			RKN_Configio.setSetting("folder_delimiter", text)
			RKN_Configio.refreshLoadFrame()
		end
	end
	row[2].properties.active = foldersActive

	RKN_Configio.createSettingsSwitch(stable, RKN_Configio.params.optionItemNameText, "item_fullname", foldersActive)

	RKN_Configio.createSettingsSwitch(stable, ReadText(RKN_Configio.config.textId, 10), "folder_fullname", foldersActive)

	local row = RKN_Configio.createSettingsSwitch(stable, ReadText(RKN_Configio.config.textId, 11), "folder_flatten_single_item", foldersActive)
	row[1].properties.mouseOverText = ReadText(RKN_Configio.config.textId, 14)

	stable:addEmptyRow(Helper.standardTextHeight / 2)

	RKN_Configio.createSettingsSwitch(stable, ReadText(RKN_Configio.config.textId, 33), "item_hide_inactive", true)

	if RKN_Configio.params.settingKey == RKN_Configio.config.shipLoadoutKey or RKN_Configio.params.settingKey == RKN_Configio.config.stationLoadoutKey then
		local row = RKN_Configio.createSettingsSwitch(stable, ReadText(RKN_Configio.config.textId, 89), "item_load_partial", true)
		row[1].properties.mouseOverText = ReadText(RKN_Configio.config.textId, 90)
	end
end

function RKN_Configio.createSettingsSwitch(stable, text, setting, active)
	local checked = RKN_Configio.getSettings()[setting]
	local row = stable:addRow(true, { fixed = true })
	row[1]:createText(text, { color = (not active) and Color["text_inactive"] or nil })
	row[2]:createButton({ active = active }):setText(checked and ReadText(RKN_Configio.config.textId, 100) or ReadText(RKN_Configio.config.textId, 101), checked and RKN_Configio.config.settingSwitchActiveTextProperties or RKN_Configio.config.settingSwitchInActiveTextProperties)
	row[2].handlers.onClick = function()
		if active then
			RKN_Configio.setSetting(setting, not checked)
			RKN_Configio.refreshLoadFrame()
		end
	end
	return row
end

function RKN_Configio.createSearchField(stable)
	-- Search bar --
	local row = stable:addRow(false, { fixed = true })
	row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 15), RKN_Configio.config.browserHeaderTextProperties)

	local row = stable:addRow(true, { fixed = true })
	local editBox = row[1]:createEditBox({ scaling = true, height = Helper.standardButtonHeight }):setText(RKN_Configio.getState().filter.search, { })
	row[1].handlers.onEditBoxDeactivated = RKN_Configio.searchItemEdit
	row[2]:createButton({  }):setText(ReadText(RKN_Configio.config.textId, 16), { halign = "center" })
	row[2].handlers.onClick = function () RKN_Configio.searchItemEdit(nil, "", true) end
	if RKN_Configio.autoSelectSearch then
		-- This will cause the editbox to be automatically activated --
		RKN_Configio.params.contextMode.nameEditBox = editBox
	end
end

function RKN_Configio.createCPModulesFilter(stable)
	local row = stable:addRow(false, { fixed = true })
	row[1]:createText(ReadText(RKN_Configio.config.textId, 17), RKN_Configio.config.browserHeaderTextProperties)
	row[1].properties.mouseOverText = ReadText(RKN_Configio.config.textId, 23)

	local addSeparation = RKN_Configio.addModulesToFilter(stable, ReadText(RKN_Configio.config.textId, 18), true)
	if addSeparation then
		stable:addEmptyRow(Helper.standardTextHeight)
	end
	RKN_Configio.addModulesToFilter(stable, ReadText(RKN_Configio.config.textId, 19), false)
end

function RKN_Configio.addModulesToFilter(table, buttonText, checked)
	local atLeastOneAdded = false;
	local selectedMacros = RKN_Configio.getState().filter.macros
	for _, module in ipairs(RKN_Configio.getAllProductionModules()) do
		local macro = module.macro
		if (checked and RKN_Configio_Utils.ArrayIndexOf(selectedMacros, macro) ~= nil) or (not checked and RKN_Configio_Utils.ArrayIndexOf(selectedMacros, macro) == nil) then
			local row = table:addRow(true, { })
			row[1]:createText(module.name, { })
			row[2]:createButton({  }):setText(buttonText, { halign = "center" })
			row[2].handlers.onClick = function () RKN_Configio.filterMacroToggled(macro, not checked) end
			atLeastOneAdded = true
		end
	end
	return atLeastOneAdded
end

function RKN_Configio.createShipFilters(stable, classOptions, purposes, races)
	local row = stable:addRow(false, { fixed = true })
	row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 31), RKN_Configio.config.browserHeaderTextProperties)

	local addSeparation = RKN_Configio.addAllToShipFilter(stable, classOptions, purposes, races, ReadText(RKN_Configio.config.textId, 18), true)
	if addSeparation then
		stable:addEmptyRow(Helper.standardTextHeight / 4)
		row = stable:addRow(false, { bgColor = { r = 128, g = 128, b = 128, a = 100 } } )
		row[1]:createText("", { height = 3 } )
		stable:addEmptyRow(Helper.standardTextHeight / 4)
	end
	RKN_Configio.addAllToShipFilter(stable, classOptions, purposes, races, ReadText(RKN_Configio.config.textId, 19), false)
end

function RKN_Configio.addAllToShipFilter(table, classOptions, purposes, races, buttonText, checked)
	local added = RKN_Configio.addToShipFilter(table, classOptions, RKN_Configio.getState().filter.sizes, checked, buttonText, false)
	added = RKN_Configio.addToShipFilter(table, purposes, RKN_Configio.getState().filter.purposes, checked, buttonText, added)
	return RKN_Configio.addToShipFilter(table, races, RKN_Configio.getState().filter.races, checked, buttonText, added)
end

function RKN_Configio.addToShipFilter(table, options, selected, checked, buttonText, atLeastOneAdded)
	local needSep = atLeastOneAdded
	if #options > 1 then
		for _, op in ipairs(options) do
			if (checked and selected[op.id] ~= nil) or (not checked and selected[op.id] == nil) then
				if needSep then
					table:addEmptyRow(Helper.standardTextHeight / 4)
					needSep = false
				end
				local row = table:addRow(true, { })
				row[1]:createText(op.text, { })
				row[2]:createButton({  }):setText(buttonText, { halign = "center" })
				row[2].handlers.onClick = function () RKN_Configio.filterShipToggled(op.id, selected, not checked) end
				atLeastOneAdded = true
			end
		end
	end
	return atLeastOneAdded
end

function RKN_Configio.createAutoPresetEditorButtons(stable)
	local row = stable:addRow(false, { fixed = true })
	row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 74), RKN_Configio.config.browserHeaderTextProperties)
	local row = stable:addRow(true, { fixed = true })
	row[1]:setColSpan(2):createButton({ }):setText(ReadText(RKN_Configio.config.textId, 75), { halign = "center" })
	row[1].handlers.onClick = function()
		RKN_Configio.getState().presetEditor = nil
		RKN_Configio.params.onOpenPresetEditor()
	end
	local row = stable:addRow(true, { fixed = true })
	row[1]:setColSpan(2):createButton({ active = function() return RKN_Configio.getSelectedRowCustomAutoPreset() ~= nil end }):setText(ReadText(RKN_Configio.config.textId, 76), { halign = "center" })
	row[1].handlers.onClick = function()
		RKN_Configio.getState().presetEditor = RKN_Configio.getSelectedRowCustomAutoPreset()
		RKN_Configio.params.onOpenPresetEditor()
	end
end

function RKN_Configio.createAutoPresetEditorContext()
	Helper.removeAllWidgetScripts(RKN_Configio.params.menu, RKN_Configio.params.contextLayer)

	local contextFrame = Helper.createFrameHandle(RKN_Configio.params.menu, {
		layer = RKN_Configio.params.contextLayer,
		standardButtons = {},
		width = RKN_Configio.params.width,
		x = RKN_Configio.params.x,
		y = RKN_Configio.params.y,
		autoFrameHeight = true,
	})
	RKN_Configio.params.setContextFrame(contextFrame)
	contextFrame:setBackground("solid", { color = Color["frame_background_semitransparent"] })

	local preset = RKN_Configio.getState().presetEditor
	if not preset then
		preset = {
			name = "New Auto-Preset",
			engines = {},
			weapons = {},
			mturrets = {},
			lturrets = {},
			sshields = {},
			mshields = {},
			lshields = {},
			xlshields = {},
			thrusters = {},
			software = {
				longrangescanner = { type = "exact", id = "software_scannerlongrangemk1" },
				objectscanner = { type = "exact", id = "software_scannerobjectmk1" },
				docking = { type = "exact", id = "none" },
				trading = { type = "exact", id = "none" },
				targeting = { type = "exact", id = "none" }
			},
			drones = { type = "percentage" },
			crew = { type = "percentage" },
			deployables = { type = "percentage" },
			countermeasure = { type = "percentage" }
		}
		RKN_Configio.getState().presetEditor = preset
	end

	local raceOptions = { { id = "any", text = ReadText(RKN_Configio.config.textId, 34), icon = "", displayremoveoption = false } }
	for _,race in ipairs(RKN_Configio.getAllAutoPresetRaces()) do
		if race ~= "other" then
			table.insert(raceOptions, { id = race.id, text = race.name, icon = "", displayremoveoption = false })
		end
	end

	local htable = contextFrame:addTable(1, { tabOrder = 6, x = Helper.borderSize, width = RKN_Configio.params.width - Helper.borderSize * 2 })
	local row = htable:addRow(false, { fixed = true })
	row[1]:createText(ReadText(RKN_Configio.config.textId, 35), RKN_Configio.config.browserHeaderTextProperties)

	local smallColWidth = Helper.scaleY(Helper.standardTextHeight)
	local optionsWidth = (RKN_Configio.params.width / 2) - Helper.borderSize * 2
	local optionsY = row:getHeight() + Helper.borderSize * 3;
	local c1table = contextFrame:addTable(6, { tabOrder = 6, x = Helper.borderSize, y = optionsY, width = optionsWidth, maxVisibleHeight  = RKN_Configio.params.height })
	c1table:setColWidth(1, smallColWidth, false)
	c1table:setColWidth(2, smallColWidth, false)
	c1table:setColWidth(3, smallColWidth, false)
	c1table:setColWidth(4, smallColWidth, false)
	c1table:setColWidth(5, smallColWidth, false)

	local row = c1table:addRow(false, { fixed = false })
	row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 36), {})
	RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.mTurretOptions, preset.mturrets)

	c1table:addEmptyRow(Helper.standardTextHeight / 2)
	local row = c1table:addRow(false, { fixed = false })
	row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 37), {})
	RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.lTurretOptions, preset.lturrets)

	if RKN_Configio.params.editorShipLoadout then
		c1table:addEmptyRow(Helper.standardTextHeight / 2)
		local row = c1table:addRow(false, { fixed = false })
		row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 38), {})
		RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.sShieldsOptions, preset.sshields)
	end

	c1table:addEmptyRow(Helper.standardTextHeight / 2)
	local row = c1table:addRow(false, { fixed = false })
	row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 39), {})
	RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.mShieldOptions, preset.mshields)

	c1table:addEmptyRow(Helper.standardTextHeight / 2)
	local row = c1table:addRow(false, { fixed = false })
	row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 40), {})
	RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.lShieldOptions, preset.lshields)

	if RKN_Configio.params.editorShipLoadout then
		c1table:addEmptyRow(Helper.standardTextHeight / 2)
		local row = c1table:addRow(false, { fixed = false })
		row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 41), {})
		RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.xlShieldOptions, preset.xlshields)

		c1table:addEmptyRow(Helper.standardTextHeight / 2)
		local row = c1table:addRow(false, { fixed = false })
		row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 42), {})
		RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.engineOptions, preset.engines)

		c1table:addEmptyRow(Helper.standardTextHeight / 2)
		local row = c1table:addRow(false, { fixed = false })
		row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 43), {})
		RKN_Configio.createPresetRules(c1table, raceOptions, RKN_Configio.config.valueOptions, RKN_Configio.params.weaponOptions, preset.weapons)

		c1table:addEmptyRow(Helper.standardTextHeight / 2)
		local row = c1table:addRow(false, { fixed = false })
		row[1]:setColSpan(6):createText(ReadText(RKN_Configio.config.textId, 44), {})
		local onlyAnyRace = { { id = "any", text = ReadText(RKN_Configio.config.textId, 34), icon = "", displayremoveoption = false } }
		RKN_Configio.createPresetRules(c1table, onlyAnyRace, RKN_Configio.config.valueOptions, RKN_Configio.params.thrusterOptions, preset.thrusters)
	end


	local c2table = contextFrame:addTable(3, { tabOrder = 6, x = Helper.borderSize * 2 + (RKN_Configio.params.width / 2), y = optionsY, width = optionsWidth, maxVisibleHeight  = RKN_Configio.params.height })
	c2table:setColWidth(1, smallColWidth, false)

	if RKN_Configio.params.editorShipLoadout then
		local row = c2table:addRow(false, { fixed = false })
		row[1]:setColSpan(3):createText(ReadText(RKN_Configio.config.textId, 45), {})
		local row = c2table:addRow(true, { fixed = false })
		row[2]:createText(ReadText(RKN_Configio.config.textId, 46), {})
		row[3]:createDropDown(RKN_Configio.config.dockingComputerOptions, { startOption = preset.software.docking.id, height = Helper.standardTextHeight })
		row[3].handlers.onDropDownConfirmed = function(_, id)
			preset.software.docking.id = id
		end
		local row = c2table:addRow(true, { fixed = false })
		row[2]:createText(ReadText(RKN_Configio.config.textId, 47), {})
		row[3]:createDropDown(RKN_Configio.config.longRangeScannerOptions, { startOption = preset.software.longrangescanner.id, height = Helper.standardTextHeight })
		row[3].handlers.onDropDownConfirmed = function(_, id)
			preset.software.longrangescanner.id = id
		end
		local row = c2table:addRow(true, { fixed = false })
		row[2]:createText(ReadText(RKN_Configio.config.textId, 48), {})
		row[3]:createDropDown(RKN_Configio.config.objectScannerOptions, { startOption = preset.software.objectscanner.id, height = Helper.standardTextHeight })
		row[3].handlers.onDropDownConfirmed = function(_, id)
			preset.software.objectscanner.id = id
		end
		local row = c2table:addRow(true, { fixed = false })
		row[2]:createText(ReadText(RKN_Configio.config.textId, 49), {})
		row[3]:createDropDown(RKN_Configio.config.targetingComputerOptions, { startOption = preset.software.targeting.id, height = Helper.standardTextHeight })
		row[3].handlers.onDropDownConfirmed = function(_, id)
			preset.software.targeting.id = id
		end
		local row = c2table:addRow(true, { fixed = false })
		row[2]:createText(ReadText(RKN_Configio.config.textId, 50), {})
		row[3]:createDropDown(RKN_Configio.config.tradingComputerOptions, { startOption = preset.software.trading.id, height = Helper.standardTextHeight })
		row[3].handlers.onDropDownConfirmed = function(_, id)
			preset.software.trading.id = id
		end

		local row = c2table:addRow(false, { fixed = false })
		row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 51), {})
		RKN_Configio.createPresetPercentageSlider(c2table, "crew", preset.crew, ReadText(RKN_Configio.config.textId, 52))
		RKN_Configio.createPresetPercentageSlider(c2table, "marines", preset.crew, ReadText(RKN_Configio.config.textId, 53))

		local row = c2table:addRow(false, { fixed = false })
		row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 54), {})
		RKN_Configio.createPresetPercentageSlider(c2table, "cargo", preset.drones, ReadText(RKN_Configio.config.textId, 55))
		RKN_Configio.createPresetPercentageSlider(c2table, "mining", preset.drones, ReadText(RKN_Configio.config.textId, 56))
		RKN_Configio.createPresetPercentageSlider(c2table, "defence", preset.drones, ReadText(RKN_Configio.config.textId, 57))
		RKN_Configio.createPresetPercentageSlider(c2table, "repair", preset.drones, ReadText(RKN_Configio.config.textId, 58))

		local row = c2table:addRow(false, { fixed = false })
		row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 59), {})
		RKN_Configio.createPresetPercentageSlider(c2table, "advsatellite", preset.deployables, ReadText(RKN_Configio.config.textId, 60))
		RKN_Configio.createPresetPercentageSlider(c2table, "satellite", preset.deployables, ReadText(RKN_Configio.config.textId, 61))
		RKN_Configio.createPresetPercentageSlider(c2table, "resprobe", preset.deployables, ReadText(RKN_Configio.config.textId, 62))
		RKN_Configio.createPresetPercentageSlider(c2table, "lastower1", preset.deployables, ReadText(RKN_Configio.config.textId, 63))
		RKN_Configio.createPresetPercentageSlider(c2table, "lastower2", preset.deployables, ReadText(RKN_Configio.config.textId, 64))
		RKN_Configio.createPresetPercentageSlider(c2table, "ffmine", preset.deployables, ReadText(RKN_Configio.config.textId, 65))
		RKN_Configio.createPresetPercentageSlider(c2table, "mine", preset.deployables, ReadText(RKN_Configio.config.textId, 66))
		RKN_Configio.createPresetPercentageSlider(c2table, "trackmine", preset.deployables, ReadText(RKN_Configio.config.textId, 67))

		local row = c2table:addRow(false, { fixed = false })
		row[1]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 68), {})
		RKN_Configio.createPresetPercentageSlider(c2table, "flares", preset.countermeasure, ReadText(RKN_Configio.config.textId, 68))

		c2table:addEmptyRow(Helper.standardTextHeight)
	end

	local row = c2table:addRow(true, { fixed = false })
	row[1]:setColSpan(3):createEditBox({ scaling = true, height = Helper.standardButtonHeight }):setText(preset.name, { })
	row[1].handlers.onTextChanged = function(_, text, textchanged)
		preset.name = text
	end

	local allPresets = RKN_Configio.getAutoPresets(RKN_Configio.params.settingKey)
	local row = c2table:addRow(true, { fixed = false })
	row[1]:setColSpan(2):createButton({ active = function() return RKN_Configio.getAutoPresetByName(allPresets, preset.name) ~= nil end }):setText(ReadText(RKN_Configio.config.textId, 70), { halign = "center" })
	row[1].handlers.onClick = function()
		RKN_Configio.saveAutoPreset(preset, RKN_Configio.getAutoPresetByName(allPresets, preset.name).id)
		RKN_Configio.params.onSave()
	end
	row[3]:createButton({ active = function() return RKN_Configio.getAutoPresetByName(allPresets, preset.name) == nil end }):setText(ReadText(RKN_Configio.config.textId, 69), { halign = "center" })
	row[3].handlers.onClick = function()
		RKN_Configio.saveAutoPreset(preset)
		RKN_Configio.params.onSave()
	end
	
	if RKN_Configio.getState().topRow then
		c1table:setTopRow(RKN_Configio.getState().topRow.leftTable)
	end

	contextFrame:display()
end

function RKN_Configio.createPresetRules(c1table, raceOptions, valueOptions, exactOptions, rules)
	local exactKey = "exact"
	local autoKey = "auto"

	for i, rule in ipairs(rules) do
		----- Rule header row -----
		local row = c1table:addRow(true, { fixed = false })
		-- Move up button --
		row[2]:createButton({ active = i ~= 1, height = Helper.standardTextHeight }):setIcon("widget_arrow_up_01")
		row[2].handlers.onClick = function ()
			table.insert(rules, i-1, rule)
			table.remove(rules, i+1)
			RKN_Configio.refreshPresetFrame()
		end
		-- Move down button --
		row[3]:createButton({ active = i ~= #rules, height = Helper.standardTextHeight }):setIcon("widget_arrow_down_01")
		row[3].handlers.onClick = function ()
			table.insert(rules, i, rules[i+1])
			table.remove(rules, i+2)
			RKN_Configio.refreshPresetFrame()
		end
		-- Delete button --
		row[4]:createButton({ height = Helper.standardTextHeight }):setIcon("widget_cross_01")
		row[4].handlers.onClick = function ()
			table.remove(rules, i)
			RKN_Configio.refreshPresetFrame()
		end
		-- Rule number --
		--row[5]:setColSpan(2):createText(tostring(i), { })

		if rule.type == exactKey then
			row[5]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 87))
			RKN_Configio.createPresetExactRows(c1table, exactOptions, rule)
		elseif rule.type == autoKey then
			row[5]:setColSpan(2):createText(ReadText(RKN_Configio.config.textId, 88))
			RKN_Configio.createPresetAutoRows(c1table, raceOptions, valueOptions, rule)
		else
			row[3]:setColSpan(4):createText("Unknown rule type!", {})
		end
	end

	-- Create add new rule dropdown
	local row = c1table:addRow(true, { fixed = false })
	local addOptions = {
		{ id = exactKey, text = ReadText(RKN_Configio.config.textId, 77), icon = "", displayremoveoption = false },
		{ id = autoKey, text = ReadText(RKN_Configio.config.textId, 78), icon = "", displayremoveoption = false }
	}
	row[2]:setColSpan(5):createDropDown(addOptions, { height = Helper.standardTextHeight, textOverride = ReadText(RKN_Configio.config.textId, 79)})
	row[2].handlers.onDropDownConfirmed = function(_, id)
		local rule = { type = id }
		if id == autoKey then
			-- set defaults
			rule.race = "any"
			rule.value = "low"
		end
		table.insert(rules, rule)
		RKN_Configio.refreshPresetFrame()
	end
end

function RKN_Configio.createPresetExactRows(c1table, options, rule)
	local row = c1table:addRow(true, { fixed = false })
	row[3]:setColSpan(3):createText(ReadText(RKN_Configio.config.textId, 80), {})
	row[6]:createDropDown(options, { startOption = rule.macro, height = Helper.standardTextHeight })
	row[6].handlers.onDropDownConfirmed = function(_, id)
		rule.macro = id
	end
end

function RKN_Configio.createPresetAutoRows(c1table, raceOptions, valueOptions, rule)
	local row = c1table:addRow(true, { fixed = false })
	row[3]:setColSpan(3):createText(ReadText(RKN_Configio.config.textId, 81), {})
	row[6]:createDropDown(raceOptions, { active = #raceOptions > 1, startOption = rule.race, height = Helper.standardTextHeight })
	row[6].handlers.onDropDownConfirmed = function(_, id)
		rule.race = id
	end
	local row = c1table:addRow(true, { fixed = false })
	row[3]:setColSpan(3):createText(ReadText(RKN_Configio.config.textId, 82), {})
	row[6]:createDropDown(valueOptions, { active = #valueOptions > 1, startOption = rule.value, height = Helper.standardTextHeight })
	row[6].handlers.onDropDownConfirmed = function(_, id)
		rule.value = id
	end
end

function RKN_Configio.createPresetPercentageSlider(c1table, current, all, text)
	local remaining = 100
	for k, v in pairs(all) do
		if k ~= "type" and k ~= current then
			remaining = remaining - v
		end
	end

	local row = c1table:addRow(true, { fixed = false })
	row[2]:setColSpan(2):createSliderCell({ maxSelect = remaining, height = Helper.standardTextHeight, valueColor = Color["slider_value"], min = 0, max = 100, start = all[current], suffix = "%" }):setText(text)
	row[2].handlers.onSliderCellConfirm = function(_, value)
		all[current] = value
		RKN_Configio.refreshPresetFrame()
	end
end

function RKN_Configio.createDeleteConfirmation(contextFrame, y, item)
	local htable = contextFrame:addTable(8, { tabOrder = 6, x = Helper.borderSize, y = y, width = RKN_Configio.params.width - Helper.borderSize * 2 })
	local row = htable:addRow(false, { fixed = true })
	row[1]:setColSpan(8):createText(ReadText(RKN_Configio.config.textId, 83), RKN_Configio.config.browserHeaderTextProperties)

	local row = htable:addRow(false, { fixed = true })
	row[3]:setColSpan(4):createText(ReadText(RKN_Configio.config.textId, 84):format(item.name), { wordwrap = true })

	htable:addEmptyRow(Helper.standardTextHeight)
	local row = htable:addRow(true, { fixed = true })
	row[5]:createButton({ }):setText(ReadText(RKN_Configio.config.textId, 85), { halign = "center" })
	row[5].handlers.onClick = function()
		RKN_Configio.params.onDeletion(item)
		RKN_Configio.contextModule = nil
		RKN_Configio.refreshLoadFrame()
	end
	row[6]:createButton({ }):setText(ReadText(RKN_Configio.config.textId, 86), { halign = "center" })
	row[6].handlers.onClick = function()
		RKN_Configio.contextModule = nil
		RKN_Configio.refreshLoadFrame()
	end
end

function RKN_Configio.createRenameItemContext(contextFrame, y, item)
	local state = RKN_Configio.getState()
	local htable = contextFrame:addTable(8, { tabOrder = 6, x = Helper.borderSize, y = y, width = RKN_Configio.params.width - Helper.borderSize * 2 })
	local row = htable:addRow(false, { fixed = true })
	row[1]:setColSpan(8):createText(ReadText(RKN_Configio.config.textId, 94), RKN_Configio.config.browserHeaderTextProperties)

	local row = htable:addRow(false, { fixed = true })
	row[3]:createText(ReadText(RKN_Configio.config.textId, 95), { wordwrap = true })
	RKN_Configio.params.contextMode.nameEditBox = row[4]:setColSpan(3):createEditBox({ scaling = true, height = Helper.standardTextHeight }):setText(state.renameText, { })
	row[4].handlers.onTextChanged = function(_, text)
		state.renameText = text
	end

	local takenNames = {}
	for _, l in ipairs(RKN_Configio.params.itemsList()) do
		takenNames[RKN_Configio.name] = true
	end

	htable:addEmptyRow(Helper.standardTextHeight)
	local row = htable:addRow(true, { fixed = true })
	row[5]:createButton({ active = function() return not takenNames[state.renameText] end }):setText(ReadText(RKN_Configio.config.textId, 85), { halign = "center" })
	row[5].handlers.onClick = function()
		RKN_Configio.params.onRename(item, state.renameText)
		RKN_Configio.contextModule = nil
		RKN_Configio.refreshLoadFrame()
	end
	row[6]:createButton({ }):setText(ReadText(RKN_Configio.config.textId, 86), { halign = "center" })
	row[6].handlers.onClick = function()
		RKN_Configio.contextModule = nil
		RKN_Configio.refreshLoadFrame()
	end
end

function RKN_Configio.createSaveItemContext(contextFrame, y, item)
	local state = RKN_Configio.getState()
	local htable = contextFrame:addTable(8, { tabOrder = 6, x = Helper.borderSize, y = y, width = RKN_Configio.params.width - Helper.borderSize * 2 })
	local row = htable:addRow(false, { fixed = true })
	row[1]:setColSpan(8):createText(ReadText(RKN_Configio.config.textId, 97), RKN_Configio.config.browserHeaderTextProperties)

	local row = htable:addRow(false, { fixed = true })
	row[3]:createText(ReadText(RKN_Configio.config.textId, 96), { wordwrap = true })
	RKN_Configio.params.contextMode.nameEditBox = row[4]:setColSpan(3):createEditBox({ scaling = true, height = Helper.standardTextHeight }):setText(state.saveText, { })
	row[4].handlers.onTextChanged = function(_, text)
		state.saveText = text
	end

	local takenNames = {}
	for _, l in ipairs(RKN_Configio.params.itemsList()) do
		takenNames[RKN_Configio.name] = RKN_Configio.params.isItemSavable(l)
	end

	htable:addEmptyRow(Helper.standardTextHeight)
	local row = htable:addRow(true, { fixed = true })
	row[4]:createButton({ active = function() return takenNames[state.saveText] == true end }):setText(ReadText(RKN_Configio.config.textId, 70), { halign = "center" })
	row[4].handlers.onClick = function()
		RKN_Configio.params.onSave(state.saveText, true)
		RKN_Configio.contextModule = nil
		RKN_Configio.refreshLoadFrame()
	end
	row[5]:createButton({ active = function() return takenNames[state.saveText] == nil end }):setText(ReadText(RKN_Configio.config.textId, 69), { halign = "center" })
	row[5].handlers.onClick = function()
		RKN_Configio.params.onSave(state.saveText, false)
		RKN_Configio.contextModule = nil
		RKN_Configio.refreshLoadFrame()
	end
	row[6]:createButton({ }):setText(ReadText(RKN_Configio.config.textId, 86), { halign = "center" })
	row[6].handlers.onClick = function()
		RKN_Configio.contextModule = nil
		RKN_Configio.refreshLoadFrame()
	end
end

function RKN_Configio.isRowValidForLoad()
	return RKN_Configio.selectedEntry and RKN_Configio.selectedEntry.active
end

function RKN_Configio.isRowValidForDeletion()
	return RKN_Configio.selectedEntry and RKN_Configio.selectedEntry.deleteable
end

function RKN_Configio.isRowValidForRename()
	return RKN_Configio.selectedEntry and RKN_Configio.selectedEntry.renamable
end

function RKN_Configio.isRowValidForSave()
	--return RKN_Configio.selectedEntry and (RKN_Configio.selectedEntry.type == "folder" or RKN_Configio.selectedEntry.savable)
	return RKN_Configio.params.onSave ~= nil
end

function RKN_Configio.getSelectedRowCustomAutoPreset()
	return RKN_Configio.selectedEntry and RKN_Configio.selectedEntry.item and RKN_Configio.selectedEntry.item.customPreset
end

function RKN_Configio.buttonDeleteItem()
	if RKN_Configio.isRowValidForDeletion() then
		RKN_Configio.contextModule = function(contextFrame, y) RKN_Configio.createDeleteConfirmation(contextFrame, y, RKN_Configio.selectedEntry.item) end
		RKN_Configio.refreshLoadFrame()
	end
end

function RKN_Configio.buttonLoadItem()
	if RKN_Configio.isRowValidForLoad() then
		RKN_Configio.params.onSelection(RKN_Configio.selectedEntry.item)
	end
end

function RKN_Configio.buttonRenameItem()
	if RKN_Configio.isRowValidForRename() then
		RKN_Configio.getState().renameText = RKN_Configio.selectedEntry.item.name
		RKN_Configio.contextModule = function(contextFrame, y) RKN_Configio.createRenameItemContext(contextFrame, y, RKN_Configio.selectedEntry.item) end
		RKN_Configio.refreshLoadFrame()
	end
end

function RKN_Configio.buttonSaveItem()
	if RKN_Configio.isRowValidForSave() then
		if RKN_Configio.selectedEntry.type == "folder" then
			RKN_Configio.getState().saveText = RKN_Configio.selectedEntry.fullname .. RKN_Configio.getSettings().folder_delimiter
		else
			RKN_Configio.getState().saveText = RKN_Configio.selectedEntry.item.name
		end
		RKN_Configio.contextModule = function(contextFrame, y) RKN_Configio.createSaveItemContext(contextFrame, y) end
		RKN_Configio.refreshLoadFrame()
	end
end

function RKN_Configio.refreshLoadFrame()
	local state = RKN_Configio.getState()
	state.topRow = {
		listTable = GetTopRow(state.tables[1]),
		settingsTable = GetTopRow(state.tables[3])
	}
	RKN_Configio.autoSelectSearch = false
	RKN_Configio.createLoadContext()
end

function RKN_Configio.refreshPresetFrame()
	local state = RKN_Configio.getState()
	state.topRow = {
		leftTable = GetTopRow(state.tables[2])
	}
	RKN_Configio.createAutoPresetEditorContext()
end

function RKN_Configio.buttonExtendListEntry(index, row)
	local key = RKN_Configio.config.folderIdFormat:format(RKN_Configio.params.settingKey, index)
	RKN_Configio.getState().expandedFolders[key] = not RKN_Configio.getState().expandedFolders[key]
	RKN_Configio.getState().selectedRow = row
	RKN_Configio.refreshLoadFrame()
end

function RKN_Configio.buttonExpandAll(listRoot)
	RKN_Configio.expandAll(listRoot)
	RKN_Configio.refreshLoadFrame()
end

function RKN_Configio.expandAll(root)
	for _,folder in ipairs(root.folders_arr) do
		RKN_Configio.getState().expandedFolders[RKN_Configio.config.folderIdFormat:format(RKN_Configio.params.settingKey, folder.fullname)] = true
		RKN_Configio.expandAll(folder)
	end
end

function RKN_Configio.buttonCollapseAll()
	for k,_ in pairs(RKN_Configio.getState().expandedFolders) do
		RKN_Configio.getState().expandedFolders[k] = false
	end
	RKN_Configio.refreshLoadFrame()
end

function RKN_Configio.searchItemEdit(_, text, textchanged)
	if not textchanged then
		return
	end

	RKN_Configio.getState().filter.search = text
	RKN_Configio.refreshLoadFrame()
end

function RKN_Configio.filterMacroToggled(macro, checked)
	local selectedMacros = RKN_Configio.getState().filter.macros
	if checked then
		table.insert(selectedMacros, macro)
	else
		local index = RKN_Configio_Utils.ArrayIndexOf(selectedMacros, macro)
		if index then
			table.remove(selectedMacros, index)
		end
	end
	RKN_Configio.refreshLoadFrame()
end

function RKN_Configio.filterShipToggled(id, selected, checked)
	if checked then
		selected[id] = true
	else
		selected[id] = nil
	end
	RKN_Configio.refreshLoadFrame()
end

function RKN_Configio.onRowChanged(uitable, rowdata)
	if RKN_Configio.ltable and uitable == RKN_Configio.ltable.id then
		RKN_Configio.selectedEntry = rowdata
		return true
	end
	return false
end

function RKN_Configio.onSelectElement(uitable)
	if uitable == RKN_Configio.ltable.id then
		RKN_Configio.buttonLoadItem()
	end
end

function RKN_Configio.onDropDownActivated(dropdown)
	return true
end

function RKN_Configio.viewCreated(layer, ...)
	if layer == 2 then
		local state = RKN_Configio.getState();
		if state then
			state.tables = table.pack(...)
		end
	end
end

function RKN_Configio.onStationLoadoutLoad(menu, item)
	if item.customPreset then
		local upgradeplan = RKN_Configio.generateLoadoutUpgradePlan(menu, item.customPreset)
		menu.getUpgradeData(upgradeplan)
		if menu.holomap and (menu.holomap ~= 0) then
			Helper.callLoadoutFunction(menu.constructionplan[menu.loadoutMode].upgradeplan, nil, function (loadout, _) return C.UpdateObjectConfigurationMap(menu.holomap, menu.container, menu.loadoutModule.component, menu.loadoutModule.macro, true, loadout) end)
		end
		menu.displayMenu()
	elseif item.partial and RKN_Configio.getSettings().item_load_partial then
		local loadout = Helper.getLoadoutHelper(C.GetLoadout, C.GetLoadoutCounts, 0, menu.loadoutModule.macro, item.id)
		local upgradeplan = Helper.convertLoadout(menu.loadoutModule.component, menu.loadoutModule.macro, loadout, nil)
		RKN_Configio.trimPartialLoadout(menu.constructionplan[menu.loadoutMode].upgradeplan, upgradeplan, menu.upgradewares, false)
		menu.getUpgradeData(upgradeplan)
		if menu.holomap and (menu.holomap ~= 0) then
			Helper.callLoadoutFunction(menu.constructionplan[menu.loadoutMode].upgradeplan, nil, function (loadout, _) return C.UpdateObjectConfigurationMap(menu.holomap, menu.container, menu.loadoutModule.component, menu.loadoutModule.macro, true, loadout) end)
		end
		menu.displayMenu()
	else
		menu.dropdownLoadout(_, item.id)
	end
end

function RKN_Configio.onShipLoadoutLoad(menu, item)
	if item.customPreset then
		menu.loadoutName = item.name
		menu.setCustomShipName()
		local upgradeplan = RKN_Configio.generateLoadoutUpgradePlan(menu, item.customPreset)
		if menu.usemacro then
			menu.captainSelected = true
		end
		menu.getDataAndDisplay(upgradeplan, nil)
	elseif item.partial and RKN_Configio.getSettings().item_load_partial then
		menu.loadoutName = item.name
		menu.setCustomShipName()
		local loadout = Helper.getLoadoutHelper2(C.GetLoadout2, C.GetLoadoutCounts2, "UILoadout2", menu.object, menu.macro, item.id)
		local upgradeplan = Helper.convertLoadout(menu.object, menu.macro, loadout, menu.software, "UILoadout2")
		RKN_Configio.trimPartialLoadout(menu.upgradeplan, upgradeplan, menu.upgradewares, true)
		menu.getDataAndDisplay(upgradeplan, menu.crew)
	else
		menu.dropdownLoadout(_, item.id)
	end
end

function RKN_Configio.onLoadoutRemoved(defaultLoad, item)
	if not item.customPreset then
		defaultLoad(nil, item.id)
		return
	end

	local autoPresets = GetNPCBlackboard(RKN_Configio.getPlayerId(), RKN_Configio.config.autoPresetsBlackboardId)
	if autoPresets then
		autoPresets[RKN_Configio.params.settingKey][item.id] = nil
		SetNPCBlackboard(RKN_Configio.getPlayerId(), RKN_Configio.config.autoPresetsBlackboardId, autoPresets)
		RKN_Configio.refreshLoadFrame()
	end
end

function RKN_Configio.buttonDeleteCP(menu, id)
	C.RemoveConstructionPlan("local", id)
	if id == menu.currentCPID then
		menu.currentCPID = nil
		menu.currentCPName = nil
	end
	for i, plan in ipairs(menu.constructionplans) do
		if plan.id == id then
			table.remove(menu.constructionplans, i)
			break
		end
	end
end

function RKN_Configio.dropdownSort(_, id)
	RKN_Configio.getState().sort = id
	RKN_Configio.refreshLoadFrame()
end

function RKN_Configio.addStationPlanMouseover(plans)
	for _, plan in ipairs(plans) do
		-- Make missing blueprints text red
		if plan.mouseovertext and not plan.active then
			plan.mouseovertext = Helper.convertColorToText(RKN_Configio.config.stationPlanMissingBlueprintsColor) .. plan.mouseovertext .. "\27X"
		end

		-- Add "Contains production modules" list
		local atLeastOne = false;
		local text = ReadText(RKN_Configio.config.textId, 104)
		for _, module in ipairs(RKN_Configio.getAllProductionModules()) do
			local hasmacros = Helper.textArrayHelper({ module.macro }, function (numtexts, texts) return C.CheckConstructionPlanForMacros(plan.id, texts, numtexts) end)
			if (hasmacros) then
				atLeastOne = true
				text = text .. "\n· " .. module.name
			end
		end
		if (atLeastOne) then
			if plan.mouseovertext then
				text = plan.mouseovertext .. "\n\n" .. text
			end
			plan.mouseovertext = text
		end
	end
	return plans
end

function RKN_Configio.setRowButtonText(button, icon, text, properties)
	local buttonWidth = button:getWidth() - Helper.borderSize * 2
	local full = icon .. text
	local font = properties.font or Helper.standardFont
	local fontsize = properties.fontsize or Helper.standardFontSizestandardTextHeight
	local truncated = TruncateText(full, font, Helper.scaleFont(font, fontsize), buttonWidth)
	local final = full
	if (full ~= truncated) then
		final = text
	end
	button:setText(final, RKN_Configio.config.buttonRowTextProperties)
end

init()