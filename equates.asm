.label SPRPTR = $07f8

// The location in memory for our sprites
.label SPRITE_MEMORY = $2000

// The location in memory for our characters
.label CHARACTER_MEMORY = $3000

// These are markers for the board's state. Each piece has its own signature
// The MSB identifies the piece's color. A value of 1 means the piece is BLACK
.label EMPTY_PIECE  = %00000000
.label WHITE_PAWN   = %00000001
.label BLACK_PAWN   = %10000001
.label WHITE_KNIGHT = %00000010
.label BLACK_KNIGHT = %10000010
.label WHITE_BISHOP = %00000100
.label BLACK_BISHOP = %10000100
.label WHITE_ROOK   = %00001000
.label BLACK_ROOK   = %10001000
.label WHITE_KING   = %00010000
.label BLACK_KING   = %10010000
.label WHITE_QUEEN  = %00100000
.label BLACK_QUEEN  = %10100000

// Sprite pointers for the 6 pieces
.label EMPTY_SPR  = $80
.label PAWN_SPR   = $81
.label KNIGHT_SPR = $82
.label BISHOP_SPR = $83
.label ROOK_SPR   = $84
.label QUEEN_SPR  = $85
.label KING_SPR   = $86

.label CURRENT_PIECE = $08

.label RASTER_START = 39
.label PIECE_HEIGHT = 24
.label PIECE_WIDTH = PIECE_HEIGHT
.label NUM_ROWS = 8
.label NUM_COLS = NUM_ROWS

// Addresses used for memcopy operations
.label copy_from = $02
.label copy_to = $04
.label copy_size = $06
