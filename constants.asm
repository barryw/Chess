// Constants and Hardware Definitions
// Memory layout, piece definitions, game constants, zero page allocations

*=* "Constants"

//
// Memory Layout
//

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

//
// Memory Configuration ($01 Processor Port)
// Controls ROM/RAM banking for maximum memory utilization
//
// Bit 0 (LORAM):  Affects BASIC visibility (only when HIRAM=1)
// Bit 1 (HIRAM):  0 = RAM at $E000-$FFFF AND $A000-$BFFF, 1 = KERNAL ROM
// Bit 2 (CHAREN): 0 = CHAR ROM at $D000, 1 = I/O
// NOTE: When HIRAM=0, BOTH BASIC and KERNAL are banked out regardless of LORAM
//
.const MEMORY_CONFIG_DEFAULT = $37  // BASIC + KERNAL + I/O (stock C64)
.const MEMORY_CONFIG_NORMAL  = $34  // RAM + RAM + I/O (16KB extra!)
.const MEMORY_CONFIG_TURBO   = $30  // ALL RAM (20KB extra, NO I/O!)

//
// Extended Memory Regions (available with MEMORY_CONFIG_NORMAL)
//
.const BOOK_HASH_TABLE = $5600      // Opening book hash table start
.const BOOK_HASH_SIZE  = $4A00      // ~18.5KB for hash table ($5600-$9FFF)
.const SWAP_BUFFER     = $A000      // 8KB swap buffer for disk loading
.const SWAP_BUFFER_SIZE = $2000     // 8KB
// $C000-$CFFF reserved for Transposition Table (see ai/tt.asm)
.const BOOK_ENTRIES    = $E000      // 8KB for book entry data
.const BOOK_ENTRIES_SIZE = $2000    // 8KB
.const TURBO_WORKSPACE = $D000      // 4KB extra during turbo mode
.const TURBO_WORKSPACE_SIZE = $1000 // 4KB (only when I/O disabled!)

//
// Timing Constants
//

// The speed of the title's color scroll. Higher is slower
.const TITLE_COLOR_SCROLL_SPEED = $08

// The speed that the spinner rotates. Higher is slower
.const THINKING_SPINNER_SPEED = $1e

// The cursor flash speed
.const CURSOR_FLASH_SPEED = $10

// The speed to flash the selected piece at
.const PIECE_FLASH_SPEED = $10

//
// IRQ Vectors
//

.const NMI_VECTOR = $fffa
.const RESET_VECTOR = $fffc
.const IRQ_VECTOR = $fffe

//
// Piece Definitions
//

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
values stored in Board88
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

// Piece type constants (lower 7 bits, used for type checks)
// These equal piece_value & $7F - EMPTY_SPR
.const PAWN_TYPE   = $01
.const KNIGHT_TYPE = $02
.const BISHOP_TYPE = $03
.const ROOK_TYPE   = $04
.const QUEEN_TYPE  = $05
.const KING_TYPE   = $06

//
// Player and Game Constants
//

.const ONE_PLAYER   = $01
.const TWO_PLAYERS  = $02

// Constants for the coordinate selections
.const INPUT_MOVE_FROM = $00
.const INPUT_MOVE_TO   = $80

// index positions into the structure containing play
// clock information
.const WHITE_CLOCK_POS = $00
.const BLACK_CLOCK_POS = $03

// These indicate the current player
.const WHITES_TURN = $01
.const BLACKS_TURN = $00

//
// Raster Constants
//

.const RASTER_START = $27
.const PIECE_HEIGHT = $18
.const PIECE_WIDTH  = PIECE_HEIGHT
.const NUM_ROWS     = $08
.const NUM_COLS     = NUM_ROWS

//
// Difficulty Levels
//

.const LEVEL_EASY   = $00
.const LEVEL_MEDIUM = $01
.const LEVEL_HARD   = $02

// Time budgets in jiffies (1/60 second)
.const TIME_EASY   = 180      // 3 seconds
.const TIME_MEDIUM = 600      // 10 seconds
.const TIME_HARD   = 1500     // 25 seconds

//
// AI Search Constants
//

.const MATE_SCORE     = 120    // Score for checkmate (+120 = we win, -120 = we lose)
.const DRAW_SCORE     = 0      // Score for stalemate/draw
.const NEG_INFINITY   = $80    // -128 as signed byte (worst possible)
.const MAX_DEPTH      = 8      // Maximum search depth
.const MAX_KILLER_DEPTH = 16   // Maximum killer move storage depth

//
// Game State Constants (returned by CheckGameState)
//
.const GAME_NORMAL           = $00  // Not in check, has moves
.const GAME_CHECK            = $01  // In check, has moves
.const GAME_CHECKMATE        = $02  // In check, no moves
.const GAME_STALEMATE        = $03  // Not in check, no moves
.const GAME_DRAW_50_MOVE     = $04  // 50-move rule draw
.const GAME_DRAW_REPETITION  = $05  // Threefold repetition draw
.const GAME_DRAW_INSUFFICIENT = $06 // Insufficient material draw

//
// Menu Constants
//

.const MENU_GAME          = $00
.const MENU_MAIN          = $01
.const MENU_QUIT          = $02
.const MENU_PLAYER_SELECT = $03
.const MENU_COLOR_SELECT  = $04
.const MENU_LEVEL_SELECT  = $05
.const MENU_ABOUT_SHOWING = $06
.const MENU_FORFEIT       = $07
.const MENU_PROMOTION     = $08
.const MENU_GAME_OVER     = $09

//
// Enable/Disable and Bit Constants
//

// We enable by setting bit 8
.const ENABLE   = $80
.const DISABLE  = $00

// Bit 8
.const BIT8 = ENABLE

// Bit 7
.const BIT7 = $40

// Lower 7 bits
.const LOWER7 = $7f

//
// 0x88 Board Constants
//

// Board size in bytes (16 columns x 8 rows)
.const BOARD_SIZE = $80

// Off-board detection mask: (index & $88) != 0 means off-board
.const OFFBOARD_MASK = $88

// Row stride in 0x88 format
.const ROW_STRIDE = $10

// No en passant available
.const NO_EN_PASSANT = $ff

//
// Castling Rights Bitmap
//

.const CASTLE_WK = %00000001  // White kingside
.const CASTLE_WQ = %00000010  // White queenside
.const CASTLE_BK = %00000100  // Black kingside
.const CASTLE_BQ = %00001000  // Black queenside
.const CASTLE_ALL = %00001111 // All rights intact

//
// Zero Page Allocations ($02-$25, 36 bytes)
// Note: $00-$01 = CPU port, $50-$5f = keyboard routine
//

// Memory copy/fill operations
.const copy_from  = $02   // 2 bytes: source pointer
.const copy_to    = $04   // 2 bytes: destination pointer
.const copy_size  = $06   // 2 bytes: byte count
.const fill_to    = $08   // 2 bytes: destination pointer
.const fill_size  = $0a   // 2 bytes: byte count
.const fill_value = $0c   // 1 byte: fill value

// Math operations
.const num1   = $0d       // 2 bytes: operand 1
.const num2   = $0f       // 2 bytes: operand 2
.const result = $11       // 2 bytes: result

// Display pointers
.const printvector = $13          // 2 bytes: print output location
.const capturedvector = $15       // 2 bytes: captured pieces storage
.const inputlocationvector = $17  // 2 bytes: user input screen location
.const printclockvector = $19     // 2 bytes: clock display location

// General purpose temp storage
.const temp1 = $1b        // 2 bytes
.const temp2 = $1d        // 2 bytes

// String printing (PrintString/PrintAt)
.const str_ptr = $1f      // 2 bytes: pointer to null-terminated string
.const scr_ptr = $21      // 2 bytes: pointer to screen memory
.const col_ptr = $23      // 2 bytes: pointer to color memory
.const print_color = $25  // 1 byte: text color

// Move validation (IsSquareAttacked, piece validation)
.const attack_sq = $26    // 1 byte: square being checked for attack
.const attack_color = $27 // 1 byte: color attacking (0=black, 1=white)
.const move_delta = $28   // 1 byte: calculated move delta (signed)
.const ray_dir = $29      // 1 byte: current ray direction offset
.const ray_sq = $2a       // 1 byte: current square in ray traversal
.const piece_type = $2b   // 1 byte: piece type being validated

// AI Search temps (used by Negamax alpha-beta)
// Note: $e8-$ef are used by AI search functions (see below)
.const search_alpha = $2c // 1 byte: alpha bound for current call
.const search_beta = $2d  // 1 byte: beta bound for current call

// Timer library registers ($30-$37)
// Used by CreateTimer, UpdateTimers, EnDisTimer
.label r0  = $30
.label r0L = $30
.label r0H = $31
.label r1  = $32
.label r1L = $32
.label r1H = $33
.label r2  = $34
.label r2L = $34
.label r2H = $35
.label r3  = $36
.label r3L = $36
.label r3H = $37

//
// Timer Library Constants
//
.const MAX_TIMERS = 8
.const TIMER_STRUCT_SIZE = 8
.const TIMER_STRUCT_BYTES = MAX_TIMERS * TIMER_STRUCT_SIZE  // 64 bytes
.const TIMER_SINGLE_SHOT = 0
.const TIMER_CONTINUOUS = 1

// Timer IDs (for easy reference)
.const TIMER_FLASH_PIECE = 0
.const TIMER_FLASH_CURSOR = 1
.const TIMER_SPINNER = 2
.const TIMER_COLOR_CYCLE = 3

//
// Extended Zero Page Allocations ($e6-$fe)
// Used by AI search and move generation
//
// AI Search (Negamax and related):
// $e8 = negamax alpha parameter (passed to recursive calls)
// $e9 = negamax beta parameter (passed to recursive calls)
// $eb = current move score (negated child result)
//
// MakeMove/UnmakeMove:
// $f0-$f5 = temp storage for move processing
//
// Move Generation:
// $f7-$fa = temp storage for piece movement

//
// Pawn Direction Constants (for move validation)
//

.const PAWN_PUSH_WHITE = $f0      // -16 (north)
.const PAWN_PUSH_BLACK = $10      // +16 (south)
.const PAWN_START_RANK_WHITE = 6  // Row 6 in 0x88 (rank 2)
.const PAWN_START_RANK_BLACK = 1  // Row 1 in 0x88 (rank 7)
.const PAWN_PROMO_RANK_WHITE = 0  // Row 0 in 0x88 (rank 8)
.const PAWN_PROMO_RANK_BLACK = 7  // Row 7 in 0x88 (rank 1)

//
// Keyboard Constants
//

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
