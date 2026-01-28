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
