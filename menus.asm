*=* "Menus"

/*
Read the keyboard and process the key presses
*/
ReadKeyboard:
  jsr Keyboard
  bcs NoValidInput
  cmp #KEY_M
  bne !nextkey+
  jmp HandleMKey
!nextkey:
  cmp #KEY_B
  bne !nextkey+
  jmp HandleBKey
!nextkey:
  cmp #KEY_Q
  bne !nextkey+
  jmp HandleQKey
!nextkey:
  cmp #KEY_Y
  bne !nextkey+
  jmp HandleYKey
!nextkey:
  cmp #KEY_N
  bne !nextkey+
  jmp HandleNKey
!nextkey:
  cmp #KEY_P
  bne !nextkey+
  jmp HandlePKey
!nextkey:
  cmp #KEY_1
  bne !nextkey+
  jmp Handle1Key
!nextkey:
  cmp #KEY_2
  bne !nextkey+
  jmp Handle2Key
!nextkey:
NoValidInput:
  rts

/*
The B key is used to go backwards in the menus as well as column select during the game
*/
HandleBKey:
  lda currentmenu
  cmp #MENU_PLAYER_SELECT
  beq !start+
  cmp #MENU_LEVEL_SELECT
  beq !playerselect+
  cmp #MENU_GAME
  beq !columnselect+
  rts

!columnselect:
  rts

!start:
  jmp StartMenu

!playerselect:
  jmp PlayerSelectMenu

/*
The M key is used to mute/unmute the music while on the main screen or during gameplay
*/
HandleMKey:
  lda currentmenu
  cmp #MENU_MAIN
  beq !music+
  cmp #MENU_GAME
  beq !music+
  rts

!music:
  jmp ToggleMusic

/*
Handle the pressing of the Q key. This is normally tied to the Quit option from the main menu
*/
HandleQKey:
  lda currentmenu
  cmp #MENU_MAIN
  bne !exit+
  jsr QuitMenu
!exit:
  rts

/*
Handle the pressing of the Y key. This normally tied to the Quit option
*/
HandleYKey:
  lda currentmenu
  cmp #MENU_QUIT
  bne !exit+
  lda #$37
  sta $01
  jsr $fce2
!exit:
  rts

/*
Handle the pressing of the N key. This is normally tied to the Quit option
*/
HandleNKey:
  lda currentmenu
  cmp #MENU_QUIT
  bne !exit+
  jsr StartMenu
!exit:
  rts

/*
Handle the pressing of the P key.
*/
HandlePKey:
  lda currentmenu
  cmp #MENU_MAIN
  bne !exit+
  jsr PlayerSelectMenu
!exit:
  rts

/*
The 1 key serves a couple of purposes: player selection and row selection during gameplay
*/
Handle1Key:
  lda currentmenu
  cmp #MENU_PLAYER_SELECT
  bne !next+
  lda #$01
  jsr ShowLevelSelectMenu
!next:
  rts

/*
The 2 key serves a couple of purposes: player selection and row selection during gameplay
*/
Handle2Key:
  lda currentmenu
  cmp #MENU_PLAYER_SELECT
  bne !next+
  lda #$02
  jsr ShowLevelSelectMenu
!next:
  rts

ShowLevelSelectMenu:
  sta numplayers
  jsr LevelSelectMenu
  rts

/*
Clear the menu options and any displayed questions

TODO: This could probably be simplified with routine to clear the right side of the screen
*/
ClearMenus:
  CopyMemory(EmptyRowStart, ScreenAddress(Empty1Pos), EmptyRowEnd - EmptyRowStart)
  CopyMemory(EmptyRowStart, ScreenAddress(Empty2Pos), EmptyRowEnd - EmptyRowStart)
  CopyMemory(EmptyRowStart, ScreenAddress(Empty3Pos), EmptyRowEnd - EmptyRowStart)
  CopyMemory(EmptyRowStart, ScreenAddress(Empty4Pos), EmptyRowEnd - EmptyRowStart)
  CopyMemory(EmptyRowStart, ScreenAddress(EmptyQuestionPos), EmptyRowEnd - EmptyRowStart)
  rts

/*
Show the Start menu and the available options
*/
StartMenu:
  jsr ClearMenus
  lda #MENU_MAIN
  sta currentmenu

  // Display the Play Game menu option
  CopyMemory(PlayStart, ScreenAddress(PlayGamePos), PlayEnd - PlayStart)
  CopyMemory(PlayColorStart, ColorAddress(PlayGamePos), PlayColorEnd - PlayColorStart)

  // Display the Quit Game menu option
  CopyMemory(QuitStart, ScreenAddress(QuitGamePos), QuitEnd - QuitStart)
  CopyMemory(QuitColorStart, ColorAddress(QuitGamePos), QuitColorEnd - QuitColorStart)

  // Display the music play/stop menu option
  jmp DisplayMuteMenu

/*
Show the Quit menu and the available options
*/
QuitMenu:
  jsr ClearMenus
  lda #MENU_QUIT
  sta currentmenu

  // Display Quit message
  CopyMemory(QuitConfirmationStart, ScreenAddress(QuitConfirmPos), QuitConfirmationEnd - QuitConfirmationStart)
  CopyMemory(QuitConfirmationColorStart, ColorAddress(QuitConfirmPos), QuitConfirmationColorEnd - QuitConfirmationColorStart)

  // Yes option
  CopyMemory(YesStart, ScreenAddress(YesPos), YesEnd - YesStart)
  CopyMemory(YesColorStart, ColorAddress(YesPos), YesColorEnd - YesColorStart)

  // No option
  CopyMemory(NoStart, ScreenAddress(NoPos), NoEnd - NoStart)
  CopyMemory(NoColorStart, ColorAddress(NoPos), NoColorEnd - NoColorStart)

  rts

PlayerSelectMenu:
  jsr ClearMenus
  lda #MENU_PLAYER_SELECT
  sta currentmenu

  // Display the Player Selection message
  CopyMemory(PlayerSelectStart, ScreenAddress(PlayerSelectPos), PlayerSelectEnd - PlayerSelectStart)
  CopyMemory(PlayerSelectColorStart, ColorAddress(PlayerSelectPos), PlayerSelectColorEnd - PlayerSelectColorStart)

  // 1 player option
  CopyMemory(OnePlayerStart, ScreenAddress(OnePlayerPos), OnePlayerEnd - OnePlayerStart)
  CopyMemory(OnePlayerColorStart, ColorAddress(OnePlayerPos), OnePlayerColorEnd - OnePlayerColorStart)

  // 2 player option
  CopyMemory(TwoPlayerStart, ScreenAddress(TwoPlayerPos), TwoPlayerEnd - TwoPlayerStart)
  CopyMemory(TwoPlayerColorStart, ColorAddress(TwoPlayerPos), TwoPlayerColorEnd - TwoPlayerColorStart)

  jmp ShowBackMenuItem

/*
Color selection menu
*/
ColorSelectMenu:
  jsr ClearMenus
  rts

/*
Level selection menu
*/
LevelSelectMenu:
  jsr ClearMenus
  lda #MENU_LEVEL_SELECT
  sta currentmenu

  CopyMemory(LevelSelectStart, ScreenAddress(LevelSelectPos), LevelSelectEnd - LevelSelectStart)
  CopyMemory(LevelSelectColorStart, ColorAddress(LevelSelectPos), LevelSelectColorEnd - LevelSelectColorStart)

  // Easy menu option
  CopyMemory(LevelEasyStart, ScreenAddress(EasyPos), LevelEasyEnd - LevelEasyStart)
  CopyMemory(LevelEasyColorStart, ColorAddress(EasyPos), LevelEasyColorEnd - LevelEasyColorStart)

  // Medium menu option
  CopyMemory(LevelMediumStart, ScreenAddress(MediumPos), LevelMediumEnd - LevelMediumStart)
  CopyMemory(LevelMediumColorStart, ColorAddress(MediumPos), LevelMediumColorEnd - LevelMediumColorStart)

  // Hard menu option
  CopyMemory(LevelHardStart, ScreenAddress(HardPos), LevelHardEnd - LevelHardStart)
  CopyMemory(LevelHardColorStart, ColorAddress(HardPos), LevelHardColorEnd - LevelHardColorStart)

  jmp ShowBackMenuItem

/*
Menu displayed while the game is being played
*/
GameMenu:
  jsr ClearMenus
  lda #MENU_GAME
  sta currentmenu

  rts

ShowBackMenuItem:
  // Back to main menu option
  CopyMemory(BackMenuStart, ScreenAddress(BackMenuPos), BackMenuEnd - BackMenuStart)
  CopyMemory(BackMenuColorStart, ColorAddress(BackMenuPos), BackMenuColorEnd - BackMenuColorStart)
  rts
