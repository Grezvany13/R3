/*
 * Author: Titan
 * Loops through all infantry units on the map and saves to db event buffer
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * call FUNC(movementsInfantry);
 *
 * Public: No
 */

#include "script_component.hpp"
private _functionLogName = "AAR > movementsInfantry";

private _movementData = "";

// Loop through all units on the map
{
    [_x] call FUNC(addInfantryEventHandlers);

    if (vehicle _x == _x && !(_x isKindOf "Logic")) then {

        private _unitUid = getPlayerUID _x;
        private _unitPos = getPos _x;
        private _unitDirection = round getDir _x;
        private _unitIconRaw = getText (configFile >> "CfgVehicles" >> (typeOf _x) >> "icon");
        private _unitIcon = _unitIconRaw splitString "\" joinString "";
        private _unitFaction = _x call FUNC(calcSideInt);
        private _unitGroupId = groupID group _x;
        private _unitIsLeader = (if((leader group _x) == _x) then { true } else { false });

        // Save player to db
        [_unitUid, name _x] spawn FUNC(dbSavePlayer);

        // Form JSON for saving
        // It sucks we have to use such abbreviated keys but we need to save as much space as pos!
        private _singleUnitMovementData = format['
            {
                "unit": "%1",
                "id": "%2",
                "pos": %3,
                "dir": %4,
                "ico": "%5",
                "fac": "%6",
                "grp": "%7",
                "ldr": "%8"
            }',
            _x,
            _unitUid,
            _unitPos,
            _unitDirection,
            _unitIcon,
            _unitFaction,
            _unitGroupId,
            _unitIsLeader
        ];

        // We don't want leading commas in our JSON
        private _seperator = if (_movementData == "") then { "" } else { "," };

        // Combine this unit's data with our current running movements data
        _movementData = [[_movementData, _singleUnitMovementData], _seperator] call CBA_fnc_join;
    };
} forEach allUnits;

// Send the json to our extension for saving to the db
if (_movementData != "") then {

    private _movementDataJsonArray = format["[%1]", _movementData];
    ["positions_infantry", _movementDataJsonArray] call FUNC(dbInsertEvent);
};
