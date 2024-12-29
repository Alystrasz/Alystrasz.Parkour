# Parkour

![Screenshot showing checkpoints](https://raw.githubusercontent.com/Alystrasz/Alystrasz.Parkour/refs/heads/main/assets/checkpoints.png)

A gamemode where players have to cross checkpoints and race between each other for the leaderboard 1st position. Remember single player mission [The Pilot's Gauntlet](https://titanfall.fandom.com/wiki/The_Pilot's_Gauntlet)? Well, it's the same story, but in multiplayer!

## Game mode

### Rules

All you need to do is cross the starting line, cross all checkpoints and reach the finish line as fast as you can!

For games to be fair, all players have the same loadout: same weapon, same grenade, same ability and same kit.

### Interface

![Interface screenshot](https://raw.githubusercontent.com/Alystrasz/Alystrasz.Parkour/main/assets/ui.png)

When you start a parkour run, several elements appear on your HUD:
* the number of checkpoints you validated;
* your current time and speed;
* a icon showing location of the next checkpoint (here, it's hidden in the building in front of us).

### Leaderboards

![Screenshot of both local and world leaderboards](https://raw.githubusercontent.com/Alystrasz/Alystrasz.Parkour/refs/heads/main/assets/leaderboards.png)

Scores of all players are displayed on leaderboards, not far from starting and finish lines. There are two leaderboards:
* the **local** leaderboard displays scores for the current match;
* the **world** leaderboard displays scores of all times for the current map.

## Development

Feel free to contribute!

Progress is tracked in this [GitHub board](https://github.com/users/Alystrasz/projects/1).

### Map configuration

Map configuration (*i.e.* coordinates of all entities, including start/finish lines, checkpoints and ziplines) is fetched from the [Parkour API](https://github.com/Alystrasz/parkour-api).

To locally create a new parkour route, you can make your local server load map configuration from a local JSON file instead by following the [local setup guide](https://github.com/Alystrasz/Alystrasz.Parkour/blob/main/docs/LOCAL.md).

### Positioning triggers

To help you position parkour elements on the map, you can enable triggers display by running the following commands in your console:
```shell
sv_cheats 1
enable_debug_overlays 1
```

![Screenshot of triggers on mp_thaw](https://raw.githubusercontent.com/Alystrasz/Alystrasz.Parkour/main/assets/triggers.png)

* start trigger appears in red;
* end trigger is colored yellow;
* checkpoint triggers are painted green;
* "building" trigger (used to show the way to players who stray a little too far from starting line) appears in blue.