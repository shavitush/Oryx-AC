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

#include <sourcemod>
#include <oryx>

#pragma newdecls required
#pragma semicolon 1

#define DESC1 "Unsynchronised movement"
#define DESC2 "Invalid wish velocity"
#define DESC3 "Wish velocity is too high"

EngineVersion gEV_Type = Engine_Unknown;
float gF_FullPress = 0.0;

public Plugin myinfo = 
{
	name = "ORYX sanity module",
	author = "Rusty, shavit",
	description = "Sanity checks on movement tampering.",
	version = ORYX_VERSION,
	url = "https://github.com/shavitush/Oryx-AC"
}

public void OnPluginStart()
{
	gEV_Type = GetEngineVersion();

	// cl_forwardspeed's and cl_sidespeed's default setting.
	if(gEV_Type == Engine_CSS)
	{
		gF_FullPress = 400.0;
	}

	else if(gEV_Type == Engine_CSGO || gEV_Type == Engine_TF2)
	{
		gF_FullPress = 450.0;
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	if(!IsPlayerAlive(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	// Invalid usercmd->forwardmove or usercmd->sidemove.
	// cl_forwardspeed and cl_sidespeed are the fully-pressed move values.
	// The game will never apply them unless the buttons are added into the usercmd too.
	// Also, the the move values cannot be anything other than: 0, speed * 0.25, speed * 0.5, speed * 0.75, and speed.
	//
	// https://mxr.alliedmods.net/hl2sdk-css/source/game/client/in_main.cpp#557
	// https://mxr.alliedmods.net/hl2sdk-css/source/game/client/in_main.cpp#842

	if((vel[0] == gF_FullPress && (buttons & IN_FORWARD) == 0) ||
	   (vel[1] == -gF_FullPress && (buttons & IN_MOVELEFT) == 0) ||
	   (vel[0] == -gF_FullPress && (buttons & IN_BACK) == 0) ||
	   (vel[1] == gF_FullPress && (buttons & IN_MOVERIGHT) == 0))
	{
		Oryx_Trigger(client, TRIGGER_DEFINITIVE, DESC1);
	}
	
	else if(!IsValidMove(vel[0]) || !IsValidMove(vel[1]))
	{
		Oryx_Trigger(client, TRIGGER_DEFINITIVE, DESC2);
	}

	else if(FloatAbs(vel[0]) > gF_FullPress || FloatAbs(vel[1]) > gF_FullPress)
	{
		Oryx_Trigger(client, TRIGGER_DEFINITIVE, DESC3);
	}

	return Plugin_Continue;
}

bool IsValidMove(float num)
{
	num = FloatAbs(num);

	// VERY minor optimization loss, but makes the coder less annoying to read.
	float speed = gF_FullPress;

	return (num == 0.0 || num == speed || num == (speed * 0.75) || num == (speed * 0.50) || num == (speed * 0.25));
}
