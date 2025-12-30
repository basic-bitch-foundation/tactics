# Tactics - Quick Break Games

quick brain break games right in your browser extension. made this cz i kept getting distracted opening full games during work/study sessions and losing track of time.

## the problem

when you're grinding code or studying for hours, you need quick mental breaks. but opening a game exe or going to a gaming site is risky - next thing you know 2 hours passed and you forgot what you were doing. 

so i built this extension for fast 2-5min game breaks without leaving your workspace. click, play, close. that's it.

## what it does

two classic strategy games that make you think but don't suck you in for hours:
- **tic tac toe** - vs ai opponent 
- **dots and boxes** - 6x6 grid vs ai

both games have ai opponents(kindly wait for response it might some time ) that actually think  so it's not boring. games are quick, you get your mental reset, then back to work.

![Tic Tac Toe Game](https://github.com/basic-bitch-foundation/tactics/blob/main/tactic-assets/tic_tac_toe.png?raw=true)
![Dots and Boxes Game](https://github.com/basic-bitch-foundation/tactics/blob/main/tactic-assets/Dot_n_box.png?raw=true)

## why this exists

**solves a real life problem:** need brain breaks during long work sessions but don't want to get sucked into addictive games or lose track of time. these are quick tactical games perfect for 3-5min pomodoro breaks.

**not just another long install game:** built specifically for productivity breaks. ai opponents make it engaging but games stay short. chrome extension means instant access without context switching to another app.

## tech stuff(can skip dude!)

built with:
- godot 4 (game engine)
- exported to web/wasm
- chrome extension wrapper
- javascript bridge for api calls (godot http doesn't work in extensions)
- ai opponents via hackclub api (gemini, deepseek, qwen)

had to completely rewrite the http request system to work with chrome's service worker restrictions. ended up using postMessage bridge between godot > iframe > popup > background script.

## how to run

1. download the latest release from [here](https://github.com/basic-bitch-foundation/tactics/archive/refs/heads/main.zip)
2. unzip the file somewhere
3. open chrome and go to `chrome://extensions/`
4. enable "Developer mode" (toggle in top right)
5. click "Load unpacked"
6. select the foldre named "extension" in unzipped folder (the one with manifest.json)
7. extension icon should appear in your toolbar
8. click it and play

that's it. no install, no signup, just works.

## playing the games

**tic tac toe:**
- click any empty cell to place your mark
- ai responds immediately(may lag!) 
- first to get 3 in a row wins
- scores tracked across rounds

**dots and boxes:**
- click between dots to draw lines
- complete a box to score and go again
- try to chain multiple boxes
- ai uses strategy (tries to complete 3-sided boxes, blocks yours)

both games have sound effects and turn indicators so you know what's happening.

## building from source(again for techies)

if you want to modify or build yourself:

1. clone the repo
```bash
git clone https://github.com/basic-bitch-foundation/tactics/tactics.git
cd tactics
```

2. open the godot project files in godot 4
3. export for web (HTML5)
4. copy exported files to `extension/game/` folder
5. load the extension folder in chrome

the godot source is in `/godot-project/` and extension code is in `/extension/`

## why it's different

this isn't just tic tac toe,  built specifically for:
- **productivity breaks** - games designed to be quick (2-5min)
- **no time sink** - can't get addicted and lose hours
- **actually smart ai** - uses real llm api so it's challenging
- **instant access** - extension popup, no new tabs or apps
- **offline-ish** - games work, just ai needs connection

## technical challenges

biggest pain was getting godot http requests to work in chrome extensions. service workers don't allow direct http from the game, so i had to:
- detect when running in extension vs standalone
- use javascript postMessage to communicate between godot and extension
- proxy all api calls through background.js
- handle async responses back to godot

also implemented fallback ai with multiple models (deepseek, gemini, qwen) with timeout handling. if one fails or takes too long, tries the next one. if all fail, does random valid move.

## future ideas

might add:
- more quick games (checkers, connect 4, etc)
- difficulty levels
- offline mode with minimax ai
- timer/pomodoro integration
- stats tracking
- feel free to contibute!

## license

MIT - do whatever you want with it

## credits

- built with godot engine
- ai via hackclub proxy api
- assets made in aseprite
- sounds from opensource

---

made this for # carnaival by Hackclub.com but figured others might find it useful. if you're spending 8+ hours coding/studying, take breaks. your brain needs it.

issues/prs welcome if you find bugs or have ideas.
 
