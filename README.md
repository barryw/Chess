         _____                              _                    __ _  _      _____ _
        / ____|                            | |                  / /| || |    / ____| |
       | |     ___  _ __ ___  _ __ ___   __| | ___  _ __ ___   / /_| || |_  | |    | |__   ___  ___ ___
       | |    / _ \| '_ ` _ \| '_ ` _ \ / _` |/ _ \| '__/ _ \ | '_ \__   _| | |    | '_ \ / _ \/ __/ __|
       | |___| (_) | | | | | | | | | | | (_| | (_) | | |  __/ | (_) | | |   | |____| | | |  __/\__ \__ \
        \_____\___/|_| |_| |_|_| |_| |_|\__,_|\___/|_|  \___|  \___/  |_|    \_____|_| |_|\___||___/___/


#### Introduction

This is my stab at an implementation of Chess for the Commodore 64 written in 6510 assembly language.

#### LOL! Why?!

I grew up using Commodore computers, starting with the VIC-20 and progressing through the 64, the 128 and finally an Amiga 500. I learned to program on them, first in BASIC and then a bit with 6510 assembly. These machines hold a special place in my heart.

There's also a beauty in the simplicity of this machine that makes it fun and challenging to write for. When you have a machine with 65535 bytes of memory, you have to make them all count. It's not like the slop that gets thrown out on modern machines where you can drag in gigabytes of libraries without worry. On an 8 bit machine, you have to be very creative in how you allocate your memory.

Modern tool chains have also gotten to a point where it's much nicer to develop for these older machines. Back when these machines were popular, writing code for them was painful. There were no IDEs, and debugging was tricky. Now, you can edit your code in whatever editor you'd like, and there are tons of cross assemblers and cross compilers which can build your code and launch a C64 emulator like VICE for you. The edit, build, debug cycle is very short and it's easy to see the results of changes.

#### Why chess?

The gameplay of chess lines up nicely with some of the limitations of the Commodore 64. It features an 8x8 board with mostly static pieces and doesn't require sound.

One of the biggest limitations of the 64 is that it only has 8 hardware sprites. For a lot of games, this is enough, but for a chess game this poses a problem. Each side starts with 16 pieces, and so at the start of the game there are 32 pieces on the board - well beyond the 8 sprites the machine has.

To get around this, a technique called "sprite multiplexing" is used whereby the 8 sprites can be reused by changing them during a raster interrupt. In this case, each row on the chess board can contain up to 8 sprites and during the raster interrupt for each row, the sprites are moved and changed to represent the pieces on that row. It's pretty complex and challenging and requires precise timing to make it appear as though there are 32 sprites on the screen at once.

#### How do I build it?

It's all built with KickAssembler, which really is a Kick Ass Assembler! It makes it very easy to build 6502/6510 code and has a nice java-like language built in.

There's a docker image containing KickAssembler that you can use. You will need to have `Make` and `docker` installed to run this.

```bash
make build
```

This will output a file called `C64Chess.d64` that you can load into VICE or your 1541 Ultimate II+.

#### How is the code laid out?

I've tried to put related things into the same files, but for the most part everything is brought in from `main.asm`. If you're going to make changes, be very careful that things don't overlap! The sprites, custom characters and music cannot move, so you'll need to make sure that everything is located around them.

The chess pieces are rendered with sprites, which have to be multiplexed to get 32 pieces. This is very easy on a game like chess where the pieces are stationary. It's also nice that the chess board is 8x8 which lines up very nicely with limitations on an 8-bit machine like the 64.

Raster interrupts are heavily used to do the sprite multiplexing. Every 24 scan lines the sprites are re-drawn to show the pieces for that row. The last row also triggers the once-per-frame subroutines (keyboard scan, title colors, music, play clock updates).

#### Current status

It's still early days, so the game isn't even close to playable yet. My first goal is to get gameplay working to where players can take turns moving their pieces to any location and upping the captured count when pieces are captured. Once that's working reliably, I'll add in the logic to validate whether a move is legal before making it.

Lastly I'm going to add in some "AI" to allow humans to play the computer.

A stretch goal is to include pre-defined scenarios where play starts deep into a game and it's up to the player to win in X number of moves. This may prove difficult on a machine with 64k.
