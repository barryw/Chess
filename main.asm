BasicUpstart2(start)

//
// This is an implementation of chess for the Commdore 64
//

// Create the D64 image
.disk [filename="C64Chess.d64", name="C64 CHESS", id="2021!"]
{
  [name="C64 CHESS", type="prg", segments="Default"]
}

.const DEBUG=false

*=* "Main"

start:
  jsr SetupSprites
  jsr SetupScreen
  jsr SetupCharacters
  jsr SetupMusic
  jsr SetupInterrupt

  jmp *

#import "vic.asm"
#import "equates.asm"
#import "math.asm"
#import "memory.asm"
#import "menus.asm"
#import "functions.asm"
#import "keyboard.asm"
#import "board.asm"
#import "routines.asm"
#import "raster.asm"
#import "strings.asm"
#import "sprites.asm"
#import "storage.asm"
#import "music.asm"
#import "characters.asm"
