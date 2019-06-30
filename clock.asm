/*
If the game has started, show the clock for the current player
*/
ShowClock:
  lda currentmenu
  cmp #MENU_GAME
  beq !tracktime+
  rts

!tracktime:
  rts
