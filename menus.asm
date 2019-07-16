*=* "Menus"

/*
Read the keyboard and process the key presses
*/
ReadKeyboard:
  jsr Keyboard
  bcc !processkey+
  rts
!processkey:
  sta currentkey
  cpx #$02
  bne !next+
  jmp HandleReturnKey
!next:
  cpx #$01
  bne !next+
  jmp HandleDeleteKey
!next:
  cmp #KEY_A
  bne !next+
  jmp HandleAKey
!next:
  cmp #KEY_B
  bne !next+
  jmp HandleBKey
!next:
  cmp #KEY_C
  bne !next+
  jmp HandleCKey
!next:
  cmp #KEY_D
  bne !next+
  jmp HandleDKey
!next:
  cmp #KEY_E
  bne !next+
  jmp HandleEKey
!next:
  cmp #KEY_F
  bne !next+
  jmp HandleFKey
!next:
  cmp #KEY_G
  bne !next+
  jmp HandleGKey
!next:
  cmp #KEY_H
  bne !next+
  jmp HandleHKey
!next:
  cmp #KEY_M
  bne !next+
  jmp HandleMKey
!next:
  cmp #KEY_N
  bne !next+
  jmp HandleNKey
!next:
  cmp #KEY_P
  bne !next+
  jmp HandlePKey
!next:
  cmp #KEY_Q
  bne !next+
  jmp HandleQKey
!next:
  cmp #KEY_Y
  bne !next+
  jmp HandleYKey
!next:
  cmp #KEY_1
  bne !next+
  jmp Handle1Key
!next:
  cmp #KEY_2
  bne !next+
  jmp Handle2Key
!next:
  cmp #KEY_3
  bne !next+
  jmp Handle3Key
!next:
  cmp #KEY_4
  bne !next+
  jmp Handle4Key
!next:
  cmp #KEY_5
  bne !next+
  jmp Handle5Key
!next:
  cmp #KEY_6
  bne !next+
  jmp Handle6Key
!next:
  cmp #KEY_7
  bne !next+
  jmp Handle7Key
!next:
  cmp #KEY_8
  bne !next+
  jmp Handle8Key
!next:
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
  jmp HandleColumnSelection

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

!columnselect:
  jmp HandleColumnSelection

!levelselect:
  jne numplayers:#ONE_PLAYER:!playerselect+
  jmp LevelSelectMenu

!start:
  jmp StartMenu

!playerselect:
  jmp PlayerSelectMenu

HandleCKey:
HandleDKey:
  jmp HandleColumnSelection

/*
The E key is used as column select during the game, or the Easy level menu selection
*/
HandleEKey:
  jeq currentmenu:#MENU_LEVEL_SELECT:!easy+

!columnselect:
  jmp HandleColumnSelection

!easy:
  stb #LEVEL_EASY:difficulty
  jmp ColorSelectMenu

HandleFKey:
HandleGKey:
  jmp HandleColumnSelection

/*
The H key is used as column select during the game, or the Hard level menu selection
*/
HandleHKey:
  jeq currentmenu:#MENU_LEVEL_SELECT:!hard+

!columnselect:
  jmp HandleColumnSelection

!hard:
  stb #LEVEL_HARD:difficulty
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
  stb #LEVEL_MEDIUM:difficulty
  jmp ColorSelectMenu

!music:
  jmp ToggleMusic

/*
Handle the pressing of the Q key. This is normally tied to the Quit option from the main menu
*/
HandleQKey:
  jne currentmenu:#MENU_MAIN:!exit+
  jsr QuitMenu
!exit:
  rts

/*
Handle the pressing of the Y key. This normally tied to the Quit option
*/
HandleYKey:
  jne currentmenu:#MENU_QUIT:!exit+
  jsr DisableSprites
  stb #$37:$01
  jsr $fce2
!exit:
  rts

/*
Handle the pressing of the N key. This is normally tied to the Quit option
*/
HandleNKey:
  jne currentmenu:#MENU_QUIT:!exit+
  jsr StartMenu
!exit:
  rts

/*
Handle the pressing of the P key.
*/
HandlePKey:
  jne currentmenu:#MENU_MAIN:!exit+
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
  stb #ONE_PLAYER:numplayers
  jmp LevelSelectMenu

!colorselect:
  stb #BLACK:player1color
  jmp StartGame

!rowselect:
  jmp HandleRowSelection

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
  stb #TWO_PLAYERS:numplayers
  jmp ColorSelectMenu

!colorselect:
  stb #WHITE:player1color
  jmp StartGame

!rowselect:
  jmp HandleRowSelection

Handle3Key:
Handle4Key:
Handle5Key:
Handle6Key:
Handle7Key:
Handle8Key:
  jmp HandleRowSelection

/*
Handle the pressing of the return key. This key gets pressed when
the player has typed in the entire movefrom or moveto coordinates
*/
HandleReturnKey:
  bfs processreturn:!exit+
  sef processreturn
  eor #BIT8
  sta processreturn
  jne currentmenu:#MENU_GAME:!endreturn+
  lda showcursor        // Are we accepting input?
  beq !endreturn+

  jne movetoindex:#BIT8:!processmove+
  jne movefromindex:#BIT8:!validatefrom+

  jmp !endreturn+       // Nope. Don't do anything until we have a movefrom value
!validatefrom:
  jsr ValidateFrom      // Make sure this is a valid move
  jmp !endreturn+
!processmove:
  jsr ValidateMove
  jeq moveisvalid:#$00:!endreturn+
!movepiece:
  jsr MovePiece
  jsr ChangePlayers
!endreturn:
  clf processreturn
!exit:
  rts

/*
Allow the user to correct their input
*/
HandleDeleteKey:
  ldy cursorxpos        // Is the cursor at the beginning of input?
  cpy #$00
  beq !exit+            // Yea. just exit since we can't delete anymore.
  stb #$20:(inputlocationvector),y
  dec cursorxpos
!exit:
  rts

/*
Deal with a row selection. This is the second part of the board coordinate.
*/
HandleRowSelection:
  jeq cursorxpos:#$00:!exit+
  lda currentkey
  sec
  sbc #$31              // Store the row 0 based instead of 1 based.
  tay
  lda rowlookup, y      // Invert the row numbers
  pha
  jne inputselection:#INPUT_MOVE_FROM:!moveto+
  pla
  sta movefrom + $01
  jsr ComputeMoveFromOffset
  jmp !continue+
!moveto:
  pla
  sta moveto + $01
  jsr ComputeMoveToOffset
!continue:
  jsr DisplayCoordinate
!exit:
  rts

/*
Deal with a column selection. This is the first part of the board coordinate
for movefrom and moveto.
*/
HandleColumnSelection:
  jeq cursorxpos:#$01:!exit+
  lda currentkey
  sec
  sbc #$01              // Make the column number 0 based
  pha
  jne inputselection:#INPUT_MOVE_FROM:!moveto+
  pla
  sta movefrom
  jmp !continue+
!moveto:
  pla
  sta moveto
!continue:
  clc
  adc #$41              // Make the column selection uppercase
  sta currentkey
  jsr DisplayCoordinate
  inc cursorxpos        // Move the cursor over 1 place
!exit:
  rts

/*
Display either the row or the column
*/
DisplayCoordinate:
  jsr ClearError
  lda currentkey
  StoreWord(inputlocationvector, ScreenAddress(CursorPos))
  ldy cursorxpos
  sta (inputlocationvector), y
  rts

/*
The main game loop
*/
StartGame:
  jsr ShowGameMenu

!playgame:
  jeq numplayers:#TWO_PLAYERS:!twoplayers+

!oneplayer:
  jeq currentplayer:player1color:!playersturn+
!computersturn:
  jsr ShowThinking
  jmp !exit+

!playersturn:
!twoplayers:
  jsr DisplayMoveFromPrompt

!exit:
  rts

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
Show the status line under the title and copyright. It includes which player is currently playing
as well as a play clock for that player.
*/
ShowStatus:
  CopyMemory(TurnStart, ScreenAddress(TurnPos), TurnEnd - TurnStart)
  FillMemory(ColorAddress(TurnPos), TurnEnd - TurnStart, WHITE)

  CopyMemory(TimeStart, ScreenAddress(TimePos), TimeEnd - TimeStart)
  FillMemory(ColorAddress(TimePos), TimeEnd - TimeStart, WHITE)

  FillMemory(ScreenAddress(StatusSepPos), $0e, $77)
  FillMemory(ColorAddress(StatusSepPos), $0e, WHITE)

  rts

/*
Show the portion of the screen that details which pieces have been captured by the current player
*/
ShowCaptured:
  CopyMemory(CapturedStart, ScreenAddress(CapturedPos), CapturedEnd - CapturedStart)
  FillMemory(ColorAddress(CapturedPos), CapturedEnd - CapturedStart, WHITE)

  CopyMemory(CapturedUnderlineStart, ScreenAddress(CapturedUnderlinePos), CapturedUnderlineEnd - CapturedUnderlineStart)
  FillMemory(ColorAddress(CapturedUnderlinePos), CapturedUnderlineEnd - CapturedUnderlineStart, WHITE)

  CopyMemory(CapturedPawnStart, ScreenAddress(CapturedPawnPos), CapturedPawnEnd - CapturedPawnStart)
  FillMemory(ColorAddress(CapturedPawnPos), CapturedPawnEnd - CapturedPawnStart, WHITE)

  CopyMemory(CapturedKnightStart, ScreenAddress(CapturedKnightPos), CapturedKnightEnd - CapturedKnightStart)
  FillMemory(ColorAddress(CapturedKnightPos), CapturedKnightEnd - CapturedKnightStart, WHITE)

  CopyMemory(CapturedBishopStart, ScreenAddress(CapturedBishopPos), CapturedBishopEnd - CapturedBishopStart)
  FillMemory(ColorAddress(CapturedBishopPos), CapturedBishopEnd - CapturedBishopStart, WHITE)

  CopyMemory(CapturedRookStart, ScreenAddress(CapturedRookPos), CapturedRookEnd - CapturedRookStart)
  FillMemory(ColorAddress(CapturedRookPos), CapturedRookEnd - CapturedRookStart, WHITE)

  CopyMemory(CapturedQueenStart, ScreenAddress(CapturedQueenPos), CapturedQueenEnd - CapturedQueenStart)
  FillMemory(ColorAddress(CapturedQueenPos), CapturedQueenEnd - CapturedQueenStart, WHITE)

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

  // Display the music play/stop menu option
  jmp DisplayUnmuteMenu

/*
Show the Quit menu and the available options
*/
QuitMenu:
  jsr ClearMenus
  SetMenu(MENU_QUIT)

  // Display Quit message
  CopyMemory(QuitConfirmationStart, ScreenAddress(QuitConfirmPos), QuitConfirmationEnd - QuitConfirmationStart)
  FillMemory(ColorAddress(QuitConfirmPos), QuitConfirmationEnd - QuitConfirmationStart, WHITE)

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

/*
Display the prompt to allow the player to enter the coordinates of the piece to move.
*/
DisplayMoveFromPrompt:
  CopyMemory(MoveFromStart, ScreenAddress(MovePos), MoveFromEnd - MoveFromStart)
  FillMemory(ColorAddress(MovePos), MoveFromEnd - MoveFromStart, WHITE)

  SetInputSelection(INPUT_MOVE_FROM)

  jsr ResetInput

  Enable(showcursor)

  rts

/*
Display the prompt to allow the player to enter the coordinates of where to move the
selected piece.
*/
DisplayMoveToPrompt:
  CopyMemory(MoveToStart, ScreenAddress(MovePos), MoveToEnd - MoveToStart)
  FillMemory(ColorAddress(MovePos), MoveToEnd - MoveToStart, WHITE)

  SetInputSelection(INPUT_MOVE_TO)

  jsr ResetInput

  rts

/*
If the current player's king is in check, display a helpful message
*/
ShowKingInCheck:
  jeq currentplayer:#WHITES_TURN:!white+

!black:
  ldx #BLACK
  jmp !continue+

!white:
  ldx #WHITE

!continue:
  jne incheckflags, x:#ENABLE:!exit+
  CopyMemory(KingInCheckStart, ScreenAddress(KingInCheckPos), KingInCheckEnd - KingInCheckStart)
  FillMemory(ColorAddress(KingInCheckPos), KingInCheckEnd - KingInCheckStart, WHITE)

!exit:
  rts

/*
Figure out whose turn it is and update the status lines.
*/
UpdateCurrentPlayer:
  stb #$3c:subseconds   // Reset subsecond count
  jeq numplayers:#ONE_PLAYER:!oneplayer+

!twoplayers:
  stb #WHITE:ColorAddress(PlayerNumberPos)
  jeq player1color:currentplayer:!playeronesturn+

!playertwosturn:
  stb #'2':ScreenAddress(PlayerNumberPos)
  jmp !playersturn+
!playeronesturn:
  stb #'1':ScreenAddress(PlayerNumberPos)
  jmp !playersturn+

!oneplayer:
  stb #BLACK:ColorAddress(PlayerNumberPos)
  jeq player1color:currentplayer:!playersturn+

!computersturn:
  CopyMemory(ComputerStart, ScreenAddress(TurnValuePos), ComputerEnd - ComputerStart)
  FillMemory(ColorAddress(TurnValuePos), ComputerEnd - ComputerStart, WHITE)
  jsr ShowThinking      // Enable the spinner to show that the computer is thinking
  jmp !return+

!playersturn:
  CopyMemory(PlayerStart, ScreenAddress(TurnValuePos), PlayerEnd - PlayerStart)
  FillMemory(ColorAddress(TurnValuePos), PlayerEnd - PlayerStart, WHITE)
  jsr HideThinking      // If it's the players turn, disable the spinner

!return:
  rts
