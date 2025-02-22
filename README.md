# Expanded Configuration Loader

## Description
Replaces the simple dropdown to load stations, ships, or loadouts with a bigger and more feature-rich dialog.

* Wider dialog: allowing for displaying of much longer names without cutting off.
* Groups: Organize your presets by including a delimiter character in the name, which this new dialog will use create a pseudo folder structure. You can thereby organize stations by mods, factions, production type, or whatever you like.
* Search: Quickly find what you're looking for by typing part of it's name.
* Production module filter: Filter stations by what production modules are included.
* Ship race filter: Now you can easily find the boron ships in your long list of blueprints.
* Disable mod by menu: Don't like the new dialog for a specific menu (station plans, module loadout, ship loadout)? You can disable them individually.
* Custom auto-generated loadout presets: Generate loadouts based on custom criteria, so you don't have to build every loadout from scratch.
* Partial loading: Allows you to load ship presets that you would not normally be able to due to missing blueprints.

### Groups

Let's say you have three station plans:

 - ARG/EnergyCells/The First
 - ARG/EnergyCells/The Second
 - ARG/Wharf/Big Boy
 
If we enable groups, and set the delimiter to slash '/', then the list will reorganize into the following structure:
 ```
 - [-] ARG				<-- collapsible group
 -     [-] EnergyCells		
 -         The First			<-- station plan
 -         The Second			
 -     [-] Wharf
 -         Big Boy
 ```
 
#### 'Flatten one-item group' setting

In the example in the previous section, we can see that "ARG/Wharf/Big Boy" takes up two rows when organized into groups, which is double of what it did without grouping. We could collapse the group, but this would still be strictly worse than ungrouped because we now can't see what the group contains.
The option 'Flatten one-item group' just ungroups these items. Meaning that it would result in following structure:
```
 - [-] ARG
 -     [-] EnergyCells		
 -         The First
 -         The Second			
 -     Wharf/Big Boy
 ```

The 'EnergyCells' group is left untouched because it contains more than one item. Note that 'Flatten one-item group' is recursive, meaning that if the group ARG also contained just one item after applying it, it too would be ungrouped.

### Custom Auto-generated Preset

You know those default loadout presets called "High Preset", "Medium Preset", etc? Have you ever wanted something like that, but with more freedom to define exactly how it chooses each loadout module? For example "High Preset, but only Argon modules". That's what this feature seeks to accomplish.

Lets go through each type of setting in the auto-preset editor.

The entire left side allows you to setup rules for how it will match modules. Use the dropdowns for each module type to add a rule. You can add multiple rules, and order them by priority. Rules will be evaluated from the top, and will continue to the next if that rule did not find any match. There are currently only two types of rules, "Match exact" and "Match by race and value".
Match exact is self-explanatory and just looks for the exact module you have selected. The module options only show those that are known to your character.
Match by race and value is more automatic, and allows you to specify the race of the module, as-well as the general price of the module. The selection based on value is very simple right now, as it just sorts the modules by price and picks either the highest, lowest, or median.
Unlike with the default auto-presets, these will always attempt to fill out every slot.

The software selection only allows for choosing exact software.

The sliders for crew, drones, deployables, and flares are percentage based. So if you set Service crew to 70% and Marines to 10%, select the preset for a ship with crew capacity of 130, then it will choose 91 service crew and 13 marine. The total value of each slider section cannot go above 100%, for obvious reasons.

If you ever want to edit an auto-preset, you can select one in the loader and click "Edit Selected in Editor". And just like with vanilla saving, you can overwrite as long as the name is the same.

*NOTE: The editor does not currently have any options for missiles.*

*NOTE: The custom auto-presets are tied to the save. They will NOT appear between different saves.*

## Requirements

* SirNuke's Mod Support API [[Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274) | [Nexus](https://www.nexusmods.com/x4foundations/mods/503)]

## Compatibility

This mod is save compatible. You can add it to an existing save, and remove it without errors.

This mod is NOT guaranteed to be compatible with other mods that make changes to the station or ship designer UI.

Use along-side VRO can break the "Race filter" during ship selection, unless this is also installed: [Maker-race fix for VRO](https://www.nexusmods.com/x4foundations/mods/1523/)

Does not support resolutions lower than 1920x1080

## Thanks to
* netUpb/fikrethos: for feedback and help with code.
* Eliptus: author of partial loadout, which I was given permission to incorporate.

## Updates

* 1.4.7: Use new official lua declaration to avoid requiring disabled UI protection mode
* 1.4.6: Fix 7.5 compatibility. Add "Type" ship sorting option.
* 1.4.5: Add production modules to station plan mouse-over text
* 1.4.4: Ignore case when sorting by name
* 1.4.3: Fixed UI when playing with 1440 vertical resolution
* 1.4.2: Fixed "Rename ship using loadout name" not working for partial or custom auto presets.
* 1.4.1: Fixed hidden filter removing all ships in ship selection. Added partial loadout loading to station modules.
* 1.4: Improved ship selection list. Now shows icons for the ship and whether you own the blueprint.
* 1.3: Added 'Save As' button. Remade settings switches. Added icons to button row.
* 1.2.1: Fixed unresponsive station map after opening a context menu.
* 1.2: Added option for loading partial ship loadout. Add size and purpose filter in ship selection. Remove ship size dropdown. Add sorting dropdown. Add rename button for ship and station module loadouts. Remove 'other' race option in auto-preset editor. Disable race dropdown for thruster auto rule.
* 1.1: Added auto-generated preset editor. Added custom delete confirmation dialog. Fixed delete and load buttons working despite being inactive.
* 1.0: Initial release