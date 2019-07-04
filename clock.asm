/*
If the game has started, show the clock for the current player
*/
ShowClock:
  lda currentmenu       // Are we in a game?
  cmp #MENU_GAME
  beq !checksubseconds+
  rts

!checksubseconds:
  lda subseconds        // Have subseconds reached 0?
  cmp #$01
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
  lda blackseconds
  sta num1
  StoreWord(printvector, ScreenAddress(SecondsPos))
  jsr PrintByte
  lda blackminutes
  sta num1
  StoreWord(printvector, ScreenAddress(MinutesPos))
  jsr PrintByte
  lda blackhours
  sta num1
  StoreWord(printvector, ScreenAddress(HoursPos))
  jsr PrintByte
  jmp !return+

!showwhiteclock:
  lda whiteseconds
  sta num1
  StoreWord(printvector, ScreenAddress(SecondsPos))
  jsr PrintByte
  lda whiteminutes
  sta num1
  StoreWord(printvector, ScreenAddress(MinutesPos))
  jsr PrintByte
  lda whitehours
  sta num1
  StoreWord(printvector, ScreenAddress(HoursPos))
  jsr PrintByte

!return:
  rts

/*
Update the clock for the current player
*/
UpdateClock:
  lda currentmenu       // Are we in a game?
  cmp #MENU_GAME
  bne !return+

!updateclock:
  dec subseconds
  bne !return+
  lda #$3c
  sta subseconds
  lda currentplayer
  cmp #WHITES_TURN
  beq !updatewhiteclock+

!updateblackclock:
  sed
  clc
  lda blackseconds
  adc #$01
  sta blackseconds
  cmp #$60              // Have we hit 60 seconds?
  bne !return+
  lda #$00              // Yup. Reset seconds and increment minutes
  sta blackseconds
  clc
  lda blackminutes
  adc #$01
  sta blackminutes
  cmp #$60              // Have we hit 60 minutes?
  bne !return+
  lda #$00              // Yup. Reset minutes and increment hours
  sta blackminutes
  clc
  lda blackhours
  adc #$01
  sta blackhours
  cld
  jmp !return+

!updatewhiteclock:
  sed
  clc
  lda whiteseconds
  adc #$01
  sta whiteseconds
  cmp #$60
  bne !return+
  lda #$00
  sta whiteseconds
  clc
  lda whiteminutes
  adc #$01
  sta whiteminutes
  cmp #$60
  bne !return+
  lda #$00
  sta whiteminutes
  clc
  lda whitehours
  adc #$01
  sta whitehours
  cld

!return:
  rts
