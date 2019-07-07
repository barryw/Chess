#importonce
#import "board.asm"

*=* "Routines"

/*
Turn on and position all 8 sprites. We spread them out every 24 pixels and
place them on the first row. The multiplexer is responsible for moving them
to subsequent rows.
*/
SetupSprites:
  lda #$ff
  sta vic.SPENA
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
  lda #$00
  sta vic.SPENA
  rts

/*
Turn on the custom characters
*/
SetupCharacters:
  lda vic.VMCSB
  and #$f0
  ora #$0d
  sta vic.VMCSB
  lda #$35
  sta $01

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
  lda #$17
  sta vic.VMCSB

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
  lda Columns, y
  sta $07c1,x
  inx
  inx
  inx
  iny
  cpy #$09
  bne !loop-

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
  and #$f0              // Get the upper nybble first
  lsr
  lsr
  lsr
  lsr
  adc #$30
  ldy #$00
  sta (printvector),y
  iny
  lda num1
  and #$0f              // Get the lower nybble
  adc #$30
  sta (printvector),y
  pla
  tay
  rts

/*
Display the "Thinking" message with an indeterminate progress bar. This is shown
when the computer is determining its best move.
*/
ShowThinking:
  CopyMemory(ThinkingStart, ScreenAddress(ThinkingPos), ThinkingEnd - ThinkingStart)
  FillMemory(ColorAddress(ThinkingPos), ThinkingEnd - ThinkingStart, $01)
  lda #$80
  sta playclockrunning
  sta spinnerenabled
  rts

/*
Hide the "Thinking" message when the computer is ready to move
*/
HideThinking:
  FillMemory(ColorAddress(ThinkingPos), ThinkingEnd - ThinkingStart, $00)
  lda #$00
  sta playclockrunning
  sta spinnerenabled
  rts

/*
Update the counts of captured pieces for the current player
*/
UpdateCaptureCounts:
  lda #$00
  sta playclockrunning
  StoreWord(printvector, ScreenAddress(CapturedCountStart))
  ldy #$00
  lda currentplayer
  cmp #WHITES_TURN
  beq !whitecaptured+
!blackcaptured:
  StoreWord(capturedvector, blackcaptured)
  jmp !print+
!whitecaptured:
  StoreWord(capturedvector, whitecaptured)
!print:
  lda (capturedvector), y
  sta num1
  jsr PrintByte
  lda printvector
  clc
  adc #$28
  sta printvector
  iny
  cpy #$05
  bne !print-

  lda #$80
  sta playclockrunning

  rts

/*
Calculate the board offset for the movefrom coordinate
*/
ComputeMoveFromOffset:
  lda movefrom + $01
  asl
  asl
  asl
  clc
  adc movefrom
  sta movefromindex

  rts

/*
Calculate the board offset for the moveto coordinate
*/
ComputeMoveToOffset:
  lda moveto + $01
  asl
  asl
  asl
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
  lda #$80              // Show the cursor
  sta showcursor

  rts

/*
Validate that the selected movefrom location contains a piece of the correct color
*/
ValidateFrom:
  ldx movefromindex     // Get the piece at the selected location
  lda BoardState, x
  cmp #EMPTY_PIECE      // Is it an empty square?
  beq !emptysquare+
  and #$80
  clc
  rol
  rol
  cmp currentplayer
  bne !notyourpiece+

  ldx movefromindex
  lda BoardState, x
  sta selectedpiece

  lda #$80              // Start flashing the selected piece
  sta flashpiece

  jsr DisplayMoveToPrompt

  jmp !exit+
!notyourpiece:
  CopyMemory(NotYourPieceStart, ScreenAddress(ErrorPos), NotYourPieceEnd - NotYourPieceStart)
  FillMemory(ColorAddress(ErrorPos), NotYourPieceEnd - NotYourPieceStart, WHITE)
  jmp !clearinput+
!emptysquare:
  CopyMemory(NoPieceStart, ScreenAddress(ErrorPos), NoPieceEnd - NoPieceStart)
  FillMemory(ColorAddress(ErrorPos), NoPieceEnd - NoPieceStart, WHITE)
!clearinput:
  jsr ResetInput
  lda #$80
  sta movefromindex
  lda #$00
  sta selectedpiece

!exit:
  rts

/*
Validate that the selected moveto location is valid for the piece selected
*/
ValidateMove:
  rts
