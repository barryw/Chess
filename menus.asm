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

  CopyMemory(ForfeitStart, ScreenAddress(ForfeitPos), ForfeitEnd - ForfeitStart)
  FillMemory(ColorAddress(ForfeitPos), ForfeitEnd - ForfeitStart, WHITE)

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
  CopyMemory(PlayStart, ScreenAddress(PlayGamePos), PlayEnd - PlayStart)
  FillMemory(ColorAddress(PlayGamePos), PlayEnd - PlayStart, WHITE)

  // Display the About menu option
  CopyMemory(AboutStart, ScreenAddress(AboutPos), AboutEnd - AboutStart)
  FillMemory(ColorAddress(AboutPos), AboutEnd - AboutStart, WHITE)

  // Display the Quit Game menu option
  CopyMemory(QuitStart, ScreenAddress(QuitGamePos), QuitEnd - QuitStart)
  FillMemory(ColorAddress(QuitGamePos), QuitEnd - QuitStart, WHITE)

  rts

/*
Show the Forfeit confirmation and available options
*/
ForfeitMenu:
  jsr ClearMenus
  SetMenu(MENU_FORFEIT)

  CopyMemory(ForfeitConfirmationStart, ScreenAddress(ForfeitConfirmPos), ForfeitConfirmationEnd - ForfeitConfirmationEnd)
  FillMemory(ColorAddress(ForfeitConfirmPos), ForfeitConfirmationEnd - ForfeitConfirmationStart, WHITE)

  jmp ShowYesNoOptions

/*
Show the Quit menu and the available options
*/
QuitMenu:
  jsr ClearMenus
  SetMenu(MENU_QUIT)

  // Display Quit message
  CopyMemory(QuitConfirmationStart, ScreenAddress(QuitConfirmPos), QuitConfirmationEnd - QuitConfirmationStart)
  FillMemory(ColorAddress(QuitConfirmPos), QuitConfirmationEnd - QuitConfirmationStart, WHITE)

  jmp ShowYesNoOptions

ShowYesNoOptions:
  // Yes option
  CopyMemory(YesStart, ScreenAddress(YesPos), YesEnd - YesStart)
  FillMemory(ColorAddress(YesPos), YesEnd - YesStart, WHITE)

  // No option
  CopyMemory(NoStart, ScreenAddress(NoPos), NoEnd - NoStart)
  FillMemory(ColorAddress(NoPos), NoEnd - NoStart, WHITE)

  rts

PlayerSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_PLAYER_SELECT)

  // Display the Player Selection message
  CopyMemory(PlayerSelectStart, ScreenAddress(PlayerSelectPos), PlayerSelectEnd - PlayerSelectStart)
  FillMemory(ColorAddress(PlayerSelectPos), PlayerSelectEnd - PlayerSelectStart, WHITE)

  // 1 player option
  CopyMemory(OnePlayerStart, ScreenAddress(OnePlayerPos), OnePlayerEnd - OnePlayerStart)
  FillMemory(ColorAddress(OnePlayerPos), OnePlayerEnd - OnePlayerStart, WHITE)

  // 2 player option
  CopyMemory(TwoPlayerStart, ScreenAddress(TwoPlayerPos), TwoPlayerEnd - TwoPlayerStart)
  FillMemory(ColorAddress(TwoPlayerPos), TwoPlayerEnd - TwoPlayerStart, WHITE)

  jmp ShowBackMenuItem

/*
Level selection menu
*/
LevelSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_LEVEL_SELECT)

  CopyMemory(LevelSelectStart, ScreenAddress(LevelSelectPos), LevelSelectEnd - LevelSelectStart)
  FillMemory(ColorAddress(LevelSelectPos), LevelSelectEnd - LevelSelectStart, WHITE)

  // Easy menu option
  CopyMemory(LevelEasyStart, ScreenAddress(EasyPos), LevelEasyEnd - LevelEasyStart)
  FillMemory(ColorAddress(EasyPos), LevelEasyEnd - LevelEasyStart, WHITE)

  // Medium menu option
  CopyMemory(LevelMediumStart, ScreenAddress(MediumPos), LevelMediumEnd - LevelMediumStart)
  FillMemory(ColorAddress(MediumPos), LevelMediumEnd - LevelMediumStart, WHITE)

  // Hard menu option
  CopyMemory(LevelHardStart, ScreenAddress(HardPos), LevelHardEnd - LevelHardStart)
  FillMemory(ColorAddress(HardPos), LevelHardEnd - LevelHardStart, WHITE)

  jmp ShowBackMenuItem

/*
Color selection menu
*/
ColorSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_COLOR_SELECT)

  // Color select message
  CopyMemory(Player1ColorStart, ScreenAddress(ColorSelectPos), Player1ColorEnd - Player1ColorStart)
  FillMemory(ColorAddress(ColorSelectPos), Player1ColorEnd - Player1ColorStart, WHITE)

  // Black menu item
  CopyMemory(BlackMenuStart, ScreenAddress(BlackPos), BlackMenuEnd - BlackMenuStart)
  FillMemory(ColorAddress(BlackPos), BlackMenuEnd - BlackMenuStart, WHITE)

  // White menu item
  CopyMemory(WhiteMenuStart, ScreenAddress(WhitePos), WhiteMenuEnd - WhiteMenuStart)
  FillMemory(ColorAddress(WhitePos), WhiteMenuEnd - WhiteMenuStart, WHITE)

  jmp ShowBackMenuItem

/*
Display the menu item to allow navigating backwards
*/
ShowBackMenuItem:
  CopyMemory(BackMenuStart, ScreenAddress(BackMenuPos), BackMenuEnd - BackMenuStart)
  FillMemory(ColorAddress(BackMenuPos), BackMenuEnd - BackMenuStart, WHITE)

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
