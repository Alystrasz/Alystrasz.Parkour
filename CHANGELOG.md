# Changelog

## 0.3.3

### Fixes

* Removed leaked API key :>

## 0.3.2

### Fixes

* Projectiles are removed on run reset;
* Gravity star sounds are only emitted on the thrower;
* All dropped weapons are now destroyed;
* Weapon ammunition is refilled on run reset;
* Code optimizations.

## 0.3.1

### Fixes

* Fix clientside crash happening after many resets.

## 0.3.0

### Features

* A map poll triggers 2 minutes before the end of the match, asking players which map they want to play next;
* Map configuration names now appear in game;
* Speedmeter component shows the PB time of the entire event (not just of the local match);
* Added support for props (meaning server can spawn objects on the map);
* Added support for `floor_is_lava` riff (*i.e.* deadly fog can be spawned);
* Added debug utils to ease the creation of new routes;
* Added configuration samples for 3 new routes.

### Fixes

* Highscore and reset banners don't overlap;
* Dead players aren't prompted with run reset;
* Run reset prompt is shown to immobile players only;
* Players can no longer benefit from multiple stim boosts;
* Players cannot checkpoint-respawn into the ground or walls;
* "START" and "FINISH" panels are not displayed at the same time;
* Weapon name is not shown on run reset;
* MRVN redirects players to web scoreboard using HTTP link provided by the server;
* All messages are now properly (clientside) translated;
* Cleaned code base.

## 0.2.1

### Fixes

* Players can teleport to map start even when they're not running;
* Players are frozen at the end of the match;
* A run can no longer be started just after finishing another one;
* Servers do not send scoreboard states to players if it's not needed;
* World scoreboard is directly updated if a local new world high score is registered;
* In high score notification, decimal places are now limited to 2.

## 0.2.0

### Features

* Scoring API now hosts a world scoreboard, which displays scores of all players on all maps;
* A MRVN named R-MY made his way to the Parkour mode! He can help newcomers by:
  * explaining the mode rules;
  * showing the world scoreboard;
  * displaying starting line location when players get a bit too far from it.
* Map configuration can be retrieved from either local file or distant server, allowing for new maps to be released during an event without players needing to download a patch.

### Fixes

* Players face the starting line when resetting their run;
* Boost progress indicator is hidden.

![image](https://github.com/Alystrasz/Alystrasz.Parkour/assets/11993538/6825fae0-35ba-4cbd-8c0e-06b93eb6c7b3)

![image](https://github.com/Alystrasz/Alystrasz.Parkour/assets/11993538/7b695448-8528-49b5-aeb5-169d028b59bc)

## 0.1.2

### Features

* Highlight personal scores on both leaderboards;
* All players now have the same passive ability.

### Fixes

* Use new Parkour API configuration (paving the way for the mode to support other maps than `mp_thaw`)

![new_leaderboards](https://github.com/Alystrasz/Alystrasz.Parkour/assets/11993538/6254bfb4-5cd3-42eb-8b0d-0e0807711f51)

## 0.1.1

### Features

* All players now have the same loadout, which is forced for each map;
* All scores are displayed on one scoreboard (the one accessible when pressing __Tab__);
* A winner is picked at the end of the match.

### Fixes

* Game server does not send more than 10 leaderboard entries (as the leaderboard interface only supports 10 entries, it was useless sending more)

## 0.1.0

### Feature

The _local_ scoreboard displays scores of the current match, while the _world_ scoreboard displays best scores of all times on the current map.

![image](https://github.com/Alystrasz/Alystrasz.Parkour/assets/11993538/231afb36-4e92-4eda-8b54-40a2c46de430)

## 0.0.5

### Features

* Resetting a run is now done by pressing the `boost` keyboard shortcut;
* Sounds are now played when crossing checkpoints;
* Statistics are persisted through entire matches (players can disconnect from/reconnect to a match and and still have their scores there)

### Fixes

* Leaderboard updates when more than 10 players are playing;
* Checkpoints only trigger for players (and not NPCs).

## 0.0.4

### Features

* All cooldowns are reset on run finish/reset.

### Fixes

* Resetting through starting line does not start a new run;
* Resetting while dead does not crash the server.

### Credits

Thanks to the players `FORTY`, `NeiigoR`, `Neinguar`, `Nonogn`, `TheLavaLump`, `Webplatapusone` and `xPEDALE_mttw` for participating in testing sessions.

## 0.0.3

### Fixes

* Starting a run before highscore banner fades does not crash the client anymore;
* Resetting through checkpoint and finish line now works properly;
* Highscore banner does not appear anymore to all players when a new player joins the server.

## 0.0.2

CI fixes (hopefully)

## 0.0.1

Initial test release, which includes:
* checkpoints;
* live updates with concurrent players;
* map leaderboard;
* and more!
