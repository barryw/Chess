#importonce

// Chess Rules Module
// Draw detection: 50-move rule, threefold repetition, insufficient material

*=* "AI Rules"

//
// UpdateHalfmoveClock
// Call after each move to update the 50-move rule counter
// Input: A = 1 if pawn moved, 0 otherwise
//        Carry set if capture occurred
// Resets clock on pawn move or capture, increments otherwise
//
UpdateHalfmoveClock:
  bcs !reset_clock+     // Capture - reset
  cmp #$01
  beq !reset_clock+     // Pawn move - reset

  // Not pawn or capture - increment
  inc HalfmoveClock
  rts

!reset_clock:
  lda #$00
  sta HalfmoveClock
  rts

//
// CheckFiftyMoveRule
// Check if 50-move rule draw has been reached
// Output: Carry set = draw by 50-move rule
//         Carry clear = not a draw
//
CheckFiftyMoveRule:
  lda HalfmoveClock
  cmp #100              // 50 moves = 100 half-moves
  bcs !fifty_draw+
  clc
  rts
!fifty_draw:
  sec
  rts

//
// RecordPosition
// Store current position hash in history for repetition detection
// Call after each move
// Uses ZobristHash (2 bytes) from zobrist.asm
//
RecordPosition:
  ldx HistoryCount
  cpx #MAX_HISTORY
  bcs !history_full+    // Don't overflow

  lda ZobristHash
  sta PositionHistoryLo, x
  lda ZobristHash + 1
  sta PositionHistoryHi, x
  inc HistoryCount

!history_full:
  rts

//
// CheckRepetition
// Check if current position has occurred 3 times (threefold repetition)
// Output: Carry set = draw by repetition
//         Carry clear = not a draw
// Clobbers: A, X, Y
// Optimized: Loop check at bottom saves 1 cycle/iteration (up to 200 cycles)
//
CheckRepetition:
  lda #$00
  sta RepeatCount       // Count occurrences
  ldx #$00              // History index
  cpx HistoryCount      // Handle empty history
  beq !check_rep_done+

!check_rep_loop:
  // Compare current hash with history[X]
  lda ZobristHash
  cmp PositionHistoryLo, x
  bne !rep_next+
  lda ZobristHash + 1
  cmp PositionHistoryHi, x
  bne !rep_next+

  // Match found
  inc RepeatCount
  lda RepeatCount
  cmp #$03              // 3 occurrences?
  bcs !repetition_draw+

!rep_next:
  inx
  cpx HistoryCount      // Check at bottom: BNE saves 1 cycle vs JMP
  bne !check_rep_loop-

!check_rep_done:
  clc                   // No repetition draw
  rts

!repetition_draw:
  sec                   // Draw by repetition
  rts

RepeatCount:
  .byte $00

//
// ClearPositionHistory
// Reset history for new game
//
ClearPositionHistory:
  lda #$00
  sta HistoryCount
  sta HalfmoveClock
  rts

//
// CheckInsufficientMaterial
// Check if the position has insufficient material for checkmate
// Draws: K vs K, K+B vs K, K+N vs K, K+B vs K+B (same color)
// Output: Carry set = insufficient material (draw)
//         Carry clear = sufficient material
// Clobbers: A, X, Y, $e0-$e5
//
// Strategy: Count pieces by type. If only kings remain, or only
// king + minor piece vs king, it's insufficient.
//
// Optimized: Hot path (offboard/empty) uses branches, saves ~240 cycles
//
CheckInsufficientMaterial:
  // Initialize piece counts
  lda #$00
  sta WhitePawnCnt
  sta WhiteKnightCnt
  sta WhiteBishopCnt
  sta WhiteRookCnt
  sta WhiteQueenCnt
  sta BlackPawnCnt
  sta BlackKnightCnt
  sta BlackBishopCnt
  sta BlackRookCnt
  sta BlackQueenCnt
  sta WhiteBishopSquare
  sta BlackBishopSquare

  // Scan board
  ldx #$00              // Board index

!insuf_scan_loop:
  // Check if valid square (hot path: 64/128 squares are offboard)
  txa
  and #OFFBOARD_MASK
  bne !insuf_next_sq+   // Offboard - branch to nearby label (2 cycles vs 3)

  // Check if empty (hot path: most valid squares are empty)
  lda Board88, x
  cmp #EMPTY_PIECE
  beq !insuf_next_sq+   // Empty - branch to nearby label (2 cycles vs 3)

  // Has piece - process (cold path, ~16-32 pieces)
  jmp !process_piece+

!insuf_next_sq:
  inx
  cpx #BOARD_SIZE
  bne !insuf_scan_loop- // Branch back (2 cycles vs 3 for JMP)

!done_scan:
  jmp !evaluate_material+

// Piece processing moved here to keep hot path tight
!process_piece:
  // Save square for bishop color check
  stx TempSq

  // Determine piece type and color
  pha                   // Save piece
  and #WHITE_COLOR      // Get color bit
  sta TempColor         // $80 = white, $00 = black
  pla                   // Restore piece
  and #$07              // Get type (1-6)

  // Increment appropriate counter
  cmp #PAWN_TYPE
  bne !not_pawn_insuf+
  lda TempColor
  bne !white_pawn_insuf+
  inc BlackPawnCnt
  jmp !insuf_next_sq-
!white_pawn_insuf:
  inc WhitePawnCnt
  jmp !insuf_next_sq-

!not_pawn_insuf:
  cmp #KNIGHT_TYPE
  bne !not_knight_insuf+
  lda TempColor
  bne !white_knight_insuf+
  inc BlackKnightCnt
  jmp !insuf_next_sq-
!white_knight_insuf:
  inc WhiteKnightCnt
  jmp !insuf_next_sq-

!not_knight_insuf:
  cmp #BISHOP_TYPE
  bne !not_bishop_insuf+
  // Save bishop square color for same-color bishop check
  lda TempSq
  jsr GetSquareColor    // Returns $00 = dark, $01 = light
  sta TempBishopColor
  lda TempColor
  bne !white_bishop_insuf+
  inc BlackBishopCnt
  lda TempBishopColor
  sta BlackBishopSquare
  jmp !insuf_next_sq-
!white_bishop_insuf:
  inc WhiteBishopCnt
  lda TempBishopColor
  sta WhiteBishopSquare
  jmp !insuf_next_sq-

!not_bishop_insuf:
  cmp #ROOK_TYPE
  bne !not_rook_insuf+
  lda TempColor
  bne !white_rook_insuf+
  inc BlackRookCnt
  jmp !insuf_next_sq-
!white_rook_insuf:
  inc WhiteRookCnt
  jmp !insuf_next_sq-

!not_rook_insuf:
  cmp #QUEEN_TYPE
  bne !is_king_insuf+   // Must be king, skip counting
  lda TempColor
  bne !white_queen_insuf+
  inc BlackQueenCnt
  jmp !insuf_next_sq-
!white_queen_insuf:
  inc WhiteQueenCnt
  jmp !insuf_next_sq-

!is_king_insuf:
  jmp !insuf_next_sq-

!evaluate_material:

  // Now check for insufficient material
  // First: any pawns, rooks, or queens = sufficient
  lda WhitePawnCnt
  ora BlackPawnCnt
  ora WhiteRookCnt
  ora BlackRookCnt
  ora WhiteQueenCnt
  ora BlackQueenCnt
  bne !sufficient+

  // Only kings, knights, and bishops left
  // Calculate total minor pieces for each side
  lda WhiteKnightCnt
  clc
  adc WhiteBishopCnt
  sta WhiteMinorCnt

  lda BlackKnightCnt
  clc
  adc BlackBishopCnt
  sta BlackMinorCnt

  // K vs K
  lda WhiteMinorCnt
  ora BlackMinorCnt
  beq !insufficient+

  // K + minor vs K (either side has 1 minor, other has 0)
  lda WhiteMinorCnt
  beq !check_black_lone_minor+
  cmp #$01
  bne !check_two_bishops+
  lda BlackMinorCnt
  beq !insufficient+    // White has 1 minor, black has none
  jmp !check_two_bishops+

!check_black_lone_minor:
  lda BlackMinorCnt
  cmp #$01
  beq !insufficient+    // Black has 1 minor, white has none

!check_two_bishops:
  // K + B vs K + B on same color squares
  lda WhiteMinorCnt
  cmp #$01
  bne !sufficient+
  lda BlackMinorCnt
  cmp #$01
  bne !sufficient+

  // Both sides have exactly 1 minor piece
  // Check if both are bishops on same color
  lda WhiteBishopCnt
  cmp #$01
  bne !sufficient+
  lda BlackBishopCnt
  cmp #$01
  bne !sufficient+

  // Both sides have single bishop - check colors
  lda WhiteBishopSquare
  cmp BlackBishopSquare
  bne !sufficient+      // Different colors = can mate

!insufficient:
  sec                   // Insufficient material
  rts

!sufficient:
  clc                   // Sufficient material
  rts

//
// GetSquareColor
// Determine if a square is light or dark
// Input: A = 0x88 square index
// Output: A = 0 (dark) or 1 (light)
// Dark squares: a1, c1, e1, g1, b2, d2... (row XOR col) odd
// Light squares: b1, d1, f1, h1, a2, c2... (row XOR col) even
// Optimized: XOR trick avoids PHA/PLA, saves ~11 cycles
//
GetSquareColor:
  sta TempCol           // Save square
  lsr                   // Shift right 4 times to get row in low nibble
  lsr
  lsr
  lsr
  eor TempCol           // XOR with original: bit0 = (row bit0) XOR (col bit0)
  and #$01              // Isolate parity bit
  eor #$01              // Flip convention (0=dark, 1=light)
  rts

//
// IsCurrentKingAttacked
// Check if the current side's king (based on SearchSide) is under attack
// Output: Carry set = king is attacked, Carry clear = not attacked
// Clobbers: A
// Optimized: Extracted common code, reduces duplication by ~40 bytes
//
IsCurrentKingAttacked:
  // Get king square based on SearchSide
  lda SearchSide
  bne !get_white_king+
  lda blackkingsq
  bne !got_king+        // BNE always taken (king never at $00)
!get_white_king:
  lda whitekingsq
!got_king:
  sta attack_sq

  // Set attacker color (opposite of SearchSide)
  // If SearchSide=1 (white), attacker=black (0)
  // If SearchSide=0 (black), attacker=white (1)
  lda SearchSide
  eor #$01              // Flip: 0->1, 1->0
  sta attack_color
  jmp IsSquareAttacked  // Tail call optimization: JMP instead of JSR+RTS

//
// AICheckGameState
// Comprehensive game state check for AI search combining all conditions
// Output: A = game state constant
//   GAME_NORMAL (0) = game continues normally
//   GAME_CHECK (1) = king in check, has moves
//   GAME_CHECKMATE (2) = checkmate
//   GAME_STALEMATE (3) = stalemate
//   GAME_DRAW_50_MOVE (4) = 50-move rule
//   GAME_DRAW_REPETITION (5) = threefold repetition
//   GAME_DRAW_INSUFFICIENT (6) = insufficient material
//
AICheckGameState:
  // First check draws (before expensive move generation)
  jsr CheckFiftyMoveRule
  bcc !not_fifty+
  lda #GAME_DRAW_50_MOVE
  rts

!not_fifty:
  jsr CheckRepetition
  bcc !not_repetition+
  lda #GAME_DRAW_REPETITION
  rts

!not_repetition:
  jsr CheckInsufficientMaterial
  bcc !not_insufficient+
  lda #GAME_DRAW_INSUFFICIENT
  rts

!not_insufficient:
  // Generate legal moves to check for checkmate/stalemate
  jsr GenerateLegalMoves
  lda MoveCount
  bne !has_moves+

  // No moves - check if king is in check
  jsr IsCurrentKingAttacked
  bcc !stalemate+

  // King in check with no moves = checkmate
  lda #GAME_CHECKMATE
  rts

!stalemate:
  lda #GAME_STALEMATE
  rts

!has_moves:
  // Has moves - check if in check
  jsr IsCurrentKingAttacked
  bcc !normal+

  lda #GAME_CHECK
  rts

!normal:
  lda #GAME_NORMAL
  rts

// Temporary storage for insufficient material check
WhitePawnCnt:     .byte $00
WhiteKnightCnt:   .byte $00
WhiteBishopCnt:   .byte $00
WhiteRookCnt:     .byte $00
WhiteQueenCnt:    .byte $00
BlackPawnCnt:     .byte $00
BlackKnightCnt:   .byte $00
BlackBishopCnt:   .byte $00
BlackRookCnt:     .byte $00
BlackQueenCnt:    .byte $00
WhiteMinorCnt:    .byte $00
BlackMinorCnt:    .byte $00
WhiteBishopSquare: .byte $00
BlackBishopSquare: .byte $00
TempSq:           .byte $00
TempColor:        .byte $00
TempCol:          .byte $00
TempBishopColor:  .byte $00
