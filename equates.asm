.label SPRPTR = $07f8

// The location in memory for our sprites
.label SPRITE_MEMORY = $2000

// The location in memory for our characters
.label CHARACTER_MEMORY = $3000

// The location of screen memory (bank 0)
.const SCREEN_MEMORY = $0400

.const COLOR_MEMORY = $d800

// The offset between color memory and screen memory (in bank 0)
.const COLOR_MEMORY_OFFSET = COLOR_MEMORY - SCREEN_MEMORY

// Struct for describing positions on a screen
.struct ScreenPos{x,y}

// Positions for title and copyright
.var Title1Pos = ScreenPos($1c, $00) // x=28, y=0
.var Title2Pos = ScreenPos($1c, $01) // x=28, y=1
.var CopyrightPos = ScreenPos($1a, $02) // x=26,y=1

// Positions for main menu items
.var PlayGamePos = ScreenPos($1a, $15) // x=26,y=21
.var MusicTogglePos = ScreenPos($1a, $16) // x=26,y=22
.var QuitGamePos = ScreenPos($1a, $17) // x=26,y=23

// Positions for quit menu items
.var YesPos = ScreenPos($1a, $15)
.var NoPos = ScreenPos($1a, $16)

// Positions for player select menu items
.var OnePlayerPos = ScreenPos($1a, $15)
.var TwoPlayerPos = ScreenPos($1a, $16)

.var Empty1Pos = ScreenPos($1a, $15)
.var Empty2Pos = ScreenPos($1a, $16)
.var Empty3Pos = ScreenPos($1a, $17)

.var QuitConfirmPos = ScreenPos($1e, $0a) // x=26,y=10
.var PlayerSelectPos = ScreenPos($1b, $0a) // x=26,y=10

.var WhiteTimerLabelPos = ScreenPos($1b, $03) // x=27,y=3
.var BlackTimerLabelPos = ScreenPos($22, $03) // x=34,y=3

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
.label PAWN_SPR   = $80
.label KNIGHT_SPR = $81
.label BISHOP_SPR = $82
.label ROOK_SPR   = $83
.label QUEEN_SPR  = $84
.label KING_SPR   = $85

.label CURRENT_PIECE = $08

.label RASTER_START = 39
.label PIECE_HEIGHT = 24
.label PIECE_WIDTH  = PIECE_HEIGHT
.label NUM_ROWS     = 8
.label NUM_COLS     = NUM_ROWS

// Constants for the menus that can be displayed
.const MENU_NONE          = $00
.const MENU_MAIN          = $01
.const MENU_QUIT          = $02
.const MENU_PLAYER_SELECT = $03
.const MENU_COLOR_SELECT  = $04

// Addresses used for memcopy operations
.label copy_from  = $02
.label copy_to    = $04
.label copy_size  = $06

// Addresses used for math operations
.const num1   = $08
.const num2   = $0a
.const result = $0c
