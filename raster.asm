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
updatesprites:
  lda BoardSprites, x   // Set the sprite pointer
  sta SPRPTR, y
  lda BoardColors, x    // Set the sprite color
  sta vic.SP0COL, y
  inx
  iny
  cpy #NUM_COLS
  bne updatesprites

  // Handle our routines during the interrupt, but only once per frame
  lda counter
  cmp #NUM_ROWS - 1
  bne SkipServiceRoutines
  jsr ComputeBoard
  jsr ColorCycleTitle
  jsr PlayMusic
  jsr ReadKeyboard

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

// Read the keyboard and respond
ReadKeyboard:
  jsr Keyboard
  bcs NoValidInput
  cmp #$0d // M key
  bne NextKey1
  jsr ToggleMusic
NextKey1:
  cmp #$11 // Q key
  bne NextKey2
  jsr HandleQuit
NextKey2:
  cmp #$19 // Y key
  bne NextKey3
  jsr ConfirmQuit
NextKey3:
  cmp #$0e // N key
  bne NextKey4
  jsr QuitAbort
NextKey4:
  cmp #$10
  bne NextKey5
  jsr StartGame
NextKey5:
  cmp #$31 // 1 key
  bne NextKey6
  jsr OnePlayer
NextKey6:
  cmp #$32 // 2 key
  bne NextKey7
  jsr TwoPlayer
NextKey7:
NoValidInput:
  rts

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

Color cycle the title

*/
ColorCycleTitle:
  inc colorcycletiming
  lda colorcycletiming
  cmp #$10
  beq begin
  bne return

begin:
  lda #$00
  sta colorcycletiming

  ldx #$00
  ldy colorcycleposition
  iny
  sty colorcycleposition
  cpy #$07
  bne painttitle
  ldy #$00
  sty colorcycleposition
painttitle:
  lda titlecolors, y
  sta vic.CLRRAM + 30, x
  sta vic.CLRRAM + 70, x
  inx
  cpx #$08
  beq return
  iny
  cpy #$07
  bne painttitle
  ldy #$00
  jmp painttitle
return:
  rts

/*

This will compute the entire board based on the internal representation of it in 'BoardState'. This gets called once per frame on
the last interrupt of the screen.

BoardState contains an 8x8 grid of pieces stored as a contiguous 64 bytes. Each byte represents a single square on the board.
The pieces identify the type as well as the color, but they do NOT have sprite pointer or color data. That's what this routine does.

This routine iterates over the 64 pieces and calculates which sprite and color lives in each square. Once that's computed, it stores
this information in 2 separate 64 byte blocks of memory called BoardSprites and BoardColors.

During the raster IRQ, we quickly calculate the pieces for the row based on the variable 'current' by looking through BoardSprites and
BoardColors. This way we only do the heavy computation once per frame, but can quickly display the sprites for each row.

*/
ComputeBoard:
  ldx #$00

keepcomputing:
  lda BoardState, x
  sta CURRENT_PIECE
  and #$fe              // Strip bit 0 to remove color information

  cmp #BLACK_PAWN
  beq ShowPawn
  cmp #BLACK_KNIGHT
  beq ShowKnight
  cmp #BLACK_BISHOP
  beq ShowBishop
  cmp #BLACK_ROOK
  beq ShowRook
  cmp #BLACK_KING
  beq ShowKing
  cmp #BLACK_QUEEN
  beq ShowQueen
  jmp ShowEmpty

ShowPawn:
  lda #PAWN_SPR
  jmp continue
ShowKnight:
  lda #KNIGHT_SPR
  jmp continue
ShowBishop:
  lda #BISHOP_SPR
  jmp continue
ShowRook:
  lda #ROOK_SPR
  jmp continue
ShowKing:
  lda #KING_SPR
  jmp continue
ShowQueen:
  lda #QUEEN_SPR
  jmp continue
ShowEmpty:
  lda #EMPTY_SPR

continue:
  sta BoardSprites, x     // Store the sprite pointers
  lda CURRENT_PIECE
  and #$01                // Strip all bits but color information
  sta BoardColors, x      // Store the sprite colors
  inx
  cpx #$40                // Have we processed all 64 squares?
  bne keepcomputing
  rts
