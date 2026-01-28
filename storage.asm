*=* "Variable Storage"
/*

This file contains the storage locations of several variables. It's essentially
the state of the game.
*/

// Which chess board row are we working on right now?
counter:
  .byte $00

// The temp location of the current piece
currentpiece:
  .byte $00

// The temp location of the current key pressed
currentkey:
  .byte $00

// Store the lines where we want to trigger our raster interrupt
// Trigger 6 lines before sprite Y (was 4) to allow for inline sprite extraction
irqypos:
  .byte $2e, $46, $5e, $76, $8e, $a6, $be, $d6

// Store the lines where we should display our chess pieces
spriteypos:
  .byte $34, $4c, $64, $7c, $94, $ac, $c4, $dc

titlecolorsstart:
  .byte RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE
titlecolorsend:

// Whether to show the spinner
spinnerenabled:
  .byte $00

// The current spinner character being shown
spinnercurrent:
  .byte $00

spinnertiming:
  .byte THINKING_SPINNER_SPEED

colorcycletiming:
  .byte TITLE_COLOR_SCROLL_SPEED

colorcycleposition:
  .byte $00

// The difficulty level for the game when in 1player mode
difficulty:
  .byte $00

// Keep track of the current player. 0 = black, 1 = white
currentplayer:
  .byte WHITES_TURN

// Number of players
numplayers:
  .byte $00

// Which color is player 1? 0 = black, 1 = white
player1color:
  .byte $00

// Whether to play music or not. $80 = play, $00 = mute
playmusic:
  .byte $00

// Which menu is currently being displayed?
currentmenu:
  .byte $00

// This gets updated every screen refresh. It counts down and once
// it reaches 0, it will update the seconds value for the current
// player.
subseconds:
  .byte $3c

// Screen locations for each component of the timer
timerpositions:
  .word ScreenAddress(SecondsPos), ScreenAddress(MinutesPos), ScreenAddress(HoursPos)

// Whether or not the play clock is counting
playclockrunning:
  .byte ENABLE

// Countdown timer for flashing the cursor
cursorflashtimer:
  .byte CURSOR_FLASH_SPEED

timers:

// Keep track of the total time for white
// Stored as BCD
whiteseconds:
  .byte $00
whiteminutes:
  .byte $00
whitehours:
  .byte $00

// Keep track of the total time for black
// Stored as BCD
blackseconds:
  .byte $00
blackminutes:
  .byte $00
blackhours:
  .byte $00

// Keep track of the number of each pieces captured by white
whitecaptured:
  .fill $05, $00

// Keep track of the number of each pieces captured by black
blackcaptured:
  .fill $05, $00

// Placeholder memory for the portion of the screen that's obscured
// by the "About" window
screenbuffer:
  .fill $1e0, $00

colorbuffer:
  .fill $1e0, $00

// Whether to show the flashing cursor to wait for the movefrom/moveto coordinates
showcursor:
  .byte $00

// The x position for the cursor. Can only be 0 or 1
cursorxpos:
  .byte $00

// $00 = movefrom, $80 = moveto
inputselection:
  .byte $00

// $00 move is not valid, $80 move is valid
movefromisvalid:
  .byte $00

// $00 move is not valid, $80 move is valid
movetoisvalid:
  .byte $00

// The location of the piece the player wants to move
movefrom:
  .word $0000

// Stores the location where the player wants to move to
moveto:
  .word $0000

// Store the 0x88 offset in Board88 for the piece to move here
movefromindex:
  .byte BIT8

// Store the 0x88 offset in Board88 for the location to move to here
movetoindex:
  .byte BIT8

// This is a lookup table to translate row numbers into their
// inverse. This is needed due to the way Board88 is arranged.
// This could probably be done in code, but I'm lazy.
rowlookup:
  .byte $07, $06, $05, $04, $03, $02, $01, $00

processreturn:
  .byte $00

// If the player has selected a piece, this will hold the piece's
// color and sprite pointer. It will be flashed between this and
// the empty piece to give the appearance that the piece is flashing.
selectedpiece:
  .byte $00

// How quickly the selected piece should be flashed
pieceflashtimer:
  .byte PIECE_FLASH_SPEED

// A flag indicating whether a piece should be flashed
flashpiece:
  .byte $00

// A flag to indicate when a player's king is in check. Black is first.
incheckflags:
  .word $0000

pausetimer:
  .byte $00, $00, $00

//
// Auxiliary Game State for Move Validation
// These track derived state that's only updated on specific events
//

// 0x88 index of white king (starts at e1 = row 7 * 16 + col 4 = $74)
whitekingsq:
  .byte $74

// 0x88 index of black king (starts at e8 = row 0 * 16 + col 4 = $04)
blackkingsq:
  .byte $04

// Castling rights bitmap: bit 0=WK, 1=WQ, 2=BK, 3=BQ
// All set at game start ($0f)
castlerights:
  .byte $0f

// 0x88 index of en passant target square, $ff = none available
enpassantsq:
  .byte $ff

//
// Draw Detection State
//

// Halfmove clock for 50-move rule
// Reset on pawn move or capture, draw when reaches 100
HalfmoveClock:
  .byte $00

// Full move number (increments after Black's move)
FullmoveNumber:
  .word $0001

// Position history for threefold repetition detection
// Stores 16-bit Zobrist hashes for each position
.const MAX_HISTORY = 200
PositionHistoryLo:
  .fill MAX_HISTORY, $00
PositionHistoryHi:
  .fill MAX_HISTORY, $00
HistoryCount:
  .byte $00

//
// Direction Offset Tables for Move Validation
// These are 0x88 offsets (signed bytes)
//

// Orthogonal directions (rook, queen)
OrthogonalOffsets:
  .byte $f0, $10, $ff, $01    // N(-16), S(+16), W(-1), E(+1)
OrthogonalOffsetsEnd:

// Diagonal directions (bishop, queen)
DiagonalOffsets:
  .byte $ef, $f1, $0f, $11    // NW(-17), NE(-15), SW(+15), SE(+17)
DiagonalOffsetsEnd:

// All 8 directions (queen, king)
AllDirectionOffsets:
  .byte $ef, $f0, $f1, $ff, $01, $0f, $10, $11
AllDirectionOffsetsEnd:

// Knight move offsets
KnightOffsets:
  .byte $df, $e1, $ee, $f2, $0e, $12, $1f, $21
  // -33, -31, -18, -14, +14, +18, +31, +33
KnightOffsetsEnd:

// Pawn capture offsets (indexed by color: 0=black, 1=white)
// Black pawns capture SE(+17) and SW(+15)
// White pawns capture NE(-15) and NW(-17)
PawnCaptureOffsets:
  .byte $0f, $11    // Black: SW(+15), SE(+17)
  .byte $ef, $f1    // White: NW(-17), NE(-15)

//
// Promotion State
//

// Square where pawn is promoting ($ff = not promoting)
promotionsq:
  .byte $ff

// Selected promotion piece type
promotionpiece:
  .byte $00

//
// Piece Lists for Optimized Move Generation
// Each player has a list of up to 16 piece positions (0x88 indices)
// $FF = slot is empty (piece captured)
//
// Slot assignment (matches starting position):
//   0-7: Back rank pieces (R,N,B,Q,K,B,N,R)
//   8-15: Pawns
// This fixed mapping allows O(1) lookup when a specific piece is captured
//

// White piece positions (slots 0-15)
// Initial: $70,$71,$72,$73,$74,$75,$76,$77 (back rank a1-h1)
//          $60,$61,$62,$63,$64,$65,$66,$67 (pawns a2-h2)
WhitePieceList:
  .byte $70, $71, $72, $73, $74, $75, $76, $77  // Rook,Knight,Bishop,Queen,King,Bishop,Knight,Rook
  .byte $60, $61, $62, $63, $64, $65, $66, $67  // Pawns a2-h2

// Black piece positions (slots 0-15)
// Initial: $00,$01,$02,$03,$04,$05,$06,$07 (back rank a8-h8)
//          $10,$11,$12,$13,$14,$15,$16,$17 (pawns a7-h7)
BlackPieceList:
  .byte $00, $01, $02, $03, $04, $05, $06, $07  // Rook,Knight,Bishop,Queen,King,Bishop,Knight,Rook
  .byte $10, $11, $12, $13, $14, $15, $16, $17  // Pawns a7-h7

// Active piece counts (for quick iteration bounds)
WhitePieceCount:
  .byte 16
BlackPieceCount:
  .byte 16

// Temp storage for piece list operations
piecelist_idx:
  .byte $00

//
// Timer Library Storage
// 8 timers × 8 bytes each = 64 bytes
// Structure per timer:
//   +0: enabled (0=disabled, 1=enabled)
//   +1: mode (0=single-shot, 1=continuous)
//   +2,+3: current countdown value (16-bit)
//   +4,+5: reload frequency (16-bit, 60=1 second)
//   +6,+7: callback address (16-bit)
//
c64lib_timers:
  .fill TIMER_STRUCT_BYTES, $00
