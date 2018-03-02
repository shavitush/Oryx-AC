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

#if defined bhoptimer
#undef REQUIRE_PLUGIN
#include <shavit>
#endif

#pragma newdecls required
#pragma semicolon 1

#define DESC1 "Movement config"

int gI_PerfectConfigStreak[MAXPLAYERS+1];
int gI_PreviousButtons[MAXPLAYERS+1];
#if defined bhoptimer
int gI_JumpsFromZone[MAXPLAYERS+1];
#endif

public Plugin myinfo = 
{
	name = "ORYX movement config module",
	author = "Rusty, shavit",
	description = "Detects movement configs (null binds, \"k120 syndrome\" etc).",
	version = ORYX_VERSION,
	url = "https://github.com/shavitush/Oryx-AC"
}

public void OnPluginStart()
{
	RegAdminCmd("config_streak", Command_ConfigStreak, ADMFLAG_BAN, "Print the config stat buffer for a given player.");

	LoadTranslations("common.phrases");
}

public void OnClientPutInServer(int client)
{
	gI_PerfectConfigStreak[client] = 0;
	#if defined bhoptimer
	gI_JumpsFromZone[client] = 0;
	#endif
}

public Action Command_ConfigStreak(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "Usage: config_streak <target>");

		return Plugin_Handled;
	}
	
	char[] sArgs = new char[MAX_TARGET_LENGTH];
	GetCmdArgString(sArgs, MAX_TARGET_LENGTH);

	int target = FindTarget(client, sArgs);

	if(target == -1)
	{
		return Plugin_Handled;
	}

	char[] sAuth = new char[32];
	
	if(!GetClientAuthId(target, AuthId_Steam3, sAuth, 32))
	{
		strcopy(sAuth, 32, "ERR_GETTING_ID");
	}
		
	ReplyToCommand(client, "\n\n\nUser \x03%N\x01 (\x05%s\x01) is on a config streak of \x04%d\x01.", target, sAuth, gI_PerfectConfigStreak[target]);
	
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	if(!IsPlayerAlive(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}

	int iFlags = GetEntityFlags(client);
	
	#if defined bhoptimer
	// Attempt at only sampling real gameplay (out of the start zone).
	if(Shavit_InsideZone(client, Zone_Start, -1))
	{
		gI_JumpsFromZone[client] = 0;

		return Plugin_Continue;
	}
	
	if((iFlags & FL_ONGROUND) > 0 && (buttons & IN_JUMP) > 0)
	{
		gI_JumpsFromZone[client]++;
	}
		
	if(gI_JumpsFromZone[client] < 2)
	{
		return Plugin_Continue;
	}
	#endif
	
	if((iFlags & FL_ONGROUND) == 0)
	{
		// Check for perfect transitions in W/A/S/D.
		if(((buttons & IN_MOVELEFT) == 0 && (buttons & IN_MOVERIGHT) > 0 && (gI_PreviousButtons[client] & IN_MOVERIGHT) == 0 && (gI_PreviousButtons[client] & IN_MOVELEFT) > 0) || 
			((buttons & IN_MOVERIGHT) == 0 && (buttons & IN_MOVELEFT) > 0 && (gI_PreviousButtons[client] & IN_MOVELEFT) == 0 && (gI_PreviousButtons[client] & IN_MOVERIGHT) > 0) ||
			((buttons & IN_FORWARD) == 0 && (buttons & IN_BACK) > 0 && (gI_PreviousButtons[client] & IN_BACK) == 0 && (gI_PreviousButtons[client] & IN_FORWARD) > 0) ||
			((buttons & IN_BACK) == 0 && (buttons & IN_FORWARD) > 0 && (gI_PreviousButtons[client] & IN_FORWARD) == 0 && (gI_PreviousButtons[client] & IN_BACK) > 0))
		{
			PerfectTransition(client);
		}

		// Are both moveleft/moveright pressed?
		else if(buttons & (IN_MOVELEFT | IN_MOVERIGHT) == (IN_MOVELEFT | IN_MOVERIGHT))
		{
			gI_PerfectConfigStreak[client] = 0;
		}
	}

	gI_PreviousButtons[client] = buttons;

	return Plugin_Continue;
}

void PerfectTransition(int client)
{
	if(++gI_PerfectConfigStreak[client] < 150)
	{
		return;
	}

	if(gI_PerfectConfigStreak[client] == 250)
	{
		Oryx_Trigger(client, TRIGGER_LOW, DESC1);
	}

	else if(gI_PerfectConfigStreak[client] == 330)
	{
		Oryx_Trigger(client, TRIGGER_MEDIUM, DESC1);
	}

	else if(gI_PerfectConfigStreak[client] % 510 == 0) // 510 or above
	{
		Oryx_Trigger(client, TRIGGER_HIGH_NOKICK, DESC1);
	}
}
