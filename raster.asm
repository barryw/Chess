*=* "Raster Routine"

SetupInterrupt:
  sei

  lda #LOWER7
  sta vic.CIAICR
  sta vic.CI2ICR

  lda vic.CIAICR
  lda vic.CI2ICR

  lda #$01
  sta vic.VICIRQ
  sta vic.IRQMSK

  stb irqypos:vic.RASTER
  stb #$1b:vic.SCROLY

  StoreWord(IRQ_VECTOR, irq) // Point the interrupt vector at our routine

  cli
  rts

/*
Main raster IRQ handler. The raster is chained such that when the interrupt fires, it does its processing
and as its last step sets the next raster to fire 24 lines lower. It also maintains a variable called
'counter' which keeps track of what row we're on. When counter reaches 8, it gets reset to 0.
*/
irq:
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
  mult8
  tax
  ldy #$00
!updatesprites:
  stb BoardSprites, x:SPRPTR, y
  stb BoardColors, x:vic.SP0COL, y
  inx
  iny
  cpy #NUM_COLS
  bne !updatesprites-

  // On the last row, run our service routines
  jne counter:#NUM_ROWS - 1:!skip+
  jsr RunServiceRoutines

!skip:
  ldx counter
  inx
  cpx #NUM_ROWS
  bne !nextirq+
  ldx #$00

!nextirq:
  stx counter
  stb irqypos, x:vic.RASTER

  PopStack()

  rti

/*
These get called once per frame at the end of the frame
*/
RunServiceRoutines:
  jsr ComputeBoard      // Recompute and draw the board
  jsr ColorCycleTitle   // Color cycle the title and make it look pretty
  jsr UpdateClock       // Update the play clock for whichever player is playing
  jsr ShowClock         // Display the play clock
  jsr ShowSpinner       // Show the spinner if required
  jsr FlashCursor       // Flash the cursor if it's on-screen
  jsr FlashPiece        // If a piece has been selected to move, flash it

  rts

/*
If the player has selected a piece, flash it
*/
FlashPiece:
  bfc flashpiece:!exit+
  dec pieceflashtimer
  bpl !exit+
  stb #PIECE_FLASH_SPEED:pieceflashtimer
  ldx movefromindex
  jeq BoardState, x:#EMPTY_SPR:!showpiece+
!showempty:             // Flash OFF
  stb #EMPTY_SPR:BoardState, x
  jmp !exit+
!showpiece:             // Flash ON
  stb selectedpiece:BoardState, x
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
  stb #CURSOR_FLASH_SPEED:cursorflashtimer
  StoreWord(inputlocationvector, ScreenAddress(CursorPos))
  ldy cursorxpos
  lda (inputlocationvector),y
  eor #ENABLE
  sta (inputlocationvector),y

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
  stb #THINKING_SPINNER_SPEED:spinnertiming
  ldx spinnercurrent
  cpx #spinnerend - spinnerstart
  bne !spin+
  ldx #$00
  stx spinnercurrent
!spin:
  stb spinnerstart, x:ScreenAddress(SpinnerPos)
  stb #$01:ColorAddress(SpinnerPos)
  inc spinnercurrent
!return:
  rts

/*
Color cycle the title
*/
ColorCycleTitle:
  dec colorcycletiming
  bne !return+
  stb #TITLE_COLOR_SCROLL_SPEED:colorcycletiming

  ldx #$00
  inc colorcycleposition
  ldy colorcycleposition
  cpy #titlecolorsend - titlecolorsstart
  bne !paint+
  ldy #$00
  sty colorcycleposition
!paint:
  lda titlecolorsstart, y
  sta ColorAddress(Title1CharPos), x
  sta ColorAddress(Title2CharPos), x
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
  stb BoardState, x:currentpiece
  and #LOWER7           // Strip high bit to remove the color information.
                        // The remaining 7 bits are the sprite pointer
  sta BoardSprites, x   // Set the pointer for this sprite
  lda currentpiece
  pcol                  // Get the piece's color
  sta BoardColors, x
  inx
  cpx #BIT7             // Have we processed the entire board?
  bne !compute-
  rts

/*
Busy loop while waiting for the VBlank. We want to do most of our work here
*/
WaitForVblank:
  pha
  php
  wfv vic.RASTER:#$80
  plp
  pla
  rts
