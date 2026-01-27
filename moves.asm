/*
Check to see if the selected piece has any moves. We don't even want the player to
be able to select a piece if it can't move anywhere.

Carry Clear = no moves
Carry Set = 1 or more valid moves
*/
HasValidMoves:
  ldx movefromindex
  lda BoardState, x

  sec

  rts

/*
Check to make sure the selected piece can move to the moveto location.

Carry Clear = invalid move
Carry Set = valid move
*/
ValidateMove:

  sec

  rts

/*
Validate that the selected movefrom location contains a piece of the correct color
*/
ValidateFrom:
  clf movefromisvalid
  ldx movefromindex     // Get the piece at the selected location
  chk_empty !emptysquare+
  chk_mine !notyours+   // My piece?

  jsr HasValidMoves     // Does this piece have valid moves?
  bcs !moveisvalid+
  jmp !novalidmoves+

!moveisvalid:
  jsr FlashPieceOn      // Start flashing the selected piece
  jsr DisplayMoveToPrompt
  sef movefromisvalid   // Set the 'movefromisvalid' flag

  jmp !exit+
!emptysquare:
  PrintAt(NoPieceText, ErrorPos, WHITE)
  jmp !clearinput+
!notyours:
  PrintAt(NotYourPieceText, ErrorPos, WHITE)
  jmp !clearinput+
!novalidmoves:
  PrintAt(NoMovesText, ErrorPos, WHITE)
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
  chk_empty !checkvalid+ // Empty square?
  chk_mine !checkvalid+  // My piece?
!alreadyyours:
  PrintAt(AlreadyYoursText, ErrorPos, WHITE)
  jsr ResetInput
  stb #BIT8:movetoindex
  jmp !exit+

!checkvalid:
  jsr ValidateMove      // Are we good?
  bcs !isvalid+         // If the move is good, set the carry flag
  PrintAt(InvalidMoveText, ErrorPos, WHITE)
  jmp !exit+
!isvalid:
  sef movetoisvalid
!exit:
  rts

/*
After we've validated that this is a valid move, do the bit shuffling. If there's
a piece in moveto, capture it first and then move the piece.
*/
MovePiece:
  jsr FlashPieceOff     // Turn off the flashing of the selected piece
  ldx movetoindex
  chk_empty !movepiece+ // If there's no piece in moveto, just move our piece
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
Check to see if the current player's king is in check.
*/
CheckKingInCheck:
  rts
