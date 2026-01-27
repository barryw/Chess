BasicUpstart2(start)

//
// This is an implementation of chess for the Commdore 64
//

// Create the D64 image
.disk [filename="C64Chess.d64", name="C64 CHESS", id=" 2A"]
{
  [name="C64 CHESS", type="prg", segments="Default"]
}

.const DEBUG=false

*=* "Main"

start:
  jsr SetupSprites
  jsr SetupScreen
  jsr SetupCharacters
  jsr SetupInterrupt

!readkeyboard:
  jsr WaitForVblank
  jsr ReadKeyboard
  jmp !readkeyboard-

#import "vic.asm"
#import "macros.asm"
#import "pseudocommands.asm"
#import "constants.asm"
#import "version.asm"
#import "layout.asm"
#import "memory.asm"
#import "functions.asm"
#import "keyboard.asm"
#import "sprites.asm"
#import "clock.asm"
#import "board.asm"
#import "routines.asm"
#import "moves.asm"
#import "raster.asm"
#import "storage.asm"
#import "strings.asm"
#import "opening_moves.asm"
#import "characters.asm"
#import "display.asm"
#import "input.asm"
#import "game.asm"
#import "menus.asm"
