/*
Check to see if the selected piece has any moves. We don't even want the player to
be able to select a piece if it can't move anywhere.

Carry Clear = no moves
Carry Set = 1 or more valid moves

Uses temp2+1 to save original movetoindex
*/
HasValidMoves:
  // Save original movetoindex
  lda movetoindex
  sta temp2 + 1

  // Get piece type
  ldx movefromindex
  lda Board88, x
  and #LOWER7           // Strip color

  cmp #PAWN_SPR
  bne !not_pawn+
  jmp HasValidMovesPawn
!not_pawn:
  cmp #KNIGHT_SPR
  bne !not_knight+
  jmp HasValidMovesKnight
!not_knight:
  cmp #BISHOP_SPR
  bne !not_bishop+
  jmp HasValidMovesBishop
!not_bishop:
  cmp #ROOK_SPR
  bne !not_rook+
  jmp HasValidMovesRook
!not_rook:
  cmp #QUEEN_SPR
  bne !not_queen+
  jmp HasValidMovesQueen
!not_queen:
  cmp #KING_SPR
  bne !not_king+
  jmp HasValidMovesKing
!not_king:

  // Unknown piece - no moves
  jmp HasValidMovesNone

/*
Check knight moves - 8 fixed offsets
*/
HasValidMovesKnight:
  ldx #$00
!knight_loop:
  stx ray_dir           // Save index
  lda movefromindex
  clc
  adc KnightOffsets, x
  // Check on-board
  tay
  and #OFFBOARD_MASK
  bne !knight_next+
  // Try this target
  sty movetoindex
  jsr TryMoveTarget
  bcc !knight_next+
  jmp HasValidMovesFound
!knight_next:
  ldx ray_dir
  inx
  cpx #KnightOffsetsEnd - KnightOffsets
  bne !knight_loop-
  jmp HasValidMovesNone

/*
Check king moves - 8 adjacent squares

OPTIMIZED: Instead of calling TryMoveTarget->ValidateMoveWithCheck for each
candidate square (which does make/unmake + full attack scan), we directly
check if the target square is attacked by the opponent.

Key insight: For king moves, checking "is target square attacked?" is
equivalent to "would king be in check after moving there?" - but much faster
because we skip the make/unmake cycle.

CRITICAL: We must temporarily remove the king from its current square before
checking attacks. Otherwise the king blocks its own attack rays (e.g., if
moving north and there's a rook 2 squares north, the king would appear to
block the rook's attack on the target square).

Performance: ~8x faster for kings with no legal moves (checkmate detection)
Old: 8 directions * (geometry + make + full attack scan + restore)
New: 8 directions * (on-board check + own-piece check + attack scan)
*/
HasValidMovesKing:
  // Save the king piece for restoration
  ldx movefromindex
  lda Board88, x
  sta temp1              // Save king piece

  // Temporarily remove king from board (critical for correct attack detection)
  lda #EMPTY_SPR
  sta Board88, x

  // Determine opponent's color for attack checks
  lda currentplayer
  eor #$01               // Flip: 0->1, 1->0
  sta attack_color       // Opponent attacks the squares we check

  ldx #$00               // Direction index
!king_loop:
  // Calculate target square
  lda movefromindex
  clc
  adc AllDirectionOffsets, x
  sta attack_sq          // Store target for IsSquareAttacked
  tay                    // Y = target square for later use

  // Check if target is on-board (0x88 trick)
  and #OFFBOARD_MASK
  bne !king_next+        // Off-board, try next direction

  // Check if target contains our own piece
  lda Board88, y
  cmp #EMPTY_SPR
  beq !check_attacked+   // Empty square - check if attacked

  // Not empty - check if it's our piece or enemy piece
  and #BIT8              // Get color bit
  sta piece_type         // Temp store color
  lda currentplayer
  beq !king_check_black+

  // Current player is white - our pieces have bit 7 set
  lda piece_type
  bne !king_next+        // Has bit 7 = white = our piece, skip
  jmp !check_attacked+   // No bit 7 = black = enemy, can capture

!king_check_black:
  // Current player is black - our pieces have bit 7 clear
  lda piece_type
  beq !king_next+        // No bit 7 = black = our piece, skip
  // Has bit 7 = white = enemy, can capture (fall through)

!check_attacked:
  // Target is either empty or contains enemy piece
  // Check if target square is attacked by opponent
  // NOTE: Save X on stack because IsSquareAttacked clobbers ray_dir
  txa
  pha
  jsr IsSquareAttacked
  pla
  tax
  bcs !king_next+        // Attacked! Not a valid move

  // Target is NOT attacked - this is a valid escape square!
  // Restore king to board before returning
  ldx movefromindex
  lda temp1
  sta Board88, x
  jmp HasValidMovesFound

!king_next:
  inx
  cpx #AllDirectionOffsetsEnd - AllDirectionOffsets
  bne !king_loop-

  // No valid moves found - restore king and return failure
  ldx movefromindex
  lda temp1
  sta Board88, x
  jmp HasValidMovesNone

/*
Check bishop moves - 4 diagonal rays
*/
HasValidMovesBishop:
  ldx #$00
!bishop_dir_loop:
  stx ray_dir
  lda DiagonalOffsets, x
  sta move_delta
  lda movefromindex
  sta ray_sq

!bishop_ray:
  lda ray_sq
  clc
  adc move_delta
  sta ray_sq
  tay
  and #OFFBOARD_MASK
  bne !bishop_next_dir+
  // Try this target
  sty movetoindex
  jsr TryMoveTarget
  bcc !bishop_continue+
  jmp HasValidMovesFound
!bishop_continue:
  // If blocked by a piece, stop this ray
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  bne !bishop_next_dir+
  // Continue ray
  jmp !bishop_ray-

!bishop_next_dir:
  ldx ray_dir
  inx
  cpx #DiagonalOffsetsEnd - DiagonalOffsets
  bne !bishop_dir_loop-
  jmp HasValidMovesNone

/*
Check rook moves - 4 orthogonal rays
*/
HasValidMovesRook:
  ldx #$00
!rook_dir_loop:
  stx ray_dir
  lda OrthogonalOffsets, x
  sta move_delta
  lda movefromindex
  sta ray_sq

!rook_ray:
  lda ray_sq
  clc
  adc move_delta
  sta ray_sq
  tay
  and #OFFBOARD_MASK
  bne !rook_next_dir+
  sty movetoindex
  jsr TryMoveTarget
  bcc !rook_continue+
  jmp HasValidMovesFound
!rook_continue:
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  bne !rook_next_dir+
  jmp !rook_ray-

!rook_next_dir:
  ldx ray_dir
  inx
  cpx #OrthogonalOffsetsEnd - OrthogonalOffsets
  bne !rook_dir_loop-
  jmp HasValidMovesNone

/*
Check queen moves - both diagonal and orthogonal rays
*/
HasValidMovesQueen:
  // Try diagonals first
  ldx #$00
!queen_diag_loop:
  stx ray_dir
  lda DiagonalOffsets, x
  sta move_delta
  lda movefromindex
  sta ray_sq

!queen_diag_ray:
  lda ray_sq
  clc
  adc move_delta
  sta ray_sq
  tay
  and #OFFBOARD_MASK
  bne !queen_diag_next+
  sty movetoindex
  jsr TryMoveTarget
  bcc !queen_diag_continue+
  jmp HasValidMovesFound
!queen_diag_continue:
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  bne !queen_diag_next+
  jmp !queen_diag_ray-

!queen_diag_next:
  ldx ray_dir
  inx
  cpx #DiagonalOffsetsEnd - DiagonalOffsets
  bne !queen_diag_loop-

  // Try orthogonals
  ldx #$00
!queen_ortho_loop:
  stx ray_dir
  lda OrthogonalOffsets, x
  sta move_delta
  lda movefromindex
  sta ray_sq

!queen_ortho_ray:
  lda ray_sq
  clc
  adc move_delta
  sta ray_sq
  tay
  and #OFFBOARD_MASK
  bne !queen_ortho_next+
  sty movetoindex
  jsr TryMoveTarget
  bcc !queen_ortho_continue+
  jmp HasValidMovesFound
!queen_ortho_continue:
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  bne !queen_ortho_next+
  jmp !queen_ortho_ray-

!queen_ortho_next:
  ldx ray_dir
  inx
  cpx #OrthogonalOffsetsEnd - OrthogonalOffsets
  bne !queen_ortho_loop-
  jmp HasValidMovesNone

/*
Check pawn moves - push and captures based on color
*/
HasValidMovesPawn:
  // Get pawn color
  ldx movefromindex
  lda Board88, x
  and #BIT8
  bne !white_pawn_moves+

  // Black pawn - try push south (+16) and captures (+15, +17)
  lda movefromindex
  clc
  adc #PAWN_PUSH_BLACK
  tay
  and #OFFBOARD_MASK
  bne !black_try_double+
  sty movetoindex
  jsr TryMoveTarget
  bcc !black_try_double+
  jmp HasValidMovesFound

!black_try_double:
  // Try double push from start rank
  lda movefromindex
  and #$f0
  cmp #$10              // Row 1?
  bne !black_try_captures+
  lda movefromindex
  clc
  adc #PAWN_PUSH_BLACK * 2
  tay
  and #OFFBOARD_MASK
  bne !black_try_captures+
  sty movetoindex
  jsr TryMoveTarget
  bcc !black_try_captures+
  jmp HasValidMovesFound

!black_try_captures:
  // Try SW capture (+15)
  lda movefromindex
  clc
  adc #$0f
  tay
  and #OFFBOARD_MASK
  bne !black_try_se+
  sty movetoindex
  jsr TryMoveTarget
  bcc !black_try_se+
  jmp HasValidMovesFound

!black_try_se:
  // Try SE capture (+17)
  lda movefromindex
  clc
  adc #$11
  tay
  and #OFFBOARD_MASK
  bne HasValidMovesNone
  sty movetoindex
  jsr TryMoveTarget
  bcc HasValidMovesNone
  jmp HasValidMovesFound

!white_pawn_moves:
  // White pawn - try push north (-16) and captures (-15, -17)
  lda movefromindex
  clc
  adc #PAWN_PUSH_WHITE  // -16
  tay
  and #OFFBOARD_MASK
  bne !white_try_double+
  sty movetoindex
  jsr TryMoveTarget
  bcc !white_try_double+
  jmp HasValidMovesFound

!white_try_double:
  // Try double push from start rank
  lda movefromindex
  and #$f0
  cmp #$60              // Row 6?
  bne !white_try_captures+
  lda movefromindex
  clc
  adc #$e0              // -32
  tay
  and #OFFBOARD_MASK
  bne !white_try_captures+
  sty movetoindex
  jsr TryMoveTarget
  bcc !white_try_captures+
  jmp HasValidMovesFound

!white_try_captures:
  // Try NW capture (-17 = $ef)
  lda movefromindex
  clc
  adc #$ef
  tay
  and #OFFBOARD_MASK
  bne !white_try_ne+
  sty movetoindex
  jsr TryMoveTarget
  bcc !white_try_ne+
  jmp HasValidMovesFound

!white_try_ne:
  // Try NE capture (-15 = $f1)
  lda movefromindex
  clc
  adc #$f1
  tay
  and #OFFBOARD_MASK
  bne HasValidMovesNone
  sty movetoindex
  jsr TryMoveTarget
  bcc HasValidMovesNone
  jmp HasValidMovesFound

HasValidMovesNone:
  // Restore original movetoindex and return no moves
  lda temp2 + 1
  sta movetoindex
  clc
  rts

HasValidMovesFound:
  // Restore original movetoindex and return has moves
  lda temp2 + 1
  sta movetoindex
  sec
  rts

/*
Helper: Try a move to the current movetoindex and check if valid.
Assumes movefromindex and movetoindex are set.
Returns: Carry set = valid move found
*/
TryMoveTarget:
  // First check if destination is valid (not our own piece)
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  beq !try_validate+    // Empty is OK
  // Check if it's an enemy piece
  and #BIT8             // Get color
  sta piece_type        // Temp store
  lda currentplayer
  beq !check_if_white+
  // Current player is white - target must be black (bit 7 clear)
  lda piece_type
  bne !own_piece+       // Has bit 7 = white = our piece
  jmp !try_validate+
!check_if_white:
  // Current player is black - target must be white (bit 7 set)
  lda piece_type
  beq !own_piece+       // No bit 7 = black = our piece
!try_validate:
  // Now try the full validation
  jsr ValidateMoveWithCheck
  rts
!own_piece:
  clc
  rts

/*
Check if the current player has any legal moves.
OPTIMIZED VERSION: Uses piece lists instead of scanning all 128 board squares.

Old method: Scan 128 squares, check 64 valid, filter to ~16 pieces = O(128)
New method: Iterate piece list directly = O(16) worst case, O(n) where n = remaining pieces

Performance gain: 4-8x faster depending on piece count.
Critical for checkmate/stalemate detection which runs after every move.

Returns:
  Carry set = has at least one legal move
  Carry clear = no legal moves (checkmate or stalemate)

Uses temp2 to save movefromindex, piecelist_idx for iteration
*/
PlayerHasAnyLegalMoves:
  // Save original movefromindex
  lda movefromindex
  sta temp2

  // Select the appropriate piece list based on current player
  lda currentplayer
  beq !scan_black_list+

  //
  // White player - iterate WhitePieceList
  //
  ldx #$00              // Piece list index
!white_loop:
  cpx WhitePieceCount   // Check if we've scanned all pieces
  beq !no_moves+        // No more pieces to check

  lda WhitePieceList, x // Get piece position (0x88 index)
  cmp #$ff              // Skip empty slots (shouldn't happen with count-based loop)
  beq !white_next+

  // This is a valid piece position - check if it has any legal moves
  sta movefromindex
  stx piecelist_idx     // Save list index
  jsr HasValidMoves
  ldx piecelist_idx     // Restore list index
  bcs !has_moves+       // Carry set = found a legal move!

!white_next:
  inx
  bne !white_loop-      // Always branches (we'll hit count limit first)
  beq !no_moves+        // Safety: wrapped around

  //
  // Black player - iterate BlackPieceList
  //
!scan_black_list:
  ldx #$00
!black_loop:
  cpx BlackPieceCount
  beq !no_moves+

  lda BlackPieceList, x
  cmp #$ff
  beq !black_next+

  sta movefromindex
  stx piecelist_idx
  jsr HasValidMoves
  ldx piecelist_idx
  bcs !has_moves+

!black_next:
  inx
  bne !black_loop-
  // Fall through to no_moves

!no_moves:
  // No legal moves found
  lda temp2
  sta movefromindex     // Restore original movefromindex
  clc
  rts

!has_moves:
  lda temp2
  sta movefromindex     // Restore original movefromindex
  sec
  rts

/*
Check the game state after a move.
Determines if the current player is in check, checkmate, or stalemate.

Returns:
  A = 0: Normal (not in check, has moves)
  A = 1: In check (but has legal moves)
  A = 2: Checkmate (in check, no legal moves)
  A = 3: Stalemate (not in check, no legal moves)
*/
CheckGameState:
  // First check if current player's king is in check
  jsr CheckKingInCheck
  php                   // Save check status

  // Check if player has any legal moves
  jsr PlayerHasAnyLegalMoves
  bcs !has_moves+

  // No legal moves - is it checkmate or stalemate?
  plp                   // Restore check status
  bcs !checkmate+

  // Not in check, no moves = stalemate
  lda #$03
  rts

!checkmate:
  // In check, no moves = checkmate
  lda #$02
  rts

!has_moves:
  // Has legal moves
  plp                   // Restore check status
  bcs !in_check+

  // Not in check, has moves = normal
  lda #$00
  rts

!in_check:
  // In check but has moves
  lda #$01
  rts

/*
Check to make sure the selected piece can move to the moveto location.
Dispatches to piece-specific validation routines.

Carry Clear = invalid move
Carry Set = valid move
*/
ValidateMove:
  // Get piece type from movefromindex
  ldx movefromindex
  lda Board88, x
  and #LOWER7           // Strip color to get piece type

  cmp #PAWN_SPR
  bne !not_pawn+
  jmp ValidatePawn
!not_pawn:
  cmp #KNIGHT_SPR
  bne !not_knight+
  jmp ValidateKnight
!not_knight:
  cmp #BISHOP_SPR
  bne !not_bishop+
  jmp ValidateBishop
!not_bishop:
  cmp #ROOK_SPR
  bne !not_rook+
  jmp ValidateRook
!not_rook:
  cmp #QUEEN_SPR
  bne !not_queen+
  jmp ValidateQueen
!not_queen:
  cmp #KING_SPR
  bne !not_king+
  jmp ValidateKing
!not_king:

  // Unknown piece type - invalid
  clc
  rts

/*
Validate knight move.
Knights move in an L-shape: 2 squares in one direction, 1 square perpendicular.
The 8 valid offsets are: -33, -31, -18, -14, +14, +18, +31, +33
*/
ValidateKnight:
  // Calculate delta = moveto - movefrom
  lda movetoindex
  sec
  sbc movefromindex
  sta move_delta

  // Check if delta matches one of the 8 knight offsets
  ldx #$00
!check_loop:
  lda move_delta
  cmp KnightOffsets, x
  beq !valid+
  inx
  cpx #KnightOffsetsEnd - KnightOffsets
  bne !check_loop-

  // No match - invalid move
  clc
  rts

!valid:
  sec
  rts

/*
Validate rook move.
Rooks move along ranks (rows) and files (columns) - orthogonal directions only.
*/
ValidateRook:
  jsr ValidateOrthogonal
  rts

/*
Validate bishop move.
Bishops move diagonally only.
*/
ValidateBishop:
  jsr ValidateDiagonal
  rts

/*
Validate queen move.
Queens can move orthogonally OR diagonally.
*/
ValidateQueen:
  // Try orthogonal first
  jsr ValidateOrthogonal
  bcs !valid+
  // If not orthogonal, try diagonal
  jsr ValidateDiagonal
!valid:
  rts

/*
Validate king move including castling.
Kings move one square in any direction, or castle (move 2 squares).
*/
ValidateKing:
  // Calculate delta = moveto - movefrom
  lda movetoindex
  sec
  sbc movefromindex
  sta move_delta

  // Check for castling attempt (delta = +2 kingside or -2 queenside)
  lda move_delta
  cmp #$02              // Kingside castling?
  bne !not_ks_castle+
  jmp ValidateCastleKingside
!not_ks_castle:
  cmp #$fe              // Queenside castling? (-2 in signed)
  bne !not_qs_castle+
  jmp ValidateCastleQueenside
!not_qs_castle:

  // Check if delta matches one of the 8 king offsets
  ldx #$00
!check_loop:
  lda move_delta
  cmp AllDirectionOffsets, x
  beq !valid+
  inx
  cpx #AllDirectionOffsetsEnd - AllDirectionOffsets
  bne !check_loop-

  // No match - invalid move
  clc
  rts

!valid:
  sec
  rts

/*
Validate kingside castling (O-O).
White: King e1→g1, Rook h1→f1
Black: King e8→g8, Rook h8→f8
*/
ValidateCastleKingside:
  // Check castling rights
  lda currentplayer
  beq !black_kingside+

  // White kingside castling
  lda castlerights
  and #CASTLE_WK
  beq !invalid+         // Right already lost

  // King must be on e1 ($74)
  lda movefromindex
  cmp #$74
  bne !invalid+

  // f1 and g1 must be empty
  lda Board88 + $75     // f1
  cmp #EMPTY_SPR
  bne !invalid+
  lda Board88 + $76     // g1
  cmp #EMPTY_SPR
  bne !invalid+

  // King must not be in check
  jsr CheckKingInCheck
  bcs !invalid+

  // f1 must not be attacked
  lda #$75
  sta attack_sq
  lda #BLACKS_TURN      // Attacked by black
  sta attack_color
  jsr IsSquareAttacked
  bcs !invalid+

  // g1 must not be attacked (landing square)
  lda #$76
  sta attack_sq
  jsr IsSquareAttacked
  bcs !invalid+

  sec
  rts

!black_kingside:
  // Black kingside castling
  lda castlerights
  and #CASTLE_BK
  beq !invalid+

  // King must be on e8 ($04)
  lda movefromindex
  cmp #$04
  bne !invalid+

  // f8 and g8 must be empty
  lda Board88 + $05     // f8
  cmp #EMPTY_SPR
  bne !invalid+
  lda Board88 + $06     // g8
  cmp #EMPTY_SPR
  bne !invalid+

  // King must not be in check
  jsr CheckKingInCheck
  bcs !invalid+

  // f8 must not be attacked
  lda #$05
  sta attack_sq
  lda #WHITES_TURN      // Attacked by white
  sta attack_color
  jsr IsSquareAttacked
  bcs !invalid+

  // g8 must not be attacked
  lda #$06
  sta attack_sq
  jsr IsSquareAttacked
  bcs !invalid+

  sec
  rts

!invalid:
  clc
  rts

/*
Validate queenside castling (O-O-O).
White: King e1→c1, Rook a1→d1
Black: King e8→c8, Rook a8→d8
*/
ValidateCastleQueenside:
  lda currentplayer
  beq !black_queenside+

  // White queenside castling
  lda castlerights
  and #CASTLE_WQ
  beq !qs_invalid+

  // King must be on e1 ($74)
  lda movefromindex
  cmp #$74
  bne !qs_invalid+

  // b1, c1, d1 must be empty
  lda Board88 + $71     // b1
  cmp #EMPTY_SPR
  bne !qs_invalid+
  lda Board88 + $72     // c1
  cmp #EMPTY_SPR
  bne !qs_invalid+
  lda Board88 + $73     // d1
  cmp #EMPTY_SPR
  bne !qs_invalid+

  // King must not be in check
  jsr CheckKingInCheck
  bcs !qs_invalid+

  // d1 must not be attacked
  lda #$73
  sta attack_sq
  lda #BLACKS_TURN
  sta attack_color
  jsr IsSquareAttacked
  bcs !qs_invalid+

  // c1 must not be attacked
  lda #$72
  sta attack_sq
  jsr IsSquareAttacked
  bcs !qs_invalid+

  sec
  rts

!black_queenside:
  // Black queenside castling
  lda castlerights
  and #CASTLE_BQ
  beq !qs_invalid+

  // King must be on e8 ($04)
  lda movefromindex
  cmp #$04
  bne !qs_invalid+

  // b8, c8, d8 must be empty
  lda Board88 + $01     // b8
  cmp #EMPTY_SPR
  bne !qs_invalid+
  lda Board88 + $02     // c8
  cmp #EMPTY_SPR
  bne !qs_invalid+
  lda Board88 + $03     // d8
  cmp #EMPTY_SPR
  bne !qs_invalid+

  // King must not be in check
  jsr CheckKingInCheck
  bcs !qs_invalid+

  // d8 must not be attacked
  lda #$03
  sta attack_sq
  lda #WHITES_TURN
  sta attack_color
  jsr IsSquareAttacked
  bcs !qs_invalid+

  // c8 must not be attacked
  lda #$02
  sta attack_sq
  jsr IsSquareAttacked
  bcs !qs_invalid+

  sec
  rts

!qs_invalid:
  clc
  rts

/*
Validate pawn move (without en passant for now).
Pawns move forward 1 square, or 2 from start rank.
Pawns capture diagonally.
*/
ValidatePawn:
  // Calculate delta = moveto - movefrom
  lda movetoindex
  sec
  sbc movefromindex
  sta move_delta

  // Get pawn's color to determine direction
  ldx movefromindex
  lda Board88, x
  and #BIT8             // Isolate color bit
  bne ValidateWhitePawn

  // Fall through to black pawn validation
ValidateBlackPawn:
  //
  // Black pawn - moves south (positive direction)
  //
  // Check for single push (delta = +16)
  lda move_delta
  cmp #PAWN_PUSH_BLACK
  bne !black_check_double+
  // Single push - destination must be empty
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  beq !black_valid+
  bne !black_invalid+   // Always branch (inverted logic)

!black_check_double:
  // Check for double push (delta = +32) from start rank
  lda move_delta
  cmp #PAWN_PUSH_BLACK * 2
  bne !black_check_capture+
  // Must be on start rank (row 1 in 0x88 = index $10-$17)
  lda movefromindex
  and #$f0              // Get row
  cmp #$10              // Row 1?
  bne !black_invalid+
  // Destination must be empty
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  bne !black_invalid+
  // Square in between must be empty (movefrom + 16)
  lda movefromindex
  clc
  adc #PAWN_PUSH_BLACK
  tax
  lda Board88, x
  cmp #EMPTY_SPR
  beq !black_valid+
  bne !black_invalid+   // Always branch

!black_check_capture:
  // Check diagonal captures (+15 or +17)
  lda move_delta
  cmp #$0f              // SW (+15)
  beq !black_capture+
  cmp #$11              // SE (+17)
  bne !black_invalid+
!black_capture:
  // Destination must have an enemy piece OR be en passant square
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  bne !black_valid+     // Has a piece - valid capture
  // Empty square - check if it's en passant
  lda movetoindex
  cmp enpassantsq
  beq !black_valid+     // En passant capture!
  bne !black_invalid+   // Empty and not en passant

!black_valid:
  sec
  rts
!black_invalid:
  clc
  rts

ValidateWhitePawn:
  //
  // White pawn - moves north (negative direction)
  //
  // Check for single push (delta = -16 = $f0)
  lda move_delta
  cmp #PAWN_PUSH_WHITE
  bne !white_check_double+
  // Single push - destination must be empty
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  beq !white_valid+
  bne !white_invalid+   // Always branch

!white_check_double:
  // Check for double push (delta = -32 = $e0) from start rank
  lda move_delta
  cmp #$e0              // PAWN_PUSH_WHITE * 2 = -32
  bne !white_check_capture+
  // Must be on start rank (row 6 in 0x88 = index $60-$67)
  lda movefromindex
  and #$f0              // Get row
  cmp #$60              // Row 6?
  bne !white_invalid+
  // Destination must be empty
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  bne !white_invalid+
  // Square in between must be empty (movefrom - 16)
  lda movefromindex
  clc
  adc #PAWN_PUSH_WHITE  // Add -16 (= subtract 16)
  tax
  lda Board88, x
  cmp #EMPTY_SPR
  beq !white_valid+
  bne !white_invalid+   // Always branch

!white_check_capture:
  // Check diagonal captures (-17 or -15)
  lda move_delta
  cmp #$ef              // NW (-17)
  beq !white_capture+
  cmp #$f1              // NE (-15)
  bne !white_invalid+
!white_capture:
  // Destination must have an enemy piece OR be en passant square
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  bne !white_valid+     // Has a piece - valid capture
  // Empty square - check if it's en passant
  lda movetoindex
  cmp enpassantsq
  beq !white_valid+     // En passant capture!
  bne !white_invalid+   // Empty and not en passant

!white_valid:
  sec
  rts
!white_invalid:
  clc
  rts

/*
Validate orthogonal movement (for rook and queen).
Check that the move is along a rank or file and path is clear.
*/
ValidateOrthogonal:
  // Calculate delta = moveto - movefrom
  lda movetoindex
  sec
  sbc movefromindex
  sta move_delta

  // Determine which orthogonal direction (if any)
  // N(-16): delta = $f0, $e0, $d0... (multiples of -16)
  // S(+16): delta = $10, $20, $30... (multiples of +16)
  // W(-1):  delta = $ff, $fe, $fd... (-1, -2, -3...)
  // E(+1):  delta = $01, $02, $03... (+1, +2, +3...)

  // Check for north/south movement (low nibble = 0)
  lda move_delta
  and #$0f
  bne !check_east_west+

  // It's N or S - determine direction
  lda move_delta
  and #$80              // Check sign
  bne !going_north+
  // Going south (positive)
  lda #$10
  jmp !validate_ray+
!going_north:
  lda #$f0
  jmp !validate_ray+

!check_east_west:
  // Check for east/west movement (high nibble = 0 or $f for wrapping)
  lda move_delta
  and #$f0
  beq !going_east+      // High nibble 0 = going east
  cmp #$f0
  beq !going_west+      // High nibble $f = going west

  // Not orthogonal
  clc
  rts

!going_east:
  lda #$01
  jmp !validate_ray+
!going_west:
  lda #$ff

!validate_ray:
  // A = direction offset, validate path is clear
  sta ray_dir
  lda movefromindex
  sta ray_sq

!ray_loop:
  lda ray_sq
  clc
  adc ray_dir
  sta ray_sq

  // Did we reach the destination?
  cmp movetoindex
  beq !path_clear+

  // Check if off-board (shouldn't happen for valid moves)
  and #OFFBOARD_MASK
  bne !blocked+

  // Is this square empty?
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  bne !blocked+

  // Continue along ray
  jmp !ray_loop-

!blocked:
  clc
  rts
!path_clear:
  sec
  rts

/*
Validate diagonal movement (for bishop and queen).
Check that the move is along a diagonal and path is clear.
*/
ValidateDiagonal:
  // Calculate delta = moveto - movefrom
  lda movetoindex
  sec
  sbc movefromindex
  sta move_delta

  // Determine which diagonal direction (if any)
  // NW(-17): $ef, $de, $cd... (multiples of -17)
  // NE(-15): $f1, $e2, $d3... (multiples of -15)
  // SW(+15): $0f, $1e, $2d... (multiples of +15)
  // SE(+17): $11, $22, $33... (multiples of +17)

  // For diagonals, check if delta is a multiple of a diagonal offset
  // by dividing and checking remainder

  // Try each diagonal direction
  ldx #$00
!try_direction:
  lda DiagonalOffsets, x
  sta ray_dir
  jsr CheckDiagonalMultiple
  bcs !found_direction+
  inx
  cpx #DiagonalOffsetsEnd - DiagonalOffsets
  bne !try_direction-

  // Not a diagonal move
  clc
  rts

!found_direction:
  // ray_dir has the direction, validate path is clear
  lda movefromindex
  sta ray_sq

!diag_ray_loop:
  lda ray_sq
  clc
  adc ray_dir
  sta ray_sq

  // Did we reach the destination?
  cmp movetoindex
  beq !diag_path_clear+

  // Check if off-board
  and #OFFBOARD_MASK
  bne !diag_blocked+

  // Is this square empty?
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  bne !diag_blocked+

  // Continue along ray
  jmp !diag_ray_loop-

!diag_blocked:
  clc
  rts
!diag_path_clear:
  sec
  rts

/*
Helper: Check if move_delta is a valid multiple of ray_dir (diagonal offset).
Walk from movefrom adding ray_dir until we reach moveto or go off-board.
Returns: Carry set if moveto is reachable via this direction
*/
CheckDiagonalMultiple:
  lda movefromindex
  sta ray_sq

!check_loop:
  lda ray_sq
  clc
  adc ray_dir
  sta ray_sq

  // Did we reach moveto?
  cmp movetoindex
  beq !is_multiple+

  // Off-board?
  and #OFFBOARD_MASK
  bne !not_multiple+

  // Keep going (limit to 7 iterations max for safety)
  jmp !check_loop-

!not_multiple:
  clc
  rts
!is_multiple:
  sec
  rts

/*
Validate that the selected movefrom location contains a piece of the correct color
*/
ValidateFrom:
  clf movefromisvalid
  ldx movefromindex     // Get the piece at the selected location
  chk_empty !emptysquare+
  chk_mine !notyours+   // My piece?

  jsr HasValidMoves     // Does this piece have valid moves?
  bcs !moveisvalid+
  jmp !novalidmoves+

!moveisvalid:
  jsr FlashPieceOn      // Start flashing the selected piece
  jsr DisplayMoveToPrompt
  sef movefromisvalid   // Set the 'movefromisvalid' flag

  jmp !exit+
!emptysquare:
  PrintAt(NoPieceText, ErrorPos, WHITE)
  jmp !clearinput+
!notyours:
  PrintAt(NotYourPieceText, ErrorPos, WHITE)
  jmp !clearinput+
!novalidmoves:
  PrintAt(NoMovesText, ErrorPos, WHITE)
!clearinput:
  jsr ResetInput
  stb #BIT8:movefromindex

!exit:
  rts

/*
Validate that the selected moveto location is valid for the piece selected
*/
ValidateTo:
  clf movetoisvalid     // Reset the valid move flag
  ldx movetoindex       // Is the destination an empty square?
  chk_empty !checkvalid+ // Empty square?
  chk_mine !checkvalid+  // My piece?
!alreadyyours:
  PrintAt(AlreadyYoursText, ErrorPos, WHITE)
  jsr ResetInput
  stb #BIT8:movetoindex
  jmp !exit+

!checkvalid:
  jsr ValidateMoveWithCheck  // Are we good? (includes check verification)
  bcs !isvalid+              // If the move is good, set the carry flag
  PrintAt(InvalidMoveText, ErrorPos, WHITE)
  jmp !exit+
!isvalid:
  sef movetoisvalid
!exit:
  rts

/*
Wrapper around ValidateMove that also verifies the move doesn't leave
the current player's king in check.

Carry Clear = invalid move (either geometrically or leaves king in check)
Carry Set = valid move
*/
ValidateMoveWithCheck:
  // First check if the move is geometrically valid
  jsr ValidateMove
  bcs !basic_valid+       // If basic validation passes, continue
  jmp !invalid+           // Otherwise exit immediately
!basic_valid:

  // Move is valid - now check if it leaves king in check
  // Save board state for the two affected squares
  ldx movefromindex
  lda Board88, x
  sta temp1               // Save piece being moved
  ldx movetoindex
  lda Board88, x
  sta temp1 + 1           // Save captured piece (or empty)

  // If moving the king, save old position
  lda temp1
  and #LOWER7
  cmp #KING_SPR
  bne !not_king_move+
  // Save king's current square
  lda currentplayer
  beq !save_black_king+
  lda whitekingsq
  sta temp2
  jmp !make_temp_move+
!save_black_king:
  lda blackkingsq
  sta temp2
  jmp !make_temp_move+
!not_king_move:
  lda #$ff                // Flag: not a king move
  sta temp2

!make_temp_move:
  // Make the move temporarily
  ldx movetoindex
  lda temp1               // The piece being moved
  sta Board88, x
  ldx movefromindex
  lda #EMPTY_SPR
  sta Board88, x

  // Update king position if this is a king move
  lda temp1
  and #LOWER7
  cmp #KING_SPR
  bne !check_for_check+
  lda currentplayer
  beq !update_black_king_temp+
  ldx movetoindex
  stx whitekingsq
  jmp !check_for_check+
!update_black_king_temp:
  ldx movetoindex
  stx blackkingsq

!check_for_check:
  // Check if our king is now in check
  jsr CheckKingInCheck
  php                     // Save carry (check result) on stack

  // Restore the board
  ldx movefromindex
  lda temp1               // Restore moving piece
  sta Board88, x
  ldx movetoindex
  lda temp1 + 1           // Restore captured piece (or empty)
  sta Board88, x

  // Restore king position if it was a king move
  lda temp2
  cmp #$ff
  beq !check_result+
  lda currentplayer
  beq !restore_black_king+
  lda temp2
  sta whitekingsq
  jmp !check_result+
!restore_black_king:
  lda temp2
  sta blackkingsq

!check_result:
  // Get the check result back
  plp
  bcs !in_check+          // Carry set = was in check = invalid

  // Not in check - move is valid
  sec
  rts

!in_check:
!invalid:
  clc
  rts

/*
After we've validated that this is a valid move, do the bit shuffling. If there's
a piece in moveto, capture it first and then move the piece.
*/
MovePiece:
  jsr FlashPieceOff     // Turn off the flashing of the selected piece

  // Update piece lists BEFORE modifying Board88
  // This handles both the moving piece and any captured piece
  jsr UpdatePieceListForMove

  ldx movetoindex
  chk_empty !movepiece+ // If there's no piece in moveto, just move our piece
  and #LOWER7           // Strip color information
  cmp #PAWN_SPR         // Capture a pawn?
  beq !capturepawn+
  cmp #KNIGHT_SPR       // A knight?
  beq !captureknight+
  cmp #BISHOP_SPR       // A bishop?
  beq !capturebishop+
  cmp #ROOK_SPR         // A rook?
  beq !capturerook+
  cmp #QUEEN_SPR        // A queen?
  beq !capturequeen+
  jmp !movepiece+

!capturepawn:
  ldx #CAP_PAWN
  jmp !capturepiece+
!captureknight:
  ldx #CAP_KNIGHT
  jmp !capturepiece+
!capturebishop:
  ldx #CAP_BISHOP
  jmp !capturepiece+
!capturerook:
  ldx #CAP_ROOK
  // Also check if captured rook was on corner square - affects castling rights
  lda movetoindex
  cmp #$70              // a1 - white queenside rook
  bne !not_a1_capture+
  lda castlerights
  and #~CASTLE_WQ
  sta castlerights
  jmp !capturepiece+
!not_a1_capture:
  cmp #$77              // h1 - white kingside rook
  bne !not_h1_capture+
  lda castlerights
  and #~CASTLE_WK
  sta castlerights
  jmp !capturepiece+
!not_h1_capture:
  cmp #$00              // a8 - black queenside rook
  bne !not_a8_capture+
  lda castlerights
  and #~CASTLE_BQ
  sta castlerights
  jmp !capturepiece+
!not_a8_capture:
  cmp #$07              // h8 - black kingside rook
  bne !capturepiece+
  lda castlerights
  and #~CASTLE_BK
  sta castlerights
  jmp !capturepiece+
!capturequeen:
  ldx #CAP_QUEEN
!capturepiece:
  jne currentplayer:#WHITES_TURN:!incrementblack+
  inc whitecaptured, x
  jmp !movepiece+
!incrementblack:
  inc blackcaptured, x
!movepiece:
  ldx movetoindex       // Move it to the moveto location
  stb selectedpiece:Board88, x
  ldx movefromindex     // Empty the movefrom location
  stb #EMPTY_SPR:Board88, x

  // Update king position if a king was moved
  lda selectedpiece
  and #LOWER7           // Strip color to get piece type
  cmp #KING_SPR         // Was it a king?
  beq !is_king_move+
  jmp !check_rook_move+
!is_king_move:

  // King moved - update position and handle castling
  ldx movetoindex       // Get destination square
  lda currentplayer
  beq !updateblackking+

  // White king moved
  stx whitekingsq
  // Lose both white castling rights
  lda castlerights
  and #~(CASTLE_WK | CASTLE_WQ)
  sta castlerights

  // Check if this was castling (king moved 2 squares)
  lda movetoindex
  sec
  sbc movefromindex
  cmp #$02              // Kingside?
  bne !check_white_qs+
  // White kingside castling - move rook h1→f1
  lda #$77              // h1 (from)
  ldx #$75              // f1 (to)
  jsr UpdateCastlingRook
  lda Board88 + $77     // h1 rook
  sta Board88 + $75     // f1
  lda #EMPTY_SPR
  sta Board88 + $77     // Clear h1
  jmp !notking+
!check_white_qs:
  cmp #$fe              // Queenside? (-2)
  beq !do_white_qs+
  jmp !notking+
!do_white_qs:
  // White queenside castling - move rook a1→d1
  lda #$70              // a1 (from)
  ldx #$73              // d1 (to)
  jsr UpdateCastlingRook
  lda Board88 + $70     // a1 rook
  sta Board88 + $73     // d1
  lda #EMPTY_SPR
  sta Board88 + $70     // Clear a1
  jmp !notking+

!updateblackking:
  stx blackkingsq
  // Lose both black castling rights
  lda castlerights
  and #~(CASTLE_BK | CASTLE_BQ)
  sta castlerights

  // Check if this was castling
  lda movetoindex
  sec
  sbc movefromindex
  cmp #$02              // Kingside?
  bne !check_black_qs+
  // Black kingside castling - move rook h8→f8
  lda #$07              // h8 (from)
  ldx #$05              // f8 (to)
  jsr UpdateCastlingRook
  lda Board88 + $07     // h8 rook
  sta Board88 + $05     // f8
  lda #EMPTY_SPR
  sta Board88 + $07     // Clear h8
  jmp !notking+
!check_black_qs:
  cmp #$fe              // Queenside?
  beq !do_black_qs+
  jmp !notking+
!do_black_qs:
  // Black queenside castling - move rook a8→d8
  lda #$00              // a8 (from)
  ldx #$03              // d8 (to)
  jsr UpdateCastlingRook
  lda Board88 + $00     // a8 rook
  sta Board88 + $03     // d8
  lda #EMPTY_SPR
  sta Board88 + $00     // Clear a8
  jmp !notking+

!check_rook_move:
  // Check if a rook moved (affects castling rights)
  cmp #ROOK_SPR
  beq !do_rook_check+
  jmp !notking+
!do_rook_check:

  // Rook moved - check which corner and update rights
  lda movefromindex
  cmp #$70              // a1?
  bne !check_h1+
  lda castlerights
  and #~CASTLE_WQ
  sta castlerights
  jmp !notking+
!check_h1:
  cmp #$77              // h1?
  bne !check_a8+
  lda castlerights
  and #~CASTLE_WK
  sta castlerights
  jmp !notking+
!check_a8:
  cmp #$00              // a8?
  bne !check_h8+
  lda castlerights
  and #~CASTLE_BQ
  sta castlerights
  jmp !notking+
!check_h8:
  cmp #$07              // h8?
  bne !notking+
  lda castlerights
  and #~CASTLE_BK
  sta castlerights

!notking:
  // Handle pawn special moves
  lda selectedpiece
  and #LOWER7
  cmp #PAWN_SPR
  beq !is_pawn_move+
  jmp !clear_ep+
!is_pawn_move:

  // This is a pawn move - check for en passant capture or double push
  // First check if this was an en passant capture
  lda movetoindex
  ldx enpassantsq
  cpx #NO_EN_PASSANT
  beq !check_double_push+
  cmp enpassantsq       // Did pawn land on en passant square?
  bne !check_double_push+

  // En passant capture! Remove the captured pawn
  // Captured pawn is on the same file as moveto, but on the row we came from
  lda currentplayer
  beq !remove_white_pawn+
  // Current player is white - captured black pawn is one row south (+16)
  lda movetoindex
  clc
  adc #$10              // One row south
  tax
  // Remove from piece list (A = captured pawn square)
  txa
  pha                   // Save square for Board88 update
  jsr RemovePawnEnPassant
  pla
  tax
  lda #EMPTY_SPR
  sta Board88, x
  // Count the capture
  ldx #CAP_PAWN
  inc whitecaptured, x
  jmp !check_double_push+
!remove_white_pawn:
  // Current player is black - captured white pawn is one row north (-16)
  lda movetoindex
  clc
  adc #$f0              // One row north (-16)
  tax
  // Remove from piece list (A = captured pawn square)
  txa
  pha                   // Save square for Board88 update
  jsr RemovePawnEnPassant
  pla
  tax
  lda #EMPTY_SPR
  sta Board88, x
  // Count the capture
  ldx #CAP_PAWN
  inc blackcaptured, x

!check_double_push:
  // First check for pawn promotion
  lda movetoindex
  and #$f0              // Get row
  beq !check_promotion+ // Row 0 = white promotion rank
  cmp #$70              // Row 7 = black promotion rank
  bne !no_promotion+

!check_promotion:
  // Pawn reached last rank - set promotion flag
  lda movetoindex
  sta promotionsq
  jmp !clear_ep+        // Clear en passant and exit

!no_promotion:
  // Check if pawn moved 2 squares (set en passant for opponent)
  lda movetoindex
  sec
  sbc movefromindex
  sta move_delta
  lda move_delta
  cmp #$20              // +32 (black pawn double push)
  beq !set_ep_black+
  cmp #$e0              // -32 (white pawn double push)
  beq !set_ep_white+
  jmp !clear_ep+

!set_ep_black:
  // Black pawn moved 2 squares - en passant square is the skipped square
  lda movefromindex
  clc
  adc #$10              // One row south (skipped square)
  sta enpassantsq
  jmp !exit+

!set_ep_white:
  // White pawn moved 2 squares
  lda movefromindex
  clc
  adc #$f0              // One row north (skipped square = -16)
  sta enpassantsq
  jmp !exit+

!clear_ep:
  // Clear en passant square (no double pawn push this move)
  stb #NO_EN_PASSANT:enpassantsq
!exit:
  rts

/*
Check to see if the current player's king is in check.
Returns: Carry set = in check, Carry clear = not in check
*/
CheckKingInCheck:
  // Get the current player's king square
  lda currentplayer
  beq !checkblack+
  lda whitekingsq
  jmp !docheck+
!checkblack:
  lda blackkingsq
!docheck:
  sta attack_sq
  // Attacking color is the opponent
  lda currentplayer
  eor #$01            // Flip: 0→1, 1→0
  sta attack_color
  jsr IsSquareAttacked
  rts

/*
Check if a square is under attack by a given color.
Uses "reverse ray casting" - look outward from target square for attackers.

Input:
  attack_sq    - 0x88 index of square to check
  attack_color - color of potential attackers (0=black, 1=white)

Output:
  Carry set   = square IS attacked
  Carry clear = square is NOT attacked

Clobbers: A, X, Y, ray_sq, ray_dir, piece_type
*/
IsSquareAttacked:

  //
  // 1. Check for knight attacks
  //
  ldx #$00
!knight_loop:
  lda attack_sq
  clc
  adc KnightOffsets, x
  tay                   // Y = target square
  // Check if off-board
  and #OFFBOARD_MASK
  bne !knight_next+     // Off-board, skip
  // Check what's on this square
  lda Board88, y
  cmp #EMPTY_SPR
  beq !knight_next+     // Empty, no attacker
  // Is it an enemy knight?
  pha                   // Save piece
  and #LOWER7           // Get piece type
  cmp #KNIGHT_SPR
  bne !knight_notmatch+
  // It's a knight - check if enemy color
  pla
  jsr CheckEnemyColor
  bcc !knight_next+     // Not enemy, continue
  jmp !attacked+        // Enemy knight = attacked!
!knight_notmatch:
  pla                   // Restore stack
!knight_next:
  inx
  cpx #KnightOffsetsEnd - KnightOffsets
  bne !knight_loop-

  //
  // 2. Check for king attacks (adjacent squares)
  //
  ldx #$00
!king_loop:
  lda attack_sq
  clc
  adc AllDirectionOffsets, x
  tay                   // Y = target square
  // Check if off-board
  and #OFFBOARD_MASK
  bne !king_next+
  // Check what's on this square
  lda Board88, y
  cmp #EMPTY_SPR
  beq !king_next+
  // Is it an enemy king?
  pha
  and #LOWER7
  cmp #KING_SPR
  bne !king_notmatch+
  pla
  jsr CheckEnemyColor
  bcc !king_next+       // Not enemy, continue
  jmp !attacked+        // Enemy king = attacked!
!king_notmatch:
  pla
!king_next:
  inx
  cpx #AllDirectionOffsetsEnd - AllDirectionOffsets
  bne !king_loop-

  //
  // 3. Check diagonal rays (bishop, queen, pawn on first step)
  //
  ldx #$00
!diag_loop:
  stx ray_dir           // Save direction index
  lda DiagonalOffsets, x
  sta move_delta        // Store direction offset
  lda attack_sq
  sta ray_sq            // Start from attack square
  ldy #$00              // Y = distance counter (0 = first step)

!diag_ray:
  lda ray_sq
  clc
  adc move_delta
  sta ray_sq
  // Check if off-board
  and #OFFBOARD_MASK
  bne !diag_next_dir+   // Hit edge, try next direction

  // Check what's on this square
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  beq !diag_continue+   // Empty, continue ray

  // Found a piece - is it enemy bishop or queen?
  pha
  and #LOWER7
  cmp #BISHOP_SPR
  beq !diag_check_enemy+
  cmp #QUEEN_SPR
  beq !diag_check_enemy+

  // Check for pawn on first step only
  cpy #$00              // First step?
  bne !diag_blocked+    // No, pawns only attack one square
  cmp #PAWN_SPR
  bne !diag_blocked+

  // It's a pawn - check if it can attack this direction
  // Using REVERSE ray casting: we look FROM target to find attackers
  // White pawns attack NW/NE, so from target we look SW/SE (indices 2,3)
  // Black pawns attack SW/SE, so from target we look NW/NE (indices 0,1)
  pla
  pha                   // Keep piece on stack
  jsr CheckEnemyColor
  bcc !diag_blocked+    // Not enemy, blocked
  // Check pawn direction matches attack color (reversed for ray casting)
  lda attack_color
  beq !check_black_pawn+
  // White attacking - look SW/SE (indices 2,3) to find white pawn
  lda ray_dir
  cmp #$02
  bcc !diag_blocked+    // Index < 2, wrong direction for white pawn
  pla
  jmp !attacked+
!check_black_pawn:
  // Black attacking - look NW/NE (indices 0,1) to find black pawn
  lda ray_dir
  cmp #$02
  bcs !diag_blocked+    // Index >= 2, wrong direction for black pawn
  pla
  jmp !attacked+

!diag_check_enemy:
  pla
  jsr CheckEnemyColor
  bcc !diag_next_dir+   // Blocked by friendly piece
  jmp !attacked+

!diag_blocked:
  pla                   // Clean stack
!diag_next_dir:
  ldx ray_dir
  inx
  cpx #DiagonalOffsetsEnd - DiagonalOffsets
  bne !diag_loop-
  jmp !check_ortho+

!diag_continue:
  iny                   // Increment distance
  jmp !diag_ray-

  //
  // 4. Check orthogonal rays (rook, queen)
  //
!check_ortho:
  ldx #$00
!ortho_loop:
  stx ray_dir
  lda OrthogonalOffsets, x
  sta move_delta
  lda attack_sq
  sta ray_sq

!ortho_ray:
  lda ray_sq
  clc
  adc move_delta
  sta ray_sq
  // Check if off-board
  and #OFFBOARD_MASK
  bne !ortho_next_dir+

  // Check what's on this square
  ldx ray_sq
  lda Board88, x
  cmp #EMPTY_SPR
  beq !ortho_ray-       // Empty, continue ray

  // Found a piece - is it enemy rook or queen?
  pha
  and #LOWER7
  cmp #ROOK_SPR
  beq !ortho_check_enemy+
  cmp #QUEEN_SPR
  beq !ortho_check_enemy+
  // Blocked by non-rook/queen
  pla
  jmp !ortho_next_dir+

!ortho_check_enemy:
  pla
  jsr CheckEnemyColor
  bcc !ortho_next_dir+  // Blocked by friendly piece
  jmp !attacked+

!ortho_next_dir:
  ldx ray_dir
  inx
  cpx #OrthogonalOffsetsEnd - OrthogonalOffsets
  bne !ortho_loop-

  //
  // No attackers found
  //
  clc
  rts

!attacked:
  sec
  rts

/*
Helper: Check if piece in A is enemy color.
Input: A = piece (with color bit), attack_color = attacking color
Output: Carry set if piece belongs to attack_color
*/
CheckEnemyColor:
  // Get piece color: bit 7 set = white, clear = black
  and #BIT8             // Isolate color bit
  beq !piece_is_black+
  // Piece is white
  lda attack_color
  cmp #WHITES_TURN      // Is white the attacker?
  beq !is_enemy+
  clc
  rts
!piece_is_black:
  lda attack_color
  cmp #BLACKS_TURN      // Is black the attacker?
  beq !is_enemy+
  clc
  rts
!is_enemy:
  sec
  rts
