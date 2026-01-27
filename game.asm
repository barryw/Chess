// Game Flow and Control
// Main keyboard dispatch, key handlers, game flow, player management

*=* "Game"

/*
Read the keyboard and process the key presses.
Optimized dispatch using range checks and jump tables.
Uses RTS trick for 6502-compatible indirect jumps.
*/
ReadKeyboard:
  jsr Keyboard
  bcc !processkey+
  rts

!processkey:
  sta currentkey

  // Check special keys via X register (Return=2, Delete=1)
  cpx #$02
  beq !return+
  cpx #$01
  beq !delete+

  // Check column keys A-H ($01-$08) - use jump table
  cmp #KEY_A
  bcc !checkother+
  cmp #KEY_H + 1
  bcs !checkother+
  // It's A-H: use indexed jump via RTS trick
  sec
  sbc #KEY_A              // Convert to 0-7
  asl                     // *2 for word table
  tax
  lda ColumnKeyTable + 1, x
  pha
  lda ColumnKeyTable, x
  pha
  rts                     // "Return" to handler address

!checkother:
  // Check number keys 1-8 ($31-$38) - use jump table
  cmp #KEY_1
  bcc !checkmenu+
  cmp #KEY_8 + 1
  bcs !checkmenu+
  // It's 1-8: use indexed jump via RTS trick
  sec
  sbc #KEY_1              // Convert to 0-7
  asl                     // *2 for word table
  tax
  lda NumberKeyTable + 1, x
  pha
  lda NumberKeyTable, x
  pha
  rts                     // "Return" to handler address

!checkmenu:
  // Menu keys: M, N, P, Q, Y, Z (not sequential, use compare chain)
  cmp #KEY_M
  beq !mkey+
  cmp #KEY_N
  beq !nkey+
  cmp #KEY_P
  beq !pkey+
  cmp #KEY_Q
  beq !qkey+
  cmp #KEY_Y
  beq !ykey+
  cmp #KEY_Z
  beq !zkey+
  rts

!return:
  jmp HandleReturnKey
!delete:
  jmp HandleDeleteKey
!mkey:
  jmp HandleMKey
!nkey:
  jmp HandleNKey
!pkey:
  jmp HandlePKey
!qkey:
  jmp HandleQKey
!ykey:
  jmp HandleYKey
!zkey:
  jmp HandleZKey

// Jump tables for column and number keys (address - 1 for RTS trick)
ColumnKeyTable:
  .word HandleAKey - 1, HandleBKey - 1, HandleCKey - 1, HandleDKey - 1
  .word HandleEKey - 1, HandleFKey - 1, HandleGKey - 1, HandleHKey - 1

NumberKeyTable:
  .word Handle1Key - 1, Handle2Key - 1, Handle3Key - 1, Handle4Key - 1
  .word Handle5Key - 1, Handle6Key - 1, Handle7Key - 1, Handle8Key - 1

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
  ldx #$00                // X=0: ONE_PLAYER, BLACK, LevelSelectMenu
  jmp HandleNumberKeyCommon

/*
The 2 key serves a few purposes: player selection, color selection and row selection during gameplay
*/
Handle2Key:
  ldx #$01                // X=1: TWO_PLAYERS, WHITE, ColorSelectMenu
  // Fall through to HandleNumberKeyCommon

/*
Common handler for 1/2 keys in menus
Input: X = 0 for key 1, X = 1 for key 2
*/
HandleNumberKeyCommon:
  lda currentmenu
  cmp #MENU_PLAYER_SELECT
  beq !playerselect+
  cmp #MENU_COLOR_SELECT
  beq !colorselect+
  cmp #MENU_GAME
  beq !rowselect+
  rts

!playerselect:
  inx                     // X becomes 1 (ONE_PLAYER) or 2 (TWO_PLAYERS)
  stx numplayers
  dex
  beq !oneplayer+
  jmp ColorSelectMenu     // 2 players -> color select
!oneplayer:
  jmp LevelSelectMenu     // 1 player -> level select

!colorselect:
  stx player1color        // X=0 (BLACK) or X=1 (WHITE)
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
