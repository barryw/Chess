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
// Bit 0 identifies the piece's color. A value of 1 means the piece is WHITE
.label EMPTY_PIECE  = %00000000
.label WHITE_PAWN   = %00000011
.label BLACK_PAWN   = %00000010
.label WHITE_KNIGHT = %00000101
.label BLACK_KNIGHT = %00000100
.label WHITE_BISHOP = %00001001
.label BLACK_BISHOP = %00001000
.label WHITE_ROOK   = %00010001
.label BLACK_ROOK   = %00010000
.label WHITE_KING   = %00100001
.label BLACK_KING   = %00100000
.label WHITE_QUEEN  = %01000001
.label BLACK_QUEEN  = %01000000

// Sprite pointers for the 6 pieces
.const EMPTY_SPR  = $80
.const PAWN_SPR   = $81
.const KNIGHT_SPR = $82
.const BISHOP_SPR = $83
.const ROOK_SPR   = $84
.const QUEEN_SPR  = $85
.const KING_SPR   = $86

.label CURRENT_PIECE = $08

// Constants for raster interrupts
.const RASTER_START = $27
.const PIECE_HEIGHT = $18
.const PIECE_WIDTH  = PIECE_HEIGHT
.const NUM_ROWS     = $08
.const NUM_COLS     = NUM_ROWS

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
