*=* "String Storage"

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
CopyrightColorStart:
  .fill CopyrightEnd - CopyrightStart, $01
CopyrightColorEnd:

PlayStart:
  .text "[P] Play Game"
PlayEnd:
PlayColorStart:
  .fill PlayEnd - PlayStart, $01
PlayColorEnd:

YesStart:
  .text "[Y] Yes"
YesEnd:
YesColorStart:
  .fill YesEnd - YesStart, $01
YesColorEnd:

NoStart:
  .text "[N] No"
NoEnd:
NoColorStart:
  .fill NoEnd - NoStart, $01
NoColorEnd:

MuteStart:
  .text "[M] Stop Music"
MuteEnd:
MuteColorStart:
  .fill MuteEnd - MuteStart, $01
MuteColorEnd:

UnmuteStart:
  .text "[M] Play Music"
UnmuteEnd:
UnmuteColorStart:
  .fill UnmuteEnd - UnmuteStart, $01
UnmuteColorEnd:

ForfeitStart:
  .text "[Z] Forfeit"
ForfeitEnd:
ForfeitColorStart:
  .fill ForfeitEnd - ForfeitStart, $01
ForfeitColorEnd:

QuitStart:
  .text "[Q] Quit Game"
QuitEnd:
QuitColorStart:
  .fill QuitEnd - QuitStart, $01
QuitColorEnd:

QuitConfirmationStart:
  .text "Quit?"
QuitConfirmationEnd:
QuitConfirmationColorStart:
  .fill QuitConfirmationEnd - QuitConfirmationStart, $01
QuitConfirmationColorEnd:

EmptyRowStart:
  .fill $0e, $20
EmptyRowEnd:

WhiteStart:
  .text "WHITE"
WhiteEnd:
WhiteColorStart:
  .fill WhiteEnd - WhiteStart, $01
WhiteColorEnd:

BlackStart:
  .text "BLACK"
BlackEnd:
BlackColorStart:
  .fill BlackEnd - BlackStart, $01
BlackColorEnd:

PlayerSelectStart:
  .text "Player Count"
PlayerSelectEnd:
PlayerSelectColorStart:
  .fill PlayerSelectEnd - PlayerSelectStart, $01
PlayerSelectColorEnd:

OnePlayerStart:
  .text "[1] 1 Player"
OnePlayerEnd:
OnePlayerColorStart:
  .fill OnePlayerEnd - OnePlayerStart, $01
OnePlayerColorEnd:

TwoPlayerStart:
  .text "[2] 2 Players"
TwoPlayerEnd:
TwoPlayerColorStart:
  .fill TwoPlayerEnd - TwoPlayerStart, $01
TwoPlayerColorEnd:

WhiteOrBlackStart:

BlacksTurnStart:
  .text "Black's Turn"
BlacksTurnEnd:

WhitesTurnStart:
  .text "White's Turn"
WhitesTurnEnd:

InvalidMoveStart:
  .text "Invalid Move"
InvalidMoveEnd:
