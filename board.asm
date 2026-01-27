#importonce

*=* "Board Storage"
/*

Keeps track of the complete state of the board throughout play. It starts in this initial configuration.

During the raster interrupts, the board is constantly redrawn using multiplexed sprites. This allows us
to show up to 32 sprites at once.

*/
BoardState:
  .byte BLACK_ROOK, BLACK_KNIGHT, BLACK_BISHOP, BLACK_QUEEN, BLACK_KING, BLACK_BISHOP, BLACK_KNIGHT, BLACK_ROOK
  .byte BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN
  .byte WHITE_ROOK, WHITE_KNIGHT, WHITE_BISHOP, WHITE_QUEEN, WHITE_KING, WHITE_BISHOP, WHITE_KNIGHT, WHITE_ROOK

/*
Matrix of sprite pointers to match the state above
*/
BoardSprites:
  .fill $40, $00

/*
Matrix of sprite colors to match the state above
*/
BoardColors:
  .fill $40, $00

// Shows the columns along the bottom of the board
Columns:
  .text "ABCDEFGH"

/*
Generate the checkerboard pattern in color RAM at runtime.
This saves ~960 bytes of program space.

The board is 24x24 characters (8x8 chess squares, each 3x3 chars).
Colors: $0f (light gray) and $0b (dark gray) alternate.
*/
GenerateBoardColors:
  // Use zero page pointers for indirect addressing
  // We'll use $fb/$fc for the color RAM pointer
  lda #<vic.CLRRAM
  sta $fb
  lda #>vic.CLRRAM
  sta $fc

  ldx #$00          // Screen row counter (0-23)

!rowloop:
  // Determine starting color based on chess row (screen row / 3)
  // Chess row 0,2,4,6 start light ($0f), rows 1,3,5,7 start dark ($0b)
  txa
  lsr               // Divide by 2
  and #$03          // Keep low 2 bits after accounting for /3
  // Actually simpler: check (row/3) & 1
  txa
  // Divide X by 3 using lookup or repeated subtraction
  // For rows 0-2: chess row 0, for 3-5: row 1, etc.
  cmp #$03
  bcc !r0+
  cmp #$06
  bcc !r1+
  cmp #$09
  bcc !r2+
  cmp #$0c
  bcc !r3+
  cmp #$0f
  bcc !r4+
  cmp #$12
  bcc !r5+
  cmp #$15
  bcc !r6+
  jmp !r7+

!r0:
!r2:
!r4:
!r6:
  lda #$0f          // Even chess rows start light
  jmp !fillrow+
!r1:
!r3:
!r5:
!r7:
  lda #$0b          // Odd chess rows start dark

!fillrow:
  // A = starting color, fill 24 columns (8 squares * 3 chars)
  ldy #$00
!colloop:
  // Write current color 3 times (one chess square width)
  sta ($fb), y
  iny
  sta ($fb), y
  iny
  sta ($fb), y
  iny
  // Toggle color: $0f XOR $04 = $0b, $0b XOR $04 = $0f
  eor #$04
  // Repeat for 8 squares
  cpy #$18          // 24 columns = 8 squares * 3 chars
  bne !colloop-

  // Advance pointer by 40 (screen width)
  lda $fb
  clc
  adc #$28
  sta $fb
  bcc !noinc+
  inc $fc
!noinc:

  // Next row
  inx
  cpx #$18          // 24 screen rows
  bne !rowloop-

  rts

