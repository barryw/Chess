BasicUpstart2(start)

//
// This is an implementation of chess for the Commdore 64
//

.const DEBUG=false

#import "vic.asm"
#import "equates.asm"
#import "board.asm"
#import "sprites.asm"
#import "routines.asm"
#import "raster.asm"
#import "storage.asm"
#import "strings.asm"
#import "characters.asm"

*=* "Main"

start:
  jsr SetupSprites
  jsr SetupScreen
  jsr SetupCharacters

  InitRasterInterrupt(irq)

  jmp *
