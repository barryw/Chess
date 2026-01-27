// Input Handling
// Processing player coordinate input for move from/to selections

*=* "Input"

/*
Handle the pressing of the return key. This key gets pressed when
the player has typed in the entire movefrom or moveto coordinates
*/
HandleReturnKey:
  jne currentmenu:#MENU_GAME:!exit+
  bfs processreturn:!exit+
  bfc showcursor:!exit+

  sef processreturn     // Set the flag indicating that we're already processing
                        // a press of the return key.

  bfs movefromisvalid:!validateto+
  bfs movetoisvalid:!movepiece+

!validatefrom:
  bfs movefromindex:!endreturn+
  jsr ValidateFrom      // Make sure this is a valid move
  jmp !endreturn+
!validateto:
  bfs movetoindex:!endreturn+
  jsr ValidateTo
  bfc movetoisvalid:!endreturn+
!movepiece:
  jsr MovePiece
  jsr ChangePlayers
!endreturn:
  clf processreturn     // Clear the return processing flag
!exit:
  rts

/*
Allow the user to correct their input
*/
HandleDeleteKey:
  ldy cursorxpos        // Is the cursor at the beginning of input?
  cpy #$00
  beq !exit+            // Yea. just exit since we can't delete anymore.
  stb #$20:(inputlocationvector),y
  dec cursorxpos
!exit:
  rts

/*
Deal with a row selection. This is the second part of the board coordinate.
*/
HandleRowSelection:
  jeq cursorxpos:#$00:!exit+
  lda currentkey
  sec
  sbc #$31              // Store the row 0 based instead of 1 based.
  tay
  lda rowlookup, y      // Invert the row numbers
  pha
  jne inputselection:#INPUT_MOVE_FROM:!moveto+
  pla
  sta movefrom + $01
  jsr ComputeMoveFromOffset
  jmp !continue+
!moveto:
  pla
  sta moveto + $01
  jsr ComputeMoveToOffset
!continue:
  jsr DisplayCoordinate
!exit:
  rts

/*
Deal with a column selection. This is the first part of the board coordinate
for movefrom and moveto.
*/
HandleColumnSelection:
  jeq cursorxpos:#$01:!exit+
  lda currentkey        // KEY_A-KEY_H = $01-$08 = screen codes A-H
  pha                   // Save for display (already correct screen code)
  sec
  sbc #$01              // Make the column number 0 based for storage
  tax                   // Save column in X (jne clobbers A)
  jne inputselection:#INPUT_MOVE_FROM:!moveto+
  stx movefrom
  jmp !continue+
!moveto:
  stx moveto
!continue:
  pla                   // Restore original key (screen code A-H)
  sta currentkey
  jsr DisplayCoordinate
  inc cursorxpos        // Move the cursor over 1 place
!exit:
  rts

/*
Display either the row or the column
*/
DisplayCoordinate:
  jsr ClearError
  StoreWord(inputlocationvector, ScreenAddress(CursorPos))
  lda currentkey        // Load AFTER StoreWord (which clobbers A)
  ldy cursorxpos
  sta (inputlocationvector), y
  rts
