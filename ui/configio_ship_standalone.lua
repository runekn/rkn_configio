-- /ui/addons/ego_detailmonitor/menu_ship_configuration.lua

-- ffi setup 
local ffi = require("ffi")
local C = ffi.C

--local Lib = require("extensions.sn_mod_support_apis.lua_library")

local rkn_menu = {}
local menu = {}

local config = {
	contextLayer = 2,
	dropDownTextProperties = {
		halign = "center",
		font = Helper.standardFont,
		fontsize = Helper.scaleFont(Helper.standardFont, Helper.standardFontSize),
		color = Color["text_normal"],
		x = 0,
		y = 0
	},
	dropdownRatios = {
		class = 0.7,
		ship = 1.3,
	},
}

local function init()
	menu = Helper.getMenu("ShipConfigurationMenu")
	menu.createTitleBar = rkn_menu.createTitleBar
	menu.onRowChanged = rkn_menu.onRowChanged
	menu.onSelectElement = rkn_menu.onSelectElement
	menu.onDropDownActivated = rkn_menu.onDropDownActivated
	rkn_menu.viewCreatedOld = menu.viewCreated
	menu.viewCreated = rkn_menu.viewCreated
end

function rkn_menu.createTitleBar(frame)
	local classOptions, shipOptions, curShipOption, loadoutOptions = menu.evaluateShipOptions()

	if menu.mode == "modify" then
		local ftable = frame:addTable(5, { tabOrder = 4, height = 0, x = menu.titleData.offsetX, y = menu.titleData.offsetY, scaling = false, reserveScrollBar = false })
		ftable:setColWidth(1, menu.titleData.dropdownWidth)
		ftable:setColWidth(2, menu.titleData.dropdownWidth)
		ftable:setColWidth(3, menu.titleData.height)
		ftable:setColWidth(4, menu.titleData.height)
		ftable:setColWidth(5, menu.titleData.height)

		local row = ftable:addRow(true, { fixed = true, bgColor = Color["row_background_blue"] })
		-- class
		row[1]:createDropDown(classOptions, { startOption = menu.class, active = (not menu.isReadOnly) and (#classOptions > 0), optionWidth = menu.titleData.dropdownWidth, helpOverlayID = "shipconfig_classoptions", helpOverlayText = " ", helpOverlayHighlightOnly = true, uiTriggerID = "shipconfig_classoptions" }):setTextProperties(config.dropDownTextProperties)
		row[1].handlers.onDropDownConfirmed = menu.dropdownShipClass
		-- ships
		local dropDownIconProperties = {
			width = menu.titleData.height / 2,
			height = menu.titleData.height / 2,
			x = menu.titleData.dropdownWidth - 1.5 * menu.titleData.height,
			y = 0,
			scaling = false,
		}

		row[2]:createDropDown(shipOptions, { startOption = curShipOption, active = (not menu.isReadOnly) and (menu.class ~= ""), optionWidth = menu.titleData.dropdownWidth, optionHeight = (menu.statsTableOffsetY or Helper.viewHeight) - menu.titleData.offsetY - Helper.frameBorder, helpOverlayID = "shipconfig_shipoptions", helpOverlayText = " ", helpOverlayHighlightOnly = true, uiTriggerID = "shipconfig_shipoptions" }):setTextProperties(config.dropDownTextProperties):setIconProperties(dropDownIconProperties)
		row[2].properties.text.halign = "left"
		row[2].handlers.onDropDownConfirmed = menu.dropdownShip
		-- reset camera
		row[3]:createButton({ active = true, height = menu.titleData.height, mouseOverText = ffi.string(C.ConvertInputString(ReadText(1026, 7911), ReadText(1026, 7902))) }):setIcon("menu_reset_view"):setHotkey("INPUT_STATE_DETAILMONITOR_RESET_VIEW", { displayIcon = false })
		row[3].handlers.onClick = function () return C.ResetMapPlayerRotation(menu.holomap) end
		-- undo
		row[4]:createButton({ active = function () return (#menu.undoStack > 1) and (menu.undoIndex < #menu.undoStack) end, height = menu.titleData.height, mouseOverText = ReadText(1026, 7903) .. Helper.formatOptionalShortcut(" (%s)", "action", 278) }):setIcon("menu_undo")
		row[4].handlers.onClick = function () return menu.undoHelper(true) end
		-- redo
		row[5]:createButton({ active = function () return (#menu.undoStack > 1) and (menu.undoIndex > 1) end, height = menu.titleData.height, mouseOverText = ReadText(1026, 7904) .. Helper.formatOptionalShortcut(" (%s)", "action", 279) }):setIcon("menu_redo")
		row[5].handlers.onClick = function () return menu.undoHelper(false) end

		ftable:addConnection(1, 3, true)
	else
		local ftable = frame:addTable(7, { tabOrder = 4, height = 0, x = menu.titleData.offsetX, y = menu.titleData.offsetY, scaling = false, reserveScrollBar = false })
		if ((menu.macro == "") and (menu.object == 0)) then
			ftable.properties.defaultInteractiveObject = true
		end
		ftable:setColWidth(1, config.dropdownRatios.class * menu.titleData.dropdownWidth)
		ftable:setColWidth(2, config.dropdownRatios.ship * menu.titleData.dropdownWidth)
		ftable:setColWidth(3, menu.titleData.dropdownWidth)
		ftable:setColWidth(4, menu.titleData.height)
		ftable:setColWidth(5, menu.titleData.height)
		ftable:setColWidth(6, menu.titleData.height)
		ftable:setColWidth(7, menu.titleData.height)

		local row = ftable:addRow(true, { fixed = true, bgColor = Color["row_background_blue"] })
		---- Runekn's Changes Start Here! ----
		--[[
		-- class
		row[1]:createDropDown(classOptions, { startOption = menu.class, active = (not menu.isReadOnly) and (#classOptions > 0), helpOverlayID = "shipconfig_classoptions", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setTextProperties(config.dropDownTextProperties)
		row[1].handlers.onDropDownConfirmed = menu.dropdownShipClass
		-- ships
		local dropDownIconProperties = {
			width = menu.titleData.height / 2,
			height = menu.titleData.height / 2,
			x = config.dropdownRatios.ship * menu.titleData.dropdownWidth - 1.5 * menu.titleData.height,
			y = 0,
			scaling = false,
		}
		local dropdown = row[2]:createDropDown(shipOptions, { startOption = curShipOption, active = (not menu.isReadOnly) and (menu.class ~= ""), optionHeight = (menu.statsTableOffsetY or Helper.viewHeight) - menu.titleData.offsetY - Helper.frameBorder, helpOverlayID = "shipconfig_shipoptions", helpOverlayText = " ", helpOverlayHighlightOnly = true }):setTextProperties(config.dropDownTextProperties):setIconProperties(dropDownIconProperties)
		row[2].properties.text.halign = "left"
		row[2].handlers.onDropDownConfirmed = menu.dropdownShip
		--]]

		local dropdown = RKN_Configio.createShipTitleBarButton(row, menu, config, classOptions, shipOptions, curShipOption)
		---- Runekn's Changes Stop Here! ----
		local active = true
		if (menu.mode == "purchase") and (menu.macro ~= "") and (not menu.validLicence) then
			active = false
			local haslicence, icon, overridecolor, mouseovertext = menu.checkLicence(menu.macro, true)
			dropdown.properties.text.color = overridecolor
			dropdown.properties.icon.color = overridecolor
		end
		if (menu.mode == "upgrade") and (not menu.isReadOnly) and (menu.object ~= 0) then
			if not C.CanContainerEquipShip(menu.container, menu.object) then
				active = false
			end
		end

		-- loadout
		---- Runekn's Changes Start Here! ----
		--row[3]:createDropDown(loadoutOptions, { textOverride = ReadText(1001, 7905), active = (not menu.isReadOnly) and active and ((menu.object ~= 0) or (menu.macro ~= "")) and (next(menu.loadouts) ~= nil), optionWidth = menu.titleData.dropdownWidth + menu.titleData.height + Helper.borderSize, optionHeight = (menu.statsTableOffsetY or Helper.viewHeight) - menu.titleData.offsetY - Helper.frameBorder, mouseOverText = (menu.mode == "customgamestart") and (ColorText["text_warning"] .. ReadText(1026, 8022)) or "" }):setTextProperties(config.dropDownTextProperties)
		--row[3].handlers.onDropDownConfirmed = menu.dropdownLoadout
		--row[3].handlers.onDropDownRemoved = menu.dropdownLoadoutRemoved

		RKN_Configio.createShipLoadoutTitleBarButton(row, menu, config, active, loadoutOptions)
		---- Runekn's Changes Stop Here! ----

		---- Store exisiting loadout mod compatibility start ----
		if menu.uix_callbacks and menu.uix_callbacks ["displaySlots_on_before_create_store_loadout_button"] then
			for uix_id, uix_callback in pairs (menu.uix_callbacks ["displaySlots_on_before_create_store_loadout_button"]) do
				uix_callback ()
			end
		end
		---- Store exisiting loadout mod compatibility end ----

		-- save
		row[4]:createButton({ active = (not menu.isReadOnly) and active and ((menu.object ~= 0) or (menu.macro ~= "")), height = menu.titleData.height, mouseOverText = ReadText(1026, 7905), helpOverlayID = "shipconfig_saveloadout", helpOverlayText = " ", helpOverlayHighlightOnly = true, uiTriggerID = "shipconfig_saveloadout" }):setIcon("menu_save")
		row[4].handlers.onClick = menu.buttonTitleSave

		---- Store exisiting loadout mod compatibility start ----
		if menu.uix_callbacks and menu.uix_callbacks ["displaySlots_on_after_create_store_loadout_button"] then
			for uix_id, uix_callback in pairs (menu.uix_callbacks ["displaySlots_on_after_create_store_loadout_button"]) do
				uix_callback ()
			end
		end
		---- Store exisiting loadout mod compatibility end ----

		-- reset camera
		row[5]:createButton({ active = true, height = menu.titleData.height, mouseOverText = ffi.string(C.ConvertInputString(ReadText(1026, 7911), ReadText(1026, 7902))) }):setIcon("menu_reset_view"):setHotkey("INPUT_STATE_DETAILMONITOR_RESET_VIEW", { displayIcon = false })
		row[5].handlers.onClick = function () return C.ResetMapPlayerRotation(menu.holomap) end
		-- undo
		row[6]:createButton({ active = function () return (#menu.undoStack > 1) and (menu.undoIndex < #menu.undoStack) end, height = menu.titleData.height, mouseOverText = ReadText(1026, 7903) .. Helper.formatOptionalShortcut(" (%s)", "action", 278) }):setIcon("menu_undo")
		row[6].handlers.onClick = function () return menu.undoHelper(true) end
		-- redo
		row[7]:createButton({ active = function () return (#menu.undoStack > 1) and (menu.undoIndex > 1) end, height = menu.titleData.height, mouseOverText = ReadText(1026, 7904) .. Helper.formatOptionalShortcut(" (%s)", "action", 279) }):setIcon("menu_redo")
		row[7].handlers.onClick = function () return menu.undoHelper(false) end

		ftable:addConnection(1, 3, true)
	end

	menu.topRows.ship = nil
	menu.selectedRows.ship = nil
	menu.selectedCols.ship = nil
end

function rkn_menu.onRowChanged(row, rowdata, uitable)
	if menu.mode == "modify" then
		if uitable == menu.slottable then
			if type(rowdata) == "table" then
				menu.currentSlot = rowdata[1]
				menu.selectMapMacroSlot()
			end
		end
	end
	-- Runekn's Changes Start Here! --
	RKN_Configio.onRowChanged(uitable, rowdata)
	-- Runekn's Changes Stop Here! --
end

function rkn_menu.onSelectElement(uitable)
	-- Runekn's Changes Start Here! --
    RKN_Configio.onSelectElement(uitable)
	-- Runekn's Changes Stop Here! --
end

function rkn_menu.onDropDownActivated(dropdown)
	-- Runekn's Changes Start Here! --
	if RKN_Configio.onDropDownActivated(dropdown) then
		return
	end
	-- Runekn's Changes Stop Here! --

	menu.closeContextMenu()
end

function rkn_menu.viewCreated(layer, ...)
	RKN_Configio.viewCreated(layer, ...)
	rkn_menu.viewCreatedOld(layer, ...)
end

init()