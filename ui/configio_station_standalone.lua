-- /ui/addons/ego_detailmonitor/menu_station_configuration.lua

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
}

local function init()
	menu = Helper.getMenu("StationConfigurationMenu")
	menu.createTitleBar = rkn_menu.createTitleBar
	menu.refreshTitleBar = rkn_menu.refreshTitleBar
	menu.onRowChanged = rkn_menu.onRowChanged
	menu.onSelectElement = rkn_menu.onSelectElement
	menu.onDropDownActivated = rkn_menu.onDropDownActivated
	rkn_menu.viewCreatedOld = menu.viewCreated
	menu.viewCreated = rkn_menu.viewCreated
end

-- Overriden function --
function rkn_menu.createTitleBar(frame)
	menu.updateConstructionPlans()
	menu.getImportablePlans()

	local ftable = frame:addTable(9, { tabOrder = 5, height = 0, x = menu.titleData.offsetX, y = menu.titleData.offsetY, scaling = false, reserveScrollBar = false })
	ftable:setColWidth(1, menu.titleData.nameWidth)
	ftable:setColWidth(2, menu.titleData.dropdownWidth)
	ftable:setColWidth(3, menu.titleData.height)
	ftable:setColWidth(4, menu.titleData.height)
	ftable:setColWidth(5, menu.titleData.height)
	ftable:setColWidth(6, menu.titleData.height)
	ftable:setColWidth(7, menu.titleData.height)
	ftable:setColWidth(8, menu.titleData.height)
	ftable:setColWidth(9, menu.titleData.height)

	local row = ftable:addRow(true, { fixed = true, bgColor = Color["row_background_blue"] })
	if not menu.loadoutMode then
		-- name
		row[1]:createEditBox({ scaling = true }):setText(ffi.string(C.GetComponentName(menu.container)), { halign = "center", font = Helper.headerRow1Font, fontsize = Helper.headerRow1FontSize })
		row[1].handlers.onEditBoxDeactivated = menu.editboxNameUpdateText
		-- load
		local loadOptions = {}
		for _, plan in ipairs(menu.constructionplans) do
			table.insert(loadOptions, { id = plan.id, text = plan.name, icon = "", displayremoveoption = plan.deleteable, active = plan.active, mouseovertext = plan.mouseovertext })
		end
		table.sort(loadOptions, function (a, b) return a.text < b.text end)
		------- Runekn's Changes Start Here! ----------
		--row[2]:createDropDown(loadOptions, { textOverride = ReadText(1001, 7904), optionWidth = menu.titleData.dropdownWidth + menu.titleData.height + Helper.borderSize }):setTextProperties(config.dropDownTextProperties)
		--row[2].handlers.onDropDownActivated = function () menu.noupdate = true end
		--row[2].handlers.onDropDownConfirmed = menu.dropdownLoad
		--row[2].handlers.onDropDownRemoved = menu.dropdownRemovedCP

		RKN_Configio.createStationTitleBarButton(row, menu, config, loadOptions)
		------- Runekn's Changes Stop Here! ----------
		-- save
		row[3]:createButton({ helpOverlayID = "save_constructionplan", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height, mouseOverText = ReadText(1026, 7901) }):setIcon("menu_save")
		row[3].handlers.onClick = menu.buttonTitleSave
		-- Import
		row[4]:createButton({ helpOverlayID = "import_constructionplan", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height, mouseOverText = ReadText(1026, 7916) }):setIcon("menu_import")
		row[4].handlers.onClick = menu.buttonTitleImport
		-- Export
		row[5]:createButton({ helpOverlayID = "export_constructionplan", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height, mouseOverText = ReadText(1026, 7917) }):setIcon("menu_export")
		row[5].handlers.onClick = menu.buttonTitleExport
		-- reset camera
		row[6]:createButton({ helpOverlayID = "reset_topview", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height, mouseOverText = ffi.string(C.ConvertInputString(ReadText(1026, 7911), ReadText(1026, 7902))) }):setIcon("menu_reset_view"):setHotkey("INPUT_STATE_DETAILMONITOR_RESET_VIEW", { displayIcon = false })
		row[6].handlers.onClick = function () return C.ResetMapPlayerRotation(menu.holomap) end
		-- undo
		menu.canundo = false
		if menu.holomap and (menu.holomap ~= 0) then
			menu.canundo = C.CanUndoConstructionMapChange(menu.holomap)
		end
		row[7]:createButton({ helpOverlayID = "undo_constructionplan", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = menu.canundo, height = menu.titleData.height, mouseOverText = ReadText(1026, 7903) .. Helper.formatOptionalShortcut(" (%s)", "action", 278) }):setIcon("menu_undo")
		row[7].handlers.onClick = function () return menu.undoHelper(true) end
		-- redo
		menu.canredo = false
		if menu.holomap and (menu.holomap ~= 0) then
			menu.canredo = C.CanRedoConstructionMapChange(menu.holomap)
		end
		row[8]:createButton({ helpOverlayID = "redo_constructionplan", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = menu.canredo, height = menu.titleData.height, mouseOverText = ReadText(1026, 7904) .. Helper.formatOptionalShortcut(" (%s)", "action", 279) }):setIcon("menu_redo")
		row[8].handlers.onClick = function () return menu.undoHelper(false) end
		-- settings
		row[9]:createButton({ helpOverlayID = "settings", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height }):setIcon("menu_options")
		row[9].handlers.onClick = menu.buttonTitleSettings
	else
		-- name
		row[1]:createEditBox({ scaling = true }):setText(ffi.string(C.GetComponentName(menu.container)), { halign = "center", font = Helper.headerRow1Font, fontsize = Helper.headerRow1FontSize })
		row[1].handlers.onEditBoxDeactivated = menu.editboxNameUpdateText
		-- load
		------- Runekn's Changes Start Here! ----------
		local loadoutOptions = {}
		if next(menu.loadouts) then
			for _, loadout in ipairs(menu.loadouts) do
				table.insert(loadoutOptions, { id = loadout.id, text = loadout.name, icon = "", displayremoveoption = loadout.deleteable, active = loadout.active, mouseovertext = loadout.mouseovertext })
			end
		end
		--row[2]:setColSpan(6):createDropDown(loadoutOptions, { textOverride = ReadText(1001, 7905), optionWidth = menu.titleData.dropdownWidth + 6 * (menu.titleData.height + Helper.borderSize) }):setTextProperties(config.dropDownTextProperties)
		--row[2].handlers.onDropDownConfirmed = menu.dropdownLoadout
		--row[2].handlers.onDropDownRemoved = menu.dropdownRemovedLoadout

		RKN_Configio.createStationLoadoutTitleBarButton(row, menu, config, loadoutOptions)
		------- Runekn's Changes Stop Here! ----------
		-- save
		row[8]:createButton({ helpOverlayID = "save_loadout", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height, mouseOverText = ReadText(1026, 7905) }):setIcon("menu_save")
		row[8].handlers.onClick = menu.buttonTitleSaveLoadout
		-- reset camera
		row[9]:createButton({ helpOverlayID = "reset_topview", helpOverlayText = " ", helpOverlayHighlightOnly = true, active = true, height = menu.titleData.height, mouseOverText = ffi.string(C.ConvertInputString(ReadText(1026, 7911), ReadText(1026, 7902))) }):setIcon("menu_reset_view"):setHotkey("INPUT_STATE_DETAILMONITOR_RESET_VIEW", { displayIcon = false })
		row[9].handlers.onClick = function () return C.ResetMapPlayerRotation(menu.holomap) end
	end
end

-- Overriden function --
function rkn_menu.refreshTitleBar()
	local text = {
		alignment = "center",
		fontname = Helper.standardFont,
		fontsize = Helper.scaleFont(Helper.standardFont, Helper.standardFontSize),
		color = Color["text_normal"],
		x = 0,
		y = 0
	}

	menu.updateConstructionPlans()
	menu.getImportablePlans()

	if not menu.loadoutMode then
		text.override = ReadText(1001, 7904)
		local loadOptions = {}
		for _, plan in ipairs(menu.constructionplans) do
			table.insert(loadOptions, { id = plan.id, text = plan.name, icon = "", displayremoveoption = plan.deleteable, active = plan.active, mouseovertext = plan.mouseovertext })
		end
		table.sort(loadOptions, function (a, b) return a.text < b.text end)

		-- editbox
		local desc = Helper.createEditBox(Helper.createTextInfo(ffi.string(C.GetComponentName(menu.container)), "center", Helper.headerRow1Font, Helper.scaleFont(Helper.headerRow1Font, Helper.headerRow1FontSize), 255, 255, 255, 100), true, 0, 0, 0, 0, nil, nil, false)
		Helper.setCellContent(menu, menu.titlebartable, desc, 1, 1, nil, "editbox", nil, menu.editboxNameUpdateText)
		-- dropdown
		------- Runekn's Changes Start Here! ----------
		--local desc = Helper.createDropDown(loadOptions, "", text, nil, true, true, 0, 0, 0, 0, nil, nil, "", menu.titleData.dropdownWidth + menu.titleData.height + Helper.borderSize)
		--Helper.setCellContent(menu, menu.titlebartable, desc, 1, 2, nil, "dropdown", nil, function () menu.noupdate = true end, menu.dropdownLoad, menu.dropdownRemovedCP)

		RKN_Configio.createRefreshStationTitleBarButton(menu, text, loadOptions)
		------- Runekn's Changes Stop Here! ----------
		-- save
		local desc = Helper.createButton(nil, Helper.createButtonIcon("menu_save", nil, 255, 255, 255, 100), true, true, 0, 0, 0, menu.titleData.height, nil, nil, nil, ReadText(1026, 7901))
		Helper.setCellContent(menu, menu.titlebartable, desc, 1, 3, nil, "button", nil, menu.buttonTitleSave)
	else
		text.override = ReadText(1001, 7905)
		local loadoutOptions = {}
		if next(menu.loadouts) then
			for _, loadout in ipairs(menu.loadouts) do
				table.insert(loadoutOptions, { id = loadout.id, text = loadout.name, icon = "", displayremoveoption = loadout.deleteable, active = loadout.active, mouseovertext = loadout.mouseovertext })
			end
		end

		-- editbox
		local desc = Helper.createEditBox(Helper.createTextInfo(ffi.string(C.GetComponentName(menu.container)), "center", Helper.headerRow1Font, Helper.scaleFont(Helper.headerRow1Font, Helper.headerRow1FontSize), 255, 255, 255, 100), true, 0, 0, 0, 0, nil, nil, false)
		Helper.setCellContent(menu, menu.titlebartable, desc, 1, 1, nil, "editbox", nil, menu.editboxNameUpdateText)
		-- dropdown
		------- Runekn's Changes Start Here! ----------
		--local desc = Helper.createDropDown(loadoutOptions, "", text, nil, true, next(menu.loadouts) ~= nil, 0, 0, 0, 0, nil, nil, "", menu.titleData.dropdownWidth + 4 * (menu.titleData.height + Helper.borderSize))
		--Helper.setCellContent(menu, menu.titlebartable, desc, 1, 2, nil, "dropdown", nil, nil, menu.dropdownLoadout, menu.dropdownRemovedLoadout)

		RKN_Configio.createRefreshStationLoadoutTitleBarButton(menu, text, loadoutOptions)
		------- Runekn's Changes Stop Here! ----------
		-- save
		local desc = Helper.createButton(nil, Helper.createButtonIcon("menu_save", nil, 255, 255, 255, 100), true, true, 0, 0, 0, menu.titleData.height, nil, nil, nil, ReadText(1026, 7905))
		Helper.setCellContent(menu, menu.titlebartable, desc, 1, 8, nil, "button", nil, menu.buttonTitleSaveLoadout)
	end
end

-- Overriden function --
function rkn_menu.onRowChanged(row, rowdata, uitable, modified, input, source)
	-- Runekn's Changes Start Here! --
	if RKN_Configio.onRowChanged(uitable, rowdata) then
        return
    end
	-- Runekn's Changes Stop Here! --

	if not menu.loadoutMode then
		if uitable == menu.plantable then
			if menu.holomap ~= 0 then
				if (source ~= "auto") or (menu.selectedModule == nil) then
					if (type(rowdata) == "table") and rowdata.ismodule and (not rowdata.removed) then
						menu.newSelectedModule = rowdata.module
						C.SelectBuildMapEntry(menu.holomap, rowdata.idx)
					elseif menu.selectedModule ~= nil then
						menu.newSelectedModule = "clear"
						C.ClearBuildMapSelection(menu.holomap)
					end
				end
			end
		elseif uitable == menu.contexttable then
			if (source ~= "auto") or (menu.contextData and (menu.contextData.selectedEntry == nil)) then
				if (type(rowdata) == "table") then
					menu.contextData.newSelectedEntry = rowdata
				end
			end
		end
	end
end

-- Overriden function --
function rkn_menu.onSelectElement(uitable, modified, row)
	if uitable == menu.plantable then
		if menu.holomap ~= 0 then
			if (source ~= "auto") or (menu.selectedModule == nil) then
				local rowdata = Helper.getCurrentRowData(menu, uitable)
				if (type(rowdata) == "table") and rowdata.ismodule and (not rowdata.removed) then
					C.SetFocusMapConstructionPlanEntry(menu.holomap, rowdata.idx, true)
				end
			end
		end
    end
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