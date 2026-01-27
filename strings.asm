*=* "String Storage"

/*
This file stores all of the strings in the game.

Most strings are null-terminated for use with PrintAt/PrintString.
Special cases (multi-color, fills) use the old Start/End pattern.
*/

// === SPECIAL CASES: Keep old format (per-character colors or fills) ===

TitleRow1Start:
  .byte $eb, $ed, $fb, $fd, $20, $f9, $f3, $f5, $f7, $f7
TitleRow1End:

TitleRow1ColorStart:
  .byte LIGHT_BLUE, LIGHT_BLUE, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE, RED, ORANGE
TitleRow1ColorEnd:

TitleRow2Start:
  .byte $ec, $ee, $fc, $fe, $20, $fa, $f4, $f6, $f8, $f8
TitleRow2End:

TitleRow2ColorStart:
  .byte LIGHT_BLUE, RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE, RED, ORANGE
TitleRow2ColorEnd:

CopyrightStart:
  .byte $dd, $de, $df, $e4, $e1, $db, $e2, $e3, $ea, $e5, $e6, $e7, $e8, $e9
CopyrightEnd:

EmptyRowStart:
  .fill $0e, $20
EmptyRowEnd:

CapturedUnderlineStart:
  .fill $08, $77
CapturedUnderlineEnd:

AboutTextStart:
  .byte $e0, $e0, $e0, $e0, $70
  .fill $06, $40
  .text @"\$73About C64 Chess\$6b"
  .fill $07, $40
  .byte $6e, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "This is my attempt at a chess "
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "game for the C64,made possible"
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "by modern tools like CBM prg  "
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "Studio and KickAssembler.     "
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .fill $1e, $20
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "BIG thanks to my wife Kate for"
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "her love, support & sprites! "
  .byte $dc
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .fill $1e, $20
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "Feel free to share this game. "
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $1c
  .text "-Barry @ www.barrywalker.io   "
  .byte $1c, $e0, $e0, $e0, $e0
  .byte $e0, $e0, $e0, $e0, $6d
  .fill $1e, $40
  .byte $7d, $e0, $e0, $e0, $e0
AboutTextEnd:
AboutTextColorStart:
  .byte $0f, $0f, $0f, $0b
  .fill $08, $01
  .byte RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE
  .byte RED, ORANGE, YELLOW, LIGHT_GREEN, LIGHT_BLUE, BLUE, PURPLE
  .byte RED
  .fill $09, $01
  .word $0000, $0000
  .byte $0f, $0f, $0f, $0b
  .fill $20, $01
  .word $0000, $0000
  .byte $0f, $0f, $0f, $0b
  .fill $20, $01
  .word $0000, $0000
  .byte $0b, $0b, $0b, $0f
  .fill $20, $01
  .word $0000, $0000
  .byte $0b, $0b, $0b, $0f
  .fill $20, $01
  .word $0000, $0000
  .byte $0b, $0b, $0b, $0f
  .fill $20, $01
  .word $0000, $0000
  .byte $0f, $0f, $0f, $0b
  .fill $20, $01
  .word $0000, $0000
  .byte $0f, $0f, $0f, $0b
  .fill $20, $01
  .word $0000, $0000
  .byte $0f, $0f, $0f, $0b
  .fill $20, $01
  .word $0000, $0000
  .byte $0b, $0b, $0b, $0f
  .fill $20, $01
  .word $0000, $0000
  .byte $0b, $0b, $0b, $0f
  .fill $20, $01
  .word $0000, $0000
  .byte $0b, $0b, $0b, $0f
  .fill $20, $01
  .word $0000, $0000
AboutTextColorEnd:

// Display an indeterminate progress bar with some characters
spinnerstart:
  .byte $7c, $6c, $7b, $7e
spinnerend:

// === NULL-TERMINATED STRINGS for PrintAt ===

PlayText:
  .text "[P]lay Game"
  .byte $00

AboutMenuText:
  .text "[A]bout"
  .byte $00

QuitText:
  .text "[Q]uit Game"
  .byte $00

YesText:
  .text "[Y]es"
  .byte $00

NoText:
  .text "[N]o"
  .byte $00

ForfeitText:
  .text "[Z] Forfeit"
  .byte $00

QuitConfirmText:
  .text "Quit?"
  .byte $00

ForfeitConfirmText:
  .text "Forfeit?"
  .byte $00

PlayerSelectText:
  .text "Player Count"
  .byte $00

LevelSelectText:
  .text "Level Select"
  .byte $00

Player1ColorText:
  .text "Player 1 Color"
  .byte $00

PlayerText:
  .text "Player"
  .byte $00

ComputerText:
  .text "Computer"
  .byte $00

OnePlayerText:
  .text "[1] Player"
  .byte $00

TwoPlayerText:
  .text "[2] Players"
  .byte $00

ZeroPlayerText:
  .text "[0] Computer"
  .byte $00

BackMenuText:
  .text "[B] Back"
  .byte $00

LevelEasyText:
  .text "[E] Easy"
  .byte $00

LevelMediumText:
  .text "[M] Medium"
  .byte $00

LevelHardText:
  .text "[H] Hard"
  .byte $00

BlackMenuText:
  .text "[1] Black"
  .byte $00

WhiteMenuText:
  .text "[2] White"
  .byte $00

TurnText:
  .text "Turn :"
  .byte $00

TimeText:
  .text "Time :"
  .byte $00

ThinkingText:
  .text "Thinking"
  .byte $00

MoveFromText:
  .text "Move From :   "
  .byte $00

MoveToText:
  .text "Move To   :   "
  .byte $00

NoPieceText:
  .text "No piece there"
  .byte $00

NotYourPieceText:
  .text "Not your piece"
  .byte $00

AlreadyYoursText:
  .text "Already yours "
  .byte $00

InvalidMoveText:
  .text " Invalid Move "
  .byte $00

NoMovesText:
  .text "No Valid Moves"
  .byte $00

CheckText:
  .text "Check!"
  .byte $00

MateText:
  .text "Mate!"
  .byte $00

StalemateText:
  .text "Stalemate!"
  .byte $00

CapturedText:
  .text "Captured"
  .byte $00

CapturedPawnText:
  .text @"\$1e Pawns   X   "
  .byte $00

CapturedKnightText:
  .text @"\$25 Knights X   "
  .byte $00

CapturedBishopText:
  .text @"\$23 Bishops X   "
  .byte $00

CapturedRookText:
  .text @"\$1f Rooks   X   "
  .byte $00

CapturedQueenText:
  .text @"\$22 Queens  X   "
  .byte $00

KingInCheckText:
  .text "King in check"
  .byte $00

PromotionText:
  .text "Promote to:"
  .byte $00

PromoteQueenText:
  .text "(Q)ueen"
  .byte $00

PromoteRookText:
  .text "(R)ook"
  .byte $00

PromoteBishopText:
  .text "(B)ishop"
  .byte $00

PromoteKnightText:
  .text "K(N)ight"
  .byte $00

WhiteWinsText:
  .text "White Wins!"
  .byte $00

BlackWinsText:
  .text "Black Wins!"
  .byte $00

DrawText:
  .text "   Draw!   "
  .byte $00

GameOverText:
  .text "[M] Main Menu"
  .byte $00

