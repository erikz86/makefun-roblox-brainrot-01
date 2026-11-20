# Brainrot Bay

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) [![make.fun](https://img.shields.io/badge/make.fun-roblox--brainrot--01-blue)](https://make.fun/bounty/roblox-brainrot-01) [![Roblox](https://img.shields.io/badge/Roblox-Studio-red)](https://create.roblox.com)

Brainrot Bay is a low-poly 3D Roblox game inspired by Steal-a-Brainrot. Build a collection of strange characters, grow your income, and defend your base.

## How to play

- Walk to the conveyor and click a brainrot to buy it with your money. It moves into an available slot at your base.
- Earn money per second from your collection. Rarities range from Common to BrainrotGod; Gold mutations earn 2x income and Diamond mutations earn 5x.
- Steal brainrots from other bases to expand your collection.
- Rebirth for 50,000 money to permanently double your income with each rebirth.
- Survive thief waves that attack every 90 seconds.

## How to build

With Rojo installed, build the place from the repository root:

```sh
rojo build default.project.json -o game.rbxl
```

The project maps shared, server, and client source folders into Roblox services. The server script builds the world at runtime.

The Node 22 entrypoint `main.ts` packages the built place, play metadata, source, screenshots, and dossier into `MAKEFUN_OUTPUT_DIR` (default `/output`).

See the [Brainrot Bay bounty](https://make.fun/bounty/roblox-brainrot-01).
