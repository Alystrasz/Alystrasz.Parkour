# Running parkour mod locally

To create a parkour configuration for a given map:

1. Install the mod (obviously) in your `mods` repository
2. Open the `Alystrasz.Parkour/mod.json` file with your favourite text editor
3. Set the value of the `parkour_use_local_config` configuration variable to `1` (is `0` by default)
4. Start your game and get into the private match lobby
5. Select the "Parkour" mode (on the last page) and launch the match
7. Once into the match, load the map of your choice through the console (*e.g.* `map mp_thaw`)

The mod will throw an error since there's no configuration file for the selected map, and will create
this configuration file for you in the `R2Northstar/save_data/Alystrasz.Parkour` directory.

Once it has been created, you can configure your parkour, taking example on map samples from the
`samples` directory.
