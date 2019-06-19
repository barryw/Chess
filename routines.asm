#importonce
#import "board.asm"

*=* "Routines"

// Set the initial positions of the 8 sprites
SetupSprites:
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

// Bring in the custom characters
SetupCharacters:
  lda vic.VMCSB
  and #$f0
  ora #$0d
  sta vic.VMCSB
  lda #$35
  sta $01

  rts

SetupScreen:
  jsr ClearScreen
  lda #$00
  sta vic.BGCOL0
  sta vic.EXTCOL
  lda #$17
  sta vic.VMCSB

  ldx #$00
drawloop:
  lda Board,x
  sta vic.CLRRAM,x
  lda Board+$0100,x
  sta vic.CLRRAM+$0100,x
  lda Board+$0200,x
  sta vic.CLRRAM+$0200,x
  lda Board+$0300,x
  sta vic.CLRRAM+$0300,x
  lda #224
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  inx
  bne drawloop

  ldx #$00
  ldy #$00
drawcolumns:
  lda Columns, y
  sta $07c1,x
  inx
  inx
  inx
  iny
  cpy #$09
  bne drawcolumns

  lda #'8'
  sta $0440
  lda #'7'
  sta $04b8
  lda #'6'
  sta $0530
  lda #'5'
  sta $05a8
  lda #'4'
  sta $0620
  lda #'3'
  sta $0698
  lda #'2'
  sta $0710
  lda #'1'
  sta $0788

  // Display the title
  CopyMemory(TitleRow1Start, ScreenAddress(Title1Pos), TitleRow1End - TitleRow1Start)
  CopyMemory(TitleRow1ColorStart, ColorAddress(Title1Pos), TitleRow1ColorEnd - TitleRow1ColorStart)
  CopyMemory(TitleRow2Start, ScreenAddress(Title2Pos), TitleRow2End - TitleRow2Start)
  CopyMemory(TitleRow2ColorStart, ColorAddress(Title2Pos), TitleRow2ColorEnd - TitleRow2ColorStart)

  // Display the copyright
  CopyMemory(CopyrightStart, ScreenAddress(CopyrightPos), CopyrightEnd - CopyrightStart)
  CopyMemory(CopyrightColorStart, ColorAddress(CopyrightPos), CopyrightColorEnd - CopyrightColorStart)

  // Display the Play Game menu option
  CopyMemory(PlayStart, ScreenAddress(PlayGamePos), PlayEnd - PlayStart)
  CopyMemory(PlayColorStart, ColorAddress(PlayGamePos), PlayColorEnd - PlayColorStart)

  // Display the Quit Game menu option
  CopyMemory(QuitStart, ScreenAddress(QuitGamePos), QuitEnd - QuitStart)
  CopyMemory(QuitColorStart, ColorAddress(QuitGamePos), QuitColorEnd - QuitColorStart)

  rts

// Clear the screen by storing space directly to screen memory
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

HandleQuit:
  lda isquitting
  cmp #$00
  bne alreadyquitting
  lda #$01
  sta isquitting
  CopyMemory(QuitConfirmationStart, ScreenAddress(QuitConfirmPos), QuitConfirmationEnd - QuitConfirmationStart)
  CopyMemory(QuitConfirmationColorStart, ColorAddress(QuitConfirmPos), QuitConfirmationColorEnd - QuitConfirmationColorStart)
alreadyquitting:
  rts

// Reset the C64
ConfirmQuit:
  lda isquitting
  cmp #$01
  beq DoQuit
  rts
DoQuit:
  lda #$37 // Swap the kernal back in
  sta $01
  jsr $fce2 // call the reset vector

// The user has decided that they don't want to quit
QuitAbort:
  lda #$00
  sta isquitting
  CopyMemory(EmptyRowStart, ScreenAddress(QuitConfirmPos), QuitConfirmationEnd - QuitConfirmationStart)
  rts

// Let's Rock!
StartGame:
  CopyMemory(PlayerSelectStart, ScreenAddress(PlayerSelectPos), PlayerSelectEnd - PlayerSelectStart)
  CopyMemory(PlayerSelectColorStart, ColorAddress(PlayerSelectPos), PlayerSelectColorEnd - PlayerSelectColorStart)
  rts

OnePlayer:

TwoPlayer:
  rts

// Depending on who's playing, show their game clock
DisplayGameClock:
  lda currentplayer
  cmp #$00
  beq ShowWhiteClock

ShowWhiteClock:
  rts
