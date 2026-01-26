*=* "Routines"

/*
Turn on and position all 8 sprites. We spread them out every 24 pixels and
place them on the first row. The multiplexer is responsible for moving them
to subsequent rows.
*/
SetupSprites:
  stb #$ff:vic.SPENA
  ldx #$00
  stx counter
  lda #PIECE_WIDTH
storex:
  sta vic.SP0X,x
  clc
  adc #PIECE_WIDTH
  inx
  inx
  cpx #$10
  bne storex

  rts

/*
Disable all sprites
*/
DisableSprites:
  stb #$00:vic.SPENA
  rts

/*
Turn on the custom characters
*/
SetupCharacters:
  stb #$1d:vic.VMCSB
  stb #$35:$01

  rts

/*
Clear the screen
*/
ClearScreen:
  ldx #$ff
  lda #$20
clrloop:
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  dex
  bne clrloop
  rts

/*
Set up the chess board
*/
SetupScreen:
  jsr ClearScreen
  lda #$00
  sta vic.BGCOL0
  sta vic.EXTCOL
  stb #$17:vic.VMCSB

  ldx #$00
!loop:
  lda Board,x
  sta vic.CLRRAM,x
  lda Board+$0100,x
  sta vic.CLRRAM+$0100,x
  lda Board+$0200,x
  sta vic.CLRRAM+$0200,x
  lda Board+$0300,x
  sta vic.CLRRAM+$0300,x
  lda #$e0
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  inx
  bne !loop-

  ldx #$00
  ldy #$00
!loop:
  stb Columns, y:$07c1, x
  inx
  inx
  inx
  iny
  cpy #$09
  bne !loop-

  stb #'8':ScreenAddress(ScreenPos($18, $01))
  stb #'7':ScreenAddress(ScreenPos($18, $04))
  stb #'6':ScreenAddress(ScreenPos($18, $07))
  stb #'5':ScreenAddress(ScreenPos($18, $0a))
  stb #'4':ScreenAddress(ScreenPos($18, $0d))
  stb #'3':ScreenAddress(ScreenPos($18, $10))
  stb #'2':ScreenAddress(ScreenPos($18, $13))
  stb #'1':ScreenAddress(ScreenPos($18, $16))

  // Display the title
  CopyMemory(TitleRow1Start, ScreenAddress(Title1Pos), TitleRow1End - TitleRow1Start)
  CopyMemory(TitleRow1ColorStart, ColorAddress(Title1Pos), TitleRow1ColorEnd - TitleRow1ColorStart)
  CopyMemory(TitleRow2Start, ScreenAddress(Title2Pos), TitleRow2End - TitleRow2Start)
  CopyMemory(TitleRow2ColorStart, ColorAddress(Title2Pos), TitleRow2ColorEnd - TitleRow2ColorStart)

  // Display the copyright
  CopyMemory(CopyrightStart, ScreenAddress(CopyrightPos), CopyrightEnd - CopyrightStart)
  FillMemory(ColorAddress(CopyrightPos), CopyrightEnd - CopyrightStart, WHITE)

  jmp StartMenu

/*
Print out a byte as 2 digits. This assumes that the byte is stored as BCD
with the upper nybble containing the 10s value and the lower nybble containing
the 1s value. The digits are written to the location pointed at by printvector
*/
PrintByte:
  tya
  pha
  lda num1
  pha
  and #$f0              // Get the upper nybble first
  lsr
  lsr
  lsr
  lsr
  adc #$30
  ldy #$00
  sta (printvector),y
  iny
  pla
  and #$0f              // Get the lower nybble
  adc #$30
  sta (printvector),y
  pla
  tay
  rts

/*
Calculate the board offset for the movefrom coordinate
*/
ComputeMoveFromOffset:
  lda movefrom + $01
  mult8
  clc
  adc movefrom
  sta movefromindex

  rts

/*
Calculate the board offset for the moveto coordinate
*/
ComputeMoveToOffset:
  lda moveto + $01
  mult8
  clc
  adc moveto
  sta movetoindex

  rts

/*
Clear the error line
*/
ClearError:
  FillMemory(ColorAddress(ErrorPos), $0e, BLACK)
  rts

/*
Reset the input for whatever position is being displayed
*/
ResetInput:
  ldy #$00              // Reset the cursor position
  sty cursorxpos
  lda #$20              // Put space characters in both coordinate locations
  sta (inputlocationvector), y
  iny
  sta (inputlocationvector), y

  rts

/*
Reset everything for the current player
*/
ResetPlayer:
  lda #$00              // Clear out movefrom and moveto
  sta movefrom
  sta movefrom + $01
  sta moveto
  sta moveto + $01

  lda #BIT8
  sta movefromindex     // Reset movefromindex and movetoindex
  sta movetoindex

  lda #$00
  sta movetoisvalid
  sta movefromisvalid

  rts
