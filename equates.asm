// The bank the VIC-II chip will be in
.const BANK = $00

// The start of physical RAM the VIC-II will see
.const VIC_START = (BANK * $4000)

// The starting sprite pointer
.const START_SPRITE_PTR = $30

// The location in memory for our sprites
.const SPRITE_MEMORY = VIC_START + (START_SPRITE_PTR * $40)

// The location in memory for our characters
.const CHARACTER_MEMORY = $3000

// The location of screen memory in whatever bank we're in
.const SCREEN_MEMORY = VIC_START + $0400

// The location of sprite pointer memory
.const SPRPTR = SCREEN_MEMORY + $03f8

// The location of color RAM is constant
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

// Positions for game menu items
.var RotatePos = ScreenPos($1a, $16)
.var ForfeitPos = ScreenPos($1a, $17)

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

.var TurnPos = ScreenPos($1a, $04)
.var TimePos = ScreenPos($1a, $05)

.var TurnValuePos = ScreenPos($20, $04)
.var TimeValuePos = ScreenPos($20, $05)

// Show how many pieces a player has captured
.var CapturedPos = ScreenPos($1c, $0c)
.var CapturedUnderlinePos = ScreenPos($1c, $0d)
.var CapturedPawnPos = ScreenPos($1a, $0e)
.var CapturedKnightPos = ScreenPos($1a, $0f)
.var CapturedBishopPos = ScreenPos($1a, $10)
.var CapturedRookPos = ScreenPos($1a, $11)
.var CapturedQueenPos = ScreenPos($1a, $12)

.var CapturedCountStart = ScreenPos($26, $0e)

// These are indexes into the storage area that tracks
// how many of each piece has been captured for white
// and black
.const CAP_PAWN   = $00
.const CAP_KNIGHT = $01
.const CAP_BISHOP = $02
.const CAP_ROOK   = $03
.const CAP_QUEEN  = $04

.const BLACK_COLOR = $00
.const WHITE_COLOR = $80

// Sprite pointers for the 6 pieces
.const EMPTY_SPR  = START_SPRITE_PTR
.const PAWN_SPR   = START_SPRITE_PTR + 1
.const KNIGHT_SPR = START_SPRITE_PTR + 2
.const BISHOP_SPR = START_SPRITE_PTR + 3
.const ROOK_SPR   = START_SPRITE_PTR + 4
.const QUEEN_SPR  = START_SPRITE_PTR + 5
.const KING_SPR   = START_SPRITE_PTR + 6

/*
Add color information using the high bit of the sprite pointer. These are the
values stored in BoardState
*/
.const EMPTY_PIECE  = EMPTY_SPR   + BLACK_COLOR
.const WHITE_PAWN   = PAWN_SPR    + WHITE_COLOR
.const BLACK_PAWN   = PAWN_SPR    + BLACK_COLOR
.const WHITE_KNIGHT = KNIGHT_SPR  + WHITE_COLOR
.const BLACK_KNIGHT = KNIGHT_SPR  + BLACK_COLOR
.const WHITE_BISHOP = BISHOP_SPR  + WHITE_COLOR
.const BLACK_BISHOP = BISHOP_SPR  + BLACK_COLOR
.const WHITE_ROOK   = ROOK_SPR    + WHITE_COLOR
.const BLACK_ROOK   = ROOK_SPR    + BLACK_COLOR
.const WHITE_KING   = KING_SPR    + WHITE_COLOR
.const BLACK_KING   = KING_SPR    + BLACK_COLOR
.const WHITE_QUEEN  = QUEEN_SPR   + WHITE_COLOR
.const BLACK_QUEEN  = QUEEN_SPR   + BLACK_COLOR

.label CURRENT_PIECE = $08

.const ONE_PLAYER = $01
.const TWO_PLAYERS = $02

// These indicate the current player
.const WHITES_TURN = $01
.const BLACKS_TURN = $00

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
.const copy_from  = $02
.const copy_to    = $04
.const copy_size  = $06

// Addresses used for math operations
.const num1   = $08
.const num2   = $0a
.const result = $0c

// A 16 bit vector to the next location to print to
.const printvector = $0e

// A 16 bit vector to the start of the location of
// storage that tracks captured pieces
.const capturedvector = $10

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
