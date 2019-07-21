*=* "Memory"

/*
Fill memory with bytes. This is very similar to the memcopy routine
below, but just stores a single value into a range of addresses.
*/
FillMemory:
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
  rts

/*
Do the actual memory copy.

Doesn't need to be on a page boundary. Can copy fragments as well.
*/
CopyMemory:
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
  bfs movefromindex:!exit+
  ldx movefromindex
  stb BoardState, x:selectedpiece
  sef flashpiece        // Turn flashing on
!exit:
  rts

/*
Disable the flashing of a selected piece
*/
FlashPieceOff:
  clf flashpiece        // Turn flashing off
  ldx movefromindex     // Stick it back in BoardState
  stb selectedpiece:BoardState, x
!exit:
  rts
