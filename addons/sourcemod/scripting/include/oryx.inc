/*  Oryx AC: collects and analyzes statistics to find some cheaters in CS:S, CS:GO, and TF2 bunnyhop.
 *  Copyright (C) 2018  Nolan O.
 *  Copyright (C) 2018  shavit.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#if defined _oryx_included
	#endinput
#endif
#define _oryx_included

#define ORYX_VERSION "1.1"

/**
* List of current detection descriptions:
* 
* "Acute TR formatter"
* "+left/right bypasser"
* "Prestrafe tool"
* "Average strafe too close to 0"
* "Too many perfect strafes"
* "Movement config"
* "Unsynchronised movement"
* "Invalid wish velocity"
* "Script on scroll"
* "Hyperscroll"
*/

enum
{
	TRIGGER_LOW,			// Reachable by skilled players occasionally. Not always necessary before a med detect.
	TRIGGER_MEDIUM,			// Reachable by skilled players by unlikely chance.
	TRIGGER_HIGH,			// Only theoretically reachable by the aligning of stars by the gods.
	TRIGGER_HIGH_NOKICK,	// This should really only be used for a follow up definitive detection.
	TRIGGER_DEFINITIVE,		// Non-skill-based detection type. 100% sure detection.
	TRIGGER_TEST			// Allows you to develop new detections on live servers with minimal side effects.
};

/**
 * Acceptable timers: "bhoptimer" & "notimer"
 */
#define bhoptimer

/**
 * Call to activate oryx's trigger procedure (logging, kicking, admin notifications, etc..).
 *
 * @param client				Client entity index.
 * @param level					Level of detection as defined in the above enum.
 * @param cheat					Short description or name of the cheat being detected.
 * @noreturn
 */
native void Oryx_Trigger(int client, int level, char[] cheat);

/**
 * Prints a message to admins' chat.
 *
 * @param msg 					Pre-formatted message to print to admins.
 * @noreturn
 */
native void Oryx_PrintToAdmins(char[] msg);

/**
 * Prints a message to admins' console.
 *
 * @param msg 					Pre-formatted message to print to admins.
 * @noreturn
 */
native void Oryx_PrintToAdminsConsole(char[] msg);

/**
 * Tests if f1 is within a 1/frac threshold of f2.
 *
 * @param f1					First value.
 * @param f2					Second value.
 * @param frac					Used as a fractional threshold of f2 for f1 to be within.
 * @return 						True if the test passed.
 */
native bool Oryx_WithinFlThresh(float f1, float f2, float frac);
