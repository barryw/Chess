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
  mult16                // We multiply the row counter by 16 to get the 0x88 index
  tax                   // X = offset into BoardSprites/BoardColors for this row
  ldy #$00

!updatesprites:
  lda BoardSprites, x   // Read pre-computed sprite pointer
  sta SPRPTR, y         // Write to VIC
  lda BoardColors, x    // Read pre-computed color
  sta vic.SP0COL, y     // Write to VIC
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
  stx counter           // Set up the row for the next interrupt
  stb irqypos, x:vic.RASTER

  PopStack()

  rti

/*
These get called once per frame at the end of the frame
*/
RunServiceRoutines:
  jsr ComputeBoard      // Sync Board88 → BoardSprites/BoardColors for display
  jsr UpdateTimers      // Process timer callbacks (runs at 60Hz)
  jsr UpdateClock       // Update the play clock for whichever player is playing
  jsr ShowClock         // Display the play clock
  jsr ShowSpinner       // Show the spinner if required
  jsr FlashCursor       // Flash the cursor if it's on-screen
  jsr FlashPiece        // If a piece has been selected to move, flash it

  rts

/*
Sync Board88 to display arrays (BoardSprites/BoardColors)
Called once per frame to decouple display from game logic.
This allows AI to modify Board88 freely during search.
Only processes 64 valid squares (skips 0x88 padding columns).
*/
ComputeBoard:
  ldx #$00              // Start at row 0, col 0

!row_loop:
  ldy #$08              // 8 valid columns per row

!col_loop:
  lda Board88, x
  sta currentpiece      // Save piece+color (zero page = fast)
  and #LOWER7           // Strip color bit
  sta BoardSprites, x
  lda currentpiece      // Restore piece+color (3 cycles vs 4 for pla)
  pcol                  // Extract color
  sta BoardColors, x
  inx
  dey
  bne !col_loop-

  // Skip 8 invalid columns (0x88 padding)
  txa
  clc
  adc #$08
  tax
  cpx #BOARD_SIZE
  bcc !row_loop-
  rts

/*
If the player has selected a piece, flash it
Called by timer library at PIECE_FLASH_SPEED intervals (when enabled)
*/
FlashPieceCallback:
  ldx movefromindex
  chk_empty !showpiece+
!showempty:             // Flash OFF
  stb #EMPTY_SPR:Board88, x
  rts
!showpiece:             // Flash ON
  stb selectedpiece:Board88, x
  rts

// Legacy wrapper - still called from RunServiceRoutines but does nothing now
FlashPiece:
  rts

/*
Flash the cursor indicating that we're waiting on human input
Called by timer library at CURSOR_FLASH_SPEED intervals (when enabled)
*/
FlashCursorCallback:
  StoreWord(inputlocationvector, ScreenAddress(CursorPos))
  ldy cursorxpos
  lda (inputlocationvector),y
  eor #ENABLE
  sta (inputlocationvector),y
  rts

// Legacy wrapper - still called from RunServiceRoutines but does nothing now
FlashCursor:
  rts

/*
Display an indeterminate progress bar spinner when the computer is "Thinking"
Called by timer library at THINKING_SPINNER_SPEED intervals (when enabled)
*/
SpinnerCallback:
  ldx spinnercurrent
  cpx #spinnerend - spinnerstart
  bne !spin+
  ldx #$00
  stx spinnercurrent
!spin:
  stb spinnerstart, x:ScreenAddress(SpinnerPos)
  stb #$01:ColorAddress(SpinnerPos)
  inc spinnercurrent
  rts

// Legacy wrapper - still called from RunServiceRoutines but does nothing now
ShowSpinner:
  rts

/*
Color cycle the title (timer callback version)
Called by timer library at TITLE_COLOR_SCROLL_SPEED intervals
*/
ColorCycleTitle:
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
Busy loop while waiting for the VBlank. We want to do most of our work here
*/
WaitForVblank:
  wfv vic.RASTER:#$80
  rts
