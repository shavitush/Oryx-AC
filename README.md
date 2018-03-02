[![Discord server](https://discordapp.com/api/guilds/389675819959844865/widget.png?style=shield)](https://discord.gg/jyA9q5k)

### Build status
[![Build status](https://travis-ci.org/shavitush/Oryx-AC.svg?branch=master)](https://travis-ci.org/shavitush/Oryx-AC)

# The Oryx bunnyhop anticheat for CS:S, CS:GO, and TF2.

This is a fork of Oryx, the bunnyhop anticheat written by Rusty/Nolan-O. The README will be mostly left untouched unless I need to change anything.

The main differences from the original version are:

* I have supported CS:GO and TF2.
* I edited the plugin to work with [bhoptimer](https://github.com/shavitush/bhoptimer). [bTimes](https://github.com/Nolan-O/bTimes) support has been dropped.
* [smlib](https://github.com/splewis/smlib) is not a dependency anymore.
* Optimizations have been applied.
* Cleaned the code where I could. Most plugins will look as if they were rewritten, as I don't like the way Rusty wrote them in first place.
* SourceMod 1.9 is the target version. Support for older versions of SourceMod will not be provided.
* More detection methods have been added.

Rusty's notes:

> This was written for SourceMod v1.7. Few comments are provided because I never planned on releasing the code, however there are *some* comments. The bulk of everything outside of oryx.sp is just pure game-mechanic-related logic anyway, so it just works because that's the way things work.

# Building

All you need to do is make sure you've specified your timer in oryx.inc by defining either `notimer` or `bhoptimer`. Build each file manually with the SourceMod compiler, like usual.  
If `bhoptimer` is defined, you will need [bhoptimer](https://github.com/shavitush/bhoptimer)'s include file.  
Send a pull request if you want to support other timers.

# Documentation  

A lot of this info is found in oryx.inc too.

Exported command | Action | Admin only? | From: 
---------------- | ------ | ----------- | -----
sm_otest | Enables the TRIGGER_TEST detection level | yes | oryx
sm_lock \<player> | Disables movement for a player | yes | oryx
scroll_stats \<player> | Print the scroll stat buffer for a given player | no | oryx-scroll
strafe_stats \<player> | Print the strafe stat buffer for a given player | no | oryx-strafe
config_streak \<player> | Print the config stat buffer for a given player | yes | oryx-configcheck


Trigger type | Usage
------------ | -----
TRIGGER_LOW | Like an early warning system. Oryx has probably not found a cheater, but you should keep an eye out.  
TRIGGER_MEDIUM | Also early warning.  
TRIGGER_HIGH | Oryx is pretty sure someone is cheating, and this will kick them.  
TRIGGER_HIGH_NOKICK | Just what it sounds like. High alert, but no automated consequences.  
TRIGGER_DEFINITIVE | Used by only by oryx-sanity right now. This should be used on non-stat-based detections.
TRIGGER_TEST | Allows you to develop new detections on live servers with minimal side effects.

Detection type | Meaning | From
-------------- | ------- | ----
Acute TR formatter | The player's turn rate has been made perfect | oryx-strafe
+left/right bypasser | +left/right bitflags have been stripped from the client's buttons variable | oryx-strafe
Prestrafe tool | Player is using a static turnrate to get 289 walk speed. Same as +left/right bypassing, but for a specific value on the ground | oryx-strafe
Average strafe too close to 0 | The average strafe offset is suspiciously near 0 | oryx-strafe
Too many perfect strafes | The average strafe offset is not too close to 0, but there is a suspiciously high frequency of 0s | oryx-strafe
Movement config | Player exhibits behavior that is humanly possible, but movement configs would enforce it | oryx-configcheck
Unsynchronised movement | Wish velocity does not align with with the player's buttons variable | oryx-sanity
Invalid wish velocity | Wish velocity can only be specific values ([link 1](https://mxr.alliedmods.net/hl2sdk-css/source/game/client/in_main.cpp#557), [link 2](https://mxr.alliedmods.net/hl2sdk-css/source/game/client/in_main.cpp#842)) | oryx-sanity
Wish velocity is too high | Wish velocity exceeds the default `cl_forwardspeed` or `cl_sidespeed` settings | oryx-sanity
Scripted jumps (havg) | Too many perfect jumps indicates a potential jump script usage | oryx-scroll
Scripted jumps (havgp, patt1, patt2, wpatt, wpatt2) | Too many perfect jumps while maintaining obviously weird scroll stats | oryx-scroll
Scripted jumps (nobf, bf-af, noaf) | Inhuman stats for scrolls before touching the ground and after jumping | oryx-scroll
Scroll macro (highn) | Way too many scroll inputs per jump, giving away the player using some kind of jump macro | oryx-scroll
Scroll cheat (interval, ticks) | Analysis on interval between scrolls ~~and ticks on ground~~ (WIP). These methods are at low detection level due to the nature of UDP causing packets to not be in the correct order all the time | oryx-scroll

**Note**: `oryx-sanity` **will** cause false positives with gamepads and controllers.  
**Note 2**: If using [bhoptimer](https://github.com/shavitush/bhoptimer), add `oryx_bypass` to the special string. This setting will disable the sanity, strafe, and movement config anticheats from triggering on the style. For example:

```
"7"
{
	"name"				"Hack vs Hack"
	"shortname"			"HVH"
	"htmlcolor"			"FFFFFF"
	"command"			"hvh"
	"clantag"			"HVH"

	"rankingmultiplier"	"0.0"
	"specialstring"		"oryx_bypass"
}

"8"
{
	"name"				"Autostrafer"
	"shortname"			"AS"
	"htmlcolor"			"FFFFFF"
	"command"			"autostrafe"
	"clantag"			"AS"

	"rankingmultiplier"	"0.0"
	"specialstring"		"100gainstrafe;tas;oryx_bypass"
}
```

Docs on natives are found in `oryx.inc`, using the SourceMod self-documenting style.

The plugins have only been tested with bhoptimer v1.5b (as found [here](https://github.com/shavitush/bhoptimer)).

# Logs

Relevant information will be logged into `addons/sourcemod/logs/oryx-ac.log`.  
Scroll cheaters will be listed in `addons/sourcemod/logs/oryx-ac-scroll.log`.  
Strafe hackers will be listed in `addons/sourcemod/logs/oryx-strafe-stats.log`.  
Chat messages will be printed to admins with `sm_ban` access, or the `oryx_admin` override. Admins will hear a beep sound to grab their attention when needed.

# Useful Definitions

* **Key-transition**: the changing of direction with keys (i.e. changing from `+moveleft` to `+moveright`)
* **Angle-transition**: the changing of direction in a player's camera along the x axis
* **Strafe offset**: the number of ticks that pass between a key-transition and angle-transition
* **Wish velocity**: Also called wishvel, this value is used for calculating movement direction, not the player buttons variable
* **Movement config**: Key bindings that prohibit the player from pressing opposing movement keys (i.e. `+moveleft` and `+moveright` can't be held at the same time
* **TR**: Turn-rate -- the rate of rotation of the client's camera along the x axis
