// Game Flow and Control
// Main keyboard dispatch, key handlers, game flow, player management

*=* "Game"

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
  cmp #KEY_Z
  bne !next+
  jmp HandleZKey
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
The M key is used to select medium difficulty
*/
HandleMKey:
  lda currentmenu
  cmp #MENU_LEVEL_SELECT
  beq !medium+
  rts

!medium:
  stb #LEVEL_MEDIUM:difficulty
  jmp ColorSelectMenu

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
Handle the pressing of the Z key. This is used to forfeit an in-progress game.
*/
HandleZKey:
  jne currentmenu:#MENU_GAME:!exit+

  //clf playclockrunning  // Stop the clock temporarily
  //clf showcursor        // Disable the cursor
  //jsr ForfeitMenu

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
Swap the board and swap players. This is called after a player has
made a move.
*/
ChangePlayers:
  lda currentplayer
  eor #%00000001        // Swap the players
  sta currentplayer

  clf playclockrunning  // Turn off the play clock while we swap

  jsr UpdateCaptureCounts
  jsr ResetPlayer
  jsr UpdateCurrentPlayer

  jne numplayers:#ONE_PLAYER:!twoplayers+
  jsr ShowThinking
  jmp !return+
!twoplayers:
  jsr DisplayMoveFromPrompt

!return:
  sef playclockrunning   // Turn the play clock back on

  rts
