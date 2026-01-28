#importonce

// Pseudo-Legal Move Generator
// Generates all moves that follow piece movement rules
// Legality (king in check) verified separately

*=* "AI MoveGen"

//
// Move List Storage
// Maximum ~218 moves in any chess position (theoretical max)
// Using 2 bytes per move: from (0x88) + to (0x88)
// 128 moves = 256 bytes storage
//
.const MAX_MOVES = 128

// Move count (number of moves in list)
MoveCount:
  .byte $00

// Move list: pairs of (from, to) squares
// Index by: MoveListFrom[i], MoveListTo[i]
MoveListFrom:
  .fill MAX_MOVES, $00

MoveListTo:
  .fill MAX_MOVES, $00

// MVV-LVA piece values for capture scoring
// Score = Victim * 8 - Attacker (approximates Victim * 10 - Attacker)
MVV_LVA_Values:
  .byte 0               // 0: empty
  .byte 10              // 1: pawn
  .byte 32              // 2: knight
  .byte 33              // 3: bishop
  .byte 50              // 4: rook
  .byte 90              // 5: queen
  .byte 0               // 6: king

// Score storage for MVV-LVA sorting (one per move)
MoveScores:
  .fill MAX_MOVES, $00

//
// Clear move list
// Resets count to zero
// Clobbers: A
//
ClearMoveList:
  lda #$00
  sta MoveCount
  rts

//
// Add move to list
// Input: A = from square (0x88 index)
//        X = to square (0x88 index)
// Clobbers: Y
// Note: Does not check for overflow (caller's responsibility)
//
AddMove:
  ldy MoveCount         // Y = current count (index for new move)
  sta MoveListFrom, y   // Store 'from' square
  txa                   // A = to square
  sta MoveListTo, y     // Store 'to' square
  inc MoveCount         // Increment count
  rts

//
// Get move from list
// Input: X = move index (0 to MoveCount-1)
// Output: A = from square, Y = to square
// Clobbers: none beyond return values
//
GetMove:
  lda MoveListFrom, x   // A = from square
  ldy MoveListTo, x     // Y = to square
  rts

//
// Generate knight moves from a square
// Input: A = from square (0x88 index)
//        X = side to move color ($80 = white, $00 = black)
// Clobbers: A, X, Y, $f7-$fa
//
GenerateKnightMoves:
  sta $f7               // $f7 = from square
  stx $f8               // $f8 = our color
  lda #$00
  sta $f9               // $f9 = offset index

!knight_loop:
  ldx $f9               // X = offset index
  lda $f7               // Start with from square
  clc
  adc KnightOffsets, x  // Add knight offset
  sta $fa               // $fa = target square

  // Check if target is on board
  and #OFFBOARD_MASK
  bne !knight_next+     // Off board, skip

  // Check what's on target square
  ldx $fa
  lda Board88, x

  // If empty, add move
  cmp #EMPTY_PIECE
  beq !add_knight_move+

  // Check if enemy piece (can capture)
  and #WHITE_COLOR      // Get piece color
  cmp $f8               // Compare with our color
  beq !knight_next+     // Same color = can't capture, skip

  // Enemy piece - can capture
!add_knight_move:
  lda $f7               // A = from
  ldx $fa               // X = to
  jsr AddMove

!knight_next:
  inc $f9               // Next offset
  lda $f9
  cmp #$08              // 8 knight offsets
  bne !knight_loop-

  rts

//
// Generate sliding moves in given directions
// Input: A = from square (0x88 index)
//        X = side to move color ($80 = white, $00 = black)
//        Y = number of directions
//        $fd/$fe = pointer to direction table (set before calling)
// Clobbers: A, X, Y, $f7-$fe
//
// This is a helper used by rook, bishop, queen generators
// Uses $fd/$fe as zero-page pointer for indirect indexed addressing
//

GenerateSlidingMoves:
  sta $f7               // $f7 = from square
  stx $f8               // $f8 = our color
  sty $fb               // $fb = number of directions
  lda #$00
  sta $f9               // $f9 = direction index

!direction_loop:
  // Get direction offset
  ldy $f9
  lda ($fd), y          // $fd/$fe = direction table pointer
  sta $fa               // $fa = direction offset

  // Start sliding from the from square (reset each direction)
  lda $f7
  sta $fc               // $fc = current square

!slide_loop:
  // Move one step in direction
  lda $fc
  clc
  adc $fa               // Add direction offset
  sta $fc               // $fc = new target square

  // Check if on board
  and #OFFBOARD_MASK
  bne !next_direction+  // Off board, try next direction

  // Check what's on target square
  ldx $fc
  lda Board88, x

  // If empty, add move and continue sliding
  cmp #EMPTY_PIECE
  beq !add_slide_move+

  // Not empty - check if enemy piece
  and #WHITE_COLOR      // Get piece color
  cmp $f8               // Compare with our color
  beq !next_direction+  // Same color = blocked, next direction

  // Enemy piece - add capture move, then stop
  lda $f7               // A = from
  ldx $fc               // X = to
  jsr AddMove
  jmp !next_direction+

!add_slide_move:
  lda $f7               // A = from
  ldx $fc               // X = to
  jsr AddMove
  jmp !slide_loop-      // Continue sliding

!next_direction:
  inc $f9               // Next direction
  lda $f9
  cmp $fb               // Done all directions?
  bne !direction_loop-

  rts

//
// Generate rook moves (orthogonal sliding)
// Input: A = from square, X = side color
// Clobbers: A, X, Y, $f7-$fe
//
GenerateRookMoves:
  pha                   // Save from square
  lda #<OrthogonalOffsets
  sta $fd               // Direction pointer low byte
  lda #>OrthogonalOffsets
  sta $fe               // Direction pointer high byte
  pla                   // Restore from square
  ldy #$04              // 4 orthogonal directions
  jmp GenerateSlidingMoves

//
// Generate bishop moves (diagonal sliding)
// Input: A = from square, X = side color
// Clobbers: A, X, Y, $f7-$fe
//
GenerateBishopMoves:
  pha                   // Save from square
  lda #<DiagonalOffsets
  sta $fd               // Direction pointer low byte
  lda #>DiagonalOffsets
  sta $fe               // Direction pointer high byte
  pla                   // Restore from square
  ldy #$04              // 4 diagonal directions
  jmp GenerateSlidingMoves

//
// Generate queen moves (all 8 directions sliding)
// Input: A = from square, X = side color
// Clobbers: A, X, Y, $f7-$fe
//
GenerateQueenMoves:
  pha                   // Save from square
  lda #<AllDirectionOffsets
  sta $fd               // Direction pointer low byte
  lda #>AllDirectionOffsets
  sta $fe               // Direction pointer high byte
  pla                   // Restore from square
  ldy #$08              // 8 directions
  jmp GenerateSlidingMoves

//
// Generate king moves (one square in any direction)
// Input: A = from square, X = side color
// Note: Does NOT check for moving into check - that's done at legality level
// Clobbers: A, X, Y, $f7-$fa
//
GenerateKingMoves:
  sta $f7               // $f7 = from square
  stx $f8               // $f8 = our color
  lda #$00
  sta $f9               // $f9 = direction index

!king_loop:
  ldx $f9               // X = direction index
  lda $f7               // Start with from square
  clc
  adc AllDirectionOffsets, x  // Add direction offset
  sta $fa               // $fa = target square

  // Check if target is on board
  and #OFFBOARD_MASK
  bne !king_next+       // Off board, skip

  // Check what's on target square
  ldx $fa
  lda Board88, x

  // If empty, add move
  cmp #EMPTY_PIECE
  beq !add_king_move+

  // Check if enemy piece (can capture)
  and #WHITE_COLOR      // Get piece color
  cmp $f8               // Compare with our color
  beq !king_next+       // Same color = can't capture, skip

  // Enemy piece - can capture
!add_king_move:
  lda $f7               // A = from
  ldx $fa               // X = to
  jsr AddMove

!king_next:
  inc $f9               // Next direction
  lda $f9
  cmp #$08              // 8 king directions
  bne !king_loop-

  // Fall through to castling generation
  jmp GenerateCastlingMoves

//
// Generate castling moves (called from GenerateKingMoves)
// Uses $f7 = king's current square, $f8 = our color
// Checks castling rights, empty squares between king and rook
// Note: Does NOT check if king passes through check (legal filter handles that)
//
GenerateCastlingMoves:
  lda $f8               // Our color
  bne !white_castle+

!black_castle:
  // Black castling - king must be on e8 ($04)
  lda $f7
  cmp #$04
  beq !black_king_ok+
  jmp !castle_done+
!black_king_ok:

  // Check black kingside (bit 2)
  lda castlerights
  and #%00000100
  beq !black_queenside+

  // Check f8 ($05) and g8 ($06) are empty
  lda Board88 + $05
  cmp #EMPTY_PIECE
  bne !black_queenside+
  lda Board88 + $06
  cmp #EMPTY_PIECE
  bne !black_queenside+

  // Add black kingside castle: e8 ($04) -> g8 ($06)
  lda #$04
  ldx #$06
  jsr AddMove

!black_queenside:
  // Check black queenside (bit 3)
  lda castlerights
  and #%00001000
  beq !castle_done+

  // Check b8 ($01), c8 ($02), d8 ($03) are empty
  lda Board88 + $01
  cmp #EMPTY_PIECE
  bne !castle_done+
  lda Board88 + $02
  cmp #EMPTY_PIECE
  bne !castle_done+
  lda Board88 + $03
  cmp #EMPTY_PIECE
  bne !castle_done+

  // Add black queenside castle: e8 ($04) -> c8 ($02)
  lda #$04
  ldx #$02
  jsr AddMove
  rts

!white_castle:
  // White castling - king must be on e1 ($74)
  lda $f7
  cmp #$74
  bne !castle_done+

  // Check white kingside (bit 0)
  lda castlerights
  and #%00000001
  beq !white_queenside+

  // Check f1 ($75) and g1 ($76) are empty
  lda Board88 + $75
  cmp #EMPTY_PIECE
  bne !white_queenside+
  lda Board88 + $76
  cmp #EMPTY_PIECE
  bne !white_queenside+

  // Add white kingside castle: e1 ($74) -> g1 ($76)
  lda #$74
  ldx #$76
  jsr AddMove

!white_queenside:
  // Check white queenside (bit 1)
  lda castlerights
  and #%00000010
  beq !castle_done+

  // Check b1 ($71), c1 ($72), d1 ($73) are empty
  lda Board88 + $71
  cmp #EMPTY_PIECE
  bne !castle_done+
  lda Board88 + $72
  cmp #EMPTY_PIECE
  bne !castle_done+
  lda Board88 + $73
  cmp #EMPTY_PIECE
  bne !castle_done+

  // Add white queenside castle: e1 ($74) -> c1 ($72)
  lda #$74
  ldx #$72
  jsr AddMove

!castle_done:
  rts

//
// Generate pawn moves
// Input: A = from square, X = side color ($80 = white, $00 = black)
// Note: Now handles en passant captures
// Clobbers: A, X, Y, $f7-$fb
//
.const WHITE_PAWN_PUSH = $f0    // -16 (north)
.const BLACK_PAWN_PUSH = $10    // +16 (south)
.const WHITE_START_ROW = $60    // Row 6 (rank 2)
.const BLACK_START_ROW = $10    // Row 1 (rank 7)
.const PROMO_FLAG_KNIGHT = $80  // Bit 7 set = Knight promotion (vs Queen)
.const WHITE_PROMO_ROW = $00    // Row 0 (rank 8) - white promotes here
.const BLACK_PROMO_ROW = $70    // Row 7 (rank 1) - black promotes here

GeneratePawnMoves:
  sta $f7               // $f7 = from square
  stx $f8               // $f8 = our color

  // Determine push direction based on color
  lda $f8
  bne !white_pawn+

  // Black pawn - pushes south
  lda #BLACK_PAWN_PUSH
  sta $f9               // $f9 = push direction
  lda #BLACK_START_ROW
  sta $fb               // $fb = start row base
  jmp !generate_pawn_pushes+

!white_pawn:
  // White pawn - pushes north
  lda #WHITE_PAWN_PUSH
  sta $f9               // $f9 = push direction
  lda #WHITE_START_ROW
  sta $fb               // $fb = start row base

!generate_pawn_pushes:
  // Single push
  lda $f7
  clc
  adc $f9               // Add push direction
  sta $fa               // $fa = target square

  // Check if on board
  and #OFFBOARD_MASK
  bne !pawn_captures+   // Off board, skip to captures

  // Check if empty (pawns can only push to empty squares)
  ldx $fa
  lda Board88, x
  cmp #EMPTY_PIECE
  bne !pawn_captures+   // Blocked, skip to captures

  // Add single push move - check for promotion first
  jsr AddPawnMoveWithPromotion

  // Check for double push (from start row)
  lda $f7
  and #$70              // Get row (high nibble)
  cmp $fb               // Compare with start row
  bne !pawn_captures+   // Not on start row, skip double push

  // Double push - add another step
  lda $fa               // Current target (after single push)
  clc
  adc $f9               // Add push direction again
  sta $fa               // $fa = double push target

  // Check if on board
  and #OFFBOARD_MASK
  bne !pawn_captures+   // Off board

  // Check if empty
  ldx $fa
  lda Board88, x
  cmp #EMPTY_PIECE
  bne !pawn_captures+   // Blocked

  // Add double push move
  lda $f7               // A = from
  ldx $fa               // X = to
  jsr AddMove

!pawn_captures:
  // Generate capture moves
  // White captures: NW (-17=$ef), NE (-15=$f1)
  // Black captures: SW (+15=$0f), SE (+17=$11)
  // Use PawnCaptureOffsets table: [Black SW, Black SE, White NW, White NE]

  // Determine capture offset base
  lda $f8               // Our color
  beq !black_captures+
  lda #$02              // White offset index = 2
  jmp !capture_loop_start+
!black_captures:
  lda #$00              // Black offset index = 0

!capture_loop_start:
  sta $fb               // $fb = capture offset index

!capture_loop:
  ldx $fb
  lda PawnCaptureOffsets, x
  sta $fa               // $fa = capture direction

  lda $f7
  clc
  adc $fa               // Target capture square
  sta $fa

  // Check if on board
  and #OFFBOARD_MASK
  bne !next_capture+

  // Check if enemy piece or en passant square
  ldx $fa
  lda Board88, x
  cmp #EMPTY_PIECE
  bne !check_enemy+

  // Empty square - check if it's en passant target
  lda $fa
  cmp enpassantsq
  bne !next_capture+    // Not en passant square, skip
  jmp !add_capture+     // Is en passant - add the move

!check_enemy:
  // Check if enemy
  and #WHITE_COLOR
  cmp $f8
  beq !next_capture+    // Same color - can't capture own piece

!add_capture:
  // Enemy piece or en passant - add capture move with promotion check
  jsr AddPawnMoveWithPromotion

!next_capture:
  inc $fb               // Next capture direction
  lda $fb
  // Check if done (white: 2,3 -> done at 4; black: 0,1 -> done at 2)
  lda $f8
  bne !white_capture_check+
  lda $fb
  cmp #$02              // Black done after index 1
  bne !capture_loop-
  rts

!white_capture_check:
  lda $fb
  cmp #$04              // White done after index 3
  bne !capture_loop-
  rts

//
// AddPawnMoveWithPromotion - Add pawn move, generating both Q and N if promoting
// Uses $f7 = from square, $f8 = our color, $fa = to square
// Checks if to square is on promotion rank and adds both promotion variants
// Clobbers: A, X
//
AddPawnMoveWithPromotion:
  // Determine promotion row based on color
  lda $f8               // Our color
  bne !check_white_promo+

  // Black pawn - promotes on row 7 ($70)
  lda $fa               // to square
  and #$70              // Get row nibble
  cmp #BLACK_PROMO_ROW
  beq !is_promotion+
  jmp !normal_pawn_move+

!check_white_promo:
  // White pawn - promotes on row 0 ($00)
  lda $fa               // to square
  and #$70              // Get row nibble
  cmp #WHITE_PROMO_ROW
  bne !normal_pawn_move+

!is_promotion:
  // Add Queen promotion (to square as-is, bit 7 clear)
  lda $f7               // A = from
  ldx $fa               // X = to
  jsr AddMove

  // Add Knight promotion (to square with bit 7 set)
  lda $f7               // A = from
  lda $fa
  ora #PROMO_FLAG_KNIGHT
  tax                   // X = to | $80
  lda $f7               // A = from
  jsr AddMove
  rts

!normal_pawn_move:
  // Not a promotion - add regular move
  lda $f7               // A = from
  ldx $fa               // X = to
  jsr AddMove
  rts

//
// Generate all pseudo-legal moves for a side
// Input: X = side to move color ($80 = white, $00 = black)
// Output: Moves added to move list (call ClearMoveList first!)
// Clobbers: A, X, Y, $f0-$fe
//
GenerateAllMoves:
  stx $f0               // $f0 = side to move color

  // Loop through all 0x88 squares
  lda #$00
  sta $f1               // $f1 = current square index

!gen_loop:
  // Check if valid square (index & $88 == 0)
  lda $f1
  and #OFFBOARD_MASK
  bne !gen_next_square+

  // Get piece at this square
  ldx $f1
  lda Board88, x
  cmp #EMPTY_PIECE
  beq !gen_next_square+ // Empty square, skip

  // Check if piece belongs to side to move
  pha                   // Save piece value
  and #WHITE_COLOR      // Get piece color
  cmp $f0               // Compare with side to move
  bne !gen_skip_piece+  // Not our piece, skip

  // Our piece - determine type and generate moves
  pla                   // Restore piece value
  and #$07              // Get piece type (1-6)
  cmp #$01              // Pawn?
  beq !gen_pawn+
  cmp #$02              // Knight?
  beq !gen_knight+
  cmp #$03              // Bishop?
  beq !gen_bishop+
  cmp #$04              // Rook?
  beq !gen_rook+
  cmp #$05              // Queen?
  beq !gen_queen+
  cmp #$06              // King?
  beq !gen_king+
  jmp !gen_next_square+ // Unknown piece type

!gen_skip_piece:
  pla                   // Clean up stack
  jmp !gen_next_square+

!gen_pawn:
  lda $f1               // From square
  ldx $f0               // Side color
  jsr GeneratePawnMoves
  jmp !gen_next_square+

!gen_knight:
  lda $f1               // From square
  ldx $f0               // Side color
  jsr GenerateKnightMoves
  jmp !gen_next_square+

!gen_bishop:
  lda $f1               // From square
  ldx $f0               // Side color
  jsr GenerateBishopMoves
  jmp !gen_next_square+

!gen_rook:
  lda $f1               // From square
  ldx $f0               // Side color
  jsr GenerateRookMoves
  jmp !gen_next_square+

!gen_queen:
  lda $f1               // From square
  ldx $f0               // Side color
  jsr GenerateQueenMoves
  jmp !gen_next_square+

!gen_king:
  lda $f1               // From square
  ldx $f0               // Side color
  jsr GenerateKingMoves

!gen_next_square:
  inc $f1               // Next square
  lda $f1
  cmp #BOARD_SIZE       // Done all 128 bytes?
  bne !gen_loop-

  lda MoveCount         // Return move count in A
  rts

//
// OrderMoves - Partition captures to front of move list
// Captures are better moves to try first for alpha-beta pruning
//
// Input: MoveListFrom/MoveListTo populated, MoveCount set
//        X = enemy color ($00 = black pieces are enemy, $80 = white pieces are enemy)
// Output: Move list reordered with captures first
// Clobbers: A, X, Y, $ec-$ef
//
OrderMoves:
  stx $ec               // $ec = enemy color

  lda #$00
  sta $ed               // $ed = write pointer (where next capture goes)

  ldy #$00              // Y = read pointer

!order_loop:
  cpy MoveCount
  beq !order_done+      // Done all moves?

  // Check if move at Y is a capture (target has enemy piece)
  lda MoveListTo, y     // Get target square
  tax
  lda Board88, x        // Get piece on target
  cmp #EMPTY_PIECE
  beq !not_capture+     // Empty = not a capture

  // Check if it's an enemy piece
  and #WHITE_COLOR      // Get color bit
  cmp $ec               // Compare with enemy color
  bne !not_capture+     // Not enemy = not a capture

  // It's a capture - swap move at Y with move at $ed (write pointer)
  ldx $ed               // X = write pointer
  cpx $ed               // Compare indices (Y already loaded)
  // Actually need: cpy $ed
  sty $ef               // Save Y
  cpy $ed
  beq !just_advance+    // Same index, no need to swap

  // Swap MoveListFrom[Y] with MoveListFrom[$ed]
  lda MoveListFrom, y
  sta $ee               // temp = from[Y]
  lda MoveListFrom, x
  sta MoveListFrom, y   // from[Y] = from[X]
  lda $ee
  sta MoveListFrom, x   // from[X] = temp

  // Swap MoveListTo[Y] with MoveListTo[$ed]
  lda MoveListTo, y
  sta $ee               // temp = to[Y]
  lda MoveListTo, x
  sta MoveListTo, y     // to[Y] = to[X]
  lda $ee
  sta MoveListTo, x     // to[X] = temp

!just_advance:
  inc $ed               // Advance write pointer

!not_capture:
  iny                   // Next read position
  jmp !order_loop-

!order_done:
  rts

//
// OrderMovesMVVLVA - Sort captures by Most Valuable Victim - Least Valuable Attacker
// Captures sorted to front, ordered by MVV-LVA score descending
// Non-captures remain after captures in original order
//
// Input: MoveListFrom/MoveListTo populated, MoveCount set
// Output: Move list reordered with best captures first
// Clobbers: A, X, Y, $e0-$e7
//
OrderMovesMVVLVA:
  // First pass: score all captures, partition to front
  lda #$00
  sta $e0               // $e0 = write index (captures)
  sta $e1               // $e1 = read index

!score_loop:
  lda $e1
  cmp MoveCount
  beq !sort_captures+

  // Get target square
  ldx $e1
  lda MoveListTo, x
  and #$7f              // Clear promotion flag if present
  tay
  lda Board88, y        // Piece on target
  cmp #EMPTY_PIECE
  beq !not_capture_mvv+

  // It's a capture - calculate MVV-LVA score
  and #$07              // Victim type
  tay
  lda MVV_LVA_Values, y
  asl
  asl
  asl                   // Victim * 8 (approximates *10)
  sta $e2               // Victim score

  // Get attacker type
  ldx $e1
  lda MoveListFrom, x
  tay
  lda Board88, y
  and #$07              // Attacker type
  tay
  lda MVV_LVA_Values, y
  sta $e3               // Attacker value

  // Score = victim*8 - attacker
  lda $e2
  sec
  sbc $e3
  ldx $e1
  sta MoveScores, x     // Store score for this move

  // Swap capture to write position
  ldy $e0
  cpx $e0
  beq !same_pos_mvv+

  // Swap from[x] with from[y]
  lda MoveListFrom, x
  pha
  lda MoveListFrom, y
  sta MoveListFrom, x
  pla
  sta MoveListFrom, y

  // Swap to[x] with to[y]
  lda MoveListTo, x
  pha
  lda MoveListTo, y
  sta MoveListTo, x
  pla
  sta MoveListTo, y

  // Swap scores[x] with scores[y]
  lda MoveScores, x
  pha
  lda MoveScores, y
  sta MoveScores, x
  pla
  sta MoveScores, y

!same_pos_mvv:
  inc $e0               // Advance write pointer

!not_capture_mvv:
  inc $e1
  jmp !score_loop-

!sort_captures:
  // $e0 = number of captures
  // Now bubble sort captures by score (descending)
  lda $e0
  cmp #$02
  bcc !mvvlva_done+     // 0 or 1 captures, no sort needed

  sta $e4               // $e4 = capture count

!outer_sort:
  lda #$00
  sta $e5               // $e5 = swapped flag

  lda #$00
  sta $e1               // $e1 = index

!inner_sort:
  lda $e1
  clc
  adc #$01
  cmp $e4
  bcs !check_swapped+   // Done inner loop

  // Compare scores[i] with scores[i+1]
  ldx $e1
  lda MoveScores, x
  ldy $e1
  iny
  cmp MoveScores, y
  bcs !no_swap_mvv+     // scores[i] >= scores[i+1], no swap

  // Swap moves at i and i+1
  lda MoveListFrom, x
  pha
  lda MoveListFrom, y
  sta MoveListFrom, x
  pla
  sta MoveListFrom, y

  lda MoveListTo, x
  pha
  lda MoveListTo, y
  sta MoveListTo, x
  pla
  sta MoveListTo, y

  lda MoveScores, x
  pha
  lda MoveScores, y
  sta MoveScores, x
  pla
  sta MoveScores, y

  lda #$01
  sta $e5               // Set swapped flag

!no_swap_mvv:
  inc $e1
  jmp !inner_sort-

!check_swapped:
  lda $e5
  bne !outer_sort-      // If swapped, do another pass

!mvvlva_done:
  rts

//
// GenerateCaptures
// Generate only capture moves (for quiescence search)
// Input: X = side to move color ($80=white, $00=black)
// Output: Captures in move list, MoveCount set
// Clobbers: A, X, Y, $f0-$fe
//
GenerateCaptures:
  stx $f0               // Save side color

  // Generate all pseudo-legal moves
  jsr ClearMoveList
  ldx $f0
  jsr GenerateAllMoves

  // Filter to only captures
  lda #$00
  sta $e0               // $e0 = read index
  sta $e1               // $e1 = write index

!filter_caps_loop:
  lda $e0
  cmp MoveCount
  beq !filter_caps_done+

  // Check if target has enemy piece
  ldx $e0
  lda MoveListTo, x
  and #$7f              // Clear promotion flag
  tay
  lda Board88, y
  cmp #EMPTY_PIECE
  beq !skip_non_cap+

  // Check it's enemy (not our color)
  and #WHITE_COLOR
  eor $f0               // XOR with our color
  beq !skip_non_cap+    // Same color after XOR = not enemy

  // It's a capture - keep it
  ldy $e1
  cpx $e1
  beq !same_cap_pos+

  // Copy move to write position
  lda MoveListFrom, x
  sta MoveListFrom, y
  lda MoveListTo, x
  sta MoveListTo, y

!same_cap_pos:
  inc $e1

!skip_non_cap:
  inc $e0
  jmp !filter_caps_loop-

!filter_caps_done:
  lda $e1
  sta MoveCount
  rts
