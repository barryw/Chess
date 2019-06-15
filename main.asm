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

  InitRasterInterrupt(irq)

  jmp *

#import "vic.asm"
#import "equates.asm"
#import "board.asm"
#import "sprites.asm"
#import "routines.asm"
#import "raster.asm"
#import "storage.asm"
#import "strings.asm"
#import "characters.asm"
