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
  cmp #WHITES_TURN      // Whose turn is it?
  beq !showwhiteclock+

!showblackclock:
  ldx #BLACK_CLOCK_POS  // Set the position to show the black clock
  jmp !doshow+

!showwhiteclock:
  ldx #WHITE_CLOCK_POS  // Set the position to show the white clock

!doshow:
  ldy #$00
!showloop:
  lda timers, x         // Get the correct position in the timers structure
  sta num1              // White clock is the first 3 bytes, black the last 3
  lda timerpositions, y
  sta printvector
  iny
  lda timerpositions, y
  sta printvector + 1
  jsr PrintByte         // Print the 2 byte BCD digit for this position
  inx
  iny
  cpx #$03              // hours, minutes and seconds
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
  lda currentplayer     // Whose turn is it?
  cmp #WHITES_TURN
  beq !updatewhiteclock+

!updateblackclock:
  ldx #BLACK_CLOCK_POS  // Black player is up
  jmp !doupdate+

!updatewhiteclock:
  ldx #WHITE_CLOCK_POS  // White player is up

!doupdate:
  sed                   // All of our numbers are in BCD.
!updatetimers:
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
  bne !updatetimers-

!return:
  cld
  rts
