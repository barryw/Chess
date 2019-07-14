/*
If the game has started, show the clock for the current player
*/
ShowClock:
  jne currentmenu:#MENU_GAME:!return+

!showclock:
  FillMemory(ColorAddress(HoursPos), $08, WHITE)
  lda #':'
  sta ScreenAddress(Colon1Pos)
  sta ScreenAddress(Colon2Pos)
  jeq currentplayer:#WHITES_TURN:!showwhiteclock+

!showblackclock:
  ldx #BLACK_CLOCK_POS  // Set the position to show the black clock
  jmp !doshow+

!showwhiteclock:
  ldx #WHITE_CLOCK_POS  // Set the position to show the white clock

!doshow:
  ldy #$00
  CopyWord(printvector, temp1)
  CopyWord(num1, temp2)
!showloop:
  stb timers, x:num1
  stb timerpositions, y:printvector
  iny
  stb timerpositions, y:printvector + $01
  jsr PrintByte         // Print the 2 byte BCD digit for this position
  inx
  iny
  cpy #$06              // hours, minutes and seconds
  bne !showloop-
  CopyWord(temp2, num1)
  CopyWord(temp1, printvector)
!return:
  rts

/*
Update the clock for the current player
*/
UpdateClock:
  jne currentmenu:#MENU_GAME:!return+
  bfc playclockrunning:!return+

!updateclock:
  dec subseconds
  bne !return+
  stb #$3c:subseconds
  jeq currentplayer:#WHITES_TURN:!updatewhiteclock+

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
  cld

!return:
  rts
