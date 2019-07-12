*=* "String Storage"

/*
This file stores all of the strings in the game
*/

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

PlayStart:
  .text "[P] Play Game"
PlayEnd:

UnmuteStart:
  .text "[M] Play Music"
UnmuteEnd:

MuteStart:
  .text "[M] Stop Music"
MuteEnd:

AboutStart:
  .text "[A] About"
AboutEnd:

QuitStart:
  .text "[Q] Quit Game"
QuitEnd:

YesStart:
  .text "[Y] Yes"
YesEnd:

NoStart:
  .text "[N] No"
NoEnd:

ForfeitStart:
  .text "[Z] Forfeit"
ForfeitEnd:

QuitConfirmationStart:
  .text "Quit?"
QuitConfirmationEnd:

PlayerSelectStart:
  .text "Player Count"
PlayerSelectEnd:

LevelSelectStart:
  .text "Level Select"
LevelSelectEnd:

Player1ColorStart:
  .text "Player 1 Color"
Player1ColorEnd:

EmptyRowStart:
  .fill $0e, $20
EmptyRowEnd:

PlayerStart:
  .text "Player"
PlayerEnd:

ComputerStart:
  .text "Computer"
ComputerEnd:

OnePlayerStart:
  .text "[1] 1 Player"
OnePlayerEnd:

TwoPlayerStart:
  .text "[2] 2 Players"
TwoPlayerEnd:

BackMenuStart:
  .text "[B] Back"
BackMenuEnd:

LevelEasyStart:
  .text "[E] Easy"
LevelEasyEnd:

LevelMediumStart:
  .text "[M] Medium"
LevelMediumEnd:

LevelHardStart:
  .text "[H] Hard"
LevelHardEnd:

BlackMenuStart:
  .text "[1] Black"
BlackMenuEnd:

WhiteMenuStart:
  .text "[2] White"
WhiteMenuEnd:

TurnStart:
  .text "Turn :"
TurnEnd:

TimeStart:
  .text "Time :"
TimeEnd:

ThinkingStart:
  .text "Thinking"
ThinkingEnd:

MoveFromStart:
  .text "Move From :   "
MoveFromEnd:

MoveToStart:
  .text "Move To   :   "
MoveToEnd:

NoPieceStart:
  .text "No piece there"
NoPieceEnd:

NotYourPieceStart:
  .text "Not your piece"
NotYourPieceEnd:

AlreadyYoursStart:
  .text "Already yours"
AlreadyYoursEnd:

InvalidMoveStart:
  .text "Invalid Move"
InvalidMoveEnd:

CheckStart:
  .text "Check!"
CheckEnd:

MateStart:
  .text "Mate!"
MateEnd:

CapturedStart:
  .text "Captured"
CapturedEnd:
CapturedUnderlineStart:
  .fill CapturedEnd - CapturedStart, $77
CapturedUnderlineEnd:

CapturedPawnStart:
  .byte $1e
  .text " Pawns   X   "
CapturedPawnEnd:

CapturedKnightStart:
  .byte $25
  .text " Knights X   "
CapturedKnightEnd:

CapturedBishopStart:
  .byte $23
  .text " Bishops X   "
CapturedBishopEnd:

CapturedRookStart:
  .byte $1f
  .text " Rooks   X   "
CapturedRookEnd:

CapturedQueenStart:
  .byte $22
  .text " Queens  X   "
CapturedQueenEnd:

AboutTextStart:
  .byte $e0, $e0, $e0, $e0, $70
  .fill $06, $40
  .byte $73
  .text "About C64 Chess"
  .byte $6b
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
