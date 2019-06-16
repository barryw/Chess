#importonce

// Keeps track of the complete state of the board throughout play. It starts in the initial configuration.
// During the raster interrupts, the board is constantly redrawn using multiplexed sprites. This allows us
// to show up to 32 sprites at once.
BoardState:
  .byte BLACK_ROOK, BLACK_KNIGHT, BLACK_BISHOP, BLACK_QUEEN, BLACK_KING, BLACK_BISHOP, BLACK_KNIGHT, BLACK_ROOK
  .byte BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN
  .byte WHITE_ROOK, WHITE_KNIGHT, WHITE_BISHOP, WHITE_QUEEN, WHITE_KING, WHITE_BISHOP, WHITE_KNIGHT, WHITE_ROOK

// Shows the columns along the bottom of the board
Columns:
  .text "ABCDEFGH"

// Shows the rows along the right side of the board
Rows:
  .text "87654321"

// This draws the checkerboard using 2 different shades of gray
Board:
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f
  .byte $0f,$0b,$0b,$0b,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  .byte $0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b,$0b,$0f,$0f,$0f,$0b,$0b
  .byte $0b,$0f,$0f,$0f,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  .byte $00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$01,$00,$00,$01
  .byte $00,$00,$01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

