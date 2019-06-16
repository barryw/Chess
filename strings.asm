*=* "String Storage"
TitleStart:
  .byte $dc
  .text "64 Chess"
TitleEnd:
TitleColorStart:
  .byte $02, $08, $07, $0d, $0e, $06, $04, $02, $08
TitleColorEnd:

CopyrightStart:
  .byte $dd, $de, $df, $e4, $e1, $db, $e2, $e3, $ea, $e5, $e6, $e7, $e8, $e9
CopyrightEnd:
CopyrightColorStart:
  .fill CopyrightEnd - CopyrightStart, $01
CopyrightColorEnd:

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

QuitStart:
  .text "[Q] Quit Game"
QuitEnd:
QuitColorStart:
  .fill QuitEnd - QuitStart, $01
QuitColorEnd:

QuitConfirmation:
  .text "Quit (Y/N)?"
  .byte $00

PlayerSelect:
  .text "1 or 2 players?"
  .byte $00

BlacksTurn:
  .text "Black's Turn"
  .byte $00

WhitesTurn:
  .text "White's Turn"
  .byte $00

InvalidMove:
  .text "Invalid Move"
  .byte $00
