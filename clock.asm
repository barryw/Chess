/*
If the game has started, show the clock for the current player
*/
ShowClock:
  lda currentmenu       // Are we in a game?
  cmp #MENU_GAME
  beq !checksubseconds+
  rts

!checksubseconds:
  lda subseconds        // Has the subsecond clock started?
  cmp #$3b
  beq !showclock+
  rts

!showclock:
  FillMemory(ColorAddress(HoursPos), $08, WHITE)
  lda #':'
  sta ScreenAddress(Colon1Pos)
  sta ScreenAddress(Colon2Pos)
  lda currentplayer
  cmp #WHITES_TURN
  beq !showwhiteclock+

!showblackclock:
  ldx #BLACK_CLOCK_POS  // Set the position to show the black clock
  jmp !doshow+

!showwhiteclock:
  ldx #WHITE_CLOCK_POS  // Set the position to show the white clock

!doshow:
  ldy #$00
!showloop:
  lda timers, x
  sta num1
  lda timerpositions, y
  sta printvector
  iny
  lda timerpositions, y
  sta printvector + 1
  jsr PrintByte         // Print the 2 byte BCD digit for this position
  inx
  iny
  cpx #$03
  bne !showloop-

!return:
  rts

/*
Update the clock for the current player
*/
UpdateClock:
  lda currentmenu       // Are we in a game?
  cmp #MENU_GAME
  bne !return+
  lda playclockrunning  // Is the play clock running?
  bpl !return+

!updateclock:
  dec subseconds
  bne !return+
  lda #$3c
  sta subseconds
  lda currentplayer
  cmp #WHITES_TURN
  beq !updatewhiteclock+

!updateblackclock:
  ldx #$03
  jmp !doupdate+

!updatewhiteclock:
  ldx #$00
  sed

!doupdate:
  clc
  lda timers, x
  adc #$01
  sta timers, x
  cmp #$60              // Have we hit 60 seconds/minutes/hours?
  bne !return+
  lda #$00              // Yup. Reset seconds and increment minutes/hours
  sta timers, x
  inx
  cpx #$02
  bne !doupdate-

!return:
  cld
  rts
