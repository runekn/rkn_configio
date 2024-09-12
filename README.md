# Expanded Configuration Loader

## Description
Replaces the simple dropdown to load stations, ships, or loadouts with a bigger and more feature-rich dialog.

* Wider dialog: allowing for displaying of much longer names without cutting off.
* Groups: Organize your presets by including a delimiter character in the name, which this new dialog will use create a pseudo folder structure. You can thereby organize stations by mods, factions, production type, or whatever you like.
* Search: Quickly find what you're looking for by typing part of it's name.
* Production module filter: Filter stations by what production modules are included.
* Ship race filter: Now you can easily find the boron ships in your long list of blueprints.
* Disable mod by menu: Don't like the new dialog for a specific menu (station plans, module loadout, ship loadout)? You can disable them individually.

### How does groups work?

Let's say you have three station plans:

 - ARG/EnergyCells/The First
 - ARG/EnergyCells/The Second
 - ARG/Wharf/Big Boy
 
If we enable groups, and set the delimiter to slash '/', then the list will reorganize into the follwing structure:
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

## Requirements

* SirNuke's Mod Support API [[Steam](https://steamcommunity.com/sharedfiles/filedetails/?id=2042901274) | [Nexus](https://www.nexusmods.com/x4foundations/mods/503)]

## Compatibility

This mod is save compatible. You can add it to an existing save, and remove it without errors.

This mod is NOT guaranteed to be compatible with other mods that make changes to the station or ship designer UI.

## Thanks to
* netUpb/fikrethos: for feedback and help with code.

## Updates

* 1.0: Initial release