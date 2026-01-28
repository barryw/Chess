#importonce

// Chess AI Search Module
// Implements Make/Unmake move infrastructure for tree search

*=* "AI Search"

//
// Undo Stack
// Each entry saves state needed to unmake a move
// Stack grows upward: undo[0] = depth 0, undo[1] = depth 1, etc.
//
// Entry format (6 bytes per entry):
//   +0: captured_piece (piece on target square before move, or EMPTY_PIECE)
//   +1: prev_castlerights
//   +2: prev_enpassantsq
//   +3: flags (bit 0 = castling, bit 1 = en passant capture, bit 2 = promotion)
//   +4: extra_from (for castling: rook's original square)
//   +5: extra_to (for castling: rook's new square, for EP: captured pawn square)
//
.const UNDO_ENTRY_SIZE = 6
.const UNDO_FLAG_CASTLING = %00000001
.const UNDO_FLAG_EP_CAPTURE = %00000010
.const UNDO_FLAG_PROMOTION = %00000100

// Undo stack storage (MAX_DEPTH entries x 6 bytes = 48 bytes)
UndoStack:
  .fill MAX_DEPTH * UNDO_ENTRY_SIZE, $00

// Current search depth (0 = root)
SearchDepth:
  .byte $00

// Side to move at current search node ($80 = white, $00 = black)
SearchSide:
  .byte WHITE_COLOR

//
// MakeMove
// Executes a move on the board, saving undo information
//
// Input: A = from square (0x88 index)
//        X = to square (0x88 index)
// Uses SearchDepth to index into UndoStack
// Clobbers: A, X, Y, $f0-$f5
//
MakeMove:
  sta $f0               // $f0 = from square
  stx $f1               // $f1 = to square

  // Calculate undo stack pointer: UndoStack + SearchDepth * 6
  lda SearchDepth
  asl                   // * 2
  sta $f2
  asl                   // * 4
  clc
  adc $f2               // * 6
  tax                   // X = offset into UndoStack

  // Save captured piece (what's on target square)
  ldy $f1               // Y = to square
  lda Board88, y
  sta UndoStack, x      // +0: captured_piece

  // Save castling rights
  lda castlerights
  sta UndoStack + 1, x  // +1: prev_castlerights

  // Save en passant square
  lda enpassantsq
  sta UndoStack + 2, x  // +2: prev_enpassantsq

  // Initialize flags to 0
  lda #$00
  sta UndoStack + 3, x  // +3: flags
  sta UndoStack + 4, x  // +4: extra_from
  sta UndoStack + 5, x  // +5: extra_to

  // Get the piece being moved
  ldy $f0               // Y = from square
  lda Board88, y
  sta $f3               // $f3 = moving piece

  // Get piece type (lower 3 bits)
  and #$07
  sta $f4               // $f4 = piece type (1-6)

  //
  // Handle special moves
  //

  // Check for king move (type 6)
  cmp #$06
  beq !is_king_move+
  jmp !not_king_move+

!is_king_move:
  // King move - check for castling (move delta = +2 or -2)
  lda $f1
  sec
  sbc $f0
  cmp #$02              // Kingside castling?
  beq !kingside_castle+
  cmp #$fe              // Queenside castling? (-2)
  beq !queenside_castle+
  jmp !update_king_pos+

!kingside_castle:
  // Set castling flag
  lda UndoStack + 3, x
  ora #UNDO_FLAG_CASTLING
  sta UndoStack + 3, x

  // Determine rook squares based on color
  lda $f3               // Moving piece (king)
  and #WHITE_COLOR
  bne !white_ks_castle+

  // Black kingside: rook h8($07) -> f8($05)
  lda #$07
  sta UndoStack + 4, x  // extra_from = h8
  lda #$05
  sta UndoStack + 5, x  // extra_to = f8
  jmp !do_castle_rook+

!white_ks_castle:
  // White kingside: rook h1($77) -> f1($75)
  lda #$77
  sta UndoStack + 4, x  // extra_from = h1
  lda #$75
  sta UndoStack + 5, x  // extra_to = f1
  jmp !do_castle_rook+

!queenside_castle:
  // Set castling flag
  lda UndoStack + 3, x
  ora #UNDO_FLAG_CASTLING
  sta UndoStack + 3, x

  lda $f3
  and #WHITE_COLOR
  bne !white_qs_castle+

  // Black queenside: rook a8($00) -> d8($03)
  lda #$00
  sta UndoStack + 4, x  // extra_from = a8
  lda #$03
  sta UndoStack + 5, x  // extra_to = d8
  jmp !do_castle_rook+

!white_qs_castle:
  // White queenside: rook a1($70) -> d1($73)
  lda #$70
  sta UndoStack + 4, x  // extra_from = a1
  lda #$73
  sta UndoStack + 5, x  // extra_to = d1

!do_castle_rook:
  // Move the rook - X still has undo stack offset
  // Get rook's from square
  ldy UndoStack + 4, x  // Y = rook from square
  lda Board88, y        // A = rook piece
  sta $f5               // $f5 = save rook piece

  // Clear rook's original square
  lda #EMPTY_PIECE
  sta Board88, y

  // Get rook's to square and place rook there
  ldy UndoStack + 5, x  // Y = rook to square
  lda $f5               // A = rook piece
  sta Board88, y        // Place rook at new position
  jmp !update_king_pos+

!update_king_pos:
  // Update king position tracker
  lda $f3
  and #WHITE_COLOR
  bne !update_white_king+
  lda $f1
  sta blackkingsq
  jmp !do_basic_move+
!update_white_king:
  lda $f1
  sta whitekingsq
  jmp !do_basic_move+

!not_king_move:
  // Check for pawn move (type 1)
  lda $f4
  cmp #$01
  beq !is_pawn_move+
  jmp !not_pawn_move+

!is_pawn_move:
  // Pawn move - check for en passant capture
  ldy $f1               // to square
  lda Board88, y
  cmp #EMPTY_PIECE
  bne !check_double_push+  // Capturing normal piece, not EP

  // Moving to empty square - check if it's en passant square
  lda $f1
  cmp enpassantsq
  bne !check_double_push+

  // En passant capture!
  lda UndoStack + 3, x
  ora #UNDO_FLAG_EP_CAPTURE
  sta UndoStack + 3, x

  // Calculate captured pawn square (same file, one row back)
  lda $f3               // Moving pawn
  and #WHITE_COLOR
  bne !white_ep_capture+

  // Black pawn capturing white pawn (white pawn one row north)
  lda $f1
  clc
  adc #$f0              // -16 = one row north
  sta UndoStack + 5, x  // extra_to = captured pawn square
  tay
  lda Board88, y        // Get the captured pawn
  sta UndoStack, x      // Store in captured_piece slot (overwrite EMPTY)
  lda #EMPTY_PIECE
  sta Board88, y        // Remove captured pawn
  jmp !clear_ep+

!white_ep_capture:
  // White pawn capturing black pawn (black pawn one row south)
  lda $f1
  clc
  adc #$10              // +16 = one row south
  sta UndoStack + 5, x  // extra_to = captured pawn square
  tay
  lda Board88, y        // Get the captured pawn
  sta UndoStack, x      // Store in captured_piece slot
  lda #EMPTY_PIECE
  sta Board88, y        // Remove captured pawn
  jmp !clear_ep+

!check_double_push:
  // Check for double pawn push (sets new en passant square)
  lda $f1
  sec
  sbc $f0
  cmp #$20              // +32 = black double push
  beq !set_ep_black+
  cmp #$e0              // -32 = white double push
  beq !set_ep_white+
  jmp !clear_ep+

!set_ep_black:
  // Black pushed 2 squares - EP square is the skipped square
  lda $f0
  clc
  adc #$10              // One row south
  sta enpassantsq
  jmp !do_basic_move+

!set_ep_white:
  // White pushed 2 squares
  lda $f0
  clc
  adc #$f0              // One row north (-16)
  sta enpassantsq
  jmp !do_basic_move+

!clear_ep:
  // No double push - clear en passant
  lda #NO_EN_PASSANT
  sta enpassantsq
  jmp !do_basic_move+

!not_pawn_move:
  // Not king or pawn - clear en passant square
  lda #NO_EN_PASSANT
  sta enpassantsq

  // Check for rook move (affects castling rights)
  lda $f4
  cmp #$04              // Rook?
  bne !do_basic_move+

  // Rook moved - update castling rights based on from square
  lda $f0
  cmp #$00              // a8?
  bne !check_h8+
  lda castlerights
  and #~CASTLE_BQ
  sta castlerights
  jmp !do_basic_move+
!check_h8:
  cmp #$07              // h8?
  bne !check_a1+
  lda castlerights
  and #~CASTLE_BK
  sta castlerights
  jmp !do_basic_move+
!check_a1:
  cmp #$70              // a1?
  bne !check_h1+
  lda castlerights
  and #~CASTLE_WQ
  sta castlerights
  jmp !do_basic_move+
!check_h1:
  cmp #$77              // h1?
  bne !do_basic_move+
  lda castlerights
  and #~CASTLE_WK
  sta castlerights

!do_basic_move:
  // Execute the basic move: clear from, place piece on to
  ldy $f0               // from square
  lda #EMPTY_PIECE
  sta Board88, y        // Clear from square

  ldy $f1               // to square
  lda $f3               // moving piece
  sta Board88, y        // Place on to square

  // Update castling rights if rook was captured
  lda UndoStack, x      // captured piece
  cmp #EMPTY_PIECE
  beq !make_done+
  and #$07
  cmp #$04              // Was it a rook?
  bne !make_done+

  // Rook captured - update castling rights
  lda $f1               // to square (where rook was)
  cmp #$00
  bne !cap_check_h8+
  lda castlerights
  and #~CASTLE_BQ
  sta castlerights
  jmp !make_done+
!cap_check_h8:
  cmp #$07
  bne !cap_check_a1+
  lda castlerights
  and #~CASTLE_BK
  sta castlerights
  jmp !make_done+
!cap_check_a1:
  cmp #$70
  bne !cap_check_h1+
  lda castlerights
  and #~CASTLE_WQ
  sta castlerights
  jmp !make_done+
!cap_check_h1:
  cmp #$77
  bne !make_done+
  lda castlerights
  and #~CASTLE_WK
  sta castlerights

!make_done:
  // Increment search depth
  inc SearchDepth

  // Flip side to move
  lda SearchSide
  eor #WHITE_COLOR
  sta SearchSide

  rts

//
// UnmakeMove
// Reverses a move using saved undo information
//
// Input: A = from square (original from, where piece returns)
//        X = to square (original to, now empty or has captured piece)
// Uses SearchDepth-1 to index into UndoStack
// Clobbers: A, X, Y, $f0-$f5
//
UnmakeMove:
  sta $f0               // $f0 = from square (piece returns here)
  stx $f1               // $f1 = to square (was destination)

  // Decrement search depth first
  dec SearchDepth

  // Flip side to move back
  lda SearchSide
  eor #WHITE_COLOR
  sta SearchSide

  // Calculate undo stack pointer
  lda SearchDepth
  asl
  sta $f2
  asl
  clc
  adc $f2
  tax                   // X = offset into UndoStack

  // Get the piece that moved (it's on the 'to' square now)
  ldy $f1
  lda Board88, y
  sta $f3               // $f3 = moving piece

  // Put the piece back on from square
  ldy $f0
  sta Board88, y

  // Check flags for special moves
  lda UndoStack + 3, x  // flags
  sta $f4               // $f4 = flags

  // Handle en passant capture
  and #UNDO_FLAG_EP_CAPTURE
  beq !check_castling+

  // En passant - restore captured pawn to its square
  ldy UndoStack + 5, x  // extra_to = captured pawn square
  lda UndoStack, x      // captured piece (the pawn)
  sta Board88, y        // Restore the pawn

  // Clear the to square (en passant target was empty)
  ldy $f1
  lda #EMPTY_PIECE
  sta Board88, y
  jmp !restore_state+

!check_castling:
  lda $f4
  and #UNDO_FLAG_CASTLING
  beq !restore_capture+

  // Castling - move rook back
  ldy UndoStack + 5, x  // extra_to = where rook is now
  lda Board88, y        // Get rook
  pha                   // Save rook
  lda #EMPTY_PIECE
  sta Board88, y        // Clear rook's current position

  ldy UndoStack + 4, x  // extra_from = rook's original square
  pla                   // Restore rook
  sta Board88, y        // Put rook back

  // Clear the king's to square
  ldy $f1
  lda #EMPTY_PIECE
  sta Board88, y
  jmp !restore_state+

!restore_capture:
  // Normal move - restore captured piece (or empty) to to square
  ldy $f1
  lda UndoStack, x      // captured_piece
  sta Board88, y

!restore_state:
  // Restore castling rights
  lda UndoStack + 1, x
  sta castlerights

  // Restore en passant square
  lda UndoStack + 2, x
  sta enpassantsq

  // Restore king position if it was a king that moved
  lda $f3
  and #$07
  cmp #$06              // King?
  bne !unmake_done+

  // Restore king position
  lda $f3
  and #WHITE_COLOR
  bne !restore_white_king+
  lda $f0
  sta blackkingsq
  jmp !unmake_done+
!restore_white_king:
  lda $f0
  sta whitekingsq

!unmake_done:
  rts

//
// IsSearchKingInCheck
// Check if the side that JUST moved left their king in check
// Call this AFTER MakeMove to verify move legality
//
// After MakeMove, SearchSide has been flipped to the opponent.
// So the side that just moved is (SearchSide XOR $80).
// We check if THEIR king is under attack by the CURRENT SearchSide.
//
// Output: Carry set = in check (move was illegal)
//         Carry clear = not in check (move was legal)
// Clobbers: A, X, Y, attack_sq, attack_color, and IsSquareAttacked temps
//
IsSearchKingInCheck:
  // Determine which king to check (the side that just moved)
  lda SearchSide
  eor #WHITE_COLOR        // Get the color of the side that just moved
  bne !check_white_king+

  // Black just moved - check black king
  lda blackkingsq
  jmp !setup_attack+

!check_white_king:
  // White just moved - check white king
  lda whitekingsq

!setup_attack:
  sta attack_sq           // King square to check

  // Attacker is the current SearchSide (the opponent)
  // Convert $80=white, $00=black to WHITES_TURN=1, BLACKS_TURN=0
  lda SearchSide
  beq !black_attacks+
  lda #WHITES_TURN        // White is attacking (SearchSide = white)
  jmp !call_attack+
!black_attacks:
  lda #BLACKS_TURN        // Black is attacking (SearchSide = black)
!call_attack:
  sta attack_color
  jsr IsSquareAttacked
  rts

//
// FilterLegalMoves
// Filter the move list to contain only legal moves
// Call after GenerateAllMoves to remove moves that leave king in check
//
// Input: MoveListFrom/MoveListTo filled with pseudo-legal moves
//        MoveCount = number of pseudo-legal moves
// Output: MoveListFrom/MoveListTo contains only legal moves
//         MoveCount = number of legal moves
//         A = number of legal moves
// Clobbers: A, X, Y, $e0-$e5
//
// Algorithm:
// - Iterate through all moves
// - For each move: MakeMove, check if in check, UnmakeMove
// - If legal, keep it; if illegal, skip it
// - Compact the list by writing legal moves to front
//
FilterLegalMoves:
  lda #$00
  sta $e0               // $e0 = read index
  sta $e1               // $e1 = write index (legal move count)

!filter_loop:
  // Check if we've processed all moves
  lda $e0
  cmp MoveCount
  beq !filter_done+

  // Get move at read index
  ldx $e0
  lda MoveListFrom, x
  sta $e2               // $e2 = from square
  lda MoveListTo, x
  sta $e3               // $e3 = to square

  // Make the move
  lda $e2
  ldx $e3
  jsr MakeMove

  // Check if this leaves our king in check
  jsr IsSearchKingInCheck
  php                   // Save carry (check result)

  // Unmake the move
  lda $e2
  ldx $e3
  jsr UnmakeMove

  // Check result
  plp
  bcs !skip_illegal+    // Carry set = in check = illegal

  // Legal move - copy to write position if different from read
  lda $e0
  cmp $e1
  beq !same_position+   // No need to copy if same position

  // Copy move to write position
  ldx $e0
  ldy $e1
  lda MoveListFrom, x
  sta MoveListFrom, y
  lda MoveListTo, x
  sta MoveListTo, y

!same_position:
  inc $e1               // Increment legal move count

!skip_illegal:
  inc $e0               // Next move
  jmp !filter_loop-

!filter_done:
  // Update MoveCount with legal move count
  lda $e1
  sta MoveCount
  rts

//
// GenerateLegalMoves
// Generate all legal moves for the current SearchSide
// Convenience function combining GenerateAllMoves + FilterLegalMoves
//
// Output: MoveListFrom/MoveListTo contains legal moves
//         MoveCount = number of legal moves
//         A = number of legal moves
// Clobbers: A, X, Y, many temps
//
GenerateLegalMoves:
  // Clear move list
  jsr ClearMoveList

  // Generate all pseudo-legal moves
  ldx SearchSide
  jsr GenerateAllMoves

  // Filter out illegal moves
  jsr FilterLegalMoves

  // Order moves: captures first (improves alpha-beta pruning)
  // Enemy color = opposite of SearchSide
  lda SearchSide
  eor #WHITE_COLOR      // Flip color bit
  tax                   // X = enemy color
  jsr OrderMoves

  lda MoveCount
  rts

//
// InitSearch
// Initialize search state before starting a new search
// Sets depth to 0 and side to current player
//
InitSearch:
  lda #$00
  sta SearchDepth

  // Set SearchSide from currentplayer
  lda currentplayer
  beq !black_to_move+
  lda #WHITE_COLOR
  sta SearchSide
  rts
!black_to_move:
  lda #BLACK_COLOR
  sta SearchSide
  rts

//
// Best move storage (set during search at root level)
//
BestMoveFrom:
  .byte $00
BestMoveTo:
  .byte $00

//
// Search state variables for Negamax recursion
// These use zero page for speed ($e6-$ef reserved for search)
//
// $e6 = current depth in Negamax call
// $e7 = best score at current depth
// $e8 = move index during iteration
// $e9 = current move from square
// $ea = current move to square
// $eb = current move score (after negate)
// $ec = root depth (to detect when to save best move)
//

//
// Evaluate
// Returns score from perspective of SearchSide
// Positive = good for SearchSide, negative = bad
// Output: A = score (signed 8-bit, clamped to -120..+120)
// Clobbers: Uses EvaluateMaterial temps
//
Evaluate:
  jsr EvaluateMaterial

  // EvalScore is 16-bit, positive = white advantage
  // Convert to 8-bit from perspective of SearchSide

  // First clamp to 8-bit range
  // If high byte is $00, low byte is positive (0-255)
  // If high byte is $FF, low byte is negative (-1 to -256 as signed)
  // Otherwise overflow - clamp to max/min

  lda EvalScore + 1    // High byte
  beq !positive+
  cmp #$FF
  beq !negative+

  // Overflow - determine direction and clamp
  bmi !clamp_neg+
  lda #120             // Clamp to +120
  jmp !apply_side+
!clamp_neg:
  lda #<-120           // Clamp to -120 ($88)
  jmp !apply_side+

!positive:
  // High byte is 0, check if low byte fits in signed positive
  lda EvalScore
  cmp #121
  bcc !apply_side+     // < 121, fits as positive
  lda #120             // Clamp to +120
  jmp !apply_side+

!negative:
  // High byte is $FF, low byte is negative
  lda EvalScore
  cmp #<-120           // Compare to -120 ($88)
  bcs !apply_side+     // >= -120 (as signed), fits
  lda #<-120           // Clamp to -120
  jmp !apply_side+

!apply_side:
  // Now A has 8-bit score from white's perspective
  // If SearchSide is black ($00), negate the score
  ldx SearchSide
  bne !done_eval+      // White = $80, non-zero, keep as-is

  // Black to move - negate score
  eor #$FF
  clc
  adc #$01

!done_eval:
  rts

//
// Negamax with Alpha-Beta Pruning
// Recursive search from current position
// Input: A = depth remaining
//        $e8 = alpha (lower bound, initially -128)
//        $e9 = beta (upper bound, initially +127)
// Output: A = best score (signed 8-bit)
//         If at root (SearchDepth == 0), sets BestMoveFrom/BestMoveTo
// Clobbers: Many registers and temps
//
// IMPORTANT: This function saves/restores state for recursion using
// the NegamaxState array indexed by depth, since the 6502 stack is limited.
//
Negamax:
  // Base case: depth == 0 -> evaluate
  cmp #$00
  bne !search+
  jsr Evaluate
  rts

!search:
  // Calculate state array offset = (SearchDepth) * 8
  // We'll store: move_count, best_score, move_index, from, to, depth, alpha, beta
  pha                   // Save depth on stack temporarily
  lda SearchDepth
  asl                   // *2
  asl                   // *4
  asl                   // *8
  tax                   // X = offset into NegamaxState
  pla                   // Get depth back
  sta NegamaxState + 5, x   // [offset+5] = depth remaining (survives recursion)

  // Store alpha/beta for this depth (read from entry parameters at $e8/$e9)
  lda $e8
  sta NegamaxState + 6, x   // [offset+6] = alpha
  lda $e9
  sta NegamaxState + 7, x   // [offset+7] = beta

  // Generate legal moves for current side
  jsr GenerateLegalMoves

  // Recalculate state offset (GenerateLegalMoves clobbered X)
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Save move count at this depth
  lda MoveCount
  sta NegamaxState, x   // [offset+0] = move count

  // Check for no legal moves
  cmp #$00
  bne !have_moves+

  // No moves - checkmate or stalemate?
  lda SearchSide
  bne !check_white_king_mate+
  lda blackkingsq
  jmp !check_if_in_check+
!check_white_king_mate:
  lda whitekingsq

!check_if_in_check:
  sta attack_sq

  lda SearchSide
  beq !white_attacks_mate+
  lda #BLACKS_TURN
  jmp !do_check_mate+
!white_attacks_mate:
  lda #WHITES_TURN
!do_check_mate:
  sta attack_color
  jsr IsSquareAttacked

  bcc !stalemate+
  lda #<-MATE_SCORE
  rts

!stalemate:
  lda #DRAW_SCORE
  rts

!have_moves:
  // Recalculate state offset (clobbered by IsSquareAttacked path)
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Initialize best score to -infinity
  lda #NEG_INFINITY
  sta NegamaxState + 1, x   // [offset+1] = best score

  // Initialize move index to 0
  lda #$00
  sta NegamaxState + 2, x   // [offset+2] = move index

!move_loop:
  // Recalculate state offset
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Check if done with all moves
  lda NegamaxState + 2, x   // move index
  cmp NegamaxState, x       // move count
  bne !continue_loop+
  jmp !search_done+

!continue_loop:
  // Get move from list
  lda NegamaxState + 2, x   // move index
  tay
  lda MoveListFrom, y
  sta NegamaxState + 3, x   // [offset+3] = from
  lda MoveListTo, y
  sta NegamaxState + 4, x   // [offset+4] = to

  // Make the move
  lda NegamaxState + 3, x
  ldy NegamaxState + 4, x
  sty $f0                   // temp for X parameter
  ldx $f0
  jsr MakeMove

  // Recurse: score = -Negamax(depth - 1, -beta, -alpha)
  // Recalculate state offset to get our depth
  lda SearchDepth
  sec
  sbc #$01                  // SearchDepth-1 gives us parent's depth index
  asl                       // *2
  asl                       // *4
  asl                       // *8
  tax

  // Set up alpha/beta for child: child_alpha = -beta, child_beta = -alpha
  lda NegamaxState + 7, x   // beta
  eor #$FF
  clc
  adc #$01                  // -beta
  sta $e8                   // child alpha = -beta

  lda NegamaxState + 6, x   // alpha
  eor #$FF
  clc
  adc #$01                  // -alpha
  sta $e9                   // child beta = -alpha

  lda NegamaxState + 5, x   // Load our saved depth
  sec
  sbc #$01                  // depth - 1
  jsr Negamax

  // Negate score: score = -score
  eor #$FF
  clc
  adc #$01
  sta $eb                   // Save negated score in temp

  // Recalculate state offset for PARENT (SearchDepth-1 because MakeMove incremented it)
  lda SearchDepth
  sec
  sbc #$01                  // Parent's depth index
  asl
  asl
  asl
  tax

  // Unmake the move (using parent's saved from/to)
  lda NegamaxState + 3, x   // from
  ldy NegamaxState + 4, x   // to
  sty $f0
  ldx $f0
  jsr UnmakeMove

  // Recalculate state offset again
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Compare: if score > best, update best
  // Signed comparison: score - best
  lda $eb                   // score
  sec
  sbc NegamaxState + 1, x   // score - best
  bvc !no_overflow+
  eor #$80                  // Flip sign bit for overflow case
!no_overflow:
  bmi !not_better+          // If negative, score <= best

  // Score is better - update best
  lda $eb
  sta NegamaxState + 1, x   // update best score

  // If at root (SearchDepth == 0), save best move
  lda SearchDepth
  bne !not_at_root+

  // At root - save best move
  lda NegamaxState + 3, x
  sta BestMoveFrom
  lda NegamaxState + 4, x
  sta BestMoveTo

!not_at_root:
  // Alpha-Beta: if best > alpha, update alpha
  // Recalculate state offset (may have been clobbered)
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Signed comparison: best > alpha?
  lda $eb                   // best (same as score that just improved)
  sec
  sbc NegamaxState + 6, x   // best - alpha
  bvc !no_overflow2+
  eor #$80
!no_overflow2:
  bmi !not_better+          // If negative, best <= alpha
  beq !not_better+          // If zero, best == alpha (not strictly greater)

  // Update alpha = best
  lda $eb
  sta NegamaxState + 6, x

  // Alpha-Beta cutoff: if alpha >= beta, prune
  // Signed comparison: alpha >= beta?
  lda NegamaxState + 6, x   // alpha
  sec
  sbc NegamaxState + 7, x   // alpha - beta
  bvc !no_overflow3+
  eor #$80
!no_overflow3:
  bmi !not_better+          // If negative, alpha < beta (no cutoff)
  jmp !search_done+         // Cutoff! Return immediately

!not_better:
  // Recalculate state offset
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Regenerate moves for this position (child search clobbered the list)
  jsr GenerateLegalMoves

  // Recalculate offset again (GenerateLegalMoves clobbers X)
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Next move
  inc NegamaxState + 2, x   // move index++
  jmp !move_loop-

!search_done:
  // Recalculate state offset
  lda SearchDepth
  asl
  asl
  asl
  tax

  // Return best score
  lda NegamaxState + 1, x
  rts

//
// Negamax state storage - 8 bytes per depth level
// [0] = move count at this depth
// [1] = best score at this depth
// [2] = current move index
// [3] = current move from
// [4] = current move to
// [5] = depth remaining
// [6] = alpha (lower bound)
// [7] = beta (upper bound)
//
NegamaxState:
  .fill MAX_DEPTH * 8, $00

//
// FindBestMove
// Main entry point for AI to find best move
// Uses iterative deepening: searches at depth 1, then 2, etc.
// Benefits: Always has a move ready, better move ordering in future
// Input: None (uses difficulty setting)
// Output: BestMoveFrom/BestMoveTo contain best move
//         A = best score from deepest search
//
FindBestMove:
  // Initialize search
  jsr InitSearch

  // Determine max depth from difficulty:
  // Easy = 2, Medium = 3, Hard = 4
  lda difficulty
  cmp #LEVEL_EASY
  bne !check_medium+
  lda #2
  jmp !start_iter+
!check_medium:
  cmp #LEVEL_MEDIUM
  bne !check_hard+
  lda #3
  jmp !start_iter+
!check_hard:
  lda #4

!start_iter:
  sta MaxSearchDepth        // Store target depth
  lda #1
  sta IterDepth             // Start at depth 1

!iter_loop:
  // Set up alpha/beta window for this iteration
  lda #NEG_INFINITY         // alpha = -128 (worst possible)
  sta $e8
  lda #$7F                  // beta = +127 (best possible)
  sta $e9

  // Run search at current depth
  lda IterDepth
  jsr Negamax
  sta IterScore             // Save score for potential use

  // Move to next depth
  inc IterDepth
  lda IterDepth
  cmp MaxSearchDepth
  bcc !iter_loop-           // If IterDepth < MaxSearchDepth, continue
  beq !iter_loop-           // If IterDepth = MaxSearchDepth, do one more

  // Return score from deepest search
  lda IterScore
  rts

// Iterative deepening state
IterDepth:
  .byte $00
MaxSearchDepth:
  .byte $00
IterScore:
  .byte $00
