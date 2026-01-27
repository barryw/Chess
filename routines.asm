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

  // Clear color RAM to black and fill screen with background char
  ldx #$00
  lda #$00
!clearcolor:
  sta vic.CLRRAM,x
  sta vic.CLRRAM+$0100,x
  sta vic.CLRRAM+$0200,x
  sta vic.CLRRAM+$0300,x
  inx
  bne !clearcolor-

  ldx #$00
  lda #$e0
!fillscreen:
  sta $0400,x
  sta $0500,x
  sta $0600,x
  sta $0700,x
  inx
  bne !fillscreen-

  // Generate the checkerboard pattern (replaces ~960 bytes of static data)
  jsr GenerateBoardColors

  // Column letters at bottom (A-H)
  ldx #$00
  ldy #$00
!loop:
  stb Columns, y:$07c1, x
  lda #WHITE
  sta $dbc1, x            // Color RAM for bottom row
  inx
  inx
  inx
  iny
  cpy #$08
  bne !loop-

  // Row numbers (8-1) on the right side with their colors
  stb #'8':ScreenAddress(ScreenPos($18, $01))
  stb #WHITE:ColorAddress(ScreenPos($18, $01))
  stb #'7':ScreenAddress(ScreenPos($18, $04))
  stb #WHITE:ColorAddress(ScreenPos($18, $04))
  stb #'6':ScreenAddress(ScreenPos($18, $07))
  stb #WHITE:ColorAddress(ScreenPos($18, $07))
  stb #'5':ScreenAddress(ScreenPos($18, $0a))
  stb #WHITE:ColorAddress(ScreenPos($18, $0a))
  stb #'4':ScreenAddress(ScreenPos($18, $0d))
  stb #WHITE:ColorAddress(ScreenPos($18, $0d))
  stb #'3':ScreenAddress(ScreenPos($18, $10))
  stb #WHITE:ColorAddress(ScreenPos($18, $10))
  stb #'2':ScreenAddress(ScreenPos($18, $13))
  stb #WHITE:ColorAddress(ScreenPos($18, $13))
  stb #'1':ScreenAddress(ScreenPos($18, $16))
  stb #WHITE:ColorAddress(ScreenPos($18, $16))

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
  clc                   // Explicit clear before add
  adc #$30
  ldy #$00
  sta (printvector),y
  iny
  pla
  and #$0f              // Get the lower nybble
  clc                   // Explicit clear before add
  adc #$30
  sta (printvector),y
  pla
  tay
  rts

/*
Print a null-terminated string to screen with color.
Inputs:
  str_ptr   - pointer to null-terminated string
  scr_ptr   - pointer to screen memory location
  col_ptr   - pointer to color memory location
  print_color - color to use for all characters
*/
PrintString:
  ldy #$00
!loop:
  lda (str_ptr),y         // Get character from string
  beq !done+              // $00 = end of string
  sta (scr_ptr),y         // Write to screen RAM
  lda print_color         // Get the color
  sta (col_ptr),y         // Write to color RAM
  iny
  bne !loop-              // Loop (max 256 chars)
!done:
  rts

/*
Calculate board offset from coordinate pair.
Input: X = 0 for movefrom, X = 2 for moveto
Output: A = board index, stored in corresponding index variable
*/
ComputeBoardOffset:
  lda movefrom + $01, x   // Get row (movefrom+1 or moveto+1)
  mult16                  // row * 16 (0x88 indexing)
  clc
  adc movefrom, x         // + column
  cpx #$00
  bne !storeto+
  sta movefromindex
  rts
!storeto:
  sta movetoindex
  rts

/*
Calculate the board offset for the movefrom coordinate
*/
ComputeMoveFromOffset:
  ldx #$00
  jmp ComputeBoardOffset

/*
Calculate the board offset for the moveto coordinate
*/
ComputeMoveToOffset:
  ldx #$02
  jmp ComputeBoardOffset

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
