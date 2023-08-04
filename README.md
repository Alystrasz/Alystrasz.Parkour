# Parkour

A gamemode where players have to cross checkpoints and race between each other for the
leaderboard 1st position.

## Development

Feel free to contribute!

Progress is tracked in this [GitHub board](https://github.com/users/Alystrasz/projects/1).

### Map configuration

Map configuration (*i.e.* coordinates of all entities, including start/finish lines, checkpoints and ziplines) is fetched from the [Parkour API](https://github.com/Alystrasz/parkour-api).

To locally create a new parkour route, you can make your local server load map configuration from a local JSON file instead by setting the `parkour_use_local_config` configuration variable to 1.
