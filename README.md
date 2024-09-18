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

### How does groups work?

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
 
### How does 'Flatten one-item group' work?

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

### How does 'Custom Auto-generated Preset' work?

You know those default loadout presets called "High Preset", "Medium Preset", etc? Have you ever wanted something like that, but with more freedom to define exactly how it chooses each loadout module? For example "High Preset, but only Argon modules". That's what this feature seeks to accomplish.

Lets go through each type of setting in the auto-preset editor.

The entire left side allows you to setup rules for how it will match modules. Use the dropdowns for each module type to add a rule. You can add multiple rules, and order them by priority. Rules will be evaluated from the top, and will continue to the next if that rule did not find any match. There are currently only two types of rules, "Match exact" and "Match by race and value".
Match exact is self-explanatory and just looks for the exact module you have selected. The module options only show those that are known to your character.
Match by race and value is more automatic, and allows you to specify the race of the module, aswell as the general price of the module. The selection based on value is very simple right now, as it just sorts the modules by price and picks either the highest, lowest, or median.
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

## Thanks to
* netUpb/fikrethos: for feedback and help with code.

## Updates

* 1.1: Custom auto-generated presets. Delete confirmation. Fix delete and load buttons.
* 1.0: Initial release