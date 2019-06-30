#import "vic.asm"
#import "routines.asm"

*=* "Raster Routine"
.macro InitRasterInterrupt(address) {
  sei

  lda #$7f
  sta vic.CIAICR
  sta vic.CI2ICR

  lda vic.CIAICR
  lda vic.CI2ICR

  lda #$01
  sta vic.VICIRQ
  sta vic.IRQMSK

  lda irqypos
  sta vic.RASTER

  lda #$ff
  sta vic.SPENA

  lda #$1b
  sta vic.SCROLY

  StoreWord($fffe, address)

  cli
}

SetupInterrupt:
  InitRasterInterrupt(irq)
  rts

/*

Main raster IRQ handler. The raster is chained such that when the interrupt fires, it does its processing
and as its last step sets the next raster to fire 24 lines lower. It also maintains a variable called
'counter' which keeps track of what row we're on. When counter reaches 8, it gets reset to 0.

*/
irq:
  .if(DEBUG == true) {
    inc vic.EXTCOL
  }

  dec vic.VICIRQ

  PushStack()

  ldx counter
  lda spriteypos, x     // Get the sprite Y positions for this row

  sta vic.SP0Y          // and set them
  sta vic.SP1Y
  sta vic.SP2Y
  sta vic.SP3Y
  sta vic.SP4Y
  sta vic.SP5Y
  sta vic.SP6Y
  sta vic.SP7Y

  // Update sprite colors & pointers
  txa
  asl                   // Multiply the row by 8 to get the correct position
  asl                   // inside our 64 byte data structures
  asl
  tax
  ldy #$00
!updatesprites:
  lda BoardSprites, x   // Set the sprite pointer
  sta SPRPTR, y
  lda BoardColors, x    // Set the sprite color
  sta vic.SP0COL, y
  inx
  iny
  cpy #NUM_COLS
  bne !updatesprites-

  // Handle our routines during the interrupt, but only once per frame
  lda counter
  cmp #NUM_ROWS - 1
  bne SkipServiceRoutines
  jsr PlayMusic         // Play the music if it's turned on
  jsr ComputeBoard      // Recompute and draw the board
  jsr ColorCycleTitle   // Color cycle the title and make it look pretty
  jsr ShowClock         // Display the play clock
  jsr ShowSpinner       // Show the spinner if required

SkipServiceRoutines:
  ldx counter
  inx
  cpx #NUM_ROWS
  bne NextIRQ
  ldx #$00

NextIRQ:
  stx counter
  lda irqypos, x
  sta vic.RASTER

  .if(DEBUG == true) {
    dec vic.EXTCOL
  }

  PopStack()

  rti

/*

If the music is unmuted, play it. This will get called on every raster interrupt (8 times per frame),
but will only call the SID play routine once per frame. It checks to see if counter == 0 (first row)
and if so, calls the SID play routine.

*/
PlayMusic:
  lda playmusic         // Is music enabled?
  cmp #$01
  bne return2
  jsr music_play        // Play it
return2:
  rts

/*
Display an indeterminate progress bar spinner
*/
ShowSpinner:
  lda spinnerenabled
  beq !return+
  dec spinnertiming
  bne !return+
  lda #$10
  sta spinnertiming
  ldx spinnercurrent
  cpx #spinnerend - spinnerstart
  bne !spin+
  ldx #$00
  stx spinnercurrent
!spin:
  lda spinnerstart, x
  sta ScreenAddress(SpinnerPos)
  lda #$01
  sta ColorAddress(SpinnerPos)
  inc spinnercurrent
!return:
  rts

/*
Color cycle the title
*/
ColorCycleTitle:
  dec colorcycletiming
  bne !return+
  lda #$10
  sta colorcycletiming

  ldx #$00
  ldy colorcycleposition
  iny
  sty colorcycleposition
  cpy #titlecolorsend - titlecolorsstart
  bne !paint+
  ldy #$00
  sty colorcycleposition
!paint:
  lda titlecolorsstart, y
  sta vic.CLRRAM + $1e, x
  sta vic.CLRRAM + $46, x
  inx
  cpx #$08
  beq !return+
  iny
  cpy #titlecolorsend - titlecolorsstart
  bne !paint-
  ldy #$00
  jmp !paint-
!return:
  rts

/*

This will compute the entire board based on the internal representation of it in 'BoardState'. This gets called once per frame on
the last interrupt of the screen.

BoardState contains an 8x8 grid of pieces stored as a contiguous 64 bytes. Each byte represents a single square on the board and it
contains the sprite pointer in the lower 7 bits and the color in the high bit.

This routine iterates over the 64 pieces and calculates which sprite and color lives in each square. Once that's computed, it stores
this information in 2 separate 64 byte blocks of memory called BoardSprites and BoardColors.

During the raster IRQ, we quickly calculate the pieces for the row based on the variable 'current' by looking through BoardSprites and
BoardColors. This way we only do the heavy computation once per frame, but can quickly display the sprites for each row.

*/
ComputeBoard:
  ldx #$00

!compute:
  lda BoardState, x
  sta CURRENT_PIECE
  and #$7f              // Strip high bit to remove the color information.
                        // The remaining 7 bits are the sprite pointer
  sta BoardSprites, x   // Set the pointer for this sprite
  lda CURRENT_PIECE
  and #$80              // Strip the lower 7 bits to get color information
  rol
  rol
  sta BoardColors, x
  inx
  cpx #$40              // Have we processed the entire board?
  bne !compute-
  rts

/*
Busy loop while waiting for the VBlank. We want to do most of our work here
*/
WaitForVblank:
  pha
!wait:
  lda vic.RASTER
  cmp #$80
  bne !wait-
  pla
  rts
