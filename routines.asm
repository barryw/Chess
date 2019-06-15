#importonce

#import "board.asm"

// Set the initial positions of the 8 sprites
SetupSprites:
  ldx #$00
  stx counter
  lda #PIECE_WIDTH
storex:
  sta vic.SP0X,x
  clc
  adc #PIECE_WIDTH
  inx
  inx
  cpx #$10
  bne storex
  rts

// Clear the screen by storing space directly to screen memory
ClearScreen:
  ldx #$ff
  lda #$20
clrloop:
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  dex
  bne clrloop
  rts

SetupScreen:
  jsr ClearScreen
  lda #$00
  sta vic.BGCOL0
  sta vic.EXTCOL
  lda #$17
  sta vic.VMCSB

  ldx #$00
drawloop:
  lda Board,x
  sta vic.CLRRAM,x
  lda Board+$0100,x
  sta vic.CLRRAM+$0100,x
  lda Board+$0200,x
  sta vic.CLRRAM+$0200,x
  lda Board+$0300,x
  sta vic.CLRRAM+$0300,x
  lda #224
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  inx
  bne drawloop

  ldx #$00
  ldy #$00
drawcolumns:
  lda Columns, y
  sta $07c1,x
  inx
  inx
  inx
  iny
  cpy #$09
  bne drawcolumns

  lda #'8'
  sta $0440
  lda #'7'
  sta $04b8
  lda #'6'
  sta $0530
  lda #'5'
  sta $05a8
  lda #'4'
  sta $0620
  lda #'3'
  sta $0698
  lda #'2'
  sta $0710
  lda #'1'
  sta $0788

  ldx #$00
title:
  lda Title, x
  cmp #$00
  beq finishtitle
  sta $041d, x
  lda #$01
  sta vic.CLRRAM + 29,x
  inx
  jmp title
finishtitle:
  ldx #$00
copyright:
  lda Copyright, x
  cmp #$00
  beq finishcopyright
  sta $07b2, x
  lda #$01
  sta vic.CLRRAM + 946, x
  inx
  jmp copyright
finishcopyright:
  ldx #$00
barry:
  lda Barry, x
  cmp #$00
  beq finishbarry
  sta $7db, x
  lda #$01
  sta vic.CLRRAM + 987, x
  inx
  jmp barry
finishbarry:
  rts

// Bring in the custom characters
SetupCharacters:
  lda vic.VMCSB
  and #$f0
  ora #$0d
  sta vic.VMCSB
  lda #$35
  sta $01
  rts

.macro PushStack() {
  pha
  txa
  pha
  tya
  pha
  php
}

.macro PopStack() {
  plp
  pla
  tay
  pla
  tax
  pla
}

// Store a word
.macro StoreWord(address, word) {
  lda #<word
  sta address
  lda #>word
  sta address+1
}

// Display a single row of pieces
.macro ShowRow() {
  lda counter
  asl
  asl
  asl
  tax
  ldy #0
loop:
  lda BoardState, x
  sta CURRENT_PIECE
  and #$7f

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
  // Turn the sprite off
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
  cmp #$80
  beq black

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

// Perform an 8-bit multiply. The numbers to multiply need to be stored
// in num1 and num2. The result is stored in A
Multiply8Bit:
  lda #$00
  beq enterLoop

doAdd:
  clc
  adc num1

loop:
  asl num1
enterLoop:
  lsr num2
  bcs doAdd
  bne loop
  rts

Add16Bit:
  clc
  lda <word1
  adc <word2
  sta <result
  lda >word1
  adc >word2
  sta >result
  rts
