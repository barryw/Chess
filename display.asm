// Display Functions
// Non-menu screen updates: status, captured pieces, prompts, thinking indicator

*=* "Display"

/*
Display the "Thinking" message with an indeterminate progress bar. This is shown
when the computer is determining its best move.
*/
ShowThinking:
  FillMemory(ScreenAddress(InteractionLinePos), $0e, $20)
  PrintAt(ThinkingText, ThinkingPos, WHITE)
  lda #TIMER_SPINNER
  jsr EnableTimer
  Disable(showcursor)
  lda #TIMER_FLASH_CURSOR
  jsr DisableTimer
  rts

/*
Hide the "Thinking" message when the computer is ready to move
Also clears the depth and best move display lines
*/
HideThinking:
  FillMemory(ColorAddress(ThinkingPos), $08, BLACK)
  FillMemory(ColorAddress(ThinkingDepthPos), $0e, BLACK)
  FillMemory(ColorAddress(ThinkingBestPos), $0e, BLACK)
  lda #TIMER_SPINNER
  jsr DisableTimer
  rts

/*
Update the thinking display showing current search depth and best move found.
Call this after each completed iteration in iterative deepening.

Uses: IterDepth (current depth), BestMoveFrom, BestMoveTo
Clobbers: A, X, Y, temp1, temp2
*/
UpdateThinkingDisplay:
  // Display "Depth: X"
  PrintAt(ThinkingDepthText, ThinkingDepthPos, WHITE)

  // Print depth as single digit (1-8)
  lda IterDepth
  clc
  adc #$30              // Convert to ASCII digit
  sta ScreenAddress(ThinkingDepthPos) + 7  // After "Depth: "
  lda #WHITE
  sta ColorAddress(ThinkingDepthPos) + 7

  // Display "Best:  " prefix
  PrintAt(ThinkingBestText, ThinkingBestPos, WHITE)

  // Convert BestMoveFrom to algebraic (e.g., "e2")
  lda BestMoveFrom
  jsr SquareToAlgebraic
  // A = file char, X = rank char
  sta ScreenAddress(ThinkingBestPos) + 7   // File letter (a-h)
  stx ScreenAddress(ThinkingBestPos) + 8   // Rank digit (1-8)
  lda #WHITE
  sta ColorAddress(ThinkingBestPos) + 7
  sta ColorAddress(ThinkingBestPos) + 8

  // Display "-" separator
  lda #'-'
  sta ScreenAddress(ThinkingBestPos) + 9
  lda #WHITE
  sta ColorAddress(ThinkingBestPos) + 9

  // Convert BestMoveTo to algebraic
  lda BestMoveTo
  and #$7f              // Clear promotion flag if present
  jsr SquareToAlgebraic
  sta ScreenAddress(ThinkingBestPos) + 10  // File letter
  stx ScreenAddress(ThinkingBestPos) + 11  // Rank digit
  lda #WHITE
  sta ColorAddress(ThinkingBestPos) + 10
  sta ColorAddress(ThinkingBestPos) + 11

  rts

/*
Convert a 0x88 square index to algebraic notation characters.
Input: A = 0x88 square index
Output: A = file char ('a'-'h')
        X = rank char ('1'-'8')
Clobbers: temp1
*/
SquareToAlgebraic:
  sta temp1             // Save square

  // Extract file (column) = square & $07
  and #$07
  clc
  adc #'a'              // Convert 0-7 to 'a'-'h'
  pha                   // Save file char

  // Extract rank = 8 - (square >> 4)
  lda temp1
  lsr
  lsr
  lsr
  lsr                   // square >> 4 = row 0-7
  eor #$07              // Invert: 0->7, 7->0
  clc
  adc #'1'              // Convert to '1'-'8'
  tax                   // Rank in X

  pla                   // File in A
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
Show the status line under the title and copyright. It includes which player is currently playing
as well as a play clock for that player.
*/
ShowStatus:
  PrintAt(TurnText, TurnPos, WHITE)
  PrintAt(TimeText, TimePos, WHITE)

  FillMemory(ScreenAddress(StatusSepPos), $0e, $77)
  FillMemory(ColorAddress(StatusSepPos), $0e, WHITE)

  rts

/*
Show the portion of the screen that details which pieces have been captured by the current player
*/
ShowCaptured:
  PrintAt(CapturedText, CapturedPos, WHITE)

  CopyMemory(CapturedUnderlineStart, ScreenAddress(CapturedUnderlinePos), CapturedUnderlineEnd - CapturedUnderlineStart)
  FillMemory(ColorAddress(CapturedUnderlinePos), CapturedUnderlineEnd - CapturedUnderlineStart, WHITE)

  PrintAt(CapturedPawnText, CapturedPawnPos, WHITE)
  PrintAt(CapturedKnightText, CapturedKnightPos, WHITE)
  PrintAt(CapturedBishopText, CapturedBishopPos, WHITE)
  PrintAt(CapturedRookText, CapturedRookPos, WHITE)
  PrintAt(CapturedQueenText, CapturedQueenPos, WHITE)

  rts

/*
If the current player's king is in check, display a helpful message
*/
ShowKingInCheck:
  jeq currentplayer:#WHITES_TURN:!white+

!black:
  ldx #BLACK
  jmp !continue+

!white:
  ldx #WHITE

!continue:
  jne incheckflags, x:#ENABLE:!exit+
  PrintAt(KingInCheckText, KingInCheckPos, WHITE)

!exit:
  rts

/*
Figure out whose turn it is and update the status lines.
*/
UpdateCurrentPlayer:
  stb #$3c:subseconds   // Reset subsecond count
  jeq numplayers:#ONE_PLAYER:!oneplayer+

!twoplayers:
  stb #WHITE:ColorAddress(PlayerNumberPos)
  jeq player1color:currentplayer:!playeronesturn+

!playertwosturn:
  stb #'2':ScreenAddress(PlayerNumberPos)
  jmp !playersturn+
!playeronesturn:
  stb #'1':ScreenAddress(PlayerNumberPos)
  jmp !playersturn+

!oneplayer:
  stb #BLACK:ColorAddress(PlayerNumberPos)
  jeq player1color:currentplayer:!playersturn+

!computersturn:
  FillMemory(ScreenAddress(TurnValuePos), $08, $20)  // Clear the turn value area
  PrintAt(ComputerText, TurnValuePos, WHITE)
  jsr ShowThinking      // Enable the spinner to show that the computer is thinking
  jmp !return+

!playersturn:
  FillMemory(ScreenAddress(TurnValuePos), $08, $20)  // Clear the turn value area
  PrintAt(PlayerText, TurnValuePos, WHITE)
  jsr HideThinking      // If it's the players turn, disable the spinner

!return:
  rts

/*
Display the prompt to allow the player to enter the coordinates of the piece to move.
*/
DisplayMoveFromPrompt:
  PrintAt(MoveFromText, MovePos, WHITE)

  SetInputSelection(INPUT_MOVE_FROM)

  jsr ResetInput

  Enable(showcursor)
  lda #TIMER_FLASH_CURSOR
  jsr EnableTimer

  rts

/*
Display the prompt to allow the player to enter the coordinates of where to move the
selected piece.
*/
DisplayMoveToPrompt:
  PrintAt(MoveToText, MovePos, WHITE)

  SetInputSelection(INPUT_MOVE_TO)

  jsr ResetInput

  Enable(showcursor)
  lda #TIMER_FLASH_CURSOR
  jsr EnableTimer

  rts

