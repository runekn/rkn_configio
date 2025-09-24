-- ffi setup 
local ffi = require("ffi")
local C = ffi.C

function RKN_Configio.prepareBrowserStructure(itemList)
	-- First we build the folder structure --
	local root = { type = "folder", name = "root", folders = {}, folders_arr = {}, items = {} }
	for _, item in ipairs(itemList) do
		if not RKN_Configio.filterItem(item) then
			goto continue
		end
		local cwd = root
		-- iterate through item folders --
		local nextMatch = function () return item.name end
		local levelsLeft = 0
		if RKN_Configio.getSettings().folder_enabled then
			nextMatch = string.gmatch(item.name, "[^" .. RKN_Configio_Utils.EscapeGmatch(RKN_Configio.getSettings().folder_delimiter) .. "]+")
			levelsLeft = RKN_Configio.params.maxFolders
		end
		local folder = nextMatch()
		local name = item.name
		local folderPath = ""
		while 1==1 do
			-- Check if this is the item name --
			local next = nextMatch()
			if not next then
				name = folder
				break
			end
			levelsLeft = levelsLeft -1
			if levelsLeft <= 0 then
				-- Make the rest of the actual item name, the displayed name --
				name = item.name:sub(folderPath:len())
				break
			end
			-- Otherwise, path to folder --
			folderPath = folderPath == "" and folder or folderPath .. RKN_Configio.getSettings().folder_delimiter .. folder
			local target = cwd.folders[folder]
			if not target then
				target = { type = "folder", name = folder, fullname = folderPath, folders = {}, folders_arr = {}, items = {} }
				cwd.folders[folder] = target
				table.insert(cwd.folders_arr, target)
			end
			cwd = target
			folder = next
		end
		-- Insert item to final folder --
		table.insert(cwd.items, {
			type = "item",
			name = name,
			active = RKN_Configio.params.isItemActive(item),
			deleteable = item.deleteable,
			renamable = RKN_Configio.params.isItemRenamable and RKN_Configio.params.isItemRenamable(item),
			savable = RKN_Configio.params.isItemSavable and RKN_Configio.params.isItemSavable(item),
			item = item })
		::continue::
	end

	if RKN_Configio.getSettings().folder_flatten_single_item then
		RKN_Configio.undentSingleItems(root)
	end

	-- Now we sort all folders --
	RKN_Configio.sortFolder(root)

	return root
end

function RKN_Configio.filterItem(item)
	local search = RKN_Configio.getState().filter.search
	if search and search ~= "" then
		local searchMatch = item.name:lower():find(search:lower())
		if not searchMatch then
			return false
		end
	end
	if RKN_Configio.getSettings().item_hide_inactive and not RKN_Configio.params.isItemActive(item) then
		return false
	end
	if RKN_Configio.params.itemFilter and (not RKN_Configio.params.itemFilter(item)) then
		return false
	end
	return true
end

function RKN_Configio.filterItemByModules(item)
	local selectedMacros = RKN_Configio.getState().filter.macros
	if selectedMacros and #selectedMacros > 0 then
		local hasmacros = Helper.textArrayHelper(selectedMacros, function (numtexts, texts) return C.CheckConstructionPlanForMacros(item.id, texts, numtexts) end)
		if not hasmacros then
			return false
		end
	end
	return true
end

function RKN_Configio.filterShip(item)
	local selectedRaces = RKN_Configio.getState().filter.races
	local selectedSizes = RKN_Configio.getState().filter.sizes
	local selectedPurposes = RKN_Configio.getState().filter.purposes
	if selectedRaces and next(selectedRaces) ~= nil then
		for _,r in ipairs(item.races) do
			if selectedRaces[r] then
				goto continue
			end
		end
		return false
	end
	::continue::
	if selectedPurposes and next(selectedPurposes) ~= nil then
		if not selectedPurposes[item.purpose] then
			return false
		end
	end
	if selectedSizes and next(selectedSizes) ~= nil then
		if not selectedSizes[item.class] then
			return false
		end
	end
	return true
end

function RKN_Configio.undentSingleItems(folder, parent)
	local canDelete = true
	local atLeastOneSubFolder = false
	-- recursive --
	RKN_Configio_Utils.ArrayRemove(folder.folders_arr, function(t, i, j)
		local subfolder = folder.folders_arr[i];
		local keepSubFolder = RKN_Configio.undentSingleItems(subfolder, folder)
		canDelete = canDelete and not keepSubFolder
		atLeastOneSubFolder = atLeastOneSubFolder or keepSubFolder
		return keepSubFolder
	end);

	-- move item to parent if there is only one --
	local itemCount = #folder.items
	if itemCount == 1 and not atLeastOneSubFolder and parent then
		local item = folder.items[1]

		table.insert(parent.items, item)
		table.remove(folder.items, 1)

		item.name = folder.name .. RKN_Configio.getSettings().folder_delimiter .. item.name
	elseif itemCount > 1 then
		canDelete = false
	end
	return not canDelete
end

function RKN_Configio.sortFolder(folder)
	local sortOption = RKN_Configio.getState().sort or RKN_Configio.params.sortDefault
	table.sort(folder.items, function (a,b) return RKN_Configio.params.sortItems(a, b, sortOption) end)
	table.sort(folder.folders_arr, function (a, b) return a.name < b.name end)
	for _, innerFolder in ipairs(folder.folders_arr) do
		RKN_Configio.sortFolder(innerFolder)
	end
end

function RKN_Configio.getAllWaresByTag(tag)
	-- uint32_t GetNumWares(const char* tags, bool research, const char* licenceownerid, const char* exclusiontags);
	-- uint32_t GetWares(const char** result, uint32_t resultlen, const char* tags, bool research, const char* licenceownerid, const char* exclusiontags);
	local result = {}
	local numwares = C.GetNumWares(tag, false, nil, "noplayerblueprint")
	local wares = ffi.new("const char*[?]", numwares)
	numwares = C.GetWares(wares, numwares, tag, false, nil, "noplayerblueprint")
	for j = 0, numwares - 1 do
		local locware = ffi.string(wares[j])
		table.insert(result, locware)
	end
	return result
end

function RKN_Configio.getAliases()
	-- Problem is that in lua I cannot differentiate between original macros without aliases, and alias macros.
	-- So we create this map of alias macro -> original macro
	-- We connect them by name, because that is the only thing available. This assumes that aliases has the same name.
	if not RKN_Configio.aliases then
		local hasAlias = {}
		local hasNoAlias = {}
		RKN_Configio.collectAliasesByTag("weapon", hasAlias, hasNoAlias)
		RKN_Configio.collectAliasesByTag("turret", hasAlias, hasNoAlias)
		RKN_Configio.collectAliasesByTag("shield", hasAlias, hasNoAlias)
		RKN_Configio.collectAliasesByTag("engine", hasAlias, hasNoAlias)
		RKN_Configio.collectAliasesByTag("thruster", hasAlias, hasNoAlias)

		local result = {}
		for text, macro in pairs(hasNoAlias) do
			result[macro] = hasAlias[text]
		end
		RKN_Configio.aliases = result
	end
	return RKN_Configio.aliases
end

function RKN_Configio.collectAliasesByTag(tag, hasAliasMap, hasNoAliasMap)
	for _, ware in ipairs(RKN_Configio.getAllWaresByTag(tag)) do
		local name, macro = GetWareData(ware, "name", "component")
		local hasAlias = GetMacroData(macro, "hasinfoalias")
		if hasAlias then
			hasAliasMap[name] = macro
		else
			if hasNoAliasMap[name] then
				DebugError("collectAliasesByTag: MULTIPLE ALIASES! " .. macro)
			end
			hasNoAliasMap[name] = macro
		end
	end
end

function RKN_Configio.getAllProductionModules()
	if not RKN_Configio.allProductionModules then
		local result = {}
		for _, ware in ipairs(RKN_Configio.getAllWaresByTag("module")) do
			local name, macro = GetWareData(ware, "name", "component")
			local moduletype = GetMacroData(macro, "infolibrary")

			if moduletype == "moduletypes_production" or moduletype == "moduletypes_processing" or moduletype == "moduletypes_build" then
				local entry = { name = name, macro = macro }
				table.insert(result, entry)
			end
		end
		table.sort(result, function (a, b) return a.name < b.name end)
		RKN_Configio.allProductionModules = result
	end
	return RKN_Configio.allProductionModules
end

function RKN_Configio.getAllWeapons()
	if not RKN_Configio.allWeapons then
		local result = {}
		for _, ware in ipairs(RKN_Configio.getAllWaresByTag("weapon")) do
			local name, macro = GetWareData(ware, "name", "component")
			local hasAlias, librarytype = GetMacroData(macro, "hasinfoalias", "infolibrary")
			if not hasAlias and IsKnownItem(librarytype, macro) then
				local entry = { text = name, id = macro, icon = "", displayremoveoption = false }
				table.insert(result, entry)
			end
		end
		
		table.sort(result, function (a, b) return a.text < b.text end)
		RKN_Configio.allWeapons = result
	end
	return RKN_Configio.allWeapons
end

function RKN_Configio.getAllTurrets()
	local mTurrets = {}
	local lTurrets = {}

	local turrets = RKN_Configio.getAllWaresByTag("turret")
    for _, ware in ipairs(turrets) do
        local name, macro = GetWareData(ware, "name", "component")
		local hasAlias, librarytype = GetMacroData(macro, "hasinfoalias", "infolibrary")
		if not hasAlias and IsKnownItem(librarytype, macro) then
			local entry = { text = name, id = macro, icon = "", displayremoveoption = false }
			local _, _, slotsize = macro:find("^%a+_%a+_(%a)_")
			if slotsize then
				if slotsize:lower() == "l" then
					table.insert(lTurrets, entry)
				elseif slotsize:lower() == "m" then
					table.insert(mTurrets, entry)
				end
			end
		end
    end
	
	table.sort(mTurrets, function (a, b) return a.text < b.text end)
	table.sort(lTurrets, function (a, b) return a.text < b.text end)
	return mTurrets, lTurrets
end

function RKN_Configio.getAllShields()
	local mShields = {}
	local lShields = {}
	local xlShields = {}
	local sShields = {}
    for _, ware in ipairs(RKN_Configio.getAllWaresByTag("shield")) do
        local name, macro = GetWareData(ware, "name", "component")
		
		local hasAlias, librarytype = GetMacroData(macro, "hasinfoalias", "infolibrary")
		if not hasAlias and IsKnownItem(librarytype, macro) then
			local entry = { text = name, id = macro, icon = "", displayremoveoption = false }
			local _, _, type, slotsize = macro:find("^(%a+)_%a+_(%a+)_")
			if slotsize and type ~= "ishield" then -- Ignore VRO internal shields
				if slotsize:lower() == "l" then
					table.insert(lShields, entry)
				elseif slotsize:lower() == "m" then
					table.insert(mShields, entry)
				elseif slotsize:lower() == "xl" then
					table.insert(xlShields, entry)
				elseif slotsize:lower() == "s" then
					table.insert(sShields, entry)
				end
			end
		end
    end
	
	table.sort(sShields, function (a, b) return a.text < b.text end)
	table.sort(mShields, function (a, b) return a.text < b.text end)
	table.sort(lShields, function (a, b) return a.text < b.text end)
	table.sort(xlShields, function (a, b) return a.text < b.text end)
	return sShields, mShields, lShields, xlShields
end

function RKN_Configio.getAllEngines()
	local result = {}
    for _, ware in ipairs(RKN_Configio.getAllWaresByTag("engine")) do
        local name, macro = GetWareData(ware, "name", "component")
		
		local hasAlias, librarytype = GetMacroData(macro, "hasinfoalias", "infolibrary")
		if not hasAlias and IsKnownItem(librarytype, macro) then
			local entry = { text = name, id = macro, icon = "", displayremoveoption = false }
			table.insert(result, entry)
		end
    end
	
	table.sort(result, function (a, b) return a.text < b.text end)
	return result
end

function RKN_Configio.getAllThrusters()
	local result = {}
    for _, ware in ipairs(RKN_Configio.getAllWaresByTag("thruster")) do
        local name, macro = GetWareData(ware, "name", "component")
		
		local hasAlias, librarytype = GetMacroData(macro, "hasinfoalias", "infolibrary")
		if not hasAlias and IsKnownItem(librarytype, macro) then
			local entry = { text = name, id = macro, icon = "", displayremoveoption = false }
			table.insert(result, entry)
		end
    end
	
	table.sort(result, function (a, b) return a.text < b.text end)
	return result
end

function RKN_Configio.getRaceNameMap()
	if not RKN_Configio.raceNameMap then
		local races = {}
		local n = C.GetNumAllRaces()
		local buf = ffi.new("RaceInfo[?]", n)
		n = C.GetAllRaces(buf, n)
		for i = 0, n - 1 do
			local id = ffi.string(buf[i].id)
			local name = ffi.string(buf[i].name)
			races[id] = name
		end
		RKN_Configio.raceNameMap = races
	end
	return RKN_Configio.raceNameMap
end

function RKN_Configio.getAllShipFilterRaces()
	local races = RKN_Configio.getRaceNameMap()
	table.sort(races, function (a, b) return a.name < b.name end)
	table.insert(races, { name = ReadText(RKN_Configio.config.textId, 106), id = "other" })
	return races
end

function RKN_Configio.getAllAutoPresetRaces()
	if not RKN_Configio.allAutoPresetRaces then
		local skip = { khaak = true, drone = true, xenon = true }
		local raceMap = RKN_Configio.getRaceNameMap()
		local races = {}
		for id,name in pairs(raceMap) do
			if not skip[id] then
				table.insert(races, { id = id, name = name })
			end
		end
		table.sort(races, function (a, b) return a.name < b.name end)
		RKN_Configio.allAutoPresetRaces = races
	end
	return RKN_Configio.allAutoPresetRaces
end

function RKN_Configio.getState()
	if not RKN_Configio.state then
		RKN_Configio.state = { }
		for _,key in ipairs({RKN_Configio.config.stationKey, RKN_Configio.config.stationLoadoutKey, RKN_Configio.config.shipLoadoutKey, RKN_Configio.config.shipKey}) do
			RKN_Configio.state[key] = {
				filter = {
					macros = {},
					races = {},
					sizes = {},
					purposes = {}
				},
				expandedFolders = {},
				selectedRow = nil,
				topRow = nil,
			}
		end
	end
	return RKN_Configio.state[RKN_Configio.params.settingKey]
end

function RKN_Configio.getPlayerId()
	if not RKN_Configio.playerID then
		RKN_Configio.playerID = ConvertStringTo64Bit(tostring(C.GetPlayerID()))
	end
	return RKN_Configio.playerID
end

function RKN_Configio.getSettings(key)
	if not key then
		key = RKN_Configio.params.settingKey
	end
	if not RKN_Configio.settings then
		RKN_Configio.settings = RKN_Configio_Utils.DeepCopy(RKN_Configio.config.defaultSettings)
		-- Apply persistent userdata settings
		__userdata_rknconfigo_settings = __userdata_rknconfigo_settings or {}
		for settingKey, menuSettings in pairs(__userdata_rknconfigo_settings) do
			for key1, value in pairs(menuSettings) do
				RKN_Configio.settings[settingKey][key1] = value;
			end
		end
	end
	return RKN_Configio.settings[key]
end

function RKN_Configio.setSetting(key, value, settingKey)
	if not settingKey then
		settingKey = RKN_Configio.params.settingKey
	end
	RKN_Configio.settings[settingKey][key] = value
	RKN_Configio.setSettingPersistent(key, value, settingKey)
end

function RKN_Configio.setSettingPersistent(key, value, settingKey)
	__userdata_rknconfigo_settings = __userdata_rknconfigo_settings or {}
	-- Save setting in persistent userdata if it is different from default
	if (RKN_Configio.config.defaultSettings[settingKey][key] == value and __userdata_rknconfigo_settings[settingKey]) then
		__userdata_rknconfigo_settings[settingKey][key] = nil
	else
		if __userdata_rknconfigo_settings[settingKey] then
			__userdata_rknconfigo_settings[settingKey][key] = value
		else
			__userdata_rknconfigo_settings[settingKey] = {[key] = value}
		end
	end
end

function RKN_Configio.addCustomAutoPresets(menu, key, loadouts)
	local autoPresets = RKN_Configio.getAutoPresets(key)
	if next(autoPresets) ~= nil then
		for id, preset in pairs(autoPresets) do
			local p = { customPreset = preset, id = id, name = preset.name, deleteable = true, active = true }
			if menu.mode == "customgamestart" then
				p.mouseovertext = "Rules matching by value do not work in creative start"
			end
			table.insert(loadouts, p)
		end
	end
	return loadouts
end

function RKN_Configio.getAutoPresetByName(autoPresets, name)
	for id, preset in pairs(autoPresets) do
		if preset.name == name then
			return preset
		end
	end
	return nil
end

function RKN_Configio.getAutoPresets(key)
	if not RKN_Configio.getPlayerId() then
		return {}
	end
	local autoPresets = GetNPCBlackboard(RKN_Configio.getPlayerId(), RKN_Configio.config.autoPresetsBlackboardId)
	if autoPresets then
		return autoPresets[key] or {}
	end
	return {}
end

function RKN_Configio.saveAutoPreset(preset, id)
	if not preset or not preset.name or preset.name == "" then
		return
	end
	local autoPresets = GetNPCBlackboard(RKN_Configio.getPlayerId(), RKN_Configio.config.autoPresetsBlackboardId)
	if not autoPresets then
		autoPresets = { idCounter = 0 }
	end
	local autoPresetsForKey = autoPresets[RKN_Configio.params.settingKey]
	if not autoPresetsForKey then
		autoPresetsForKey = {}
		autoPresets[RKN_Configio.params.settingKey] = autoPresetsForKey
	end
	if not id then
		id = autoPresets.idCounter + 1
		autoPresets.idCounter = id
		preset.id = id
	end
	autoPresetsForKey["rknconfigio_auto_" .. tostring(id)] = preset
	SetNPCBlackboard(RKN_Configio.getPlayerId(), RKN_Configio.config.autoPresetsBlackboardId, autoPresets)
end

function RKN_Configio.generateLoadoutUpgradePlan(menu, presetTemplate)
	local upgradeplan = {
		drone = { },
		thruster = { },
		shield = { },
		engine = { },
		deployable = { },
		crew = { },
		turret = { },
		turretgroup = { },
		software = { },
		shieldgroup = { },
		countermeasure = { },
		missile = { },
		enginegroup = { },
		weapon = { }
	}

	for _, group in ipairs(menu.groups) do
		if #group.turret.possiblemacros > 0 then
			local chosenMacro
			if group.turret.slotsize == "medium" then
				chosenMacro = RKN_Configio.chooseMacroByRules(menu, group.turret.possiblemacros, presetTemplate.mturrets)
			elseif group.turret.slotsize == "large" then
				chosenMacro = RKN_Configio.chooseMacroByRules(menu, group.turret.possiblemacros, presetTemplate.lturrets)
			end
			if chosenMacro then
				table.insert(upgradeplan.turretgroup, { path = group.path, group = group.group, count = group.turret.total, macro = chosenMacro })
			end
		end
		if #group.shield.possiblemacros > 0 then
			local chosenMacro
			if group.shield.slotsize == "medium" then
				chosenMacro = RKN_Configio.chooseMacroByRules(menu, group.shield.possiblemacros, presetTemplate.mshields)
			elseif group.shield.slotsize == "large" then
				chosenMacro = RKN_Configio.chooseMacroByRules(menu, group.shield.possiblemacros, presetTemplate.lshields)
			elseif group.shield.slotsize == "extralarge" then
				chosenMacro = RKN_Configio.chooseMacroByRules(menu, group.shield.possiblemacros, presetTemplate.xlshields)
			end
			if chosenMacro then
				table.insert(upgradeplan.shieldgroup, { path = group.path, group = group.group, count = group.shield.total, macro = chosenMacro })
			end
		end
		if #group.engine.possiblemacros > 0 then
			local chosenMacro = RKN_Configio.chooseMacroByRules(menu, group.engine.possiblemacros, presetTemplate.engines)
			if chosenMacro then
				table.insert(upgradeplan.enginegroup, { path = group.path, group = group.group, count = group.engine.total, macro = chosenMacro })
				for i = 1, group.engine.total do
					table.insert(upgradeplan.engine, { macro = chosenMacro, weaponmode = "", ammomacro = "" })
				end
			end
		end
	end

	for type, slots in pairs(menu.slots) do
		for i, slot in ipairs(slots) do
			if not slot.isgroup and #slot.possiblemacros > 0 then
				if type == "shield" then
					local chosenMacro
					if slot.slotsize == "small" then
						chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.sshields)
					elseif slot.slotsize == "medium" then
						chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.mshields)
					elseif slot.slotsize == "large" then
						chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.lshields)
					elseif slot.slotsize == "extralarge" then
						chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.xlshields)
					else
						-- Internal shields from VRO has no slotsize and only one available macro
						chosenMacro = slot.possiblemacros[1]
					end
					if chosenMacro then
						upgradeplan.shield[i] = { macro = chosenMacro, weaponmode = "", ammomacro = "" }
					end
				elseif type == "weapon" then
					local chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.weapons)
					if chosenMacro then
						upgradeplan.weapon[i] = { macro = chosenMacro, weaponmode = "", ammomacro = "" }
					end
				elseif type == "engine" and #upgradeplan.enginegroup == 0 then
					local chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.engines)
					if chosenMacro then
						upgradeplan.engine[i] = { macro = chosenMacro, weaponmode = "", ammomacro = "" }
					end
				elseif type == "turret" then
					local chosenMacro
					if slot.slotsize == "medium" then
						chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.mturrets)
					elseif slot.slotsize == "large" then
						chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.lturrets)
					end
					if chosenMacro then
						upgradeplan.turret[i] = { macro = chosenMacro, weaponmode = "", ammomacro = "" }
					end
				elseif type == "thruster" then
					local chosenMacro = RKN_Configio.chooseMacroByRules(menu, slot.possiblemacros, presetTemplate.thrusters)
					if chosenMacro then
						upgradeplan.thruster[i] = { macro = chosenMacro }
					end
				end
			end
		end
	end

	if RKN_Configio.params.settingKey == RKN_Configio.config.shipLoadoutKey then
		if presetTemplate.software.docking.id ~= "none" then
			upgradeplan.software[1] = presetTemplate.software.docking.id
		end
		if presetTemplate.software.longrangescanner.id ~= "none" then
			upgradeplan.software[3] = presetTemplate.software.longrangescanner.id
		end
		if presetTemplate.software.objectscanner.id ~= "none" then
			upgradeplan.software[4] = presetTemplate.software.objectscanner.id
		end
		if presetTemplate.software.targeting.id ~= "none" then
			upgradeplan.software[5] = presetTemplate.software.targeting.id
		end
		if presetTemplate.software.trading.id ~= "none" then
			upgradeplan.software[6] = presetTemplate.software.trading.id
		end
		upgradeplan.software[2] = "software_flightassistmk1"
		if menu.crew then
			local crewCapacity = menu.crew.capacity
			upgradeplan.crew.service = RKN_Configio.getProportionateCount(crewCapacity, presetTemplate.crew.crew)
			upgradeplan.crew.marine = RKN_Configio.getProportionateCount(crewCapacity, presetTemplate.crew.marines)
			if menu.mode == "customgamestart" then
				local crewoption = ""
				if presetTemplate.crew.creativecrewoption then
					crewoption = presetTemplate.crew.creativecrewoption
				elseif upgradeplan.crew.marine > 0 or upgradeplan.crew.service > 0 then
					crewoption = RKN_Configio.getCreativeCrewOptions()[2].id
				end
				menu.customgamestartpeopledef = crewoption
			end
		end
		local droneCapacity = GetMacroUnitStorageCapacity(menu.macro)
		if droneCapacity > 0 then
			upgradeplan.drone.ship_gen_xs_cargodrone_empty_01_a_macro = RKN_Configio.getProportionateCount(droneCapacity, presetTemplate.drones.cargo)
			if C.IsUnitMacroCompatible(menu.object, menu.macro, "ship_gen_s_miningdrone_solid_01_a_macro") then
				upgradeplan.drone.ship_gen_s_miningdrone_solid_01_a_macro = RKN_Configio.getProportionateCount(droneCapacity, presetTemplate.drones.mining)
			elseif C.IsUnitMacroCompatible(menu.object, menu.macro, "ship_gen_s_miningdrone_liquid_01_a_macro") then
				upgradeplan.drone.ship_gen_s_miningdrone_liquid_01_a_macro = RKN_Configio.getProportionateCount(droneCapacity, presetTemplate.drones.mining)
			end
			upgradeplan.drone.ship_gen_s_fightingdrone_01_a_macro = RKN_Configio.getProportionateCount(droneCapacity, presetTemplate.drones.defence)
			upgradeplan.drone.ship_gen_xs_repairdrone_01_a_macro = RKN_Configio.getProportionateCount(droneCapacity, presetTemplate.drones.repair)
		end
		local deployCapacity = C.GetMacroDeployableCapacity(menu.macro)
		if deployCapacity > 0 then
			upgradeplan.deployable.eq_arg_satellite_02_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.advsatellite)
			upgradeplan.deployable.eq_arg_satellite_01_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.satellite)
			upgradeplan.deployable.env_deco_nav_beacon_t1_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.navbeacon)
			upgradeplan.deployable.eq_arg_resourceprobe_01_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.resprobe)
			upgradeplan.deployable.ship_gen_xs_lasertower_01_a_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.lastower1)
			upgradeplan.deployable.ship_gen_s_lasertower_01_a_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.lastower2)
			upgradeplan.deployable.weapon_gen_mine_03_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.ffmine)
			upgradeplan.deployable.weapon_gen_mine_01_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.mine)
			upgradeplan.deployable.weapon_gen_mine_02_macro = RKN_Configio.getProportionateCount(deployCapacity, presetTemplate.deployables.trackmine)
		end
		local counterCapacity = C.GetDefaultCountermeasureStorageCapacity(menu.macro)
		if counterCapacity > 0 then
			upgradeplan.countermeasure.countermeasure_flares_01_macro = RKN_Configio.getProportionateCount(counterCapacity, presetTemplate.countermeasure.flares)
		end
		--C.GetMacroMissileCapacity(currentmacro)
	end

	return upgradeplan
end

function RKN_Configio.getProportionateCount(totalCapacity, preset)
	if not preset then
		return 0
	end
	return math.floor(totalCapacity * (preset / 100))
end

function RKN_Configio.chooseMacroByRules(menu, possiblemacros, rules)
	for _, rule in ipairs(rules) do
		local macro
		if rule.type == "exact" then
			macro = RKN_Configio.chooseMacroByExactRule(possiblemacros, rule)
		elseif rule.type == "auto" then
			macro = RKN_Configio.chooseMacroByAutoRule(menu, possiblemacros, rule)
		end
		if macro then
			return macro
		end
	end
	return nil
end

function RKN_Configio.chooseMacroByExactRule(possiblemacros, rule)
	if not rule.macro then
		return nil
	end
	local aliases = RKN_Configio.getAliases()
	for _, macro in ipairs(possiblemacros) do
		if macro == rule.macro or aliases[rule.macro] == macro then
			return macro
		end
	end
	return nil
end

function RKN_Configio.chooseMacroByAutoRule(menu, possiblemacros, rule)
	if not rule.race or not rule.value or not menu.container then -- if menu.container == nil then we are not at a shipyard, and cannot get prices.
		return nil
	end

	-- First filter by race
	local filteredMacros = {}
	for _, macro in ipairs(possiblemacros) do
		local macroRaces, ware = GetMacroData(macro, "makerraceid", "ware")
		if rule.race == "any" or RKN_Configio_Utils.ArrayIndexOf(macroRaces, rule.race) then
			if RKN_Configio.params.settingKey == RKN_Configio.config.shipLoadoutKey then
				local tradelicence = GetWareData(ware, "tradelicence")
				if menu.isplayerowned or (not tradelicence) or tradelicence == "" or HasLicence("player", tradelicence, menu.containerowner) then
					table.insert(filteredMacros, { macro = macro })
				end
			else
				table.insert(filteredMacros, { macro = macro })
			end
		end
	end
	if #filteredMacros == 0 then
		return nil
	end
	-- Now sort by price and choose by rule value
	for _, macro in ipairs(filteredMacros) do
		local ware = GetMacroData(macro.macro, "ware")
		if ware then
			local price = tonumber(C.GetBuildWarePrice(menu.container, ware))
			macro.price = price
		else
			macro.price = 0
		end
	end
	table.sort(filteredMacros, function (a, b) return a.price < b.price end)
	if rule.value == "low" then
		return filteredMacros[1].macro
	elseif rule.value == "medium" then
		return filteredMacros[math.floor(#filteredMacros / 2)].macro
	elseif rule.value == "high" then
		return filteredMacros[#filteredMacros].macro
	else
		return nil
	end
end

-- Created by Eliptus
-- Edited and integrated by Runekn
function RKN_Configio.addPartialFlag(loadouts)
	if RKN_Configio.getSettings().item_load_partial then
		for _, loadout in ipairs(loadouts) do
			if not loadout.active then
				loadout.name = loadout.name
				loadout.active = true
				loadout.partial = true
			end
		end
	end
	return loadouts
end

-- Created by Eliptus
-- Edited and integrated by Runekn
function RKN_Configio.trimPartialLoadout(currentUpgradePlan, upgradeplan, upgradewares, isShipyard)
	for type,plan in pairs(upgradeplan) do
		local spec = Helper.findUpgradeType(type)
		local wares = upgradewares[type]

		local groupSuffix = "group"
		if type:sub(-#groupSuffix) == groupSuffix then
			local slotType = type:sub(1, #type - #groupSuffix)
			spec = Helper.findUpgradeType(slotType)
			wares = upgradewares[slotType]
		end

		if spec == nil or wares == nil then
			-- skip

		elseif spec.supertype == 'macro' or spec.supertype == 'virtualmacro' then
			-- plan[slot]['macro'] = macro
			for slot,info in pairs(plan) do
				local alreadyBuilt = currentUpgradePlan[type][slot].macro == info.macro
				local buildable = RKN_Configio_Utils.Any(wares, function(v, _) return v.macro == info.macro and (v.isFromShipyard or not isShipyard) end)
				if not buildable then
					if alreadyBuilt then
						info.count = currentUpgradePlan[type][slot].count
					else
						info.macro = ''
						if info.count then
							info.count = 0
						end
					end
				end
			end

		elseif spec.supertype == 'ammo' then
			local missile = type == "missile" -- Don't preserve existing missiles that cannot be built at this shipyard. This is due to left bar sliders setting max value to 0 and thus crashing UI
			-- plan[macro] = count
			for macro,_ in pairs(plan) do
				if not RKN_Configio_Utils.Any(wares, function(v, _) return v.macro == macro and (v.isFromShipyard or not missile) end) then
					plan[macro] = 0
				end
			end

		elseif spec.supertype == 'software' then
			-- plan[slot] = ware
			for slot,ware in pairs(plan) do
				if not RKN_Configio_Utils.Any(wares, function(v, _) return v.ware == ware end) then
					plan[slot] = ''
				end
			end

		end
	end
end

function RKN_Configio.createShipOptions(menu)
	local shipOptions = {}
	for _, shipmacros in pairs(menu.availableshipmacrosbyclass) do
		for _, macro in ipairs(shipmacros) do
			local haslicence, icon, overridecolor, mouseovertext, limitstring = menu.checkLicence(macro, true)
			local name, infolibrary, shiptypename, primarypurpose, shipicon, races = GetMacroData(macro, "name", "infolibrary", "shiptypename", "primarypurpose", "icon", "makerraceid")
			local class = ffi.string(C.GetMacroClass(macro))
			local text =  "\27[" .. shipicon .. "] " .. name .. " - " .. shiptypename .. limitstring
			local hasBlueprint = C.GetNumBlueprints("", "", macro) > 0
			if #races == 0 then
				table.insert(races, "other")
			end
			local modicon = nil
			-- TODO: get working
			--local modquality = C.GetHighestEquipmentModQuality(macro)
			--if modquality > 0 then
				--modicon = " \27[mods_grade_0" .. modquality .. "]"
			--end
			table.insert(shipOptions, {
				id = macro,
				text = text,
				icon = icon or "", displayremoveoption = false,
				overridecolor = overridecolor,
				mouseovertext = mouseovertext,
				shipicon = shipicon,
				hasBlueprint = hasBlueprint,
				shiptypename = shiptypename,
				name = name .. limitstring,
				objectid = "",
				class = class,
				purpose = primarypurpose,
				races = races,
				helpOverlayID = "shipconfig_shipoptions_" .. macro,
				helpOverlayText = " ",
				helpOverlayHighlightOnly = true,
				modicon = modicon
			})
		end
	end
	return shipOptions
end

function RKN_Configio.getShipPurposes(shipOptions)
	local purposes = {}
	for _, ship in ipairs(shipOptions) do
		if not purposes[ship.purpose] then
			local name = RKN_Configio.config.shipPurposeNames[ship.purpose]
			if not name then
				name = ship.purpose:gsub("^%l", string.upper)
			end
			table.insert(purposes, { id = ship.purpose, text = name })
			purposes[ship.purpose] = true
		end
	end
	table.sort(purposes, function(a,b) return a.text < b.text end)
	return purposes
end

function RKN_Configio.getShipRaces(shipOptions)
	local races = {}
	local raceNameMap = RKN_Configio.getRaceNameMap()
	for _, ship in ipairs(shipOptions) do
		for _, race in ipairs(ship.races) do
			if not races[race] then
				local name = race == "other" and ReadText(RKN_Configio.config.textId, 106) or raceNameMap[race]
				table.insert(races, { id = race, text = name })
				races[race] = true
			end
		end
	end
	table.sort(races, function(a,b)
		if b.id == "other" then
			return true
		elseif a.id == "other" then
			return false
		end
		return a.text < b.text
	end)
	return races
end

function RKN_Configio.clearFilterIfNotAvailable(filter, options)
	if not filter then
		return
	end
	for id, _ in pairs(filter) do
		local found = false
		for _, op in ipairs(options) do
			if id == op.id then
				found = true
				break
			end
		end
		if not found then
			filter[id] = nil
		end
	end
end

function RKN_Configio.sortShips(a, b, o)
	if o == "default" then
		return Helper.sortShipsByClassAndPurpose(a.item, b.item)
	elseif o == "type" then
		return RKN_Configio.compareShipType(a,b)
	end
	return RKN_Configio.compareItemNames(a,b)
end

function RKN_Configio.renameStationLoadout(menu, item, newName)
	if item.customPreset then
		item.customPreset.name = newName
		RKN_Configio.saveAutoPreset(item.customPreset, item.customPreset.id)
	else
		local loadout = Helper.getLoadoutHelper(C.GetLoadout, C.GetLoadoutCounts, 0, menu.loadoutModule.macro, item.id)
		C.SaveLoadout(menu.loadoutModule.macro, loadout, "local", "player", false, newName, "") -- overwrite does not update the name. Have to create brand new.
		C.RemoveLoadout("local", menu.loadoutModule.macro, item.id)
		menu.getPresetLoadouts()
	end
end

function RKN_Configio.renameShipLoadout(menu, item, newName)
	if item.customPreset then
		item.customPreset.name = newName
		RKN_Configio.saveAutoPreset(item.customPreset, item.customPreset.id)
	else
		local loadout = Helper.getLoadoutHelper2(C.GetLoadout2, C.GetLoadoutCounts2, "UILoadout2", menu.object, menu.macro, item.id)
		local macro = (menu.macro ~= "") and menu.macro or GetComponentData(ConvertStringToLuaID(tostring(menu.object)), "macro")
		C.SaveLoadout2(macro, loadout, "local", "player", false, newName, "") -- overwrite does not update the name. Have to create brand new.
		C.RemoveLoadout("local", macro, item.id)
		menu.getPresetLoadouts()
	end
end

function RKN_Configio.getCreativeCrewOptions()
	if not RKN_Configio.creativeCrewOptions then
		RKN_Configio.creativeCrewOptions = {}
		local n = C.GetNumPlayerPeopleDefinitions()
		local buf = ffi.new("PeopleDefinitionInfo[?]", n)
		n = C.GetPlayerPeopleDefinitions(buf, n)
		for i = 0, n - 1 do
			table.insert(RKN_Configio.creativeCrewOptions, { id = ffi.string(buf[i].id), text = ffi.string(buf[i].name), icon = "", displayremoveoption = false, mouseovertext = ffi.string(buf[i].desc) })
		end
		table.sort(RKN_Configio.creativeCrewOptions, function (a, b) return a.text < b.text end)
		table.insert(RKN_Configio.creativeCrewOptions, 1, { id = "none", text = ReadText(1001, 9931), icon = "", displayremoveoption = false })
	end
	return RKN_Configio.creativeCrewOptions
end

function RKN_Configio.compareItemNames(a, b)
	return a.name:lower() < b.name:lower()
end

function RKN_Configio.compareShipType(a, b)
	if a.item.shiptypename == b.item.shiptypename then
		if a.item.class == b.item.class then
			return RKN_Configio.compareItemNames(a,b)
		end
		return RKN_Configio.config.shipSizeOrder[a.item.class] < RKN_Configio.config.shipSizeOrder[b.item.class]
	end
	return a.item.shiptypename < b.item.shiptypename
end