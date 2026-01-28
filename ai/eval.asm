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

//
// EvaluatePosition
// Full evaluation: material + piece-square tables
// Result in EvalScore (16-bit signed)
// Clobbers: A, X, Y, $f0-$f6
//
EvaluatePosition:
  // Start with material evaluation
  jsr EvaluateMaterial

  // Now add PST bonuses
  ldx #$00              // Board index

PstLoop:
  // Check if valid square
  txa
  and #OFFBOARD_MASK
  bne PstNext

  // Get piece at square
  lda Board88, x
  cmp #EMPTY_PIECE
  beq PstNext

  // Save board index
  stx $f0

  // Get piece type and color
  pha
  and #WHITE_COLOR
  sta $f1               // $f1 = color ($80=white, $00=black)
  pla
  and #$07              // Piece type (1-6)
  sta $f2               // $f2 = piece type

  // Get PST pointer for this piece type
  tay
  lda PST_Table_Lo, y
  sta $f3
  lda PST_Table_Hi, y
  sta $f4               // $f3/$f4 = PST pointer

  // Convert 0x88 square to 0-63 index
  // sq64 = (row * 8) + col = ((sq >> 4) * 8) + (sq & 7)
  lda $f0
  and #$07              // Column (0-7)
  sta $f5
  lda $f0
  lsr
  lsr
  lsr
  lsr                   // Row (0-7)
  asl
  asl
  asl                   // Row * 8
  ora $f5               // + column = 0-63
  sta $f5               // $f5 = square index 0-63

  // For black pieces, mirror the square (XOR with $38 = flip rank)
  lda $f1
  beq !mirror+
  jmp !lookup+
!mirror:
  lda $f5
  eor #$38              // Mirror for black
  sta $f5

!lookup:
  // Look up PST value
  ldy $f5
  lda ($f3), y          // A = PST value (signed byte)
  sta $f6               // Save PST value

  // Call appropriate helper based on color
  lda $f1
  beq PstBlackPiece
  jmp PstWhitePiece

PstNext:
  inx
  cpx #BOARD_SIZE
  beq !done+
  jmp PstLoop
!done:
  rts

//
// PstWhitePiece - Add PST value for white piece
// Input: $f6 = signed PST value
// Modifies: A
//
PstWhitePiece:
  lda $f6
  bmi !negative+
  // Positive PST value - add it
  clc
  lda EvalScore
  adc $f6
  sta EvalScore
  lda EvalScore + 1
  adc #$00
  sta EvalScore + 1
  ldx $f0
  jmp PstNext

!negative:
  // Negative PST value - subtract its absolute value
  lda $f6
  eor #$ff
  clc
  adc #$01              // Negate to get positive
  sta $f6
  sec
  lda EvalScore
  sbc $f6
  sta EvalScore
  lda EvalScore + 1
  sbc #$00
  sta EvalScore + 1
  ldx $f0
  jmp PstNext

//
// PstBlackPiece - Subtract PST value for black piece
// Input: $f6 = signed PST value
// Modifies: A
//
PstBlackPiece:
  lda $f6
  bmi !negative+
  // Positive PST value - subtract it
  sec
  lda EvalScore
  sbc $f6
  sta EvalScore
  lda EvalScore + 1
  sbc #$00
  sta EvalScore + 1
  ldx $f0
  jmp PstNext

!negative:
  // Negative PST value - subtracting negative = adding positive
  lda $f6
  eor #$ff
  clc
  adc #$01              // Negate to get positive
  sta $f6
  clc
  lda EvalScore
  adc $f6
  sta EvalScore
  lda EvalScore + 1
  adc #$00
  sta EvalScore + 1
  ldx $f0
  jmp PstNext
