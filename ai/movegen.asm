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

  rts

//
// Generate pawn moves
// Input: A = from square, X = side color ($80 = white, $00 = black)
// Note: Does NOT handle en passant or promotion flags
// Clobbers: A, X, Y, $f7-$fb
//
.const WHITE_PAWN_PUSH = $f0    // -16 (north)
.const BLACK_PAWN_PUSH = $10    // +16 (south)
.const WHITE_START_ROW = $60    // Row 6 (rank 2)
.const BLACK_START_ROW = $10    // Row 1 (rank 7)

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

  // Add single push move
  lda $f7               // A = from
  ldx $fa               // X = to
  jsr AddMove

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

  // Check if enemy piece (must be enemy to capture)
  ldx $fa
  lda Board88, x
  cmp #EMPTY_PIECE
  beq !next_capture+    // Empty - pawns can't move diagonally to empty

  // Check if enemy
  and #WHITE_COLOR
  cmp $f8
  beq !next_capture+    // Same color - can't capture own piece

  // Enemy piece - add capture move
  lda $f7               // A = from
  ldx $fa               // X = to
  jsr AddMove

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
