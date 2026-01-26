// Display Functions
// Non-menu screen updates: status, captured pieces, prompts, thinking indicator

*=* "Display"

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
Show the status line under the title and copyright. It includes which player is currently playing
as well as a play clock for that player.
*/
ShowStatus:
  CopyMemory(TurnStart, ScreenAddress(TurnPos), TurnEnd - TurnStart)
  FillMemory(ColorAddress(TurnPos), TurnEnd - TurnStart, WHITE)

  CopyMemory(TimeStart, ScreenAddress(TimePos), TimeEnd - TimeStart)
  FillMemory(ColorAddress(TimePos), TimeEnd - TimeStart, WHITE)

  FillMemory(ScreenAddress(StatusSepPos), $0e, $77)
  FillMemory(ColorAddress(StatusSepPos), $0e, WHITE)

  rts

/*
Show the portion of the screen that details which pieces have been captured by the current player
*/
ShowCaptured:
  CopyMemory(CapturedStart, ScreenAddress(CapturedPos), CapturedEnd - CapturedStart)
  FillMemory(ColorAddress(CapturedPos), CapturedEnd - CapturedStart, WHITE)

  CopyMemory(CapturedUnderlineStart, ScreenAddress(CapturedUnderlinePos), CapturedUnderlineEnd - CapturedUnderlineStart)
  FillMemory(ColorAddress(CapturedUnderlinePos), CapturedUnderlineEnd - CapturedUnderlineStart, WHITE)

  CopyMemory(CapturedPawnStart, ScreenAddress(CapturedPawnPos), CapturedPawnEnd - CapturedPawnStart)
  FillMemory(ColorAddress(CapturedPawnPos), CapturedPawnEnd - CapturedPawnStart, WHITE)

  CopyMemory(CapturedKnightStart, ScreenAddress(CapturedKnightPos), CapturedKnightEnd - CapturedKnightStart)
  FillMemory(ColorAddress(CapturedKnightPos), CapturedKnightEnd - CapturedKnightStart, WHITE)

  CopyMemory(CapturedBishopStart, ScreenAddress(CapturedBishopPos), CapturedBishopEnd - CapturedBishopStart)
  FillMemory(ColorAddress(CapturedBishopPos), CapturedBishopEnd - CapturedBishopStart, WHITE)

  CopyMemory(CapturedRookStart, ScreenAddress(CapturedRookPos), CapturedRookEnd - CapturedRookStart)
  FillMemory(ColorAddress(CapturedRookPos), CapturedRookEnd - CapturedRookStart, WHITE)

  CopyMemory(CapturedQueenStart, ScreenAddress(CapturedQueenPos), CapturedQueenEnd - CapturedQueenStart)
  FillMemory(ColorAddress(CapturedQueenPos), CapturedQueenEnd - CapturedQueenStart, WHITE)

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
  CopyMemory(KingInCheckStart, ScreenAddress(KingInCheckPos), KingInCheckEnd - KingInCheckStart)
  FillMemory(ColorAddress(KingInCheckPos), KingInCheckEnd - KingInCheckStart, WHITE)

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
  CopyMemory(ComputerStart, ScreenAddress(TurnValuePos), ComputerEnd - ComputerStart)
  FillMemory(ColorAddress(TurnValuePos), ComputerEnd - ComputerStart, WHITE)
  jsr ShowThinking      // Enable the spinner to show that the computer is thinking
  jmp !return+

!playersturn:
  CopyMemory(PlayerStart, ScreenAddress(TurnValuePos), PlayerEnd - PlayerStart)
  FillMemory(ColorAddress(TurnValuePos), PlayerEnd - PlayerStart, WHITE)
  jsr HideThinking      // If it's the players turn, disable the spinner

!return:
  rts

/*
Display the prompt to allow the player to enter the coordinates of the piece to move.
*/
DisplayMoveFromPrompt:
  CopyMemory(MoveFromStart, ScreenAddress(MovePos), MoveFromEnd - MoveFromStart)
  FillMemory(ColorAddress(MovePos), MoveFromEnd - MoveFromStart, WHITE)

  SetInputSelection(INPUT_MOVE_FROM)

  jsr ResetInput

  Enable(showcursor)

  rts

/*
Display the prompt to allow the player to enter the coordinates of where to move the
selected piece.
*/
DisplayMoveToPrompt:
  CopyMemory(MoveToStart, ScreenAddress(MovePos), MoveToEnd - MoveToStart)
  FillMemory(ColorAddress(MovePos), MoveToEnd - MoveToStart, WHITE)

  SetInputSelection(INPUT_MOVE_TO)

  jsr ResetInput

  rts
