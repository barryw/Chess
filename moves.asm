/*
Check to see if the selected piece has any moves.
*/
HasValidMoves:


/*
Validate that the selected movefrom location contains a piece of the correct color
*/
ValidateFrom:
  clf movefromisvalid
  ldx movefromindex     // Get the piece at the selected location
  jeq BoardState, x:#EMPTY_PIECE:!emptysquare+
  chk_mine !notyours+   // My piece?

  jsr FlashPieceOn      // Start flashing the selected piece
  jsr DisplayMoveToPrompt

  sef movefromisvalid

  jmp !exit+
!notyours:
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
  clf movetoisvalid     // Reset the valid move flag
  ldx movetoindex       // Is the destination an empty square?
  jeq BoardState, x:#EMPTY_SPR:!checkvalid+
  chk_mine !checkvalid+  // My piece?
!alreadyyours:
  CopyMemory(AlreadyYoursStart, ScreenAddress(ErrorPos), AlreadyYoursEnd - AlreadyYoursStart)
  FillMemory(ColorAddress(ErrorPos), AlreadyYoursEnd - AlreadyYoursStart, WHITE)
  jsr ResetInput
  stb #BIT8:movetoindex
  jmp !exit+

!checkvalid:
  jsr ValidateMove      // Are we good?
  bcs !isvalid+         // If the move is good, set the carry flag
  CopyMemory(InvalidMoveStart, ScreenAddress(ErrorPos), InvalidMoveEnd - InvalidMoveStart)
  FillMemory(ColorAddress(ErrorPos), InvalidMoveEnd - InvalidMoveStart, WHITE)
  jmp !exit+
!isvalid:
  sef movetoisvalid
!exit:
  rts

/*
Check to make sure the selected piece can move to the moveto location.

Carry Clear = invalid move
Carry Set = valid move
*/
ValidateMove:

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
