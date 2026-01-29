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
NOTE: $35 (HIRAM=0) banks out BOTH BASIC and KERNAL ROM.
$A000-$BFFF and $E000-$FFFF are RAM, $D000-$DFFF is I/O.
*/
SetupCharacters:
  stb #$1d:vic.VMCSB
  stb #$35:$01

  rts

/*
Enter turbo mode - ALL RAM including $D000-$DFFF
WARNING: No I/O access! No screen, no sound, no keyboard!
Use only during computation bursts, restore quickly.
$30 = %00110000: All RAM, no I/O
*/
EnterTurboMode:
  stb #MEMORY_CONFIG_TURBO:$01
  rts

/*
Exit turbo mode - restore I/O access
*/
ExitTurboMode:
  stb #MEMORY_CONFIG_NORMAL:$01
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

  // Display version in lower right corner
  PrintAt(VersionText, VersionPos, LIGHT_GREY)

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

/*
==============================================================================
PIECE LIST MANAGEMENT ROUTINES

These routines maintain the WhitePieceList and BlackPieceList arrays which
track the 0x88 positions of each player's pieces. This enables O(n) scanning
where n = actual pieces rather than O(128) board scanning.

Key insight: We use a SWAP-AND-SHRINK strategy for captures. When a piece is
captured, we swap it with the last active piece and decrement the count.
This keeps all active pieces contiguous at the start of the list.
==============================================================================
*/

/*
Initialize piece lists from current Board88 state.
Call this at game start or after loading a position.

This scans Board88 once and populates both piece lists.
Runtime: ~300 cycles (once per game)
*/
InitPieceLists:
  // Clear both lists
  ldx #15
  lda #$ff
!clear_loop:
  sta WhitePieceList, x
  sta BlackPieceList, x
  dex
  bpl !clear_loop-

  // Reset counts
  lda #$00
  sta WhitePieceCount
  sta BlackPieceCount

  // Scan Board88 for pieces
  ldx #$00              // Board88 index
!scan_loop:
  // 0x88 validity check
  txa
  and #OFFBOARD_MASK
  bne !next_square+

  // Check if occupied
  lda Board88, x
  cmp #EMPTY_SPR
  beq !next_square+

  // Got a piece - determine color
  and #BIT8
  bne !white_piece+

  // Black piece: add to BlackPieceList
  ldy BlackPieceCount
  txa
  sta BlackPieceList, y
  inc BlackPieceCount
  jmp !next_square+

!white_piece:
  // White piece: add to WhitePieceList
  ldy WhitePieceCount
  txa
  sta WhitePieceList, y
  inc WhitePieceCount

!next_square:
  inx
  cpx #BOARD_SIZE
  bne !scan_loop-

  rts

/*
Update piece list when a piece moves.
Call BEFORE updating Board88.

Input:
  movefromindex = source square (0x88)
  movetoindex   = destination square (0x88)
  currentplayer = which player is moving (0=black, 1=white)

This finds the piece in the appropriate list and updates its position.
If there's a capture, we also remove the captured piece from opponent's list.
Runtime: ~80 cycles average
*/
UpdatePieceListForMove:
  // First, check if this is a capture (destination has enemy piece)
  ldx movetoindex
  lda Board88, x
  cmp #EMPTY_SPR
  beq !no_capture+

  // Capture! Remove enemy piece from their list
  // Enemy is opposite of currentplayer
  lda currentplayer
  beq !capture_white+

  // Current is white, capturing black piece
  jsr RemoveFromBlackPieceList
  jmp !no_capture+

!capture_white:
  // Current is black, capturing white piece
  jsr RemoveFromWhitePieceList

!no_capture:
  // Now update the moving piece's position in its list
  lda currentplayer
  beq !update_black+

  // White piece moving
  jsr UpdateWhitePiecePosition
  rts

!update_black:
  jsr UpdateBlackPiecePosition
  rts

/*
Remove piece at movetoindex from White piece list.
Uses swap-and-shrink: swap target with last piece, decrement count.
*/
RemoveFromWhitePieceList:
  lda movetoindex
  ldx #$00
!find_loop:
  cpx WhitePieceCount
  beq !not_found+       // Safety: piece not in list
  cmp WhitePieceList, x
  beq !found+
  inx
  bne !find_loop-       // Always branches (X can't be 0 after INX from 0)

!found:
  // Swap with last piece and shrink
  dec WhitePieceCount
  ldy WhitePieceCount
  lda WhitePieceList, y // Get last piece's position
  sta WhitePieceList, x // Put it where removed piece was
  lda #$ff
  sta WhitePieceList, y // Clear the old last slot
!not_found:
  rts

/*
Remove piece at movetoindex from Black piece list.
*/
RemoveFromBlackPieceList:
  lda movetoindex
  ldx #$00
!find_loop:
  cpx BlackPieceCount
  beq !not_found+
  cmp BlackPieceList, x
  beq !found+
  inx
  bne !find_loop-

!found:
  dec BlackPieceCount
  ldy BlackPieceCount
  lda BlackPieceList, y
  sta BlackPieceList, x
  lda #$ff
  sta BlackPieceList, y
!not_found:
  rts

/*
Update white piece position from movefromindex to movetoindex.
*/
UpdateWhitePiecePosition:
  lda movefromindex
  ldx #$00
!find_loop:
  cpx WhitePieceCount
  beq !not_found+
  cmp WhitePieceList, x
  beq !found+
  inx
  bne !find_loop-

!found:
  lda movetoindex
  sta WhitePieceList, x
!not_found:
  rts

/*
Update black piece position from movefromindex to movetoindex.
*/
UpdateBlackPiecePosition:
  lda movefromindex
  ldx #$00
!find_loop:
  cpx BlackPieceCount
  beq !not_found+
  cmp BlackPieceList, x
  beq !found+
  inx
  bne !find_loop-

!found:
  lda movetoindex
  sta BlackPieceList, x
!not_found:
  rts

/*
Handle en passant capture for piece lists.
Call when en passant capture is detected (after UpdatePieceListForMove).

Input: A = square of captured pawn (NOT the landing square)

En passant is special because the captured piece is not on movetoindex.
*/
RemovePawnEnPassant:
  sta piecelist_idx     // Save the square
  // Determine which color pawn was captured
  lda currentplayer
  beq !remove_white_pawn+

  // White captured black pawn
  lda piecelist_idx
  ldx #$00
!find_black:
  cpx BlackPieceCount
  beq !done+
  cmp BlackPieceList, x
  beq !found_black+
  inx
  bne !find_black-
!found_black:
  dec BlackPieceCount
  ldy BlackPieceCount
  lda BlackPieceList, y
  sta BlackPieceList, x
  lda #$ff
  sta BlackPieceList, y
  rts

!remove_white_pawn:
  lda piecelist_idx
  ldx #$00
!find_white:
  cpx WhitePieceCount
  beq !done+
  cmp WhitePieceList, x
  beq !found_white+
  inx
  bne !find_white-
!found_white:
  dec WhitePieceCount
  ldy WhitePieceCount
  lda WhitePieceList, y
  sta WhitePieceList, x
  lda #$ff
  sta WhitePieceList, y
!done:
  rts

/*
Update piece list for castling rook move.
Called after the king move is already processed in piece list.

Input:
  A = rook's original square (0x88)
  X = rook's destination square (0x88)
  currentplayer = which player is castling
*/
UpdateCastlingRook:
  sta piecelist_idx     // Save from-square
  stx temp1             // Save to-square (using temp1 as scratch)

  lda currentplayer
  beq !update_black_rook+

  // White rook: find in WhitePieceList and update position
  lda piecelist_idx     // Get from-square
  ldx #$00
!find_white_rook:
  cpx WhitePieceCount
  beq !castling_done+
  cmp WhitePieceList, x
  beq !found_white_rook+
  inx
  bne !find_white_rook-
!found_white_rook:
  lda temp1             // Get to-square
  sta WhitePieceList, x
  rts

!update_black_rook:
  lda piecelist_idx
  ldx #$00
!find_black_rook:
  cpx BlackPieceCount
  beq !castling_done+
  cmp BlackPieceList, x
  beq !found_black_rook+
  inx
  bne !find_black_rook-
!found_black_rook:
  lda temp1
  sta BlackPieceList, x
!castling_done:
  rts
