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

UnmuteStart:
  .text "[M] Play Music"
UnmuteEnd:
UnmuteColorStart:
  .fill UnmuteEnd - UnmuteStart, $01
UnmuteColorEnd:

MuteStart:
  .text "[M] Stop Music"
MuteEnd:
MuteColorStart:
  .fill MuteEnd - MuteStart, $01
MuteColorEnd:

AboutStart:
  .text "[A] About"
AboutEnd:
AboutColorStart:
  .fill AboutEnd - AboutStart, $01
AboutColorEnd:

QuitStart:
  .text "[Q] Quit Game"
QuitEnd:
QuitColorStart:
  .fill QuitEnd - QuitStart, $01
QuitColorEnd:

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

ForfeitStart:
  .text "[Z] Forfeit"
ForfeitEnd:
ForfeitColorStart:
  .fill ForfeitEnd - ForfeitStart, $01
ForfeitColorEnd:

QuitConfirmationStart:
  .text "Quit?"
QuitConfirmationEnd:
QuitConfirmationColorStart:
  .fill QuitConfirmationEnd - QuitConfirmationStart, $01
QuitConfirmationColorEnd:

PlayerSelectStart:
  .text "Player Count"
PlayerSelectEnd:
PlayerSelectColorStart:
  .fill PlayerSelectEnd - PlayerSelectStart, $01
PlayerSelectColorEnd:

LevelSelectStart:
  .text "Level Select"
LevelSelectEnd:
LevelSelectColorStart:
  .fill LevelSelectEnd - LevelSelectStart, $01
LevelSelectColorEnd:

Player1ColorStart:
  .text "Player 1 Color"
Player1ColorEnd:
P1ColorStart:
  .fill Player1ColorEnd - Player1ColorStart, $01
P1ColorEnd:

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

BackMenuStart:
  .text "[B] Back"
BackMenuEnd:
BackMenuColorStart:
  .fill BackMenuEnd - BackMenuStart, $01
BackMenuColorEnd:

LevelEasyStart:
  .text "[E] Easy"
LevelEasyEnd:
LevelEasyColorStart:
  .fill LevelEasyEnd - LevelEasyStart, $01
LevelEasyColorEnd:

LevelMediumStart:
  .text "[M] Medium"
LevelMediumEnd:
LevelMediumColorStart:
  .fill LevelMediumEnd - LevelMediumStart, $01
LevelMediumColorEnd:

LevelHardStart:
  .text "[H] Hard"
LevelHardEnd:
LevelHardColorStart:
  .fill LevelHardEnd - LevelHardStart, $01
LevelHardColorEnd:

BlackMenuStart:
  .text "[1] Black"
BlackMenuEnd:
BlackMenuColorStart:
  .fill BlackMenuEnd - BlackMenuStart, $01
BlackMenuColorEnd:

WhiteMenuStart:
  .text "[2] White"
WhiteMenuEnd:
WhiteMenuColorStart:
  .fill WhiteMenuEnd - WhiteMenuStart, $01
WhiteMenuColorEnd:

BlacksTurnStart:
  .text "Black's Turn"
BlacksTurnEnd:

WhitesTurnStart:
  .text "White's Turn"
WhitesTurnEnd:

InvalidMoveStart:
  .text "Invalid Move"
InvalidMoveEnd:

CheckStart:
  .text "Check!"
CheckEnd:

MateStart:
  .text "Mate!"
MateEnd:

AboutScreenStart:

AboutScreenEnd:
