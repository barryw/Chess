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
// Pawn Structure Evaluation Constants
//
.const DOUBLED_PAWN_PENALTY = 15
.const ISOLATED_PAWN_PENALTY = 20
.const PASSED_PAWN_BONUS_BASE = 20

//
// King Safety Evaluation Constants
//
.const CASTLED_BONUS = 30         // Bonus for being on castled squares
.const PAWN_SHIELD_BONUS = 10     // Bonus per pawn in shield
.const OPEN_FILE_PENALTY = 25     // Penalty for open file near king
.const KING_CENTER_PENALTY = 30   // Penalty for king in center in middlegame

// Passed pawn bonus by rank (row 0 = rank 8, row 7 = rank 1)
// White pawns advance toward row 0, black toward row 7
PassedPawnBonus:
  .byte 60, 50, 40, 30, 20, 20, 0, 0   // White: rank 7=60 down to rank 2=20

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
// Pawn count storage per file (0-7)
//
WhitePawnsPerFile: .fill 8, $00
BlackPawnsPerFile: .fill 8, $00

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
  // Evaluate pawn structure
  jsr EvaluatePawnStructure
  // Evaluate king safety
  jsr EvaluateKingSafety
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
//
// EvaluatePawnStructure
// Analyze pawn structure: doubled, isolated, passed pawns
// Adds/subtracts from EvalScore
// Clobbers: A, X, Y, $f0-$f7
//
EvaluatePawnStructure:
  // Clear pawn counts
  ldx #$07
  lda #$00
!clear_pawn_counts:
  sta WhitePawnsPerFile, x
  sta BlackPawnsPerFile, x
  dex
  bpl !clear_pawn_counts-

  // Count pawns per file
  ldx #$00              // Board index

!count_pawns_loop:
  // Check if valid square
  txa
  and #OFFBOARD_MASK
  bne !count_next+

  // Get piece
  lda Board88, x
  and #$07              // Get type
  cmp #$01              // Is it a pawn?
  bne !count_next+

  // Get file (column)
  txa
  and #$07
  tay                   // Y = file (0-7)

  // Check color
  lda Board88, x
  and #WHITE_COLOR
  bne !white_pawn_count+

  // Black pawn
  lda BlackPawnsPerFile, y
  clc
  adc #$01
  sta BlackPawnsPerFile, y
  jmp !count_next+

!white_pawn_count:
  lda WhitePawnsPerFile, y
  clc
  adc #$01
  sta WhitePawnsPerFile, y

!count_next:
  inx
  cpx #BOARD_SIZE
  bne !count_pawns_loop-

  //
  // Check for doubled pawns (more than 1 pawn on same file)
  //
  ldx #$07              // File index

!doubled_loop:
  // White doubled
  lda WhitePawnsPerFile, x
  cmp #$02
  bcc !no_white_doubled+

  // Penalty for white doubled pawns
  sec
  lda EvalScore
  sbc #DOUBLED_PAWN_PENALTY
  sta EvalScore
  lda EvalScore + 1
  sbc #$00
  sta EvalScore + 1

!no_white_doubled:
  // Black doubled
  lda BlackPawnsPerFile, x
  cmp #$02
  bcc !no_black_doubled+

  // Bonus for white (black has weak pawns)
  clc
  lda EvalScore
  adc #DOUBLED_PAWN_PENALTY
  sta EvalScore
  lda EvalScore + 1
  adc #$00
  sta EvalScore + 1

!no_black_doubled:
  dex
  bpl !doubled_loop-

  //
  // Check for isolated pawns (no friendly pawn on adjacent files)
  //
  ldx #$07              // File index

!isolated_loop:
  // White isolated check
  lda WhitePawnsPerFile, x
  beq !check_black_iso+ // No white pawn on this file

  // Check adjacent files
  cpx #$00
  beq !check_right_w+   // File a, only check right

  // Check left file
  lda WhitePawnsPerFile - 1, x
  bne !no_white_iso+    // Has neighbor on left

!check_right_w:
  cpx #$07
  beq !white_is_iso+    // File h, already checked left, isolated

  // Check right file
  lda WhitePawnsPerFile + 1, x
  bne !no_white_iso+    // Has neighbor on right

!white_is_iso:
  // White isolated pawn - penalty
  sec
  lda EvalScore
  sbc #ISOLATED_PAWN_PENALTY
  sta EvalScore
  lda EvalScore + 1
  sbc #$00
  sta EvalScore + 1

!no_white_iso:
!check_black_iso:
  // Black isolated check
  lda BlackPawnsPerFile, x
  beq !next_iso_file+   // No black pawn on this file

  cpx #$00
  beq !check_right_b+

  lda BlackPawnsPerFile - 1, x
  bne !no_black_iso+

!check_right_b:
  cpx #$07
  beq !black_is_iso+

  lda BlackPawnsPerFile + 1, x
  bne !no_black_iso+

!black_is_iso:
  // Black isolated pawn - bonus for white
  clc
  lda EvalScore
  adc #ISOLATED_PAWN_PENALTY
  sta EvalScore
  lda EvalScore + 1
  adc #$00
  sta EvalScore + 1

!no_black_iso:
!next_iso_file:
  dex
  bpl !isolated_loop-

  //
  // Check for passed pawns (no enemy pawns ahead or on adjacent files)
  //
  ldx #$00              // Board index

!passed_loop:
  txa
  and #OFFBOARD_MASK
  bne !passed_next+

  lda Board88, x
  and #$07
  cmp #$01              // Pawn?
  bne !passed_next+

  // Get file and row
  stx $f0               // Save board index
  txa
  and #$07
  sta $f1               // $f1 = file (0-7)
  txa
  lsr
  lsr
  lsr
  lsr
  sta $f2               // $f2 = row (0-7)

  // Check pawn color
  lda Board88, x
  and #WHITE_COLOR
  bne !check_white_passed+

  // Black pawn - check if passed (no white pawns ahead toward row 7)
  jsr CheckBlackPassed
  bcc !passed_next+

  // Black passed pawn - penalty for white
  // Bonus = PassedPawnBonus[7 - row] since black advances toward row 7
  lda #$07
  sec
  sbc $f2
  tay
  lda PassedPawnBonus, y
  sta $f3
  sec
  lda EvalScore
  sbc $f3
  sta EvalScore
  lda EvalScore + 1
  sbc #$00
  sta EvalScore + 1
  jmp !passed_restore+

!check_white_passed:
  // White pawn - check if passed (no black pawns ahead toward row 0)
  jsr CheckWhitePassed
  bcc !passed_restore+

  // White passed pawn - bonus for white
  // Bonus = PassedPawnBonus[row] since white advances toward row 0
  ldy $f2
  lda PassedPawnBonus, y
  sta $f3
  clc
  lda EvalScore
  adc $f3
  sta EvalScore
  lda EvalScore + 1
  adc #$00
  sta EvalScore + 1

!passed_restore:
  ldx $f0

!passed_next:
  inx
  cpx #BOARD_SIZE
  bne !passed_loop-

  rts

//
// CheckWhitePassed
// Check if white pawn at $f1 (file), $f2 (row) is passed
// Output: Carry set = passed, Carry clear = not passed
// Clobbers: A, Y, $f4
//
CheckWhitePassed:
  // Check rows above (row-1 down to row 0) on file and adjacent files
  lda $f2
  sta $f4               // Current row to check

!check_wp_row:
  dec $f4
  bmi !wp_is_passed+    // Checked all rows, it's passed

  // Calculate 0x88 index: row * 16 + file
  lda $f4
  asl
  asl
  asl
  asl                   // row * 16
  ora $f1               // + file
  tay                   // Y = square to check

  // Check same file for black pawn
  lda Board88, y
  and #$07
  cmp #$01              // Pawn?
  bne !check_wp_adj+
  lda Board88, y
  and #WHITE_COLOR
  beq !wp_not_passed+   // Black pawn blocks

!check_wp_adj:
  // Check left file if not file a
  lda $f1
  beq !check_wp_right+
  dey                   // Left square
  lda Board88, y
  and #$07
  cmp #$01
  bne !check_wp_right_restore+
  lda Board88, y
  and #WHITE_COLOR
  beq !wp_not_passed+   // Black pawn on left

!check_wp_right_restore:
  iny                   // Restore Y

!check_wp_right:
  // Check right file if not file h
  lda $f1
  cmp #$07
  beq !check_wp_row-
  iny                   // Right square
  lda Board88, y
  and #$07
  cmp #$01
  bne !check_wp_row-
  lda Board88, y
  and #WHITE_COLOR
  beq !wp_not_passed+   // Black pawn on right

  jmp !check_wp_row-

!wp_is_passed:
  sec
  rts

!wp_not_passed:
  clc
  rts

//
// CheckBlackPassed
// Check if black pawn at $f1 (file), $f2 (row) is passed
// Output: Carry set = passed, Carry clear = not passed
// Clobbers: A, Y, $f4
//
CheckBlackPassed:
  // Check rows below (row+1 up to row 7) on file and adjacent files
  lda $f2
  sta $f4

!check_bp_row:
  inc $f4
  lda $f4
  cmp #$08
  beq !bp_is_passed+    // Checked all rows, it's passed

  // Calculate 0x88 index
  lda $f4
  asl
  asl
  asl
  asl
  ora $f1
  tay

  // Check same file for white pawn
  lda Board88, y
  and #$07
  cmp #$01
  bne !check_bp_adj+
  lda Board88, y
  and #WHITE_COLOR
  bne !bp_not_passed+   // White pawn blocks

!check_bp_adj:
  // Check left file
  lda $f1
  beq !check_bp_right+
  dey
  lda Board88, y
  and #$07
  cmp #$01
  bne !check_bp_right_restore+
  lda Board88, y
  and #WHITE_COLOR
  bne !bp_not_passed+

!check_bp_right_restore:
  iny

!check_bp_right:
  // Check right file
  lda $f1
  cmp #$07
  beq !check_bp_row-
  iny
  lda Board88, y
  and #$07
  cmp #$01
  bne !check_bp_row-
  lda Board88, y
  and #WHITE_COLOR
  bne !bp_not_passed+

  jmp !check_bp_row-

!bp_is_passed:
  sec
  rts

!bp_not_passed:
  clc
  rts

//
// EvaluateKingSafety
// Score king safety: castling position, pawn shield, exposure
// Adds/subtracts from EvalScore
// Clobbers: A, X, Y, $f0-$f4
//
EvaluateKingSafety:
  // Evaluate white king safety
  lda whitekingsq
  jsr EvaluateSingleKingSafety
  // A = safety score (positive = safe)
  // Add to EvalScore (good for white)
  clc
  adc EvalScore
  sta EvalScore
  lda EvalScore + 1
  adc #$00
  sta EvalScore + 1

  // Evaluate black king safety
  lda blackkingsq
  jsr EvaluateSingleKingSafety
  // A = safety score
  // Subtract from EvalScore (good for black = bad for white)
  sta $f0
  sec
  lda EvalScore
  sbc $f0
  sta EvalScore
  lda EvalScore + 1
  sbc #$00
  sta EvalScore + 1

  rts

//
// EvaluateSingleKingSafety
// Input: A = king square (0x88)
// Output: A = safety score (0-50 range, higher = safer)
// Clobbers: X, Y, $f0-$f4
//
EvaluateSingleKingSafety:
  sta $f0               // $f0 = king square
  lda #$00
  sta $f1               // $f1 = safety score accumulator

  // Get file and row
  lda $f0
  and #$07
  sta $f2               // $f2 = file (0-7)
  lda $f0
  lsr
  lsr
  lsr
  lsr
  sta $f3               // $f3 = row (0-7)

  // Determine if this is white or black king
  lda $f0
  cmp whitekingsq
  beq !is_white+
  jmp EvalBlackKingSafety

!is_white:
  jmp EvalWhiteKingSafety

//
// EvalWhiteKingSafety - Helper for white king safety
// Input: $f0=king square, $f1=score, $f2=file, $f3=row
// Output: A = safety score
// Clobbers: X, Y
//
EvalWhiteKingSafety:
  // Check if castled (on g1 or c1 = row 7, file 6 or 2)
  lda $f3
  cmp #$07              // Row 7 (rank 1)?
  beq !check_castled_file+
  jmp !white_not_castled+

!check_castled_file:
  lda $f2
  cmp #$06              // File g (kingside)?
  beq !white_castled+
  cmp #$02              // File c (queenside)?
  beq !white_castled+
  jmp !white_not_castled+

!white_castled:
  // King is castled - bonus
  clc
  lda $f1
  adc #CASTLED_BONUS
  sta $f1

  // Check pawn shield (pawns in front of king)
  // For kingside: check f2, g2, h2 squares
  // For queenside: check a2, b2, c2 squares
  lda $f2
  cmp #$06
  bne !white_qs_shield+

  // Kingside: check $65 (f2), $66 (g2), $67 (h2)
  lda Board88 + $65
  and #$07
  cmp #$01              // Pawn?
  bne !ws1+
  lda Board88 + $65
  and #WHITE_COLOR
  beq !ws1+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!ws1:
  lda Board88 + $66
  and #$07
  cmp #$01
  bne !ws2+
  lda Board88 + $66
  and #WHITE_COLOR
  beq !ws2+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!ws2:
  lda Board88 + $67
  and #$07
  cmp #$01
  bne !white_done+
  lda Board88 + $67
  and #WHITE_COLOR
  beq !white_done+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
  jmp !white_done+

!white_qs_shield:
  // Queenside: check $60 (a2), $61 (b2), $62 (c2)
  lda Board88 + $60
  and #$07
  cmp #$01
  bne !wqs1+
  lda Board88 + $60
  and #WHITE_COLOR
  beq !wqs1+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!wqs1:
  lda Board88 + $61
  and #$07
  cmp #$01
  bne !wqs2+
  lda Board88 + $61
  and #WHITE_COLOR
  beq !wqs2+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!wqs2:
  lda Board88 + $62
  and #$07
  cmp #$01
  bne !white_done+
  lda Board88 + $62
  and #WHITE_COLOR
  beq !white_done+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
  jmp !white_done+

!white_not_castled:
  // King not castled - check if in center (files d-e)
  lda $f2
  cmp #$03              // File d?
  beq !white_center_penalty+
  cmp #$04              // File e?
  bne !white_done+

!white_center_penalty:
  // King in center - penalty
  sec
  lda $f1
  sbc #KING_CENTER_PENALTY
  sta $f1

!white_done:
  lda $f1               // Return safety score
  rts

//
// EvalBlackKingSafety - Helper for black king safety
// Input: $f0=king square, $f1=score, $f2=file, $f3=row
// Output: A = safety score
// Clobbers: X, Y
//
EvalBlackKingSafety:
  // Check if castled (on g8 or c8 = row 0, file 6 or 2)
  lda $f3
  cmp #$00              // Row 0 (rank 8)?
  beq !check_black_castled_file+
  jmp !black_not_castled+

!check_black_castled_file:
  lda $f2
  cmp #$06              // File g?
  beq !black_castled+
  cmp #$02              // File c?
  beq !black_castled+
  jmp !black_not_castled+

!black_castled:
  // King is castled - bonus
  clc
  lda $f1
  adc #CASTLED_BONUS
  sta $f1

  // Check pawn shield (pawns in front of king)
  // For kingside: check f7, g7, h7 squares
  // For queenside: check a7, b7, c7 squares
  lda $f2
  cmp #$06
  bne !black_qs_shield+

  // Kingside: check $15 (f7), $16 (g7), $17 (h7)
  lda Board88 + $15
  and #$07
  cmp #$01
  bne !bs1+
  lda Board88 + $15
  and #WHITE_COLOR
  bne !bs1+             // Must be BLACK pawn
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!bs1:
  lda Board88 + $16
  and #$07
  cmp #$01
  bne !bs2+
  lda Board88 + $16
  and #WHITE_COLOR
  bne !bs2+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!bs2:
  lda Board88 + $17
  and #$07
  cmp #$01
  bne !black_done+
  lda Board88 + $17
  and #WHITE_COLOR
  bne !black_done+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
  jmp !black_done+

!black_qs_shield:
  // Queenside: check $10 (a7), $11 (b7), $12 (c7)
  lda Board88 + $10
  and #$07
  cmp #$01
  bne !bqs1+
  lda Board88 + $10
  and #WHITE_COLOR
  bne !bqs1+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!bqs1:
  lda Board88 + $11
  and #$07
  cmp #$01
  bne !bqs2+
  lda Board88 + $11
  and #WHITE_COLOR
  bne !bqs2+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
!bqs2:
  lda Board88 + $12
  and #$07
  cmp #$01
  bne !black_done+
  lda Board88 + $12
  and #WHITE_COLOR
  bne !black_done+
  clc
  lda $f1
  adc #PAWN_SHIELD_BONUS
  sta $f1
  jmp !black_done+

!black_not_castled:
  // King not castled - check if in center
  lda $f2
  cmp #$03
  beq !black_center_penalty+
  cmp #$04
  bne !black_done+

!black_center_penalty:
  sec
  lda $f1
  sbc #KING_CENTER_PENALTY
  sta $f1

!black_done:
  lda $f1               // Return safety score
  rts
