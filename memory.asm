*=* "Memory"
.macro PushStack() {
  pha
  txa
  pha
  tya
  pha
}

.macro PopStack() {
  pla
  tay
  pla
  tax
  pla
}

/*
Store a 16 bit word
*/
.macro StoreWord(address, word) {
  lda #<word
  sta address
  lda #>word
  sta address+1
}

/*
Perform a memory copy

Each parameter is 16 bits
*/
.macro CopyMemory(from_address, to_address, size) {
!wait:
  lda copymutex
  cmp #$00
  bne !wait-
  lda #$01
  sta copymutex
  StoreWord(copy_from, from_address)
  StoreWord(copy_to, to_address)
  StoreWord(copy_size, size)
  jsr CopyMemory
  lda #$00
  sta copymutex
}

/*
Fill a block of memory with a byte
*/
.macro FillMemory(address, size, value) {
!wait:
  lda fillmutex
  cmp #$00
  bne !wait-
  lda #$01
  sta fillmutex
  StoreWord(fill_to, address)
  StoreWord(fill_size, size)
  lda #value
  sta fill_value
  jsr FillMemory
  lda #$00
  sta fillmutex
}

FillMemory:
  ldy #0
  ldx fill_size + 1
  beq !frag_fill+
!page_fill:
  lda fill_value
  sta (fill_to), y
  iny
  bne !page_fill-
  inc fill_to + 1
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
  ldx copy_size + 1
  beq !frag+
!page:
  lda (copy_from), y
  sta (copy_to), y
  iny
  bne !page-
  inc copy_from + 1
  inc copy_to + 1
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
