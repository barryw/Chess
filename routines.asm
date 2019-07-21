#importonce
#import "board.asm"

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
Display the "Thinking" message with an indeterminate progress bar. This is shown
when the computer is determining its best move.
*/
ShowThinking:
  FillMemory(ScreenAddress(InteractionLinePos), $0e, $20)
  CopyMemory(ThinkingStart, ScreenAddress(ThinkingPos), ThinkingEnd - ThinkingStart)
  FillMemory(ColorAddress(ThinkingPos), ThinkingEnd - ThinkingStart, WHITE)
  Enable(spinnerenabled)
  Disable(showcursor)
  rts

/*
Hide the "Thinking" message when the computer is ready to move
*/
HideThinking:
  FillMemory(ColorAddress(ThinkingPos), ThinkingEnd - ThinkingStart, BLACK)
  Disable(spinnerenabled)
  rts

/*
Update the counts of captured pieces for the current player
*/
UpdateCaptureCounts:
  StoreWord(printvector, ScreenAddress(CapturedCountStart))
  ldy #$00
  jeq currentplayer:#WHITES_TURN:!whitecaptured+
!blackcaptured:
  StoreWord(capturedvector, blackcaptured)
  jmp !print+
!whitecaptured:
  StoreWord(capturedvector, whitecaptured)
!print:
  stb (capturedvector), y:num1
  jsr PrintByte
  lda printvector
  clc
  adc #$28
  sta printvector
  iny
  cpy #$05
  bne !print-
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

/*
Validate that the selected movefrom location contains a piece of the correct color
*/
ValidateFrom:
  clf movefromisvalid
  ldx movefromindex     // Get the piece at the selected location
  jeq BoardState, x:#EMPTY_PIECE:!emptysquare+
  and #BIT8             // Shift the color bit (the high bit) around to bit 0
  clc                   // so that we can compare it to the current player
  rol
  rol
  cmp currentplayer     // Does it belong to the current player?
  bne !notyourpiece+

  jsr FlashPieceOn      // Start flashing the selected piece
  jsr DisplayMoveToPrompt

  sef movefromisvalid

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
  stb #BIT8:movefromindex

!exit:
  rts

/*
Validate that the selected moveto location is valid for the piece selected
*/
ValidateTo:
  clf movetoisvalid       // Reset the valid move flag
  ldx movetoindex       // Is the destination an empty square?
  jeq BoardState, x:#EMPTY_SPR:!validmove+
  and #BIT8             // Is it one of our own pieces?
  clc
  rol
  rol
  cmp currentplayer
  bne !validmove+
!alreadyyours:
  CopyMemory(AlreadyYoursStart, ScreenAddress(ErrorPos), AlreadyYoursEnd - AlreadyYoursStart)
  FillMemory(ColorAddress(ErrorPos), AlreadyYoursEnd - AlreadyYoursStart, WHITE)
  jsr ResetInput
  stb #BIT8:movetoindex
  jmp !exit+

!validmove:
  sef movetoisvalid       // Move is valid
!exit:
  rts

/*
After we've validated that this is a valid move, do the bit shuffling. If there's
a piece in moveto, capture it first and then move the piece.
*/
MovePiece:
  jsr FlashPieceOff     // Turn off the flashing of the selected piece
  ldx movetoindex
  jeq BoardState, x:#EMPTY_SPR:!movepiece+
  and #LOWER7           // Strip color information
  cmp #PAWN_SPR         // Capture a pawn?
  beq !capturepawn+
  cmp #KNIGHT_SPR       // A knight?
  beq !captureknight+
  cmp #BISHOP_SPR       // A bishop?
  beq !capturebishop+
  cmp #ROOK_SPR         // A rook?
  beq !capturerook+
  cmp #QUEEN_SPR        // A queen?
  beq !capturequeen+
  jmp !movepiece+

!capturepawn:
  ldx #CAP_PAWN
  jmp !capturepiece+
!captureknight:
  ldx #CAP_KNIGHT
  jmp !capturepiece+
!capturebishop:
  ldx #CAP_BISHOP
  jmp !capturepiece+
!capturerook:
  ldx #CAP_ROOK
  jmp !capturepiece+
!capturequeen:
  ldx #CAP_QUEEN
!capturepiece:
  jne currentplayer:#WHITES_TURN:!incrementblack+
  inc whitecaptured, x
  jmp !movepiece+
!incrementblack:
  inc blackcaptured, x
!movepiece:
  ldx movetoindex       // Move it to the moveto location
  stb selectedpiece:BoardState, x
  ldx movefromindex     // Empty the movefrom location
  stb #EMPTY_SPR:BoardState, x
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

/*
Check to see if the current player's king is in check.
*/
CheckKingInCheck:
  rts
