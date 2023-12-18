# Golf Card Game

This game follows the [rules outlined by Bicycle Cards](https://bicyclecards.com/how-to-play/six-card-golf) with a slight modification to scoring.

## To Play (WIP)

Builds will be available in our [Releases Page](https://github.com/WonkyMic/golf_cards_godot/releases) when ready.

## Multiplayer Setup (WIP)

If you have your own server, you can the `--headless` flag in CMD, Terminal, Powershell, or whatever to start in Lobby mode.

### Lobby Testing While Developing

For the lobby to work in a development environment, you'll need to add an environment variable directing the program to your project folder:

- `GOLF_DEBUG_PROJECT_PATH` needs to refer to whatever folder your Godot project is in (example: `C:\Users\jonathan\projects\golf_cards_godot`)
  - this is necessary for Godot to reference your project path when starting a new child process
  - this environment variable is **not** necessary for the exported game binary

Once done, you can run the following to start up a lobby instance with debugging enabled:

#### GitBash/Terminal

```sh
cd $GOLF_DEBUG_PROJECT_PATH
godot . --headless
```

#### CMD

```bat
cd %GOLF_DEBUG_PROJECT_PATH%
godot . --headless
```

#### Powershell

```PowerShell
cd $env:GOLF_DEBUG_PROJECT_PATH
godot . --headless
```

## Goals

- Splash / Intro screen
- Menu / Options
- Animations and Layout Polishing
- Code Refactoring
- Bug Fixes (if last card played is a Draw and Replace of unflipped card the game does not end)

## Shoutouts

- Card images couresy of [Kenney](www.kenney.nl)! Check them out for free assets for *your* game!
- Speedcloth background photo courtesy [photos-public-domain.com](https://photos-public-domain.com)!
