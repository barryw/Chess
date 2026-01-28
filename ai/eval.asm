#importonce

// Position Evaluation
// Returns centipawn score (positive = white advantage)

*=* "AI Eval"

//
// Piece Values (scaled: pawn = 10)
// Values chosen to fit in single byte operations while preserving
// relative values: P=1, N=3.2, B=3.3, R=5, Q=9
//
.const PAWN_VALUE   = 10
.const KNIGHT_VALUE = 32
.const BISHOP_VALUE = 33
.const ROOK_VALUE   = 50
.const QUEEN_VALUE  = 90
.const KING_VALUE   = 0    // Kings not counted in material

//
// Piece value lookup table
// Indexed by (piece & $07) - piece type
// Index 0 = empty, 1-6 = pawn through king
//
PieceValues:
  .byte 0              // 0: empty/invalid
  .byte PAWN_VALUE     // 1: pawn
  .byte KNIGHT_VALUE   // 2: knight
  .byte BISHOP_VALUE   // 3: bishop
  .byte ROOK_VALUE     // 4: rook
  .byte QUEEN_VALUE    // 5: queen
  .byte KING_VALUE     // 6: king

//
// Evaluation result (16-bit signed)
// Positive = white advantage, negative = black advantage
//
EvalScore:
  .word $0000

//
// Evaluate material balance
// Loops through board, sums white pieces, subtracts black pieces
// Result in EvalScore (16-bit signed)
// Clobbers: A, X, Y
//
EvaluateMaterial:
  // Clear score
  lda #$00
  sta EvalScore
  sta EvalScore + 1

  // Loop through all 0x88 squares
  ldx #$00

!squareloop:
  // Check if valid square (index & $88 == 0)
  txa
  and #OFFBOARD_MASK
  bne !nextsquare+

  // Get piece at this square
  lda Board88, x
  cmp #EMPTY_PIECE
  beq !nextsquare+

  // Save square index
  stx $f7

  // Extract piece type (lower 3 bits)
  pha                   // Save full piece value
  and #$07              // Get type (1-6)
  tay                   // Y = piece type index
  lda PieceValues, y    // A = piece value
  sta $f8               // Save value

  // Check piece color
  pla                   // Restore piece value
  and #WHITE_COLOR      // Check high bit
  beq !blackpiece+

  // White piece - add to score
  clc
  lda EvalScore
  adc $f8
  sta EvalScore
  lda EvalScore + 1
  adc #$00              // Add carry
  sta EvalScore + 1
  jmp !restorex+

!blackpiece:
  // Black piece - subtract from score
  sec
  lda EvalScore
  sbc $f8
  sta EvalScore
  lda EvalScore + 1
  sbc #$00              // Subtract borrow
  sta EvalScore + 1

!restorex:
  // Restore square index
  ldx $f7

!nextsquare:
  inx
  cpx #BOARD_SIZE       // Done all 128 bytes?
  bne !squareloop-

  rts
