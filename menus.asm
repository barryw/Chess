*=* "Menus"

/*
Display the menu that's shown while the game is being played
*/
ShowGameMenu:
  jsr ClearMenus

  SetMenu(MENU_GAME)

  jsr ShowStatus
  jsr UpdateCurrentPlayer
  jsr UpdateCaptureCounts
  jsr ShowCaptured
  jsr UpdateCaptureCounts
  jsr CheckKingInCheck
  jsr ShowKingInCheck

  PrintAt(ForfeitText, ForfeitPos, WHITE)

  rts

/*
Clear the menu options and any displayed questions

TODO: This could probably be simplified with routine to clear the right side of the screen
*/
ClearMenus:
  FillMemory(ColorAddress(Empty1Pos), $0e, BLACK)
  FillMemory(ColorAddress(Empty2Pos), $0e, BLACK)
  FillMemory(ColorAddress(Empty3Pos), $0e, BLACK)
  FillMemory(ColorAddress(Empty4Pos), $0e, BLACK)
  FillMemory(ColorAddress(EmptyQuestionPos), $0e, BLACK)

  rts

/*
Show the Start menu and the available options
*/
StartMenu:
  jsr ClearMenus
  SetMenu(MENU_MAIN)

  // Display the Play Game menu option
  PrintAt(PlayText, PlayGamePos, WHITE)

  // Display the About menu option
  PrintAt(AboutMenuText, AboutPos, WHITE)

  // Display the Quit Game menu option
  PrintAt(QuitText, QuitGamePos, WHITE)

  rts

/*
Show the Forfeit confirmation and available options
*/
ForfeitMenu:
  jsr ClearMenus
  SetMenu(MENU_FORFEIT)

  PrintAt(ForfeitConfirmText, ForfeitConfirmPos, WHITE)

  jmp ShowYesNoOptions

/*
Show the Quit menu and the available options
*/
QuitMenu:
  jsr ClearMenus
  SetMenu(MENU_QUIT)

  // Display Quit message
  PrintAt(QuitConfirmText, QuitConfirmPos, WHITE)

  jmp ShowYesNoOptions

ShowYesNoOptions:
  // Yes option
  PrintAt(YesText, YesPos, WHITE)

  // No option
  PrintAt(NoText, NoPos, WHITE)

  rts

PlayerSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_PLAYER_SELECT)

  // Display the Player Selection message
  PrintAt(PlayerSelectText, PlayerSelectPos, WHITE)

  // 1 player option
  PrintAt(OnePlayerText, OnePlayerPos, WHITE)

  // 2 player option
  PrintAt(TwoPlayerText, TwoPlayerPos, WHITE)

  jmp ShowBackMenuItem

/*
Level selection menu
*/
LevelSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_LEVEL_SELECT)

  PrintAt(LevelSelectText, LevelSelectPos, WHITE)

  // Easy menu option
  PrintAt(LevelEasyText, EasyPos, WHITE)

  // Medium menu option
  PrintAt(LevelMediumText, MediumPos, WHITE)

  // Hard menu option
  PrintAt(LevelHardText, HardPos, WHITE)

  jmp ShowBackMenuItem

/*
Color selection menu
*/
ColorSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_COLOR_SELECT)

  // Color select message
  PrintAt(Player1ColorText, ColorSelectPos, WHITE)

  // Black menu item
  PrintAt(BlackMenuText, BlackPos, WHITE)

  // White menu item
  PrintAt(WhiteMenuText, WhitePos, WHITE)

  jmp ShowBackMenuItem

/*
Pawn promotion menu - shown when a pawn reaches the last rank
*/
PromotionMenu:
  jsr ClearMenus
  SetMenu(MENU_PROMOTION)

  // Promotion select message
  PrintAt(PromotionText, PromotionSelectPos, WHITE)

  // Queen option
  PrintAt(PromoteQueenText, PromoteQueenPos, WHITE)

  // Rook option
  PrintAt(PromoteRookText, PromoteRookPos, WHITE)

  // Bishop option
  PrintAt(PromoteBishopText, PromoteBishopPos, WHITE)

  // Knight option
  PrintAt(PromoteKnightText, PromoteKnightPos, WHITE)

  rts

/*
Display the menu item to allow navigating backwards
*/
ShowBackMenuItem:
  PrintAt(BackMenuText, BackMenuPos, WHITE)

  rts

/*
Show the About menu
*/
ShowAboutMenu:
  // Buffer the center portion of the screen
  CopyMemory(ScreenAddress(AboutTextPos), screenbuffer, AboutTextEnd - AboutTextStart)
  CopyMemory(ColorAddress(AboutTextPos), colorbuffer, AboutTextEnd - AboutTextStart)

  CopyMemory(AboutTextStart, ScreenAddress(AboutTextPos), AboutTextEnd - AboutTextStart)
  CopyMemory(AboutTextColorStart, ColorAddress(AboutTextPos), AboutTextColorEnd - AboutTextColorStart)

  SetMenu(MENU_ABOUT_SHOWING)

  rts

/*
Remove the about menu
*/
HideAboutMenu:
  // Load the buffer back
  CopyMemory(colorbuffer, ColorAddress(AboutTextPos), AboutTextEnd - AboutTextStart)
  CopyMemory(screenbuffer, ScreenAddress(AboutTextPos), AboutTextEnd - AboutTextStart)

  SetMenu(MENU_MAIN)

  rts

