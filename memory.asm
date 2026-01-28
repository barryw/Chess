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
Flip the board in place for 0x88 layout.
Swaps row 0 ($00-$07) with row 7 ($70-$77), row 1 with row 6, etc.
Each row is 16 bytes apart in 0x88 indexing.
NOTE: Uses temp1, temp2 for row indices - does NOT touch 'counter' (used by raster IRQ)
*/
FlipBoard:
  ldx #$00              // Top row base ($00)
  ldy #$70              // Bottom row base ($70)

!rowloop:
  // Save row base indices
  stx temp1
  sty temp1 + $01

  // Swap 8 valid squares in this row pair
  lda #$08
  sta temp2             // Use temp2 as column counter (NOT counter!)

!colloop:
  lda Board88, x        // Load from top row
  pha                   // Save on stack
  lda Board88, y        // Load from bottom row
  sta Board88, x        // Store at top
  pla                   // Restore top value
  sta Board88, y        // Store at bottom
  inx                   // Next column
  iny
  dec temp2
  bne !colloop-

  // Move to next row pair (top row +16, bottom row -16)
  lda temp1
  clc
  adc #ROW_STRIDE       // Next row down (+16)
  tax
  lda temp1 + $01
  sec
  sbc #ROW_STRIDE       // Next row up (-16)
  tay
  cpx #$40              // Done when rows meet at middle (row 4)
  bne !rowloop-
  rts

/*
Enable the flashing of the selected piece
*/
FlashPieceOn:
  bfs movefromindex:!exit+
  ldx movefromindex
  stb Board88, x:selectedpiece
  lda #TIMER_FLASH_PIECE
  jsr EnableTimer
!exit:
  rts

/*
Disable the flashing of a selected piece
*/
FlashPieceOff:
  lda #TIMER_FLASH_PIECE
  jsr DisableTimer
  ldx movefromindex     // Stick it back in Board88
  stb selectedpiece:Board88, x
!exit:
  rts
