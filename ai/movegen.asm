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

// Move generation routines will be added here in subsequent tasks
