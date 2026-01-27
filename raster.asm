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
  tax                   // X = offset into Board88 for this row
  ldy #$00
!updatesprites:
  lda Board88, x        // Load piece+color directly from Board88
  and #LOWER7           // Strip color bit for sprite pointer
  sta SPRPTR, y         // Write sprite pointer to VIC
  lda Board88, x        // Load again (faster than temp storage)
  pcol                  // Extract color (0=black, 1=white)
  sta vic.SP0COL, y     // Write sprite color to VIC
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
  chk_empty !showpiece+
!showempty:             // Flash OFF
  stb #EMPTY_SPR:Board88, x
  jmp !exit+
!showpiece:             // Flash ON
  stb selectedpiece:Board88, x
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
Busy loop while waiting for the VBlank. We want to do most of our work here
*/
WaitForVblank:
  wfv vic.RASTER:#$80
  rts
