*=* "Menus"

.macro SetMenu(menu) {
  lda #menu
  sta currentmenu
}

/*
Read the keyboard and process the key presses
*/
ReadKeyboard:
  jsr Keyboard
  bcs NoValidInput
  jsr WaitForVblank
  cmp #KEY_M
  bne !nextkey+
  jmp HandleMKey
!nextkey:
  cmp #KEY_A
  bne !nextkey+
  jmp HandleAKey
!nextkey:
  cmp #KEY_B
  bne !nextkey+
  jmp HandleBKey
!nextkey:
  cmp #KEY_E
  bne !nextkey+
  jmp HandleEKey
!nextkey:
  cmp #KEY_H
  bne !nextkey+
  jmp HandleHKey
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
The A key is used to display the About menu or as column select during the game
*/
HandleAKey:
  lda currentmenu
  cmp #MENU_MAIN
  beq !showabout+
  cmp #MENU_ABOUT_SHOWING
  beq !hideabout+

!columnselect:
  rts

!showabout:
  jmp ShowAboutMenu

!hideabout:
  jmp HideAboutMenu

/*
The B key is used to go backwards in the menus as well as column select during the game
*/
HandleBKey:
  lda currentmenu
  cmp #MENU_PLAYER_SELECT
  beq !start+
  cmp #MENU_LEVEL_SELECT
  beq !playerselect+
  cmp #MENU_COLOR_SELECT
  beq !levelselect+
  cmp #MENU_GAME
  beq !columnselect+
  rts

!columnselect:
  rts

!levelselect:
  lda numplayers
  cmp #ONE_PLAYER
  bne !playerselect+
  jmp LevelSelectMenu

!start:
  jmp StartMenu

!playerselect:
  jmp PlayerSelectMenu

/*
The E key is used as column select during the game, or the Easy level menu selection
*/
HandleEKey:
  lda currentmenu
  cmp #MENU_LEVEL_SELECT
  beq !easy+

!columnselect:
  rts

!easy:
  lda #LEVEL_EASY
  sta difficulty
  jmp ColorSelectMenu

/*
The H key is used as column select during the game, or the Hard level menu selection
*/
HandleHKey:
  lda currentmenu
  cmp #MENU_LEVEL_SELECT
  beq !hard+

!columnselect:
  rts

!hard:
  lda #LEVEL_HARD
  sta difficulty
  jmp ColorSelectMenu

/*
The M key is used to mute/unmute the music while on the main screen or during gameplay
*/
HandleMKey:
  lda currentmenu
  cmp #MENU_MAIN
  beq !music+
  cmp #MENU_GAME
  beq !music+
  cmp #MENU_LEVEL_SELECT
  beq !medium+
  rts

!medium:
  lda #LEVEL_MEDIUM
  sta difficulty
  jmp ColorSelectMenu

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
  jsr DisableSprites
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
The 1 key serves a few purposes: player selection, color selection and row selection during gameplay
*/
Handle1Key:
  lda currentmenu
  cmp #MENU_PLAYER_SELECT
  beq !playerselect+
  cmp #MENU_COLOR_SELECT
  beq !colorselect+
  cmp #MENU_GAME
  beq !rowselect+
  rts

!playerselect:
  lda #ONE_PLAYER
  sta numplayers
  jmp LevelSelectMenu

!colorselect:
  lda #BLACK
  sta player1color
  jmp StartGame

!rowselect:
  rts

/*
The 2 key serves a few purposes: player selection, color selection and row selection during gameplay
*/
Handle2Key:
  lda currentmenu
  cmp #MENU_PLAYER_SELECT
  beq !playerselect+
  cmp #MENU_COLOR_SELECT
  beq !colorselect+
  cmp #MENU_GAME
  beq !rowselect+
  rts

!playerselect:
  lda #TWO_PLAYERS
  sta numplayers
  jmp ColorSelectMenu

!colorselect:
  lda #WHITE
  sta player1color
  jmp StartGame

!rowselect:
  rts

/*
Start the game
*/
StartGame:
  jsr ShowGameMenu

  rts

/*
Display the menu that's shown while the game is being played\
*/
ShowGameMenu:
  jsr ClearMenus
  SetMenu(MENU_GAME)

  jsr ShowCaptured

  CopyMemory(RotateStart, ScreenAddress(RotatePos), RotateEnd - RotateStart)
  CopyMemory(RotateColorStart, ColorAddress(RotatePos), RotateColorEnd - RotateColorStart)

  CopyMemory(ForfeitStart, ScreenAddress(ForfeitPos), ForfeitEnd - ForfeitStart)
  CopyMemory(ForfeitColorStart, ColorAddress(ForfeitPos), ForfeitColorEnd - ForfeitColorStart)

  rts

ShowCaptured:
  CopyMemory(CapturedStart, ScreenAddress(CapturedPos), CapturedEnd - CapturedStart)
  CopyMemory(CapturedColorStart, ColorAddress(CapturedPos), CapturedColorEnd - CapturedColorStart)

  CopyMemory(CapturedUnderlineStart, ScreenAddress(CapturedUnderlinePos), CapturedUnderlineEnd - CapturedUnderlineStart)
  CopyMemory(CapturedColorStart, ColorAddress(CapturedUnderlinePos), CapturedColorEnd - CapturedColorStart)

  CopyMemory(CapturedPawnStart, ScreenAddress(CapturedPawnPos), CapturedPawnEnd - CapturedPawnStart)
  CopyMemory(CapturedPieceColorStart, ColorAddress(CapturedPawnPos), CapturedPieceColorEnd - CapturedPieceColorStart)

  CopyMemory(CapturedKnightStart, ScreenAddress(CapturedKnightPos), CapturedKnightEnd - CapturedKnightStart)
  CopyMemory(CapturedPieceColorStart, ColorAddress(CapturedKnightPos), CapturedPieceColorEnd - CapturedPieceColorStart)

  CopyMemory(CapturedBishopStart, ScreenAddress(CapturedBishopPos), CapturedBishopEnd - CapturedBishopStart)
  CopyMemory(CapturedPieceColorStart, ColorAddress(CapturedBishopPos), CapturedPieceColorEnd - CapturedPieceColorStart)

  CopyMemory(CapturedRookStart, ScreenAddress(CapturedRookPos), CapturedRookEnd - CapturedRookStart)
  CopyMemory(CapturedPieceColorStart, ColorAddress(CapturedRookPos), CapturedPieceColorEnd - CapturedPieceColorStart)

  CopyMemory(CapturedQueenStart, ScreenAddress(CapturedQueenPos), CapturedQueenEnd - CapturedQueenStart)
  CopyMemory(CapturedPieceColorStart, ColorAddress(CapturedQueenPos), CapturedPieceColorEnd - CapturedPieceColorStart)

  lda currentplayer
  ldy #$00
  cmp #WHITES_TURN
  beq !whitecaptured+
!blackcaptured:
  StoreWord(capturedvector, blackcaptured)
  jmp !print+
!whitecaptured:
  StoreWord(capturedvector, whitecaptured)
!print:
  StoreWord(printvector, ScreenAddress(CapturedCountStart))
!loop:
  lda (capturedvector), y
  sta num1
  jsr PrintDigit
  lda printvector
  clc
  adc #$28
  sta printvector
  iny
  cpy #$05
  bne !loop-

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
  SetMenu(MENU_MAIN)

  // Display the Play Game menu option
  CopyMemory(PlayStart, ScreenAddress(PlayGamePos), PlayEnd - PlayStart)
  CopyMemory(PlayColorStart, ColorAddress(PlayGamePos), PlayColorEnd - PlayColorStart)

  // Display the About menu option
  CopyMemory(AboutStart, ScreenAddress(AboutPos), AboutEnd - AboutStart)
  CopyMemory(AboutColorStart, ColorAddress(AboutPos), AboutColorEnd - AboutColorStart)

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
  SetMenu(MENU_QUIT)

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
  SetMenu(MENU_PLAYER_SELECT)

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
Level selection menu
*/
LevelSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_LEVEL_SELECT)

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
Color selection menu
*/
ColorSelectMenu:
  jsr ClearMenus
  SetMenu(MENU_COLOR_SELECT)

  // Color select message
  CopyMemory(Player1ColorStart, ScreenAddress(ColorSelectPos), Player1ColorEnd - Player1ColorStart)
  CopyMemory(P1ColorStart, ColorAddress(ColorSelectPos), P1ColorEnd - P1ColorStart)

  // Black menu item
  CopyMemory(BlackMenuStart, ScreenAddress(BlackPos), BlackMenuEnd - BlackMenuStart)
  CopyMemory(BlackMenuColorStart, ColorAddress(BlackPos), BlackMenuColorEnd - BlackMenuColorStart)

  // White menu item
  CopyMemory(WhiteMenuStart, ScreenAddress(WhitePos), WhiteMenuEnd - WhiteMenuStart)
  CopyMemory(WhiteMenuColorStart, ColorAddress(WhitePos), WhiteMenuColorEnd - WhiteMenuColorStart)

  jmp ShowBackMenuItem

/*
Menu displayed while the game is being played
*/
GameMenu:
  jsr ClearMenus
  SetMenu(MENU_GAME)

  rts

ShowBackMenuItem:
  // Back to main menu option
  CopyMemory(BackMenuStart, ScreenAddress(BackMenuPos), BackMenuEnd - BackMenuStart)
  CopyMemory(BackMenuColorStart, ColorAddress(BackMenuPos), BackMenuColorEnd - BackMenuColorStart)
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
  lda #$01
  sta aboutisshowing
  rts

HideAboutMenu:
  // Load the buffer back
  CopyMemory(colorbuffer, ColorAddress(AboutTextPos), AboutTextEnd - AboutTextStart)
  CopyMemory(screenbuffer, ScreenAddress(AboutTextPos), AboutTextEnd - AboutTextStart)

  lda #$00
  sta aboutisshowing
  SetMenu(MENU_MAIN)
  rts
