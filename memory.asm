*=* "Memory"

/*
Fill memory with bytes. This is very similar to the memcopy routine
below, but just stores a single value into a range of addresses.
*/
FillMemory:
  wfc fillmutex         // Wait for mutex to be released
  sef fillmutex         // Set the mutex
  ldy #0
  ldx fill_size + $01
  beq !frag_fill+
!page_fill:
  lda fill_value
  sta (fill_to), y
  iny
  bne !page_fill-
  inc fill_to + $01
  dex
  bne !page_fill-
!frag_fill:
  cpy fill_size
  beq !done_fill+
  lda fill_value
  sta (fill_to), y
  iny
  bne !frag_fill-
!done_fill:
  clf fillmutex         // Clear the mutex
!exit:
  rts

/*
Do the actual memory copy.

Doesn't need to be on a page boundary. Can copy fragments as well.
*/
CopyMemory:
  wfc copymutex
  sef copymutex
  ldy #0
  ldx copy_size + $01
  beq !frag+
!page:
  lda (copy_from), y
  sta (copy_to), y
  iny
  bne !page-
  inc copy_from + $01
  inc copy_to + $01
  dex
  bne !page-
!frag:
  cpy copy_size
  beq !done+
  lda (copy_from), y
  sta (copy_to), y
  iny
  bne !frag-
!done:
  clf copymutex
!exit:
  rts

/*
Flip the board
*/
FlipBoard:
  PushStack()
  ldx #$3f
  ldy #$00
!loop:
  lda BoardState, x
  sta fliptmp, y
  iny
  dex
  cpx #$ff
  bne !loop-
  ldx #$00
!loop2:
  lda fliptmp, x
  sta BoardState, x
  inx
  cpx #$40
  bne !loop2-
  PopStack()
  rts

/*
Enable the flashing of the selected piece
*/
FlashPieceOn:
  ldx movefromindex     // Has a piece been selected?
  bmi !exit+            // Nope. Just exit.
  lda BoardState, x     // Grab the piece that's in that location
  sta selectedpiece     // tuck it away for later
  sef flashpiece        // Turn flashing on
!exit:
  rts

/*
Disable the flashing of a selected piece
*/
FlashPieceOff:
  lda flashpiece
  bpl !exit+
  lda selectedpiece     // Retrieve our stored piece
  ldx movefromindex     // Stick it back in BoardState
  sta BoardState, x
  clf flashpiece        // Turn flashing off
!exit:
  rts
