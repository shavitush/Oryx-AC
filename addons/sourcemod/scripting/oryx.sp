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
#include <sdktools>
#include <oryx>

#pragma newdecls required
#pragma semicolon 1

EngineVersion gEV_Type = Engine_Unknown;

char gS_LogPath[PLATFORM_MAX_PATH];
char gS_BeepSound[PLATFORM_MAX_PATH];

bool gB_Testing[MAXPLAYERS+1];
bool gB_Locked[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "ORYX Anti-Cheat",
	author = "Rusty, shavit",
	description = "Cheat detection interface.",
	version = ORYX_VERSION,
	url = "https://github.com/shavitush/Oryx-AC"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Oryx_Trigger", Native_OryxTrigger);
	CreateNative("Oryx_WithinFlThresh", Native_WithinFlThresh);
	CreateNative("Oryx_PrintToAdmins", Native_PrintToAdmins);
	CreateNative("Oryx_PrintToAdminsConsole", Native_PrintToAdminsConsole);

	// registers library, check "bool LibraryExists(const char[] name)" in order to use with other plugins
	RegPluginLibrary("oryx");

	return APLRes_Success;
}

public void OnPluginStart()
{
	gEV_Type = GetEngineVersion();

	CreateConVar("oryx_version", ORYX_VERSION, "Plugin version.", (FCVAR_NOTIFY | FCVAR_DONTRECORD));
	
	RegAdminCmd("sm_otest", Command_OryxTest, ADMFLAG_BAN, "Enables the TRIGGER_TEST detection level.");
	RegAdminCmd("sm_lock", Command_LockPlayer, ADMFLAG_BAN, "Disables movement for a player.");

	LoadTranslations("common.phrases");
	
	BuildPath(Path_SM, gS_LogPath, PLATFORM_MAX_PATH, "logs/oryx-ac.log");
}

public void OnMapStart()
{
	// Beep sounds.
	Handle hConfig = LoadGameConfigFile("funcommands.games");

	if(hConfig == null)
	{
		SetFailState("Unable to load game config funcommands.games");

		return;
	}
	
	if(GameConfGetKeyValue(hConfig, "SoundBeep", gS_BeepSound, PLATFORM_MAX_PATH))
	{
		PrecacheSound(gS_BeepSound, true);
	}
}

public void OnClientPutInServer(int client)
{
	gB_Locked[client] = false;
	gB_Testing[client] = false;
}

public Action Command_OryxTest(int client, int args)
{
	gB_Testing[client] = !gB_Testing[client];
	ReplyToCommand(client, "Testing is %s.", (gB_Testing[client])? "on":"off");

	return Plugin_Handled;
}

public Action Command_LockPlayer(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "Usage: sm_lock <target>");

		return Plugin_Handled;
	}
	
	char[] sArgs = new char[MAX_TARGET_LENGTH];
	GetCmdArgString(sArgs, MAX_TARGET_LENGTH);

	int target = FindTarget(client, sArgs);

	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	gB_Locked[target] = !gB_Locked[target];
	ReplyToCommand(client, "Player has been %s.", (gB_Locked[target])? "locked":"unlocked");
	PrintToChat(target, "An admin has %s your ability to move!", (gB_Locked[target])? "locked":"unlocked");

	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3])
{
	// Movement is locked, don't allow anything.
	if(gB_Locked[client])
	{
		buttons = 0;
		vel[0] = 0.0;
		vel[1] = 0.0;
		impulse = 0;

		return Plugin_Changed;
	}

	return Plugin_Continue;
}

public int Native_OryxTrigger(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int level = GetNativeCell(2);
	
	char[] sLevel = new char[16];
	char[] sCheatDescription = new char[32];

	GetNativeString(3, sCheatDescription, 32);

	if(level == TRIGGER_LOW)
	{
		strcopy(sLevel, 16, "LOW");
	}

	else if(level == TRIGGER_MEDIUM)
	{
		strcopy(sLevel, 16, "MEDIUM");
	}

	else if(level == TRIGGER_HIGH)
	{
		strcopy(sLevel, 16, "HIGH");
		KickClient(client, "%s", sCheatDescription);
	}

	else if(level == TRIGGER_HIGH_NOKICK)
	{
		strcopy(sLevel, 16, "HIGH-NOKICK");
	}

	else if(level == TRIGGER_DEFINITIVE)
	{
		strcopy(sLevel, 16, "DEFINITIVE");
		KickClient(client, "%s", sCheatDescription);
	}

	else if(level == TRIGGER_TEST)
	{
		char[] sBuffer = new char[128];
		Format(sBuffer, 128, "(\x03%N\x01) - %s | Level: %s", client, sCheatDescription, "TESTING");

		for(int i = 1; i <= MaxClients; i++)
		{
			if(gB_Testing[i] && IsClientInGame(i))
			{
				PrintToChat(i, "%s", sBuffer);
			}
		}

		return;
	}

	char[] sAuth = new char[32];
	GetClientAuthId(client, AuthId_Steam3, sAuth, 32);

	char[] sBuffer = new char[128];
	Format(sBuffer, 128, "\x03%N\x01 - \x05%s\x01 Cheat: %s | Level: %s", client, sAuth, sCheatDescription, sLevel);
	Oryx_PrintToAdmins(sBuffer);
	
	LogToFileEx(gS_LogPath, "%L - Cheat: %s | Level: %s", client, sCheatDescription, sLevel);
}

public int Native_WithinFlThresh(Handle plugin, int numParams)
{
	float f2 = GetNativeCell(2);
	float t = f2 / GetNativeCell(3);
	float f1 = GetNativeCell(1);

	return (f1 > (f2 - t) && f1 < (f2 + t));
}

public int Native_PrintToAdmins(Handle plugin, int numParams)
{
	char[] sMessage = new char[128];
	GetNativeString(1, sMessage, 128);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(CheckCommandAccess(i, "oryx_admin", ADMFLAG_GENERIC))
		{
			PrintToChat(i, "%s\x04[ORYX]\x01 %s", (gEV_Type == Engine_CSGO)? " ":"", sMessage);

			if(gEV_Type == Engine_CSS || gEV_Type == Engine_TF2)
			{
				EmitSoundToClient(i, gS_BeepSound);
			}

			else
			{
				ClientCommand(i, "play */%s", gS_BeepSound);
			}
		}
	}
}

public int Native_PrintToAdminsConsole(Handle plugin, int numParams)
{
	char[] sMessage = new char[128];
	GetNativeString(1, sMessage, 128);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(CheckCommandAccess(i, "oryx_admin", ADMFLAG_GENERIC))
		{
			PrintToConsole(i, "[ORYX] %s", sMessage);
		}
	}
}
