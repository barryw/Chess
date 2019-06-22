#importonce

*=* "Board Storage"
/*

Keeps track of the complete state of the board throughout play. It starts in this initial configuration.

During the raster interrupts, the board is constantly redrawn using multiplexed sprites. This allows us
to show up to 32 sprites at once.

*/
BoardState:
  .byte BLACK_ROOK, BLACK_KNIGHT, BLACK_BISHOP, BLACK_QUEEN, BLACK_KING, BLACK_BISHOP, BLACK_KNIGHT, BLACK_ROOK
  .byte BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN, BLACK_PAWN
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE, EMPTY_PIECE
  .byte WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN, WHITE_PAWN
  .byte WHITE_ROOK, WHITE_KNIGHT, WHITE_BISHOP, WHITE_QUEEN, WHITE_KING, WHITE_BISHOP, WHITE_KNIGHT, WHITE_ROOK

/*
Matrix of sprite pointers to match the state above
*/
BoardSprites:
  .fill $40, $00

/*
Matrix of sprite colors to match the state above
*/
BoardColors:
  .fill $40, $00

// Shows the columns along the bottom of the board
Columns:
  .text "ABCDEFGH"

// This draws the checkerboard using 2 different shades of gray
// TODO: Render the board with code instead of using 1k of data
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

