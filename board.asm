#importonce

*=* "Board Storage"
/*

0x88 Board Representation - THE SINGLE SOURCE OF TRUTH

Index = row * 16 + col, where:
- Valid squares: (index & $88) == 0 (columns 0-7 of each row)
- Invalid/off-board: (index & $88) != 0 (columns 8-15, used for bounds checking)

This layout enables 2-cycle off-board detection: AND #$88 / BNE offboard

Row layout (128 bytes total):
  Row 0 (rank 8): $00-$07 valid, $08-$0F invalid
  Row 1 (rank 7): $10-$17 valid, $18-$1F invalid
  ...
  Row 7 (rank 1): $70-$77 valid, $78-$7F invalid

*/
Board88:
  // Row 0 ($00-$0F): Black back rank + invalid padding
  .byte BLACK_ROOK, BLACK_KNIGHT, BLACK_BISHOP, BLACK_QUEEN, BLACK_KING, BLACK_BISHOP, BLACK_KNIGHT, BLACK_ROOK
  .fill 8, EMPTY_PIECE    // Invalid columns $08-$0F

  // Row 1 ($10-$1F): Black pawns + invalid padding
  .byte BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN
  .fill 8, EMPTY_PIECE    // Invalid columns $18-$1F

  // Row 2 ($20-$2F): Empty + invalid padding
  .fill 8, EMPTY_PIECE
  .fill 8, EMPTY_PIECE

  // Row 3 ($30-$3F): Empty + invalid padding
  .fill 8, EMPTY_PIECE
  .fill 8, EMPTY_PIECE

  // Row 4 ($40-$4F): Empty + invalid padding
  .fill 8, EMPTY_PIECE
  .fill 8, EMPTY_PIECE

  // Row 5 ($50-$5F): Empty + invalid padding
  .fill 8, EMPTY_PIECE
  .fill 8, EMPTY_PIECE

  // Row 6 ($60-$6F): White pawns + invalid padding
  .byte WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN
  .fill 8, EMPTY_PIECE    // Invalid columns $68-$6F

  // Row 7 ($70-$7F): White back rank + invalid padding
  .byte WHITE_ROOK, WHITE_KNIGHT, WHITE_BISHOP, WHITE_QUEEN, WHITE_KING, WHITE_BISHOP, WHITE_KNIGHT, WHITE_ROOK
  .fill 8, EMPTY_PIECE    // Invalid columns $78-$7F

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

