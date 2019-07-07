*=* "Raster Routine"

SetupInterrupt:
  sei

  lda #$7f
  sta vic.CIAICR
  sta vic.CI2ICR

  lda vic.CIAICR
  lda vic.CI2ICR

  lda #$01
  sta vic.VICIRQ
  sta vic.IRQMSK

  lda irqypos           // Get the raster line for the first interrupt
  sta vic.RASTER

  lda #$1b
  sta vic.SCROLY

  StoreWord(IRQ_VECTOR, irq) // Point the interrupt vector at our routine

  cli
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

  txa
  asl                   // Multiply the row by 8 to get the correct position
  asl                   // inside our 64 byte data structures
  asl
  tax
  ldy #$00
!updatesprites:
  lda BoardSprites, x   // Set the sprite pointer based on the piece in this position
  sta SPRPTR, y
  lda BoardColors, x    // Set the sprite color for this sprite
  sta vic.SP0COL, y
!continue:
  inx
  iny
  cpy #NUM_COLS
  bne !updatesprites-

  lda counter
  cmp #NUM_ROWS - 1
  bne !skip+            // Handle our routines during the interrupt, but only once per frame
  jsr RunServiceRoutines

!skip:
  ldx counter
  inx
  cpx #NUM_ROWS
  bne !nextirq+
  ldx #$00

!nextirq:
  stx counter
  lda irqypos, x
  sta vic.RASTER

  .if(DEBUG == true) {
    dec vic.EXTCOL
  }

  PopStack()

  rti

/*
These get called once per frame at the end of the frame
*/
RunServiceRoutines:
  jsr PlayMusic         // Play the music if it's turned on
  jsr ComputeBoard      // Recompute and draw the board
  jsr ColorCycleTitle   // Color cycle the title and make it look pretty
  jsr UpdateClock       // Update the play clock for whichever player is playing
  jsr ShowClock         // Display the play clock
  jsr ShowSpinner       // Show the spinner if required
  jsr FlashCursor       // Flash the cursor if it's on-screen
  jsr FlashPiece

  rts

/*
If the player has selected a piece, flash it
*/
FlashPiece:
  lda flashpiece
  cmp #$00
  beq !exit+
  dec pieceflashtimer
  bpl !exit+
  lda #PIECE_FLASH_SPEED
  sta pieceflashtimer

  ldx movefromindex
  lda BoardState, x
  cmp #EMPTY_SPR
  beq !showpiece+
!showempty:
  lda #EMPTY_SPR
  sta BoardState, x
  jmp !exit+
!showpiece:
  lda selectedpiece
  sta BoardState, x
!exit:
  rts

/*
Flash the cursor indicating that we're waiting on human input
*/
FlashCursor:
  lda showcursor
  beq !return+
  dec cursorflashtimer
  bne !return+
  lda #CURSOR_FLASH_SPEED
  sta cursorflashtimer
  StoreWord(inputlocationvector, ScreenAddress(CursorPos))
  ldy cursorxpos
  lda (inputlocationvector),y
  eor #$80
  sta (inputlocationvector),y

!return:
  rts

/*
If the music is unmuted, play it. This will get called once per frame (60x a second).
*/
PlayMusic:
  lda playmusic         // Is music enabled?
  cmp #$01
  bne !return+
  jsr music_play        // Play it
!return:
  rts

/*
Display an indeterminate progress bar spinner when the computer is "Thinking"
*/
ShowSpinner:
  lda spinnerenabled
  beq !return+
  dec spinnertiming
  bne !return+
  lda #THINKING_SPINNER_SPEED
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
  lda #TITLE_COLOR_SCROLL_SPEED
  sta colorcycletiming

  ldx #$00
  inc colorcycleposition
  ldy colorcycleposition
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
  sta currentpiece
  and #$7f              // Strip high bit to remove the color information.
                        // The remaining 7 bits are the sprite pointer
  sta BoardSprites, x   // Set the pointer for this sprite
  lda currentpiece
  and #$80              // Strip the lower 7 bits to get color information
  clc
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
