// Clears the menu area
ClearMenus:
  CopyMemory(EmptyRowStart, ScreenAddress(Empty1Pos), EmptyRowEnd - EmptyRowStart)
  CopyMemory(EmptyRowStart, ScreenAddress(Empty2Pos), EmptyRowEnd - EmptyRowStart)
  CopyMemory(EmptyRowStart, ScreenAddress(Empty3Pos), EmptyRowEnd - EmptyRowStart)
  rts

StartMenu:
  jsr ClearMenus
  // Display the Play Game menu option
  CopyMemory(PlayStart, ScreenAddress(PlayGamePos), PlayEnd - PlayStart)
  CopyMemory(PlayColorStart, ColorAddress(PlayGamePos), PlayColorEnd - PlayColorStart)

  // Display the Quit Game menu option
  CopyMemory(QuitStart, ScreenAddress(QuitGamePos), QuitEnd - QuitStart)
  CopyMemory(QuitColorStart, ColorAddress(QuitGamePos), QuitColorEnd - QuitColorStart)

  jsr DisplayMuteMenu

  rts

QuitMenu:
  jsr ClearMenus
  CopyMemory(YesStart, ScreenAddress(YesPos), YesEnd - YesStart)
  CopyMemory(YesColorStart, ColorAddress(YesPos), YesColorEnd - YesColorStart)

  CopyMemory(NoStart, ScreenAddress(NoPos), NoEnd - NoStart)
  CopyMemory(NoColorStart, ColorAddress(NoPos), NoColorEnd - NoColorStart)

  rts

PlayerSelectMenu:
  jsr ClearMenus
  CopyMemory(OnePlayerStart, ScreenAddress(OnePlayerPos), OnePlayerEnd - OnePlayerStart)
  CopyMemory(OnePlayerColorStart, ColorAddress(OnePlayerPos), OnePlayerColorEnd - OnePlayerColorStart)

  CopyMemory(TwoPlayerStart, ScreenAddress(TwoPlayerPos), TwoPlayerEnd - TwoPlayerStart)
  CopyMemory(TwoPlayerColorStart, ColorAddress(TwoPlayerPos), TwoPlayerColorEnd - TwoPlayerColorStart)
  rts

ColorSelectMenu:
  jsr ClearMenus
  rts
