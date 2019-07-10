*=* "Memory"
.macro PushStack() {
  php
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
  plp
}

// Toggle a flag
.macro Toggle(address) {
  lda address
  eor #$80
  sta address
}

// Disable a flag
.macro Disable(address) {
  lda #$00
  sta address
}

// Enable a flag
.macro Enable(address) {
  lda #$80
  sta address
}
/*
Store a 16 bit word
*/
.macro StoreWord(address, word) {
  lda #<word
  sta address
  lda #>word
  sta address + $01
}

/*
Perform a memory copy

Each parameter is 16 bits
*/
.macro CopyMemory(from_address, to_address, size) {
  StoreWord(copy_from, from_address)
  StoreWord(copy_to, to_address)
  StoreWord(copy_size, size)
  jsr CopyMemory
}

/*
Fill a block of memory with a byte
*/
.macro FillMemory(address, size, value) {
  StoreWord(fill_to, address)
  StoreWord(fill_size, size)
  lda #value
  sta fill_value
  jsr FillMemory
}

FillMemory:
  lda fillmutex
  cmp #$00
  bne FillMemory
  lda #$01
  sta fillmutex
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
  lda #$00
  sta fillmutex
  rts

/*
Do the actual memory copy.

Doesn't need to be on a page boundary. Can copy fragments as well.
*/
CopyMemory:
  lda copymutex
  cmp #$00
  bne CopyMemory
  lda #$01
  sta copymutex
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
  lda #$00
  sta copymutex
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
