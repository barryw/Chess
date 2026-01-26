// Screen Layout Definitions
// All ScreenPos structs defining where UI elements appear on screen

*=* "Layout"

// Struct for describing positions on a screen
.struct ScreenPos{x,y}

// The row where questions are asked
.const QUESTION_ROW = $0a

// The position of the first menu
.var Menu1Pos = ScreenPos($1a, $14)

// Positions for title and copyright
.var Title1Pos = ScreenPos($1c, $00)
.var Title2Pos = ScreenPos(Title1Pos.x, Title1Pos.y + $01)
.var CopyrightPos = ScreenPos($1a, Title2Pos.y + $01)
.var Title1CharPos = ScreenPos($1e, Title1Pos.y)
.var Title2CharPos = ScreenPos($1e, Title2Pos.y)

// Positions for main menu items
.var PlayGamePos = ScreenPos($1a, Menu1Pos.y + $01)
.var AboutPos = ScreenPos($1a, PlayGamePos.y + $01)
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

.var EmptyQuestionPos = ScreenPos($1a, QUESTION_ROW)
.var Empty1Pos = ScreenPos($1a, Menu1Pos.y)
.var Empty2Pos = ScreenPos($1a, Menu1Pos.y + $01)
.var Empty3Pos = ScreenPos($1a, Menu1Pos.y + $02)
.var Empty4Pos = ScreenPos($1a, Menu1Pos.y + $03)

.var BackMenuPos = ScreenPos($1a, $17)

.var ForfeitConfirmPos = ScreenPos($1c, QUESTION_ROW)
.var QuitConfirmPos = ScreenPos($1e, QUESTION_ROW)
.var PlayerSelectPos = ScreenPos($1b, QUESTION_ROW)
.var LevelSelectPos = ScreenPos($1b, QUESTION_ROW)
.var ColorSelectPos = ScreenPos($1a, QUESTION_ROW)

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
.var KingInCheckPos = ScreenPos($1a, $09)

.var CapturedCountStart = ScreenPos($26, CapturedPawnPos.y)

.var InteractionLinePos = ScreenPos($1a, $07)
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
