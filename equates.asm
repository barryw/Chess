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

// The speed of the title's color scroll. Higher is slower
.const TITLE_COLOR_SCROLL_SPEED = $08

// The speed that the spinner rotates. Higher is slower
.const THINKING_SPINNER_SPEED = $20

// The cursor flash speed
.const CURSOR_FLASH_SPEED = $10

// The speed to flash the selected piece at
.const PIECE_FLASH_SPEED = $10

// IRQ vector locations
.const NMI_VECTOR = $fffa
.const RESET_VECTOR = $fffc
.const IRQ_VECTOR = $fffe

// Struct for describing positions on a screen
.struct ScreenPos{x,y}

// The position of the first menu
.var Menu1Pos = ScreenPos($1a, $14)

// Positions for title and copyright
.var Title1Pos = ScreenPos($1c, $00)
.var Title2Pos = ScreenPos(Title1Pos.x, Title1Pos.y + $01)
.var CopyrightPos = ScreenPos($1a, Title2Pos.y + $01)

// Positions for main menu items
.var PlayGamePos = ScreenPos($1a, Menu1Pos.y)
.var MusicTogglePos = ScreenPos($1a, PlayGamePos.y + $01)
.var AboutPos = ScreenPos($1a, MusicTogglePos.y + $01)
.var QuitGamePos = ScreenPos($1a, AboutPos.y + $01)
.var AboutTextPos = ScreenPos($00, $06)

// Positions for quit menu items
.var YesPos = ScreenPos($1a, Menu1Pos.y + $01)
.var NoPos = ScreenPos($1a, Menu1Pos.y + $02)

// Positions for player select menu items
.var OnePlayerPos = ScreenPos($1a, Menu1Pos.y + $01)
.var TwoPlayerPos = ScreenPos($1a, Menu1Pos.y + $02)

// Positions for level select menu items
.var EasyPos = ScreenPos($1a, Menu1Pos.y)
.var MediumPos = ScreenPos($1a, Menu1Pos.y + $01)
.var HardPos = ScreenPos($1a, Menu1Pos.y + $02)

// Positions for color select menu items
.var BlackPos = ScreenPos($1a, Menu1Pos.y + $01)
.var WhitePos = ScreenPos($1a, Menu1Pos.y + $02)

// Positions for game menu items
.var ForfeitPos = ScreenPos($1a, $17)

.var EmptyQuestionPos = ScreenPos($1a, $0a)
.var Empty1Pos = ScreenPos($1a, Menu1Pos.y)
.var Empty2Pos = ScreenPos($1a, Menu1Pos.y + $01)
.var Empty3Pos = ScreenPos($1a, Menu1Pos.y + $02)
.var Empty4Pos = ScreenPos($1a, Menu1Pos.y + $03)

.var BackMenuPos = ScreenPos($1a, $17)

.var QuitConfirmPos = ScreenPos($1e, $0a)
.var PlayerSelectPos = ScreenPos($1b, $0a)
.var LevelSelectPos = ScreenPos($1b, $0a)
.var ColorSelectPos = ScreenPos($1a, $0a)

.var TurnPos = ScreenPos($1a, $04)
.var TimePos = ScreenPos($1a, $05)

.var TurnValuePos = ScreenPos($20, TurnPos.y)
.var TimeValuePos = ScreenPos($20, TimePos.y)
.var StatusSepPos = ScreenPos($1a, TimePos.y + $01)

.var PlayerNumberPos = ScreenPos($27, TurnValuePos.y)

// Positions for the play clock
.var SecondsPos = ScreenPos($26, $05)
.var MinutesPos = ScreenPos($23, SecondsPos.y)
.var HoursPos = ScreenPos($20, SecondsPos.y)
.var Colon1Pos = ScreenPos($22, SecondsPos.y)
.var Colon2Pos = ScreenPos($25, SecondsPos.y)

// Show how many pieces a player has captured
.var CapturedPos = ScreenPos($1d, $0c)
.var CapturedUnderlinePos = ScreenPos(CapturedPos.x, CapturedPos.y + $01)
.var CapturedPawnPos = ScreenPos($1a, CapturedPos.y + $02)
.var CapturedKnightPos = ScreenPos($1a, CapturedPos.y + $03)
.var CapturedBishopPos = ScreenPos($1a, CapturedPos.y + $04)
.var CapturedRookPos = ScreenPos($1a, CapturedPos.y + $05)
.var CapturedQueenPos = ScreenPos($1a, CapturedPos.y + $06)

.var CapturedCountStart = ScreenPos($26, CapturedPawnPos.y)

.var ThinkingPos = ScreenPos($1c, $07)
.var SpinnerPos = ScreenPos($25, ThinkingPos.y)
.var MovePos = ScreenPos($1a, ThinkingPos.y)
.var CursorPos = ScreenPos($26, ThinkingPos.y)

// The location to display movement errors
.var ErrorPos = ScreenPos($1a, ThinkingPos.y + $02)

// These are indexes into the storage area that tracks
// how many of each piece has been captured for white
// and black
.const CAP_PAWN   = $00
.const CAP_KNIGHT = $01
.const CAP_BISHOP = $02
.const CAP_ROOK   = $03
.const CAP_QUEEN  = $04

// Set the high bit on our pieces to make them white
.const BLACK_COLOR = %00000000
.const WHITE_COLOR = %10000000

/*
Sprite pointers for the 6 pieces + empty. The pointers must be < 128
so that we can store color information in the high bit.
*/
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

.const ONE_PLAYER   = $01
.const TWO_PLAYERS  = $02

// Constants for the coordinate selections
.const INPUT_MOVE_FROM = $00
.const INPUT_MOVE_TO   = $80

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

// Addresses used for memfill operations
.const fill_to    = $08
.const fill_size  = $0a
.const fill_value = $0c

// Addresses used for math operations
.const num1   = $0d
.const num2   = $0f
.const result = $11

// A 16 bit vector to the next location to print to
.const printvector = $13

// A 16 bit vector to the start of the location of
// storage that tracks captured pieces
.const capturedvector = $15

// Pointer to screen location of user input
.const inputlocationvector = $17

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
