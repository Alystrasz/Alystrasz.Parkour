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

### External resources:

* Parkour API: https://github.com/Alystrasz/parkour-api
* Parkour server config: https://github.com/Alystrasz/ParkourDedicatedConfiguration
