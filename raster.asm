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

  lda #$1b
  sta vic.SCROLY

  StoreWord($fffe, address)

  cli
}

// Raster interrupt handler. This is the meat of generating all 32 chess
// pieces. We have 8 rows of 8 sprites, so our raster triggers every 24
// lines.
irq:
  .if(DEBUG == true) {
    inc vic.EXTCOL
  }
  PushStack()

  dec vic.VICIRQ

  ldx counter
  lda spriteypos, x

  sta vic.SP0Y
  sta vic.SP1Y
  sta vic.SP2Y
  sta vic.SP3Y
  sta vic.SP4Y
  sta vic.SP5Y
  sta vic.SP6Y
  sta vic.SP7Y

  ShowRow()

  ldx counter
  inx
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

  jsr ColorCycleTitle
  jsr PlayMusic
  jsr ReadKeyboard

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

// Play the background music
PlayMusic:
  lda counter
  cmp #$00
  bne return2
  lda playmusic
  cmp #$01
  bne return2
  jsr music_play
return2:
  rts

// Color cycle the title to give it a nice rainbow effect
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

// Display a single row of pieces
.macro ShowRow() {
  lda counter
  asl // multiply the counter by 8
  asl // this gives us the position
  asl // inside the BoardState for each row
  tax
  ldy #0
loop:
  lda BoardState, x // get the BoardState for the current location
  sta CURRENT_PIECE
  and #$7f // strip the piece's color information

  // Which piece do we have at this location?
  cmp #WHITE_PAWN
  beq ShowPawn
  cmp #WHITE_KNIGHT
  beq ShowKnight
  cmp #WHITE_BISHOP
  beq ShowBishop
  cmp #WHITE_ROOK
  beq ShowRook
  cmp #WHITE_KING
  beq ShowKing
  cmp #WHITE_QUEEN
  beq ShowQueen

ShowEmpty:
  // Turn the sprite off for an empty square
  lda vic.SPENA
  and spritesoff, y
  sta vic.SPENA
  jmp continue2

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

continue:
  // Turn the sprite on
  sta SPRPTR, y
  lda vic.SPENA
  ora spriteson, y
  sta vic.SPENA

  // Is it white or black?
  lda CURRENT_PIECE
  and #$80
  bne black

  lda #$01
  sta vic.SP0COL, y
  jmp continue2
black:
  lda #$00
  sta vic.SP0COL, y
continue2:
  inx
  iny
  cpy #NUM_COLS
  bne loop
}
