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
.var CopyrightPos = ScreenPos($1a, $02) // x=26,y=2

// Positions for main menu items
.var PlayGamePos = ScreenPos($1a, $14) // x=26,y=20
.var MusicTogglePos = ScreenPos($1a, $15) // x=26,y=21
.var AboutPos = ScreenPos($1a, $16) // x=26,y=22
.var QuitGamePos = ScreenPos($1a, $17) // x=26,y=23
.var AboutTextPos = ScreenPos($00, $06) // x=0,y=6

// Positions for quit menu items
.var YesPos = ScreenPos($1a, $15)
.var NoPos = ScreenPos($1a, $16)

// Positions for player select menu items
.var OnePlayerPos = ScreenPos($1a, $15)
.var TwoPlayerPos = ScreenPos($1a, $16)

// Positions for level select menu items
.var EasyPos = ScreenPos($1a, $14)
.var MediumPos = ScreenPos($1a, $15)
.var HardPos = ScreenPos($1a, $16)

// Positions for color select menu items
.var BlackPos = ScreenPos($1a, $15)
.var WhitePos = ScreenPos($1a, $16)

.var EmptyQuestionPos = ScreenPos($1a, $0a)
.var Empty1Pos = ScreenPos($1a, $14)
.var Empty2Pos = ScreenPos($1a, $15)
.var Empty3Pos = ScreenPos($1a, $16)
.var Empty4Pos = ScreenPos($1a, $17)

.var BackMenuPos = ScreenPos($1a, $17)

.var QuitConfirmPos = ScreenPos($1e, $0a) // x=26,y=10
.var PlayerSelectPos = ScreenPos($1b, $0a) // x=26,y=10
.var LevelSelectPos = ScreenPos($1b, $0a) // x=26,y=10
.var ColorSelectPos = ScreenPos($1a, $0a) // x=26,y=10

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

.const ONE_PLAYER = $01
.const TWO_PLAYERS = $02

// Constants for raster interrupts
.const RASTER_START = $27
.const PIECE_HEIGHT = $18
.const PIECE_WIDTH  = PIECE_HEIGHT
.const NUM_ROWS     = $08
.const NUM_COLS     = NUM_ROWS

// Constants for difficulty levels
.const LEVEL_EASY   = $00
.const LEVEL_MEDIUM = $01
.const LEVEL_HARD   = $02

// Constants for the menus that can be displayed
.const MENU_GAME          = $00
.const MENU_MAIN          = $01
.const MENU_QUIT          = $02
.const MENU_PLAYER_SELECT = $03
.const MENU_COLOR_SELECT  = $04
.const MENU_LEVEL_SELECT  = $05
.const MENU_ABOUT_SHOWING = $06

// Addresses used for memcopy operations
.label copy_from  = $02
.label copy_to    = $04
.label copy_size  = $06

// Addresses used for math operations
.const num1   = $08
.const num2   = $0a
.const result = $0c

.const KEY_A = $01
.const KEY_B = $02
.const KEY_C = $03
.const KEY_D = $04
.const KEY_E = $05
.const KEY_F = $06
.const KEY_G = $07
.const KEY_H = $08
.const KEY_I = $09
.const KEY_J = $0a
.const KEY_K = $0b
.const KEY_L = $0c
.const KEY_M = $0d
.const KEY_N = $0e
.const KEY_O = $0f
.const KEY_P = $10
.const KEY_Q = $11
.const KEY_R = $12
.const KEY_S = $13
.const KEY_T = $14
.const KEY_U = $15
.const KEY_V = $16
.const KEY_W = $17
.const KEY_X = $18
.const KEY_Y = $19
.const KEY_Z = $1a

.const KEY_1 = $31
.const KEY_2 = $32
.const KEY_3 = $33
.const KEY_4 = $34
.const KEY_5 = $35
.const KEY_6 = $36
.const KEY_7 = $37
.const KEY_8 = $38
